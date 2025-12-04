#!/bin/bash
# ============================================================================
# Script: Invocar Lambda de Generación de Embeddings
# Descripción: Genera embeddings vectoriales para un informe médico
# ============================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}  Generación de Embeddings Vectoriales${NC}"
echo -e "${CYAN}========================================${NC}\n"

# Verificar que las variables de entorno estén configuradas
if [ -z "$PARTICIPANT_PREFIX" ]; then
    echo -e "${RED}ERROR: Variables de entorno no configuradas.${NC}"
    echo -e "${YELLOW}Ejecuta primero: source setup-env-vars-cloudshell.sh${NC}\n"
    exit 1
fi

# Obtener InformeId del argumento o procesar todos
INFORME_ID="$1"

if [ -z "$INFORME_ID" ]; then
    echo -e "${CYAN}Generando embeddings para TODOS los informes sin embeddings...${NC}\n"
    PAYLOAD="{}"
    MODE="all"
else
    echo -e "${CYAN}Generando embedding para informe ID: $INFORME_ID${NC}\n"
    PAYLOAD="{\"informe_id\": $INFORME_ID}"
    MODE="single"
fi

echo -e "${CYAN}Invocando Lambda generate-embeddings...${NC}"

# Medir tiempo de ejecución
START_TIME=$(date +%s)

# Invocar Lambda
LAMBDA_NAME="$PARTICIPANT_PREFIX-generate-embeddings"

aws lambda invoke \
    --function-name "$LAMBDA_NAME" \
    --cli-binary-format raw-in-base64-out \
    --payload "$PAYLOAD" \
    embeddings_response.json > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo -e "\n${RED}ERROR al invocar Lambda${NC}\n"
    rm -f embeddings_response.json
    exit 1
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Leer respuesta
if [ -f embeddings_response.json ]; then
    RESULT=$(cat embeddings_response.json)
    
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}  Resultado de Generación de Embeddings${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    
    # Verificar si es JSON válido
    if ! echo "$RESULT" | python3 -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
        echo -e "${RED}ERROR: La respuesta no es JSON válido${NC}"
        echo -e "${YELLOW}Contenido de la respuesta:${NC}"
        cat embeddings_response.json
        rm -f embeddings_response.json
        exit 1
    fi
    
    STATUS_CODE=$(echo "$RESULT" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('statusCode', 0))" 2>/dev/null || echo "0")
    
    if [ "$STATUS_CODE" = "200" ]; then
        PROCESSED=$(echo "$RESULT" | python3 -c "import sys, json; data=json.load(sys.stdin); body=json.loads(data.get('body', '{}')); print(body.get('processed', 0))" 2>/dev/null || echo "0")
        TOTAL=$(echo "$RESULT" | python3 -c "import sys, json; data=json.load(sys.stdin); body=json.loads(data.get('body', '{}')); print(body.get('total', 0))" 2>/dev/null || echo "0")
        
        if [ "$PROCESSED" = "0" ]; then
            echo -e "${RED}Estado: ERROR - No se procesó el informe${NC}"
            echo -e "${RED}Procesados: $PROCESSED / $TOTAL${NC}"
            echo -e "\n${YELLOW}⚠ TROUBLESHOOTING:${NC}"
            echo -e "${YELLOW}Ver logs de la Lambda para más detalles:${NC}"
            echo -e "  aws logs tail /aws/lambda/$LAMBDA_NAME --since 5m\n"
            rm -f embeddings_response.json
            exit 1
        fi
        
        echo -e "${GREEN}Estado: ÉXITO${NC}"
        echo -e "${GREEN}Procesados: $PROCESSED / $TOTAL${NC}"
        echo -e "\n${CYAN}Tiempo de procesamiento: $DURATION segundos${NC}"
        
        # Mostrar detalles de los embeddings generados
        if [ "$PROCESSED" -gt 0 ]; then
            echo -e "\n${CYAN}Embeddings generados:${NC}"
            
            # Extraer detalles del body de la respuesta
            DETAILS_JSON=$(echo "$RESULT" | python3 -c "import sys, json; data=json.load(sys.stdin); body=json.loads(data.get('body', '{}')); print(json.dumps(body.get('details', [])))" 2>/dev/null || echo "[]")
            
            # Mostrar cada embedding generado
            echo "$DETAILS_JSON" | python3 -c "
import sys, json
details = json.load(sys.stdin)
for i, detail in enumerate(details, 1):
    print(f\"  [{i}] ID: {detail.get('informe_id', 'N/A')}\")
    print(f\"      Trabajador: {detail.get('trabajador', 'N/A')}\")
    print(f\"      Tipo examen: {detail.get('tipo_examen', 'N/A')}\")
    print(f\"      Longitud texto: {detail.get('longitud_texto', 0)} caracteres\")
    if i < len(details):
        print()
" 2>/dev/null || echo -e "${GREEN}  ✓ $PROCESSED embedding(s) generado(s) correctamente${NC}"
        fi
        
    else
        echo -e "${RED}Estado: ERROR${NC}"
        echo -e "${RED}Código: $STATUS_CODE${NC}"
        echo -e "${RED}Mensaje: $RESULT${NC}"
    fi
    
    # Limpiar archivo temporal
    rm -f embeddings_response.json
    
else
    echo -e "${RED}ERROR: No se pudo leer la respuesta de Lambda.${NC}\n"
    exit 1
fi

echo -e "\n${CYAN}========================================${NC}\n"

# Sugerencias
echo -e "${CYAN}Próximos pasos:${NC}"
if [ "$MODE" = "single" ]; then
    echo -e "1. Buscar informes similares: ./test-similarity-search.sh $INFORME_ID"
else
    echo -e "1. Buscar informes similares: ./test-similarity-search.sh <informe_id>"
fi
echo -e "2. Comparar SQL vs Embeddings: ./demo-rag-comparison.sh\n"
