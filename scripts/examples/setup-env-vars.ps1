# Setup Environment Variables for Medical Reports Workshop
# Este script configura las variables de entorno necesarias para interactuar con los recursos AWS

# ============================================================================
# INSTRUCCIONES:
# 1. Reemplaza "participant-X" con tu prefijo asignado (ej: participant-1)
# 2. Ejecuta este script: .\setup-env-vars.ps1
# 3. Las variables estarán disponibles en tu sesión actual de PowerShell
# ============================================================================

# IMPORTANTE: Reemplaza "participant-X" con tu prefijo asignado
$PARTICIPANT_PREFIX = "participant-X"

Write-Host "🔧 Configurando variables de entorno para $PARTICIPANT_PREFIX..." -ForegroundColor Cyan

# Obtener ARN del cluster de Aurora
Write-Host "📊 Obteniendo ARN del cluster Aurora..." -ForegroundColor Yellow
$CLUSTER_ARN = aws cloudformation describe-stacks `
  --stack-name "$PARTICIPANT_PREFIX-MedicalReportsLegacyStack" `
  --query 'Stacks[0].Outputs[?OutputKey==`AuroraClusterArn`].OutputValue' `
  --output text

if ($CLUSTER_ARN) {
    $env:CLUSTER_ARN = $CLUSTER_ARN
    Write-Host "✅ CLUSTER_ARN: $CLUSTER_ARN" -ForegroundColor Green
} else {
    Write-Host "❌ Error: No se pudo obtener CLUSTER_ARN" -ForegroundColor Red
}

# Obtener ARN del secret de Aurora
Write-Host "🔐 Obteniendo ARN del secret..." -ForegroundColor Yellow
$SECRET_ARN = aws cloudformation describe-stacks `
  --stack-name "$PARTICIPANT_PREFIX-MedicalReportsLegacyStack" `
  --query 'Stacks[0].Outputs[?OutputKey==`AuroraSecretArn`].OutputValue' `
  --output text

if ($SECRET_ARN) {
    $env:SECRET_ARN = $SECRET_ARN
    Write-Host "✅ SECRET_ARN: $SECRET_ARN" -ForegroundColor Green
} else {
    Write-Host "❌ Error: No se pudo obtener SECRET_ARN" -ForegroundColor Red
}

# Configurar nombre de la base de datos
$env:DATABASE_NAME = "medical_reports"
Write-Host "✅ DATABASE_NAME: medical_reports" -ForegroundColor Green

# Obtener URL de API Gateway
Write-Host "🌐 Obteniendo URL de API Gateway..." -ForegroundColor Yellow
$API_URL = aws cloudformation describe-stacks `
  --stack-name "$PARTICIPANT_PREFIX-MedicalReportsLegacyStack" `
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' `
  --output text

if ($API_URL) {
    $env:API_GATEWAY_URL = $API_URL
    Write-Host "✅ API_GATEWAY_URL: $API_URL" -ForegroundColor Green
} else {
    Write-Host "❌ Error: No se pudo obtener API_GATEWAY_URL" -ForegroundColor Red
}

# Obtener URL de la App Web
Write-Host "🌐 Obteniendo URL de App Web..." -ForegroundColor Yellow
$WEB_URL = aws cloudformation describe-stacks `
  --stack-name "$PARTICIPANT_PREFIX-MedicalReportsLegacyStack" `
  --query 'Stacks[0].Outputs[?OutputKey==`WebsiteURL`].OutputValue' `
  --output text

if ($WEB_URL) {
    $env:WEBSITE_URL = $WEB_URL
    Write-Host "✅ WEBSITE_URL: $WEB_URL" -ForegroundColor Green
} else {
    Write-Host "❌ Error: No se pudo obtener WEBSITE_URL" -ForegroundColor Red
}

Write-Host ""
Write-Host "✅ Variables de entorno configuradas correctamente!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Variables disponibles:" -ForegroundColor Cyan
Write-Host "   - `$env:CLUSTER_ARN" -ForegroundColor White
Write-Host "   - `$env:SECRET_ARN" -ForegroundColor White
Write-Host "   - `$env:DATABASE_NAME" -ForegroundColor White
Write-Host "   - `$env:API_GATEWAY_URL" -ForegroundColor White
Write-Host "   - `$env:WEBSITE_URL" -ForegroundColor White
Write-Host ""
Write-Host "💡 Tip: Estas variables solo están disponibles en esta sesión de PowerShell" -ForegroundColor Yellow
