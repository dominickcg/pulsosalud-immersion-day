# ============================================================================
# Script de Despliegue - AI Stacks Día 2 (Participante)
# ============================================================================
# 
# Este script despliega los AI Stacks necesarios para el Día 2 del workshop:
#   • AIRAGStack (Lambda generate-embeddings + similarity search)
#   • AIEmailStack (Lambda send-email)
#
# Uso:
#   .\scripts\participant-deploy-day2.ps1 participant-1 tu-email@example.com
#
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$ParticipantPrefix,
    
    [Parameter(Mandatory=$true)]
    [string]$VerifiedEmail,
    
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
Write-Host " 🚀 Medical Reports Workshop - Día 2" -ForegroundColor $ColorHighlight
Write-Host " Despliegue de AI Stacks: RAG Avanzado y Emails Personalizados" -ForegroundColor $ColorHighlight
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host ""
Write-Host "Participante: $ParticipantPrefix" -ForegroundColor $ColorInfo
Write-Host "Email verificado: $VerifiedEmail" -ForegroundColor $ColorInfo
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
# Validar formato de email
# ============================================================================
if ($VerifiedEmail -notmatch '^[^@]+@[^@]+\.[^@]+$') {
    Write-Host "❌ Formato de email inválido" -ForegroundColor $ColorError
    Write-Host ""
    Write-Host "Proporciona un email válido" -ForegroundColor $ColorWarning
    Write-Host "Ejemplo: tu-email@example.com" -ForegroundColor Gray
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
$env:VERIFIED_EMAIL = $VerifiedEmail
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
# Verificar prerequisitos del Día 1
# ============================================================================
Write-Host ""
Write-Host "🔍 Verificando prerequisitos..." -ForegroundColor $ColorInfo

# Verificar LegacyStack
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

# Verificar AI Stacks del Día 1
$classificationStack = "$ParticipantPrefix-AIClassificationStack"
$summaryStack = "$ParticipantPrefix-AISummaryStack"

$classStack = aws cloudformation describe-stacks --stack-name $classificationStack --profile $Profile 2>&1
$summStack = aws cloudformation describe-stacks --stack-name $summaryStack --profile $Profile 2>&1

if ($LASTEXITCODE -ne 0 -or $classStack -match "does not exist") {
    Write-Host "⚠ AIClassificationStack no encontrado" -ForegroundColor $ColorWarning
    Write-Host ""
    Write-Host "Debes completar el despliegue del Día 1 primero." -ForegroundColor $ColorWarning
    Write-Host "Ejecuta: .\scripts\participant-deploy-day1.ps1 $ParticipantPrefix" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

if ($summStack -match "does not exist") {
    Write-Host "⚠ AISummaryStack no encontrado" -ForegroundColor $ColorWarning
    Write-Host ""
    Write-Host "Debes completar el despliegue del Día 1 primero." -ForegroundColor $ColorWarning
    Write-Host "Ejecuta: .\scripts\participant-deploy-day1.ps1 $ParticipantPrefix" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-Host "✓ AI Stacks del Día 1 encontrados" -ForegroundColor $ColorSuccess

# ============================================================================
# Verificar email en SES (opcional, solo warning)
# ============================================================================
Write-Host ""
Write-Host "📧 Verificando email en SES..." -ForegroundColor $ColorInfo

$sesIdentities = aws ses list-identities --profile $Profile 2>&1

if ($LASTEXITCODE -eq 0) {
    $identitiesObj = $sesIdentities | ConvertFrom-Json
    
    if ($identitiesObj.Identities -contains $VerifiedEmail) {
        Write-Host "✓ Email verificado en SES" -ForegroundColor $ColorSuccess
    }
    else {
        Write-Host "⚠ Email NO verificado en SES" -ForegroundColor $ColorWarning
        Write-Host ""
        Write-Host "El envío de emails fallará hasta que verifiques tu email." -ForegroundColor $ColorWarning
        Write-Host "Consulta la PARTICIPANT_GUIDE.md para instrucciones." -ForegroundColor Gray
        Write-Host ""
        Write-Host "¿Deseas continuar de todos modos? (s/n)" -ForegroundColor $ColorWarning
        $continue = Read-Host
        
        if ($continue -ne "s" -and $continue -ne "S") {
            Write-Host "❌ Despliegue cancelado" -ForegroundColor $ColorWarning
            exit 0
        }
    }
}
else {
    Write-Host "⚠ No se pudo verificar email en SES" -ForegroundColor $ColorWarning
    Write-Host "Continuando de todos modos..." -ForegroundColor Gray
}

# ============================================================================
# Verificar dependencias
# ============================================================================
Write-Host ""
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
# Desplegar AI Stacks del Día 2
# ============================================================================
Write-Host ""
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host " 🤖 Desplegando AI Stacks del Día 2" -ForegroundColor $ColorHighlight
Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host ""
Write-Host "Stacks que se desplegarán:" -ForegroundColor $ColorInfo
Write-Host ""
Write-Host "  1️⃣  AIRAGStack" -ForegroundColor $ColorSuccess
Write-Host "      • Lambda: generate-embeddings" -ForegroundColor Gray
Write-Host "      • Usa Titan Embeddings v2 (1024 dimensiones)" -ForegroundColor Gray
Write-Host "      • Búsqueda semántica con similitud de coseno" -ForegroundColor Gray
Write-Host "      • Tabla separada: informes_embeddings" -ForegroundColor Gray
Write-Host ""
Write-Host "  2️⃣  AIEmailStack" -ForegroundColor $ColorSuccess
Write-Host "      • Lambda: send-email" -ForegroundColor Gray
Write-Host "      • Emails personalizados por nivel de riesgo" -ForegroundColor Gray
Write-Host "      • Integración con Amazon SES" -ForegroundColor Gray
Write-Host "      • Usa Bedrock Nova Pro (temp=0.7)" -ForegroundColor Gray
Write-Host ""
Write-Host "⏱️  Tiempo estimado: 6-8 minutos" -ForegroundColor $ColorWarning
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
$ragStack = "$ParticipantPrefix-AIRAGStack"
$emailStack = "$ParticipantPrefix-AIEmailStack"

# Ejecutar CDK deploy para ambos stacks
$startTime = Get-Date

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "Desplegando: $ragStack y $emailStack" -ForegroundColor $ColorInfo
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""

npx cdk deploy $ragStack $emailStack --require-approval never --profile $Profile --context verifiedEmail=$VerifiedEmail

$exitCode = $LASTEXITCODE
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "============================================================================" -ForegroundColor $ColorHighlight

if ($exitCode -eq 0) {
    Write-Host "✓ ¡Despliegue completado exitosamente!" -ForegroundColor $ColorSuccess
    Write-Host ""
    Write-Host "⏱️  Tiempo total: $($duration.Minutes) minutos $($duration.Seconds) segundos" -ForegroundColor $ColorInfo
    
    # Verificar que el tiempo fue menor a 8 minutos
    if ($duration.TotalMinutes -le 8) {
        Write-Host "✓ Tiempo objetivo cumplido (<8 minutos)" -ForegroundColor $ColorSuccess
    }
    else {
        Write-Host "⚠ Tiempo excedió el objetivo de 8 minutos" -ForegroundColor $ColorWarning
    }
    
    Write-Host ""
    
    # ========================================================================
    # Obtener información de los stacks
    # ========================================================================
    Write-Host "📋 Obteniendo información de tus Lambdas..." -ForegroundColor $ColorInfo
    Write-Host ""
    
    # RAG Stack
    $ragStackInfo = aws cloudformation describe-stacks --stack-name $ragStack --profile $Profile | ConvertFrom-Json
    $ragOutputs = $ragStackInfo.Stacks[0].Outputs
    
    $embeddingsLambdaName = ($ragOutputs | Where-Object { $_.OutputKey -eq "GenerateEmbeddingsLambdaName" }).OutputValue
    
    # Email Stack
    $emailStackInfo = aws cloudformation describe-stacks --stack-name $emailStack --profile $Profile | ConvertFrom-Json
    $emailOutputs = $emailStackInfo.Stacks[0].Outputs
    
    $sendEmailLambdaName = ($emailOutputs | Where-Object { $_.OutputKey -eq "SendEmailLambdaName" }).OutputValue
    $emailEndpoint = ($emailOutputs | Where-Object { $_.OutputKey -eq "EmailEndpoint" }).OutputValue
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  🎯 Tus Lambdas de IA del Día 2 están listas:" -ForegroundColor $ColorSuccess
    Write-Host ""
    Write-Host "  🔢 Generación de Embeddings:" -ForegroundColor $ColorInfo
    Write-Host "     Lambda: $embeddingsLambdaName" -ForegroundColor White
    Write-Host "     Modelo: Titan Embeddings v2 (1024 dims)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  📧 Envío de Emails Personalizados:" -ForegroundColor $ColorInfo
    Write-Host "     Lambda: $sendEmailLambdaName" -ForegroundColor White
    Write-Host "     Endpoint: $emailEndpoint" -ForegroundColor Gray
    Write-Host "     Email verificado: $VerifiedEmail" -ForegroundColor Gray
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host ""
    
    # ========================================================================
    # Próximos pasos
    # ========================================================================
    Write-Host "🎓 Próximos pasos:" -ForegroundColor $ColorHighlight
    Write-Host ""
    Write-Host "  Módulo 3: RAG Avanzado con Embeddings" -ForegroundColor $ColorSuccess
    Write-Host "  ────────────────────────────────────────" -ForegroundColor Gray
    Write-Host "  1. Genera embeddings para un informe:" -ForegroundColor Gray
    Write-Host "     .\scripts\examples\invoke-embeddings.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. Busca informes similares:" -ForegroundColor Gray
    Write-Host "     .\scripts\examples\test-similarity-search.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "  3. Compara RAG Día 1 vs Día 2:" -ForegroundColor Gray
    Write-Host "     .\scripts\examples\demo-rag-comparison.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "  Módulo 4: Emails Personalizados" -ForegroundColor $ColorSuccess
    Write-Host "  ────────────────────────────────" -ForegroundColor Gray
    Write-Host "  4. Genera y envía un email:" -ForegroundColor Gray
    Write-Host "     .\scripts\examples\invoke-email.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 Conceptos que aprenderás:" -ForegroundColor $ColorInfo
    Write-Host "   • Embeddings vectoriales con Titan v2" -ForegroundColor Gray
    Write-Host "   • Búsqueda semántica vs SQL" -ForegroundColor Gray
    Write-Host "   • Similitud de coseno" -ForegroundColor Gray
    Write-Host "   • Personalización de emails por nivel de riesgo" -ForegroundColor Gray
    Write-Host "   • Privacidad médica en RAG" -ForegroundColor Gray
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
    Write-Host "  • Stack: $ragStack o $emailStack" -ForegroundColor Gray
    Write-Host "  • Región: $Region" -ForegroundColor Gray
    Write-Host "  • Perfil: $Profile" -ForegroundColor Gray
    Write-Host "  • Email: $VerifiedEmail" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-Host "============================================================================" -ForegroundColor $ColorHighlight
Write-Host ""
Write-Host "🎉 ¡Listo para el Día 2 del workshop!" -ForegroundColor $ColorSuccess
Write-Host ""
