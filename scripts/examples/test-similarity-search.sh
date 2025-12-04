#!/bin/bash
# ============================================================================
# Script: Probar Búsqueda de Similitud con Embeddings
# Descripción: Busca los 5 informes más similares usando embeddings vectoriales
# ============================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}  Búsqueda de Similitud con Embeddings${NC}"
echo -e "${CYAN}========================================${NC}\n"

# Verificar que las variables de entorno estén configuradas
if [ -z "$PARTICIPANT_PREFIX" ]; then
    echo -e "${RED}ERROR: Variables de entorno no configuradas.${NC}"
    echo -e "${YELLOW}Ejecuta primero: source setup-env-vars-cloudshell.sh${NC}\n"
    exit 1
fi

# Obtener InformeId del argumento o usar el último con embedding
INFORME_ID="$1"
TOP_K="${2:-5}"

if [ -z "$INFORME_ID" ]; then
    echo -e "${CYAN}Obteniendo último informe con embedding...${NC}"
    
    QUERY="SELECT ie.informe_id, im.tipo_examen, t.nombre FROM informes_embeddings ie JOIN informes_medicos im ON ie.informe_id = im.id JOIN trabajadores t ON im.trabajador_id = t.id ORDER BY ie.created_at DESC LIMIT 1"
    
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
    
    RECORD_COUNT=$(echo "$RESULT" | python3 -c "import sys, json; print(len(json.load(sys.stdin).get('records', [])))")
    
    if [ "$RECORD_COUNT" -eq 0 ]; then
        echo -e "${RED}ERROR: No se encontraron informes con embeddings.${NC}"
        echo -e "${YELLOW}Ejecuta primero: ./invoke-embeddings.sh${NC}\n"
        exit 1
    fi
    
    INFORME_ID=$(echo "$RESULT" | python3 -c "import sys, json; print(json.load(sys.stdin)['records'][0][0]['longValue'])")
    TIPO_EXAMEN=$(echo "$RESULT" | python3 -c "import sys, json; print(json.load(sys.stdin)['records'][0][1]['stringValue'])")
    TRABAJADOR=$(echo "$RESULT" | python3 -c "import sys, json; print(json.load(sys.stdin)['records'][0][2]['stringValue'])")
    
    echo -e "${GREEN}Usando informe ID: $INFORME_ID${NC}"
    echo -e "${CYAN}  Trabajador: $TRABAJADOR${NC}"
    echo -e "${CYAN}  Tipo examen: $TIPO_EXAMEN${NC}\n"
fi

# Verificar que el informe tiene embedding
echo -e "${CYAN}Verificando que el informe tiene embedding...${NC}"

VERIFY_QUERY="SELECT im.id, t.nombre as trabajador, im.tipo_examen, im.nivel_riesgo, im.observaciones, ie.id as embedding_id FROM informes_medicos im JOIN trabajadores t ON im.trabajador_id = t.id LEFT JOIN informes_embeddings ie ON im.id = ie.informe_id WHERE im.id = $INFORME_ID"

VERIFY_RESULT=$(aws rds-data execute-statement \
    --resource-arn "$CLUSTER_ARN" \
    --secret-arn "$SECRET_ARN" \
    --database "$DATABASE_NAME" \
    --sql "$VERIFY_QUERY" \
    --output json 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR al verificar informe: $VERIFY_RESULT${NC}\n"
    exit 1
fi

RECORD_COUNT=$(echo "$VERIFY_RESULT" | python3 -c "import sys, json; print(len(json.load(sys.stdin).get('records', [])))")

if [ "$RECORD_COUNT" -eq 0 ]; then
    echo -e "${RED}ERROR: Informe $INFORME_ID no encontrado.${NC}\n"
    exit 1
fi

# Extraer datos del informe
TRABAJADOR=$(echo "$VERIFY_RESULT" | python3 -c "import sys, json; print(json.load(sys.stdin)['records'][0][1]['stringValue'])")
TIPO_EXAMEN=$(echo "$VERIFY_RESULT" | python3 -c "import sys, json; print(json.load(sys.stdin)['records'][0][2]['stringValue'])")
NIVEL_RIESGO=$(echo "$VERIFY_RESULT" | python3 -c "import sys, json; r=json.load(sys.stdin)['records'][0][3]; print(r.get('stringValue', 'No clasificado'))")
OBSERVACIONES=$(echo "$VERIFY_RESULT" | python3 -c "import sys, json; r=json.load(sys.stdin)['records'][0][4]; print(r.get('stringValue', 'N/A'))")
EMBEDDING_ID=$(echo "$VERIFY_RESULT" | python3 -c "import sys, json; r=json.load(sys.stdin)['records'][0][5]; print(r.get('longValue', '') if not r.get('isNull') else '')")

if [ -z "$EMBEDDING_ID" ]; then
    echo -e "${RED}ERROR: El informe $INFORME_ID no tiene embedding generado.${NC}"
    echo -e "${YELLOW}Ejecuta primero: ./invoke-embeddings.sh $INFORME_ID${NC}\n"
    exit 1
fi

echo -e "${GREEN}✓ Informe de referencia encontrado${NC}"
echo -e "\n${CYAN}--- Informe de Referencia ---${NC}"
echo -e "${CYAN}ID: $INFORME_ID${NC}"
echo -e "${CYAN}Trabajador: $TRABAJADOR${NC}"
echo -e "${CYAN}Tipo examen: $TIPO_EXAMEN${NC}"
echo -e "${CYAN}Nivel de riesgo: $NIVEL_RIESGO${NC}"

if [ ${#OBSERVACIONES} -gt 100 ]; then
    OBSERVACIONES_PREVIEW="${OBSERVACIONES:0:100}..."
else
    OBSERVACIONES_PREVIEW="$OBSERVACIONES"
fi
echo -e "${CYAN}Observaciones: $OBSERVACIONES_PREVIEW${NC}"

# Ejecutar búsqueda de similitud
echo -e "\n${CYAN}Buscando informes similares...${NC}"

SIMILARITY_QUERY="SELECT im.id, t.nombre as trabajador, im.tipo_examen, im.nivel_riesgo, im.fecha_examen, LEFT(im.observaciones, 150) as observaciones_preview, 1 - (ie1.embedding <=> ie2.embedding) as similarity_score FROM informes_medicos im JOIN informes_embeddings ie1 ON im.id = ie1.informe_id JOIN trabajadores t ON im.trabajador_id = t.id CROSS JOIN informes_embeddings ie2 WHERE ie2.informe_id = $INFORME_ID AND im.id != $INFORME_ID ORDER BY similarity_score DESC LIMIT $TOP_K"

START_TIME=$(date +%s%3N)

SIMILARITY_RESULT=$(aws rds-data execute-statement \
    --resource-arn "$CLUSTER_ARN" \
    --secret-arn "$SECRET_ARN" \
    --database "$DATABASE_NAME" \
    --sql "$SIMILARITY_QUERY" \
    --output json 2>&1)

if [ $? -ne 0 ]; then
    echo -e "\n${RED}ERROR al buscar similitud: $SIMILARITY_RESULT${NC}\n"
    exit 1
fi

END_TIME=$(date +%s%3N)
DURATION=$((END_TIME - START_TIME))

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Resultados de Búsqueda de Similitud${NC}"
echo -e "${GREEN}========================================${NC}\n"

RECORD_COUNT=$(echo "$SIMILARITY_RESULT" | python3 -c "import sys, json; print(len(json.load(sys.stdin).get('records', [])))")

if [ "$RECORD_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}No se encontraron informes similares.${NC}"
    echo -e "${CYAN}Esto puede ocurrir si:${NC}"
    echo -e "${CYAN}  - Solo hay un informe con embedding en la base de datos${NC}"
    echo -e "${CYAN}  - Los otros informes no tienen embeddings generados${NC}\n"
else
    echo -e "${GREEN}Encontrados $RECORD_COUNT informes similares${NC}"
    echo -e "${CYAN}Tiempo de búsqueda: $DURATION ms${NC}\n"
    
    # Mostrar resultados
    COUNTER=1
    echo "$SIMILARITY_RESULT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for record in data.get('records', []):
    id_val = record[0]['longValue']
    trabajador = record[1]['stringValue']
    tipo_examen = record[2]['stringValue']
    nivel_riesgo = record[3].get('stringValue', 'N/A')
    fecha_examen = record[4]['stringValue']
    observaciones = record[5].get('stringValue', 'N/A')
    similarity = round(record[6]['doubleValue'], 4)
    
    print(f'[{sys.argv[1]}] Informe ID: {id_val}')
    print(f'    Similitud: {similarity}')
    print(f'    Trabajador: {trabajador}')
    print(f'    Tipo examen: {tipo_examen}')
    print(f'    Nivel riesgo: {nivel_riesgo}')
    print(f'    Fecha examen: {fecha_examen}')
    if observaciones != 'N/A':
        print(f'    Observaciones: {observaciones}...')
    print()
    sys.argv[1] = str(int(sys.argv[1]) + 1)
" "$COUNTER"
    
    # Estadísticas
    echo -e "${CYAN}--- Estadísticas ---${NC}"
    echo "$SIMILARITY_RESULT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
scores = [record[6]['doubleValue'] for record in data.get('records', [])]
if scores:
    print(f'Similitud promedio: {round(sum(scores)/len(scores), 4)}')
    print(f'Similitud máxima: {round(max(scores), 4)}')
    print(f'Similitud mínima: {round(min(scores), 4)}')
"
fi

echo -e "\n${CYAN}========================================${NC}\n"

# Explicación pedagógica
echo -e "${CYAN}¿Cómo funciona la búsqueda de similitud?${NC}"
echo -e "${GRAY}1. Cada informe se convierte en un vector de 1024 dimensiones${NC}"
echo -e "${GRAY}2. Se calcula la distancia de coseno entre vectores${NC}"
echo -e "${GRAY}3. Similitud = 1 - distancia (1 = idénticos, 0 = no relacionados)${NC}"
echo -e "${GRAY}4. Se retornan los $TOP_K informes más similares${NC}\n"

# Sugerencias
echo -e "${CYAN}Próximos pasos:${NC}"
echo -e "${GRAY}1. Comparar con búsqueda SQL tradicional (solo mismo trabajador)${NC}"
echo -e "${GRAY}2. Generar más embeddings: ./invoke-embeddings.sh${NC}"
echo -e "${GRAY}3. Ver queries de embeddings: Ver queries #13-18 en queries.sql${NC}\n"
