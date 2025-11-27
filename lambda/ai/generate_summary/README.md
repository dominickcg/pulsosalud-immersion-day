# Lambda: Generate Summary

## Descripción
Lambda que genera resúmenes ejecutivos de informes médicos usando Amazon Nova Pro con contexto histórico (RAG). Crea resúmenes de máximo 150 palabras en lenguaje claro y no técnico.

## Funcionalidad

### Entrada
```json
// Procesar todos los informes sin resumen
{}

// Procesar informe específico
{"informe_id": 123}
```

### Proceso
1. Lee informes clasificados sin resumen de Aurora
2. Obtiene contexto histórico (últimos 5 informes)
3. Construye prompt con contexto + informe actual
4. Invoca Amazon Nova Pro (temperature: 0.5)
5. Genera resumen ejecutivo (máx 150 palabras)
6. Actualiza Aurora con resumen

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

## Características del Resumen

### Requisitos
- **Longitud:** Máximo 150 palabras
- **Lenguaje:** Claro y no técnico
- **Audiencia:** Gerentes de RRHH, no médicos
- **Contenido:**
  - Hallazgos principales
  - Análisis de tendencias (si hay historial)
  - Nivel de riesgo explicado
  - Recomendaciones breves

### Ejemplo de Resumen
```
El trabajador Juan Pérez completó su examen ocupacional general. 
Los resultados muestran parámetros vitales dentro de rangos normales: 
presión arterial 118/78, peso saludable (IMC 23.5), visión y audición 
normales. Comparado con exámenes anteriores, se observa estabilidad 
consistente en todos los indicadores de salud. El nivel de riesgo es 
BAJO, lo que indica excelente condición física para continuar con sus 
actividades laborales sin restricciones. Se recomienda mantener hábitos 
saludables y realizar el próximo examen según calendario regular.
```

## Modelo de IA

### Amazon Nova Pro
- **Model ID:** `amazon.nova-pro-v1:0`
- **Temperature:** 0.5 (más creativo que clasificación)
- **Max Tokens:** 500
- **Uso:** Generación de texto claro y conciso

## Variables de Entorno
- `DB_SECRET_ARN`: ARN del secreto de Aurora
- `DB_CLUSTER_ARN`: ARN del cluster Aurora
- `DATABASE_NAME`: medical_reports
- `BUCKET_NAME`: Bucket S3

## Integración RAG
```python
from similarity_search import get_historical_context, format_context_for_prompt

# Obtener últimos 5 informes
historical = get_historical_context(
    trabajador_id=trabajador_id,
    current_informe_id=informe_id,
    limit=5
)

# Formatear para prompt
context_text = format_context_for_prompt(historical)
```

## Invocación

### Manual
```bash
aws lambda invoke \
  --function-name demo-generate-summary \
  --payload '{}' \
  response.json
```

### Desde otra Lambda
```python
lambda_client.invoke(
    FunctionName='demo-generate-summary',
    InvocationType='Event',
    Payload=json.dumps({'informe_id': informe_id})
)
```

## Flujo de Trabajo

### Después de Clasificación
```python
# 1. Clasificar riesgo
classify_risk(informe_id)

# 2. Generar resumen
generate_summary(informe_id)

# 3. Enviar email
send_email(informe_id)
```

## Base de Datos
```sql
UPDATE informes_medicos
SET resumen_ejecutivo = :summary,
    updated_at = CURRENT_TIMESTAMP
WHERE id = :informe_id
```

## Permisos IAM
- `bedrock:InvokeModel` para Nova Pro
- `secretsmanager:GetSecretValue`
- `rds-data:ExecuteStatement`

## Timeout y Memoria
- **Timeout:** 5 minutos
- **Memoria:** 1024 MB
- **Procesamiento:** ~50 informes por invocación
