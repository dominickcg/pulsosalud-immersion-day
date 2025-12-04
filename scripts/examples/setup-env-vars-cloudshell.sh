#!/bin/bash
# Setup Environment Variables for Medical Reports Workshop (CloudShell)
# Este script configura las variables de entorno necesarias para interactuar con los recursos AWS

# ============================================================================
# INSTRUCCIONES:
# 1. Ejecuta este script: source setup-env-vars-cloudshell.sh
# 2. El script detectará automáticamente tu prefijo de participante
# 3. Las variables estarán disponibles en tu sesión actual de bash
# ============================================================================

echo "🔍 Detectando tu prefijo de participante..."

# Obtener el usuario IAM actual
IAM_USER=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null)

if [ -z "$IAM_USER" ]; then
    echo "❌ Error: No se pudo obtener la identidad del usuario"
    echo "Verifica que estés autenticado en AWS"
    return 1
fi

# Extraer el username del ARN (ej: arn:aws:iam::123456789012:user/workshop-user-1 → workshop-user-1)
USERNAME=$(echo "$IAM_USER" | grep -oP 'user/\K[^/]+' || echo "$IAM_USER" | grep -oP 'assumed-role/\K[^/]+')

echo "👤 Usuario detectado: $USERNAME"

# Extraer el número del username (ej: workshop-user-1 → 1, workshop-user-5 → 5)
PARTICIPANT_NUMBER=$(echo "$USERNAME" | grep -oP '\d+$')

if [ -n "$PARTICIPANT_NUMBER" ]; then
    PARTICIPANT_PREFIX="participant-$PARTICIPANT_NUMBER"
    echo "✅ Prefijo detectado automáticamente: $PARTICIPANT_PREFIX"
else
    # Si no se pudo extraer el número, preguntar al usuario
    echo "⚠️  No se pudo detectar automáticamente tu prefijo desde el usuario: $USERNAME"
    echo "Por favor, ingresa tu prefijo de participante (ej: participant-1, participant-2, etc.):"
    read -p "PARTICIPANT_PREFIX: " PARTICIPANT_PREFIX
    
    if [ -z "$PARTICIPANT_PREFIX" ]; then
        echo "❌ Error: Debes proporcionar un prefijo de participante"
        return 1
    fi
fi

# Exportar PARTICIPANT_PREFIX para que esté disponible en otros scripts
export PARTICIPANT_PREFIX

echo "🔧 Configurando variables de entorno para $PARTICIPANT_PREFIX..."

# Obtener ARN del cluster de Aurora
echo "📊 Obteniendo ARN del cluster Aurora..."
export CLUSTER_ARN=$(aws cloudformation describe-stacks \
  --stack-name "$PARTICIPANT_PREFIX-MedicalReportsLegacyStack" \
  --query 'Stacks[0].Outputs[?OutputKey==`DatabaseClusterArn`].OutputValue' \
  --output text)

if [ -n "$CLUSTER_ARN" ]; then
    echo "✅ CLUSTER_ARN: $CLUSTER_ARN"
else
    echo "❌ Error: No se pudo obtener CLUSTER_ARN"
fi

# Obtener ARN del secret de Aurora
echo "🔐 Obteniendo ARN del secret..."
export SECRET_ARN=$(aws cloudformation describe-stacks \
  --stack-name "$PARTICIPANT_PREFIX-MedicalReportsLegacyStack" \
  --query 'Stacks[0].Outputs[?OutputKey==`DatabaseSecretArn`].OutputValue' \
  --output text)

if [ -n "$SECRET_ARN" ]; then
    echo "✅ SECRET_ARN: $SECRET_ARN"
else
    echo "❌ Error: No se pudo obtener SECRET_ARN"
fi

# Configurar nombre de la base de datos
export DATABASE_NAME="medical_reports"
echo "✅ DATABASE_NAME: medical_reports"

# Obtener URL de API Gateway
echo "🌐 Obteniendo URL de API Gateway..."
export API_GATEWAY_URL=$(aws cloudformation describe-stacks \
  --stack-name "$PARTICIPANT_PREFIX-MedicalReportsLegacyStack" \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiUrl`].OutputValue' \
  --output text)

if [ -n "$API_GATEWAY_URL" ]; then
    echo "✅ API_GATEWAY_URL: $API_GATEWAY_URL"
else
    echo "❌ Error: No se pudo obtener API_GATEWAY_URL"
fi

# Obtener URL de la App Web
echo "🌐 Obteniendo URL de App Web..."
export WEBSITE_URL=$(aws cloudformation describe-stacks \
  --stack-name "$PARTICIPANT_PREFIX-MedicalReportsLegacyStack" \
  --query 'Stacks[0].Outputs[?OutputKey==`AppWebUrl`].OutputValue' \
  --output text)

if [ -n "$WEBSITE_URL" ]; then
    echo "✅ WEBSITE_URL: $WEBSITE_URL"
else
    echo "❌ Error: No se pudo obtener WEBSITE_URL"
fi

echo ""
echo "✅ Variables de entorno configuradas correctamente!"
echo ""
echo "📝 Variables disponibles:"
echo "   - \$PARTICIPANT_PREFIX"
echo "   - \$CLUSTER_ARN"
echo "   - \$SECRET_ARN"
echo "   - \$DATABASE_NAME"
echo "   - \$API_GATEWAY_URL"
echo "   - \$WEBSITE_URL"
echo ""
echo "💡 Tip: Estas variables solo están disponibles en esta sesión de bash"
echo "💡 Para usarlas en otra sesión, ejecuta: source setup-env-vars-cloudshell.sh"
