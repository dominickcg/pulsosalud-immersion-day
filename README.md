# 🏥 Medical Reports Automation Workshop

Workshop completo para automatizar el **envío de informes médicos** usando **Amazon Bedrock** y técnicas de IA Generativa.

## 🎯 Descripción

Este workshop de 3h 15min (dividido en 2 días) enseña cómo usar Amazon Bedrock para optimizar el proceso de envío de informes médicos ocupacionales.

### El Problema de Negocio

Una empresa de salud ocupacional procesa **500 informes médicos por mes** para empresas contratistas. Actualmente:

- **125-208 horas/mes** de trabajo manual de médicos
- **20-30 minutos por informe** para clasificar riesgo y crear resumen
- **Inconsistencias** en criterios de clasificación
- **Retrasos** en envío de informes críticos
- **Costo operativo**: $6,250-10,400/mes en tiempo médico

### La Solución con IA

Este workshop enseña cómo construir un sistema que:

1. **Clasifica automáticamente** el nivel de riesgo (BAJO/MEDIO/ALTO) usando few-shot learning
2. **Genera resúmenes ejecutivos** de 100-150 palabras para gerentes
3. **Reduce el tiempo** de 20-30 min a **2 minutos por informe**
4. **Ahorra 87-92%** del tiempo de procesamiento
5. **Costo optimizado**: $800/mes vs $6,250-10,400/mes

### Lo que Aprenderás

**Día 1: Fundamentos de IA Generativa**
- Clasificar riesgos automáticamente usando **few-shot learning**
- Generar resúmenes ejecutivos con **Amazon Bedrock Nova Pro**
- Implementar **RAG simple** con búsqueda SQL para contexto histórico
- Experimentar con **temperature** y **maxTokens**
- Calcular **ROI** de soluciones de IA

**Día 2: Capacidades Avanzadas**
- Personalizar emails según nivel de riesgo
- Implementar **RAG avanzado** con embeddings vectoriales
- Integrar PDFs externos usando **Amazon Textract**
- Orquestar flujos complejos de IA

## 🏗️ Arquitectura

### Día 1: Clasificación y Resúmenes con IA

```
┌─────────────────────────────────────────────────────────────────┐
│                    DATOS LEGACY (Aurora)                         │
│  ┌──────────────────────────────────────────────────────┐       │
│  │  • 5 trabajadores con historial médico              │       │
│  │  • 3 contratistas (empresas clientes)               │       │
│  │  • 10 informes médicos de ejemplo                   │       │
│  │  • Datos: presión arterial, peso, altura, etc.      │       │
│  └────────────────────┬─────────────────────────────────┘       │
└─────────────────────────┼───────────────────────────────────────┘
                          │
                          │ GET /informes
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      APP WEB (S3 + CloudFront)                   │
│  ┌──────────────────────────────────────────────────────┐       │
│  │  • Lista de informes médicos                         │       │
│  │  • Botón "Clasificar Riesgo"                         │       │
│  │  │  • Botón "Generar Resumen"                         │       │
│  └──────────────────────────────────────────────────────┘       │
└─────────────────────────┬───────────────────────────────────────┘
                          │
        ┌─────────────────┴─────────────────┐
        │                                   │
        │ POST /classify                    │ POST /summary
        ▼                                   ▼
┌──────────────────────┐          ┌──────────────────────┐
│  Lambda: Classify    │          │  Lambda: Summary     │
│  ┌────────────────┐  │          │  ┌────────────────┐  │
│  │ 1. RAG Simple  │  │          │  │ 1. RAG Simple  │  │
│  │    (SQL query) │  │          │  │    (SQL query) │  │
│  │ 2. Few-Shot    │  │          │  │ 2. Prompt con  │  │
│  │    Learning    │  │          │  │    contexto    │  │
│  │ 3. Bedrock     │  │          │  │ 3. Bedrock     │  │
│  │    Nova Pro    │  │          │  │    Nova Pro    │  │
│  │    (temp 0.1)  │  │          │  │    (temp 0.5)  │  │
│  └────────────────┘  │          │  └────────────────┘  │
└──────────────────────┘          └──────────────────────┘
```

### Día 2: Capacidades Avanzadas

```
┌─────────────────────────────────────────────────────────────────┐
│                    CAPACIDADES ADICIONALES                       │
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │  Lambda: Email   │  │  Lambda: RAG     │  │ Lambda: PDF  │  │
│  │  • Personalizar  │  │  • Embeddings    │  │ • Textract   │  │
│  │  • Amazon SES    │  │  • pgvector      │  │ • Bedrock    │  │
│  └──────────────────┘  └──────────────────┘  └──────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

## 🚀 Setup Rápido

### Para Participantes del Workshop

**⚠️ IMPORTANTE:** El instructor ya desplegó tu infraestructura base antes del workshop. Solo necesitas desplegar los AI Stacks.

#### 1. Abrir AWS CloudShell

Abre AWS CloudShell en la consola AWS (región us-east-2)

#### 2. Clonar Repositorio

```bash
git clone <repository-url>
cd medical-reports-workshop/cdk
npm install
```

#### 3. Desplegar AI Stacks del Día 1 (3-5 minutos)

```bash
# Reemplaza participant-X con tu prefijo asignado
npx cdk deploy participant-X-AIClassificationStack participant-X-AISummaryStack --require-approval never
```

#### 4. Obtener URL de tu App Web

```bash
aws cloudformation describe-stacks \
  --stack-name participant-X-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`WebsiteURL`].OutputValue' \
  --output text
```

#### 5. Abrir App Web y Comenzar

Abre la URL en tu navegador y comienza con el Módulo 1.

---

### Para Instructores

#### Preparación Pre-Workshop (25-35 minutos por participante)

**1. Desplegar VPC Compartida (una vez):**

```powershell
cd cdk
$env:AWS_PROFILE = "workshop-profile"
npx cdk deploy SharedNetworkStack --require-approval never
```

**2. Desplegar Infraestructura Legacy (por cada participante):**

```powershell
# Usar script automatizado
.\scripts\instructor-deploy-legacy.ps1 -ParticipantName "participant-1"

# O manualmente:
npx cdk deploy participant-1-MedicalReportsLegacyStack --require-approval never
```

Esto despliega:
- Aurora Serverless v2 con datos de ejemplo
- S3 bucket para App Web
- API Gateway con endpoint /informes
- App Web estática

**3. Verificar Despliegue:**

```powershell
# Verificar que Aurora tiene datos
aws rds-data execute-statement \
  --resource-arn <cluster-arn> \
  --secret-arn <secret-arn> \
  --database medical_reports \
  --sql "SELECT COUNT(*) FROM informes_medicos"

# Verificar que App Web es accesible
curl <website-url>
```

Ver [INSTRUCTOR_GUIDE.md](INSTRUCTOR_GUIDE.md) para detalles completos.

## 📚 Estructura del Proyecto

```
medical-reports-workshop/
├── cdk/                          # Infraestructura AWS CDK
│   ├── bin/
│   │   └── app.ts               # Punto de entrada CDK
│   ├── lib/
│   │   ├── shared-network-stack.ts      # VPC compartida (pre-desplegado)
│   │   ├── legacy-stack.ts               # 🎯 Aurora + App Web (pre-desplegado)
│   │   ├── ai-classification-stack.ts    # 🎯 DÍA 1: Clasificación de riesgo
│   │   ├── ai-summary-stack.ts           # 🎯 DÍA 1: Resúmenes ejecutivos
│   │   ├── ai-email-stack.ts            # DÍA 2: Emails personalizados
│   │   ├── ai-rag-stack.ts              # DÍA 2: RAG con embeddings
│   │   └── ai-extraction-stack.ts        # DÍA 2: Textract + PDFs
│   └── package.json
│
├── lambda/                       # Funciones Lambda
│   ├── ai/
│   │   ├── classify_risk/               # 🎯 DÍA 1: Clasificación
│   │   ├── generate_summary/            # 🎯 DÍA 1: Resúmenes
│   │   ├── send_email/                  # DÍA 2: Emails
│   │   ├── generate_embeddings/         # DÍA 2: Embeddings
│   │   └── extract_pdf/                 # DÍA 2: Textract + Bedrock
│   ├── legacy/
│   │   └── list_informes/               # API para App Web
│   └── custom-resources/                # Inicialización de DB
│
├── prompts/                      # Prompts para Bedrock
│   ├── classification.txt               # 🎯 DÍA 1: Few-shot learning
│   ├── summary.txt                      # 🎯 DÍA 1: Resúmenes ejecutivos
│   ├── email_high.txt                   # DÍA 2: Email riesgo alto
│   ├── email_medium.txt                 # DÍA 2: Email riesgo medio
│   └── email_low.txt                    # DÍA 2: Email riesgo bajo
│
├── frontend/                     # App Web (pre-desplegada)
│   ├── index.html                       # Interfaz principal
│   ├── app.js                           # Lógica de clasificación/resúmenes
│   └── styles.css                       # Estilos
│
├── database/                     # Scripts SQL
│   ├── schema.sql               # Schema completo
│   └── seed_data.sql            # Datos de ejemplo
│
├── scripts/                      # Scripts de despliegue
│   ├── instructor-deploy-network.ps1    # Pre-workshop: VPC
│   ├── instructor-deploy-legacy.ps1     # Pre-workshop: Aurora + App
│   └── participant-deploy-day1.ps1      # Workshop: AI Stacks
│
├── sample_data/                  # PDFs de ejemplo (DÍA 2)
│
├── README.md                     # Este archivo
├── PARTICIPANT_GUIDE.md         # Guía detallada para participantes
└── INSTRUCTOR_GUIDE.md          # Guía detallada para instructor
```

### Leyenda
- 🎯 **DÍA 1:** Archivos que se usan en la primera sesión
- **DÍA 2:** Archivos que se usan en la segunda sesión
- **Pre-desplegado:** Infraestructura que el instructor despliega antes del workshop

## 🔄 Flujo del Workshop

### Preparación (Instructor - Antes del workshop)

1. **Desplegar infraestructura base** para todos los participantes:
   - VPC compartida
   - Aurora Serverless v2 con datos de ejemplo
   - S3 buckets individuales
   - App Web por participante

### Día 1: Clasificación y Resúmenes (75 minutos)

#### Setup (5 min)
```bash
# Participantes despliegan AI Stacks en CloudShell
npx cdk deploy participant-X-AIClassificationStack participant-X-AISummaryStack
```

#### Módulo 1: Clasificación de Riesgo (30 min)

**Usando App Web:**
1. Abrir URL de App Web
2. Ver lista de informes médicos
3. Seleccionar un informe
4. Hacer clic en "Clasificar Riesgo"
5. Ver resultado: BAJO/MEDIO/ALTO con justificación

**Usando AWS CLI:**
```bash
# Invocar Lambda directamente
aws lambda invoke \
  --function-name participant-X-classify-risk \
  --payload '{"informe_id": 1}' \
  response.json

# Ver resultado
cat response.json
```

**Conceptos aprendidos:**
- Few-shot learning con 3 ejemplos
- RAG simple con búsqueda SQL
- Temperature 0.1 para precisión

#### Módulo 2: Resúmenes Ejecutivos (30 min)

**Usando App Web:**
1. Seleccionar un informe clasificado
2. Hacer clic en "Generar Resumen"
3. Ver resumen de 100-150 palabras

**Usando AWS CLI:**
```bash
# Invocar Lambda directamente
aws lambda invoke \
  --function-name participant-X-generate-summary \
  --payload '{"informe_id": 1}' \
  response.json
```

**Conceptos aprendidos:**
- Temperature 0.5 para balance creatividad/precisión
- maxTokens 300 para limitar longitud
- RAG para contexto histórico

#### Checkpoint (10 min)

**Calcular ROI:**
- Proceso manual: 20-30 min/informe
- Proceso automatizado: 2 min/informe
- Ahorro: 87-92% del tiempo
- Costo: $800/mes vs $6,250-10,400/mes

### Día 2: Capacidades Avanzadas (2 horas)

#### Módulo 3: Emails Personalizados (30 min)
```bash
aws lambda invoke \
  --function-name participant-X-send-email \
  --payload '{"informe_id": 1}' \
  response.json
```

#### Módulo 4: RAG Avanzado con Embeddings (30 min)
```bash
# Generar embeddings
aws lambda invoke \
  --function-name participant-X-generate-embeddings \
  --payload '{"informe_id": 1}' \
  response.json
```

#### Módulo 5: Integración de PDFs con Textract (30 min)
```bash
# Subir PDF externo
aws s3 cp sample_data/informe_alto_riesgo.pdf \
  s3://participant-X-pdfs-bucket/external-reports/
```

#### Módulo 6: Experimentación Libre (30 min)
- Modificar prompts
- Experimentar con parámetros
- Probar casos edge

## 🔧 Servicios AWS Utilizados

### Día 1
| Servicio | Propósito |
|----------|-----------|
| **Amazon Bedrock** | LLM para clasificación y resúmenes |
| **Amazon Nova Pro** | Modelo de lenguaje principal |
| **Aurora Serverless v2** | Base de datos con datos legacy |
| **Lambda** | Funciones serverless para IA |
| **S3** | Hosting de App Web y almacenamiento |
| **API Gateway** | APIs REST |
| **CloudWatch** | Logs y monitoreo |
| **AWS CDK** | Infraestructura como código |

### Día 2
| Servicio | Propósito |
|----------|-----------|
| **Amazon Textract** | OCR para extracción de PDFs |
| **Amazon Titan Embeddings v2** | Generación de embeddings vectoriales |
| **pgvector** | Búsqueda vectorial avanzada |
| **Amazon SES** | Envío de emails |

## 💰 Valor de Negocio y ROI

### Métricas de Impacto (Día 1)

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| **Tiempo por informe** | 20-30 min | 2 min | 87-92% reducción |
| **Horas/mes (500 informes)** | 125-208 horas | 14.6 horas | 93% reducción |
| **Costo operativo/mes** | $6,250-10,400 | $800 | 87-92% ahorro |
| **Consistencia** | Variable | 100% | Estandarización |
| **Identificación de riesgo** | Horas | Inmediata | Tiempo real |

### Cálculo de ROI Detallado

```
Proceso Manual (ANTES):
• 500 informes/mes × 20-30 min = 125-208 horas/mes
• 125-208 horas × $50/hora médico = $6,250-10,400/mes

Proceso Automatizado (DESPUÉS):
• Clasificación automática: 500 × 30 seg = 4.2 horas
• Generación de resúmenes: 500 × 15 seg = 2.1 horas
• Revisión médica (solo ALTO riesgo): 100 × 5 min = 8.3 horas
• Total: 14.6 horas × $50/hora = $730/mes
• + Costos AWS: ~$70/mes
• Total: $800/mes

Ahorro: $5,450-9,600/mes ($65,400-115,200/año)
```

### Beneficios Adicionales

- ✅ Identificación inmediata de casos críticos (ALTO riesgo)
- ✅ Resúmenes profesionales y estandarizados
- ✅ Tendencias históricas automáticas con RAG
- ✅ Reducción de errores humanos
- ✅ Escalabilidad sin contratar más médicos
- ✅ Mejor experiencia para clientes (respuesta rápida)

## 🧪 Experimentación con Prompts

Los participantes pueden experimentar modificando los prompts en la carpeta `prompts/`:

### Ejercicio 1: Temperatura

```bash
# Modificar prompts/classification.txt
# Cambiar temperature de 0.1 a 0.3
# Observar cómo afecta la consistencia de clasificación

# Re-desplegar
cd cdk
npx cdk deploy participant-X-AIClassificationStack
```

### Ejercicio 2: Few-Shot Learning

```bash
# En prompts/classification.txt, agregar un 4to ejemplo
# Observar si mejora la precisión de clasificación
```

### Ejercicio 3: Longitud de Resúmenes

```bash
# En prompts/summary.txt, cambiar:
# "máximo 150 palabras" → "máximo 100 palabras"
# Observar cómo cambia el nivel de detalle
```

Ver [PARTICIPANT_GUIDE.md](PARTICIPANT_GUIDE.md) para más ejercicios prácticos.

## 🧠 Conceptos de IA Generativa Demostrados

### Día 1: Fundamentos

#### 1. Few-Shot Learning
- Enseñar al modelo con solo 3 ejemplos
- Clasificación precisa sin entrenamiento
- Aplicable a cualquier dominio

#### 2. RAG Simple
- Búsqueda SQL para contexto histórico
- Agregar información relevante al prompt
- Mejora la precisión de respuestas

#### 3. Temperature Control
- **0.1:** Para clasificación (precisión)
- **0.5:** Para resúmenes (balance)
- **0.7-1.0:** Para creatividad (no usado en Día 1)

#### 4. Token Management
- **maxTokens 1000:** Para justificaciones detalladas
- **maxTokens 300:** Para resúmenes concisos
- Control de costos y longitud

#### 5. Prompt Engineering
- Instrucciones claras y específicas
- Formato de salida estructurado (JSON)
- Ejemplos concretos en el prompt

### Día 2: Capacidades Avanzadas

#### 6. RAG con Embeddings
- Embeddings vectoriales con Titan
- Búsqueda por similitud semántica con pgvector
- Contexto más relevante que búsqueda SQL

#### 7. Personalización
- Contenido adaptado al nivel de riesgo
- Tono y urgencia según contexto
- Emails personalizados por contratista

#### 8. OCR + IA
- Textract para extraer texto de PDFs
- Bedrock para estructurar información
- Pipeline completo de procesamiento

#### 9. Casos de Uso Reales
- Clasificación automática con contexto
- Generación de contenido profesional
- Automatización de flujos de trabajo
- Reducción de errores humanos

## 🐛 Troubleshooting

### Error: "Lambda not found"
```bash
# Verificar que usaste el prefijo correcto
aws lambda list-functions --query 'Functions[?contains(FunctionName, `participant-X`)]'

# Verificar que el despliegue fue exitoso
aws cloudformation describe-stacks --stack-name participant-X-AIClassificationStack
```

### Error: "Access denied to Aurora"
```bash
# Verificar que Lambda tiene permisos RDS Data API
# Verificar que Lambda está en la VPC correcta
# Verificar security group de Aurora permite conexiones desde Lambda
```

### Error: "Bedrock access denied"
```bash
# Verificar que tienes acceso a Amazon Bedrock en us-east-2
# Verificar que el modelo Nova Pro está habilitado
aws bedrock list-foundation-models --region us-east-2 --query 'modelSummaries[?contains(modelId, `nova-pro`)]'
```

### Error: "App Web no carga"
```bash
# Verificar URL del stack
aws cloudformation describe-stacks \
  --stack-name participant-X-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`WebsiteURL`].OutputValue'

# Verificar que S3 bucket tiene archivos
aws s3 ls s3://participant-X-website-bucket/
```

### Los logs tardan en aparecer
```bash
# Los logs de CloudWatch pueden tardar 1-2 minutos en aparecer
# Espera un momento y vuelve a verificar
```

## 🔄 Cambio de Enfoque: Por qué el Nuevo Día 1

### Enfoque Anterior vs Nuevo

| Aspecto | Enfoque Anterior | Nuevo Enfoque (Día 1) |
|---------|------------------|----------------------|
| **Problema** | Extracción de PDFs | Optimización del envío de informes |
| **Tecnología principal** | Textract + Bedrock | Bedrock (clasificación + resúmenes) |
| **Datos** | PDFs externos | Datos legacy en Aurora |
| **Valor inmediato** | Procesamiento de documentos | ROI: 87-92% ahorro de tiempo |
| **Tiempo de despliegue** | 25-35 minutos | 3-5 minutos |
| **Complejidad** | Alta (múltiples servicios) | Media (enfoque en IA) |
| **Curva de aprendizaje** | Empinada | Gradual |

### Beneficios del Nuevo Enfoque

1. **Valor de negocio inmediato:** Los participantes ven ROI desde el primer módulo
2. **Menos tiempo de setup:** Más tiempo para aprender conceptos de IA
3. **Enfoque en IA:** Few-shot learning, RAG, temperature, maxTokens
4. **Experiencia visual:** App web para interactuar con el sistema
5. **Progresión lógica:** Día 1 (conceptos base) → Día 2 (capacidades avanzadas)

### Feedback Incorporado

- ✅ "Quiero ver valor de negocio desde el inicio"
- ✅ "El despliegue toma demasiado tiempo"
- ✅ "Necesito entender mejor los parámetros de Bedrock"
- ✅ "Quiero una interfaz visual para experimentar"
- ✅ "El ROI debe ser claro y calculable"

---

## 🧹 Limpieza de Recursos

### Para Participantes

```bash
# Eliminar solo tus AI Stacks
cd cdk
npx cdk destroy participant-X-AIClassificationStack participant-X-AISummaryStack
```

### Para Instructores

```bash
# Eliminar todos los stacks de un participante
npx cdk destroy participant-X-AIClassificationStack participant-X-AISummaryStack participant-X-MedicalReportsLegacyStack

# Eliminar VPC compartida (al final del workshop)
npx cdk destroy SharedNetworkStack
```

**Importante:** Aurora Serverless v2 está configurado con `removalPolicy: DESTROY` para facilitar la limpieza en el workshop. En producción, usa `RETAIN` o `SNAPSHOT`.

## 📖 Documentación Adicional

- **[PARTICIPANT_GUIDE.md](PARTICIPANT_GUIDE.md)** - Guía paso a paso para participantes del workshop
- **[INSTRUCTOR_GUIDE.md](INSTRUCTOR_GUIDE.md)** - Guía detallada para instructor con scripts y timing
- **[QUICK_START.md](QUICK_START.md)** - Inicio rápido para configuración
- **[SETUP.md](SETUP.md)** - Instrucciones detalladas de setup

## 📊 Estructura del Workshop

### Día 1: Clasificación y Resúmenes (75 minutos)
- **Setup:** 5 minutos
- **Módulo 1:** Clasificación de riesgo con few-shot learning (30 min)
- **Módulo 2:** Generación de resúmenes ejecutivos (30 min)
- **Checkpoint:** ROI y reflexión (10 min)

### Día 2: Capacidades Avanzadas (2 horas)
- **Módulo 3:** Emails personalizados (30 min)
- **Módulo 4:** RAG avanzado con embeddings (30 min)
- **Módulo 5:** Integración de PDFs con Textract (30 min)
- **Módulo 6:** Experimentación libre y Q&A (30 min)

## 🎓 Objetivos de Aprendizaje

### Día 1: Fundamentos de IA Generativa

Al completar el Día 1, los participantes habrán aprendido a:

1. ✅ **Calcular ROI** de soluciones de IA (87-92% ahorro de tiempo)
2. ✅ **Implementar few-shot learning** con solo 3 ejemplos
3. ✅ **Usar RAG simple** con búsqueda SQL para contexto histórico
4. ✅ **Controlar temperature** según caso de uso (0.1 vs 0.5)
5. ✅ **Gestionar tokens** para controlar longitud y costos
6. ✅ **Diseñar prompts efectivos** con instrucciones claras
7. ✅ **Integrar Amazon Bedrock** en aplicaciones reales
8. ✅ **Desplegar con AWS CDK** en 3-5 minutos
9. ✅ **Usar App Web** para interactuar con IA
10. ✅ **Identificar casos de uso** de IA en su organización

### Día 2: Capacidades Avanzadas

Al completar el Día 2, los participantes habrán aprendido a:

11. ✅ **Implementar RAG avanzado** con embeddings vectoriales
12. ✅ **Usar Amazon Textract** para OCR de PDFs
13. ✅ **Personalizar contenido** según contexto
14. ✅ **Enviar emails automáticos** con Amazon SES
15. ✅ **Experimentar con parámetros** de modelos
16. ✅ **Iterar y mejorar prompts** basado en resultados
17. ✅ **Construir flujos de trabajo** de IA end-to-end
18. ✅ **Orquestar múltiples servicios** de AWS
19. ✅ **Monitorear y debuggear** aplicaciones de IA
20. ✅ **Escalar soluciones** de IA en producción

## 🤝 Contribuciones

Este es un proyecto educativo para workshops de AWS. Para sugerencias o mejoras, contacta al instructor.

## 📄 Licencia

Este proyecto es material educativo para workshops de AWS.

## 🔗 Enlaces Útiles

- [Amazon Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Amazon Bedrock User Guide](https://docs.aws.amazon.com/bedrock/latest/userguide/)
- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/)
- [Amazon Nova Models](https://aws.amazon.com/bedrock/nova/)
- [Prompt Engineering Guide](https://www.promptingguide.ai/)
- [RAG Best Practices](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base.html)

---

**¿Listo para empezar?** 

- **Participantes:** Sigue la [Guía para Participantes](PARTICIPANT_GUIDE.md)
- **Instructores:** Revisa la [Guía para Instructores](INSTRUCTOR_GUIDE.md)
