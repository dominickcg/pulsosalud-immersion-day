# ============================================================================
# Script: Despliegue de LegacyStacks para multiples participantes
# Proposito: Desplegar Aurora, S3 y Lambdas Legacy para cada participante
# Quien: Instructor
# Cuando: Antes del workshop (despues de desplegar SharedNetworkStack)
# Tiempo estimado: ~15 minutos por participante (pueden ejecutarse en paralelo)
# ============================================================================

param(
    [string]$ConfigFile = "config/participants.json",
    [string]$Profile = "pulsosalud-immersion",
    [string]$Region = "us-east-2",
    [int]$Concurrency = 3,
    [string[]]$Participants = @()
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  Despliegue de LegacyStacks - Infraestructura por Participante" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "cdk/bin/app.ts")) {
    Write-Host "[ERROR] Este script debe ejecutarse desde la raiz del proyecto" -ForegroundColor Red
    Write-Host "   Directorio actual: $PWD" -ForegroundColor Yellow
    exit 1
}

# Configurar variables de entorno
$env:DEPLOY_MODE = "legacy"
$env:AWS_PROFILE = $Profile
$env:CDK_DEFAULT_REGION = $Region

Write-Host "[Configuracion]" -ForegroundColor Green
Write-Host "   - Modo de despliegue: $env:DEPLOY_MODE" -ForegroundColor White
Write-Host "   - Perfil AWS: $Profile" -ForegroundColor White
Write-Host "   - Region: $Region" -ForegroundColor White
Write-Host "   - Concurrencia: $Concurrency stacks en paralelo" -ForegroundColor White
Write-Host ""

# Verificar sesion AWS
Write-Host "[Verificando sesion AWS...]" -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --profile $Profile 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($identity -match "ExpiredToken") {
            Write-Host "[AVISO] Token expirado. Renovando sesion SSO..." -ForegroundColor Yellow
            aws sso login --profile $Profile
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[ERROR] No se pudo renovar la sesion SSO" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "[ERROR] No se pudo verificar la identidad AWS" -ForegroundColor Red
            Write-Host $identity -ForegroundColor Red
            exit 1
        }
    }
    
    $identityJson = $identity | ConvertFrom-Json
    Write-Host "[OK] Sesion AWS verificada" -ForegroundColor Green
    Write-Host "   - Account: $($identityJson.Account)" -ForegroundColor White
    Write-Host ""
} catch {
    Write-Host "[ERROR] No se pudo verificar la sesion AWS" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Verificar que SharedNetworkStack existe
Write-Host "[Verificando que SharedNetworkStack existe...]" -ForegroundColor Yellow
try {
    $networkStack = aws cloudformation describe-stacks --stack-name SharedNetworkStack --profile $Profile --region $Region 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] SharedNetworkStack no encontrado" -ForegroundColor Red
        Write-Host ""
        Write-Host "   Debe desplegar SharedNetworkStack primero:" -ForegroundColor Yellow
        Write-Host "   .\scripts\instructor-deploy-network.ps1" -ForegroundColor Gray
        Write-Host ""
        exit 1
    }
    Write-Host "[OK] SharedNetworkStack encontrado" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "[ERROR] No se pudo verificar SharedNetworkStack" -ForegroundColor Red
    exit 1
}

# Obtener lista de participantes
$participantList = @()

if ($Participants.Count -gt 0) {
    # Usar participantes especificados en la linea de comandos
    $participantList = $Participants
    Write-Host "[Usando participantes especificados en linea de comandos]" -ForegroundColor Green
}
elseif (Test-Path $ConfigFile) {
    # Leer del archivo de configuracion
    Write-Host "[Leyendo lista de participantes desde: $ConfigFile]" -ForegroundColor Green
    try {
        $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        $participantList = $config.participants | ForEach-Object { $_.prefix }
    }
    catch {
        Write-Host "[ERROR] No se pudo leer el archivo de configuracion" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "[ERROR] No se especificaron participantes" -ForegroundColor Red
    Write-Host ""
    Write-Host "   Opciones:" -ForegroundColor Yellow
    Write-Host "   1. Crear archivo de configuracion: $ConfigFile" -ForegroundColor Gray
    Write-Host "   2. Especificar participantes: -Participants 'participant-1','participant-2'" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-Host "   Total de participantes: $($participantList.Count)" -ForegroundColor White
foreach ($p in $participantList) {
    Write-Host "   - $p" -ForegroundColor Gray
}
Write-Host ""

# Confirmar con el usuario
$totalTime = [math]::Ceiling($participantList.Count / $Concurrency) * 15
Write-Host "[Tiempo estimado total: ~$totalTime minutos]" -ForegroundColor Yellow
Write-Host "   (Desplegando $Concurrency stacks en paralelo)" -ForegroundColor White
Write-Host ""
$response = Read-Host "Continuar con el despliegue? (s/n)"
if ($response -ne "s" -and $response -ne "S") {
    Write-Host "[Operacion cancelada por el usuario]" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "[Iniciando despliegue de LegacyStacks...]" -ForegroundColor Green
Write-Host ""

# Cambiar al directorio CDK
Push-Location cdk

try {
    # Compilar el proyecto
    Write-Host "[Compilando proyecto TypeScript...]" -ForegroundColor Yellow
    npm run build
    if ($LASTEXITCODE -ne 0) {
        throw "Error al compilar el proyecto"
    }
    Write-Host "[OK] Compilacion exitosa" -ForegroundColor Green
    Write-Host ""

    # Establecer PARTICIPANT_PREFIX con todos los participantes separados por comas
    $env:PARTICIPANT_PREFIX = $participantList -join ','
    
    # Construir lista de stacks para desplegar
    $stackNames = $participantList | ForEach-Object { "$_-MedicalReportsLegacyStack" }
    
    # Desplegar stacks en paralelo
    Write-Host "[Desplegando $($stackNames.Count) LegacyStacks con concurrencia $Concurrency...]" -ForegroundColor Yellow
    Write-Host ""
    
    $startTime = Get-Date
    
    $cdkCommand = "cdk deploy $($stackNames -join ' ') --require-approval never --concurrency $Concurrency --profile $Profile"
    Write-Host "   Ejecutando: $cdkCommand" -ForegroundColor Gray
    Write-Host ""
    
    Invoke-Expression $cdkCommand
    
    if ($LASTEXITCODE -ne 0) {
        throw "Error al desplegar LegacyStacks"
    }
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host "  [OK] LegacyStacks desplegados exitosamente" -ForegroundColor Green
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "[Tiempo total de despliegue: $($duration.Minutes) minutos $($duration.Seconds) segundos]" -ForegroundColor White
    Write-Host ""
    
    # Generar reporte de outputs
    Write-Host "[Generando reporte de outputs...]" -ForegroundColor Cyan
    Write-Host ""
    
    $report = @()
    
    foreach ($participant in $participantList) {
        $stackName = "$participant-MedicalReportsLegacyStack"
        Write-Host "   Obteniendo outputs de $stackName..." -ForegroundColor Gray
        
        try {
            $outputs = aws cloudformation describe-stacks --stack-name $stackName --profile $Profile --region $Region --query "Stacks[0].Outputs" --output json | ConvertFrom-Json
            
            $participantData = @{
                Participant = $participant
                StackName = $stackName
                Outputs = @{}
            }
            
            foreach ($output in $outputs) {
                $participantData.Outputs[$output.OutputKey] = $output.OutputValue
            }
            
            $report += $participantData
        } catch {
            Write-Host "   [AVISO] No se pudieron obtener outputs de $stackName" -ForegroundColor Yellow
        }
    }
    
    # Guardar reporte en archivo
    $reportFile = "deployment-report-legacy-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $report | ConvertTo-Json -Depth 10 | Out-File $reportFile
    
    Write-Host ""
    Write-Host "[OK] Reporte guardado en: $reportFile" -ForegroundColor Green
    Write-Host ""
    
    # Mostrar resumen
    Write-Host "[Resumen de despliegue]" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($item in $report) {
        Write-Host "   $($item.Participant):" -ForegroundColor Yellow
        Write-Host "      API URL: $($item.Outputs.ApiUrl)" -ForegroundColor White
        Write-Host "      Bucket: $($item.Outputs.BucketName)" -ForegroundColor White
        Write-Host ""
    }
    
    Write-Host "[Proximos pasos]" -ForegroundColor Cyan
    Write-Host "   1. Los participantes pueden ahora desplegar sus AI Stacks durante el workshop" -ForegroundColor White
    Write-Host "   2. Compartir con cada participante:" -ForegroundColor White
    Write-Host "      - Su PARTICIPANT_PREFIX" -ForegroundColor Gray
    Write-Host "      - Instrucciones para desplegar AI Stacks" -ForegroundColor Gray
    Write-Host ""
    
}
catch {
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Red
    Write-Host "  [ERROR] Error durante el despliegue" -ForegroundColor Red
    Write-Host "============================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "[AVISO] Algunos stacks pueden haberse desplegado exitosamente." -ForegroundColor Yellow
    Write-Host "   Revisar la consola de CloudFormation para mas detalles." -ForegroundColor Yellow
    Write-Host ""
    Pop-Location
    exit 1
}
finally {
    Pop-Location
}

Write-Host "[OK] Script completado exitosamente" -ForegroundColor Green
Write-Host ""
