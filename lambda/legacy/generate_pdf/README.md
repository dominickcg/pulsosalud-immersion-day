# Lambda: Generador de PDFs Profesionales (Versión Completa)

Esta Lambda genera PDFs profesionales y completos de informes médicos ocupacionales con un diseño atractivo usando ReportLab.

## Características

- Diseño profesional con colores corporativos
- Formato completo con todas las secciones médicas
- Tablas formateadas con encabezados y filas alternadas
- Soporte para datos JSON (examen físico, exámenes adicionales)
- Cálculo automático de IMC
- Resultados de laboratorio detallados
- Antecedentes médicos
- Examen físico por sistemas
- Exámenes complementarios adicionales
- Observaciones y recomendaciones
- Firma del médico al pie
- Estructura de carpetas organizada por fecha en S3

## Flujo

1. **Leer datos**: Obtiene el informe completo desde Aurora (trabajador, contratista, examen, laboratorio)
2. **Generar PDF**: Crea un PDF profesional y detallado usando ReportLab con platypus
3. **Subir a S3**: Guarda el PDF en S3 con estructura `legacy-reports/YYYY/MM/informe-{id}.pdf`
4. **Actualizar Aurora**: Guarda la ruta del PDF en la columna `pdf_s3_path`

## Request Format

```json
{
  "informe_id": 123
}
```

## Response Format

### Success (200)
```json
{
  "pdf_url": "s3://bucket/legacy-reports/2025/01/informe-123.pdf",
  "message": "PDF generado exitosamente"
}
```

### Not Found (404)
```json
{
  "error": "Informe not found"
}
```

### Server Error (500)
```json
{
  "error": "Internal server error",
  "message": "Error details..."
}
```

## Diseño del PDF

### 1. Encabezado
- Título principal: "INFORME MÉDICO OCUPACIONAL"
- Información de la empresa contratista (nombre, RUC)
- Tipo de examen y fecha de emisión
- Colores: Azul corporativo (#1a5490)

### 2. Datos del Trabajador
- Tabla con fondo gris claro (#f5f5f5)
- Nombre completo, DNI, fecha de nacimiento, edad, cargo
- Etiquetas en negrita, valores en texto normal

### 3. Antecedentes Médicos
- Sección con texto formateado
- Historial médico relevante del trabajador

### 4. Resultados del Examen Médico
- **Signos vitales**: Tabla con encabezado azul (#1a5490)
  - Presión arterial, frecuencia cardíaca, frecuencia respiratoria
  - Temperatura, saturación de oxígeno
  - Peso, altura, IMC, perímetro abdominal
  - Incluye rangos normales para cada parámetro
- **Exámenes complementarios básicos**: Visión, audiometría
- **Laboratorio**: Hemoglobina, glucosa, colesterol, triglicéridos, creatinina, ácido úrico

### 5. Examen Físico
- Tabla con evaluación por sistemas
- Formato: Sistema | Hallazgo
- Sistemas: Cardiovascular, respiratorio, neurológico, etc.

### 6. Exámenes Complementarios Adicionales
- Tabla con exámenes adicionales
- Formato: Examen | Resultado
- Ejemplos: Radiografías, electrocardiogramas, espirometrías

### 7. Observaciones y Recomendaciones
- Conclusiones del médico
- Recomendaciones para el trabajador
- Aptitud laboral

### 8. Pie de Página - Firma
- Línea para firma del médico
- Nombre del médico: Dr. Roberto Sánchez Muñoz
- Especialidad: Médico Ocupacional
- Registro médico

## Formato de Datos JSON

### examen_fisico (JSONB en base de datos)
```json
[
  {
    "sistema": "Cardiovascular",
    "hallazgo": "Ruidos cardíacos rítmicos, sin soplos. Pulsos periféricos presentes y simétricos."
  },
  {
    "sistema": "Respiratorio",
    "hallazgo": "Murmullo vesicular conservado bilateral, sin ruidos agregados."
  },
  {
    "sistema": "Neurológico",
    "hallazgo": "Consciente, orientado en tiempo, espacio y persona. Reflejos osteotendinosos normales."
  }
]
```

### examenes_adicionales (JSONB en base de datos)
```json
[
  {
    "nombre": "Radiografía de Tórax PA y Lateral",
    "resultado": "Campos pulmonares libres, sin infiltrados ni consolidaciones. Silueta cardíaca de tamaño y forma normal. Índice cardiotorácico: 0.45"
  },
  {
    "nombre": "Electrocardiograma de 12 derivaciones",
    "resultado": "Ritmo sinusal normal, 72 lpm. Eje eléctrico normal. Sin alteraciones de la repolarización."
  },
  {
    "nombre": "Espirometría",
    "resultado": "CVF: 4.2 L (95% predicho), VEF1: 3.5 L (92% predicho), VEF1/CVF: 83%. Patrón normal."
  }
]
```

## Colores Utilizados

- **Azul principal**: #1a5490 (títulos y encabezados de tabla)
- **Celeste claro**: #e8f4f8 (fondos de tabla)
- **Gris claro**: #f5f5f5 (sección trabajador, filas alternadas)
- **Gris**: grey (bordes de tabla)

## Dependencies

- `reportlab==4.0.7` - Librería para generación de PDFs

## Environment Variables

- `DB_SECRET_ARN`: ARN del secreto de Secrets Manager
- `DB_CLUSTER_ARN`: ARN del cluster Aurora
- `DATABASE_NAME`: Nombre de la base de datos
- `BUCKET_NAME`: Nombre del bucket S3

## Permisos IAM Requeridos

- `secretsmanager:GetSecretValue` - Para leer credenciales
- `rds-data:ExecuteStatement` - Para leer y actualizar Aurora
- `s3:PutObject` - Para subir PDFs a S3

## Estructura en S3

```
bucket-name/
└── legacy-reports/
    └── 2025/
        └── 01/
            ├── informe-1.pdf
            ├── informe-2.pdf
            └── informe-3.pdf
```

## Migración de Base de Datos

Para usar esta versión actualizada con campos completos, ejecuta primero:

```bash
psql -h <host> -U <user> -d medical_reports -f database/migration_add_detailed_fields.sql
```

Esta migración agrega:
- Campos adicionales a `trabajadores`: edad, cargo
- Campo RUC a `contratistas`
- Campos de signos vitales a `informes_medicos`: frecuencia_cardiaca, frecuencia_respiratoria, temperatura, saturacion_oxigeno, perimetro_abdominal
- Campos de texto: antecedentes_medicos
- Campos JSON: examen_fisico, examenes_adicionales
- Actualiza la vista `informes_completos`

## Ejemplo de PDF Generado

El PDF incluye:
- ✅ Encabezado profesional con información de contratista
- ✅ Datos completos del trabajador (nombre, DNI, edad, cargo)
- ✅ Antecedentes médicos
- ✅ Signos vitales completos con rangos normales
- ✅ Exámenes complementarios (visión, audiometría)
- ✅ Resultados de laboratorio detallados
- ✅ Examen físico por sistemas
- ✅ Exámenes complementarios adicionales (Rx, ECG, etc.)
- ✅ Observaciones y recomendaciones
- ✅ Firma del médico con registro

## Notas Técnicas

- Usa `SimpleDocTemplate` de ReportLab para el layout
- Usa `platypus` para elementos avanzados (tablas, párrafos, espaciadores)
- El PDF se genera en memoria (BytesIO) antes de subir a S3
- Tamaño de página: Letter (8.5" x 11")
- Márgenes: 0.5 pulgadas arriba/abajo, 0.75 pulgadas izquierda/derecha
- Fuentes: Helvetica y Helvetica-Bold
- Manejo de datos JSON con try/except para robustez
- Secciones opcionales: solo se muestran si hay datos disponibles

## Testing

```python
# Test local
event = {'informe_id': 123}
result = handler(event, None)
print(result)
```

## Compatibilidad

Esta versión es **compatible con datos antiguos**:
- Si faltan campos nuevos, simplemente no se muestran en el PDF
- Los campos JSON (examen_fisico, examenes_adicionales) son opcionales
- Los datos de laboratorio son opcionales
- Mantiene compatibilidad con el formato anterior

## Mejoras Futuras

- Agregar logo de la empresa
- Incluir gráficos de tendencias
- Generar código QR para verificación
- Agregar marca de agua
- Soporte para múltiples idiomas
- Exportar a otros formatos (DOCX, HTML)
