# Lambda Layer: Similarity Search

## Descripción
Lambda Layer compartido que proporciona funciones de búsqueda por similitud usando pgvector en Aurora PostgreSQL. Este módulo se comparte entre múltiples Lambdas para búsqueda semántica y contexto histórico.

## Funciones Principales

### 1. search_similar_informes()
Busca informes similares para un trabajador específico usando búsqueda vectorial.

```python
from similarity_search import search_similar_informes

# Buscar top 3 informes similares para un trabajador
similar = search_similar_informes(
    trabajador_id=123,
    query_embedding=[0.1, 0.2, ...],  # Vector de 1024 dimensiones
    limit=3
)

# Resultado:
# [
#   {
#     'informe_id': 456,
#     'trabajador_id': 123,
#     'tipo_examen': 'General',
#     'fecha_examen': '2024-01-15',
#     'presion_arterial': '120/80',
#     'peso': 75.5,
#     'altura': 1.75,
#     'vision': '20/20',
#     'audiometria': 'Normal',
#     'observaciones': '...',
#     'nivel_riesgo': 'BAJO',
#     'justificacion_riesgo': '...',
#     'resumen_ejecutivo': '...',
#     'trabajador_nombre': 'Juan Pérez',
#     'trabajador_documento': '12345678',
#     'distance': 0.15,      # Distancia coseno (menor = más similar)
#     'similarity': 0.85     # Similitud (mayor = más similar)
#   },
#   ...
# ]
```

### 2. search_similar_informes_all_workers()
Busca informes similares en toda la base de datos (sin filtrar por trabajador).

```python
from similarity_search import search_similar_informes_all_workers

# Buscar top 5 informes similares en toda la BD
similar = search_similar_informes_all_workers(
    query_embedding=[0.1, 0.2, ...],
    limit=5
)
```

### 3. get_historical_context()
Obtiene informes históricos de un trabajador ordenados por fecha.

```python
from similarity_search import get_historical_context

# Obtener últimos 3 informes de un trabajador
historical = get_historical_context(
    trabajador_id=123,
    current_informe_id=789,  # Opcional: excluir informe actual
    limit=3
)

# Resultado:
# [
#   {
#     'informe_id': 456,
#     'trabajador_id': 123,
#     'tipo_examen': 'General',
#     'fecha_examen': '2024-01-15',
#     'presion_arterial': '120/80',
#     ...
#   },
#   ...
# ]
```

### 4. format_context_for_prompt()
Formatea informes para incluir en prompts de IA.

```python
from similarity_search import format_context_for_prompt

# Formatear contexto histórico para prompt
context_text = format_context_for_prompt(historical)

# Resultado:
# """
# --- Informe 1 (Fecha: 2024-01-15) ---
# Tipo: General
# Presión arterial: 120/80
# Peso: 75.5 kg
# Altura: 1.75 m
# Visión: 20/20
# Audiometría: Normal
# Observaciones: ...
# Nivel de riesgo: BAJO
# Justificación: ...
# 
# --- Informe 2 (Fecha: 2023-12-10) ---
# ...
# """
```

## Uso en Lambdas

### Configuración del Layer en CDK
```typescript
const similaritySearchLayer = new lambda.LayerVersion(this, 'SimilaritySearchLayer', {
  layerVersionName: `${participantPrefix}-similarity-search`,
  code: lambda.Code.fromAsset('../lambda/shared'),
  compatibleRuntimes: [lambda.Runtime.PYTHON_3_11],
  description: 'Funciones compartidas para búsqueda por similitud con pgvector',
});

// Agregar layer a una Lambda
const myLambda = new lambda.Function(this, 'MyFunction', {
  // ...
  layers: [similaritySearchLayer],
});
```

### Importar en Lambda
```python
# En el código de tu Lambda
from similarity_search import (
    search_similar_informes,
    get_historical_context,
    format_context_for_prompt
)

def handler(event, context):
    # Usar las funciones
    similar = search_similar_informes(
        trabajador_id=123,
        query_embedding=embedding
    )
    
    context_text = format_context_for_prompt(similar)
    # Incluir context_text en prompt de Bedrock
```

## Algoritmo de Búsqueda

### pgvector con Cosine Distance
El módulo usa el operador `<=>` de pgvector para calcular distancia coseno:

```sql
SELECT *
FROM informes_embeddings
WHERE trabajador_id = 123
ORDER BY embedding <=> '[0.1, 0.2, ...]'::vector
LIMIT 3
```

- **Distancia coseno:** 0 = idéntico, 1 = opuesto
- **Similitud:** 1 - distancia (1 = idéntico, 0 = opuesto)
- **Índice:** IVFFlat para búsquedas aproximadas rápidas

## Variables de Entorno

Las funciones usan estas variables de entorno (o se pueden pasar como parámetros):

- `DB_SECRET_ARN`: ARN del secreto con credenciales de Aurora
- `DB_CLUSTER_ARN`: ARN del cluster Aurora
- `DATABASE_NAME`: Nombre de la base de datos (medical_reports)

## Casos de Uso

### 1. Clasificación de Riesgo con Contexto
```python
# Obtener informes similares del mismo trabajador
historical = get_historical_context(
    trabajador_id=trabajador_id,
    current_informe_id=current_id,
    limit=3
)

# Formatear para prompt
context = format_context_for_prompt(historical)

# Incluir en prompt de clasificación
prompt = f"""
Clasifica el siguiente informe médico.

Contexto histórico del trabajador:
{context}

Informe actual:
{current_data}

Clasifica como BAJO, MEDIO o ALTO riesgo.
"""
```

### 2. Generación de Resúmenes con Tendencias
```python
# Obtener informes históricos
historical = get_historical_context(trabajador_id, limit=5)

# Analizar tendencias
context = format_context_for_prompt(historical)

prompt = f"""
Genera un resumen ejecutivo del informe actual.
Incluye análisis de tendencias basado en el historial.

Historial:
{context}

Informe actual:
{current_data}
"""
```

### 3. Búsqueda de Casos Similares
```python
# Generar embedding del informe actual
embedding = generate_embedding(current_text)

# Buscar casos similares
similar_cases = search_similar_informes(
    trabajador_id=trabajador_id,
    query_embedding=embedding,
    limit=5
)

# Analizar patrones en casos similares
for case in similar_cases:
    print(f"Caso similar (similitud: {case['similarity']:.2f})")
    print(f"  Riesgo: {case['nivel_riesgo']}")
    print(f"  Fecha: {case['fecha_examen']}")
```

## Dependencias

- `boto3`: SDK de AWS para Python
  - `rds-data`: Cliente para RDS Data API

## Estructura del Layer

```
lambda/shared/
├── __init__.py              # Exporta funciones principales
├── similarity_search.py     # Implementación de búsqueda
└── README.md               # Esta documentación
```

## Notas Técnicas

### Dimensiones de Embeddings
- Amazon Titan Embeddings v2 soporta: 256, 512, 1024 dimensiones
- Este proyecto usa: **1024 dimensiones**
- El schema de BD debe coincidir: `vector(1024)`

### Índice pgvector
El índice IVFFlat proporciona búsquedas aproximadas rápidas:
```sql
CREATE INDEX idx_embedding_vector ON informes_embeddings 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
```

### Performance
- Búsqueda con índice: O(log n) aproximado
- Sin índice: O(n) lineal
- Recomendado: >1000 vectores para beneficio del índice

## Testing

```python
# Test básico
def test_similarity_search():
    # Embedding de prueba (1024 dimensiones)
    test_embedding = [0.1] * 1024
    
    results = search_similar_informes(
        trabajador_id=1,
        query_embedding=test_embedding,
        limit=3
    )
    
    assert len(results) <= 3
    assert all('similarity' in r for r in results)
    assert all(0 <= r['similarity'] <= 1 for r in results)
```
