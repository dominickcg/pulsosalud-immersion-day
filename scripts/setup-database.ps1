#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Script para inicializar la base de datos Aurora con el schema.

.DESCRIPTION
    Ejecuta el schema SQL en la base de datos Aurora usando RDS Data API.
    Divide el schema en statements individuales ya que RDS Data API no soporta multistatements.

.PARAMETER ParticipantPrefix
    Prefijo del participante (ej: participant-1, participant-2)

.EXAMPLE
    .\setup-database.ps1 participant-3
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ParticipantPrefix
)

$ErrorActionPreference = "Stop"

Write-Host "`n🗄️  Configurando base de datos para $ParticipantPrefix...`n" -ForegroundColor Cyan

# Obtener ARNs desde CloudFormation
Write-Host "📋 Obteniendo información del stack..." -ForegroundColor Yellow

$stackName = "$ParticipantPrefix-MedicalReportsLegacyStack"

$dbClusterArn = aws cloudformation describe-stacks `
    --stack-name $stackName `
    --query 'Stacks[0].Outputs[?OutputKey==`DbClusterArn`].OutputValue' `
    --output text `
    --profile pulsosalud-immersion

$dbSecretArn = aws cloudformation describe-stacks `
    --stack-name $stackName `
    --query 'Stacks[0].Outputs[?OutputKey==`DbSecretArn`].OutputValue' `
    --output text `
    --profile pulsosalud-immersion

if (-not $dbClusterArn -or -not $dbSecretArn) {
    Write-Host "❌ Error: No se pudieron obtener los ARNs de la base de datos" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Cluster ARN: $dbClusterArn" -ForegroundColor Green
Write-Host "✅ Secret ARN: $dbSecretArn" -ForegroundColor Green

# Leer schema SQL
$schemaPath = Join-Path $PSScriptRoot ".." "database" "schema.sql"
$schemaContent = Get-Content -Path $schemaPath -Raw

# Dividir en statements individuales (separados por ;)
$statements = $schemaContent -split ';' | Where-Object { $_.Trim() -ne '' }

Write-Host "`n📝 Ejecutando $($statements.Count) statements SQL...`n" -ForegroundColor Yellow

$successCount = 0
$errorCount = 0

foreach ($statement in $statements) {
    $trimmedStatement = $statement.Trim()
    
    # Saltar comentarios y líneas vacías
    if ($trimmedStatement -eq '' -or $trimmedStatement.StartsWith('--')) {
        continue
    }
    
    # Mostrar preview del statement
    $preview = $trimmedStatement.Substring(0, [Math]::Min(60, $trimmedStatement.Length))
    Write-Host "  Ejecutando: $preview..." -NoNewline
    
    try {
        $result = aws rds-data execute-statement `
            --resource-arn $dbClusterArn `
            --secret-arn $dbSecretArn `
            --database "medical_reports" `
            --sql $trimmedStatement `
            --profile pulsosalud-immersion `
            2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host " ✅" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host " ❌" -ForegroundColor Red
            Write-Host "    Error: $result" -ForegroundColor Red
            $errorCount++
        }
    }
    catch {
        Write-Host " ❌" -ForegroundColor Red
        Write-Host "    Error: $_" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host "`n📊 Resumen:" -ForegroundColor Cyan
Write-Host "  ✅ Exitosos: $successCount" -ForegroundColor Green
Write-Host "  ❌ Errores: $errorCount" -ForegroundColor Red

if ($errorCount -eq 0) {
    Write-Host "`n🎉 Base de datos configurada exitosamente!`n" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  Base de datos configurada con algunos errores`n" -ForegroundColor Yellow
}
