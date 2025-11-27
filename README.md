# 🏥 Medical Reports Automation - Demo Workshop

Sistema de automatización de informes médicos ocupacionales usando AWS y Amazon Bedrock para demostrar capacidades de IA Generativa en un caso de uso real.

## 📋 Descripción

Este proyecto es una demo práctica de 3h 15min (dividida en 2 días) que muestra cómo integrar servicios de AWS con Amazon Bedrock para automatizar el procesamiento de informes médicos ocupacionales. Los participantes aprenderán a:

- Extraer datos de PDFs usando **Amazon Textract** y **Amazon Bedrock**
- Implementar **RAG (Retrieval-Augmented Generation)** con embeddings vectoriales
- Clasificar riesgos usando **few-shot learning**
- Generar resúmenes ejecutivos con contexto histórico
- Personalizar emails según nivel de riesgo

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                        SISTEMA LEGACY                            │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐                  │
│  │ Register │───▶│  Aurora  │◀───│ Generate │                  │
│  │  Exam    │    │PostgreSQL│    │   PDF    │                  │
│  └──────────┘    │+pgvector │    └──────────┘                  │
│                   └────┬─────┘                                   │
└────────────────────────┼─────────────────────────────────────────┘
                         │
┌────────────────────────┼─────────────────────────────────────────┐
│                 SISTEMA DE IA                                    │
│                        │                                          │
│  ┌─────────────────────▼──────────────────────┐                 │
│  │         S3 Bucket (PDFs externos)          │                 │
│  └─────────────────────┬──────────────────────┘                 │
│                        │ trigger                                 │
│  ┌─────────────────────▼──────────────────────┐                 │
│  │  Lambda: Extract PDF                       │                 │
│  │  • Amazon Textract (OCR)                   │                 │
│  │  • Amazon Bedrock Nova Pro (estructurar)   │                 │
│  └─────────────────────┬──────────────────────┘                 │
│                        │                                          │
│  ┌─────────────────────▼──────────────────────┐                 │
│  │  Lambda: Generate Embeddings               │                 │
│  │  • Amazon Titan Embeddings v2              │                 │
│  │  • Guardar en pgvector                     │                 │
│  └─────────────────────┬──────────────────────┘                 │
│                        │                                          │
│  ┌─────────────────────▼──────────────────────┐                 │
│  │  Lambda: Classify Risk                     │                 │
│  │  • RAG: buscar informes anteriores         │                 │
│  │  • Amazon Bedrock Nova Pro (few-shot)      │                 │
│  └─────────────────────┬──────────────────────┘                 │
│                        │                                          │
│  ┌─────────────────────▼──────────────────────┐                 │
│  │  Lambda: Generate Summary                  │                 │
│  │  • RAG: contexto histórico                 │                 │
│  │  • Amazon Bedrock Nova Pro                 │                 │
│  └─────────────────────┬──────────────────────┘                 │
│                        │                                          │
│  ┌─────────────────────▼──────────────────────┐                 │
│  │  Lambda: Send Email                        │                 │
│  │  • Amazon Bedrock Nova Pro (personalizar)  │                 │
│  │  • Amazon SES (enviar)                     │                 │
│  └────────────────────────────────────────────┘                 │
└──────────────────────────────────────────────────────────────────┘
```

## 🚀 Setup Rápido

### Prerequisitos

- **AWS CLI** configurado con credenciales (usuario IAM o AWS SSO)
- **Node.js** 18+ y npm
- **Python** 3.11+
- **AWS CDK** instalado globalmente: `npm install -g aws-cdk`
- **Cuenta AWS** con acceso a Amazon Bedrock y permisos de administrador

### 1. Configurar AWS CLI

Configura tus credenciales de AWS usando uno de estos métodos:

#### Opción A: Usuario IAM

```bash
aws configure
# Ingresa tu Access Key ID, Secret Access Key, región (us-east-2), y formato (json)
```

#### Opción B: AWS SSO

```bash
aws configure sso
# Sigue las instrucciones para configurar tu perfil SSO
# Luego inicia sesión: aws sso login --profile <tu-perfil>
```

**Verificar configuración:**

```bash
aws sts get-caller-identity
# O si usas un perfil específico:
aws sts get-caller-identity --profile <tu-perfil>
```

### 2. Clonar el Repositorio

```bash
git clone <repository-url>
cd medical-reports-automation
```

### 3. Instalar Dependencias

```bash
# Instalar dependencias de CDK
cd cdk
npm install
cd ..
```

### 4. Configurar Variable de Entorno (Si usas perfil AWS específico)

Si configuraste un perfil AWS específico, establece la variable de entorno:

```bash
# Linux/Mac
export AWS_PROFILE=tu-perfil

# Windows PowerShell
$env:AWS_PROFILE = "tu-perfil"

# Windows CMD
set AWS_PROFILE=tu-perfil
```

### 5. Configurar Prefijo Único

Cada participante debe usar un prefijo único para evitar conflictos de nombres:

```bash
# Editar cdk/bin/app.ts y cambiar el prefijo
# Por ejemplo: 'participant-john' o 'team-alpha'
```

### 6. Desplegar Infraestructura

```bash
cd cdk

# Bootstrap CDK (solo primera vez)
cdk bootstrap

# Opción A: Desplegar todo de una vez (recomendado)
cdk deploy --all --require-approval never

# Opción B: Desplegar stack por stack (para seguir el workshop)
cdk deploy LegacyStack
cdk deploy AIExtractionStack
cdk deploy AIRAGStack
cdk deploy AIClassificationStack
cdk deploy AISummaryStack
cdk deploy AIEmailStack

# Si usas perfil específico, agrega --profile:
cdk deploy --all --require-approval never --profile tu-perfil
```

**Nota:** El despliegue completo toma aproximadamente 25-35 minutos (Aurora Serverless toma la mayor parte del tiempo).

### 8. Configurar Base de Datos

```bash
# Obtener endpoint de Aurora desde outputs del stack
# Conectar y ejecutar scripts SQL

psql -h <aurora-endpoint> -U postgres -d medical_reports

# Ejecutar schema
\i ../database/schema.sql

# Ejecutar datos de seed
\i ../database/seed_data.sql
```

### 9. Verificar Email en SES

El sistema envía emails personalizados, por lo que necesitas verificar tu dirección de email:

```bash
# Verificar tu email en Amazon SES
aws ses verify-email-identity --email-address tu-email@ejemplo.com --region us-east-2

# Si usas perfil específico:
aws ses verify-email-identity --email-address tu-email@ejemplo.com --region us-east-2 --profile tu-perfil

# Recibirás un email de verificación. Haz clic en el enlace para confirmar.

# Verificar estado de verificación
aws ses get-identity-verification-attributes \
  --identities tu-email@ejemplo.com \
  --region us-east-2
```

**Nota:** Si tu cuenta está en el SES Sandbox (cuentas nuevas), solo podrás enviar emails a direcciones verificadas. Para producción, solicita salir del sandbox en la consola de SES.

## 📚 Estructura del Proyecto

```
medical-reports-automation/
├── cdk/                          # Infraestructura AWS CDK
│   ├── bin/
│   │   └── app.ts               # Punto de entrada CDK
│   ├── lib/
│   │   ├── legacy-stack.ts      # Sistema legacy
│   │   ├── ai-extraction-stack.ts
│   │   ├── ai-rag-stack.ts
│   │   ├── ai-classification-stack.ts
│   │   ├── ai-summary-stack.ts
│   │   └── ai-email-stack.ts
│   └── package.json
│
├── lambda/                       # Funciones Lambda
│   ├── legacy/
│   │   ├── register_exam/       # Registrar exámenes
│   │   ├── generate_test_data/  # Generar datos de prueba
│   │   └── generate_pdf/        # Generar PDFs
│   ├── ai/
│   │   ├── extract_pdf/         # Extraer datos de PDFs
│   │   ├── generate_embeddings/ # Generar embeddings
│   │   ├── classify_risk/       # Clasificar riesgo
│   │   ├── generate_summary/    # Generar resúmenes
│   │   └── send_email/          # Enviar emails
│   └── shared/
│       └── similarity_search.py # Búsqueda RAG
│
├── database/                     # Scripts SQL
│   ├── schema.sql               # Schema completo
│   ├── seed_data.sql            # Datos iniciales
│   └── migration_*.sql          # Migraciones
│
├── prompts/                      # Prompts para Bedrock
│   ├── extraction.txt           # Extracción de datos
│   ├── extraction_v1.txt        # Versión 1 (iteración)
│   ├── extraction_v2.txt        # Versión 2 (iteración)
│   ├── extraction_v3.txt        # Versión 3 (iteración)
│   ├── classification.txt       # Clasificación de riesgo
│   ├── classification_v*.txt    # Versiones iterativas
│   ├── summary.txt              # Resúmenes ejecutivos
│   ├── email_high.txt           # Email riesgo alto
│   ├── email_medium.txt         # Email riesgo medio
│   ├── email_low.txt            # Email riesgo bajo
│   └── email_v*/*.txt           # Versiones iterativas
│
├── sample_data/                  # Datos de ejemplo
│   ├── informe_bajo_riesgo.pdf
│   ├── informe_medio_riesgo.pdf
│   ├── informe_alto_riesgo.pdf
│   └── generate_sample_pdfs.py
│
├── scripts/                      # Scripts de utilidad
│   ├── cleanup.sh               # Limpiar recursos
│   └── upload_sample_pdf.sh     # Subir PDFs de prueba
│
├── exercises/                    # Ejercicios prácticos
│   └── EXPERIMENTS.md           # Guía de experimentación
│
├── README.md                     # Este archivo
├── PARTICIPANT_GUIDE.md         # Guía para participantes
└── INSTRUCTOR_GUIDE.md          # Guía para instructor
```

## 🎯 Flujo de Trabajo

### 1. Sistema Legacy (Punto de Partida)

```bash
# Registrar un examen médico
curl -X POST https://<api-gateway-url>/examenes \
  -H "Content-Type: application/json" \
  -d '{
    "trabajador_id": 1,
    "contratista_id": 1,
    "tipo_examen": "Examen Periódico",
    "presion_arterial": "120/80",
    "peso": 75.0,
    "altura": 1.75
  }'

# Generar PDF del informe
curl -X POST https://<api-gateway-url>/examenes/generar-pdf \
  -d '{"informe_id": 1}'
```

### 2. Extracción con IA (Día 1)

```bash
# Subir PDF externo a S3
aws s3 cp sample_data/informe_alto_riesgo.pdf \
  s3://<bucket-name>/external-reports/

# La Lambda se ejecuta automáticamente (trigger S3)
# Verifica logs en CloudWatch
```

### 3. RAG con Embeddings (Día 2)

```bash
# Generar embeddings de informes existentes
aws lambda invoke \
  --function-name generate-embeddings \
  --payload '{"informe_id": 1}' \
  response.json
```

### 4. Clasificación de Riesgo (Día 2)

```bash
# Clasificar informe usando RAG
aws lambda invoke \
  --function-name classify-risk \
  --payload '{"informe_id": 1}' \
  response.json
```

### 5. Generación de Resumen (Día 2)

```bash
# Generar resumen ejecutivo
aws lambda invoke \
  --function-name generate-summary \
  --payload '{"informe_id": 1}' \
  response.json
```

### 6. Envío de Email (Día 2)

```bash
# Enviar email personalizado
aws lambda invoke \
  --function-name send-email \
  --payload '{"informe_id": 1}' \
  response.json
```

## 🔧 Servicios AWS Utilizados

| Servicio | Propósito |
|----------|-----------|
| **Amazon Bedrock** | LLM para extracción, clasificación, resúmenes y emails |
| **Amazon Nova Pro** | Modelo de lenguaje principal |
| **Amazon Titan Embeddings v2** | Generación de embeddings vectoriales |
| **Amazon Textract** | OCR para extracción de texto de PDFs |
| **Aurora Serverless v2** | Base de datos PostgreSQL con pgvector |
| **Lambda** | Funciones serverless para procesamiento |
| **S3** | Almacenamiento de PDFs |
| **API Gateway** | API REST para sistema legacy |
| **SES** | Envío de emails |
| **CloudWatch** | Logs y monitoreo |
| **Secrets Manager** | Credenciales de base de datos |
| **IAM** | Permisos y roles |

## 🧪 Experimentación con Prompts

Los participantes pueden experimentar modificando los prompts en la carpeta `prompts/`:

### Ejercicio 1: Temperatura

```python
# En prompts/extraction.txt, modificar:
# temperature: 0.1  →  temperature: 0.5

# Re-desplegar
cd cdk
cdk deploy AIExtractionStack

# Comparar resultados
```

### Ejercicio 2: Few-Shot Learning

```python
# En prompts/classification.txt, agregar más ejemplos
# Observar mejora en precisión de clasificación
```

### Ejercicio 3: Tono de Emails

```python
# En prompts/email_high.txt, cambiar:
# "tono urgente" → "tono profesional pero tranquilizador"

# Re-desplegar y comparar emails generados
```

Ver `exercises/EXPERIMENTS.md` para más ejercicios prácticos.

## 📊 Conceptos de IA Generativa Demostrados

### 1. Prompt Engineering
- Instrucciones claras y específicas
- Few-shot learning con ejemplos
- Control de temperatura y tokens
- Iteración y mejora de prompts

### 2. RAG (Retrieval-Augmented Generation)
- Embeddings vectoriales con Titan
- Búsqueda por similitud con pgvector
- Contexto histórico para mejores respuestas
- Reducción de alucinaciones

### 3. Modelos de Lenguaje (LLMs)
- Amazon Nova Pro para tareas complejas
- Parámetros: temperature, max_tokens, top_p
- Estructuración de salidas (JSON)
- Personalización según contexto

### 4. Casos de Uso Reales
- Extracción de datos no estructurados
- Clasificación con contexto
- Generación de contenido personalizado
- Automatización de flujos de trabajo

## 🐛 Troubleshooting

### Error: "Model access denied"
```bash
# Solución: Los modelos se habilitan automáticamente en la primera invocación
# Si persiste el error, verifica permisos IAM para Bedrock
```

### Error: "Database connection failed"
```bash
# Verificar security group de Aurora
# Verificar que Lambda está en la misma VPC
```

### Error: "Email not verified"
```bash
# Verificar email en SES
aws ses verify-email-identity --email-address tu-email@ejemplo.com
```

### Error: "S3 bucket already exists"
```bash
# Cambiar prefijo único en cdk/bin/app.ts
# Cada participante debe usar su propio prefijo
```

## 🧹 Limpieza de Recursos

```bash
# Eliminar todos los stacks
cd cdk
cdk destroy --all

# O usar script de limpieza
bash scripts/cleanup.sh
```

**Importante:** Aurora Serverless v2 está configurado con `removalPolicy: DESTROY` para facilitar la limpieza en la demo. En producción, usa `RETAIN` o `SNAPSHOT`.

## 📖 Documentación Adicional

- **[PARTICIPANT_GUIDE.md](PARTICIPANT_GUIDE.md)** - Guía paso a paso para participantes
- **[INSTRUCTOR_GUIDE.md](INSTRUCTOR_GUIDE.md)** - Guía detallada para instructor
- **[exercises/EXPERIMENTS.md](exercises/EXPERIMENTS.md)** - Ejercicios prácticos
- **[prompts/ITERATION_NOTES.md](prompts/ITERATION_NOTES.md)** - Notas sobre iteración de prompts

## 🎓 Objetivos de Aprendizaje

Al completar esta demo, los participantes habrán aprendido a:

1. ✅ Desplegar infraestructura serverless con AWS CDK
2. ✅ Integrar Amazon Bedrock en aplicaciones reales
3. ✅ Implementar RAG con embeddings vectoriales
4. ✅ Aplicar técnicas de prompt engineering
5. ✅ Usar Amazon Textract para OCR
6. ✅ Implementar clasificación con few-shot learning
7. ✅ Generar contenido personalizado con LLMs
8. ✅ Experimentar con parámetros de modelos
9. ✅ Iterar y mejorar prompts
10. ✅ Construir flujos de trabajo de IA end-to-end

## 🤝 Contribuciones

Este es un proyecto de demo educativa. Para sugerencias o mejoras, contacta al instructor.

## 📄 Licencia

Este proyecto es material educativo para workshops de AWS.

## 🔗 Enlaces Útiles

- [Amazon Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/)
- [Amazon Textract Documentation](https://docs.aws.amazon.com/textract/)
- [pgvector Documentation](https://github.com/pgvector/pgvector)
- [Prompt Engineering Guide](https://www.promptingguide.ai/)

---

**¿Listo para empezar?** Sigue la [Guía para Participantes](PARTICIPANT_GUIDE.md) para comenzar con la demo.
