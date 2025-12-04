# ============================================================================
# Script: Invocar Lambda de Generación de Embeddings
# Descripción: Genera embeddings vectoriales para un informe médico
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$InformeId,
    
    [Parameter(Mandatory=$false)]
    [string]$Profile = "pulsosalud-immersion"
)

# Colores para output
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

Write-Host "`n========================================" -ForegroundColor $InfoColor
Write-Host "  Generación de Embeddings Vectoriales" -ForegroundColor $InfoColor
Write-Host "========================================`n" -ForegroundColor $InfoColor

# Verificar que las variables de entorno estén configuradas
if (-not $env:PARTICIPANT_PREFIX) {
    Write-Host "ERROR: Variables de entorno no configuradas." -ForegroundColor $ErrorColor
    Write-Host "Ejecuta primero: .\setup-env-vars.ps1`n" -ForegroundColor $WarningColor
    exit 1
}

# Si no se proporciona InformeId, obtener el último informe
if (-not $InformeId) {
    Write-Host "Obteniendo último informe..." -ForegroundColor $InfoColor
    
    $query = "SELECT id FROM informes_medicos ORDER BY id DESC LIMIT 1"
    
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
            Write-Host "Usando informe ID: $InformeId`n" -ForegroundColor $SuccessColor
        } else {
            Write-Host "ERROR: No se encontraron informes en la base de datos.`n" -ForegroundColor $ErrorColor
            exit 1
        }
    } catch {
        Write-Host "ERROR al obtener informe: $_`n" -ForegroundColor $ErrorColor
        exit 1
    }
}

# Construir payload
$payload = @{
    informe_id = [int]$InformeId
} | ConvertTo-Json -Compress

Write-Host "Invocando Lambda generate-embeddings..." -ForegroundColor $InfoColor
Write-Host "Informe ID: $InformeId" -ForegroundColor $InfoColor

# Medir tiempo de ejecución
$startTime = Get-Date

try {
    # Invocar Lambda
    $lambdaName = "$env:PARTICIPANT_PREFIX-generate-embeddings"
    
    $response = aws lambda invoke `
        --function-name $lambdaName `
        --payload $payload `
        --profile $Profile `
        response.json
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    # Leer respuesta
    if (Test-Path response.json) {
        $result = Get-Content response.json | ConvertFrom-Json
        
        Write-Host "`n========================================" -ForegroundColor $SuccessColor
        Write-Host "  Resultado de Generación de Embeddings" -ForegroundColor $SuccessColor
        Write-Host "========================================`n" -ForegroundColor $SuccessColor
        
        if ($result.statusCode -eq 200) {
            $body = $result.body | ConvertFrom-Json
            
            Write-Host "Estado: ÉXITO" -ForegroundColor $SuccessColor
            Write-Host "Informe ID: $($body.informe_id)" -ForegroundColor $InfoColor
            Write-Host "Dimensiones del vector: $($body.vector_dimensions)" -ForegroundColor $InfoColor
            
            if ($body.vector_dimensions -eq 1024) {
                Write-Host "✓ Vector tiene las dimensiones correctas (1024)" -ForegroundColor $SuccessColor
            } else {
                Write-Host "⚠ Vector tiene dimensiones incorrectas (esperado: 1024)" -ForegroundColor $WarningColor
            }
            
            Write-Host "`nTiempo de procesamiento: $([math]::Round($duration, 2)) segundos" -ForegroundColor $InfoColor
            
            if ($body.contenido_preview) {
                Write-Host "`nPreview del contenido usado:" -ForegroundColor $InfoColor
                Write-Host $body.contenido_preview -ForegroundColor Gray
            }
            
            # Verificar en base de datos
            Write-Host "`nVerificando en base de datos..." -ForegroundColor $InfoColor
            
            $verifyQuery = @"
SELECT 
    ie.informe_id,
    im.tipo_examen,
    t.nombre as trabajador,
    LENGTH(ie.contenido) as longitud_texto,
    ie.created_at
FROM informes_embeddings ie
JOIN informes_medicos im ON ie.informe_id = im.id
JOIN trabajadores t ON im.trabajador_id = t.id
WHERE ie.informe_id = $InformeId
"@
            
            $dbResult = aws rds-data execute-statement `
                --resource-arn $env:CLUSTER_ARN `
                --secret-arn $env:SECRET_ARN `
                --database $env:DATABASE_NAME `
                --sql $verifyQuery `
                --profile $Profile `
                --output json | ConvertFrom-Json
            
            if ($dbResult.records.Count -gt 0) {
                $record = $dbResult.records[0]
                Write-Host "✓ Embedding almacenado correctamente en la base de datos" -ForegroundColor $SuccessColor
                Write-Host "  Trabajador: $($record[2].stringValue)" -ForegroundColor $InfoColor
                Write-Host "  Tipo examen: $($record[1].stringValue)" -ForegroundColor $InfoColor
                Write-Host "  Longitud texto: $($record[3].longValue) caracteres" -ForegroundColor $InfoColor
            }
            
        } else {
            Write-Host "Estado: ERROR" -ForegroundColor $ErrorColor
            Write-Host "Código: $($result.statusCode)" -ForegroundColor $ErrorColor
            Write-Host "Mensaje: $($result.body)" -ForegroundColor $ErrorColor
        }
        
        # Limpiar archivo temporal
        Remove-Item response.json -ErrorAction SilentlyContinue
        
    } else {
        Write-Host "ERROR: No se pudo leer la respuesta de Lambda.`n" -ForegroundColor $ErrorColor
        exit 1
    }
    
} catch {
    Write-Host "`nERROR al invocar Lambda: $_`n" -ForegroundColor $ErrorColor
    Remove-Item response.json -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "`n========================================`n" -ForegroundColor $InfoColor

# Sugerencias
Write-Host "Próximos pasos:" -ForegroundColor $InfoColor
Write-Host "1. Buscar informes similares: .\test-similarity-search.ps1 -InformeId $InformeId" -ForegroundColor Gray
Write-Host "2. Ver embeddings en BD: Ver query #14 en queries.sql`n" -ForegroundColor Gray
