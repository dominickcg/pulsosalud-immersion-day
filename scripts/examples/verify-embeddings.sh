#!/bin/bash
# ============================================================================
# Script: Verificar Embeddings Generados
# Descripción: Consulta la tabla informes_embeddings usando RDS Data API
# ============================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}Verificación de Embeddings Generados${NC}"
echo -e "${CYAN}========================================\n${NC}"

# Verificar que las variables de entorno estén configuradas
if [ -z "$PARTICIPANT_PREFIX" ]; then
    echo -e "${RED}ERROR: Variables de entorno no configuradas.${NC}"
    echo -e "${YELLOW}Ejecuta primero: source setup-env-vars-cloudshell.sh\n${NC}"
    exit 1
fi

if [ -z "$CLUSTER_ARN" ] || [ -z "$SECRET_ARN" ]; then
    echo -e "${RED}ERROR: Variables de Aurora no configuradas.${NC}"
    echo -e "${YELLOW}Ejecuta primero: source setup-env-vars-cloudshell.sh\n${NC}"
    exit 1
fi

# Parámetro opcional: informe_id específico
INFORME_ID=$1

if [ -z "$INFORME_ID" ]; then
    # Sin parámetro: mostrar todos los embeddings
    echo -e "${CYAN}Consultando todos los embeddings...${NC}\n"
    
    SQL="SELECT ie.informe_id, im.tipo_examen, im.nivel_riesgo, t.nombre as trabajador,
         LENGTH(ie.embedding::text) as embedding_size,
         ie.created_at
         FROM informes_embeddings ie
         JOIN informes_medicos im ON ie.informe_id = im.id
         JOIN trabajadores t ON im.trabajador_id = t.id
         ORDER BY ie.created_at DESC"
else
    # Con parámetro: mostrar embedding específico
    echo -e "${CYAN}Consultando embedding del informe ID: $INFORME_ID${NC}\n"
    
    SQL="SELECT ie.informe_id, im.tipo_examen, im.nivel_riesgo, t.nombre as trabajador,
         LENGTH(ie.embedding::text) as embedding_size,
         ie.created_at
         FROM informes_embeddings ie
         JOIN informes_medicos im ON ie.informe_id = im.id
         JOIN trabajadores t ON im.trabajador_id = t.id
         WHERE ie.informe_id = $INFORME_ID"
fi

# Ejecutar query
RESULT=$(aws rds-data execute-statement \
  --resource-arn "$CLUSTER_ARN" \
  --secret-arn "$SECRET_ARN" \
  --database "$DATABASE_NAME" \
  --sql "$SQL" \
  --output json 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR al consultar la base de datos:${NC}"
    echo -e "${GRAY}$RESULT${NC}\n"
    exit 1
fi

# Verificar si hay resultados
RECORD_COUNT=$(echo "$RESULT" | jq '.records | length' 2>/dev/null)

if [ -z "$RECORD_COUNT" ] || [ "$RECORD_COUNT" = "0" ]; then
    if [ -z "$INFORME_ID" ]; then
        echo -e "${YELLOW}⚠ No hay embeddings generados todavía.${NC}"
        echo -e "${CYAN}Genera embeddings con: ./invoke-embeddings.sh${NC}\n"
    else
        echo -e "${YELLOW}⚠ No existe embedding para el informe ID: $INFORME_ID${NC}"
        echo -e "${CYAN}Genera el embedding con: ./invoke-embeddings.sh $INFORME_ID${NC}\n"
    fi
    exit 0
fi

# Mostrar resultados
echo -e "${GREEN}✓ Embeddings encontrados: $RECORD_COUNT${NC}\n"

echo -e "${CYAN}┌──────────┬─────────────────────┬──────────────┬─────────────────────────┬──────────────┐${NC}"
echo -e "${CYAN}│ Informe  │ Tipo Examen         │ Riesgo       │ Trabajador              │ Vector Size  │${NC}"
echo -e "${CYAN}├──────────┼─────────────────────┼──────────────┼─────────────────────────┼──────────────┤${NC}"

# Parsear y mostrar cada registro
echo "$RESULT" | jq -r '.records[] | 
  [
    .[] | 
    if .longValue then .longValue 
    elif .stringValue then .stringValue 
    else "" end
  ] | 
  @tsv' | while IFS=$'\t' read -r informe_id tipo_examen nivel_riesgo trabajador embedding_size created_at; do
    
    # Truncar nombres largos
    tipo_examen_short=$(echo "$tipo_examen" | cut -c1-19)
    trabajador_short=$(echo "$trabajador" | cut -c1-23)
    
    printf "${GRAY}│ %-8s │ %-19s │ %-12s │ %-23s │ %-12s │${NC}\n" \
      "$informe_id" "$tipo_examen_short" "$nivel_riesgo" "$trabajador_short" "$embedding_size bytes"
done

echo -e "${CYAN}└──────────┴─────────────────────┴──────────────┴─────────────────────────┴──────────────┘${NC}\n"

# Información adicional
echo -e "${CYAN}Información sobre embeddings:${NC}"
echo -e "${GRAY}• Cada embedding es un vector de 1536 dimensiones (Amazon Titan)${NC}"
echo -e "${GRAY}• El tamaño mostrado es la representación en texto del vector${NC}"
echo -e "${GRAY}• Los embeddings capturan el significado semántico del informe${NC}\n"

if [ -z "$INFORME_ID" ]; then
    echo -e "${CYAN}Para ver un embedding específico:${NC}"
    echo -e "${GRAY}./verify-embeddings.sh <informe_id>${NC}\n"
else
    echo -e "${CYAN}Para buscar informes similares:${NC}"
    echo -e "${GRAY}./test-similarity-search.sh $INFORME_ID${NC}\n"
fi
