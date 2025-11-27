# 🛠️ Scripts de Utilidad

Esta carpeta contiene scripts útiles para gestionar el workshop de Medical Reports Automation.

## 📜 Scripts Disponibles

### 1. cleanup.sh

**Propósito:** Eliminar todos los recursos AWS creados durante el workshop.

**Uso:**
```bash
bash scripts/cleanup.sh
```

**Qué hace:**
- Elimina todos los stacks de CloudFormation en orden correcto
- Elimina base de datos Aurora (sin snapshots)
- Elimina funciones Lambda
- Elimina API Gateway
- Elimina roles y políticas IAM
- Verifica recursos restantes

**Advertencia:** Este script es destructivo. Asegúrate de que quieres eliminar todos los recursos antes de ejecutarlo.

**Ejemplo de salida:**
```
🧹 Iniciando limpieza de recursos AWS...

⚠ ADVERTENCIA: Este script eliminará TODOS los recursos del workshop.
¿Estás seguro de que quieres continuar? (escribe 'yes' para confirmar): yes

✓ Iniciando limpieza...

✓ Eliminando stack: AIEmailStack
✓ Stack AIEmailStack eliminado exitosamente

✓ Eliminando stack: AISummaryStack
✓ Stack AISummaryStack eliminado exitosamente

...

✓ ¡Limpieza completada!
```

---

### 2. upload_sample_pdf.sh

**Propósito:** Subir PDFs de ejemplo al bucket S3 para probar el sistema de extracción.

**Uso:**

**Opción 1: Subir todos los PDFs de ejemplo**
```bash
bash scripts/upload_sample_pdf.sh
```

El script detectará automáticamente el nombre del bucket desde CloudFormation.

**Opción 2: Subir un PDF específico**
```bash
bash scripts/upload_sample_pdf.sh [archivo.pdf] [bucket-name]
```

**Ejemplos:**
```bash
# Subir todos los PDFs de ejemplo
bash scripts/upload_sample_pdf.sh

# Subir un PDF específico
bash scripts/upload_sample_pdf.sh sample_data/informe_alto_riesgo.pdf my-bucket-name

# Subir un PDF personalizado
bash scripts/upload_sample_pdf.sh mi_informe.pdf my-bucket-name
```

**Qué hace:**
- Detecta automáticamente el nombre del bucket (si no se especifica)
- Sube PDFs a la carpeta `external-reports/`
- Verifica que los archivos sean PDFs válidos
- Lista los PDFs en S3 después de subir
- Proporciona comandos para verificar el procesamiento

**Ejemplo de salida:**
```
📄 Subir PDFs de Ejemplo a S3
==============================

✓ Obteniendo nombre del bucket desde CloudFormation...
✓ Bucket encontrado: medical-reports-bucket-abc123
✓ PDFs encontrados: 3

Se subirán los siguientes archivos:
  - informe_alto_riesgo.pdf
  - informe_medio_riesgo.pdf
  - informe_bajo_riesgo.pdf

¿Continuar? (y/n): y

Subiendo: informe_alto_riesgo.pdf
✓ Subido: informe_alto_riesgo.pdf → s3://medical-reports-bucket-abc123/external-reports/informe_alto_riesgo.pdf

...

✓ Subidos: 3/3 PDFs

PDFs en S3:
----------
2024-01-15 10:30:00    1234567 external-reports/informe_alto_riesgo.pdf
2024-01-15 10:30:01    1234568 external-reports/informe_medio_riesgo.pdf
2024-01-15 10:30:02    1234569 external-reports/informe_bajo_riesgo.pdf

✓ ¡Listo! Los PDFs se procesarán automáticamente.
```

---

## 🚀 Flujo de Trabajo Típico

### Durante el Workshop

1. **Desplegar infraestructura:**
   ```bash
   cd cdk
   cdk deploy --all
   ```

2. **Subir PDFs de prueba:**
   ```bash
   bash scripts/upload_sample_pdf.sh
   ```

3. **Verificar procesamiento:**
   ```bash
   aws logs tail /aws/lambda/extract-pdf --follow
   ```

### Después del Workshop

1. **Limpiar recursos:**
   ```bash
   bash scripts/cleanup.sh
   ```

2. **Verificar limpieza:**
   ```bash
   aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE
   ```

---

## 📝 Notas Importantes

### Permisos Requeridos

Los scripts requieren que tengas configurado AWS CLI con credenciales que tengan permisos para:
- CloudFormation (crear/eliminar stacks)
- S3 (subir/listar objetos)
- Lambda (ver logs)
- IAM (crear/eliminar roles)

### Regiones

Los scripts usan la región configurada en tu AWS CLI. Verifica que estés en la región correcta:
```bash
aws configure get region
```

### Troubleshooting

**Error: "Debes ejecutar este script desde la raíz del proyecto"**
- Solución: Ejecuta el script desde el directorio raíz del proyecto, no desde la carpeta `scripts/`

**Error: "No se pudo obtener el nombre del bucket"**
- Solución: Especifica el nombre del bucket manualmente o verifica que el stack LegacyStack esté desplegado

**Error: "Stack no existe"**
- Solución: Normal si el stack ya fue eliminado o nunca se desplegó

---

## 🔧 Personalización

### Agregar Más Stacks a cleanup.sh

Si agregas nuevos stacks, actualiza el array `STACKS` en `cleanup.sh`:

```bash
STACKS=(
    "MiNuevoStack"      # Agregar aquí
    "AIEmailStack"
    "AISummaryStack"
    # ...
)
```

**Importante:** Los stacks deben estar en orden inverso al despliegue (último desplegado primero).

### Cambiar Carpeta de Destino en S3

Para subir PDFs a una carpeta diferente, modifica `upload_sample_pdf.sh`:

```bash
# Cambiar esta línea:
aws s3 cp "$file" "s3://$bucket/external-reports/$filename"

# Por:
aws s3 cp "$file" "s3://$bucket/mi-carpeta/$filename"
```

---

## 📚 Recursos Adicionales

- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [S3 Documentation](https://docs.aws.amazon.com/s3/)
- [Bash Scripting Guide](https://www.gnu.org/software/bash/manual/)

---

## ✅ Checklist de Uso

### Antes del Workshop
- [ ] Verificar que AWS CLI está configurado
- [ ] Verificar permisos de la cuenta AWS
- [ ] Probar scripts en cuenta de prueba

### Durante el Workshop
- [ ] Usar `upload_sample_pdf.sh` para subir PDFs
- [ ] Verificar procesamiento en CloudWatch
- [ ] Ayudar a participantes con problemas

### Después del Workshop
- [ ] Ejecutar `cleanup.sh` para eliminar recursos
- [ ] Verificar que no quedan recursos
- [ ] Confirmar que no hay costos inesperados

---

¿Preguntas? Consulta la [Guía del Instructor](../INSTRUCTOR_GUIDE.md) o la [Guía para Participantes](../PARTICIPANT_GUIDE.md).
