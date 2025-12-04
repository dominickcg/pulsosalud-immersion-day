#!/bin/bash
# ============================================================================
# Script: Demostración de Comparación RAG Día 1 vs Día 2
# Descripción: Muestra la diferencia entre búsqueda SQL y búsqueda semántica
# ============================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

echo -e "\n${MAGENTA}============================================================================${NC}"
echo -e "${MAGENTA}  DEMOSTRACIÓN: RAG Día 1 (SQL) vs Día 2 (Embeddings Vectoriales)${NC}"
echo -e "${MAGENTA}============================================================================\n${NC}"

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

echo -e "${CYAN}Esta demostración muestra por qué necesitamos embeddings vectoriales${NC}"
echo -e "${CYAN}para búsqueda semántica en lugar de solo SQL.\n${NC}"

# ============================================================================
# PARTE 1: RAG DÍA 1 - BÚSQUEDA SQL SIMPLE
# ============================================================================

echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}  PARTE 1: RAG Día 1 - Búsqueda SQL Simple${NC}"
echo -e "${CYAN}============================================================================\n${NC}"

echo -e "${CYAN}En el Día 1, usamos SQL para buscar informes del MISMO trabajador:\n${NC}"

# Seleccionar un trabajador para el ejemplo
echo -e "${CYAN}Obteniendo trabajador de ejemplo...${NC}"

# Verificar que hay trabajadores en la base de datos
TOTAL_TRABAJADORES=$(aws rds-data execute-statement \
  --resource-arn "$CLUSTER_ARN" \
  --secret-arn "$SECRET_ARN" \
  --database "$DATABASE_NAME" \
  --sql "SELECT COUNT(*) FROM trabajadores" \
  --output text 2>/dev/null | awk '{print $NF}')

if [ -z "$TOTAL_TRABAJADORES" ] || [ "$TOTAL_TRABAJADORES" = "0" ]; then
    echo -e "${RED}ERROR: No hay trabajadores en la base de datos.${NC}"
    echo -e "${YELLOW}Los datos de seed no están cargados.${NC}"
    echo -e "${YELLOW}Contacta al instructor para que verifique el despliegue del LegacyStack.\n${NC}"
    exit 1
fi

# Usar el primer trabajador disponible (del seed data)
TRABAJADOR_ID=1
TRABAJADOR_NOMBRE="Juan Carlos Pérez García"

echo -e "${GREEN}✓ Trabajador seleccionado: $TRABAJADOR_NOMBRE (ID: $TRABAJADOR_ID)${NC}"
echo -e "${GRAY}  Total de trabajadores en la base de datos: $TOTAL_TRABAJADORES${NC}\n"

# Mostrar query SQL del Día 1
echo -e "${CYAN}Query SQL del Día 1:${NC}"
echo -e "${GRAY}---${NC}"
SQL_DAY1="SELECT * FROM informes_medicos WHERE trabajador_id = $TRABAJADOR_ID ORDER BY fecha_examen DESC"
echo -e "${GRAY}$SQL_DAY1${NC}"
echo -e "${GRAY}---\n${NC}"

echo -e "${CYAN}Ejecutando búsqueda SQL...${NC}"

SQL_RESULT=$(aws rds-data execute-statement \
  --resource-arn "$CLUSTER_ARN" \
  --secret-arn "$SECRET_ARN" \
  --database "$DATABASE_NAME" \
  --sql "$SQL_DAY1" \
  --output json 2>/dev/null)

if [ $? -eq 0 ]; then
    RECORD_COUNT=$(echo "$SQL_RESULT" | grep -o '"records":\[' | wc -l)
    echo -e "\n${GREEN}Resultados de búsqueda SQL:${NC}"
    echo -e "${GREEN}✓ Informes encontrados del mismo trabajador${NC}"
    echo -e "${CYAN}  (Solo informes del mismo trabajador)\n${NC}"
else
    echo -e "${RED}ERROR al ejecutar query SQL\n${NC}"
fi

echo -e "${YELLOW}Problema con SQL:${NC}"
echo -e "${GRAY}• Solo busca coincidencias EXACTAS (mismo trabajador_id)${NC}"
echo -e "${GRAY}• No entiende similitud SEMÁNTICA${NC}"
echo -e "${GRAY}• No puede encontrar casos SIMILARES de otros trabajadores${NC}"
echo -e "${GRAY}• Trabajadores nuevos = Sin contexto\n${NC}"

# ============================================================================
# PARTE 2: RAG DÍA 2 - BÚSQUEDA CON EMBEDDINGS
# ============================================================================

echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}  PARTE 2: RAG Día 2 - Búsqueda Semántica con Embeddings${NC}"
echo -e "${CYAN}============================================================================\n${NC}"

echo -e "${CYAN}En el Día 2, usamos embeddings para buscar casos SIMILARES:\n${NC}"

# Verificar si hay embeddings
echo -e "${CYAN}Verificando embeddings disponibles...${NC}"

QUERY_EMBEDDINGS="SELECT COUNT(*) as total FROM informes_embeddings"

EMBEDDINGS_COUNT=$(aws rds-data execute-statement \
  --resource-arn "$CLUSTER_ARN" \
  --secret-arn "$SECRET_ARN" \
  --database "$DATABASE_NAME" \
  --sql "$QUERY_EMBEDDINGS" \
  --output json 2>/dev/null)

if [ $? -eq 0 ]; then
    TOTAL_EMBEDDINGS=$(echo "$EMBEDDINGS_COUNT" | grep -o '"longValue":[0-9]*' | head -1 | cut -d':' -f2)
    
    # Validar que TOTAL_EMBEDDINGS no esté vacío
    if [ -z "$TOTAL_EMBEDDINGS" ]; then
        TOTAL_EMBEDDINGS=0
    fi
    
    if [ "$TOTAL_EMBEDDINGS" -eq 0 ]; then
        echo -e "${YELLOW}⚠ No hay embeddings generados todavía.${NC}"
        echo -e "${CYAN}Ejecuta: aws lambda invoke para generar embeddings\n${NC}"
        HAS_EMBEDDINGS=false
    else
        echo -e "${GREEN}✓ $TOTAL_EMBEDDINGS embeddings disponibles${NC}"
        HAS_EMBEDDINGS=true
    fi
else
    echo -e "${RED}ERROR al verificar embeddings\n${NC}"
    HAS_EMBEDDINGS=false
fi

# Mostrar query con embeddings
echo -e "${CYAN}Query con Embeddings del Día 2:${NC}"
echo -e "${GRAY}---${NC}"
echo -e "${GRAY}SELECT im.id, t.nombre, im.tipo_examen, im.nivel_riesgo,${NC}"
echo -e "${GRAY}       1 - (ie1.embedding <=> ie2.embedding) as similarity_score${NC}"
echo -e "${GRAY}FROM informes_medicos im${NC}"
echo -e "${GRAY}JOIN informes_embeddings ie1 ON im.id = ie1.informe_id${NC}"
echo -e "${GRAY}CROSS JOIN informes_embeddings ie2${NC}"
echo -e "${GRAY}WHERE ie2.informe_id = [informe_referencia]${NC}"
echo -e "${GRAY}  AND im.trabajador_id != $TRABAJADOR_ID${NC}"
echo -e "${GRAY}ORDER BY similarity_score DESC LIMIT 5${NC}"
echo -e "${GRAY}---\n${NC}"

echo -e "\n${GREEN}Ventajas de Embeddings:${NC}"
echo -e "${GRAY}• Busca similitud SEMÁNTICA, no solo coincidencias exactas${NC}"
echo -e "${GRAY}• Entiende sinónimos y conceptos relacionados${NC}"
echo -e "${GRAY}• Encuentra casos SIMILARES de CUALQUIER trabajador${NC}"
echo -e "${GRAY}• Trabajadores nuevos = Contexto de casos similares\n${NC}"

# ============================================================================
# PARTE 3: TABLA COMPARATIVA
# ============================================================================

echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}  PARTE 3: Comparación Directa${NC}"
echo -e "${CYAN}============================================================================\n${NC}"

echo -e "${CYAN}┌─────────────────────────┬──────────────────────┬──────────────────────────┐${NC}"
echo -e "${CYAN}│ Aspecto                 │ SQL (Día 1)          │ Embeddings (Día 2)       │${NC}"
echo -e "${CYAN}├─────────────────────────┼──────────────────────┼──────────────────────────┤${NC}"
echo -e "${GRAY}│ Tipo de búsqueda        │ Exacta/Rangos        │ Semántica                │${NC}"
echo -e "${GRAY}│ Sinónimos               │ No entiende          │ Sí entiende              │${NC}"
echo -e "${GRAY}│ Contexto                │ Campo por campo      │ Holístico                │${NC}"
echo -e "${GRAY}│ Mantenimiento           │ Manual               │ Automático               │${NC}"
echo -e "${GRAY}│ Flexibilidad            │ Rígida               │ Adaptativa               │${NC}"
echo -e "${GRAY}│ Trabajadores nuevos     │ Sin resultados       │ Encuentra similares      │${NC}"
echo -e "${CYAN}└─────────────────────────┴──────────────────────┴──────────────────────────┘\n${NC}"

# ============================================================================
# PARTE 4: EJEMPLO CONCRETO
# ============================================================================

echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}  PARTE 4: Ejemplo Concreto - Por qué SQL no es suficiente${NC}"
echo -e "${CYAN}============================================================================\n${NC}"

echo -e "${CYAN}Caso: Buscar informes similares a este perfil:${NC}"
echo -e "${GRAY}---${NC}"
echo -e "${GRAY}Trabajador: Juan Pérez - Operador de maquinaria${NC}"
echo -e "${GRAY}Presión: 145/92 mmHg${NC}"
echo -e "${GRAY}IMC: 28.5${NC}"
echo -e "${GRAY}Observaciones: \"Dolor lumbar ocasional por postura prolongada\"${NC}"
echo -e "${GRAY}---\n${NC}"

echo -e "${YELLOW}Con SQL (Día 1):${NC}"
echo -e "${GRAY}❌ Solo encuentra informes de Juan (0 si es nuevo)${NC}"
echo -e "${GRAY}❌ No puede buscar 'dolor lumbar' vs 'molestias en espalda'${NC}"
echo -e "${GRAY}❌ No entiende que 'postura prolongada' ≈ 'jornadas sentado'\n${NC}"

echo -e "${GREEN}Con Embeddings (Día 2):${NC}"
echo -e "${GRAY}✓ Encuentra 5 casos similares de CUALQUIER trabajador${NC}"
echo -e "${GRAY}✓ Entiende sinónimos: 'dolor lumbar' ≈ 'molestias en espalda'${NC}"
echo -e "${GRAY}✓ Entiende contexto: 'postura prolongada' ≈ 'jornadas sentado'${NC}"
echo -e "${GRAY}✓ Similarity scores: 0.89, 0.85, 0.82, 0.79, 0.76\n${NC}"

# ============================================================================
# CONCLUSIÓN
# ============================================================================

echo -e "${MAGENTA}============================================================================${NC}"
echo -e "${MAGENTA}  Conclusión${NC}"
echo -e "${MAGENTA}============================================================================\n${NC}"

echo -e "${CYAN}Embeddings NO son un reemplazo de SQL, son una capacidad NUEVA:${NC}"
echo -e "${GRAY}• SQL: Búsqueda estructurada por campos conocidos${NC}"
echo -e "${GRAY}• Embeddings: Búsqueda semántica por similitud conceptual\n${NC}"

echo -e "${GREEN}Valor para el sistema de salud:${NC}"
echo -e "${GRAY}• Decisiones médicas más informadas${NC}"
echo -e "${GRAY}• Tratamientos más efectivos basados en evidencia histórica${NC}"
echo -e "${GRAY}• Prevención proactiva basada en patrones ocupacionales${NC}"
echo -e "${GRAY}• Mejor uso de recursos médicos\n${NC}"

echo -e "${MAGENTA}============================================================================\n${NC}"

echo -e "${CYAN}Próximos pasos:${NC}"
echo -e "${GRAY}1. Generar más embeddings con la Lambda generate-embeddings${NC}"
echo -e "${GRAY}2. Probar búsqueda de similitud${NC}"
echo -e "${GRAY}3. Ver documentación completa: docs/RAG_PRIVACY.md\n${NC}"
