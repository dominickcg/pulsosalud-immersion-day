$dbClusterArn = "arn:aws:rds:us-east-2:675544937470:cluster:participant-3-medicalreports-auroracluster23d869c0-qbmszrdgkilj"
$dbSecretArn = "arn:aws:secretsmanager:us-east-2:675544937470:secret:participant-3/aurora/credentials-BWJ7g4"

Write-Host "Creando tablas..." -ForegroundColor Cyan

# Tabla contratistas
$sql = "CREATE TABLE IF NOT EXISTS contratistas (id SERIAL PRIMARY KEY, nombre VARCHAR(200) NOT NULL, ruc VARCHAR(20), email VARCHAR(200) NOT NULL, telefono VARCHAR(50), direccion TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)"
aws rds-data execute-statement --resource-arn $dbClusterArn --secret-arn $dbSecretArn --database "medical_reports" --sql $sql --profile pulsosalud-immersion | Out-Null
Write-Host "  contratistas OK" -ForegroundColor Green

# Tabla informes_medicos
$sql = "CREATE TABLE IF NOT EXISTS informes_medicos (id SERIAL PRIMARY KEY, trabajador_id INT NOT NULL, contratista_id INT NOT NULL, tipo_examen VARCHAR(100) NOT NULL, fecha_examen TIMESTAMP NOT NULL, presion_arterial VARCHAR(20), frecuencia_cardiaca INT, frecuencia_respiratoria INT, temperatura DECIMAL(3,1), saturacion_oxigeno INT, peso DECIMAL(5,2), altura DECIMAL(3,2), imc DECIMAL(4,1), perimetro_abdominal INT, vision VARCHAR(200), audiometria VARCHAR(200), antecedentes_medicos TEXT, examen_fisico JSONB, examenes_adicionales JSONB, observaciones TEXT, pdf_s3_path VARCHAR(500), origen VARCHAR(20) DEFAULT 'LEGACY', nivel_riesgo VARCHAR(20), justificacion_riesgo TEXT, resumen_ejecutivo TEXT, recomendaciones TEXT, procesado_por_ia BOOLEAN DEFAULT FALSE, email_enviado BOOLEAN DEFAULT FALSE, fecha_email_enviado TIMESTAMP NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (trabajador_id) REFERENCES trabajadores(id) ON DELETE CASCADE, FOREIGN KEY (contratista_id) REFERENCES contratistas(id) ON DELETE CASCADE)"
aws rds-data execute-statement --resource-arn $dbClusterArn --secret-arn $dbSecretArn --database "medical_reports" --sql $sql --profile pulsosalud-immersion | Out-Null
Write-Host "  informes_medicos OK" -ForegroundColor Green

Write-Host "`nBase de datos lista!" -ForegroundColor Green
