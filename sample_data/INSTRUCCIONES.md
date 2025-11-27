# Instrucciones para Generar PDFs de Ejemplo

## Requisitos Previos

- Python 3.8 o superior instalado
- pip (gestor de paquetes de Python)

## Pasos para Generar los PDFs

### 1. Instalar Dependencias

```bash
cd sample_data
pip install -r requirements.txt
```

O instalar directamente:

```bash
pip install reportlab==4.0.7
```

### 2. Generar los PDFs

```bash
python generate_sample_pdfs.py
```

Este script generará 3 archivos PDF:
- `informe_bajo_riesgo.pdf`
- `informe_medio_riesgo.pdf`
- `informe_alto_riesgo.pdf`

### 3. Verificar los Archivos Generados

```bash
ls -la *.pdf
```

Deberías ver los 3 archivos PDF creados.

## Contenido de los PDFs

### Informe de Riesgo BAJO
- **Trabajador:** Juan Pérez Gómez
- **Presión Arterial:** 118/78 mmHg (Normal)
- **IMC:** 23.7 (Peso normal)
- **Visión:** 20/20 (Normal)
- **Audiometría:** Normal
- **Observaciones:** Excelente estado de salud, apto sin restricciones

### Informe de Riesgo MEDIO
- **Trabajador:** María González López
- **Presión Arterial:** 142/88 mmHg (Pre-hipertensión)
- **IMC:** 28.6 (Sobrepeso)
- **Visión:** 20/30 (Leve reducción)
- **Audiometría:** Pérdida leve en frecuencias altas
- **Observaciones:** Requiere seguimiento y control médico

### Informe de Riesgo ALTO
- **Trabajador:** Carlos Rodríguez Martínez
- **Presión Arterial:** 165/102 mmHg (Hipertensión severa)
- **IMC:** 32.9 (Obesidad)
- **Visión:** 20/40 (Reducción significativa)
- **Audiometría:** Pérdida moderada bilateral
- **Observaciones:** Requiere atención médica inmediata, no apto hasta estabilización

## Uso en la Demo

### Subir a S3

Una vez generados los PDFs, súbelos a S3:

```bash
# Configurar variables
export BUCKET_NAME=tu-bucket-name
export PREFIX=demo

# Subir PDFs
aws s3 cp informe_bajo_riesgo.pdf s3://${BUCKET_NAME}/external-reports/
aws s3 cp informe_medio_riesgo.pdf s3://${BUCKET_NAME}/external-reports/
aws s3 cp informe_alto_riesgo.pdf s3://${BUCKET_NAME}/external-reports/
```

### Verificar Procesamiento

Monitorear los logs de CloudWatch:

```bash
# Logs de extracción
aws logs tail /aws/lambda/${PREFIX}-extract-pdf --follow

# Logs de clasificación
aws logs tail /aws/lambda/${PREFIX}-classify-risk --follow

# Logs de resumen
aws logs tail /aws/lambda/${PREFIX}-generate-summary --follow

# Logs de email
aws logs tail /aws/lambda/${PREFIX}-send-email --follow
```

### Verificar en Aurora

Consultar los informes procesados:

```sql
-- Ver informes extraídos
SELECT id, trabajador_id, tipo_examen, fecha_examen, nivel_riesgo
FROM informes_medicos
ORDER BY created_at DESC
LIMIT 10;

-- Ver clasificaciones
SELECT im.id, t.nombre, im.nivel_riesgo, im.justificacion_riesgo
FROM informes_medicos im
JOIN trabajadores t ON im.trabajador_id = t.id
WHERE im.nivel_riesgo IS NOT NULL
ORDER BY im.created_at DESC;

-- Ver resúmenes
SELECT im.id, t.nombre, im.nivel_riesgo, im.resumen_ejecutivo
FROM informes_medicos im
JOIN trabajadores t ON im.trabajador_id = t.id
WHERE im.resumen_ejecutivo IS NOT NULL
ORDER BY im.created_at DESC;
```

## Troubleshooting

### Error: Python no encontrado

Si obtienes un error de que Python no está instalado:

**Windows:**
1. Descarga Python desde https://www.python.org/downloads/
2. Durante la instalación, marca "Add Python to PATH"
3. Reinicia la terminal

**macOS:**
```bash
brew install python3
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install python3 python3-pip
```

### Error: reportlab no se instala

Si hay problemas instalando reportlab:

```bash
# Actualizar pip primero
python -m pip install --upgrade pip

# Instalar reportlab
pip install reportlab
```

### Los PDFs no se generan

Verifica que estás en el directorio correcto:

```bash
cd sample_data
pwd  # Debe mostrar .../sample_data
python generate_sample_pdfs.py
```

## Alternativa: Usar PDFs Existentes

Si no puedes generar los PDFs, puedes crear informes médicos manualmente usando cualquier procesador de texto (Word, Google Docs, etc.) y exportarlos como PDF. Asegúrate de incluir:

1. **Datos del trabajador:**
   - Nombre completo
   - RUT/Documento
   - Fecha de nacimiento
   - Cargo

2. **Datos del examen:**
   - Presión arterial
   - Peso y altura
   - Visión
   - Audiometría

3. **Observaciones:**
   - Descripción del estado de salud
   - Recomendaciones

El sistema de IA es flexible y puede extraer información de diferentes formatos de PDF.

