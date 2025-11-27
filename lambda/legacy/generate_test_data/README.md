# Lambda: Generador de Datos de Prueba

Esta Lambda genera datos de prueba realistas para informes médicos. Es útil para demos y testing del sistema.

## Características

- Genera datos aleatorios pero realistas usando la librería Faker
- Permite especificar el nivel de riesgo deseado (BAJO, MEDIO, ALTO)
- Genera valores de laboratorio coherentes con el nivel de riesgo
- Incluye datos completos: trabajador, contratista, examen y laboratorio

## Request Format

### Generar con nivel de riesgo específico

```json
{
  "nivel_riesgo_deseado": "ALTO"
}
```

### Generar con nivel aleatorio (request vacío)

```json
{}
```

## Response Format

```json
{
  "informe_id": 123,
  "pdf_url": "s3://bucket/legacy-reports/2025/01/informe-123.pdf",
  "nivel_riesgo_generado": "ALTO",
  "datos_generados": {
    "trabajador": {
      "nombre": "Juan Pérez García",
      "documento": "45678912",
      "fecha_nacimiento": "1985-03-15",
      "genero": "Masculino",
      "puesto": "Operador de maquinaria"
    },
    "contratista": {
      "nombre": "Constructora ABC S.A.C.",
      "email": "rrhh@constructoraabc.com"
    },
    "examen": {
      "tipo": "Pre-empleo",
      "presion_arterial": "165/105",
      "peso": 105.5,
      "altura": 1.75,
      "imc": 34.4,
      "vision": "20/20",
      "audiometria": "Normal",
      "laboratorio": {
        "hematologia": {...},
        "perfil_lipidico": {...},
        "glucosa": {...},
        "funcion_renal": {...},
        "funcion_hepatica": {...}
      },
      "observaciones": "Paciente presenta hipertensión arterial severa..."
    }
  },
  "message": "Datos de prueba generados exitosamente"
}
```

## Niveles de Riesgo

### BAJO
- Presión arterial: 110-129 / 70-84 mmHg
- Peso: 60-85 kg
- Colesterol total: 150-199 mg/dL
- Glucosa: 70-99 mg/dL
- Observaciones: Valores normales, paciente saludable

### MEDIO
- Presión arterial: 130-145 / 85-94 mmHg
- Peso: 75-95 kg
- Colesterol total: 200-239 mg/dL
- Glucosa: 100-119 mg/dL
- Observaciones: Valores límite, requiere seguimiento

### ALTO
- Presión arterial: 150-180 / 95-110 mmHg
- Peso: 95-120 kg
- Colesterol total: 240-280 mg/dL
- Glucosa: 120-150 mg/dL
- Observaciones: Valores de riesgo, requiere atención médica

## Datos Generados

### Trabajador
- Nombre completo (usando Faker con locale español)
- Documento de identidad (8 dígitos)
- Fecha de nacimiento (18-65 años)
- Género (Masculino/Femenino)
- Puesto de trabajo (aleatorio de lista predefinida)

### Contratista
- Nombre de empresa (usando Faker)
- Email corporativo

### Examen
- Tipo de examen (Pre-empleo, Periódico, Post-empleo, Reintegro)
- Signos vitales (presión, peso, altura, IMC)
- Visión y audiometría
- Laboratorio completo:
  - Hematología (hemoglobina, hematocrito, glóbulos blancos, plaquetas)
  - Perfil lipídico (colesterol total, HDL, LDL, triglicéridos)
  - Glucosa basal
  - Función renal (creatinina, urea, ácido úrico)
  - Función hepática (TGO, TGP, bilirrubina)
- Observaciones médicas coherentes con los valores

## Dependencies

- `Faker==22.0.0` - Para generar datos realistas

## Environment Variables

- `DB_SECRET_ARN`: ARN del secreto de Aurora
- `DB_CLUSTER_ARN`: ARN del cluster Aurora
- `DATABASE_NAME`: Nombre de la base de datos
- `BUCKET_NAME`: Nombre del bucket S3

## Uso en la Demo

Esta Lambda es especialmente útil para:
1. Generar datos de prueba rápidamente durante la demo
2. Crear informes con diferentes niveles de riesgo para mostrar la clasificación de IA
3. Poblar la base de datos con datos realistas para testing

## Ejemplo de Uso

```bash
# Generar informe de riesgo alto
curl -X POST https://api-url/examenes/generar-prueba \
  -H "Content-Type: application/json" \
  -d '{"nivel_riesgo_deseado": "ALTO"}'

# Generar informe con nivel aleatorio
curl -X POST https://api-url/examenes/generar-prueba
```

## Notas

- Si Faker no está disponible, usa un fallback con datos predefinidos
- Los valores de laboratorio son coherentes con el nivel de riesgo especificado
- Las observaciones médicas se generan automáticamente según los valores
- Todos los datos son ficticios y generados aleatoriamente
