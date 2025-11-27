# Script para destruir todos los stacks en orden correcto
$env:AWS_PROFILE = "pulsosalud-immersion"

Write-Host "🗑️  Destruyendo todos los stacks de PulsoSalud..." -ForegroundColor Red
Write-Host ""

# Función para verificar si un stack existe
function StackExists($stackName) {
    $result = aws cloudformation describe-stacks --stack-name $stackName --profile pulsosalud-immersion 2>&1
    return $LASTEXITCODE -eq 0
}

# Función para esperar eliminación
function WaitForDeletion($stackName) {
    Write-Host "⏳ Esperando eliminación de $stackName..." -ForegroundColor Yellow
    aws cloudformation wait stack-delete-complete --stack-name $stackName --profile pulsosalud-immersion 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $stackName eliminado" -ForegroundColor Green
    }
}

# Paso 1: Eliminar stacks dependientes primero
$dependentStacks = @(
    "demo-AISummaryStack",
    "demo-AIClassificationStack",
    "demo-AIEmailStack"
)

foreach ($stack in $dependentStacks) {
    if (StackExists $stack) {
        Write-Host "Eliminando $stack..." -ForegroundColor Yellow
        aws cloudformation delete-stack --stack-name $stack --profile pulsosalud-immersion
    }
}

# Esperar a que se eliminen
foreach ($stack in $dependentStacks) {
    if (StackExists $stack) {
        WaitForDeletion $stack
    }
}

# Paso 2: Eliminar RAG y Extraction
$middleStacks = @(
    "demo-AIRAGStack",
    "demo-AIExtractionStack"
)

foreach ($stack in $middleStacks) {
    if (StackExists $stack) {
        Write-Host "Eliminando $stack..." -ForegroundColor Yellow
        aws cloudformation delete-stack --stack-name $stack --profile pulsosalud-immersion
    }
}

foreach ($stack in $middleStacks) {
    if (StackExists $stack) {
        WaitForDeletion $stack
    }
}

# Paso 3: Finalmente eliminar Legacy
if (StackExists "demo-MedicalReportsLegacyStack") {
    Write-Host "Eliminando demo-MedicalReportsLegacyStack..." -ForegroundColor Yellow
    aws cloudformation delete-stack --stack-name demo-MedicalReportsLegacyStack --profile pulsosalud-immersion
    WaitForDeletion "demo-MedicalReportsLegacyStack"
}

Write-Host ""
Write-Host "🎉 Todos los stacks han sido eliminados!" -ForegroundColor Green
