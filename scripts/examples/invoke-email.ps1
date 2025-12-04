# ============================================================================
# Script: Invocar Lambda de Envío de Emails
# Descripción: Genera y envía email personalizado basado en clasificación
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$InformeId,
    
    [Parameter(Mandatory=$false)]
    [string]$DestinatarioEmail,
    
    [Parameter(Mandatory=$false)]
    [string]$Profile = "pulsosalud-immersion"
)

# Colores para output
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

Write-Host "`n========================================" -ForegroundColor $InfoColor
Write-Host "  Generación y Envío de Email Personalizado" -ForegroundColor $InfoColor
Write-Host "========================================`n" -ForegroundColor $InfoColor

# Verificar que las variables de entorno estén configuradas
if (-not $env:PARTICIPANT_PREFIX) {
    Write-Host "ERROR: Variables de entorno no configuradas." -ForegroundColor $ErrorColor
    Write-Host "Ejecuta primero: .\setup-env-vars.ps1`n" -ForegroundColor $WarningColor
    exit 1
}

# Si no se proporciona InformeId, obtener el último informe clasificado
if (-not $InformeId) {
    Write-Host "Obteniendo último informe clasificado..." -ForegroundColor $InfoColor
    
    $query = @"
SELECT id, nivel_riesgo 
FROM informes_medicos 
WHERE nivel_riesgo IS NOT NULL 
ORDER BY id DESC 
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
            $nivelRiesgo = $result.records[0][1].stringValue
            Write-Host "Usando informe ID: $InformeId (Riesgo: $nivelRiesgo)`n" -ForegroundColor $SuccessColor
        } else {
            Write-Host "ERROR: No se encontraron informes clasificados." -ForegroundColor $ErrorColor
            Write-Host "Ejecuta primero: .\invoke-classify.ps1`n" -ForegroundColor $WarningColor
            exit 1
        }
    } catch {
        Write-Host "ERROR al obtener informe: $_`n" -ForegroundColor $ErrorColor
        exit 1
    }
}

# Verificar que el informe tiene clasificación
Write-Host "Verificando clasificación del informe..." -ForegroundColor $InfoColor

$verifyQuery = @"
SELECT 
    im.id,
    im.nivel_riesgo,
    t.nombre as trabajador,
    im.tipo_examen,
    im.email_enviado
FROM informes_medicos im
JOIN trabajadores t ON im.trabajador_id = t.id
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
    $nivelRiesgo = $record[1].stringValue
    $trabajador = $record[2].stringValue
    $tipoExamen = $record[3].stringValue
    $emailEnviado = $record[4].booleanValue
    
    if (-not $nivelRiesgo) {
        Write-Host "ERROR: El informe $InformeId no tiene clasificación de riesgo." -ForegroundColor $ErrorColor
        Write-Host "Ejecuta primero: .\invoke-classify.ps1 -InformeId $InformeId`n" -ForegroundColor $WarningColor
        exit 1
    }
    
    Write-Host "✓ Informe encontrado" -ForegroundColor $SuccessColor
    Write-Host "  Trabajador: $trabajador" -ForegroundColor $InfoColor
    Write-Host "  Tipo examen: $tipoExamen" -ForegroundColor $InfoColor
    Write-Host "  Nivel de riesgo: $nivelRiesgo" -ForegroundColor $InfoColor
    
    if ($emailEnviado) {
        Write-Host "  ⚠ Ya se envió un email para este informe" -ForegroundColor $WarningColor
    }
    
} catch {
    Write-Host "ERROR al verificar informe: $_`n" -ForegroundColor $ErrorColor
    exit 1
}

# Si no se proporciona email, usar el email verificado del entorno
if (-not $DestinatarioEmail) {
    if ($env:VERIFIED_EMAIL) {
        $DestinatarioEmail = $env:VERIFIED_EMAIL
        Write-Host "`nUsando email verificado: $DestinatarioEmail" -ForegroundColor $InfoColor
    } else {
        Write-Host "`nERROR: No se especificó email destinatario." -ForegroundColor $ErrorColor
        Write-Host "Usa: .\invoke-email.ps1 -InformeId $InformeId -DestinatarioEmail tu@email.com`n" -ForegroundColor $WarningColor
        exit 1
    }
}

# Construir payload
$payload = @{
    informe_id = [int]$InformeId
    destinatario_email = $DestinatarioEmail
} | ConvertTo-Json -Compress

Write-Host "`nInvocando Lambda send-email..." -ForegroundColor $InfoColor

# Medir tiempo de ejecución
$startTime = Get-Date

try {
    # Invocar Lambda
    $lambdaName = "$env:PARTICIPANT_PREFIX-send-email"
    
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
        Write-Host "  Resultado de Envío de Email" -ForegroundColor $SuccessColor
        Write-Host "========================================`n" -ForegroundColor $SuccessColor
        
        if ($result.statusCode -eq 200) {
            $body = $result.body | ConvertFrom-Json
            
            Write-Host "Estado: ÉXITO" -ForegroundColor $SuccessColor
            Write-Host "Informe ID: $($body.informe_id)" -ForegroundColor $InfoColor
            Write-Host "Destinatario: $($body.destinatario)" -ForegroundColor $InfoColor
            Write-Host "Nivel de riesgo: $($body.nivel_riesgo)" -ForegroundColor $InfoColor
            
            if ($body.message_id) {
                Write-Host "Message ID (SES): $($body.message_id)" -ForegroundColor $SuccessColor
            }
            
            Write-Host "`nTiempo de procesamiento: $([math]::Round($duration, 2)) segundos" -ForegroundColor $InfoColor
            
            # Mostrar preview del email
            if ($body.email_preview) {
                Write-Host "`n========================================" -ForegroundColor $InfoColor
                Write-Host "  Preview del Email Generado" -ForegroundColor $InfoColor
                Write-Host "========================================`n" -ForegroundColor $InfoColor
                
                $preview = $body.email_preview
                
                Write-Host "Asunto: $($preview.asunto)" -ForegroundColor $InfoColor
                Write-Host "`nCuerpo (primeros 500 caracteres):" -ForegroundColor $InfoColor
                Write-Host "---" -ForegroundColor Gray
                
                $cuerpoPreview = $preview.cuerpo
                if ($cuerpoPreview.Length -gt 500) {
                    $cuerpoPreview = $cuerpoPreview.Substring(0, 500) + "..."
                }
                Write-Host $cuerpoPreview -ForegroundColor Gray
                Write-Host "---`n" -ForegroundColor Gray
            }
            
            # Verificar en base de datos
            Write-Host "Verificando actualización en base de datos..." -ForegroundColor $InfoColor
            
            $dbQuery = @"
SELECT 
    email_enviado,
    fecha_email_enviado,
    email_message_id
FROM informes_medicos
WHERE id = $InformeId
"@
            
            $dbResult = aws rds-data execute-statement `
                --resource-arn $env:CLUSTER_ARN `
                --secret-arn $env:SECRET_ARN `
                --database $env:DATABASE_NAME `
                --sql $dbQuery `
                --profile $Profile `
                --output json | ConvertFrom-Json
            
            if ($dbResult.records.Count -gt 0) {
                $dbRecord = $dbResult.records[0]
                $emailEnviadoDB = $dbRecord[0].booleanValue
                
                if ($emailEnviadoDB) {
                    Write-Host "✓ Base de datos actualizada correctamente" -ForegroundColor $SuccessColor
                    
                    if ($dbRecord[1].stringValue) {
                        Write-Host "  Fecha envío: $($dbRecord[1].stringValue)" -ForegroundColor $InfoColor
                    }
                    if ($dbRecord[2].stringValue) {
                        Write-Host "  Message ID: $($dbRecord[2].stringValue)" -ForegroundColor $InfoColor
                    }
                }
            }
            
        } else {
            Write-Host "Estado: ERROR" -ForegroundColor $ErrorColor
            Write-Host "Código: $($result.statusCode)" -ForegroundColor $ErrorColor
            
            $errorBody = $result.body
            if ($errorBody -is [string]) {
                try {
                    $errorBody = $errorBody | ConvertFrom-Json
                    Write-Host "Mensaje: $($errorBody.error)" -ForegroundColor $ErrorColor
                } catch {
                    Write-Host "Mensaje: $errorBody" -ForegroundColor $ErrorColor
                }
            }
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
Write-Host "1. Verificar email en tu bandeja de entrada" -ForegroundColor Gray
Write-Host "2. Ver historial de emails: Ver query #21 en queries.sql" -ForegroundColor Gray
Write-Host "3. Verificar en SES Console: https://console.aws.amazon.com/ses/`n" -ForegroundColor Gray
