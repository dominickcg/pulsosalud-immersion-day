# PDFs de Ejemplo para Demo

Este directorio contiene PDFs de ejemplo de informes médicos ocupacionales para demostrar el sistema de automatización con IA.

## Archivos Incluidos

### 1. informe_bajo_riesgo.pdf
**Trabajador:** Juan Pérez Gómez  
**Nivel de Riesgo Esperado:** BAJO  
**Características:**
- Todos los parámetros dentro de rangos normales
- Presión arterial: 118/78 mmHg
- IMC: 23.5 (peso normal)
- Visión: 20/20 en ambos ojos
- Audiometría: Normal en todas las frecuencias
- Sin observaciones preocupantes

### 2. informe_medio_riesgo.pdf
**Trabajador:** María González López  
**Nivel de Riesgo Esperado:** MEDIO  
**Características:**
- Algunos parámetros fuera de rango normal
- Presión arterial: 142/88 mmHg (pre-hipertensión)
- IMC: 28.3 (sobrepeso)
- Visión: 20/30 en ojo derecho (reducida)
- Audiometría: Pérdida leve en frecuencias altas
- Observaciones: Requiere seguimiento y control

### 3. informe_alto_riesgo.pdf
**Trabajador:** Carlos Rodríguez Martínez  
**Nivel de Riesgo Esperado:** ALTO  
**Características:**
- Múltiples parámetros fuera de rango
- Presión arterial: 165/102 mmHg (hipertensión)
- IMC: 32.8 (obesidad)
- Visión: 20/40 en ambos ojos (reducida significativamente)
- Audiometría: Pérdida moderada bilateral
- Observaciones: Requiere atención médica inmediata

## Uso en la Demo

Estos PDFs están diseñados para:

1. **Demostrar la extracción con IA:**
   - Subir a S3 en la carpeta `external-reports/`
   - Verificar que Textract extrae el texto correctamente
   - Confirmar que Bedrock estructura los datos en JSON

2. **Validar la clasificación de riesgo:**
   - Verificar que el sistema clasifica correctamente cada nivel
   - Comprobar que las justificaciones son apropiadas
   - Demostrar el uso de contexto histórico (RAG)

3. **Probar diferentes formatos:**
   - Cada PDF tiene un formato ligeramente diferente
   - Demuestra la flexibilidad del sistema de IA
   - Valida la robustez de la extracción

## Comandos para Subir a S3

```bash
# Configurar variables
export BUCKET_NAME=tu-bucket-name
export PREFIX=demo

# Subir PDFs de ejemplo
aws s3 cp informe_bajo_riesgo.pdf s3://${BUCKET_NAME}/external-reports/
aws s3 cp informe_medio_riesgo.pdf s3://${BUCKET_NAME}/external-reports/
aws s3 cp informe_alto_riesgo.pdf s3://${BUCKET_NAME}/external-reports/

# Verificar que se subieron correctamente
aws s3 ls s3://${BUCKET_NAME}/external-reports/
```

## Verificación del Procesamiento

Después de subir los PDFs, verificar en CloudWatch Logs:

```bash
# Ver logs de extracción
aws logs tail /aws/lambda/${PREFIX}-extract-pdf --follow

# Ver logs de clasificación
aws logs tail /aws/lambda/${PREFIX}-classify-risk --follow

# Ver logs de resumen
aws logs tail /aws/lambda/${PREFIX}-generate-summary --follow

# Ver logs de email
aws logs tail /aws/lambda/${PREFIX}-send-email --follow
```

## Resultados Esperados

### Informe Bajo Riesgo
- **Clasificación:** BAJO
- **Justificación:** "Todos los parámetros vitales dentro de rangos normales. Trabajador en excelente condición física."
- **Resumen:** Positivo y tranquilizador
- **Email:** Tono tranquilizador y motivador

### Informe Medio Riesgo
- **Clasificación:** MEDIO
- **Justificación:** "Presión arterial elevada y sobrepeso requieren seguimiento. Se recomienda control médico."
- **Resumen:** Profesional con recomendaciones claras
- **Email:** Tono profesional con plan de acción

### Informe Alto Riesgo
- **Clasificación:** ALTO
- **Justificación:** "Hipertensión severa y obesidad con múltiples factores de riesgo. Requiere atención inmediata."
- **Resumen:** Urgente pero constructivo
- **Email:** Tono urgente con pasos inmediatos

## Notas para la Demo

- Los PDFs tienen formatos ligeramente diferentes para demostrar flexibilidad
- Incluyen todos los campos requeridos por el sistema
- Los valores están basados en rangos médicos reales
- Cada PDF es representativo de su nivel de riesgo

