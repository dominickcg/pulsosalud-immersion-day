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

# Obtener InformeId del argumento o usar el último informe
INFORME_ID="$1"

if [ -z "$INFORME_ID" ]; then
    echo -e "${CYAN}Obteniendo último informe...${NC}"
    
    QUERY="SELECT id FROM informes_medicos ORDER BY id DESC LIMIT 1"
    
    RESULT=$(aws rds-data execute-statement \
        --resource-arn "$CLUSTER_ARN" \
        --secret-arn "$SECRET_ARN" \
        --database "$DATABASE_NAME" \
        --sql "$QUERY" \
        --output json 2>&1)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR al obtener informe: $RESULT${NC}\n"
        exit 1
    fi
    
    INFORME_ID=$(echo "$RESULT" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['records'][0][0]['longValue']) if data.get('records') else exit(1)")
    
    if [ -z "$INFORME_ID" ]; then
        echo -e "${RED}ERROR: No se encontraron informes en la base de datos.${NC}\n"
        exit 1
    fi
    
    echo -e "${GREEN}Usando informe ID: $INFORME_ID${NC}\n"
fi

# Construir payload
PAYLOAD="{\"informe_id\": $INFORME_ID}"

echo -e "${CYAN}Invocando Lambda generate-embeddings...${NC}"
echo -e "${CYAN}Informe ID: $INFORME_ID${NC}"

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
        
        # Verificar en base de datos
        echo -e "\n${CYAN}Verificando en base de datos...${NC}"
        
        VERIFY_QUERY="SELECT ie.informe_id, im.tipo_examen, t.nombre as trabajador, LENGTH(ie.contenido) as longitud_texto, ie.created_at FROM informes_embeddings ie JOIN informes_medicos im ON ie.informe_id = im.id JOIN trabajadores t ON im.trabajador_id = t.id WHERE ie.informe_id = $INFORME_ID"
        
        DB_RESULT=$(aws rds-data execute-statement \
            --resource-arn "$CLUSTER_ARN" \
            --secret-arn "$SECRET_ARN" \
            --database "$DATABASE_NAME" \
            --sql "$VERIFY_QUERY" \
            --output json 2>&1)
        
        if [ $? -eq 0 ]; then
            RECORD_COUNT=$(echo "$DB_RESULT" | python3 -c "import sys, json; print(len(json.load(sys.stdin).get('records', [])))")
            
            if [ "$RECORD_COUNT" -gt 0 ]; then
                TRABAJADOR=$(echo "$DB_RESULT" | python3 -c "import sys, json; print(json.load(sys.stdin)['records'][0][2]['stringValue'])")
                TIPO_EXAMEN=$(echo "$DB_RESULT" | python3 -c "import sys, json; print(json.load(sys.stdin)['records'][0][1]['stringValue'])")
                LONGITUD=$(echo "$DB_RESULT" | python3 -c "import sys, json; print(json.load(sys.stdin)['records'][0][3]['longValue'])")
                
                echo -e "${GREEN}✓ Embedding almacenado correctamente en la base de datos${NC}"
                echo -e "${CYAN}  Trabajador: $TRABAJADOR${NC}"
                echo -e "${CYAN}  Tipo examen: $TIPO_EXAMEN${NC}"
                echo -e "${CYAN}  Longitud texto: $LONGITUD caracteres${NC}"
            fi
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
echo -e "1. Buscar informes similares: ./test-similarity-search.sh $INFORME_ID"
echo -e "2. Ver embeddings en BD: Ver query #14 en queries.sql\n"
