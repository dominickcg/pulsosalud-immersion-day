# ============================================================================
# Script de Despliegue - AI Stacks Día 1 (Participante)
# ============================================================================
# 
# Este script despliega los AI Stacks necesarios para el Día 1 del workshop:
#   • AIClassificationStack (Lambda classify-risk)
#   • AISummaryStack (Lambda generate-summary)
#
# Uso:
#   .\scripts\participant-deploy-day1.ps1 participant-1
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
$ColorHighlight = "Magenta"

Write-Host ""
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host " 🚀 Medical Reports Workshop - Día 1" -ForegroundColor $ColorHighlight
Write-Host " Despliegue de AI Stacks: Clasificación y Resúmenes" -ForegroundColor $ColorHighlight
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
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
    Write-Host "Ejemplo: participant-1" -ForegroundColor Gray
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
    
    Write-Host "🔍 Verificando sesión AWS..." -ForegroundColor $ColorInfo
    
    try {
        $identity = aws sts get-caller-identity --profile $ProfileName 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $identityObj = $identity | ConvertFrom-Json
            Write-Host "✓ Sesión activa" -ForegroundColor $ColorSuccess
            Write-Host "  Account: $($identityObj.Account)" -ForegroundColor Gray
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
                Write-Host "❌ Error verificando sesión" -ForegroundColor $ColorError
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
    Write-Host "Contacta al instructor si necesitas ayuda" -ForegroundColor $ColorWarning
    Write-Host ""
    exit 1
}

# ============================================================================
# Configurar variables de entorno
# ============================================================================
Write-Host ""
Write-Host "⚙️  Configurando entorno..." -ForegroundColor $ColorInfo
$env:AWS_PROFILE = $Profile
$env:AWS_REGION = $Region
$env:PARTICIPANT_PREFIX = $ParticipantPrefix
Write-Host "✓ Configuración lista" -ForegroundColor $ColorSuccess

# ============================================================================
# Cambiar al directorio CDK
# ============================================================================
Write-Host ""
Write-Host "📁 Navegando al directorio CDK..." -ForegroundColor $ColorInfo
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$cdkPath = Join-Path $projectRoot "cdk"

if (-not (Test-Path $cdkPath)) {
    Write-Host "❌ No se encontró el directorio CDK" -ForegroundColor $ColorError
    exit 1
}

Set-Location $cdkPath
Write-Host "✓ Directorio: $cdkPath" -ForegroundColor $ColorSuccess

# ============================================================================
# Verificar que LegacyStack existe
# ============================================================================
Write-Host ""
Write-Host "🔍 Verificando prerequisitos..." -ForegroundColor $ColorInfo

$legacyStackName = "$ParticipantPrefix-MedicalReportsLegacyStack"
$legacyStack = aws cloudformation describe-stacks --stack-name $legacyStackName --profile $Profile 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Tu LegacyStack no está desplegado" -ForegroundColor $ColorError
    Write-Host ""
    Write-Host "El instructor debe haber desplegado tu infraestructura base." -ForegroundColor $ColorWarning
    Write-Host "Contacta al instructor para verificar." -ForegroundColor $ColorWarning
    Write-Host ""
    exit 1
}

Write-Host "✓ LegacyStack encontrado" -ForegroundColor $ColorSuccess

# ============================================================================
# Verificar dependencias
# ============================================================================
if (-not (Test-Path "node_modules")) {
    Write-Host "⚠ Instalando dependencias..." -ForegroundColor $ColorWarning
    npm install --silent
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error instalando dependencias" -ForegroundColor $ColorError
        exit 1
    }
}

Write-Host "✓ Dependencias verificadas" -ForegroundColor $ColorSuccess

# ============================================================================
# Desplegar AI Stacks del Día 1
# ============================================================================
Write-Host ""
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host " 🤖 Desplegando AI Stacks del Día 1" -ForegroundColor $ColorHighlight
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host ""
Write-Host "Stacks que se desplegarán:" -ForegroundColor $ColorInfo
Write-Host ""
Write-Host "  1️⃣  AIClassificationStack" -ForegroundColor $ColorSuccess
Write-Host "      • Lambda: classify-risk" -ForegroundColor Gray
Write-Host "      • Usa Bedrock Nova Pro con few-shot learning" -ForegroundColor Gray
Write-Host "      • Implementa RAG con búsqueda SQL" -ForegroundColor Gray
Write-Host ""
Write-Host "  2️⃣  AISummaryStack" -ForegroundColor $ColorSuccess
Write-Host "      • Lambda: generate-summary" -ForegroundColor Gray
Write-Host "      • Genera resúmenes ejecutivos de 100-150 palabras" -ForegroundColor Gray
Write-Host "      • Usa RAG para incluir contexto histórico" -ForegroundColor Gray
Write-Host ""
Write-Host "⏱️  Tiempo estimado: 3-5 minutos" -ForegroundColor $ColorWarning
Write-Host ""

# Confirmar con el usuario
$confirmation = Read-Host "¿Listo para desplegar? (s/n)"
if ($confirmation -ne "s" -and $confirmation -ne "S") {
    Write-Host "❌ Despliegue cancelado" -ForegroundColor $ColorWarning
    exit 0
}

Write-Host ""
Write-Host "🚀 Iniciando despliegue..." -ForegroundColor $ColorInfo
Write-Host ""

# Nombres de los stacks
$classificationStack = "$ParticipantPrefix-AIClassificationStack"
$summaryStack = "$ParticipantPrefix-AISummaryStack"

# Ejecutar CDK deploy para ambos stacks
$startTime = Get-Date

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "Desplegando: $classificationStack y $summaryStack" -ForegroundColor $ColorInfo
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""

npx cdk deploy $classificationStack $summaryStack --require-approval never --profile $Profile

$exitCode = $LASTEXITCODE
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "============================================================================" -ForegroundColor $ColorHighlight

if ($exitCode -eq 0) {
    Write-Host "✓ ¡Despliegue completado exitosamente!" -ForegroundColor $ColorSuccess
    Write-Host ""
    Write-Host "⏱️  Tiempo total: $($duration.Minutes) minutos $($duration.Seconds) segundos" -ForegroundColor $ColorInfo
    Write-Host ""
    
    # ========================================================================
    # Obtener información de los stacks
    # ========================================================================
    Write-Host "📋 Obteniendo información de tus Lambdas..." -ForegroundColor $ColorInfo
    Write-Host ""
    
    # Classification Stack
    $classStackInfo = aws cloudformation describe-stacks --stack-name $classificationStack --profile $Profile | ConvertFrom-Json
    $classOutputs = $classStackInfo.Stacks[0].Outputs
    
    $classifyLambdaName = ($classOutputs | Where-Object { $_.OutputKey -eq "ClassifyRiskLambdaName" }).OutputValue
    $classifyEndpoint = ($classOutputs | Where-Object { $_.OutputKey -eq "ClassifyEndpoint" }).OutputValue
    
    # Summary Stack
    $summaryStackInfo = aws cloudformation describe-stacks --stack-name $summaryStack --profile $Profile | ConvertFrom-Json
    $summaryOutputs = $summaryStackInfo.Stacks[0].Outputs
    
    $summaryLambdaName = ($summaryOutputs | Where-Object { $_.OutputKey -eq "GenerateSummaryLambdaName" }).OutputValue
    $summaryEndpoint = ($summaryOutputs | Where-Object { $_.OutputKey -eq "SummaryEndpoint" }).OutputValue
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  🎯 Tus Lambdas de IA están listas:" -ForegroundColor $ColorSuccess
    Write-Host ""
    Write-Host "  📊 Clasificación de Riesgo:" -ForegroundColor $ColorInfo
    Write-Host "     Lambda: $classifyLambdaName" -ForegroundColor White
    Write-Host "     Endpoint: $classifyEndpoint" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  📝 Generación de Resúmenes:" -ForegroundColor $ColorInfo
    Write-Host "     Lambda: $summaryLambdaName" -ForegroundColor White
    Write-Host "     Endpoint: $summaryEndpoint" -ForegroundColor Gray
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host ""
    
    # ========================================================================
    # Próximos pasos
    # ========================================================================
    Write-Host "🎓 Próximos pasos:" -ForegroundColor $ColorHighlight
    Write-Host ""
    Write-Host "  1. Abre tu App Web (el instructor te compartió la URL)" -ForegroundColor Gray
    Write-Host "  2. Selecciona un informe médico de la lista" -ForegroundColor Gray
    Write-Host "  3. Haz clic en 'Clasificar con IA' para ver few-shot learning en acción" -ForegroundColor Gray
    Write-Host "  4. Haz clic en 'Generar Resumen' para crear un resumen ejecutivo" -ForegroundColor Gray
    Write-Host "  5. Experimenta con diferentes informes y observa los resultados" -ForegroundColor Gray
    Write-Host ""
    Write-Host "💡 Conceptos que aprenderás:" -ForegroundColor $ColorInfo
    Write-Host "   • Few-shot learning con Amazon Bedrock" -ForegroundColor Gray
    Write-Host "   • RAG (Retrieval-Augmented Generation)" -ForegroundColor Gray
    Write-Host "   • Ajuste de temperature y maxTokens" -ForegroundColor Gray
    Write-Host "   • Prompt engineering para clasificación y resúmenes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📚 ¿Tienes dudas? Consulta la PARTICIPANT_GUIDE.md" -ForegroundColor $ColorWarning
    Write-Host ""
}
else {
    Write-Host "❌ Error durante el despliegue" -ForegroundColor $ColorError
    Write-Host ""
    Write-Host "Contacta al instructor para obtener ayuda" -ForegroundColor $ColorWarning
    Write-Host ""
    Write-Host "Información útil para debugging:" -ForegroundColor $ColorInfo
    Write-Host "  • Stack: $classificationStack o $summaryStack" -ForegroundColor Gray
    Write-Host "  • Región: $Region" -ForegroundColor Gray
    Write-Host "  • Perfil: $Profile" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host ""
Write-Host "🎉 ¡Listo para empezar el workshop!" -ForegroundColor $ColorSuccess
Write-Host ""
