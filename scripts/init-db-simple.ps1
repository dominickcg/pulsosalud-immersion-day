# Inicializar base de datos ejecutando el schema SQL
$env:AWS_PROFILE = "pulsosalud-immersion"

Write-Host "Inicializando base de datos..." -ForegroundColor Yellow

# Leer el schema
$schema = Get-Content "../database/schema.sql" -Raw

# Dividir en statements individuales (separados por ;)
$statements = $schema -split ';' | Where-Object { $_.Trim() -ne '' }

$secretArn = "arn:aws:secretsmanager:us-east-2:675544937470:secret:demo/aurora/credentials-lRoa46"
$clusterArn = "arn:aws:rds:us-east-2:675544937470:cluster:demo-medicalreportslegacysta-auroracluster23d869c0-bwmy2qqe1m2t"
$database = "medical_reports"

$count = 0
foreach ($stmt in $statements) {
    $stmt = $stmt.Trim()
    if ($stmt -eq '') { continue }
    
    $count++
    Write-Host "Ejecutando statement $count..." -NoNewline
    
    try {
        aws rds-data execute-statement `
            --resource-arn $clusterArn `
            --secret-arn $secretArn `
            --database $database `
            --sql $stmt `
            --profile pulsosalud-immersion `
            --output json | Out-Null
        
        Write-Host " OK" -ForegroundColor Green
    } catch {
        Write-Host " ERROR" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Base de datos inicializada!" -ForegroundColor Green
