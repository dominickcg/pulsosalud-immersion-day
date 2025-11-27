# Script para inicializar la base de datos usando RDS Data API
# No requiere conexión VPN

$env:AWS_PROFILE = "pulsosalud-immersion"

Write-Host "🔧 Inicializando base de datos..." -ForegroundColor Cyan

# Leer el schema SQL
$schemaPath = Join-Path $PSScriptRoot "..\database\schema.sql"
$schema = Get-Content $schemaPath -Raw

# Obtener información de la base de datos
$secretArn = "arn:aws:secretsmanager:us-east-2:675544937470:secret:demo/aurora/credentials-lRoa46"
$clusterArn = "arn:aws:rds:us-east-2:675544937470:cluster:demo-medicalreportslegacysta-auroracluster23d869c0-bwmy2qqe1m2t"
$database = "medical_reports"

Write-Host "📊 Ejecutando schema SQL..." -ForegroundColor Yellow

# Ejecutar el schema usando RDS Data API
$result = aws rds-data execute-statement `
    --resource-arn $clusterArn `
    --secret-arn $secretArn `
    --database $database `
    --sql $schema `
    --profile pulsosalud-immersion

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Schema creado exitosamente!" -ForegroundColor Green
} else {
    Write-Host "❌ Error al crear schema" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Base de datos inicializada correctamente!" -ForegroundColor Green
Write-Host ""
Write-Host "Próximos pasos:" -ForegroundColor Cyan
Write-Host "1. Generar datos de prueba: Invoke-RestMethod -Method POST -Uri 'https://2w26wsko7d.execute-api.us-east-2.amazonaws.com/prod/examenes/generar-prueba' -Body '{}' -ContentType 'application/json'"
Write-Host "2. Ver los datos en la consola de AWS RDS Query Editor"
