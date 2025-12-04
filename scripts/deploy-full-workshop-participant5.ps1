# ============================================================================
# Script de Despliegue Completo - Workshop Día 1 + Día 2
# ============================================================================
# 
# Este script despliega toda la infraestructura necesaria para participant-5:
#   1. LegacyStack (Aurora, S3, API Gateway, App Web)
#   2. AI Stacks Día 1 (Classification, Summary)
#   3. AI Stacks Día 2 (RAG, Email)
#
# Uso:
#   .\scripts\deploy-full-workshop-participant5.ps1 tu-email@example.com
#
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$VerifiedEmail,
    
    [string]$ParticipantPrefix = "participant-5",
    [string]$Profile = "pulsosalud-immersion",
    [string]$Region = "us-east-2"
)

$ColorSuccess = "Green"
$ColorError = "Red"
$ColorWarning = "Yellow"
$ColorInfo = "Cyan"
$ColorHighlight = "Magenta"

Write-Host ""
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host " Despliegue Completo del Workshop - $ParticipantPrefix" -ForegroundColor $ColorHighlight
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host ""
Write-Host "Este script desplegará:" -ForegroundColor $ColorInfo
Write-Host "  1. LegacyStack (Aurora, S3, API Gateway, App Web)" -ForegroundColor Gray
Write-Host "  2. AI Stacks Día 1 (Classification, Summary)" -ForegroundColor Gray
Write-Host "  3. AI Stacks Día 2 (RAG, Email)" -ForegroundColor Gray
Write-Host ""
Write-Host "Tiempo estimado total: ~25-30 minutos" -ForegroundColor $ColorWarning
Write-Host ""

$confirmation = Read-Host "¿Deseas continuar? (s/n)"
if ($confirmation -ne "s" -and $confirmation -ne "S") {
    Write-Host "Despliegue cancelado" -ForegroundColor $ColorWarning
    exit 0
}

# Configurar variables de entorno
$env:AWS_PROFILE = $Profile
$env:AWS_REGION = $Region
$env:PARTICIPANT_PREFIX = $ParticipantPrefix
$env:VERIFIED_EMAIL = $VerifiedEmail

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath

# ============================================================================
# Paso 1: Desplegar LegacyStack
# ============================================================================
Write-Host ""
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host " Paso 1/3: Desplegando LegacyStack" -ForegroundColor $ColorHighlight
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host ""

$legacyScript = Join-Path $scriptPath "instructor-deploy-legacy.ps1"
& $legacyScript -ParticipantPrefix $ParticipantPrefix -Profile $Profile -Region $Region

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Error desplegando LegacyStack" -ForegroundColor $ColorError
    exit 1
}

Write-Host ""
Write-Host "Esperando 30 segundos para que los recursos se estabilicen..." -ForegroundColor $ColorInfo
Start-Sleep -Seconds 30

# ============================================================================
# Paso 2: Desplegar AI Stacks Día 1
# ============================================================================
Write-Host ""
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host " Paso 2/3: Desplegando AI Stacks Día 1" -ForegroundColor $ColorHighlight
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host ""

$day1Script = Join-Path $scriptPath "participant-deploy-day1.ps1"

# Ejecutar sin confirmación interactiva
$env:AWS_PROFILE = $Profile
Set-Location (Join-Path $projectRoot "cdk")

Write-Host "Desplegando AIClassificationStack y AISummaryStack..." -ForegroundColor $ColorInfo
Write-Host ""

$classificationStack = "$ParticipantPrefix-AIClassificationStack"
$summaryStack = "$ParticipantPrefix-AISummaryStack"

$startTime = Get-Date
npx cdk deploy $classificationStack $summaryStack --require-approval never --profile $Profile
$exitCode = $LASTEXITCODE
$endTime = Get-Date
$duration = $endTime - $startTime

if ($exitCode -ne 0) {
    Write-Host ""
    Write-Host "Error desplegando AI Stacks Día 1" -ForegroundColor $ColorError
    exit 1
}

Write-Host ""
Write-Host "AI Stacks Día 1 desplegados exitosamente" -ForegroundColor $ColorSuccess
Write-Host "Tiempo: $($duration.Minutes) min $($duration.Seconds) seg" -ForegroundColor $ColorInfo

Write-Host ""
Write-Host "Esperando 15 segundos para que los recursos se estabilicen..." -ForegroundColor $ColorInfo
Start-Sleep -Seconds 15

# ============================================================================
# Paso 3: Desplegar AI Stacks Día 2
# ============================================================================
Write-Host ""
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host " Paso 3/3: Desplegando AI Stacks Día 2" -ForegroundColor $ColorHighlight
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host ""

Write-Host "Desplegando AIRAGStack y AIEmailStack..." -ForegroundColor $ColorInfo
Write-Host ""

$ragStack = "$ParticipantPrefix-AIRAGStack"
$emailStack = "$ParticipantPrefix-AIEmailStack"

$startTime = Get-Date
npx cdk deploy $ragStack $emailStack --require-approval never --profile $Profile --context verifiedEmail=$VerifiedEmail
$exitCode = $LASTEXITCODE
$endTime = Get-Date
$duration = $endTime - $startTime

if ($exitCode -ne 0) {
    Write-Host ""
    Write-Host "Error desplegando AI Stacks Día 2" -ForegroundColor $ColorError
    exit 1
}

Write-Host ""
Write-Host "AI Stacks Día 2 desplegados exitosamente" -ForegroundColor $ColorSuccess
Write-Host "Tiempo: $($duration.Minutes) min $($duration.Seconds) seg" -ForegroundColor $ColorInfo

# Verificar que el tiempo fue menor a 8 minutos
if ($duration.TotalMinutes -le 8) {
    Write-Host "Tiempo objetivo cumplido (<8 minutos)" -ForegroundColor $ColorSuccess
}
else {
    Write-Host "Tiempo excedió el objetivo de 8 minutos" -ForegroundColor $ColorWarning
}

# ============================================================================
# Resumen Final
# ============================================================================
Write-Host ""
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host " Despliegue Completo Exitoso" -ForegroundColor $ColorHighlight
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host ""

# Obtener información de los stacks
Set-Location (Join-Path $projectRoot "cdk")

$legacyStackName = "$ParticipantPrefix-MedicalReportsLegacyStack"
$legacyInfo = aws cloudformation describe-stacks --stack-name $legacyStackName --profile $Profile | ConvertFrom-Json
$legacyOutputs = $legacyInfo.Stacks[0].Outputs

$apiUrl = ($legacyOutputs | Where-Object { $_.OutputKey -eq "ApiUrl" }).OutputValue
$appWebUrl = ($legacyOutputs | Where-Object { $_.OutputKey -eq "AppWebUrl" }).OutputValue

Write-Host "Recursos desplegados para $ParticipantPrefix :" -ForegroundColor $ColorSuccess
Write-Host ""
Write-Host "App Web URL:" -ForegroundColor $ColorInfo
Write-Host "  $appWebUrl" -ForegroundColor White
Write-Host ""
Write-Host "API Gateway URL:" -ForegroundColor $ColorInfo
Write-Host "  $apiUrl" -ForegroundColor White
Write-Host ""

Write-Host "Lambdas desplegadas:" -ForegroundColor $ColorInfo
Write-Host "  Día 1:" -ForegroundColor Gray
Write-Host "    - $ParticipantPrefix-classify-risk" -ForegroundColor White
Write-Host "    - $ParticipantPrefix-generate-summary" -ForegroundColor White
Write-Host "  Día 2:" -ForegroundColor Gray
Write-Host "    - $ParticipantPrefix-generate-embeddings" -ForegroundColor White
Write-Host "    - $ParticipantPrefix-send-email" -ForegroundColor White
Write-Host ""

Write-Host "Próximos pasos:" -ForegroundColor $ColorHighlight
Write-Host "  1. Ejecutar verificación:" -ForegroundColor Gray
Write-Host "     .\scripts\verify-day2-deployment.ps1 $ParticipantPrefix" -ForegroundColor White
Write-Host ""
Write-Host "  2. Probar funcionalidad Día 1:" -ForegroundColor Gray
Write-Host "     - Abrir App Web: $appWebUrl" -ForegroundColor White
Write-Host "     - Clasificar un informe" -ForegroundColor White
Write-Host "     - Generar un resumen" -ForegroundColor White
Write-Host ""
Write-Host "  3. Probar funcionalidad Día 2:" -ForegroundColor Gray
Write-Host "     .\scripts\examples\invoke-embeddings.ps1" -ForegroundColor White
Write-Host "     .\scripts\examples\test-similarity-search.ps1" -ForegroundColor White
Write-Host "     .\scripts\examples\invoke-email.ps1" -ForegroundColor White
Write-Host ""

Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host ""

Set-Location $projectRoot
