# Invoke Generate Summary Lambda - Medical Reports Workshop
# Este script invoca la Lambda de generación de resúmenes ejecutivos

# ============================================================================
# INSTRUCCIONES:
# 1. Reemplaza "participant-X" con tu prefijo asignado (ej: participant-1)
# 2. Opcionalmente, cambia el INFORME_ID para probar diferentes informes
# 3. Ejecuta este script: .\invoke-summary.ps1
# ============================================================================

# IMPORTANTE: Reemplaza "participant-X" con tu prefijo asignado
$PARTICIPANT_PREFIX = "participant-X"

# ID del informe para generar resumen (debe estar clasificado primero)
$INFORME_ID = 1

Write-Host "📝 Generando resumen ejecutivo para informe #$INFORME_ID..." -ForegroundColor Cyan
Write-Host ""

# Crear payload JSON
$payload = @{
    informe_id = $INFORME_ID
} | ConvertTo-Json

# Guardar payload en archivo temporal
$payload | Out-File -FilePath "payload-summary.json" -Encoding utf8

# Invocar Lambda
Write-Host "📤 Invocando Lambda: $PARTICIPANT_PREFIX-generate-summary" -ForegroundColor Yellow
aws lambda invoke `
  --function-name "$PARTICIPANT_PREFIX-generate-summary" `
  --payload file://payload-summary.json `
  --cli-binary-format raw-in-base64-out `
  response-summary.json

# Verificar si la invocación fue exitosa
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Lambda invocada exitosamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📄 Respuesta:" -ForegroundColor Cyan
    
    # Leer y mostrar la respuesta
    $response = Get-Content response-summary.json | ConvertFrom-Json
    
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
        Write-Host ""
        Write-Host "   📋 Resumen Ejecutivo:" -ForegroundColor Cyan
        Write-Host "   ─────────────────────────────────────────────────────────" -ForegroundColor Gray
        Write-Host "   $($body.resumen_ejecutivo)" -ForegroundColor White
        Write-Host "   ─────────────────────────────────────────────────────────" -ForegroundColor Gray
        Write-Host ""
        Write-Host "   Palabras: $($body.word_count)" -ForegroundColor Cyan
        Write-Host "   Tiempo de procesamiento: $($body.processing_time_seconds)s" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Error en la generación del resumen:" -ForegroundColor Red
        Write-Host $response.body -ForegroundColor Red
    }
} else {
    Write-Host "❌ Error al invocar Lambda" -ForegroundColor Red
}

# Limpiar archivos temporales
Remove-Item payload-summary.json -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "💡 Tip: Puedes verificar los logs en CloudWatch:" -ForegroundColor Yellow
Write-Host "   aws logs tail /aws/lambda/$PARTICIPANT_PREFIX-generate-summary --follow" -ForegroundColor Gray
Write-Host ""
Write-Host "💡 Tip: El informe debe estar clasificado antes de generar el resumen" -ForegroundColor Yellow
Write-Host "   Si ves un error, ejecuta primero .\invoke-classify.ps1" -ForegroundColor Gray
