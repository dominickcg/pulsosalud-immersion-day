$dbClusterArn = "arn:aws:rds:us-east-2:675544937470:cluster:participant-1-medicalreports-auroracluster23d869c0-060zgbqqm7am"
$dbSecretArn = "arn:aws:secretsmanager:us-east-2:675544937470:secret:participant-1/aurora/credentials-tJ5kKm"

Write-Host "Inicializando base de datos para participant-1..." -ForegroundColor Cyan

aws rds-data execute-statement --resource-arn $dbClusterArn --secret-arn $dbSecretArn --database "medical_reports" --sql "CREATE EXTENSION IF NOT EXISTS vector" --profile pulsosalud-immersion | Out-Null
Write-Host "  Extension vector OK" -ForegroundColor Green

aws rds-data execute-statement --resource-arn $dbClusterArn --secret-arn $dbSecretArn --database "medical_reports" --sql "CREATE TABLE IF NOT EXISTS trabajadores (id SERIAL PRIMARY KEY, nombre VARCHAR(200) NOT NULL, documento VARCHAR(50) UNIQUE NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)" --profile pulsosalud-immersion | Out-Null
Write-Host "  Tabla trabajadores OK" -ForegroundColor Green

aws rds-data execute-statement --resource-arn $dbClusterArn --secret-arn $dbSecretArn --database "medical_reports" --sql "CREATE TABLE IF NOT EXISTS contratistas (id SERIAL PRIMARY KEY, nombre VARCHAR(200) NOT NULL, email VARCHAR(200) NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)" --profile pulsosalud-immersion | Out-Null
Write-Host "  Tabla contratistas OK" -ForegroundColor Green

aws rds-data execute-statement --resource-arn $dbClusterArn --secret-arn $dbSecretArn --database "medical_reports" --sql "CREATE TABLE IF NOT EXISTS informes_medicos (id SERIAL PRIMARY KEY, trabajador_id INT NOT NULL, contratista_id INT NOT NULL, tipo_examen VARCHAR(100) NOT NULL, fecha_examen TIMESTAMP NOT NULL, presion_arterial VARCHAR(20), peso DECIMAL(5,2), altura DECIMAL(3,2), vision VARCHAR(200), audiometria VARCHAR(200), observaciones TEXT, pdf_s3_path VARCHAR(500), origen VARCHAR(20) DEFAULT 'LEGACY', created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (trabajador_id) REFERENCES trabajadores(id), FOREIGN KEY (contratista_id) REFERENCES contratistas(id))" --profile pulsosalud-immersion | Out-Null
Write-Host "  Tabla informes_medicos OK" -ForegroundColor Green

Write-Host "`nBase de datos lista!" -ForegroundColor Green
