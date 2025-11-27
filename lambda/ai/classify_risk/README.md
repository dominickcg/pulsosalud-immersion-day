# Lambda: Classify Risk

## Descripción
Lambda que clasifica informes médicos en niveles de riesgo (BAJO, MEDIO, ALTO) usando Amazon Nova Pro con contexto histórico (RAG). Utiliza few-shot learning y análisis de tendencias para clasificación precisa.

## Funcionalidad

### Entrada
La Lambda puede ser invocada de dos formas:

1. **Sin parámetros** (procesa todos los informes sin clasificar):
```json
{}
```

2. **Con informe_id específico**:
```json
{
  "informe_id": 123
}
```

### Proceso
1. Lee informes médicos sin clasificar de Aurora
2. Obtiene contexto histórico del trabajador usando RAG:
   - Últimos 3 informes del mismo trabajador
   - Informes ordenados por fecha
3. Construye prompt con:
   - Criterios de clasificación (BAJO, MEDIO, ALTO)
   - Ejemplos (few-shot learning)
   - Contexto histórico del trabajador
   - Informe actual a clasificar
4. Invoca Amazon Nova Pro para clasificación
5. Parsea respuesta JSON con nivel de riesgo y justificación
6. Actualiza Aurora con clasificación

### Salida
```json
{
  "statusCode": 200,
  "body": {
    "message": "Successfully processed N informes",
    "processed": 5,
    "total": 5
  }
}
```

## Niveles de Riesgo

### BAJO
**Criterios:**
- Todos los parámetros dentro de rangos normales
- Sin observaciones preocupantes
- Historial estable o mejorando

**Ejemplo:**
- Presión arterial: 120/80
- Peso: Normal (IMC 18.5-24.9)
- Visión: 20/20
- Sin observaciones críticas

### MEDIO
**Criterios:**
- Algunos parámetros fuera de rango normal
- Observaciones que requieren seguimiento
- Cambios moderados respecto al historial

**Ejemplo:**
- Presión arterial: 140/90 (pre-hipertensión)
- Sobrepeso leve (IMC 25-29.9)
- Visión reducida
- Requiere seguimiento

### ALTO
**Criterios:**
- Múltiples parámetros fuera de rango
- Observaciones críticas
- Deterioro significativo respecto al historial
- Requiere atención inmediata

**Ejemplo:**
- Presión arterial: 160/100 (hipertensión)
- Obesidad (IMC >30)
- Problemas auditivos severos
- Múltiples anomalías

## Modelo de IA

### Amazon Nova Pro
- **Model ID:** `amazon.nova-pro-v1:0`
- **Temperature:** 0.3 (balance entre consistencia y flexibilidad)
- **Max Tokens:** 2000
- **Uso:** Clasificación con razonamiento y contexto

### Prompt Engineering

#### Few-Shot Learning
El prompt incluye ejemplos de cada nivel de riesgo para guiar al modelo:
```
RIESGO BAJO:
- Ejemplo: Presión 120/80, peso normal, visión 20/20...

RIESGO MEDIO:
- Ejemplo: Presión 140/90, sobrepeso leve...

RIESGO ALTO:
- Ejemplo: Presión 160/100, obesidad...
```

#### Contexto Histórico (RAG)
```
CONTEXTO HISTÓRICO DEL TRABAJADOR:
--- Informe 1 (Fecha: 2024-01-15) ---
Tipo: General
Presión arterial: 120/80
Nivel de riesgo: BAJO
...

--- Informe 2 (Fecha: 2023-12-10) ---
...
```

#### Formato de Respuesta
```json
{
  "nivel_riesgo": "BAJO|MEDIO|ALTO",
  "justificacion": "Explicación clara..."
}
```

## Variables de Entorno

- `DB_SECRET_ARN`: ARN del secreto con credenciales de Aurora
- `DB_CLUSTER_ARN`: ARN del cluster Aurora
- `DATABASE_NAME`: Nombre de la base de datos (medical_reports)
- `BUCKET_NAME`: Nombre del bucket S3 (no usado en esta Lambda)

## Dependencias

- `boto3`: SDK de AWS para Python
  - `bedrock-runtime`: Cliente para Amazon Bedrock
  - `rds-data`: Cliente para RDS Data API
- `similarity_search` (Lambda Layer): Funciones de RAG

## Base de Datos

### Actualización en informes_medicos
```sql
UPDATE informes_medicos
SET nivel_riesgo = 'BAJO|MEDIO|ALTO',
    justificacion_riesgo = 'texto',
    procesado_por_ia = true,
    updated_at = CURRENT_TIMESTAMP
WHERE id = :informe_id
```

## Invocación

### Manual (AWS CLI)
```bash
# Procesar todos los informes sin clasificar
aws lambda invoke \
  --function-name demo-classify-risk \
  --payload '{}' \
  response.json

# Procesar informe específico
aws lambda invoke \
  --function-name demo-classify-risk \
  --payload '{"informe_id": 123}' \
  response.json
```

### Desde otra Lambda
```python
import boto3
import json

lambda_client = boto3.client('lambda')

# Clasificar después de crear informe
response = lambda_client.invoke(
    FunctionName='demo-classify-risk',
    InvocationType='Event',  # Asíncrono
    Payload=json.dumps({'informe_id': informe_id})
)
```

### Trigger Automático (EventBridge)
```bash
# Habilitar regla (cada hora)
aws events enable-rule --name demo-classification-schedule

# Deshabilitar regla
aws events disable-rule --name demo-classification-schedule
```

## Flujo de Trabajo

### 1. Después de Extracción
```python
# En Lambda de extracción
informe_id = save_to_aurora(data)

# Invocar clasificación
lambda_client.invoke(
    FunctionName='classify-risk',
    InvocationType='Event',
    Payload=json.dumps({'informe_id': informe_id})
)
```

### 2. Antes de Resumen
```python
# Clasificar primero
classify_risk(informe_id)

# Luego generar resumen con nivel de riesgo
generate_summary(informe_id)
```

### 3. Procesamiento Batch
```python
# Procesar todos los pendientes
lambda_client.invoke(
    FunctionName='classify-risk',
    InvocationType='Event',
    Payload=json.dumps({})
)
```

## Integración RAG

### Obtener Contexto Histórico
```python
from similarity_search import get_historical_context, format_context_for_prompt

# Obtener últimos 3 informes del trabajador
historical = get_historical_context(
    trabajador_id=trabajador_id,
    current_informe_id=informe_id,
    limit=3
)

# Formatear para prompt
context_text = format_context_for_prompt(historical)
```

### Análisis de Tendencias
El contexto histórico permite:
- Detectar deterioro en parámetros vitales
- Identificar mejoras o estabilidad
- Comparar con informes anteriores
- Clasificación más precisa basada en tendencias

## Logs

La Lambda registra:
- Número de informes procesados
- Contexto histórico encontrado
- Nivel de riesgo asignado
- Justificación generada
- Prompts enviados a Bedrock
- Respuestas de Bedrock
- Errores en clasificación

## Timeout y Memoria

- **Timeout:** 5 minutos (configurado en CDK)
- **Memoria:** 1024 MB (configurado en CDK)
- **Procesamiento:** ~50 informes por invocación (límite en query)

## Permisos IAM

La Lambda requiere:
- `bedrock:InvokeModel` para Nova Pro y Titan Embeddings
- `secretsmanager:GetSecretValue` para credenciales de Aurora
- `rds-data:ExecuteStatement` para operaciones en Aurora
- `rds-data:BatchExecuteStatement` para operaciones batch

## Manejo de Errores

### Error: "No historical context found"
```python
# La Lambda continúa sin contexto histórico
context_text = "No hay informes históricos disponibles."
```

### Error: "Invalid risk level"
```python
# Defaultea a MEDIO si la respuesta es inválida
if nivel_riesgo not in ['BAJO', 'MEDIO', 'ALTO']:
    nivel_riesgo = 'MEDIO'
```

### Error: "JSON parsing failed"
```python
# Limpia markdown y reintenta
text = text.strip()
if text.startswith('```json'):
    text = text[7:]
```

## Optimizaciones

### Performance
- Procesar en batch (múltiples informes por invocación)
- Cachear contexto histórico si es posible
- Usar invocación asíncrona para no bloquear

### Costos
- Ajustar frecuencia de EventBridge según necesidad
- Usar invocación manual para casos urgentes
- Monitorear uso de Bedrock (tokens)

### Precisión
- Iterar en prompts (v1, v2, v3)
- Ajustar temperature según resultados
- Incluir más ejemplos en few-shot learning
- Refinar criterios de clasificación
- Analizar clasificaciones incorrectas

## Testing

```python
# Test básico
def test_classification():
    event = {'informe_id': 123}
    response = handler(event, None)
    
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert body['processed'] > 0
```

## Monitoreo

### CloudWatch Metrics
- Invocaciones
- Duración promedio
- Errores
- Throttles

### CloudWatch Logs
- Logs detallados de clasificación
- Prompts enviados
- Respuestas de Bedrock
- Distribución de niveles de riesgo

### Queries Útiles
```sql
-- Distribución de niveles de riesgo
SELECT nivel_riesgo, COUNT(*) 
FROM informes_medicos 
WHERE nivel_riesgo IS NOT NULL 
GROUP BY nivel_riesgo;

-- Informes sin clasificar
SELECT COUNT(*) 
FROM informes_medicos 
WHERE nivel_riesgo IS NULL;

-- Clasificaciones recientes
SELECT id, trabajador_id, nivel_riesgo, fecha_examen
FROM informes_medicos
WHERE procesado_por_ia = true
ORDER BY updated_at DESC
LIMIT 10;
```
