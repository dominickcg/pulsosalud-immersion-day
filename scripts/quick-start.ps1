# Quick Start - Inicializa y genera datos de prueba
$env:AWS_PROFILE = "pulsosalud-immersion"

$apiUrl = "https://2w26wsko7d.execute-api.us-east-2.amazonaws.com/prod"

Write-Host "Generando datos de prueba..." -ForegroundColor Yellow

# Generar datos de prueba
$body = '{"cantidad": 5}'

$response = Invoke-RestMethod -Method POST -Uri "$apiUrl/examenes/generar-prueba" -Body $body -ContentType "application/json"

Write-Host "Datos generados exitosamente!" -ForegroundColor Green
Write-Host ""
Write-Host "Resumen:"
Write-Host "- Trabajadores: $($response.trabajadores_creados)"
Write-Host "- Contratistas: $($response.contratistas_creados)"
Write-Host "- Informes: $($response.informes_generados)"
Write-Host "- PDFs: $($response.pdfs_generados)"
Write-Host ""
Write-Host "Sistema listo!" -ForegroundColor Green
