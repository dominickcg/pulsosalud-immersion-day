# Limpiar cualquier credencial expirada
Remove-Item Env:AWS_ACCESS_KEY_ID -ErrorAction SilentlyContinue
Remove-Item Env:AWS_SECRET_ACCESS_KEY -ErrorAction SilentlyContinue
Remove-Item Env:AWS_SESSION_TOKEN -ErrorAction SilentlyContinue

# Configurar perfil y región
$env:AWS_PROFILE = "pulsosalud-immersion"

# Verificar credenciales
Write-Host "Verificando credenciales AWS..."
aws sts get-caller-identity --profile pulsosalud-immersion

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: No se pudieron obtener las credenciales. Ejecuta: aws sso login --profile pulsosalud-immersion"
    exit 1
}

Write-Host "`nIniciando despliegue de CDK..."
cdk deploy --all --require-approval never --profile pulsosalud-immersion
