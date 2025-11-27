# ============================================================================
# Script: Despliegue de SharedNetworkStack
# Proposito: Desplegar la VPC compartida para todos los participantes del workshop
# Quien: Instructor
# Cuando: Una sola vez antes del workshop
# Tiempo estimado: ~8 minutos
# ============================================================================

param(
    [string]$Profile = "pulsosalud-immersion",
    [string]$Region = "us-east-2"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  Despliegue de SharedNetworkStack - VPC Compartida" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "cdk/bin/app.ts")) {
    Write-Host "[ERROR] Este script debe ejecutarse desde la raiz del proyecto" -ForegroundColor Red
    Write-Host "   Directorio actual: $PWD" -ForegroundColor Yellow
    exit 1
}

# Configurar variables de entorno
$env:DEPLOY_MODE = "network"
$env:AWS_PROFILE = $Profile
$env:CDK_DEFAULT_REGION = $Region

Write-Host "[CONFIG] Configuracion:" -ForegroundColor Green
Write-Host "   - Modo de despliegue: $env:DEPLOY_MODE" -ForegroundColor White
Write-Host "   - Perfil AWS: $Profile" -ForegroundColor White
Write-Host "   - Region: $Region" -ForegroundColor White
Write-Host ""

# Verificar sesion AWS
Write-Host "[AWS] Verificando sesion AWS..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --profile $Profile 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($identity -match "ExpiredToken") {
            Write-Host "[WARN] Token expirado. Renovando sesion SSO..." -ForegroundColor Yellow
            aws sso login --profile $Profile
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[ERROR] No se pudo renovar la sesion SSO" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "[ERROR] No se pudo verificar la identidad AWS" -ForegroundColor Red
            Write-Host $identity -ForegroundColor Red
            exit 1
        }
    }
    
    $identityJson = $identity | ConvertFrom-Json
    Write-Host "[OK] Sesion AWS verificada" -ForegroundColor Green
    Write-Host "   - Account: $($identityJson.Account)" -ForegroundColor White
    Write-Host "   - User: $($identityJson.Arn)" -ForegroundColor White
    Write-Host ""
} catch {
    Write-Host "[ERROR] No se pudo verificar la sesion AWS" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Verificar si el stack ya existe
Write-Host "[CHECK] Verificando si SharedNetworkStack ya existe..." -ForegroundColor Yellow
$stackExists = $false
try {
    $stackInfo = aws cloudformation describe-stacks --stack-name SharedNetworkStack --profile $Profile --region $Region 2>&1
    if ($LASTEXITCODE -eq 0) {
        $stackExists = $true
        $stackJson = $stackInfo | ConvertFrom-Json
        $stackStatus = $stackJson.Stacks[0].StackStatus
        Write-Host "[WARN] SharedNetworkStack ya existe con estado: $stackStatus" -ForegroundColor Yellow
        
        if ($stackStatus -match "COMPLETE") {
            Write-Host ""
            $response = Read-Host "Desea actualizar el stack existente? (s/n)"
            if ($response -ne "s" -and $response -ne "S") {
                Write-Host "[CANCEL] Operacion cancelada por el usuario" -ForegroundColor Yellow
                exit 0
            }
        }
    }
} catch {
    # Stack no existe, continuar con el despliegue
}

Write-Host ""
Write-Host "[DEPLOY] Iniciando despliegue de SharedNetworkStack..." -ForegroundColor Green
Write-Host "   Tiempo estimado: ~8 minutos" -ForegroundColor White
Write-Host ""

# Cambiar al directorio CDK
Push-Location cdk

try {
    # Compilar el proyecto
    Write-Host "[BUILD] Compilando proyecto TypeScript..." -ForegroundColor Yellow
    npm run build
    if ($LASTEXITCODE -ne 0) {
        throw "Error al compilar el proyecto"
    }
    Write-Host "[OK] Compilacion exitosa" -ForegroundColor Green
    Write-Host ""

    # Desplegar el stack
    Write-Host "[CDK] Desplegando SharedNetworkStack..." -ForegroundColor Yellow
    $startTime = Get-Date
    
    cdk deploy SharedNetworkStack --require-approval never --profile $Profile
    
    if ($LASTEXITCODE -ne 0) {
        throw "Error al desplegar SharedNetworkStack"
    }
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host "  [SUCCESS] SharedNetworkStack desplegado exitosamente" -ForegroundColor Green
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "[TIME] Tiempo de despliegue: $($duration.Minutes) minutos $($duration.Seconds) segundos" -ForegroundColor White
    Write-Host ""
    
    # Obtener outputs del stack
    Write-Host "[OUTPUTS] Outputs del stack:" -ForegroundColor Cyan
    Write-Host ""
    
    $outputs = aws cloudformation describe-stacks --stack-name SharedNetworkStack --profile $Profile --region $Region --query "Stacks[0].Outputs" --output json | ConvertFrom-Json
    
    foreach ($output in $outputs) {
        Write-Host "   $($output.OutputKey):" -ForegroundColor Yellow
        Write-Host "      $($output.OutputValue)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "[NEXT] Proximos pasos:" -ForegroundColor Cyan
    Write-Host "   1. Desplegar LegacyStacks para cada participante:" -ForegroundColor White
    Write-Host "      .\scripts\instructor-deploy-legacy.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   2. O desplegar para un participante especifico:" -ForegroundColor White
    Write-Host "      `$env:DEPLOY_MODE = 'legacy'" -ForegroundColor Gray
    Write-Host "      `$env:PARTICIPANT_PREFIX = 'participant-juan'" -ForegroundColor Gray
    Write-Host "      cd cdk" -ForegroundColor Gray
    Write-Host "      cdk deploy participant-juan-MedicalReportsLegacyStack" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Red
    Write-Host "  [ERROR] ERROR durante el despliegue" -ForegroundColor Red
    Write-Host "============================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

Write-Host "[OK] Script completado exitosamente" -ForegroundColor Green
Write-Host ""
