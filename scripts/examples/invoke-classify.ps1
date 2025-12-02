# Invoke Classify Risk Lambda - Medical Reports Workshop
# Este script invoca la Lambda de clasificación de riesgo

# ============================================================================
# INSTRUCCIONES:
# 1. Reemplaza "participant-X" con tu prefijo asignado (ej: participant-1)
# 2. Opcionalmente, cambia el INFORME_ID para probar diferentes informes
# 3. Ejecuta este script: .\invoke-classify.ps1
# ============================================================================

# IMPORTANTE: Reemplaza "participant-X" con tu prefijo asignado
$PARTICIPANT_PREFIX = "participant-X"

# ID del informe a clasificar (1-10 disponibles en la base de datos)
$INFORME_ID = 1

Write-Host "🔍 Clasificando informe médico #$INFORME_ID..." -ForegroundColor Cyan
Write-Host ""

# Crear payload JSON
$payload = @{
    informe_id = $INFORME_ID
} | ConvertTo-Json

# Guardar payload en archivo temporal
$payload | Out-File -FilePath "payload-classify.json" -Encoding utf8

# Invocar Lambda
Write-Host "📤 Invocando Lambda: $PARTICIPANT_PREFIX-classify-risk" -ForegroundColor Yellow
aws lambda invoke `
  --function-name "$PARTICIPANT_PREFIX-classify-risk" `
  --payload file://payload-classify.json `
  --cli-binary-format raw-in-base64-out `
  response-classify.json

# Verificar si la invocación fue exitosa
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Lambda invocada exitosamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📄 Respuesta:" -ForegroundColor Cyan
    
    # Leer y mostrar la respuesta
    $response = Get-Content response-classify.json | ConvertFrom-Json
    
    if ($response.statusCode -eq 200) {
        $body = $response.body | ConvertFrom-Json
        
        Write-Host "   Informe ID: $($body.informe_id)" -ForegroundColor White
        Write-Host "   Nivel de Riesgo: $($body.nivel_riesgo)" -ForegroundColor $(
            switch ($body.nivel_riesgo) {
                "BAJO" { "Green" }
                "MEDIO" { "Yellow" }
                "ALTO" { "Red" }
                default { "White" }
            }
        )
        Write-Host "   Justificación:" -ForegroundColor White
        Write-Host "   $($body.justificacion_riesgo)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "   Tiempo de procesamiento: $($body.processing_time_seconds)s" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Error en la clasificación:" -ForegroundColor Red
        Write-Host $response.body -ForegroundColor Red
    }
} else {
    Write-Host "❌ Error al invocar Lambda" -ForegroundColor Red
}

# Limpiar archivos temporales
Remove-Item payload-classify.json -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "💡 Tip: Puedes verificar los logs en CloudWatch:" -ForegroundColor Yellow
Write-Host "   aws logs tail /aws/lambda/$PARTICIPANT_PREFIX-classify-risk --follow" -ForegroundColor Gray
Write-Host ""
Write-Host "💡 Tip: Para probar otro informe, cambia la variable INFORME_ID en este script" -ForegroundColor Yellow
