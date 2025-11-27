# Lambda: Registro de Exámenes

Esta Lambda recibe datos de exámenes médicos desde el API Gateway, los valida, los guarda en Aurora y genera el PDF correspondiente.

## Flujo

1. **Validación**: Verifica que todos los campos requeridos estén presentes
2. **Upsert Trabajador**: Inserta o actualiza el trabajador en la base de datos
3. **Upsert Contratista**: Inserta o actualiza el contratista en la base de datos
4. **Insert Informe**: Crea un nuevo registro de informe médico
5. **Generar PDF**: Invoca la Lambda de generación de PDF

## Request Format

```json
{
  "trabajador": {
    "nombre": "Juan Pérez",
    "documento": "12345678",
    "fecha_nacimiento": "1985-03-15"
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

## Response Format

### Success (200)
```json
{
  "informe_id": 123,
  "pdf_url": "s3://bucket/legacy-reports/2025/01/informe-123.pdf",
  "message": "Informe generado exitosamente"
}
```

### Validation Error (400)
```json
{
  "error": "Validation error",
  "message": "trabajador.nombre is required"
}
```

### Server Error (500)
```json
{
  "error": "Internal server error",
  "message": "Error details..."
}
```

## Environment Variables

- `DB_SECRET_ARN`: ARN del secreto de Secrets Manager con las credenciales de Aurora
- `DB_CLUSTER_ARN`: ARN del cluster Aurora Serverless v2
- `DATABASE_NAME`: Nombre de la base de datos (medical_reports)
- `BUCKET_NAME`: Nombre del bucket S3 para almacenar PDFs

## Permisos IAM Requeridos

- `secretsmanager:GetSecretValue` - Para leer credenciales de Aurora
- `rds-data:ExecuteStatement` - Para ejecutar queries en Aurora
- `lambda:InvokeFunction` - Para invocar la Lambda de generación de PDF

## Testing

```bash
# Test local con evento de ejemplo
python -c "import index; print(index.handler({'body': '{...}'}, None))"
```

## Notas

- Usa RDS Data API para conectarse a Aurora (no requiere VPC endpoint)
- Los trabajadores y contratistas se insertan con upsert (INSERT si no existe, SELECT si existe)
- La generación de PDF se invoca de forma síncrona para retornar la URL en la respuesta
