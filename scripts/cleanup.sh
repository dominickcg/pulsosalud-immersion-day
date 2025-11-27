#!/bin/bash

# ============================================
# Script de Limpieza de Recursos AWS
# ============================================
# Este script elimina todos los recursos creados durante el workshop
# para evitar costos innecesarios.
#
# Uso:
#   bash scripts/cleanup.sh
#
# Nota: Este script es destructivo. Asegúrate de que quieres eliminar
# todos los recursos antes de ejecutarlo.
# ============================================

set -e  # Salir si hay algún error

echo "🧹 Iniciando limpieza de recursos AWS..."
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_info() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Verificar que estamos en el directorio correcto
if [ ! -d "cdk" ]; then
    print_error "Error: Debes ejecutar este script desde la raíz del proyecto"
    exit 1
fi

# Confirmar con el usuario
echo -e "${YELLOW}⚠ ADVERTENCIA:${NC} Este script eliminará TODOS los recursos del workshop."
echo "Esto incluye:"
echo "  - Todos los stacks de CloudFormation"
echo "  - Base de datos Aurora (sin snapshots)"
echo "  - Bucket S3 y su contenido"
echo "  - Funciones Lambda"
echo "  - Logs de CloudWatch"
echo ""
read -p "¿Estás seguro de que quieres continuar? (escribe 'yes' para confirmar): " confirm

if [ "$confirm" != "yes" ]; then
    print_warning "Limpieza cancelada"
    exit 0
fi

echo ""
print_info "Iniciando limpieza..."
echo ""

# Cambiar al directorio de CDK
cd cdk

# Lista de stacks en orden de eliminación (inverso al despliegue)
STACKS=(
    "AIEmailStack"
    "AISummaryStack"
    "AIClassificationStack"
    "AIRAGStack"
    "AIExtractionStack"
    "LegacyStack"
)

# Eliminar cada stack
for stack in "${STACKS[@]}"; do
    echo ""
    print_info "Eliminando stack: $stack"
    
    # Verificar si el stack existe
    if aws cloudformation describe-stacks --stack-name "$stack" &> /dev/null; then
        # Eliminar el stack
        cdk destroy "$stack" --force
        
        if [ $? -eq 0 ]; then
            print_info "Stack $stack eliminado exitosamente"
        else
            print_error "Error al eliminar stack $stack"
        fi
    else
        print_warning "Stack $stack no existe, saltando..."
    fi
done

# Volver al directorio raíz
cd ..

echo ""
print_info "Limpieza de stacks completada"
echo ""

# Verificar si quedan recursos
echo "Verificando recursos restantes..."
echo ""

# Verificar stacks
remaining_stacks=$(aws cloudformation list-stacks \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
    --query 'StackSummaries[?contains(StackName, `Stack`)].StackName' \
    --output text 2>/dev/null || echo "")

if [ -n "$remaining_stacks" ]; then
    print_warning "Stacks restantes encontrados:"
    echo "$remaining_stacks"
else
    print_info "No hay stacks restantes"
fi

# Verificar buckets S3 (opcional: eliminar manualmente)
echo ""
echo "Nota: Si creaste buckets S3 manualmente, elimínalos con:"
echo "  aws s3 rb s3://tu-bucket-name --force"
echo ""

# Verificar logs de CloudWatch (opcional: eliminar manualmente)
echo "Nota: Los logs de CloudWatch se conservan por defecto."
echo "Para eliminarlos manualmente:"
echo "  aws logs delete-log-group --log-group-name /aws/lambda/nombre-funcion"
echo ""

print_info "¡Limpieza completada!"
echo ""
echo "Recursos eliminados:"
echo "  ✓ Todos los stacks de CloudFormation"
echo "  ✓ Base de datos Aurora"
echo "  ✓ Funciones Lambda"
echo "  ✓ API Gateway"
echo "  ✓ Roles y políticas IAM"
echo ""
echo "Recursos que pueden requerir limpieza manual:"
echo "  - Buckets S3 (si fueron creados manualmente)"
echo "  - Log groups de CloudWatch"
echo "  - Emails verificados en SES"
echo ""
print_info "¡Listo! Tu cuenta AWS está limpia."
