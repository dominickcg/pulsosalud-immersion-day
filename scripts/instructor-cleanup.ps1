# ============================================================================
# Script: Limpieza completa de recursos del workshop
# Propósito: Eliminar todos los stacks desplegados para evitar costos
# Quién: Instructor
# Cuándo: Después del workshop
# Orden: AI Stacks → Legacy Stacks → Network Stack
# ============================================================================

param(
    [string]$ConfigFile = "config/participants.json",
    [string]$Profile = "pulsosalud-immersion",
    [string]$Region = "us-east-2",
    [int]$Concurrency = 5,
    [string[]]$Participants = @(),
    [switch]$SkipConfirmation
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Red
Write-Host "  LIMPIEZA DE RECURSOS DEL WORKSHOP" -ForegroundColor Red
Write-Host "============================================================================" -ForegroundColor Red
Write-Host ""
Write-Host "⚠️  ADVERTENCIA: Este script eliminará TODOS los recursos del workshop" -ForegroundColor Yellow
Write-Host ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "cdk/bin/app.ts")) {
    Write-Host "❌ ERROR: Este script debe ejecutarse desde la raíz del proyecto" -ForegroundColor Red
    Write-Host "   Directorio actual: $PWD" -ForegroundColor Yellow
    exit 1
}

# Configurar variables de entorno
$env:AWS_PROFILE = $Profile
$env:CDK_DEFAULT_REGION = $Region

Write-Host "📋 Configuración:" -ForegroundColor Green
Write-Host "   - Perfil AWS: $Profile" -ForegroundColor White
Write-Host "   - Región: $Region" -ForegroundColor White
Write-Host "   - Concurrencia: $Concurrency stacks en paralelo" -ForegroundColor White
Write-Host ""

# Verificar sesión AWS
Write-Host "🔐 Verificando sesión AWS..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --profile $Profile 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($identity -match "ExpiredToken") {
            Write-Host "⚠️  Token expirado. Renovando sesión SSO..." -ForegroundColor Yellow
            aws sso login --profile $Profile
            if ($LASTEXITCODE -ne 0) {
                Write-Host "❌ ERROR: No se pudo renovar la sesión SSO" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "❌ ERROR: No se pudo verificar la identidad AWS" -ForegroundColor Red
            Write-Host $identity -ForegroundColor Red
            exit 1
        }
    }
    
    $identityJson = $identity | ConvertFrom-Json
    Write-Host "✅ Sesión AWS verificada" -ForegroundColor Green
    Write-Host "   - Account: $($identityJson.Account)" -ForegroundColor White
    Write-Host ""
} catch {
    Write-Host "❌ ERROR: No se pudo verificar la sesión AWS" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Obtener lista de participantes
$participantList = @()

if ($Participants.Count -gt 0) {
    $participantList = $Participants
    Write-Host "📝 Usando participantes especificados en línea de comandos" -ForegroundColor Green
} elseif (Test-Path $ConfigFile) {
    Write-Host "📝 Leyendo lista de participantes desde: $ConfigFile" -ForegroundColor Green
    try {
        $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        $participantList = $config.participants | ForEach-Object { $_.prefix }
    } catch {
        Write-Host "⚠️  No se pudo leer el archivo de configuración" -ForegroundColor Yellow
        Write-Host "   Buscando stacks automáticamente..." -ForegroundColor Yellow
    }
}

# Si no hay participantes, buscar stacks automáticamente
if ($participantList.Count -eq 0) {
    Write-Host "🔍 Buscando stacks del workshop en CloudFormation..." -ForegroundColor Yellow
    try {
        $allStacks = aws cloudformation list-stacks --profile $Profile --region $Region --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --output json | ConvertFrom-Json
        $legacyStacks = $allStacks.StackSummaries | Where-Object { $_.StackName -match "^(.+)-MedicalReportsLegacyStack$" }
        
        $participantList = $legacyStacks | ForEach-Object {
            if ($_.StackName -match "^(.+)-MedicalReportsLegacyStack$") {
                $matches[1]
            }
        } | Select-Object -Unique
        
        if ($participantList.Count -eq 0) {
            Write-Host "⚠️  No se encontraron stacks del workshop" -ForegroundColor Yellow
            Write-Host "   Verificando solo SharedNetworkStack..." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Error al buscar stacks automáticamente" -ForegroundColor Yellow
    }
}

Write-Host "   Total de participantes encontrados: $($participantList.Count)" -ForegroundColor White
if ($participantList.Count -gt 0) {
    foreach ($p in $participantList) {
        Write-Host "   - $p" -ForegroundColor Gray
    }
}
Write-Host ""

# Mostrar resumen de lo que se eliminará
Write-Host "📊 Recursos que se eliminarán:" -ForegroundColor Cyan
Write-Host ""
$totalStacks = 0

if ($participantList.Count -gt 0) {
    Write-Host "   Por cada participante ($($participantList.Count)):" -ForegroundColor Yellow
    Write-Host "      - 5 AI Stacks (Extraction, RAG, Classification, Summary, Email)" -ForegroundColor White
    Write-Host "      - 1 LegacyStack (Aurora, S3, API Gateway, Lambdas)" -ForegroundColor White
    $totalStacks = $participantList.Count * 6
}

Write-Host "   Infraestructura compartida:" -ForegroundColor Yellow
Write-Host "      - 1 SharedNetworkStack (VPC, NAT Gateway)" -ForegroundColor White
$totalStacks += 1

Write-Host ""
Write-Host "   Total de stacks a eliminar: $totalStacks" -ForegroundColor White
Write-Host ""

# Confirmar con el usuario
if (-not $SkipConfirmation) {
    Write-Host "⚠️  ADVERTENCIA: Esta acción NO se puede deshacer" -ForegroundColor Red
    Write-Host ""
    $response = Read-Host "¿Está seguro de que desea eliminar TODOS los recursos? (escriba 'SI' para confirmar)"
    if ($response -ne "SI") {
        Write-Host "❌ Operación cancelada por el usuario" -ForegroundColor Yellow
        exit 0
    }
    Write-Host ""
}

$startTime = Get-Date
$errors = @()
$successCount = 0

# ============================================================================
# FASE 1: Eliminar AI Stacks
# ============================================================================

if ($participantList.Count -gt 0) {
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host "  FASE 1: Eliminando AI Stacks" -ForegroundColor Cyan
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $aiStackNames = @()
    foreach ($participant in $participantList) {
        $aiStackNames += "$participant-AIExtractionStack"
        $aiStackNames += "$participant-AIRAGStack"
        $aiStackNames += "$participant-AIClassificationStack"
        $aiStackNames += "$participant-AISummaryStack"
        $aiStackNames += "$participant-AIEmailStack"
    }
    
    Write-Host "🗑️  Eliminando $($aiStackNames.Count) AI Stacks..." -ForegroundColor Yellow
    Write-Host ""
    
    Push-Location cdk
    try {
        $env:DEPLOY_MODE = "ai"
        
        foreach ($stackName in $aiStackNames) {
            Write-Host "   Eliminando $stackName..." -ForegroundColor Gray
            try {
                cdk destroy $stackName --force --profile $Profile 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    $successCount++
                    Write-Host "   ✅ $stackName eliminado" -ForegroundColor Green
                } else {
                    $errors += "AI Stack: $stackName"
                    Write-Host "   ⚠️  Error al eliminar $stackName" -ForegroundColor Yellow
                }
            } catch {
                $errors += "AI Stack: $stackName - $($_.Exception.Message)"
                Write-Host "   ⚠️  Error al eliminar $stackName" -ForegroundColor Yellow
            }
        }
    } finally {
        Pop-Location
    }
    
    Write-Host ""
    Write-Host "✅ Fase 1 completada: $successCount/$($aiStackNames.Count) AI Stacks eliminados" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# FASE 2: Eliminar Legacy Stacks
# ============================================================================

if ($participantList.Count -gt 0) {
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host "  FASE 2: Eliminando Legacy Stacks" -ForegroundColor Cyan
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $legacyStackNames = $participantList | ForEach-Object { "$_-MedicalReportsLegacyStack" }
    
    Write-Host "🗑️  Eliminando $($legacyStackNames.Count) Legacy Stacks..." -ForegroundColor Yellow
    Write-Host ""
    
    Push-Location cdk
    try {
        $env:DEPLOY_MODE = "legacy"
        
        foreach ($stackName in $legacyStackNames) {
            Write-Host "   Eliminando $stackName..." -ForegroundColor Gray
            try {
                cdk destroy $stackName --force --profile $Profile 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    $successCount++
                    Write-Host "   ✅ $stackName eliminado" -ForegroundColor Green
                } else {
                    $errors += "Legacy Stack: $stackName"
                    Write-Host "   ⚠️  Error al eliminar $stackName" -ForegroundColor Yellow
                }
            } catch {
                $errors += "Legacy Stack: $stackName - $($_.Exception.Message)"
                Write-Host "   ⚠️  Error al eliminar $stackName" -ForegroundColor Yellow
            }
        }
    } finally {
        Pop-Location
    }
    
    Write-Host ""
    Write-Host "✅ Fase 2 completada: Legacy Stacks procesados" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# FASE 3: Eliminar SharedNetworkStack
# ============================================================================

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  FASE 3: Eliminando SharedNetworkStack" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "🗑️  Eliminando SharedNetworkStack..." -ForegroundColor Yellow
Write-Host ""

Push-Location cdk
try {
    $env:DEPLOY_MODE = "network"
    
    Write-Host "   Eliminando SharedNetworkStack..." -ForegroundColor Gray
    try {
        cdk destroy SharedNetworkStack --force --profile $Profile 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $successCount++
            Write-Host "   ✅ SharedNetworkStack eliminado" -ForegroundColor Green
        } else {
            $errors += "SharedNetworkStack"
            Write-Host "   ⚠️  Error al eliminar SharedNetworkStack" -ForegroundColor Yellow
        }
    } catch {
        $errors += "SharedNetworkStack - $($_.Exception.Message)"
        Write-Host "   ⚠️  Error al eliminar SharedNetworkStack" -ForegroundColor Yellow
    }
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "✅ Fase 3 completada" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Resumen Final
# ============================================================================

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "============================================================================" -ForegroundColor Green
Write-Host "  LIMPIEZA COMPLETADA" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "⏱️  Tiempo total: $($duration.Minutes) minutos $($duration.Seconds) segundos" -ForegroundColor White
Write-Host "✅ Stacks eliminados exitosamente: $successCount" -ForegroundColor Green

if ($errors.Count -gt 0) {
    Write-Host "⚠️  Errores encontrados: $($errors.Count)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Stacks con errores:" -ForegroundColor Yellow
    foreach ($error in $errors) {
        Write-Host "   - $error" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "💡 Verificar manualmente en la consola de CloudFormation:" -ForegroundColor Cyan
    Write-Host "   https://console.aws.amazon.com/cloudformation" -ForegroundColor Blue
}

Write-Host ""
Write-Host "✅ Limpieza completada" -ForegroundColor Green
Write-Host ""
