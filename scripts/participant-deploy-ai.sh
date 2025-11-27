#!/bin/bash

# ============================================================================
# Script: Despliegue de AI Stacks para Participantes
# Propósito: Desplegar las 5 Lambdas de IA durante el workshop
# Quién: Participantes del workshop
# Cuándo: Durante el Día 1 del workshop (primeros 8 minutos)
# Tiempo estimado: ~5-8 minutos
# ============================================================================

set -e

# Verificar argumentos
if [ $# -lt 2 ]; then
    echo ""
    echo "❌ ERROR: Faltan argumentos requeridos"
    echo ""
    echo "Uso: $0 <PARTICIPANT_PREFIX> <VERIFIED_EMAIL> [PROFILE] [REGION]"
    echo ""
    echo "Ejemplo:"
    echo "  $0 participant-juan juan@example.com"
    echo "  $0 participant-maria maria@example.com pulsosalud-immersion us-east-2"
    echo ""
    exit 1
fi

PARTICIPANT_PREFIX="$1"
VERIFIED_EMAIL="$2"
PROFILE="${3:-}"
REGION="${4:-us-east-2}"

# Detectar si estamos en CloudShell
# CloudShell puede detectarse por varias variables de entorno
if [ -n "$AWS_EXECUTION_ENV" ] || [ -n "$CLOUDSHELL" ] || [ "$HOME" = "/home/cloudshell-user" ]; then
    IS_CLOUDSHELL=true
    PROFILE=""  # CloudShell no necesita perfil
else
    IS_CLOUDSHELL=false
    # Si no estamos en CloudShell y no se especificó perfil, usar el default
    if [ -z "$PROFILE" ]; then
        PROFILE="pulsosalud-immersion"
    fi
fi

echo ""
echo "============================================================================"
echo "  Despliegue de AI Stacks - Lambdas de Procesamiento de IA"
echo "============================================================================"
echo ""
echo "  👋 Bienvenido al Workshop de Medical Reports Automation!"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "cdk/bin/app.ts" ]; then
    echo "❌ ERROR: Este script debe ejecutarse desde la raíz del proyecto"
    echo "   Directorio actual: $(pwd)"
    echo ""
    echo "   Navegar al directorio correcto:"
    echo "   cd ruta/al/proyecto"
    echo ""
    exit 1
fi

# Configurar variables de entorno
export DEPLOY_MODE="ai"
export PARTICIPANT_PREFIX="$PARTICIPANT_PREFIX"
export VERIFIED_EMAIL="$VERIFIED_EMAIL"
export AWS_PROFILE="$PROFILE"
export CDK_DEFAULT_REGION="$REGION"

echo "📋 Tu configuración:"
echo "   - Participante: $PARTICIPANT_PREFIX"
echo "   - Email: $VERIFIED_EMAIL"
if [ "$IS_CLOUDSHELL" = true ]; then
    echo "   - Entorno: AWS CloudShell"
else
    echo "   - Perfil AWS: $PROFILE"
fi
echo "   - Región: $REGION"
echo ""

# Verificar sesión AWS
echo "🔐 Verificando tu sesión AWS..."

# Construir comando AWS CLI con o sin perfil
if [ -n "$PROFILE" ]; then
    AWS_CMD="aws --profile $PROFILE"
else
    AWS_CMD="aws"
fi

if ! $AWS_CMD sts get-caller-identity > /dev/null 2>&1; then
    if [ "$IS_CLOUDSHELL" = true ]; then
        echo "❌ ERROR: No se pudo verificar la identidad AWS"
        echo ""
        echo "   Diagnóstico:"
        echo "   - Entorno detectado: CloudShell"
        echo "   - Comando ejecutado: $AWS_CMD sts get-caller-identity"
        echo ""
        echo "   Intenta ejecutar manualmente:"
        echo "   aws sts get-caller-identity"
        echo ""
        echo "   Si ese comando funciona, contacta al instructor."
        echo ""
        exit 1
    else
        echo "⚠️  Error de autenticación. Intentando renovar sesión SSO..."
        if ! aws sso login --profile "$PROFILE"; then
            echo "❌ ERROR: No se pudo renovar la sesión SSO"
            echo ""
            echo "   Contacta al instructor para ayuda"
            echo ""
            exit 1
        fi
    fi
fi

IDENTITY=$($AWS_CMD sts get-caller-identity --output json)
ACCOUNT=$(echo "$IDENTITY" | jq -r '.Account')

echo "✅ Sesión AWS verificada"
echo "   - Account: $ACCOUNT"
echo ""

# Verificar que LegacyStack existe
echo "🔍 Verificando que tu infraestructura base existe..."
LEGACY_STACK_NAME="${PARTICIPANT_PREFIX}-MedicalReportsLegacyStack"

if ! $AWS_CMD cloudformation describe-stacks --stack-name "$LEGACY_STACK_NAME" --region "$REGION" > /dev/null 2>&1; then
    echo "❌ ERROR: Tu LegacyStack no fue encontrado"
    echo ""
    echo "   Stack esperado: $LEGACY_STACK_NAME"
    echo ""
    echo "   El instructor debe haber desplegado este stack antes del workshop."
    echo "   Por favor contacta al instructor."
    echo ""
    exit 1
fi

echo "✅ Infraestructura base encontrada"
echo ""

echo "🚀 Iniciando despliegue de tus AI Stacks..."
echo "   Tiempo estimado: ~5-8 minutos"
echo ""
echo "   Se desplegarán 5 stacks:"
echo "   1. AIExtractionStack - Extracción de PDFs con Textract + Bedrock"
echo "   2. AIRAGStack - Embeddings vectoriales con Titan"
echo "   3. AIClassificationStack - Clasificación de riesgo con Nova Pro"
echo "   4. AISummaryStack - Generación de resúmenes con Nova Pro"
echo "   5. AIEmailStack - Emails personalizados con Nova Pro + SES"
echo ""

read -p "¿Continuar con el despliegue? (s/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Operación cancelada"
    exit 0
fi

echo ""

# Cambiar al directorio CDK
cd cdk

# Compilar el proyecto
echo "📦 Compilando proyecto TypeScript..."
if ! npm run build; then
    echo "❌ ERROR: Error al compilar el proyecto"
    exit 1
fi
echo "✅ Compilación exitosa"
echo ""

# Desplegar AI stacks
echo "☁️  Desplegando tus AI Stacks..."
echo ""
echo "   💡 Tip: Puedes ver el progreso en la consola de CloudFormation"
echo "      https://console.aws.amazon.com/cloudformation"
echo ""

START_TIME=$(date +%s)

# Construir comando CDK con o sin perfil
if [ -n "$PROFILE" ]; then
    CDK_CMD="npx cdk deploy --all --require-approval never --profile $PROFILE"
else
    CDK_CMD="npx cdk deploy --all --require-approval never"
fi

if ! $CDK_CMD; then
    echo ""
    echo "============================================================================"
    echo "  ❌ ERROR durante el despliegue"
    echo "============================================================================"
    echo ""
    echo "   💡 Posibles soluciones:"
    echo "   1. Verifica que tu LegacyStack existe"
    echo "   2. Verifica que tienes permisos suficientes"
    echo "   3. Contacta al instructor para ayuda"
    echo ""
    exit 1
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo "============================================================================"
echo "  🎉 ¡AI Stacks desplegados exitosamente!"
echo "============================================================================"
echo ""
echo "⏱️  Tiempo de despliegue: ${MINUTES} minutos ${SECONDS} segundos"
echo ""

# Obtener outputs de los AI stacks
echo "📊 Tus recursos desplegados:"
echo ""

AI_STACKS=(
    "${PARTICIPANT_PREFIX}-AIExtractionStack"
    "${PARTICIPANT_PREFIX}-AIRAGStack"
    "${PARTICIPANT_PREFIX}-AIClassificationStack"
    "${PARTICIPANT_PREFIX}-AISummaryStack"
    "${PARTICIPANT_PREFIX}-AIEmailStack"
)

for stack_name in "${AI_STACKS[@]}"; do
    if $AWS_CMD cloudformation describe-stacks --stack-name "$stack_name" --region "$REGION" > /dev/null 2>&1; then
        echo "   $stack_name:"
        $AWS_CMD cloudformation describe-stacks \
            --stack-name "$stack_name" \
            --region "$REGION" \
            --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
            --output text 2>/dev/null | while IFS=$'\t' read -r key value; do
            echo "      $key: $value"
        done
        echo ""
    fi
done

echo "📝 Próximos pasos:"
echo "   1. ✅ Tu infraestructura está lista"
echo "   2. 🎓 Continúa con los módulos del workshop"
echo "   3. 🧪 Experimenta con las Lambdas de IA"
echo ""
echo "   📚 Consulta el PARTICIPANT_GUIDE.md para más información"
echo ""

cd ..

echo "✅ ¡Listo para comenzar! 🚀"
echo ""
