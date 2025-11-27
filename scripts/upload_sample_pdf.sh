#!/bin/bash

# ============================================
# Script para Subir PDFs de Ejemplo a S3
# ============================================
# Este script facilita la carga de PDFs de ejemplo al bucket S3
# para probar el sistema de extracción con IA.
#
# Uso:
#   bash scripts/upload_sample_pdf.sh [archivo.pdf] [bucket-name]
#
# Ejemplos:
#   bash scripts/upload_sample_pdf.sh sample_data/informe_alto_riesgo.pdf my-bucket
#   bash scripts/upload_sample_pdf.sh sample_data/informe_medio_riesgo.pdf my-bucket
#   bash scripts/upload_sample_pdf.sh sample_data/informe_bajo_riesgo.pdf my-bucket
#
# Si no se especifican parámetros, el script subirá todos los PDFs
# de ejemplo al bucket configurado.
# ============================================

set -e  # Salir si hay algún error

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Banner
echo "📄 Subir PDFs de Ejemplo a S3"
echo "=============================="
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -d "sample_data" ]; then
    print_error "Error: Debes ejecutar este script desde la raíz del proyecto"
    exit 1
fi

# Función para obtener el nombre del bucket desde los outputs de CloudFormation
get_bucket_name() {
    local bucket=$(aws cloudformation describe-stacks \
        --stack-name LegacyStack \
        --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' \
        --output text 2>/dev/null)
    
    if [ -z "$bucket" ]; then
        return 1
    fi
    
    echo "$bucket"
}

# Función para subir un PDF
upload_pdf() {
    local file=$1
    local bucket=$2
    local filename=$(basename "$file")
    
    echo "Subiendo: $filename"
    
    # Subir a la carpeta external-reports/
    aws s3 cp "$file" "s3://$bucket/external-reports/$filename"
    
    if [ $? -eq 0 ]; then
        print_info "Subido: $filename → s3://$bucket/external-reports/$filename"
        return 0
    else
        print_error "Error al subir: $filename"
        return 1
    fi
}

# Función para listar PDFs en S3
list_pdfs() {
    local bucket=$1
    
    echo ""
    echo "PDFs en S3:"
    echo "----------"
    aws s3 ls "s3://$bucket/external-reports/" --recursive | grep ".pdf$" || echo "  (ninguno)"
    echo ""
}

# Modo 1: Subir un archivo específico
if [ $# -eq 2 ]; then
    PDF_FILE=$1
    BUCKET_NAME=$2
    
    # Verificar que el archivo existe
    if [ ! -f "$PDF_FILE" ]; then
        print_error "Error: Archivo no encontrado: $PDF_FILE"
        exit 1
    fi
    
    # Verificar que es un PDF
    if [[ ! "$PDF_FILE" =~ \.pdf$ ]]; then
        print_error "Error: El archivo debe ser un PDF"
        exit 1
    fi
    
    print_info "Bucket: $BUCKET_NAME"
    print_info "Archivo: $PDF_FILE"
    echo ""
    
    upload_pdf "$PDF_FILE" "$BUCKET_NAME"
    list_pdfs "$BUCKET_NAME"
    
    print_info "¡Listo! El PDF se procesará automáticamente."
    echo "Verifica los logs en CloudWatch:"
    echo "  aws logs tail /aws/lambda/extract-pdf --follow"
    
    exit 0
fi

# Modo 2: Subir todos los PDFs de ejemplo
if [ $# -eq 0 ]; then
    # Intentar obtener el nombre del bucket automáticamente
    print_info "Obteniendo nombre del bucket desde CloudFormation..."
    BUCKET_NAME=$(get_bucket_name)
    
    if [ -z "$BUCKET_NAME" ]; then
        print_error "No se pudo obtener el nombre del bucket automáticamente"
        echo ""
        echo "Uso:"
        echo "  bash scripts/upload_sample_pdf.sh [archivo.pdf] [bucket-name]"
        echo ""
        echo "Ejemplos:"
        echo "  bash scripts/upload_sample_pdf.sh sample_data/informe_alto_riesgo.pdf my-bucket"
        echo "  bash scripts/upload_sample_pdf.sh sample_data/informe_medio_riesgo.pdf my-bucket"
        echo ""
        echo "Para obtener el nombre de tu bucket:"
        echo "  aws cloudformation describe-stacks --stack-name LegacyStack \\"
        echo "    --query 'Stacks[0].Outputs[?OutputKey==\`BucketName\`].OutputValue' \\"
        echo "    --output text"
        exit 1
    fi
    
    print_info "Bucket encontrado: $BUCKET_NAME"
    echo ""
    
    # Buscar todos los PDFs en sample_data
    PDF_FILES=(sample_data/*.pdf)
    
    if [ ${#PDF_FILES[@]} -eq 0 ] || [ ! -f "${PDF_FILES[0]}" ]; then
        print_warning "No se encontraron PDFs en sample_data/"
        echo ""
        echo "Genera los PDFs primero:"
        echo "  cd sample_data"
        echo "  python generate_sample_pdfs.py"
        exit 1
    fi
    
    print_info "PDFs encontrados: ${#PDF_FILES[@]}"
    echo ""
    
    # Confirmar con el usuario
    echo "Se subirán los siguientes archivos:"
    for pdf in "${PDF_FILES[@]}"; do
        echo "  - $(basename "$pdf")"
    done
    echo ""
    read -p "¿Continuar? (y/n): " confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_warning "Operación cancelada"
        exit 0
    fi
    
    echo ""
    
    # Subir cada PDF
    success_count=0
    for pdf in "${PDF_FILES[@]}"; do
        if upload_pdf "$pdf" "$BUCKET_NAME"; then
            ((success_count++))
        fi
    done
    
    echo ""
    print_info "Subidos: $success_count/${#PDF_FILES[@]} PDFs"
    
    list_pdfs "$BUCKET_NAME"
    
    print_info "¡Listo! Los PDFs se procesarán automáticamente."
    echo ""
    echo "Verifica el procesamiento:"
    echo "  1. Logs en CloudWatch:"
    echo "     aws logs tail /aws/lambda/extract-pdf --follow"
    echo ""
    echo "  2. Datos en Aurora:"
    echo "     psql -h <endpoint> -U postgres -d medical_reports \\"
    echo "       -c \"SELECT id, trabajador_nombre, origen FROM informes_medicos WHERE origen='EXTERNO';\""
    echo ""
    
    exit 0
fi

# Modo inválido
print_error "Número incorrecto de argumentos"
echo ""
echo "Uso:"
echo "  bash scripts/upload_sample_pdf.sh                              # Subir todos los PDFs"
echo "  bash scripts/upload_sample_pdf.sh [archivo.pdf] [bucket-name] # Subir un PDF específico"
echo ""
echo "Ejemplos:"
echo "  bash scripts/upload_sample_pdf.sh"
echo "  bash scripts/upload_sample_pdf.sh sample_data/informe_alto_riesgo.pdf my-bucket"
exit 1
