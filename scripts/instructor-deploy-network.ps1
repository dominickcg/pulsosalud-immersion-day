# ============================================================================
# Script de Despliegue - PulsoSaludNetworkStack (Instructor)
# ============================================================================
# 
# Este script despliega la VPC compartida que será usada por todos los
# participantes del workshop. Solo debe ejecutarse UNA VEZ.
#
# Uso:
#   .\scripts\instructor-deploy-network.ps1
#
# ============================================================================

param(
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
Write-Host " Medical Reports Workshop - Despliegue de Red Compartida" -ForegroundColor $ColorInfo
Write-Host "============================================================================" -ForegroundColor $ColorInfo
Write-Host ""

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
            # Verificar si es error de token expirado
            if ($identity -match "ExpiredToken|expired") {
                Write-Host "⚠ Token expirado. Renovando sesión SSO..." -ForegroundColor $ColorWarning
                
                # Renovar sesión SSO
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
    Write-Host "Verifica que:" -ForegroundColor $ColorWarning
    Write-Host "  1. El perfil '$Profile' esté configurado" -ForegroundColor Gray
    Write-Host "  2. AWS CLI esté instalado" -ForegroundColor Gray
    Write-Host "  3. Tengas acceso a AWS SSO" -ForegroundColor Gray
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
Write-Host "✓ AWS_PROFILE = $Profile" -ForegroundColor $ColorSuccess
Write-Host "✓ AWS_REGION = $Region" -ForegroundColor $ColorSuccess

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
# Verificar dependencias
# ============================================================================
Write-Host ""
Write-Host "🔍 Verificando dependencias..." -ForegroundColor $ColorInfo

# Verificar Node.js
$nodeVersion = node --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Node.js: $nodeVersion" -ForegroundColor $ColorSuccess
}
else {
    Write-Host "❌ Node.js no está instalado" -ForegroundColor $ColorError
    exit 1
}

# Verificar CDK
$cdkVersion = npx cdk --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ AWS CDK: $cdkVersion" -ForegroundColor $ColorSuccess
}
else {
    Write-Host "❌ AWS CDK no está instalado" -ForegroundColor $ColorError
    exit 1
}

# Verificar node_modules
if (-not (Test-Path "node_modules")) {
    Write-Host "⚠ Instalando dependencias de Node.js..." -ForegroundColor $ColorWarning
    npm install
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error instalando dependencias" -ForegroundColor $ColorError
        exit 1
    }
    Write-Host "✓ Dependencias instaladas" -ForegroundColor $ColorSuccess
}
else {
    Write-Host "✓ Dependencias ya instaladas" -ForegroundColor $ColorSuccess
}

# ============================================================================
# Desplegar PulsoSaludNetworkStack
# ============================================================================
Write-Host ""
Write-Host "============================================================================" -ForegroundColor $ColorInfo
Write-Host " Desplegando PulsoSaludNetworkStack" -ForegroundColor $ColorInfo
Write-Host "============================================================================" -ForegroundColor $ColorInfo
Write-Host ""
Write-Host "⚠️  IMPORTANTE: Este stack se despliega UNA SOLA VEZ para todos los participantes" -ForegroundColor $ColorWarning
Write-Host ""
Write-Host "Recursos que se crearán:" -ForegroundColor $ColorInfo
Write-Host "  • VPC con subnets públicas, privadas y aisladas" -ForegroundColor Gray
Write-Host "  • NAT Gateway" -ForegroundColor Gray
Write-Host "  • Internet Gateway" -ForegroundColor Gray
Write-Host "  • Security Groups base" -ForegroundColor Gray
Write-Host ""
Write-Host "Tiempo estimado: ~10 minutos" -ForegroundColor $ColorWarning
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
$startTime = Get-Date

npx cdk deploy PulsoSaludNetworkStack --require-approval never --profile $Profile

$exitCode = $LASTEXITCODE
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "============================================================================" -ForegroundColor $ColorInfo

if ($exitCode -eq 0) {
    Write-Host "✓ PulsoSaludNetworkStack desplegado exitosamente" -ForegroundColor $ColorSuccess
    Write-Host ""
    Write-Host "Tiempo total: $($duration.Minutes) minutos $($duration.Seconds) segundos" -ForegroundColor $ColorInfo
    Write-Host ""
    Write-Host "Próximos pasos:" -ForegroundColor $ColorInfo
    Write-Host "  1. Desplegar LegacyStack para cada participante:" -ForegroundColor Gray
    Write-Host "     .\scripts\instructor-deploy-legacy.ps1 participant-1" -ForegroundColor Gray
    Write-Host "     .\scripts\instructor-deploy-legacy.ps1 participant-2" -ForegroundColor Gray
    Write-Host "     ..." -ForegroundColor Gray
    Write-Host ""
}
else {
    Write-Host "❌ Error desplegando PulsoSaludNetworkStack" -ForegroundColor $ColorError
    Write-Host ""
    Write-Host "Revisa los logs arriba para más detalles" -ForegroundColor $ColorWarning
    Write-Host ""
    exit 1
}

Write-Host "============================================================================" -ForegroundColor $ColorInfo
Write-Host ""
