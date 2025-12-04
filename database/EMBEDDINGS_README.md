# Embeddings y RAG - Estructura de Base de Datos

## Tabla: informes_embeddings

Esta tabla almacena los embeddings vectoriales de los informes médicos para búsqueda semántica (RAG).

### Estructura

```sql
CREATE TABLE informes_embeddings (
    id SERIAL PRIMARY KEY,
    informe_id INT NOT NULL,
    trabajador_id INT NOT NULL,
    embedding vector(1024),  -- Vector de Amazon Titan Embeddings v2
    contenido TEXT,          -- Texto usado para generar el embedding
    fecha_examen TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (informe_id) REFERENCES informes_medicos(id) ON DELETE CASCADE,
    FOREIGN KEY (trabajador_id) REFERENCES trabajadores(id) ON DELETE CASCADE
);
```

### Índices

```sql
-- Índice IVFFlat para búsqueda de similitud eficiente
CREATE INDEX idx_embedding_vector ON informes_embeddings 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Índices para filtrado
CREATE INDEX idx_embedding_trabajador ON informes_embeddings(trabajador_id);
CREATE INDEX idx_embedding_informe ON informes_embeddings(informe_id);
```

## Modelo de Embeddings

- **Modelo**: Amazon Titan Embeddings v2 (`amazon.titan-embed-text-v2:0`)
- **Dimensiones**: 1024
- **Método de similitud**: Cosine similarity (distancia de coseno)

## Construcción del Texto para Embeddings

El texto que se convierte en embedding incluye:

```python
texto = f"""
Trabajador: {nombre}
Tipo de examen: {tipo_examen}
Observaciones: {observaciones}
Hallazgos: {hallazgos}
Parámetros clínicos: {parametros}
"""
```

## Búsqueda de Similitud

### Query Básica

```sql
SELECT 
    im.id,
    t.nombre as trabajador,
    im.tipo_examen,
    im.nivel_riesgo,
    1 - (ie1.embedding <=> ie2.embedding) as similarity_score
FROM informes_medicos im
JOIN informes_embeddings ie1 ON im.id = ie1.informe_id
JOIN trabajadores t ON im.trabajador_id = t.id
CROSS JOIN informes_embeddings ie2
WHERE ie2.informe_id = ?  -- ID del informe de referencia
  AND im.id != ?          -- Excluir el informe actual
ORDER BY similarity_score DESC
LIMIT 5;
```

### Operadores de Distancia en pgvector

- `<=>` : Distancia de coseno (0 = idénticos, 2 = opuestos)
- `<->` : Distancia euclidiana
- `<#>` : Producto interno negativo

**Nota**: Usamos `1 - (embedding1 <=> embedding2)` para convertir distancia en similitud (1 = idénticos, 0 = no relacionados).

## Flujo de Trabajo

1. **Generación de Embedding**:
   - Lambda `generate-embeddings` se invoca cuando se crea/actualiza un informe
   - Construye texto del informe
   - Llama a Bedrock con Titan Embeddings v2
   - Almacena vector en `informes_embeddings`

2. **Búsqueda de Similitud**:
   - Lambda `send-email` (u otra función) busca informes similares
   - Usa query con JOIN a `informes_embeddings`
   - Calcula similitud de coseno
   - Retorna top 5 resultados más similares

3. **Uso en RAG**:
   - Médico consulta casos similares para contexto
   - Sistema genera recomendaciones basadas en casos similares
   - **IMPORTANTE**: Información NO se comparte con empleados (privacidad)

## Consideraciones de Privacidad

- Los embeddings permiten búsqueda semántica de casos similares
- Esta funcionalidad es para uso **INTERNO del médico**
- Los emails a empleados **NO deben mencionar** casos de otros empleados
- RAG proporciona contexto al médico, no al paciente

## Mantenimiento

### Regenerar Embeddings

Si necesitas regenerar embeddings (por ejemplo, después de cambiar el modelo):

```sql
-- Eliminar embeddings existentes
DELETE FROM informes_embeddings;

-- Invocar Lambda para cada informe
-- (Usar script de regeneración masiva)
```

### Verificar Integridad

```sql
-- Informes sin embeddings
SELECT im.id, im.trabajador_id
FROM informes_medicos im
WHERE NOT EXISTS (
    SELECT 1 FROM informes_embeddings ie 
    WHERE ie.informe_id = im.id
);

-- Embeddings huérfanos (sin informe)
SELECT ie.id, ie.informe_id
FROM informes_embeddings ie
WHERE NOT EXISTS (
    SELECT 1 FROM informes_medicos im 
    WHERE im.id = ie.informe_id
);
```

## Performance

### Índice IVFFlat

El índice IVFFlat divide el espacio vectorial en listas (clusters):

- `lists = 100`: Número de clusters
- Más listas = búsqueda más rápida pero menos precisa
- Menos listas = búsqueda más lenta pero más precisa

Para datasets pequeños (<10,000 registros), 100 listas es adecuado.

### Optimización de Queries

```sql
-- Bueno: Usa índice IVFFlat
SELECT * FROM informes_embeddings 
ORDER BY embedding <=> '[vector]' 
LIMIT 5;

-- Malo: No usa índice (escaneo completo)
SELECT * FROM informes_embeddings 
WHERE embedding <=> '[vector]' < 0.5;
```

## Referencias

- [pgvector Documentation](https://github.com/pgvector/pgvector)
- [Amazon Titan Embeddings](https://docs.aws.amazon.com/bedrock/latest/userguide/titan-embedding-models.html)
- [Cosine Similarity](https://en.wikipedia.org/wiki/Cosine_similarity)
