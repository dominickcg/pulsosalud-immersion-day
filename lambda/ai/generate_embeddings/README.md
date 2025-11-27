# Lambda: Generate Embeddings

## Descripción
Lambda que genera embeddings vectoriales de informes médicos usando Amazon Titan Embeddings v2. Los embeddings se almacenan en Aurora PostgreSQL con pgvector para búsqueda semántica.

## Funcionalidad

### Entrada
La Lambda puede ser invocada de dos formas:

1. **Sin parámetros** (procesa todos los informes sin embeddings):
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
1. Lee informes médicos de Aurora (sin embeddings o específico)
2. Crea texto representativo del informe con:
   - Datos del trabajador
   - Tipo de examen y fecha
   - Datos vitales (presión, peso, altura)
   - Evaluaciones (visión, audiometría)
   - Observaciones
   - Nivel de riesgo y justificación (si existe)
   - Resumen ejecutivo (si existe)
3. Genera embedding con Amazon Titan Embeddings v2 (1024 dimensiones)
4. Guarda embedding en tabla `informes_embeddings` con formato pgvector

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

## Modelo de IA

### Amazon Titan Embeddings v2
- **Model ID:** `amazon.titan-embed-text-v2:0`
- **Dimensiones:** 1024
- **Normalización:** Habilitada (para cosine similarity)
- **Uso:** Generación de embeddings para búsqueda semántica

## Variables de Entorno

- `DB_SECRET_ARN`: ARN del secreto con credenciales de Aurora
- `DB_CLUSTER_ARN`: ARN del cluster Aurora
- `DATABASE_NAME`: Nombre de la base de datos (medical_reports)
- `BUCKET_NAME`: Nombre del bucket S3 (no usado en esta Lambda)

## Dependencias

- `boto3`: SDK de AWS para Python
  - `bedrock-runtime`: Cliente para Amazon Bedrock
  - `rds-data`: Cliente para RDS Data API

## Base de Datos

### Tabla: informes_embeddings
```sql
CREATE TABLE informes_embeddings (
    id SERIAL PRIMARY KEY,
    informe_id INTEGER REFERENCES informes_medicos(id),
    embedding vector(1024),
    fecha_generacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_informes_embeddings_informe ON informes_embeddings(informe_id);
```

### Formato de Embedding
Los embeddings se almacenan como tipo `vector` de pgvector:
```
[0.123, -0.456, 0.789, ...]  -- 1024 valores float
```

## Invocación

### Manual (AWS CLI)
```bash
aws lambda invoke \
  --function-name demo-generate-embeddings \
  --payload '{}' \
  response.json
```

### Procesar informe específico
```bash
aws lambda invoke \
  --function-name demo-generate-embeddings \
  --payload '{"informe_id": 123}' \
  response.json
```

### Desde otra Lambda
```python
import boto3
import json

lambda_client = boto3.client('lambda')

response = lambda_client.invoke(
    FunctionName='demo-generate-embeddings',
    InvocationType='Event',  # Asíncrono
    Payload=json.dumps({})
)
```

## Casos de Uso

1. **Procesamiento Batch:** Generar embeddings para todos los informes existentes
2. **Procesamiento Incremental:** Generar embedding para un nuevo informe
3. **Re-generación:** Actualizar embeddings cuando cambia el contenido del informe

## Integración con RAG

Los embeddings generados se usan para:
- Búsqueda semántica de informes similares
- Contexto histórico para clasificación de riesgo
- Análisis de tendencias en resúmenes ejecutivos

Ver `lambda/shared/similarity_search.py` para funciones de búsqueda.

## Logs

La Lambda registra:
- Número de informes procesados
- Dimensiones del embedding generado
- Errores en generación o almacenamiento
- IDs de informes procesados exitosamente

## Timeout y Memoria

- **Timeout:** 5 minutos (configurado en CDK)
- **Memoria:** 1024 MB (configurado en CDK)
- **Procesamiento:** ~100 informes por invocación (límite en query)

## Permisos IAM

La Lambda requiere:
- `bedrock:InvokeModel` para Titan Embeddings
- `secretsmanager:GetSecretValue` para credenciales de Aurora
- `rds-data:ExecuteStatement` para operaciones en Aurora
- `rds-data:BatchExecuteStatement` para operaciones batch
