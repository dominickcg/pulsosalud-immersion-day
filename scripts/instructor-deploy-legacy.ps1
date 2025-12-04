# ============================================================================
# Script de Despliegue - LegacyStack por Participante (Instructor)
# ============================================================================
# 
# Este script despliega el LegacyStack para un participante específico.
# Incluye: Aurora, S3, API Gateway, App Web, Lambdas legacy y datos de ejemplo.
#
# Uso:
#   .\scripts\instructor-deploy-legacy.ps1 participant-1
#   .\scripts\instructor-deploy-legacy.ps1 participant-2
#   ...
#
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$ParticipantPrefix,
    
    [string]$Profile = "pulsosalud-immersion",
    [string]$Region = "us-east-2"
)

# Colores para output
$ColorSuccess = "Green"
$ColorError = "Red"
$ColorWarning = "Yellow"
$ColorInfo = "Cyan"

Write-Host ""
Write-Host "============================================================================" -ForegroundColor $ColorInfo
Write-Host " Medical Reports Workshop - Despliegue de LegacyStack" -ForegroundColor $ColorInfo
Write-Host "============================================================================" -ForegroundColor $ColorInfo
Write-Host ""
Write-Host "Participante: $ParticipantPrefix" -ForegroundColor $ColorInfo
Write-Host ""

# ============================================================================
# Validar nombre de participante
# ============================================================================
if ($ParticipantPrefix -notmatch '^participant-\d+$') {
    Write-Host "❌ Formato de nombre inválido" -ForegroundColor $ColorError
    Write-Host ""
    Write-Host "El nombre debe seguir el formato: participant-N" -ForegroundColor $ColorWarning
    Write-Host "Ejemplos válidos:" -ForegroundColor $ColorInfo
    Write-Host "  • participant-1" -ForegroundColor Gray
    Write-Host "  • participant-2" -ForegroundColor Gray
    Write-Host "  • participant-10" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# ============================================================================
# Función: Verificar y renovar sesión AWS SSO
# ============================================================================
function Test-AwsSession {
    param(
        [string]$ProfileName
    )
    
    Write-Host "🔍 Verificando sesión AWS con perfil: $ProfileName" -ForegroundColor $ColorInfo
    
    try {
        $identity = aws sts get-caller-identity --profile $ProfileName 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $identityObj = $identity | ConvertFrom-Json
            Write-Host "✓ Sesión activa" -ForegroundColor $ColorSuccess
            Write-Host "  Account: $($identityObj.Account)" -ForegroundColor Gray
            Write-Host "  User: $($identityObj.Arn)" -ForegroundColor Gray
            return $true
        }
        else {
            if ($identity -match "ExpiredToken|expired") {
                Write-Host "⚠ Token expirado. Renovando sesión SSO..." -ForegroundColor $ColorWarning
                
                aws sso login --profile $ProfileName
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✓ Sesión renovada exitosamente" -ForegroundColor $ColorSuccess
                    return $true
                }
                else {
                    Write-Host "❌ Error renovando sesión SSO" -ForegroundColor $ColorError
                    return $false
                }
            }
            else {
                Write-Host "❌ Error verificando sesión: $identity" -ForegroundColor $ColorError
                return $false
            }
        }
    }
    catch {
        Write-Host "❌ Error: $_" -ForegroundColor $ColorError
        return $false
    }
}

# ============================================================================
# Verificar sesión AWS
# ============================================================================
if (-not (Test-AwsSession -ProfileName $Profile)) {
    Write-Host ""
    Write-Host "❌ No se pudo establecer sesión con AWS" -ForegroundColor $ColorError
    Write-Host ""
    exit 1
}

# ============================================================================
# Configurar variables de entorno
# ============================================================================
Write-Host ""
Write-Host "⚙️  Configurando variables de entorno..." -ForegroundColor $ColorInfo
$env:AWS_PROFILE = $Profile
$env:AWS_REGION = $Region
$env:PARTICIPANT_PREFIX = $ParticipantPrefix
Write-Host "✓ AWS_PROFILE = $Profile" -ForegroundColor $ColorSuccess
Write-Host "✓ AWS_REGION = $Region" -ForegroundColor $ColorSuccess
Write-Host "✓ PARTICIPANT_PREFIX = $ParticipantPrefix" -ForegroundColor $ColorSuccess

# ============================================================================
# Cambiar al directorio CDK
# ============================================================================
Write-Host ""
Write-Host "📁 Cambiando al directorio CDK..." -ForegroundColor $ColorInfo
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$cdkPath = Join-Path $projectRoot "cdk"

if (-not (Test-Path $cdkPath)) {
    Write-Host "❌ No se encontró el directorio CDK: $cdkPath" -ForegroundColor $ColorError
    exit 1
}

Set-Location $cdkPath
Write-Host "✓ Directorio actual: $cdkPath" -ForegroundColor $ColorSuccess

# ============================================================================
# Verificar que SharedNetworkStack existe
# ============================================================================
Write-Host ""
Write-Host "🔍 Verificando que PulsoSaludNetworkStack esté desplegado..." -ForegroundColor $ColorInfo

$networkStack = aws cloudformation describe-stacks --stack-name PulsoSaludNetworkStack --profile $Profile 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ PulsoSaludNetworkStack no está desplegado" -ForegroundColor $ColorError
    Write-Host ""
    Write-Host "Debes desplegar primero el PulsoSaludNetworkStack:" -ForegroundColor $ColorWarning
    Write-Host "  .\scripts\instructor-deploy-network.ps1" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-Host "✓ PulsoSaludNetworkStack encontrado" -ForegroundColor $ColorSuccess

# ============================================================================
# Verificar dependencias
# ============================================================================
Write-Host ""
Write-Host "🔍 Verificando dependencias..." -ForegroundColor $ColorInfo

if (-not (Test-Path "node_modules")) {
    Write-Host "⚠ Instalando dependencias de Node.js..." -ForegroundColor $ColorWarning
    npm install
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error instalando dependencias" -ForegroundColor $ColorError
        exit 1
    }
}

Write-Host "✓ Dependencias verificadas" -ForegroundColor $ColorSuccess

# ============================================================================
# Desplegar LegacyStack
# ============================================================================
Write-Host ""
Write-Host "============================================================================" -ForegroundColor $ColorInfo
Write-Host " Desplegando $ParticipantPrefix-MedicalReportsLegacyStack" -ForegroundColor $ColorInfo
Write-Host "============================================================================" -ForegroundColor $ColorInfo
Write-Host ""
Write-Host "Recursos que se crearán:" -ForegroundColor $ColorInfo
Write-Host "  • Aurora Serverless v2 con datos de ejemplo" -ForegroundColor Gray
Write-Host "  • S3 bucket para PDFs" -ForegroundColor Gray
Write-Host "  • S3 bucket para App Web" -ForegroundColor Gray
Write-Host "  • API Gateway con endpoints" -ForegroundColor Gray
Write-Host "  • Lambdas legacy (register-exam, generate-pdf, list-informes)" -ForegroundColor Gray
Write-Host "  • Custom Resource para inicialización de DB" -ForegroundColor Gray
Write-Host ""
Write-Host "Tiempo estimado: ~15 minutos" -ForegroundColor $ColorWarning
Write-Host ""

# Confirmar con el usuario
$confirmation = Read-Host "¿Deseas continuar? (s/n)"
if ($confirmation -ne "s" -and $confirmation -ne "S") {
    Write-Host "❌ Despliegue cancelado por el usuario" -ForegroundColor $ColorWarning
    exit 0
}

Write-Host ""
Write-Host "🚀 Iniciando despliegue..." -ForegroundColor $ColorInfo
Write-Host ""

# Ejecutar CDK deploy
$stackName = "$ParticipantPrefix-MedicalReportsLegacyStack"
$startTime = Get-Date

npx cdk deploy $stackName --require-approval never --profile $Profile

$exitCode = $LASTEXITCODE
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "============================================================================" -ForegroundColor $ColorInfo

if ($exitCode -eq 0) {
    Write-Host "✓ LegacyStack desplegado exitosamente" -ForegroundColor $ColorSuccess
    Write-Host ""
    Write-Host "Tiempo total: $($duration.Minutes) minutos $($duration.Seconds) segundos" -ForegroundColor $ColorInfo
    Write-Host ""
    
    # ========================================================================
    # Obtener outputs del stack
    # ========================================================================
    Write-Host "📋 Obteniendo información del despliegue..." -ForegroundColor $ColorInfo
    Write-Host ""
    
    $stackInfo = aws cloudformation describe-stacks --stack-name $stackName --profile $Profile | ConvertFrom-Json
    $outputs = $stackInfo.Stacks[0].Outputs
    
    $apiUrl = ($outputs | Where-Object { $_.OutputKey -eq "ApiUrl" }).OutputValue
    $appWebUrl = ($outputs | Where-Object { $_.OutputKey -eq "AppWebUrl" }).OutputValue
    
    Write-Host "Información importante para $ParticipantPrefix :" -ForegroundColor $ColorInfo
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  🌐 App Web URL:" -ForegroundColor $ColorSuccess
    Write-Host "     $appWebUrl" -ForegroundColor White
    Write-Host ""
    Write-Host "  📡 API Gateway URL:" -ForegroundColor $ColorSuccess
    Write-Host "     $apiUrl" -ForegroundColor White
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host ""
    
    # ========================================================================
    # Verificación post-despliegue
    # ========================================================================
    Write-Host "🔍 Verificando despliegue..." -ForegroundColor $ColorInfo
    Write-Host ""
    
    # Verificar que Aurora tiene datos
    Write-Host "  • Verificando base de datos..." -ForegroundColor Gray
    $dbClusterArn = ($outputs | Where-Object { $_.OutputKey -eq "DatabaseClusterArn" }).OutputValue
    $dbSecretArn = ($outputs | Where-Object { $_.OutputKey -eq "DatabaseSecretArn" }).OutputValue
    
    if ($dbClusterArn -and $dbSecretArn) {
        Write-Host "    ✓ Aurora configurado correctamente" -ForegroundColor $ColorSuccess
    }
    else {
        Write-Host "    ⚠ No se pudieron obtener ARNs de Aurora" -ForegroundColor $ColorWarning
    }
    
    # Verificar que App Web está accesible
    Write-Host "  • Verificando App Web..." -ForegroundColor Gray
    try {
        $response = Invoke-WebRequest -Uri $appWebUrl -Method Head -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "    ✓ App Web accesible" -ForegroundColor $ColorSuccess
        }
    }
    catch {
        Write-Host "    ⚠ App Web aún no está disponible (puede tardar unos minutos)" -ForegroundColor $ColorWarning
    }
    
    Write-Host ""
    Write-Host "Próximos pasos:" -ForegroundColor $ColorInfo
    Write-Host "  1. Compartir la URL de la App Web con $ParticipantPrefix" -ForegroundColor Gray
    Write-Host "  2. El participante desplegará los AI Stacks durante el workshop" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Para desplegar el siguiente participante:" -ForegroundColor $ColorInfo
    Write-Host "  .\scripts\instructor-deploy-legacy.ps1 participant-N" -ForegroundColor Gray
    Write-Host ""
}
else {
    Write-Host "❌ Error desplegando LegacyStack" -ForegroundColor $ColorError
    Write-Host ""
    Write-Host "Revisa los logs arriba para más detalles" -ForegroundColor $ColorWarning
    Write-Host ""
    Write-Host "Comandos útiles para debugging:" -ForegroundColor $ColorInfo
    Write-Host "  • Ver eventos del stack:" -ForegroundColor Gray
    Write-Host "    aws cloudformation describe-stack-events --stack-name $stackName --profile $Profile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  • Ver logs de CloudWatch:" -ForegroundColor Gray
    Write-Host "    aws logs tail /aws/lambda/$ParticipantPrefix-init-database --follow --profile $Profile" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-Host "============================================================================" -ForegroundColor $ColorInfo
Write-Host ""
