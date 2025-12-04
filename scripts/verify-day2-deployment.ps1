# ============================================================================
# Script de Verificación - Despliegue Completo Día 2
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$ParticipantPrefix,
    
    [string]$Profile = "pulsosalud-immersion",
    [string]$Region = "us-east-2"
)

$ColorSuccess = "Green"
$ColorError = "Red"
$ColorWarning = "Yellow"
$ColorInfo = "Cyan"
$ColorHighlight = "Magenta"

$script:FailedChecks = 0
$script:PassedChecks = 0

Write-Host ""
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host " Verificación de Despliegue Completo - Día 2" -ForegroundColor $ColorHighlight
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host ""
Write-Host "Participante: $ParticipantPrefix" -ForegroundColor $ColorInfo
Write-Host "Perfil AWS: $Profile" -ForegroundColor $ColorInfo
Write-Host "Región: $Region" -ForegroundColor $ColorInfo
Write-Host ""

# Verificar sesión AWS
Write-Host "1. Verificando Sesión AWS" -ForegroundColor $ColorHighlight
Write-Host ""

$identity = aws sts get-caller-identity --profile $Profile 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Token expirado. Renovando sesión SSO..." -ForegroundColor $ColorWarning
    aws sso login --profile $Profile
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error estableciendo sesión con AWS" -ForegroundColor $ColorError
        exit 1
    }
    
    $identity = aws sts get-caller-identity --profile $Profile | ConvertFrom-Json
}
else {
    $identity = $identity | ConvertFrom-Json
}

$env:AWS_PROFILE = $Profile
$env:AWS_REGION = $Region

Write-Host "Sesión activa" -ForegroundColor $ColorSuccess
Write-Host "  Account: $($identity.Account)" -ForegroundColor Gray
Write-Host ""

# Verificar Stacks
Write-Host "2. Verificando CloudFormation Stacks" -ForegroundColor $ColorHighlight
Write-Host ""

$stacks = @(
    @{Name = "$ParticipantPrefix-MedicalReportsLegacyStack"; Desc = "LegacyStack"},
    @{Name = "$ParticipantPrefix-AIClassificationStack"; Desc = "AIClassificationStack (Día 1)"},
    @{Name = "$ParticipantPrefix-AISummaryStack"; Desc = "AISummaryStack (Día 1)"},
    @{Name = "$ParticipantPrefix-AIRAGStack"; Desc = "AIRAGStack (Día 2)"},
    @{Name = "$ParticipantPrefix-AIEmailStack"; Desc = "AIEmailStack (Día 2)"}
)

foreach ($stack in $stacks) {
    Write-Host "  Verificando $($stack.Desc)..." -ForegroundColor Gray
    
    $result = aws cloudformation describe-stacks --stack-name $stack.Name --profile $Profile 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        $stackObj = $result | ConvertFrom-Json
        $status = $stackObj.Stacks[0].StackStatus
        
        if ($status -eq "CREATE_COMPLETE" -or $status -eq "UPDATE_COMPLETE") {
            Write-Host "    OK - $($stack.Desc) desplegado" -ForegroundColor $ColorSuccess
            $script:PassedChecks++
        }
        else {
            Write-Host "    ERROR - $($stack.Desc) en estado: $status" -ForegroundColor $ColorError
            $script:FailedChecks++
        }
    }
    else {
        Write-Host "    ERROR - $($stack.Desc) no encontrado" -ForegroundColor $ColorError
        $script:FailedChecks++
    }
}

Write-Host ""

# Verificar Lambdas
Write-Host "3. Verificando Lambdas" -ForegroundColor $ColorHighlight
Write-Host ""

$lambdas = @(
    "$ParticipantPrefix-classify-risk",
    "$ParticipantPrefix-generate-summary",
    "$ParticipantPrefix-generate-embeddings",
    "$ParticipantPrefix-send-email",
    "$ParticipantPrefix-register-exam",
    "$ParticipantPrefix-list-informes"
)

foreach ($lambda in $lambdas) {
    Write-Host "  Verificando Lambda: $lambda..." -ForegroundColor Gray
    
    $result = aws lambda get-function --function-name $lambda --profile $Profile 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    OK - Lambda existe" -ForegroundColor $ColorSuccess
        $script:PassedChecks++
    }
    else {
        Write-Host "    ERROR - Lambda no encontrada" -ForegroundColor $ColorError
        $script:FailedChecks++
    }
}

Write-Host ""

# Verificar S3 Buckets
Write-Host "4. Verificando S3 Buckets" -ForegroundColor $ColorHighlight
Write-Host ""

$buckets = aws s3 ls --profile $Profile | Select-String $ParticipantPrefix

if ($buckets) {
    $bucketCount = ($buckets | Measure-Object).Count
    Write-Host "  OK - Encontrados $bucketCount buckets para $ParticipantPrefix" -ForegroundColor $ColorSuccess
    $script:PassedChecks++
}
else {
    Write-Host "  ERROR - No se encontraron buckets para $ParticipantPrefix" -ForegroundColor $ColorError
    $script:FailedChecks++
}

Write-Host ""

# Resumen
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host "Resumen de Verificación" -ForegroundColor $ColorHighlight
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host ""

$totalChecks = $script:PassedChecks + $script:FailedChecks
$successRate = if ($totalChecks -gt 0) { [math]::Round(($script:PassedChecks / $totalChecks) * 100, 2) } else { 0 }

Write-Host "  Total de verificaciones: $totalChecks" -ForegroundColor $ColorInfo
Write-Host "  Exitosas: $script:PassedChecks" -ForegroundColor $ColorSuccess
Write-Host "  Fallidas: $script:FailedChecks" -ForegroundColor $ColorError
Write-Host "  Tasa de éxito: $successRate%" -ForegroundColor $ColorInfo
Write-Host ""

if ($script:FailedChecks -eq 0) {
    Write-Host "Todas las verificaciones pasaron exitosamente!" -ForegroundColor $ColorSuccess
    Write-Host ""
    Write-Host "Próximos pasos:" -ForegroundColor $ColorInfo
    Write-Host "  1. Probar generación de embeddings" -ForegroundColor Gray
    Write-Host "  2. Probar búsqueda de similitud" -ForegroundColor Gray
    Write-Host "  3. Probar envío de emails" -ForegroundColor Gray
    Write-Host ""
    exit 0
}
else {
    Write-Host "Algunas verificaciones fallaron" -ForegroundColor $ColorWarning
    Write-Host ""
    Write-Host "Revisa los errores arriba y corrige los problemas antes de continuar." -ForegroundColor $ColorWarning
    Write-Host ""
    exit 1
}
