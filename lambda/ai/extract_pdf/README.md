# Lambda: Extractor de PDFs con IA

Esta Lambda procesa PDFs externos usando Amazon Textract para extraer texto y Amazon Bedrock (Nova Pro) para estructurar los datos.

## Flujo

1. **Trigger S3**: Se activa cuando se sube un PDF a `external-reports/`
2. **Extracción**: Usa Textract para extraer todo el texto del PDF
3. **Estructuración**: Usa Bedrock (Nova Pro) para convertir texto en JSON estructurado
4. **Almacenamiento**: Guarda datos en Aurora con el mismo formato que el sistema legacy

## Trigger

**S3 Event:**
- Bucket: El bucket compartido del sistema
- Prefix: `external-reports/`
- Suffix: `.pdf`
- Event: `s3:ObjectCreated:*`

## Servicios AWS Utilizados

### Amazon Textract
- **Método**: `detect_document_text`
- **Propósito**: Extraer texto de PDFs
- **Output**: Bloques de texto con coordenadas

### Amazon Bedrock (Nova Pro)
- **Modelo**: `amazon.nova-pro-v1:0`
- **Temperatura**: 0.1 (baja para extracción precisa)
- **Max tokens**: 2000
- **Propósito**: Estructurar texto extraído en JSON

### RDS Data API
- **Propósito**: Guardar datos estructurados en Aurora
- **Tablas**: trabajadores, contratistas, informes_medicos

## Formato de Datos Estructurados

```json
{
  "trabajador": {
    "nombre": "Juan Pérez",
    "documento": "12345678"
  },
  "contratista": {
    "nombre": "Constructora ABC",
    "email": "rrhh@constructoraabc.com"
  },
  "examen": {
    "tipo": "Pre-empleo",
    "presion_arterial": "120/80",
    "peso": 75.5,
    "altura": 1.75,
    "vision": "20/20",
    "audiometria": "Normal",
    "observaciones": "Paciente en buen estado general"
  }
}
```

## Prompt para Bedrock

El prompt está diseñado para:
- Extraer información específica del informe médico
- Retornar JSON válido sin texto adicional
- Manejar campos faltantes con valores por defecto
- Ser robusto ante diferentes formatos de PDF

## Manejo de Errores

### Textract
- **PDF corrupto**: Log error, skip file
- **Timeout**: Lambda tiene 5 minutos de timeout
- **No text found**: Log warning, skip file

### Bedrock
- **Invalid JSON**: Intenta limpiar markdown, si falla skip file
- **Rate limit**: Lambda reintentará automáticamente
- **Model error**: Log error, skip file

### Aurora
- **Duplicate documento**: Usa trabajador existente (upsert)
- **Duplicate email**: Usa contratista existente (upsert)
- **Connection error**: Lambda reintentará

## Environment Variables

- `DB_SECRET_ARN`: ARN del secreto de Secrets Manager
- `DB_CLUSTER_ARN`: ARN del cluster Aurora
- `DATABASE_NAME`: Nombre de la base de datos (medical_reports)
- `BUCKET_NAME`: Nombre del bucket S3

## Permisos IAM Requeridos

- `s3:GetObject` - Leer PDFs del bucket
- `textract:DetectDocumentText` - Extraer texto
- `bedrock:InvokeModel` - Invocar Nova Pro
- `secretsmanager:GetSecretValue` - Leer credenciales
- `rds-data:ExecuteStatement` - Ejecutar SQL

## Logging

La Lambda registra:
- Archivo procesado (bucket/key)
- Caracteres extraídos por Textract
- Respuesta de Bedrock (primeros 500 caracteres)
- Datos estructurados completos
- ID del informe creado
- Errores detallados con stack trace

## Testing

### Test Manual

1. Subir un PDF a S3:
```bash
aws s3 cp informe.pdf s3://bucket-name/external-reports/informe.pdf
```

2. Verificar logs en CloudWatch:
```bash
aws logs tail /aws/lambda/demo-extract-pdf --follow
```

3. Verificar en Aurora:
```sql
SELECT * FROM informes_medicos WHERE origen = 'EXTERNO' ORDER BY created_at DESC LIMIT 1;
```

### Test con Evento Simulado

```python
event = {
    "Records": [{
        "s3": {
            "bucket": {"name": "bucket-name"},
            "object": {"key": "external-reports/test.pdf"}
        }
    }]
}
```

## Características

✅ **Extracción robusta**: Textract maneja PDFs escaneados y nativos
✅ **IA Generativa**: Bedrock estructura datos sin reglas hardcodeadas
✅ **Formato consistente**: Mismo schema que sistema legacy
✅ **Upsert pattern**: No duplica trabajadores ni contratistas
✅ **Origen marcado**: Campo `origen='EXTERNO'` para distinguir
✅ **Idempotente**: Procesar el mismo PDF múltiples veces es seguro

## Limitaciones

- Textract tiene límite de 3000 páginas por documento
- Bedrock Nova Pro tiene límite de contexto (usa primeros 4000 caracteres)
- PDFs muy grandes pueden exceder el timeout de 5 minutos
- La calidad de extracción depende de la calidad del PDF

## Mejoras Futuras

- Usar Textract asíncrono para PDFs grandes
- Implementar retry con backoff exponencial
- Agregar validación de datos extraídos
- Guardar texto completo para referencia
- Generar embeddings para RAG
- Clasificar riesgo automáticamente después de extracción

## Ejemplo de Logs

```
Processing file: s3://bucket/external-reports/informe-123.pdf
Extracting text with Textract from s3://bucket/external-reports/informe-123.pdf
Extracted 2543 characters
Structuring data with Bedrock (Amazon Nova Pro)
Bedrock response: {"trabajador":{"nombre":"Juan Pérez","documento":"12345678"}...
Successfully structured data: {...}
Saving structured data to Aurora
Saved to Aurora. Informe ID: 456
Successfully processed PDF. Informe ID: 456
```

## Notas

- La Lambda se ejecuta en VPC para acceder a Aurora
- El timeout es de 5 minutos (Textract puede tardar)
- La memoria es de 1024 MB (suficiente para PDFs grandes)
- Los PDFs permanecen en S3 después del procesamiento
- El campo `pdf_s3_path` apunta al PDF original
