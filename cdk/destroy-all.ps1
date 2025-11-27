# Limpiar credenciales expiradas
Remove-Item Env:AWS_ACCESS_KEY_ID -ErrorAction SilentlyContinue
Remove-Item Env:AWS_SECRET_ACCESS_KEY -ErrorAction SilentlyContinue
Remove-Item Env:AWS_SESSION_TOKEN -ErrorAction SilentlyContinue

# Configurar perfil
$env:AWS_PROFILE = "pulsosalud-immersion"

# Verificar credenciales
Write-Host "Verificando credenciales AWS..."
aws sts get-caller-identity --profile pulsosalud-immersion

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: No se pudieron obtener las credenciales."
    exit 1
}

Write-Host "`nDestruyendo todos los stacks..."
cdk destroy --all --force --profile pulsosalud-immersion
