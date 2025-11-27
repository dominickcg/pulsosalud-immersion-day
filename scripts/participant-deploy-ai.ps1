# ============================================================================
# Script: Despliegue de AI Stacks para Participantes
# Propósito: Desplegar las 5 Lambdas de IA durante el workshop
# Quién: Participantes del workshop
# Cuándo: Durante el Día 1 del workshop (primeros 8 minutos)
# Tiempo estimado: ~5-8 minutos
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$ParticipantPrefix,
    
    [Parameter(Mandatory=$true)]
    [string]$VerifiedEmail,
    
    [string]$Profile = "pulsosalud-immersion",
    [string]$Region = "us-east-2"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  Despliegue de AI Stacks - Lambdas de Procesamiento de IA" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  👋 Bienvenido al Workshop de Medical Reports Automation!" -ForegroundColor Green
Write-Host ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "cdk/bin/app.ts")) {
    Write-Host "❌ ERROR: Este script debe ejecutarse desde la raíz del proyecto" -ForegroundColor Red
    Write-Host "   Directorio actual: $PWD" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Navegar al directorio correcto:" -ForegroundColor Yellow
    Write-Host "   cd ruta\al\proyecto" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Configurar variables de entorno
$env:DEPLOY_MODE = "ai"
$env:PARTICIPANT_PREFIX = $ParticipantPrefix
$env:VERIFIED_EMAIL = $VerifiedEmail
$env:AWS_PROFILE = $Profile
$env:CDK_DEFAULT_REGION = $Region

Write-Host "📋 Tu configuración:" -ForegroundColor Green
Write-Host "   - Participante: $ParticipantPrefix" -ForegroundColor White
Write-Host "   - Email: $VerifiedEmail" -ForegroundColor White
Write-Host "   - Perfil AWS: $Profile" -ForegroundColor White
Write-Host "   - Región: $Region" -ForegroundColor White
Write-Host ""

# Verificar sesión AWS
Write-Host "🔐 Verificando tu sesión AWS..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --profile $Profile 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($identity -match "ExpiredToken") {
            Write-Host "⚠️  Token expirado. Renovando sesión SSO..." -ForegroundColor Yellow
            aws sso login --profile $Profile
            if ($LASTEXITCODE -ne 0) {
                Write-Host "❌ ERROR: No se pudo renovar la sesión SSO" -ForegroundColor Red
                Write-Host ""
                Write-Host "   Contacta al instructor para ayuda" -ForegroundColor Yellow
                Write-Host ""
                exit 1
            }
        } else {
            Write-Host "❌ ERROR: No se pudo verificar la identidad AWS" -ForegroundColor Red
            Write-Host $identity -ForegroundColor Red
            Write-Host ""
            Write-Host "   Contacta al instructor para ayuda" -ForegroundColor Yellow
            Write-Host ""
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
    Write-Host ""
    Write-Host "   Contacta al instructor para ayuda" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Verificar que LegacyStack existe
Write-Host "🔍 Verificando que tu infraestructura base existe..." -ForegroundColor Yellow
$legacyStackName = "$ParticipantPrefix-MedicalReportsLegacyStack"
try {
    $legacyStack = aws cloudformation describe-stacks --stack-name $legacyStackName --profile $Profile --region $Region 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ ERROR: Tu LegacyStack no fue encontrado" -ForegroundColor Red
        Write-Host ""
        Write-Host "   Stack esperado: $legacyStackName" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   El instructor debe haber desplegado este stack antes del workshop." -ForegroundColor Yellow
        Write-Host "   Por favor contacta al instructor." -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
    Write-Host "✅ Infraestructura base encontrada" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "❌ ERROR: No se pudo verificar tu LegacyStack" -ForegroundColor Red
    Write-Host ""
    Write-Host "   Contacta al instructor para ayuda" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "🚀 Iniciando despliegue de tus AI Stacks..." -ForegroundColor Green
Write-Host "   Tiempo estimado: ~5-8 minutos" -ForegroundColor White
Write-Host ""
Write-Host "   Se desplegarán 5 stacks:" -ForegroundColor White
Write-Host "   1. AIExtractionStack - Extracción de PDFs con Textract + Bedrock" -ForegroundColor Gray
Write-Host "   2. AIRAGStack - Embeddings vectoriales con Titan" -ForegroundColor Gray
Write-Host "   3. AIClassificationStack - Clasificación de riesgo con Nova Pro" -ForegroundColor Gray
Write-Host "   4. AISummaryStack - Generación de resúmenes con Nova Pro" -ForegroundColor Gray
Write-Host "   5. AIEmailStack - Emails personalizados con Nova Pro + SES" -ForegroundColor Gray
Write-Host ""

$response = Read-Host "¿Continuar con el despliegue? (s/n)"
if ($response -ne "s" -and $response -ne "S") {
    Write-Host "❌ Operación cancelada" -ForegroundColor Yellow
    exit 0
}

Write-Host ""

# Cambiar al directorio CDK
Push-Location cdk

try {
    # Compilar el proyecto
    Write-Host "📦 Compilando proyecto TypeScript..." -ForegroundColor Yellow
    npm run build
    if ($LASTEXITCODE -ne 0) {
        throw "Error al compilar el proyecto"
    }
    Write-Host "✅ Compilación exitosa" -ForegroundColor Green
    Write-Host ""

    # Desplegar AI stacks
    Write-Host "☁️  Desplegando tus AI Stacks..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   💡 Tip: Puedes ver el progreso en la consola de CloudFormation" -ForegroundColor Cyan
    Write-Host "      https://console.aws.amazon.com/cloudformation" -ForegroundColor Blue
    Write-Host ""
    
    $startTime = Get-Date
    
    cdk deploy --all --require-approval never --profile $Profile
    
    if ($LASTEXITCODE -ne 0) {
        throw "Error al desplegar AI Stacks"
    }
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host "  🎉 ¡AI Stacks desplegados exitosamente!" -ForegroundColor Green
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "⏱️  Tiempo de despliegue: $($duration.Minutes) minutos $($duration.Seconds) segundos" -ForegroundColor White
    Write-Host ""
    
    # Obtener outputs de los AI stacks
    Write-Host "📊 Tus recursos desplegados:" -ForegroundColor Cyan
    Write-Host ""
    
    $aiStacks = @(
        "$ParticipantPrefix-AIExtractionStack",
        "$ParticipantPrefix-AIRAGStack",
        "$ParticipantPrefix-AIClassificationStack",
        "$ParticipantPrefix-AISummaryStack",
        "$ParticipantPrefix-AIEmailStack"
    )
    
    foreach ($stackName in $aiStacks) {
        try {
            $outputs = aws cloudformation describe-stacks --stack-name $stackName --profile $Profile --region $Region --query "Stacks[0].Outputs" --output json 2>$null | ConvertFrom-Json
            
            if ($outputs) {
                Write-Host "   $stackName:" -ForegroundColor Yellow
                foreach ($output in $outputs) {
                    Write-Host "      $($output.OutputKey): $($output.OutputValue)" -ForegroundColor White
                }
                Write-Host ""
            }
        } catch {
            # Ignorar errores al obtener outputs
        }
    }
    
    Write-Host "📝 Próximos pasos:" -ForegroundColor Cyan
    Write-Host "   1. ✅ Tu infraestructura está lista" -ForegroundColor White
    Write-Host "   2. 🎓 Continúa con los módulos del workshop" -ForegroundColor White
    Write-Host "   3. 🧪 Experimenta con las Lambdas de IA" -ForegroundColor White
    Write-Host ""
    Write-Host "   📚 Consulta el PARTICIPANT_GUIDE.md para más información" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Red
    Write-Host "  ❌ ERROR durante el despliegue" -ForegroundColor Red
    Write-Host "============================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "   💡 Posibles soluciones:" -ForegroundColor Yellow
    Write-Host "   1. Verifica que tu LegacyStack existe" -ForegroundColor White
    Write-Host "   2. Verifica que tienes permisos suficientes" -ForegroundColor White
    Write-Host "   3. Contacta al instructor para ayuda" -ForegroundColor White
    Write-Host ""
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

Write-Host "✅ ¡Listo para comenzar! 🚀" -ForegroundColor Green
Write-Host ""
