# ============================================================================
# Script: Probar Búsqueda de Similitud con Embeddings
# Descripción: Busca los 5 informes más similares usando embeddings vectoriales
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$InformeId,
    
    [Parameter(Mandatory=$false)]
    [int]$TopK = 5,
    
    [Parameter(Mandatory=$false)]
    [string]$Profile = "pulsosalud-immersion"
)

# Colores para output
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

Write-Host "`n========================================" -ForegroundColor $InfoColor
Write-Host "  Búsqueda de Similitud con Embeddings" -ForegroundColor $InfoColor
Write-Host "========================================`n" -ForegroundColor $InfoColor

# Verificar que las variables de entorno estén configuradas
if (-not $env:PARTICIPANT_PREFIX) {
    Write-Host "ERROR: Variables de entorno no configuradas." -ForegroundColor $ErrorColor
    Write-Host "Ejecuta primero: .\setup-env-vars.ps1`n" -ForegroundColor $WarningColor
    exit 1
}

# Si no se proporciona InformeId, obtener el último informe con embedding
if (-not $InformeId) {
    Write-Host "Obteniendo último informe con embedding..." -ForegroundColor $InfoColor
    
    $query = @"
SELECT ie.informe_id, im.tipo_examen, t.nombre
FROM informes_embeddings ie
JOIN informes_medicos im ON ie.informe_id = im.id
JOIN trabajadores t ON im.trabajador_id = t.id
ORDER BY ie.created_at DESC
LIMIT 1
"@
    
    try {
        $result = aws rds-data execute-statement `
            --resource-arn $env:CLUSTER_ARN `
            --secret-arn $env:SECRET_ARN `
            --database $env:DATABASE_NAME `
            --sql $query `
            --profile $Profile `
            --output json | ConvertFrom-Json
        
        if ($result.records.Count -gt 0) {
            $InformeId = $result.records[0][0].longValue
            $tipoExamen = $result.records[0][1].stringValue
            $trabajador = $result.records[0][2].stringValue
            Write-Host "Usando informe ID: $InformeId" -ForegroundColor $SuccessColor
            Write-Host "  Trabajador: $trabajador" -ForegroundColor $InfoColor
            Write-Host "  Tipo examen: $tipoExamen`n" -ForegroundColor $InfoColor
        } else {
            Write-Host "ERROR: No se encontraron informes con embeddings." -ForegroundColor $ErrorColor
            Write-Host "Ejecuta primero: .\invoke-embeddings.ps1`n" -ForegroundColor $WarningColor
            exit 1
        }
    } catch {
        Write-Host "ERROR al obtener informe: $_`n" -ForegroundColor $ErrorColor
        exit 1
    }
}

# Verificar que el informe tiene embedding
Write-Host "Verificando que el informe tiene embedding..." -ForegroundColor $InfoColor

$verifyQuery = @"
SELECT 
    im.id,
    t.nombre as trabajador,
    im.tipo_examen,
    im.nivel_riesgo,
    im.observaciones,
    ie.id as embedding_id
FROM informes_medicos im
JOIN trabajadores t ON im.trabajador_id = t.id
LEFT JOIN informes_embeddings ie ON im.id = ie.informe_id
WHERE im.id = $InformeId
"@

try {
    $verifyResult = aws rds-data execute-statement `
        --resource-arn $env:CLUSTER_ARN `
        --secret-arn $env:SECRET_ARN `
        --database $env:DATABASE_NAME `
        --sql $verifyQuery `
        --profile $Profile `
        --output json | ConvertFrom-Json
    
    if ($verifyResult.records.Count -eq 0) {
        Write-Host "ERROR: Informe $InformeId no encontrado.`n" -ForegroundColor $ErrorColor
        exit 1
    }
    
    $record = $verifyResult.records[0]
    $trabajador = $record[1].stringValue
    $tipoExamen = $record[2].stringValue
    $nivelRiesgo = if ($record[3].stringValue) { $record[3].stringValue } else { "No clasificado" }
    $observaciones = if ($record[4].stringValue) { $record[4].stringValue } else { "N/A" }
    $embeddingId = if ($record[5].isNull -eq $false) { $record[5].longValue } else { $null }
    
    if (-not $embeddingId) {
        Write-Host "ERROR: El informe $InformeId no tiene embedding generado." -ForegroundColor $ErrorColor
        Write-Host "Ejecuta primero: .\invoke-embeddings.ps1 -InformeId $InformeId`n" -ForegroundColor $WarningColor
        exit 1
    }
    
    Write-Host "✓ Informe de referencia encontrado" -ForegroundColor $SuccessColor
    Write-Host "`n--- Informe de Referencia ---" -ForegroundColor $InfoColor
    Write-Host "ID: $InformeId" -ForegroundColor $InfoColor
    Write-Host "Trabajador: $trabajador" -ForegroundColor $InfoColor
    Write-Host "Tipo examen: $tipoExamen" -ForegroundColor $InfoColor
    Write-Host "Nivel de riesgo: $nivelRiesgo" -ForegroundColor $InfoColor
    
    if ($observaciones.Length -gt 100) {
        $observacionesPreview = $observaciones.Substring(0, 100) + "..."
    } else {
        $observacionesPreview = $observaciones
    }
    Write-Host "Observaciones: $observacionesPreview" -ForegroundColor $InfoColor
    
} catch {
    Write-Host "ERROR al verificar informe: $_`n" -ForegroundColor $ErrorColor
    exit 1
}

# Ejecutar búsqueda de similitud
Write-Host "`nBuscando informes similares..." -ForegroundColor $InfoColor

$similarityQuery = @"
SELECT 
    im.id,
    t.nombre as trabajador,
    im.tipo_examen,
    im.nivel_riesgo,
    im.fecha_examen,
    LEFT(im.observaciones, 150) as observaciones_preview,
    1 - (ie1.embedding <=> ie2.embedding) as similarity_score
FROM informes_medicos im
JOIN informes_embeddings ie1 ON im.id = ie1.informe_id
JOIN trabajadores t ON im.trabajador_id = t.id
CROSS JOIN informes_embeddings ie2
WHERE ie2.informe_id = $InformeId
  AND im.id != $InformeId
ORDER BY similarity_score DESC
LIMIT $TopK
"@

try {
    $startTime = Get-Date
    
    $similarityResult = aws rds-data execute-statement `
        --resource-arn $env:CLUSTER_ARN `
        --secret-arn $env:SECRET_ARN `
        --database $env:DATABASE_NAME `
        --sql $similarityQuery `
        --profile $Profile `
        --output json | ConvertFrom-Json
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds
    
    Write-Host "`n========================================" -ForegroundColor $SuccessColor
    Write-Host "  Resultados de Búsqueda de Similitud" -ForegroundColor $SuccessColor
    Write-Host "========================================`n" -ForegroundColor $SuccessColor
    
    if ($similarityResult.records.Count -eq 0) {
        Write-Host "No se encontraron informes similares." -ForegroundColor $WarningColor
        Write-Host "Esto puede ocurrir si:" -ForegroundColor $InfoColor
        Write-Host "  - Solo hay un informe con embedding en la base de datos" -ForegroundColor $InfoColor
        Write-Host "  - Los otros informes no tienen embeddings generados`n" -ForegroundColor $InfoColor
    } else {
        Write-Host "Encontrados $($similarityResult.records.Count) informes similares" -ForegroundColor $SuccessColor
        Write-Host "Tiempo de búsqueda: $([math]::Round($duration, 2)) ms`n" -ForegroundColor $InfoColor
        
        # Mostrar resultados en formato tabla
        $counter = 1
        foreach ($record in $similarityResult.records) {
            $id = $record[0].longValue
            $trabajadorSimilar = $record[1].stringValue
            $tipoExamenSimilar = $record[2].stringValue
            $nivelRiesgoSimilar = if ($record[3].stringValue) { $record[3].stringValue } else { "N/A" }
            $fechaExamen = $record[4].stringValue
            $observacionesSimilar = if ($record[5].stringValue) { $record[5].stringValue } else { "N/A" }
            $similarityScore = [math]::Round($record[6].doubleValue, 4)
            
            # Determinar color según similitud
            $scoreColor = $InfoColor
            if ($similarityScore -gt 0.9) {
                $scoreColor = $SuccessColor
            } elseif ($similarityScore -lt 0.7) {
                $scoreColor = $WarningColor
            }
            
            Write-Host "[$counter] Informe ID: $id" -ForegroundColor $InfoColor
            Write-Host "    Similitud: $similarityScore" -ForegroundColor $scoreColor
            Write-Host "    Trabajador: $trabajadorSimilar" -ForegroundColor Gray
            Write-Host "    Tipo examen: $tipoExamenSimilar" -ForegroundColor Gray
            Write-Host "    Nivel riesgo: $nivelRiesgoSimilar" -ForegroundColor Gray
            Write-Host "    Fecha examen: $fechaExamen" -ForegroundColor Gray
            
            if ($observacionesSimilar -ne "N/A") {
                Write-Host "    Observaciones: $observacionesSimilar..." -ForegroundColor Gray
            }
            
            Write-Host ""
            $counter++
        }
        
        # Estadísticas
        $scores = $similarityResult.records | ForEach-Object { $_.6.doubleValue }
        $avgScore = ($scores | Measure-Object -Average).Average
        $maxScore = ($scores | Measure-Object -Maximum).Maximum
        $minScore = ($scores | Measure-Object -Minimum).Minimum
        
        Write-Host "--- Estadísticas ---" -ForegroundColor $InfoColor
        Write-Host "Similitud promedio: $([math]::Round($avgScore, 4))" -ForegroundColor $InfoColor
        Write-Host "Similitud máxima: $([math]::Round($maxScore, 4))" -ForegroundColor $InfoColor
        Write-Host "Similitud mínima: $([math]::Round($minScore, 4))" -ForegroundColor $InfoColor
    }
    
} catch {
    Write-Host "`nERROR al buscar similitud: $_`n" -ForegroundColor $ErrorColor
    exit 1
}

Write-Host "`n========================================`n" -ForegroundColor $InfoColor

# Explicación pedagógica
Write-Host "¿Cómo funciona la búsqueda de similitud?" -ForegroundColor $InfoColor
Write-Host "1. Cada informe se convierte en un vector de 1024 dimensiones" -ForegroundColor Gray
Write-Host "2. Se calcula la distancia de coseno entre vectores" -ForegroundColor Gray
Write-Host "3. Similitud = 1 - distancia (1 = idénticos, 0 = no relacionados)" -ForegroundColor Gray
Write-Host "4. Se retornan los $TopK informes más similares`n" -ForegroundColor Gray

# Sugerencias
Write-Host "Próximos pasos:" -ForegroundColor $InfoColor
Write-Host "1. Comparar con búsqueda SQL tradicional (solo mismo trabajador)" -ForegroundColor Gray
Write-Host "2. Generar más embeddings: .\invoke-embeddings.ps1" -ForegroundColor Gray
Write-Host "3. Ver queries de embeddings: Ver queries #13-18 en queries.sql`n" -ForegroundColor Gray
