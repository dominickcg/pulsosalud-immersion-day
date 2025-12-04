# ============================================================================
# Script: Demostración de Comparación RAG Día 1 vs Día 2
# Descripción: Muestra la diferencia entre búsqueda SQL y búsqueda semántica
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$Profile = "pulsosalud-immersion"
)

# Colores para output
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$WarningColor = "Yellow"
$HighlightColor = "Magenta"

Write-Host "`n============================================================================" -ForegroundColor $HighlightColor
Write-Host "  DEMOSTRACIÓN: RAG Día 1 (SQL) vs Día 2 (Embeddings Vectoriales)" -ForegroundColor $HighlightColor
Write-Host "============================================================================`n" -ForegroundColor $HighlightColor

# Verificar que las variables de entorno estén configuradas
if (-not $env:PARTICIPANT_PREFIX) {
    Write-Host "ERROR: Variables de entorno no configuradas." -ForegroundColor $ErrorColor
    Write-Host "Ejecuta primero: .\setup-env-vars.ps1`n" -ForegroundColor $WarningColor
    exit 1
}

Write-Host "Esta demostración muestra por qué necesitamos embeddings vectoriales" -ForegroundColor $InfoColor
Write-Host "para búsqueda semántica en lugar de solo SQL.`n" -ForegroundColor $InfoColor

# ============================================================================
# PARTE 1: RAG DÍA 1 - BÚSQUEDA SQL SIMPLE
# ============================================================================

Write-Host "============================================================================" -ForegroundColor $InfoColor
Write-Host "  PARTE 1: RAG Día 1 - Búsqueda SQL Simple" -ForegroundColor $InfoColor
Write-Host "============================================================================`n" -ForegroundColor $InfoColor

Write-Host "En el Día 1, usamos SQL para buscar informes del MISMO trabajador:`n" -ForegroundColor $InfoColor

# Seleccionar un trabajador para el ejemplo
Write-Host "Obteniendo trabajador de ejemplo..." -ForegroundColor $InfoColor

$queryTrabajador = @"
SELECT 
    t.id,
    t.nombre,
    COUNT(im.id) as total_informes
FROM trabajadores t
LEFT JOIN informes_medicos im ON t.id = im.trabajador_id
GROUP BY t.id, t.nombre
ORDER BY total_informes ASC
LIMIT 1
"@

try {
    $trabajadorResult = aws rds-data execute-statement `
        --resource-arn $env:CLUSTER_ARN `
        --secret-arn $env:SECRET_ARN `
        --database $env:DATABASE_NAME `
        --sql $queryTrabajador `
        --profile $Profile `
        --output json | ConvertFrom-Json
    
    if ($trabajadorResult.records.Count -eq 0) {
        Write-Host "ERROR: No se encontraron trabajadores.`n" -ForegroundColor $ErrorColor
        exit 1
    }
    
    $trabajadorId = $trabajadorResult.records[0][0].longValue
    $trabajadorNombre = $trabajadorResult.records[0][1].stringValue
    $totalInformes = $trabajadorResult.records[0][2].longValue
    
    Write-Host "✓ Trabajador seleccionado: $trabajadorNombre (ID: $trabajadorId)" -ForegroundColor $SuccessColor
    Write-Host "  Total de informes históricos: $totalInformes`n" -ForegroundColor $InfoColor
    
} catch {
    Write-Host "ERROR al obtener trabajador: $_`n" -ForegroundColor $ErrorColor
    exit 1
}

# Mostrar query SQL del Día 1
Write-Host "Query SQL del Día 1:" -ForegroundColor $InfoColor
Write-Host "---" -ForegroundColor Gray
$sqlDay1 = @"
SELECT * FROM informes_medicos 
WHERE trabajador_id = $trabajadorId
ORDER BY fecha_examen DESC
"@
Write-Host $sqlDay1 -ForegroundColor Gray
Write-Host "---`n" -ForegroundColor Gray

# Ejecutar query
Write-Host "Ejecutando búsqueda SQL..." -ForegroundColor $InfoColor

try {
    $sqlResult = aws rds-data execute-statement `
        --resource-arn $env:CLUSTER_ARN `
        --secret-arn $env:SECRET_ARN `
        --database $env:DATABASE_NAME `
        --sql $sqlDay1 `
        --profile $Profile `
        --output json | ConvertFrom-Json
    
    Write-Host "`nResultados de búsqueda SQL:" -ForegroundColor $SuccessColor
    
    if ($sqlResult.records.Count -eq 0) {
        Write-Host "❌ 0 informes encontrados" -ForegroundColor $WarningColor
        Write-Host "`nLimitación: Si el trabajador es nuevo o tiene pocos informes," -ForegroundColor $WarningColor
        Write-Host "no hay contexto histórico para tomar decisiones.`n" -ForegroundColor $WarningColor
    } else {
        Write-Host "✓ $($sqlResult.records.Count) informes encontrados" -ForegroundColor $SuccessColor
        Write-Host "  (Solo informes del mismo trabajador)`n" -ForegroundColor $InfoColor
    }
    
} catch {
    Write-Host "ERROR al ejecutar query SQL: $_`n" -ForegroundColor $ErrorColor
}

Write-Host "Problema con SQL:" -ForegroundColor $WarningColor
Write-Host "• Solo busca coincidencias EXACTAS (mismo trabajador_id)" -ForegroundColor Gray
Write-Host "• No entiende similitud SEMÁNTICA" -ForegroundColor Gray
Write-Host "• No puede encontrar casos SIMILARES de otros trabajadores" -ForegroundColor Gray
Write-Host "• Trabajadores nuevos = Sin contexto`n" -ForegroundColor Gray

# ============================================================================
# PARTE 2: RAG DÍA 2 - BÚSQUEDA CON EMBEDDINGS
# ============================================================================

Write-Host "============================================================================" -ForegroundColor $InfoColor
Write-Host "  PARTE 2: RAG Día 2 - Búsqueda Semántica con Embeddings" -ForegroundColor $InfoColor
Write-Host "============================================================================`n" -ForegroundColor $InfoColor

Write-Host "En el Día 2, usamos embeddings para buscar casos SIMILARES:`n" -ForegroundColor $InfoColor

# Verificar si hay embeddings
Write-Host "Verificando embeddings disponibles..." -ForegroundColor $InfoColor

$queryEmbeddings = @"
SELECT COUNT(*) as total
FROM informes_embeddings
"@

try {
    $embeddingsCount = aws rds-data execute-statement `
        --resource-arn $env:CLUSTER_ARN `
        --secret-arn $env:SECRET_ARN `
        --database $env:DATABASE_NAME `
        --sql $queryEmbeddings `
        --profile $Profile `
        --output json | ConvertFrom-Json
    
    $totalEmbeddings = $embeddingsCount.records[0][0].longValue
    
    if ($totalEmbeddings -eq 0) {
        Write-Host "⚠ No hay embeddings generados todavía." -ForegroundColor $WarningColor
        Write-Host "Ejecuta: .\invoke-embeddings.ps1 para generar embeddings`n" -ForegroundColor $InfoColor
        Write-Host "Continuando con explicación teórica...`n" -ForegroundColor $InfoColor
        $hasEmbeddings = $false
    } else {
        Write-Host "✓ $totalEmbeddings embeddings disponibles`n" -ForegroundColor $SuccessColor
        $hasEmbeddings = $true
    }
    
} catch {
    Write-Host "ERROR al verificar embeddings: $_`n" -ForegroundColor $ErrorColor
    $hasEmbeddings = $false
}

# Mostrar query con embeddings
Write-Host "Query con Embeddings del Día 2:" -ForegroundColor $InfoColor
Write-Host "---" -ForegroundColor Gray
$sqlDay2 = @"
SELECT 
    im.id,
    t.nombre as trabajador,
    im.tipo_examen,
    im.nivel_riesgo,
    LEFT(im.observaciones, 100) as observaciones_preview,
    1 - (ie1.embedding <=> ie2.embedding) as similarity_score
FROM informes_medicos im
JOIN informes_embeddings ie1 ON im.id = ie1.informe_id
JOIN trabajadores t ON im.trabajador_id = t.id
CROSS JOIN informes_embeddings ie2
WHERE ie2.informe_id = (
    SELECT informe_id FROM informes_embeddings 
    WHERE trabajador_id = $trabajadorId 
    LIMIT 1
)
  AND im.trabajador_id != $trabajadorId  -- Excluir mismo trabajador
ORDER BY similarity_score DESC
LIMIT 5
"@
Write-Host $sqlDay2 -ForegroundColor Gray
Write-Host "---`n" -ForegroundColor Gray

if ($hasEmbeddings) {
    Write-Host "Ejecutando búsqueda semántica..." -ForegroundColor $InfoColor
    
    # Primero verificar si el trabajador tiene embedding
    $checkEmbedding = @"
SELECT informe_id FROM informes_embeddings 
WHERE trabajador_id = $trabajadorId 
LIMIT 1
"@
    
    try {
        $embeddingCheck = aws rds-data execute-statement `
            --resource-arn $env:CLUSTER_ARN `
            --secret-arn $env:SECRET_ARN `
            --database $env:DATABASE_NAME `
            --sql $checkEmbedding `
            --profile $Profile `
            --output json | ConvertFrom-Json
        
        if ($embeddingCheck.records.Count -eq 0) {
            Write-Host "⚠ El trabajador $trabajadorNombre no tiene embeddings generados." -ForegroundColor $WarningColor
            Write-Host "Generando embedding para demostración...`n" -ForegroundColor $InfoColor
            
            # Aquí podrías invocar la Lambda de embeddings
            Write-Host "Tip: Ejecuta .\invoke-embeddings.ps1 para generar embeddings`n" -ForegroundColor $InfoColor
        } else {
            # Ejecutar búsqueda de similitud
            $similarityResult = aws rds-data execute-statement `
                --resource-arn $env:CLUSTER_ARN `
                --secret-arn $env:SECRET_ARN `
                --database $env:DATABASE_NAME `
                --sql $sqlDay2 `
                --profile $Profile `
                --output json | ConvertFrom-Json
            
            Write-Host "`nResultados de búsqueda semántica:" -ForegroundColor $SuccessColor
            
            if ($similarityResult.records.Count -eq 0) {
                Write-Host "⚠ No se encontraron casos similares (solo hay 1 embedding)" -ForegroundColor $WarningColor
            } else {
                Write-Host "✓ $($similarityResult.records.Count) casos similares encontrados" -ForegroundColor $SuccessColor
                Write-Host "  (De CUALQUIER trabajador con perfil similar)`n" -ForegroundColor $InfoColor
                
                # Mostrar resultados
                $counter = 1
                foreach ($record in $similarityResult.records) {
                    $informeId = $record[0].longValue
                    $trabajadorSimilar = $record[1].stringValue
                    $tipoExamen = $record[2].stringValue
                    $nivelRiesgo = if ($record[3].stringValue) { $record[3].stringValue } else { "N/A" }
                    $observaciones = if ($record[4].stringValue) { $record[4].stringValue } else { "N/A" }
                    $similarity = [math]::Round($record[5].doubleValue, 4)
                    
                    $scoreColor = $InfoColor
                    if ($similarity -gt 0.9) { $scoreColor = $SuccessColor }
                    elseif ($similarity -lt 0.7) { $scoreColor = $WarningColor }
                    
                    Write-Host "[$counter] Trabajador: $trabajadorSimilar (Informe #$informeId)" -ForegroundColor $InfoColor
                    Write-Host "    Similitud: $similarity" -ForegroundColor $scoreColor
                    Write-Host "    Tipo examen: $tipoExamen" -ForegroundColor Gray
                    Write-Host "    Nivel riesgo: $nivelRiesgo" -ForegroundColor Gray
                    Write-Host "    Observaciones: $observaciones..." -ForegroundColor Gray
                    Write-Host ""
                    $counter++
                }
            }
        }
        
    } catch {
        Write-Host "ERROR al ejecutar búsqueda semántica: $_`n" -ForegroundColor $ErrorColor
    }
}

Write-Host "`nVentajas de Embeddings:" -ForegroundColor $SuccessColor
Write-Host "• Busca similitud SEMÁNTICA, no solo coincidencias exactas" -ForegroundColor Gray
Write-Host "• Entiende sinónimos y conceptos relacionados" -ForegroundColor Gray
Write-Host "• Encuentra casos SIMILARES de CUALQUIER trabajador" -ForegroundColor Gray
Write-Host "• Trabajadores nuevos = Contexto de casos similares`n" -ForegroundColor Gray

# ============================================================================
# PARTE 3: TABLA COMPARATIVA
# ============================================================================

Write-Host "============================================================================" -ForegroundColor $InfoColor
Write-Host "  PARTE 3: Comparación Directa" -ForegroundColor $InfoColor
Write-Host "============================================================================`n" -ForegroundColor $InfoColor

Write-Host "┌─────────────────────────┬──────────────────────┬──────────────────────────┐" -ForegroundColor $InfoColor
Write-Host "│ Aspecto                 │ SQL (Día 1)          │ Embeddings (Día 2)       │" -ForegroundColor $InfoColor
Write-Host "├─────────────────────────┼──────────────────────┼──────────────────────────┤" -ForegroundColor $InfoColor
Write-Host "│ Tipo de búsqueda        │ Exacta/Rangos        │ Semántica                │" -ForegroundColor Gray
Write-Host "│ Sinónimos               │ No entiende          │ Sí entiende              │" -ForegroundColor Gray
Write-Host "│ Contexto                │ Campo por campo      │ Holístico                │" -ForegroundColor Gray
Write-Host "│ Mantenimiento           │ Manual               │ Automático               │" -ForegroundColor Gray
Write-Host "│ Flexibilidad            │ Rígida               │ Adaptativa               │" -ForegroundColor Gray
Write-Host "│ Trabajadores nuevos     │ Sin resultados       │ Encuentra similares      │" -ForegroundColor Gray
Write-Host "└─────────────────────────┴──────────────────────┴──────────────────────────┘`n" -ForegroundColor $InfoColor

# ============================================================================
# PARTE 4: EJEMPLO CONCRETO
# ============================================================================

Write-Host "============================================================================" -ForegroundColor $InfoColor
Write-Host "  PARTE 4: Ejemplo Concreto - Por qué SQL no es suficiente" -ForegroundColor $InfoColor
Write-Host "============================================================================`n" -ForegroundColor $InfoColor

Write-Host "Caso: Buscar informes similares a este perfil:" -ForegroundColor $InfoColor
Write-Host "---" -ForegroundColor Gray
Write-Host "Trabajador: Juan Pérez - Operador de maquinaria" -ForegroundColor Gray
Write-Host "Presión: 145/92 mmHg" -ForegroundColor Gray
Write-Host "IMC: 28.5" -ForegroundColor Gray
Write-Host 'Observaciones: "Dolor lumbar ocasional por postura prolongada"' -ForegroundColor Gray
Write-Host "---`n" -ForegroundColor Gray

Write-Host "Con SQL (Día 1):" -ForegroundColor $WarningColor
Write-Host "❌ Solo encuentra informes de Juan (0 si es nuevo)" -ForegroundColor Gray
Write-Host "❌ No puede buscar 'dolor lumbar' vs 'molestias en espalda'" -ForegroundColor Gray
Write-Host "❌ No entiende que 'postura prolongada' ≈ 'jornadas sentado'`n" -ForegroundColor Gray

Write-Host "Con Embeddings (Día 2):" -ForegroundColor $SuccessColor
Write-Host "✓ Encuentra 5 casos similares de CUALQUIER trabajador" -ForegroundColor Gray
Write-Host "✓ Entiende sinónimos: 'dolor lumbar' ≈ 'molestias en espalda'" -ForegroundColor Gray
Write-Host "✓ Entiende contexto: 'postura prolongada' ≈ 'jornadas sentado'" -ForegroundColor Gray
Write-Host "✓ Similarity scores: 0.89, 0.85, 0.82, 0.79, 0.76`n" -ForegroundColor Gray

# ============================================================================
# PARTE 5: PRIVACIDAD MÉDICA
# ============================================================================

Write-Host "============================================================================" -ForegroundColor $HighlightColor
Write-Host "  PARTE 5: Consideraciones de Privacidad Médica" -ForegroundColor $HighlightColor
Write-Host "============================================================================`n" -ForegroundColor $HighlightColor

Write-Host "IMPORTANTE: RAG es una herramienta INTERNA del médico`n" -ForegroundColor $WarningColor

Write-Host "✓ Vista del MÉDICO (Correcto):" -ForegroundColor $SuccessColor
Write-Host "---" -ForegroundColor Gray
Write-Host "Informe: Juan Pérez" -ForegroundColor Gray
Write-Host "Casos similares encontrados (5):" -ForegroundColor Gray
Write-Host "1. Trabajador #145 (similarity: 0.89)" -ForegroundColor Gray
Write-Host "   - Perfil similar, mejoró con pausas ergonómicas" -ForegroundColor Gray
Write-Host "2. Trabajador #203 (similarity: 0.85)" -ForegroundColor Gray
Write-Host "   - Perfil similar, requirió seguimiento cardiológico" -ForegroundColor Gray
Write-Host "---`n" -ForegroundColor Gray

Write-Host "✓ Email al EMPLEADO (Correcto):" -ForegroundColor $SuccessColor
Write-Host "---" -ForegroundColor Gray
Write-Host "Estimado Juan," -ForegroundColor Gray
Write-Host "Tu examen muestra presión arterial elevada (145/92 mmHg)." -ForegroundColor Gray
Write-Host "Recomendaciones:" -ForegroundColor Gray
Write-Host "1. Consulta con cardiólogo en 2 semanas" -ForegroundColor Gray
Write-Host "2. Pausas ergonómicas cada 2 horas" -ForegroundColor Gray
Write-Host "[NO se menciona que hay casos similares]" -ForegroundColor Gray
Write-Host "[NO se comparte información de otros empleados]" -ForegroundColor Gray
Write-Host "---`n" -ForegroundColor Gray

Write-Host "❌ Email al EMPLEADO (INCORRECTO - Viola privacidad):" -ForegroundColor $ErrorColor
Write-Host "---" -ForegroundColor Gray
Write-Host "Estimado Juan," -ForegroundColor Gray
Write-Host "Encontramos 5 casos similares al tuyo:" -ForegroundColor Gray
Write-Host "- Pedro García tuvo presión similar y mejoró con..." -ForegroundColor Gray
Write-Host "[❌ NUNCA mencionar otros empleados]" -ForegroundColor $ErrorColor
Write-Host "[❌ NUNCA compartir información de terceros]" -ForegroundColor $ErrorColor
Write-Host "---`n" -ForegroundColor Gray

# ============================================================================
# CONCLUSIÓN
# ============================================================================

Write-Host "============================================================================" -ForegroundColor $HighlightColor
Write-Host "  Conclusión" -ForegroundColor $HighlightColor
Write-Host "============================================================================`n" -ForegroundColor $HighlightColor

Write-Host "Embeddings NO son un reemplazo de SQL, son una capacidad NUEVA:" -ForegroundColor $InfoColor
Write-Host "• SQL: Búsqueda estructurada por campos conocidos" -ForegroundColor Gray
Write-Host "• Embeddings: Búsqueda semántica por similitud conceptual`n" -ForegroundColor Gray

Write-Host "Valor para el sistema de salud:" -ForegroundColor $SuccessColor
Write-Host "• Decisiones médicas más informadas" -ForegroundColor Gray
Write-Host "• Tratamientos más efectivos basados en evidencia histórica" -ForegroundColor Gray
Write-Host "• Prevención proactiva basada en patrones ocupacionales" -ForegroundColor Gray
Write-Host "• Mejor uso de recursos médicos`n" -ForegroundColor Gray

Write-Host "Respetando privacidad:" -ForegroundColor $WarningColor
Write-Host "• RAG es herramienta INTERNA del médico" -ForegroundColor Gray
Write-Host "• Empleados NO reciben información de otros casos" -ForegroundColor Gray
Write-Host "• Empleados SÍ reciben mejores recomendaciones (indirectamente)`n" -ForegroundColor Gray

Write-Host "============================================================================`n" -ForegroundColor $HighlightColor

# Sugerencias
Write-Host "Próximos pasos:" -ForegroundColor $InfoColor
Write-Host "1. Generar más embeddings: .\invoke-embeddings.ps1" -ForegroundColor Gray
Write-Host "2. Probar búsqueda de similitud: .\test-similarity-search.ps1" -ForegroundColor Gray
Write-Host "3. Ver documentación completa: docs/RAG_PRIVACY.md`n" -ForegroundColor Gray
