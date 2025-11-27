#!/bin/bash

# ============================================================================
# Script: Despliegue de SharedNetworkStack
# Propósito: Desplegar la VPC compartida para todos los participantes del workshop
# Quién: Instructor
# Cuándo: Una sola vez antes del workshop
# Tiempo estimado: ~8 minutos
# ============================================================================

set -e

PROFILE="${1:-pulsosalud-immersion}"
REGION="${2:-us-east-2}"

echo ""
echo "============================================================================"
echo "  Despliegue de SharedNetworkStack - VPC Compartida"
echo "============================================================================"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "cdk/bin/app.ts" ]; then
    echo "❌ ERROR: Este script debe ejecutarse desde la raíz del proyecto"
    echo "   Directorio actual: $(pwd)"
    exit 1
fi

# Configurar variables de entorno
export DEPLOY_MODE="network"
export AWS_PROFILE="$PROFILE"
export CDK_DEFAULT_REGION="$REGION"

echo "📋 Configuración:"
echo "   - Modo de despliegue: $DEPLOY_MODE"
echo "   - Perfil AWS: $PROFILE"
echo "   - Región: $REGION"
echo ""

# Verificar sesión AWS
echo "🔐 Verificando sesión AWS..."
if ! aws sts get-caller-identity --profile "$PROFILE" > /dev/null 2>&1; then
    echo "⚠️  Error de autenticación. Intentando renovar sesión SSO..."
    if ! aws sso login --profile "$PROFILE"; then
        echo "❌ ERROR: No se pudo renovar la sesión SSO"
        exit 1
    fi
fi

IDENTITY=$(aws sts get-caller-identity --profile "$PROFILE" --output json)
ACCOUNT=$(echo "$IDENTITY" | jq -r '.Account')
USER_ARN=$(echo "$IDENTITY" | jq -r '.Arn')

echo "✅ Sesión AWS verificada"
echo "   - Account: $ACCOUNT"
echo "   - User: $USER_ARN"
echo ""

# Verificar si el stack ya existe
echo "🔍 Verificando si SharedNetworkStack ya existe..."
if aws cloudformation describe-stacks --stack-name SharedNetworkStack --profile "$PROFILE" --region "$REGION" > /dev/null 2>&1; then
    STACK_STATUS=$(aws cloudformation describe-stacks --stack-name SharedNetworkStack --profile "$PROFILE" --region "$REGION" --query 'Stacks[0].StackStatus' --output text)
    echo "⚠️  SharedNetworkStack ya existe con estado: $STACK_STATUS"
    
    if [[ "$STACK_STATUS" == *"COMPLETE"* ]]; then
        echo ""
        read -p "¿Desea actualizar el stack existente? (s/n): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            echo "❌ Operación cancelada por el usuario"
            exit 0
        fi
    fi
fi

echo ""
echo "🚀 Iniciando despliegue de SharedNetworkStack..."
echo "   Tiempo estimado: ~8 minutos"
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

# Desplegar el stack
echo "☁️  Desplegando SharedNetworkStack..."
START_TIME=$(date +%s)

if ! cdk deploy SharedNetworkStack --require-approval never --profile "$PROFILE"; then
    echo ""
    echo "============================================================================"
    echo "  ❌ ERROR durante el despliegue"
    echo "============================================================================"
    echo ""
    exit 1
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo "============================================================================"
echo "  ✅ SharedNetworkStack desplegado exitosamente"
echo "============================================================================"
echo ""
echo "⏱️  Tiempo de despliegue: ${MINUTES} minutos ${SECONDS} segundos"
echo ""

# Obtener outputs del stack
echo "📊 Outputs del stack:"
echo ""

aws cloudformation describe-stacks \
    --stack-name SharedNetworkStack \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
    --output text | while IFS=$'\t' read -r key value; do
    echo "   $key:"
    echo "      $value"
done

echo ""
echo "📝 Próximos pasos:"
echo "   1. Desplegar LegacyStacks para cada participante:"
echo "      ./scripts/instructor-deploy-legacy.sh"
echo ""
echo "   2. O desplegar para un participante específico:"
echo "      export DEPLOY_MODE=legacy"
echo "      export PARTICIPANT_PREFIX=participant-juan"
echo "      cd cdk"
echo "      cdk deploy participant-juan-MedicalReportsLegacyStack"
echo ""

cd ..

echo "✅ Script completado exitosamente"
echo ""
