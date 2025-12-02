# AI Classification Stack

## Descripción
Stack CDK para el sistema de clasificación de riesgo con IA. Usa Amazon Nova Pro con contexto histórico (RAG) para clasificar informes médicos en niveles de riesgo: BAJO, MEDIO, ALTO.

## Componentes

### 1. Lambda: Classify Risk
- **Nombre:** `{participantPrefix}-classify-risk`
- **Propósito:** Clasificar informes médicos usando IA con contexto histórico
- **Runtime:** Python 3.11
- **Timeout:** 5 minutos
- **Memoria:** 1024 MB
- **Handler:** `index.handler`

### 2. EventBridge Rule (Opcional)
- **Nombre:** `{participantPrefix}-classification-schedule`
- **Schedule:** Cada hora
- **Estado inicial:** Deshabilitado
- **Propósito:** Trigger automático para procesar informes sin clasificar

## Permisos IAM

### Bedrock
- `bedrock:InvokeModel` para:
  - Amazon Nova Pro (clasificación)
  - Amazon Titan Embeddings v2 (búsqueda RAG)

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

Este stack depende de:

**LegacyStack:**
- VPC (importada por ID)
- Aurora Serverless v2
- S3 Bucket
- Secrets Manager

**AIRAGStack:**
- Lambda Layer de búsqueda por similitud (importado por ARN)
- Funciones de contexto histórico

## Outputs

- `ClassifyRiskLambdaArn`: ARN de la Lambda de clasificación
- `ClassifyRiskLambdaName`: Nombre de la Lambda
- `ClassificationRuleName`: Nombre de la regla EventBridge

## Despliegue

```bash
# Desplegar solo este stack
cdk deploy {participantPrefix}-AIClassificationStack

# Desplegar con prefijo personalizado
cdk deploy demo-AIClassificationStack -c participantPrefix=demo
```

## Flujo de Trabajo

### 1. Invocación Manual
```bash
aws lambda invoke \
  --function-name demo-classify-risk \
  --payload '{}' \
  response.json
```

Procesa todos los informes sin clasificar.

### 2. Invocación para Informe Específico
```bash
aws lambda invoke \
  --function-name demo-classify-risk \
  --payload '{"informe_id": 123}' \
  response.json
```

### 3. Trigger Automático (EventBridge)
```bash
# Habilitar regla
aws events enable-rule --name demo-classification-schedule

# Deshabilitar regla
aws events disable-rule --name demo-classification-schedule
```

## Proceso de Clasificación

```
1. Leer informe sin clasificar de Aurora
   ↓
2. Obtener contexto histórico del trabajador (RAG)
   - Buscar informes anteriores
   - Generar embedding del informe actual
   - Buscar informes similares
   ↓
3. Construir prompt con contexto histórico
   - Incluir informes anteriores
   - Incluir ejemplos (few-shot learning)
   - Incluir informe actual
   ↓
4. Invocar Amazon Nova Pro
   - Temperature: 0.3 (determinístico pero flexible)
   - Respuesta: nivel de riesgo + justificación
   ↓
5. Actualizar Aurora
   - nivel_riesgo: BAJO, MEDIO, ALTO
   - justificacion_riesgo: texto explicativo
   - procesado_por_ia: true
```

## Modelo de IA

### Amazon Nova Pro
- **Model ID:** `amazon.nova-pro-v1:0`
- **Temperature:** 0.3 (balance entre consistencia y flexibilidad)
- **Max Tokens:** 2000
- **Uso:** Clasificación de riesgo con razonamiento

### Prompt Engineering
- **Few-shot learning:** Ejemplos de cada nivel de riesgo
- **Contexto histórico:** Informes anteriores del trabajador
- **Instrucciones claras:** Formato de respuesta estructurado

## Niveles de Riesgo

### BAJO
- Todos los parámetros dentro de rangos normales
- Sin observaciones preocupantes
- Historial estable o mejorando

### MEDIO
- Algunos parámetros fuera de rango normal
- Observaciones que requieren seguimiento
- Cambios moderados respecto al historial

### ALTO
- Múltiples parámetros fuera de rango
- Observaciones críticas
- Deterioro significativo respecto al historial
- Requiere atención inmediata

## Casos de Uso

### 1. Clasificación Batch
Procesar todos los informes pendientes:
```python
# Invocar sin parámetros
lambda_client.invoke(
    FunctionName='demo-classify-risk',
    InvocationType='Event',
    Payload=json.dumps({})
)
```

### 2. Clasificación Individual
Clasificar un informe específico después de su creación:
```python
# Invocar con informe_id
lambda_client.invoke(
    FunctionName='demo-classify-risk',
    InvocationType='RequestResponse',
    Payload=json.dumps({'informe_id': 123})
)
```

### 3. Clasificación Automática
Habilitar EventBridge para procesamiento periódico:
```bash
aws events enable-rule --name demo-classification-schedule
```

## Integración con Workflow

### Después de Extracción
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

### Antes de Resumen
```python
# Clasificar primero
classify_risk(informe_id)

# Luego generar resumen con nivel de riesgo
generate_summary(informe_id)
```

## Logs

La Lambda registra:
- Número de informes procesados
- Nivel de riesgo asignado
- Justificación generada
- Contexto histórico utilizado
- Errores en clasificación

## Monitoreo

### CloudWatch Metrics
- Invocaciones
- Duración
- Errores
- Throttles

### CloudWatch Logs
- Logs detallados de clasificación
- Prompts enviados a Bedrock
- Respuestas de Bedrock
- Errores y excepciones

## Troubleshooting

### Error: "No historical context found"
- Verificar que existan informes anteriores del trabajador
- Verificar que los embeddings estén generados

### Error: "Invalid risk level"
- Revisar prompt de clasificación
- Verificar respuesta de Bedrock
- Ajustar temperature si es necesario

### Error: "Bedrock throttling"
- Reducir frecuencia de EventBridge
- Implementar retry con backoff exponencial
- Solicitar aumento de cuota en AWS

## Optimizaciones

### Performance
- Procesar en batch (múltiples informes por invocación)
- Cachear contexto histórico si es posible
- Usar invocación asíncrona para no bloquear

### Costos
- Ajustar frecuencia de EventBridge según necesidad
- Usar invocación manual para casos urgentes
- Monitorear uso de Bedrock

### Precisión
- Iterar en prompts (v1, v2, v3)
- Ajustar temperature según resultados
- Incluir más ejemplos en few-shot learning
- Refinar criterios de clasificación

## Dependencias

- `boto3`: SDK de AWS
- `similarity_search` (Lambda Layer): Funciones de RAG
- Amazon Nova Pro: Modelo de clasificación
- Amazon Titan Embeddings v2: Para búsqueda RAG
- Aurora PostgreSQL: Base de datos
- pgvector: Búsqueda vectorial

## Requisitos

- Aurora PostgreSQL con pgvector habilitado
- Embeddings generados para informes históricos
- Acceso a Amazon Bedrock (Nova Pro y Titan)
- Lambda Layer de búsqueda por similitud desplegado
