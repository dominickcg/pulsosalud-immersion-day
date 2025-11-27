#!/bin/bash

# ============================================================================
# Script: Despliegue de LegacyStacks para múltiples participantes
# Propósito: Desplegar Aurora, S3 y Lambdas Legacy para cada participante
# Quién: Instructor
# Cuándo: Antes del workshop (después de desplegar SharedNetworkStack)
# Tiempo estimado: ~15 minutos por participante (pueden ejecutarse en paralelo)
# ============================================================================

set -e

CONFIG_FILE="${1:-config/participants.json}"
PROFILE="${2:-pulsosalud-immersion}"
REGION="${3:-us-east-2}"
CONCURRENCY="${4:-3}"

echo ""
echo "============================================================================"
echo "  Despliegue de LegacyStacks - Infraestructura por Participante"
echo "============================================================================"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "cdk/bin/app.ts" ]; then
    echo "❌ ERROR: Este script debe ejecutarse desde la raíz del proyecto"
    echo "   Directorio actual: $(pwd)"
    exit 1
fi

# Verificar que jq está instalado
if ! command -v jq &> /dev/null; then
    echo "❌ ERROR: jq no está instalado"
    echo "   Instalar con: sudo apt-get install jq (Ubuntu/Debian)"
    echo "   O: brew install jq (macOS)"
    exit 1
fi

# Configurar variables de entorno
export DEPLOY_MODE="legacy"
export AWS_PROFILE="$PROFILE"
export CDK_DEFAULT_REGION="$REGION"

echo "📋 Configuración:"
echo "   - Modo de despliegue: $DEPLOY_MODE"
echo "   - Perfil AWS: $PROFILE"
echo "   - Región: $REGION"
echo "   - Concurrencia: $CONCURRENCY stacks en paralelo"
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

echo "✅ Sesión AWS verificada"
echo "   - Account: $ACCOUNT"
echo ""

# Verificar que SharedNetworkStack existe
echo "🔍 Verificando que SharedNetworkStack existe..."
if ! aws cloudformation describe-stacks --stack-name SharedNetworkStack --profile "$PROFILE" --region "$REGION" > /dev/null 2>&1; then
    echo "❌ ERROR: SharedNetworkStack no encontrado"
    echo ""
    echo "   Debe desplegar SharedNetworkStack primero:"
    echo "   ./scripts/instructor-deploy-network.sh"
    echo ""
    exit 1
fi
echo "✅ SharedNetworkStack encontrado"
echo ""

# Obtener lista de participantes
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ ERROR: Archivo de configuración no encontrado: $CONFIG_FILE"
    echo ""
    echo "   Crear el archivo con el siguiente formato:"
    echo '   {"participants": [{"prefix": "participant-1"}, {"prefix": "participant-2"}]}'
    echo ""
    exit 1
fi

echo "📝 Leyendo lista de participantes desde: $CONFIG_FILE"
PARTICIPANTS=$(jq -r '.participants[].prefix' "$CONFIG_FILE")
PARTICIPANT_COUNT=$(echo "$PARTICIPANTS" | wc -l)

echo "   Total de participantes: $PARTICIPANT_COUNT"
echo "$PARTICIPANTS" | while read -r p; do
    echo "   - $p"
done
echo ""

# Calcular tiempo estimado
TOTAL_TIME=$(( (PARTICIPANT_COUNT + CONCURRENCY - 1) / CONCURRENCY * 15 ))
echo "⏱️  Tiempo estimado total: ~${TOTAL_TIME} minutos"
echo "   (Desplegando $CONCURRENCY stacks en paralelo)"
echo ""

read -p "¿Continuar con el despliegue? (s/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Operación cancelada por el usuario"
    exit 0
fi

echo ""
echo "🚀 Iniciando despliegue de LegacyStacks..."
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

# Construir lista de stacks para desplegar
STACK_NAMES=""
while read -r participant; do
    STACK_NAMES="$STACK_NAMES ${participant}-MedicalReportsLegacyStack"
done <<< "$PARTICIPANTS"

# Desplegar stacks en paralelo
echo "☁️  Desplegando $PARTICIPANT_COUNT LegacyStacks con concurrencia $CONCURRENCY..."
echo ""
echo "   Ejecutando: cdk deploy$STACK_NAMES --require-approval never --concurrency $CONCURRENCY"
echo ""

START_TIME=$(date +%s)

if ! cdk deploy$STACK_NAMES --require-approval never --concurrency "$CONCURRENCY" --profile "$PROFILE"; then
    echo ""
    echo "============================================================================"
    echo "  ❌ ERROR durante el despliegue"
    echo "============================================================================"
    echo ""
    echo "⚠️  Algunos stacks pueden haberse desplegado exitosamente."
    echo "   Revisar la consola de CloudFormation para más detalles."
    echo ""
    exit 1
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo "============================================================================"
echo "  ✅ LegacyStacks desplegados exitosamente"
echo "============================================================================"
echo ""
echo "⏱️  Tiempo total de despliegue: ${MINUTES} minutos ${SECONDS} segundos"
echo ""

# Generar reporte de outputs
echo "📊 Generando reporte de outputs..."
echo ""

REPORT_FILE="deployment-report-legacy-$(date +%Y%m%d-%H%M%S).json"
echo "[" > "$REPORT_FILE"

FIRST=true
while read -r participant; do
    STACK_NAME="${participant}-MedicalReportsLegacyStack"
    echo "   Obteniendo outputs de $STACK_NAME..."
    
    if [ "$FIRST" = false ]; then
        echo "," >> "$REPORT_FILE"
    fi
    FIRST=false
    
    echo "  {" >> "$REPORT_FILE"
    echo "    \"participant\": \"$participant\"," >> "$REPORT_FILE"
    echo "    \"stackName\": \"$STACK_NAME\"," >> "$REPORT_FILE"
    echo "    \"outputs\": {" >> "$REPORT_FILE"
    
    OUTPUTS=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs' \
        --output json 2>/dev/null || echo "[]")
    
    echo "$OUTPUTS" | jq -r '.[] | "      \"" + .OutputKey + "\": \"" + .OutputValue + "\","' | sed '$ s/,$//' >> "$REPORT_FILE"
    
    echo "    }" >> "$REPORT_FILE"
    echo "  }" >> "$REPORT_FILE"
done <<< "$PARTICIPANTS"

echo "]" >> "$REPORT_FILE"

echo ""
echo "✅ Reporte guardado en: $REPORT_FILE"
echo ""

# Mostrar resumen
echo "📋 Resumen de despliegue:"
echo ""

jq -r '.[] | "   \(.participant):\n      API URL: \(.outputs.ApiUrl)\n      Bucket: \(.outputs.BucketName)\n"' "$REPORT_FILE"

echo "📝 Próximos pasos:"
echo "   1. Los participantes pueden ahora desplegar sus AI Stacks durante el workshop"
echo "   2. Compartir con cada participante:"
echo "      - Su PARTICIPANT_PREFIX"
echo "      - Instrucciones para desplegar AI Stacks"
echo ""

cd ..

echo "✅ Script completado exitosamente"
echo ""
