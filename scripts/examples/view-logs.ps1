# View CloudWatch Logs - Medical Reports Workshop
# Este script facilita la visualización de logs de CloudWatch para las Lambdas

# ============================================================================
# INSTRUCCIONES:
# 1. Reemplaza "participant-X" con tu prefijo asignado (ej: participant-1)
# 2. Elige qué Lambda quieres monitorear (classify, summary, o list)
# 3. Ejecuta este script: .\view-logs.ps1
# ============================================================================

# IMPORTANTE: Reemplaza "participant-X" con tu prefijo asignado
$PARTICIPANT_PREFIX = "participant-X"

Write-Host "📊 Visualizador de Logs - Medical Reports Workshop" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Menú de selección
Write-Host "Selecciona la Lambda que quieres monitorear:" -ForegroundColor Yellow
Write-Host "  1. Classify Risk (clasificación de riesgo)" -ForegroundColor White
Write-Host "  2. Generate Summary (resúmenes ejecutivos)" -ForegroundColor White
Write-Host "  3. List Informes (listado de informes)" -ForegroundColor White
Write-Host "  4. Ver logs de todas las Lambdas" -ForegroundColor White
Write-Host ""

$selection = Read-Host "Ingresa tu selección (1-4)"

switch ($selection) {
    "1" {
        $logGroup = "/aws/lambda/$PARTICIPANT_PREFIX-classify-risk"
        Write-Host ""
        Write-Host "📋 Mostrando logs de Classify Risk..." -ForegroundColor Green
    }
    "2" {
        $logGroup = "/aws/lambda/$PARTICIPANT_PREFIX-generate-summary"
        Write-Host ""
        Write-Host "📋 Mostrando logs de Generate Summary..." -ForegroundColor Green
    }
    "3" {
        $logGroup = "/aws/lambda/$PARTICIPANT_PREFIX-list-informes"
        Write-Host ""
        Write-Host "📋 Mostrando logs de List Informes..." -ForegroundColor Green
    }
    "4" {
        Write-Host ""
        Write-Host "📋 Mostrando logs de todas las Lambdas..." -ForegroundColor Green
        Write-Host ""
        
        # Mostrar logs de todas las Lambdas
        Write-Host "─── Classify Risk ───" -ForegroundColor Cyan
        aws logs tail "/aws/lambda/$PARTICIPANT_PREFIX-classify-risk" --since 10m --format short
        
        Write-Host ""
        Write-Host "─── Generate Summary ───" -ForegroundColor Cyan
        aws logs tail "/aws/lambda/$PARTICIPANT_PREFIX-generate-summary" --since 10m --format short
        
        Write-Host ""
        Write-Host "─── List Informes ───" -ForegroundColor Cyan
        aws logs tail "/aws/lambda/$PARTICIPANT_PREFIX-list-informes" --since 10m --format short
        
        exit
    }
    default {
        Write-Host "❌ Selección inválida" -ForegroundColor Red
        exit
    }
}

Write-Host ""
Write-Host "💡 Tip: Los logs pueden tardar 1-2 minutos en aparecer" -ForegroundColor Yellow
Write-Host "💡 Tip: Presiona Ctrl+C para detener el seguimiento de logs" -ForegroundColor Yellow
Write-Host ""
Write-Host "Opciones de visualización:" -ForegroundColor Cyan
Write-Host "  1. Ver últimos logs (últimos 10 minutos)" -ForegroundColor White
Write-Host "  2. Seguir logs en tiempo real (tail -f)" -ForegroundColor White
Write-Host ""

$viewOption = Read-Host "Ingresa tu selección (1-2)"

switch ($viewOption) {
    "1" {
        Write-Host ""
        Write-Host "📄 Últimos logs (10 minutos):" -ForegroundColor Green
        Write-Host "═══════════════════════════════════════════════" -ForegroundColor Gray
        aws logs tail $logGroup --since 10m --format short
    }
    "2" {
        Write-Host ""
        Write-Host "📡 Siguiendo logs en tiempo real (Ctrl+C para detener):" -ForegroundColor Green
        Write-Host "═══════════════════════════════════════════════" -ForegroundColor Gray
        aws logs tail $logGroup --follow --format short
    }
    default {
        Write-Host "❌ Selección inválida, mostrando últimos logs..." -ForegroundColor Yellow
        Write-Host ""
        aws logs tail $logGroup --since 10m --format short
    }
}

Write-Host ""
Write-Host "✅ Visualización de logs completada" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Comandos útiles adicionales:" -ForegroundColor Yellow
Write-Host "   # Ver logs de las últimas 2 horas:" -ForegroundColor Gray
Write-Host "   aws logs tail $logGroup --since 2h" -ForegroundColor White
Write-Host ""
Write-Host "   # Filtrar logs por palabra clave:" -ForegroundColor Gray
Write-Host "   aws logs tail $logGroup --since 1h --filter-pattern 'ERROR'" -ForegroundColor White
Write-Host ""
Write-Host "   # Ver logs con timestamps completos:" -ForegroundColor Gray
Write-Host "   aws logs tail $logGroup --since 30m --format detailed" -ForegroundColor White
