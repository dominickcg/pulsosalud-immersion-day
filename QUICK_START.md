# 🚀 Quick Start - PulsoSalud Immersion Day

## ✅ Estado del Despliegue

Todos los stacks están desplegados exitosamente:

- ✅ Sistema Legacy (API + Aurora + Lambdas)
- ✅ Sistema de Extracción con IA
- ✅ Sistema RAG con Embeddings
- ✅ Sistema de Clasificación de Riesgo
- ✅ Sistema de Generación de Resúmenes
- ✅ Sistema de Emails Personalizados

## 📊 Base de Datos Inicializada

La base de datos PostgreSQL con pgvector está lista con todas las tablas creadas.

## 🎯 Cómo Empezar a Usar el Sistema

### Opción 1: Usar la Consola de AWS

#### 1. Crear un Trabajador Manualmente

Usa el RDS Query Editor en la consola de AWS:

```sql
INSERT INTO trabajadores (nombre, documento, fecha_nacimiento, edad, genero, puesto, cargo)
VALUES ('Juan Pérez', '12345678', '1990-01-15', 33, 'Masculino', 'Operario', 'Operario de Planta');
```

#### 2. Crear un Contratista

```sql
INSERT INTO contratistas (nombre, ruc, email, telefono)
VALUES ('Empresa Demo S.A.', '20123456789', 'contacto@empresademo.com', '+51 999 888 777');
```

#### 3. Crear un Informe Médico

```sql
INSERT INTO informes_medicos (
    trabajador_id, 
    contratista_id, 
    tipo_examen, 
    fecha_examen,
    presion_arterial,
    frecuencia_cardiaca,
    temperatura,
    peso,
    altura,
    imc,
    observaciones
)
VALUES (
    1,  -- ID del trabajador creado
    1,  -- ID del contratista creado
    'Examen Médico Ocupacional Pre-Empleo',
    NOW(),
    '120/80',
    72,
    36.5,
    75.5,
    1.75,
    24.7,
    'Trabajador apto para el puesto'
);
```

### Opción 2: Usar el API Gateway

#### API URL
```
https://2w26wsko7d.execute-api.us-east-2.amazonaws.com/prod
```

#### Registrar un Examen

```powershell
$body = @{
    trabajador = @{
        nombre = "María García"
        documento = "87654321"
        fecha_nacimiento = "1985-05-20"
        edad = 38
        genero = "Femenino"
        puesto = "Supervisora"
        cargo = "Supervisora de Producción"
    }
    contratista = @{
        nombre = "Contratista XYZ"
        ruc = "20987654321"
        email = "info@contratistaxyz.com"
        telefono = "+51 999 777 666"
    }
    examen = @{
        tipo_examen = "Examen Médico Ocupacional Anual"
        fecha_examen = (Get-Date).ToString("yyyy-MM-dd")
        presion_arterial = "118/75"
        frecuencia_cardiaca = 68
        temperatura = 36.3
        peso = 62.0
        altura = 1.65
        observaciones = "Trabajadora en buen estado de salud"
    }
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Method POST -Uri "https://2w26wsko7d.execute-api.us-east-2.amazonaws.com/prod/examenes" -Body $body -ContentType "application/json"
```

### Opción 3: Probar las Lambdas de IA

#### 1. Extraer Datos de un PDF

Primero, sube un PDF a S3:

```powershell
$env:AWS_PROFILE = "pulsosalud-immersion"
aws s3 cp sample_data/informe_alto_riesgo.pdf s3://demo-medical-reports-675544937470/test/ --profile pulsosalud-immersion
```

Luego invoca la Lambda de extracción:

```powershell
$payload = @{
    pdf_s3_key = "test/informe_alto_riesgo.pdf"
} | ConvertTo-Json

aws lambda invoke `
    --function-name demo-extract-pdf `
    --payload $payload `
    --profile pulsosalud-immersion `
    response.json

Get-Content response.json | ConvertFrom-Json
```

#### 2. Generar Embeddings para RAG

```powershell
$payload = @{
    informe_id = 1
    trabajador_id = 1
} | ConvertTo-Json

aws lambda invoke `
    --function-name demo-generate-embeddings `
    --payload $payload `
    --profile pulsosalud-immersion `
    response.json
```

#### 3. Clasificar Riesgo con IA

```powershell
$payload = @{
    informe_id = 1
} | ConvertTo-Json

aws lambda invoke `
    --function-name demo-classify-risk `
    --payload $payload `
    --profile pulsosalud-immersion `
    response.json
```

#### 4. Generar Resumen Ejecutivo

```powershell
$payload = @{
    informe_id = 1
} | ConvertTo-Json

aws lambda invoke `
    --function-name demo-generate-summary `
    --payload $payload `
    --profile pulsosalud-immersion `
    response.json
```

#### 5. Enviar Email Personalizado

```powershell
$payload = @{
    informe_id = 1
} | ConvertTo-Json

aws lambda invoke `
    --function-name demo-send-email `
    --payload $payload `
    --profile pulsosalud-immersion `
    response.json
```

## 🔍 Verificar los Datos

### Ver Informes en la Base de Datos

```sql
SELECT * FROM informes_completos ORDER BY fecha_examen DESC LIMIT 10;
```

### Ver PDFs en S3

```powershell
$env:AWS_PROFILE = "pulsosalud-immersion"
aws s3 ls s3://demo-medical-reports-675544937470/ --recursive --profile pulsosalud-immersion
```

### Ver Logs de las Lambdas

```powershell
aws logs tail /aws/lambda/demo-extract-pdf --follow --profile pulsosalud-immersion
```

## 📚 Recursos Adicionales

- **PARTICIPANT_GUIDE.md**: Guía completa para participantes
- **INSTRUCTOR_GUIDE.md**: Guía para instructores
- **exercises/EXPERIMENTS.md**: Experimentos sugeridos
- **DEPLOYMENT_SUCCESS.md**: Detalles del despliegue

## 🐛 Troubleshooting

### Error: "relation trabajadores does not exist"
Ejecuta el script de inicialización:
```powershell
cd scripts
powershell -ExecutionPolicy Bypass -File init-db-simple.ps1
```

### Error: "ExpiredToken"
Renueva la sesión SSO:
```powershell
aws sso login --profile pulsosalud-immersion
```

### Ver Logs de Errores
```powershell
aws logs tail /aws/lambda/NOMBRE-LAMBDA --follow --profile pulsosalud-immersion
```

## 🎉 ¡Listo!

El sistema está completamente desplegado y listo para usar. Comienza con la Opción 1 para crear datos manualmente, o explora las Lambdas de IA directamente.
