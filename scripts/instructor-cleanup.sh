#!/bin/bash

# ============================================================================
# Script: Limpieza completa de recursos del workshop
# Propósito: Eliminar todos los stacks desplegados para evitar costos
# Quién: Instructor
# Cuándo: Después del workshop
# Orden: AI Stacks → Legacy Stacks → Network Stack
# ============================================================================

set -e

CONFIG_FILE="${1:-config/participants.json}"
PROFILE="${2:-pulsosalud-immersion}"
REGION="${3:-us-east-2}"
SKIP_CONFIRMATION="${4:-false}"

echo ""
echo "============================================================================"
echo "  LIMPIEZA DE RECURSOS DEL WORKSHOP"
echo "============================================================================"
echo ""
echo "⚠️  ADVERTENCIA: Este script eliminará TODOS los recursos del workshop"
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
export AWS_PROFILE="$PROFILE"
export CDK_DEFAULT_REGION="$REGION"

echo "📋 Configuración:"
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

echo "✅ Sesión AWS verificada"
echo "   - Account: $ACCOUNT"
echo ""

# Obtener lista de participantes
PARTICIPANTS=""

if [ -f "$CONFIG_FILE" ]; then
    echo "📝 Leyendo lista de participantes desde: $CONFIG_FILE"
    PARTICIPANTS=$(jq -r '.participants[].prefix' "$CONFIG_FILE" 2>/dev/null || echo "")
fi

# Si no hay participantes, buscar stacks automáticamente
if [ -z "$PARTICIPANTS" ]; then
    echo "🔍 Buscando stacks del workshop en CloudFormation..."
    ALL_STACKS=$(aws cloudformation list-stacks \
        --profile "$PROFILE" \
        --region "$REGION" \
        --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
        --output json)
    
    PARTICIPANTS=$(echo "$ALL_STACKS" | jq -r '.StackSummaries[].StackName' | grep -E '^.+-MedicalReportsLegacyStack$' | sed 's/-MedicalReportsLegacyStack$//' | sort -u || echo "")
    
    if [ -z "$PARTICIPANTS" ]; then
        echo "⚠️  No se encontraron stacks del workshop"
        echo "   Verificando solo SharedNetworkStack..."
    fi
fi

PARTICIPANT_COUNT=$(echo "$PARTICIPANTS" | wc -l)

echo "   Total de participantes encontrados: $PARTICIPANT_COUNT"
if [ -n "$PARTICIPANTS" ]; then
    echo "$PARTICIPANTS" | while read -r p; do
        echo "   - $p"
    done
fi
echo ""

# Mostrar resumen de lo que se eliminará
echo "📊 Recursos que se eliminarán:"
echo ""
TOTAL_STACKS=0

if [ -n "$PARTICIPANTS" ] && [ "$PARTICIPANT_COUNT" -gt 0 ]; then
    echo "   Por cada participante ($PARTICIPANT_COUNT):"
    echo "      - 5 AI Stacks (Extraction, RAG, Classification, Summary, Email)"
    echo "      - 1 LegacyStack (Aurora, S3, API Gateway, Lambdas)"
    TOTAL_STACKS=$((PARTICIPANT_COUNT * 6))
fi

echo "   Infraestructura compartida:"
echo "      - 1 SharedNetworkStack (VPC, NAT Gateway)"
TOTAL_STACKS=$((TOTAL_STACKS + 1))

echo ""
echo "   Total de stacks a eliminar: $TOTAL_STACKS"
echo ""

# Confirmar con el usuario
if [ "$SKIP_CONFIRMATION" != "true" ]; then
    echo "⚠️  ADVERTENCIA: Esta acción NO se puede deshacer"
    echo ""
    read -p "¿Está seguro de que desea eliminar TODOS los recursos? (escriba 'SI' para confirmar): " -r
    if [ "$REPLY" != "SI" ]; then
        echo "❌ Operación cancelada por el usuario"
        exit 0
    fi
    echo ""
fi

START_TIME=$(date +%s)
ERRORS=()
SUCCESS_COUNT=0

# ============================================================================
# FASE 1: Eliminar AI Stacks
# ============================================================================

if [ -n "$PARTICIPANTS" ] && [ "$PARTICIPANT_COUNT" -gt 0 ]; then
    echo "============================================================================"
    echo "  FASE 1: Eliminando AI Stacks"
    echo "============================================================================"
    echo ""
    
    AI_STACKS=()
    while read -r participant; do
        [ -z "$participant" ] && continue
        AI_STACKS+=("${participant}-AIExtractionStack")
        AI_STACKS+=("${participant}-AIRAGStack")
        AI_STACKS+=("${participant}-AIClassificationStack")
        AI_STACKS+=("${participant}-AISummaryStack")
        AI_STACKS+=("${participant}-AIEmailStack")
    done <<< "$PARTICIPANTS"
    
    echo "🗑️  Eliminando ${#AI_STACKS[@]} AI Stacks..."
    echo ""
    
    cd cdk
    export DEPLOY_MODE="ai"
    
    for stack_name in "${AI_STACKS[@]}"; do
        echo "   Eliminando $stack_name..."
        if cdk destroy "$stack_name" --force --profile "$PROFILE" > /dev/null 2>&1; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            echo "   ✅ $stack_name eliminado"
        else
            ERRORS+=("AI Stack: $stack_name")
            echo "   ⚠️  Error al eliminar $stack_name"
        fi
    done
    
    cd ..
    
    echo ""
    echo "✅ Fase 1 completada: $SUCCESS_COUNT/${#AI_STACKS[@]} AI Stacks eliminados"
    echo ""
fi

# ============================================================================
# FASE 2: Eliminar Legacy Stacks
# ============================================================================

if [ -n "$PARTICIPANTS" ] && [ "$PARTICIPANT_COUNT" -gt 0 ]; then
    echo "============================================================================"
    echo "  FASE 2: Eliminando Legacy Stacks"
    echo "============================================================================"
    echo ""
    
    LEGACY_STACKS=()
    while read -r participant; do
        [ -z "$participant" ] && continue
        LEGACY_STACKS+=("${participant}-MedicalReportsLegacyStack")
    done <<< "$PARTICIPANTS"
    
    echo "🗑️  Eliminando ${#LEGACY_STACKS[@]} Legacy Stacks..."
    echo ""
    
    cd cdk
    export DEPLOY_MODE="legacy"
    
    for stack_name in "${LEGACY_STACKS[@]}"; do
        echo "   Eliminando $stack_name..."
        if cdk destroy "$stack_name" --force --profile "$PROFILE" > /dev/null 2>&1; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            echo "   ✅ $stack_name eliminado"
        else
            ERRORS+=("Legacy Stack: $stack_name")
            echo "   ⚠️  Error al eliminar $stack_name"
        fi
    done
    
    cd ..
    
    echo ""
    echo "✅ Fase 2 completada: Legacy Stacks procesados"
    echo ""
fi

# ============================================================================
# FASE 3: Eliminar SharedNetworkStack
# ============================================================================

echo "============================================================================"
echo "  FASE 3: Eliminando SharedNetworkStack"
echo "============================================================================"
echo ""

echo "🗑️  Eliminando SharedNetworkStack..."
echo ""

cd cdk
export DEPLOY_MODE="network"

echo "   Eliminando SharedNetworkStack..."
if cdk destroy SharedNetworkStack --force --profile "$PROFILE" > /dev/null 2>&1; then
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    echo "   ✅ SharedNetworkStack eliminado"
else
    ERRORS+=("SharedNetworkStack")
    echo "   ⚠️  Error al eliminar SharedNetworkStack"
fi

cd ..

echo ""
echo "✅ Fase 3 completada"
echo ""

# ============================================================================
# Resumen Final
# ============================================================================

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo "============================================================================"
echo "  LIMPIEZA COMPLETADA"
echo "============================================================================"
echo ""
echo "⏱️  Tiempo total: ${MINUTES} minutos ${SECONDS} segundos"
echo "✅ Stacks eliminados exitosamente: $SUCCESS_COUNT"

if [ ${#ERRORS[@]} -gt 0 ]; then
    echo "⚠️  Errores encontrados: ${#ERRORS[@]}"
    echo ""
    echo "Stacks con errores:"
    for error in "${ERRORS[@]}"; do
        echo "   - $error"
    done
    echo ""
    echo "💡 Verificar manualmente en la consola de CloudFormation:"
    echo "   https://console.aws.amazon.com/cloudformation"
fi

echo ""
echo "✅ Limpieza completada"
echo ""
