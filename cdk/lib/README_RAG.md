# AI RAG Stack

## Descripción
Stack CDK para el sistema RAG (Retrieval-Augmented Generation) con embeddings vectoriales usando Amazon Titan Embeddings y pgvector en Aurora PostgreSQL.

## Componentes

### 1. Lambda Layer: Similarity Search
- **Nombre:** `{participantPrefix}-similarity-search`
- **Propósito:** Funciones compartidas para búsqueda por similitud con pgvector
- **Runtime:** Python 3.11
- **Ubicación:** `lambda/shared/`

### 2. Lambda: Generate Embeddings
- **Nombre:** `{participantPrefix}-generate-embeddings`
- **Propósito:** Generar embeddings vectoriales de informes médicos usando Amazon Titan Embeddings
- **Runtime:** Python 3.11
- **Timeout:** 5 minutos
- **Memoria:** 1024 MB
- **Handler:** `index.handler`

## Permisos IAM

### Bedrock
- `bedrock:InvokeModel` para Amazon Titan Embeddings v2

### Aurora PostgreSQL
- `secretsmanager:GetSecretValue` para credenciales
- `rds-data:ExecuteStatement` para operaciones en la base de datos
- `rds-data:BatchExecuteStatement` para operaciones batch

## Variables de Entorno

Todas las Lambdas reciben:
- `DB_SECRET_ARN`: ARN del secreto con credenciales de Aurora
- `DB_CLUSTER_ARN`: ARN del cluster Aurora
- `DATABASE_NAME`: Nombre de la base de datos (medical_reports)
- `BUCKET_NAME`: Nombre del bucket S3

## Integración con Otros Stacks

Este stack reutiliza recursos del **LegacyStack**:
- VPC (importada por ID)
- Aurora Serverless v2 (acceso vía ARN)
- S3 Bucket (referencia)

## Outputs

- `GenerateEmbeddingsLambdaArn`: ARN de la Lambda de embeddings
- `GenerateEmbeddingsLambdaName`: Nombre de la Lambda
- `SimilaritySearchLayerArn`: ARN del Lambda Layer compartido

## Despliegue

```bash
# Desplegar solo este stack
cdk deploy {participantPrefix}-AIRAGStack

# Desplegar con prefijo personalizado
cdk deploy demo-AIRAGStack -c participantPrefix=demo
```

## Flujo de Trabajo

1. **Generación de Embeddings:**
   - Lambda lee informes de Aurora
   - Invoca Amazon Titan Embeddings para generar vectores
   - Guarda embeddings en tabla `informes_embeddings` (pgvector)

2. **Búsqueda por Similitud:**
   - Funciones en el Lambda Layer permiten búsqueda semántica
   - Usa operador `<=>` de pgvector para cosine similarity
   - Filtra por `trabajador_id` para contexto personalizado
   - Retorna top 3 informes más similares

## Requisitos

- Aurora PostgreSQL con extensión `pgvector` habilitada
- Tabla `informes_embeddings` creada (ver `database/schema.sql`)
- Acceso a Amazon Bedrock (Titan Embeddings v2)
