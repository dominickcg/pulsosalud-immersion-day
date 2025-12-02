# 🎓 Guía para Participantes - Medical Reports Automation Workshop

Bienvenido al workshop de **Automatización de Informes Médicos con AWS y Amazon Bedrock**. Esta guía te llevará paso a paso a través de la implementación de un sistema que optimiza el envío de informes médicos a clientes usando IA Generativa.

## 🏥 El Problema de Negocio

Una empresa de salud ocupacional realiza exámenes médicos a trabajadores de empresas contratistas (mineras, constructoras, etc.). 

**Situación Actual:**
- Realizan 500+ exámenes médicos por mes
- Deben enviar informes a las empresas clientes
- Cada informe requiere:
  - Revisión manual por médico
  - Clasificación de nivel de riesgo
  - Creación de resumen ejecutivo
  - Redacción de email personalizado

**Objetivo del Workshop:**
Automatizar este proceso usando Amazon Bedrock para:
1. ✅ Clasificar automáticamente el nivel de riesgo (BAJO/MEDIO/ALTO)
2. ✅ Generar resúmenes ejecutivos personalizados
3. ✅ Crear emails con el tono adecuado según la urgencia
4. ✅ Reducir tiempo de procesamiento de 20-30 min a 2 min por informe

## 📅 Estructura del Workshop

**Duración Total:** 3 horas 15 minutos (dividido en 2 días)

### Día 1: Clasificación y Resúmenes con IA (1h 15min)
- ⏱️ **5 min** - Setup inicial: Despliegue de AI Stacks (3-5 min de espera)
- ⏱️ **30 min** - Módulo 1: Clasificación automática de riesgo con IA
- ⏱️ **30 min** - Módulo 2: Generación de resúmenes ejecutivos
- ⏱️ **10 min** - Checkpoint Día 1

### Día 2: Capacidades Avanzadas (2h)
- ⏱️ **30 min** - Módulo 3: Emails personalizados por nivel de riesgo
- ⏱️ **30 min** - Módulo 4: RAG con embeddings vectoriales (contexto histórico)
- ⏱️ **30 min** - Módulo 5: Integración de PDFs externos (clínicas externas)
- ⏱️ **30 min** - Experimentación libre y Q&A

---

## 🚀 Setup Inicial (5-8 minutos)

### Prerequisitos

Solo necesitas:

- ✅ **Acceso a AWS Console** (proporcionado por el instructor)
- ✅ **Navegador web** (Chrome, Firefox, Edge, Safari)

**¡Eso es todo!** Usaremos **AWS CloudShell**, que ya tiene todo pre-instalado:
- ✅ AWS CLI configurado automáticamente
- ✅ Node.js y npm
- ✅ Python 3
- ✅ Git
- ✅ Editor de texto (nano, vim)

### Información Proporcionada por el Instructor

**Ejemplo de información que recibirás:**
- Usuario AWS: `workshop-user-1`
- PARTICIPANT_PREFIX: `participant-1`
- Email del instructor: `instructor@example.com` ← **Este es el email del instructor, NO tu email personal**

**⚠️ IMPORTANTE:** El instructor ya desplegó la infraestructura base (VPC, Aurora, S3, App Web) antes del workshop. Tú solo desplegarás los AI Stacks (2 stacks, 3-5 minutos) durante esta sesión.

### Paso 1: Abrir AWS CloudShell

1. **Inicia sesión** en AWS Console con las credenciales proporcionadas
2. **Abre CloudShell**: 
   - Haz clic en el ícono de terminal (>_) en la barra superior derecha
   - O busca "CloudShell" en la barra de búsqueda
   - Se abrirá una terminal en tu navegador

![CloudShell está en la esquina superior derecha de la consola AWS]

**CloudShell ya tiene todo configurado:**
- ✅ AWS CLI con tus credenciales
- ✅ Node.js, npm, Python, Git
- ✅ 1 GB de almacenamiento persistente

### Paso 2: Clonar el Repositorio

En CloudShell, ejecuta:

```bash
# Clonar repositorio
git clone <repository-url>
cd pulsosalud-immersion-day

# Verificar que estás autenticado
aws sts get-caller-identity
```

### Paso 3: Instalar Dependencias del Proyecto

```bash
# Instalar dependencias de CDK
cd cdk
npm install

# Verificar instalación (usar npx para ejecutar CDK)
npx cdk --version
```

**Nota:** Usaremos `npx cdk` en lugar de solo `cdk` para ejecutar comandos CDK desde CloudShell.

**Tiempo:** ~2-3 minutos

Mientras se instala, el instructor explicará la arquitectura del workshop.

### Paso 4: Desplegar AI Stacks del Día 1

El instructor ya desplegó:
- ✅ VPC compartida
- ✅ Aurora Serverless v2 con datos de ejemplo (10 informes médicos)
- ✅ S3 Bucket para almacenamiento
- ✅ API Gateway con endpoints
- ✅ App Web para visualizar y ejecutar acciones
- ✅ Lambdas Legacy (registro de exámenes, listado)

Tú solo necesitas desplegar los **AI Stacks del Día 1** (2 stacks):

```bash
# Navegar al directorio CDK
cd pulsosalud-immersion-day/cdk

# Desplegar los 2 AI Stacks del Día 1
# Reemplaza participant-1 con tu PARTICIPANT_PREFIX
npx cdk deploy participant-1-AIClassificationStack participant-1-AISummaryStack --require-approval never
```

**Reemplaza:**
- `participant-1` con tu PARTICIPANT_PREFIX asignado (ej: `participant-2`, `participant-3`, etc.)

**Tiempo estimado:** 3-5 minutos

Mientras esperas, el instructor explicará la arquitectura del sistema en pantalla compartida.

**Recursos que se desplegarán (Día 1):**
1. **AIClassificationStack** - Lambda classify-risk con Bedrock Nova Pro
2. **AISummaryStack** - Lambda generate-summary con Bedrock Nova Pro

**Recursos del Día 2** (se desplegarán en la segunda sesión):
- AIEmailStack - Emails personalizados
- AIRAGStack - Embeddings vectoriales avanzados
- AIExtractionStack - Integración de PDFs externos

### Paso 5: Obtener la URL de tu App Web

Una vez completado el despliegue, obtén la URL de tu app web:

```bash
# Obtener la URL de tu app web
aws cloudformation describe-stacks \
  --stack-name participant-1-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`WebsiteURL`].OutputValue' \
  --output text
```

**Reemplaza `participant-1` con tu prefijo.**

**Copia la URL** y ábrela en tu navegador.

---

**Tu App Web incluye:**
- **Lista de informes médicos** - 10 informes de ejemplo pre-cargados
- **Vista de detalle** - Presión arterial, IMC, antecedentes, etc.
- **Botón "Clasificar con IA"** - Llama a tu Lambda classify-risk
- **Botón "Generar Resumen"** - Llama a tu Lambda generate-summary
- **Estadísticas en tiempo real** - Contadores y distribución de riesgo

**Deberías ver:**
- Una tabla con 10 informes médicos
- Cada informe tiene datos completos (nombre, presión, IMC, etc.)
- Botones de acción en cada fila
- Panel de estadísticas en la parte superior

**¡Listo!** Ya puedes empezar con el Módulo 1.

## 📚 Día 1: Optimización del Envío de Informes

**✅ Tu infraestructura ya está lista:** Si completaste el Setup Inicial, todos tus AI Stacks ya están desplegados y listos para usar.

### Módulo 1: Clasificación Automática de Riesgo (30 min)

**Objetivo:** Automatizar la clasificación de informes médicos en niveles de riesgo usando Amazon Bedrock.

#### 🎯 El Problema

**Situación Actual:**
- Un médico debe revisar CADA informe manualmente
- Debe decidir si es riesgo BAJO, MEDIO o ALTO
- Esto toma 10-15 minutos por informe
- Con 500 informes/mes = 125 horas de trabajo manual
- Riesgo de inconsistencia en criterios entre médicos

**La Solución con IA:**
- Amazon Bedrock clasifica automáticamente usando few-shot learning
- Consistencia 100% en criterios de clasificación
- Tiempo reducido a 30 segundos por informe
- Médico solo revisa casos críticos (ALTO riesgo)

**Conceptos Clave:**
```
Few-Shot Learning = Enseñar al modelo con pocos ejemplos
Bedrock Nova Pro = Modelo de lenguaje que "entiende" contexto médico
RAG = Buscar informes anteriores del mismo trabajador para contexto
```

**Flujo de Clasificación:**
```
┌─────────────┐
│ Informe     │
│ Médico      │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ 1. Buscar Informes Anteriores (RAG)    │
│    • Query SQL: últimos 3 informes      │
│    • Mismo trabajador                   │
│    • Ordenados por fecha DESC           │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ 2. Construir Prompt con Few-Shot       │
│    • Cargar ejemplos (BAJO/MEDIO/ALTO) │
│    • Agregar contexto histórico         │
│    • Agregar datos del informe actual   │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ 3. Invocar Bedrock Nova Pro            │
│    • Temperature: 0.1 (precisión)       │
│    • MaxTokens: 1000                    │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ 4. Parsear Respuesta JSON              │
│    • nivel_riesgo: BAJO/MEDIO/ALTO     │
│    • justificacion: texto explicativo   │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ 5. Guardar en Aurora                   │
│    • UPDATE informes_medicos            │
│    • SET nivel_riesgo, justificacion    │
└─────────────────────────────────────────┘
```

---

### Parte 1: Ver Datos Existentes en el Sistema Legacy (5 min)

El instructor ya cargó datos de ejemplo en tu base de datos Aurora.

#### Paso 1: Obtener endpoint de Aurora (1 min)

```bash
# Reemplaza participant-1 con tu prefijo
aws cloudformation describe-stacks \
  --stack-name participant-1-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`AuroraEndpoint`].OutputValue' \
  --output text
```

**✅ Guarda este endpoint**, lo usarás para consultas.

---

#### Paso 2: Ver informes existentes (2 min)

```bash
# Obtener ARN del cluster y secret
CLUSTER_ARN=$(aws cloudformation describe-stacks \
  --stack-name participant-1-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`ClusterArn`].OutputValue' \
  --output text)

SECRET_ARN=$(aws cloudformation describe-stacks \
  --stack-name participant-1-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`SecretArn`].OutputValue' \
  --output text)

# Ver informes en la base de datos
aws rds-data execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database medical_reports \
  --sql "SELECT id, trabajador_id, tipo_examen, presion_arterial, peso FROM informes_medicos LIMIT 5"
```

Observa que estos son informes reales que necesitan ser clasificados y enviados a clientes.

---

### Parte 2: Clasificar un Informe Automáticamente (10 min)

Ahora vamos a usar Bedrock para clasificar automáticamente el nivel de riesgo.

#### Paso 1: Invocar Lambda de Clasificación (2 min)

```bash
# Clasificar el informe ID 1
aws lambda invoke \
  --function-name participant-1-classify-risk \
  --payload '{"informe_id": 1}' \
  response.json

# Ver resultado
cat response.json
```

**✅ Deberías ver:**
```json
{
  "informe_id": 1,
  "nivel_riesgo": "ALTO",
  "justificacion": "Presión arterial 165/102 mmHg indica hipertensión severa...",
  "tiempo_procesamiento": "2.3s"
}
```

---

#### Paso 2: Ver logs en tiempo real (3 min)

```bash
# Ver logs de la Lambda
aws logs tail /aws/lambda/participant-1-classify-risk --follow
```

Busca en los logs:
- `Invoking Bedrock with inference profile` → Llamada a Bedrock
- `Few-shot examples loaded` → Ejemplos de entrenamiento
- `RAG context retrieved` → Informes anteriores del trabajador
- `Classification result` → Resultado final

**Presiona Ctrl+C para salir**

---

#### Paso 3: Verificar resultado en Aurora (2 min)

```bash
# Ver el informe clasificado
aws rds-data execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database medical_reports \
  --sql "SELECT id, nivel_riesgo, justificacion_riesgo FROM informes_medicos WHERE id = 1"
```

**✅ El informe ahora tiene:**
- `nivel_riesgo`: BAJO, MEDIO o ALTO
- `justificacion_riesgo`: Explicación detallada

---

### Parte 3: Entender Cómo Funciona (10 min)

El instructor explicará el código mientras tú sigues en tu pantalla.

#### Paso 1: Ver el Prompt de Clasificación (3 min)

```bash
# Abrir el prompt en CloudShell
cat prompts/classification.txt
```

**Observa la estructura:**

```
Eres un médico ocupacional experto...

Clasifica en uno de estos niveles:
- BAJO: Parámetros normales, apto sin restricciones
- MEDIO: Parámetros limítrofes, requiere seguimiento  
- ALTO: Parámetros alterados, requiere atención inmediata

EJEMPLOS (Few-Shot Learning):

[Ejemplo BAJO con datos específicos]
Presión: 118/75, IMC: 23.5, sin antecedentes
→ BAJO

[Ejemplo MEDIO con datos específicos]
Presión: 135/85, IMC: 27.2, colesterol elevado
→ MEDIO

[Ejemplo ALTO con datos específicos]
Presión: 155/95, IMC: 32.1, diabetes tipo 2
→ ALTO

CONTEXTO HISTÓRICO (RAG):
[Informes anteriores del trabajador]

INFORME ACTUAL:
[Datos del informe a clasificar]
```

**Lección clave:** Few-shot learning + contexto histórico = clasificación precisa

---

#### Paso 2: Ver el Código de la Lambda (4 min)

```bash
# Ver código de clasificación
cat lambda/ai/classify_risk/index.py
```

Busca estas secciones:

**1. Buscar contexto histórico (RAG):**
```python
# Buscar informes anteriores del mismo trabajador
informes_anteriores = buscar_informes_similares(trabajador_id)
```

**2. Construir prompt con ejemplos:**
```python
# Cargar ejemplos de few-shot learning
prompt = load_classification_prompt()
prompt += f"\nCONTEXTO HISTÓRICO:\n{informes_anteriores}"
prompt += f"\nINFORME ACTUAL:\n{datos_informe}"
```

**3. Invocar Bedrock:**
```python
response = bedrock_runtime.invoke_model(
    modelId='us.amazon.nova-pro-v1:0',
    body=json.dumps({
        "messages": [{"role": "user", "content": prompt}],
        "inferenceConfig": {
            "temperature": 0.1,  # Baja para precisión
            "maxTokens": 1000
        }
    })
)
```

**Lección clave:** Temperature baja (0.1) = respuestas consistentes y precisas

---

### Parte 4: Usar la App Web (5 min)

Ahora vamos a usar la interfaz visual.

#### Paso 1: Abrir tu App Web (1 min)

El instructor te proporcionó la URL de tu app web. Ábrela en tu navegador.

**Deberías ver:**
- Lista de 10 informes médicos
- Detalles de cada informe (presión arterial, IMC, etc.)
- Botón "Clasificar con IA" en cada informe
- Botón "Generar Resumen" (deshabilitado hasta clasificar)

---

#### Paso 2: Clasificar desde la App Web (2 min)

1. **Selecciona un informe** que NO esté clasificado (sin badge de riesgo)
2. **Haz clic en "Clasificar con IA"**
3. **Observa:**
   - El botón muestra "Clasificando..."
   - Después de 2-3 segundos, aparece el badge de riesgo (BAJO/MEDIO/ALTO)
   - Se muestra la justificación detallada

Detrás de escena, la app web está llamando a tu Lambda classify-risk a través de API Gateway.

---

#### Paso 3: Comparar CLI vs App Web (2 min)

**Ventajas de la App Web:**
- ✅ Visual e intuitiva
- ✅ No necesitas recordar comandos
- ✅ Ves todos los informes de un vistazo
- ✅ Feedback inmediato con badges de color

**Ventajas del CLI:**
- ✅ Automatización y scripting
- ✅ Integración con otros sistemas
- ✅ Acceso a logs detallados

**Lección:** Ambas interfaces son útiles según el caso de uso.

---

### Parte 5: Ejercicio Individual (5 min)

**Tu tarea:** Clasificar 2-3 informes más usando la app web

1. **Clasifica al menos 2 informes** usando el botón "Clasificar con IA"
2. **Observa los diferentes niveles de riesgo** (BAJO/MEDIO/ALTO)
3. **Lee las justificaciones** para entender por qué se clasificó así

**✅ Criterio de éxito:**
- Tienes al menos 3 informes clasificados
- Entiendes la diferencia entre BAJO, MEDIO y ALTO
- Los resultados tienen sentido médicamente

**❌ Si algo falla:**
- Refresca la página
- Verifica que el despliegue se completó correctamente
- Revisa los logs en CloudShell: `aws logs tail /aws/lambda/participant-1-classify-risk`
- Pide ayuda al instructor

---

### 🎓 Resumen del Módulo 1

**Lo que lograste:**
- ✅ Viste datos reales del sistema legacy
- ✅ Clasificaste informes automáticamente con Bedrock
- ✅ Entendiste few-shot learning y RAG
- ✅ Verificaste resultados en la base de datos

**Valor de negocio:**
- Tiempo: De 10-15 min → 30 segundos por informe
- Ahorro: 120+ horas/mes de trabajo médico
- Consistencia: 100% en criterios de clasificación
- Priorización: Identificación inmediata de casos críticos

**Concepto clave:** 
> Few-shot learning + RAG = Clasificación precisa sin entrenar un modelo custom

**Próximo módulo:** Generar resúmenes ejecutivos automáticamente

---

### Módulo 2: Generación de Resúmenes Ejecutivos (30 min)

**Objetivo:** Automatizar la creación de resúmenes ejecutivos para gerentes de empresas clientes.

#### 🎯 El Problema

**Situación Actual:**
- Los gerentes de empresas clientes NO leen informes médicos completos (5-10 páginas)
- Necesitan resúmenes ejecutivos de 2-3 párrafos que destaquen:
  - Hallazgos principales
  - Nivel de riesgo
  - Acciones recomendadas
  - Tendencias vs. exámenes anteriores
- Crear estos resúmenes manualmente toma 5-10 minutos por informe
- Con 500 informes/mes = 50+ horas de trabajo

**La Solución con IA:**
- Amazon Bedrock genera resúmenes automáticamente
- Incluye contexto histórico usando RAG
- Lenguaje claro y no técnico
- Tiempo reducido a 15 segundos por resumen

**Conceptos Clave:**
```
Temperature Media (0.5) = Balance entre precisión y fluidez
maxTokens = Controla la longitud del resumen
RAG = Agrega tendencias de exámenes anteriores
```

**Flujo de Generación de Resumen:**
```
┌─────────────┐
│ Informe     │
│ Clasificado │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ 1. Verificar Clasificación             │
│    • Debe tener nivel_riesgo            │
│    • Si no, retornar error              │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ 2. Buscar Informes Anteriores (RAG)    │
│    • Query SQL: últimos 2 informes      │
│    • Mismo trabajador                   │
│    • Para detectar tendencias           │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ 3. Construir Prompt para Resumen       │
│    • Cargar template summary.txt        │
│    • Agregar contexto histórico         │
│    • Agregar datos + nivel de riesgo    │
│    • Especificar audiencia (gerente)    │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ 4. Invocar Bedrock Nova Pro            │
│    • Temperature: 0.5 (balance)         │
│    • MaxTokens: 300 (~150 palabras)     │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ 5. Contar Palabras y Validar           │
│    • Verificar longitud (80-180 palabras)│
│    • Formatear respuesta                │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ 6. Guardar en Aurora                   │
│    • UPDATE informes_medicos            │
│    • SET resumen_ejecutivo              │
└─────────────────────────────────────────┘
```

---

### Parte 1: Generar un Resumen Automáticamente (10 min)

Vamos a generar un resumen ejecutivo del informe que clasificamos en el Módulo 1.

#### Paso 1: Invocar Lambda de Resumen (2 min)

```bash
# Generar resumen del informe ID 1
aws lambda invoke \
  --function-name participant-1-generate-summary \
  --payload '{"informe_id": 1}' \
  summary_response.json

# Ver resultado
cat summary_response.json
```

**✅ Deberías ver:**
```json
{
  "informe_id": 1,
  "resumen": "El trabajador Carlos Rodríguez presenta múltiples factores de riesgo que requieren atención médica inmediata. Se detecta hipertensión arterial severa (165/102 mmHg) y obesidad grado I (IMC: 32.9). Los exámenes de laboratorio revelan diabetes mellitus descompensada. Comparado con su examen anterior hace 6 meses, se observa deterioro significativo en todos los parámetros. Se recomienda restricción inmediata de actividades de alto riesgo y evaluación médica urgente.",
  "palabras": 87,
  "tiempo_procesamiento": "1.8s"
}
```

---

#### Paso 2: Ver logs en tiempo real (3 min)

```bash
# Ver logs de la Lambda
aws logs tail /aws/lambda/participant-1-generate-summary --follow
```

Busca en los logs:
- `Loading summary prompt` → Carga del prompt
- `RAG: Retrieved 2 previous reports` → Informes anteriores encontrados
- `Invoking Bedrock with temperature 0.5` → Llamada a Bedrock
- `Summary generated: 87 words` → Resumen creado

**Presiona Ctrl+C para salir**

---

#### Paso 3: Verificar resultado en Aurora (2 min)

```bash
# Ver el resumen guardado
aws rds-data execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database medical_reports \
  --sql "SELECT id, resumen_ejecutivo FROM informes_medicos WHERE id = 1"
```

**✅ El informe ahora tiene un resumen ejecutivo listo para enviar al cliente**

---

### Parte 2: Entender el Prompt de Resumen (8 min)

**El instructor explicará mientras tú sigues en tu pantalla**

#### Paso 1: Ver el Prompt (3 min)

```bash
# Abrir el prompt de resumen
cat prompts/summary.txt
```

**Observa la estructura:**

```
Genera un resumen ejecutivo del informe médico.

AUDIENCIA: Gerente de empresa (no médico)

REQUISITOS:
- Máximo 150 palabras
- Lenguaje claro, NO técnico
- Enfócate en hallazgos principales y acciones
- Incluye tendencias si hay informes anteriores

CONTEXTO HISTÓRICO (RAG):
[Informes anteriores del trabajador - si existen]

INFORME ACTUAL:
[Datos del informe]
[Nivel de riesgo: ALTO]

FORMATO:
2-3 párrafos, directo y accionable.
```

**Lección clave:** El prompt especifica la audiencia (gerente, no médico) para ajustar el lenguaje

---

#### Paso 2: Comparar con Clasificación (2 min)

**Diferencias clave entre Clasificación y Resumen:**

| Aspecto | Clasificación | Resumen |
|---------|---------------|---------|
| **Temperature** | 0.1 (preciso) | 0.5 (balanceado) |
| **maxTokens** | 1000 | 300 |
| **Objetivo** | Decisión binaria | Comunicación fluida |
| **Audiencia** | Sistema | Humano (gerente) |

**Lección:** Ajustamos parámetros según el caso de uso

---

#### Paso 3: Ver el Código (3 min)

```bash
# Ver código de generación de resumen
cat lambda/ai/generate_summary/index.py
```

**Busca estas secciones:**

**1. Buscar contexto histórico:**
```python
# Buscar informes anteriores para tendencias
informes_anteriores = buscar_informes_similares(trabajador_id, limit=2)
```

**2. Construir prompt con contexto:**
```python
prompt = load_summary_prompt()
if informes_anteriores:
    prompt += f"\nCONTEXTO HISTÓRICO:\n{format_historical_context(informes_anteriores)}"
prompt += f"\nINFORME ACTUAL:\n{datos_informe}"
prompt += f"\nNivel de riesgo: {nivel_riesgo}"
```

**3. Invocar Bedrock con temperature media:**
```python
response = bedrock_runtime.invoke_model(
    modelId='us.amazon.nova-pro-v1:0',
    body=json.dumps({
        "messages": [{"role": "user", "content": prompt}],
        "inferenceConfig": {
            "temperature": 0.5,  # Balance entre precisión y fluidez
            "maxTokens": 300     # Limita longitud del resumen
        }
    })
)
```

---

### Parte 3: Entender los Parámetros de Bedrock (7 min)

El instructor explicará los parámetros clave de Bedrock.

#### Parámetro 1: Temperature (3 min)

**¿Qué es temperature?**
- Controla la "creatividad" o "aleatoriedad" del modelo
- Rango: 0.0 (determinístico) a 1.0 (muy creativo)

**Ejemplos de uso:**

| Temperature | Caso de Uso | Resultado |
|-------------|-------------|-----------|
| **0.1** | Clasificación de riesgo | Preciso, consistente, mismo input → mismo output |
| **0.5** | Resúmenes ejecutivos | Balanceado: preciso pero con fluidez natural |
| **0.7** | Emails personalizados | Más variado, tono más natural |
| **0.9** | Brainstorming | Muy creativo, respuestas diversas |

**Lección:** Usamos temperature 0.1 para clasificación (precisión) y 0.5 para resúmenes (balance).

---

#### Parámetro 2: maxTokens (2 min)

**¿Qué es maxTokens?**
- Limita la longitud máxima de la respuesta
- 1 token ≈ 0.75 palabras en español
- 300 tokens ≈ 225 palabras

**Ejemplos de uso:**

| maxTokens | Caso de Uso | Resultado |
|-----------|-------------|-----------|
| **1000** | Clasificación con justificación | Permite explicación detallada |
| **300** | Resumen ejecutivo | Fuerza concisión (~150 palabras) |
| **500** | Email personalizado | Suficiente para email completo |

**Lección:** maxTokens no solo limita, también guía al modelo a ser más conciso.

---

#### Parámetro 3: Prompt Engineering (2 min)

**¿Qué hace un buen prompt?**
- ✅ **Contexto claro:** "Eres un médico ocupacional experto..."
- ✅ **Ejemplos (few-shot):** Muestra 2-3 ejemplos del resultado esperado
- ✅ **Formato específico:** "Responde en formato JSON: {...}"
- **Restricciones:** "Máximo 150 palabras", "Lenguaje no técnico"

**Lección:** Un prompt bien diseñado es más importante que ajustar parámetros.

---

### Parte 3.5: Experimentar con Parámetros (Opcional - 5 min)

Si tienes tiempo, experimenta con diferentes parámetros.

#### Experimento 1: Temperature Baja (0.2)

```bash
# Generar resumen con temperature baja (más determinístico)
aws lambda invoke \
  --function-name participant-1-generate-summary \
  --payload '{"informe_id": 1, "temperature": 0.2}' \
  summary_temp_low.json

# Ver resultado
cat summary_temp_low.json
```

Observa si el resumen es más técnico o más formal.

---

#### Experimento 2: Temperature Alta (0.8)

```bash
# Generar resumen con temperature alta (más creativo)
aws lambda invoke \
  --function-name participant-1-generate-summary \
  --payload '{"informe_id": 1, "temperature": 0.8}' \
  summary_temp_high.json

# Ver resultado
cat summary_temp_high.json
```

Observa si el resumen es más variado o usa lenguaje más natural.

---

#### Experimento 3: maxTokens Reducido (150)

```bash
# Generar resumen más corto
aws lambda invoke \
  --function-name participant-1-generate-summary \
  --payload '{"informe_id": 1, "maxTokens": 150}' \
  summary_short.json

# Ver resultado
cat summary_short.json
```

Observa si el resumen mantiene la información clave o pierde detalles.

---

**Lección:** Los parámetros por defecto (temperature: 0.5, maxTokens: 300) están optimizados para este caso de uso. Experimentar ayuda a entender su impacto.

---

### Parte 4: Usar la App Web para Resúmenes (5 min)

Ahora vamos a generar resúmenes desde la interfaz visual.

#### Paso 1: Generar Resumen desde la App Web (2 min)

1. **Abre tu App Web** (si la cerraste)
2. **Selecciona un informe clasificado** (con badge de riesgo)
3. **Haz clic en "Generar Resumen"**
4. **Observa:**
   - El botón muestra "Generando..."
   - Después de 1-2 segundos, aparece el resumen ejecutivo
   - Se muestra el conteo de palabras

**Nota:** Solo puedes generar resúmenes de informes ya clasificados.

---

#### Paso 2: Analizar el Resumen (2 min)

**Lee el resumen generado y verifica:**
- ✅ Lenguaje claro y no técnico (para gerentes, no médicos)
- ✅ Menciona el nivel de riesgo
- ✅ Incluye hallazgos principales
- ✅ Sugiere acciones recomendadas
- ✅ Longitud: ~100-150 palabras

Si hay informes anteriores del mismo trabajador, el resumen incluirá tendencias históricas (ej: "Comparado con su examen anterior hace 6 meses...").

---

#### Paso 3: Ejercicio Individual (1 min)

**Tu tarea:** Generar resúmenes de 2-3 informes más

1. **Genera resúmenes** de los informes que clasificaste
2. **Compara resúmenes** de diferentes niveles de riesgo
3. **Observa el tono:** ¿Es más urgente para ALTO riesgo?

**✅ Criterio de éxito:**
- Tienes al menos 3 resúmenes generados
- Los resúmenes son claros y accionables
- Entiendes cómo el nivel de riesgo afecta el contenido

---

### 🎓 Resumen del Módulo 2

**Lo que lograste:**
- ✅ Generaste resúmenes ejecutivos automáticamente
- ✅ Entendiste cómo ajustar temperature y maxTokens
- ✅ Viste cómo RAG agrega contexto histórico
- ✅ Experimentaste con diferentes parámetros

**Valor de negocio:**
- Tiempo: De 5-10 min → 15 segundos por resumen
- Ahorro: 50+ horas/mes
- Calidad: Consistente y profesional
- Tendencias: Incluye comparación con exámenes anteriores

**Concepto clave:** 
> Temperature media + maxTokens limitado = Resúmenes concisos y fluidos

**Próximo:** Checkpoint del Día 1 y cálculo de ROI

---

### 🎯 Checkpoint Día 1 y Cálculo de ROI (10 min)

#### Verificar que Todo Funciona (3 min)

**Abre tu App Web y verifica:**

1. **Informes clasificados:**
   - ✅ Al menos 3 informes con badges de riesgo (BAJO/MEDIO/ALTO)
   - ✅ Cada uno tiene justificación detallada

2. **Resúmenes generados:**
   - ✅ Al menos 3 informes con resúmenes ejecutivos
   - ✅ Resúmenes de ~100-150 palabras
   - ✅ Lenguaje claro y no técnico

3. **Estadísticas en la app:**
   - ✅ Contador de informes clasificados
   - ✅ Distribución de niveles de riesgo
   - ✅ Tiempo promedio de procesamiento

**💡 Si algo falta:** Clasifica y genera resúmenes de más informes hasta tener al menos 3 completos.

---

#### Calcular el ROI (5 min)

**👉 El instructor mostrará estos cálculos en pantalla compartida**

**Proceso Manual (ANTES):**
```
Por cada informe:
- Revisión médica y clasificación: 10-15 min
- Creación de resumen ejecutivo: 5-10 min
- Total: 15-25 min por informe

Con 500 informes/mes:
- Tiempo total: 125-208 horas/mes
- Costo (asumiendo $50/hora médico): $6,250-10,400/mes
```

**Proceso Automatizado (AHORA):**
```
Por cada informe:
- Clasificación automática: 30 segundos
- Generación de resumen: 15 segundos
- Revisión médica (solo casos ALTO): 5 min
- Total: ~1 min por informe (+ 5 min para casos críticos)

Con 500 informes/mes (asumiendo 20% ALTO riesgo):
- Tiempo total: 8 horas clasificación + 8 horas revisión = 16 horas/mes
- Costo: $800/mes
- Ahorro: $5,450-9,600/mes (87-92% reducción)
```

**Beneficios Adicionales:**
- ✅ Identificación inmediata de casos críticos
- ✅ Consistencia 100% en criterios
- ✅ Resúmenes profesionales y estandarizados
- ✅ Tendencias históricas automáticas

---

#### Preguntas para Reflexionar (2 min)

**Técnicas:**
- ¿Por qué usamos temperature 0.1 para clasificación y 0.5 para resúmenes?
- ¿Cómo ayuda RAG a mejorar la precisión?
- ¿Qué hace que un prompt sea efectivo?

**De Negocio:**
- ¿Qué otros procesos en tu organización podrían automatizarse con este patrón?
- ¿Cómo medirías el éxito de esta automatización?
- ¿Qué riesgos ves en automatizar decisiones médicas?

---

### 🎉 ¡Felicitaciones!

Has completado el Día 1 del workshop. Ahora sabes cómo:
- ✅ Clasificar informes automáticamente con few-shot learning
- ✅ Generar resúmenes ejecutivos con IA
- ✅ Ajustar parámetros (temperature, maxTokens) según el caso de uso
- ✅ Usar RAG para agregar contexto histórico
- ✅ Calcular el ROI de automatización con IA

**Mañana (Día 2):** Aprenderás a personalizar emails según el nivel de riesgo, profundizar en RAG, e integrar PDFs externos.

---

## 📖 Conceptos Clave del Día 1

Esta sección resume los conceptos técnicos más importantes que aprendiste hoy, con ejemplos concretos del workshop.

### 1. Few-Shot Learning

**¿Qué es?**
Few-shot learning es una técnica donde enseñas al modelo de IA con solo unos pocos ejemplos (típicamente 2-5) en lugar de entrenar un modelo completo con miles de datos.

**Cómo lo usamos en el workshop:**
En el prompt de clasificación, incluimos 3 ejemplos:
- 1 ejemplo de riesgo BAJO (presión 118/75, IMC 23.5)
- 1 ejemplo de riesgo MEDIO (presión 135/85, IMC 27.2)
- 1 ejemplo de riesgo ALTO (presión 155/95, IMC 32.1)

**Ventajas:**
- ✅ No requiere entrenar un modelo custom (ahorra tiempo y dinero)
- ✅ Fácil de actualizar (solo editas el prompt)
- ✅ Resultados inmediatos sin necesidad de datos históricos masivos

**Ejemplo del workshop:**
```
EJEMPLOS:

Ejemplo BAJO:
Presión: 118/75, IMC: 23.5, sin antecedentes
→ BAJO

Ejemplo MEDIO:
Presión: 135/85, IMC: 27.2, colesterol elevado
→ MEDIO

Ejemplo ALTO:
Presión: 155/95, IMC: 32.1, diabetes tipo 2
→ ALTO

Ahora clasifica este informe:
[datos del informe actual]
```

---

### 2. RAG (Retrieval-Augmented Generation)

**¿Qué es?**
RAG es una técnica que combina búsqueda de información (Retrieval) con generación de texto (Generation). Primero busca información relevante, luego la agrega al prompt para que el modelo genere una respuesta más precisa.

**Cómo lo usamos en el workshop:**
Antes de clasificar o generar un resumen, buscamos los últimos 2-3 informes del mismo trabajador usando SQL:

```sql
SELECT * FROM informes_medicos 
WHERE trabajador_id = :id 
ORDER BY fecha_examen DESC 
LIMIT 3
```

Luego agregamos esa información al prompt como "contexto histórico".

**Ventajas:**
- ✅ Reduce alucinaciones (el modelo no inventa datos)
- ✅ Proporciona contexto específico del trabajador
- ✅ Permite detectar tendencias (ej: "deterioro en los últimos 6 meses")

**Ejemplo del workshop:**
```
CONTEXTO HISTÓRICO:
- 2024-06-15: Presión 140/88, IMC 28.5, Riesgo: MEDIO
- 2024-03-10: Presión 135/85, IMC 27.2, Riesgo: MEDIO

INFORME ACTUAL:
- 2024-12-02: Presión 165/102, IMC 32.9
→ Se observa deterioro progresivo → ALTO
```

**Diferencia con búsqueda vectorial (Día 2):**
- Día 1: RAG simple con SQL (busca por `trabajador_id`)
- Día 2: RAG avanzado con embeddings (busca por similitud semántica)

---

### 3. Temperature

**¿Qué es?**
Temperature controla la "creatividad" o "aleatoriedad" del modelo. Es un número entre 0.0 y 1.0.

**Escala de Temperature:**
```
0.0 ────────── 0.5 ────────── 1.0
Determinístico  Balanceado    Muy creativo
Preciso         Natural       Variado
```

**Cómo lo usamos en el workshop:**

| Caso de Uso | Temperature | Por qué |
|-------------|-------------|---------|
| **Clasificación** | 0.1 | Necesitamos precisión y consistencia. Mismo informe → mismo resultado |
| **Resúmenes** | 0.5 | Balance entre precisión y fluidez natural del lenguaje |
| **Emails (Día 2)** | 0.7 | Más variedad y tono natural para comunicación humana |

**Ejemplo práctico:**

**Temperature 0.1 (Clasificación):**
- Input: "Presión 165/102, IMC 32.9, diabetes"
- Output 1: "ALTO - Hipertensión severa requiere atención inmediata"
- Output 2: "ALTO - Hipertensión severa requiere atención inmediata"
- Output 3: "ALTO - Hipertensión severa requiere atención inmediata"
- ✅ Siempre el mismo resultado (consistencia)

**Temperature 0.5 (Resumen):**
- Input: Mismo informe
- Output 1: "El trabajador presenta hipertensión severa y obesidad..."
- Output 2: "Se detecta presión arterial elevada y sobrepeso significativo..."
- Output 3: "Los parámetros indican hipertensión grado 2 y obesidad..."
- ✅ Variaciones naturales pero mantiene el mensaje

**Temperature 0.9 (Muy creativo - NO recomendado para este caso):**
- Output: "¡Alerta! Este trabajador necesita cambios urgentes en su estilo de vida..."
- ❌ Demasiado variado, puede perder precisión médica

---

### 4. maxTokens

**¿Qué es?**
maxTokens limita la longitud máxima de la respuesta del modelo. Un token es aproximadamente 0.75 palabras en español.

**Conversión aproximada:**
```
100 tokens  ≈  75 palabras  ≈  1 párrafo corto
300 tokens  ≈ 225 palabras  ≈  2-3 párrafos
1000 tokens ≈ 750 palabras  ≈  1 página
```

**Cómo lo usamos en el workshop:**

| Caso de Uso | maxTokens | Resultado Esperado |
|-------------|-----------|-------------------|
| **Clasificación** | 1000 | Permite justificación detallada (~500 palabras) |
| **Resúmenes** | 300 | Fuerza concisión (~150 palabras) |
| **Emails (Día 2)** | 500 | Email completo pero no excesivo (~350 palabras) |

**Función dual de maxTokens:**
1. **Limitar:** Evita respuestas demasiado largas
2. **Guiar:** El modelo ajusta su estilo para cumplir el límite

**Ejemplo práctico:**

**maxTokens 1000 (Clasificación):**
```
Resultado: "ALTO - El trabajador presenta hipertensión arterial severa 
(165/102 mmHg) que supera significativamente los valores normales 
(120/80 mmHg). Además, se observa obesidad grado I (IMC 32.9) y 
diabetes mellitus descompensada. Estos factores combinados representan 
un riesgo cardiovascular elevado que requiere intervención médica 
inmediata. Se recomienda restricción de actividades de alto riesgo 
físico y evaluación cardiológica urgente..."
```
✅ Justificación completa y detallada

**maxTokens 300 (Resumen):**
```
Resultado: "El trabajador presenta múltiples factores de riesgo que 
requieren atención inmediata. Se detecta hipertensión severa y obesidad. 
Comparado con su examen anterior, se observa deterioro significativo. 
Se recomienda restricción de actividades de riesgo y evaluación médica 
urgente."
```
✅ Conciso pero completo (~80 palabras)

**maxTokens 50 (Demasiado corto - NO recomendado):**
```
Resultado: "Hipertensión severa y obesidad. Requiere atención médica."
```
❌ Pierde información importante

---

### 5. Prompt Engineering

**¿Qué es?**
Prompt engineering es el arte de diseñar instrucciones efectivas para modelos de IA. Un buen prompt es claro, específico y proporciona contexto.

**Anatomía de un buen prompt (del workshop):**

```
1. CONTEXTO/ROL
   "Eres un médico ocupacional experto en evaluar riesgos laborales."
   → Define quién es el modelo

2. TAREA
   "Clasifica el siguiente informe en uno de estos niveles: BAJO, MEDIO, ALTO"
   → Define qué debe hacer

3. CRITERIOS
   "- BAJO: Parámetros normales, apto sin restricciones
    - MEDIO: Parámetros limítrofes, requiere seguimiento
    - ALTO: Parámetros alterados, requiere atención inmediata"
   → Define cómo evaluar

4. EJEMPLOS (Few-Shot)
   [3 ejemplos concretos con datos y resultados]
   → Muestra el formato esperado

5. CONTEXTO ADICIONAL (RAG)
   "CONTEXTO HISTÓRICO: [informes anteriores]"
   → Proporciona información relevante

6. INPUT
   "INFORME ACTUAL: [datos del informe]"
   → Los datos a procesar

7. FORMATO DE SALIDA
   "Responde en formato JSON: {nivel_riesgo: ..., justificacion: ...}"
   → Define el formato de respuesta
```

**Mejores prácticas del workshop:**
- ✅ Especifica la audiencia ("para gerentes, no médicos")
- ✅ Usa restricciones claras ("máximo 150 palabras")
- ✅ Proporciona ejemplos concretos (few-shot learning)
- ✅ Incluye contexto relevante (RAG)
- ✅ Define el formato de salida (JSON, párrafos, etc.)

---

### 6. Comparación: Clasificación vs Resumen

**Tabla comparativa de configuraciones:**

| Aspecto | Clasificación | Resumen |
|---------|---------------|---------|
| **Objetivo** | Decisión categórica (BAJO/MEDIO/ALTO) | Comunicación fluida |
| **Audiencia** | Sistema/Médico | Gerente (no médico) |
| **Temperature** | 0.1 (precisión) | 0.5 (balance) |
| **maxTokens** | 1000 (justificación detallada) | 300 (concisión) |
| **Prompt** | Criterios técnicos + ejemplos | Lenguaje claro + restricciones |
| **RAG** | Últimos 3 informes | Últimos 2 informes |
| **Salida** | JSON estructurado | Texto en párrafos |
| **Tiempo** | ~30 segundos | ~15 segundos |

**Lección clave:** No hay una configuración "correcta" universal. Los parámetros se ajustan según el caso de uso específico.

---

### 🎯 Aplicando estos conceptos

**Pregunta de reflexión:** Si tuvieras que crear un sistema para generar emails de seguimiento, ¿qué parámetros usarías?

**Respuesta sugerida:**
- Temperature: 0.6-0.7 (más natural que resumen, menos que brainstorming)
- maxTokens: 400-500 (email completo pero no excesivo)
- Few-shot: 2-3 ejemplos de emails por nivel de riesgo
- RAG: Incluir historial de comunicaciones previas
- Prompt: Especificar tono (urgente/profesional/tranquilizador)

**Verás esto en acción en el Día 2 del workshop!** 🚀

---

## 📚 Día 2: Capacidades Avanzadas

**📝 Nota:** El contenido del Día 2 será actualizado próximamente para reflejar el nuevo enfoque:
- Módulo 3: Emails personalizados por nivel de riesgo
- Módulo 4: RAG avanzado con embeddings vectoriales
- Módulo 5: Integración de PDFs externos (clínicas externas)
- Experimentación libre

**Por ahora, el contenido a continuación corresponde a la versión anterior del workshop.**

---

### Módulo 3: RAG con Embeddings Vectoriales (30 min)

#### Objetivo
Implementar RAG (Retrieval-Augmented Generation) para proporcionar contexto histórico a las respuestas de IA.

#### ¿Qué es RAG?

**RAG** = Retrieval-Augmented Generation

1. **Retrieval**: Buscar información relevante en una base de datos
2. **Augmented**: Agregar esa información al prompt
3. **Generation**: Generar respuesta con contexto

**Beneficios:**
- ✅ Reduce alucinaciones
- ✅ Proporciona contexto específico
- ✅ Mejora precisión de respuestas

#### Paso 1: Desplegar Stack RAG

```bash
cd cdk
cdk deploy AIRAGStack
```

**Recursos creados:**
- Lambda para generar embeddings
- Permisos para Amazon Titan Embeddings

#### Paso 2: Entender Embeddings

Los **embeddings** son representaciones vectoriales de texto:

```python
# Texto original
"Presión arterial: 140/90 mmHg"

# Embedding (vector de 1024 dimensiones)
[0.123, -0.456, 0.789, ..., 0.234]
```

**Ventaja:** Textos similares tienen embeddings similares.

#### Paso 3: Generar Embeddings

```bash
# Generar embeddings para un informe
aws lambda invoke \
  --function-name generate-embeddings \
  --payload '{"informe_id": 1}' \
  response.json

# Ver resultado
cat response.json
```

#### Paso 4: Revisar Código de Búsqueda

Abre [`lambda/shared/similarity_search.py`](lambda/shared/similarity_search.py):

```python
def buscar_informes_similares(trabajador_id, embedding_actual, limit=3):
    """
    Busca informes anteriores del mismo trabajador usando similitud coseno.
    """
    sql = """
        SELECT 
            ie.informe_id,
            ie.contenido,
            1 - (ie.embedding <=> %s::vector) as similarity
        FROM informes_embeddings ie
        WHERE ie.trabajador_id = %s
          AND ie.informe_id != %s
        ORDER BY ie.embedding <=> %s::vector
        LIMIT %s
    """
```

**Conceptos clave:**
- `<=>` es el operador de distancia coseno de pgvector
- Menor distancia = mayor similitud
- Filtramos por trabajador_id para contexto relevante

#### Paso 5: Probar Búsqueda RAG

```bash
# Crear varios informes para el mismo trabajador
aws lambda invoke \
  --function-name generate-test-data \
  --payload '{"trabajador_id": 1, "cantidad": 3}' \
  response.json

# Generar embeddings para todos
for i in {1..3}; do
  aws lambda invoke \
    --function-name generate-embeddings \
    --payload "{\"informe_id\": $i}" \
    response.json
done

# Ahora la búsqueda RAG encontrará informes anteriores
```

---

### Módulo 4: Clasificación de Riesgo con Few-Shot Learning (30 min)

#### Objetivo
Clasificar informes médicos en niveles de riesgo (BAJO, MEDIO, ALTO) usando few-shot learning.

#### ¿Qué es Few-Shot Learning?

**Few-shot learning** = Enseñar al modelo con pocos ejemplos en el prompt.

```
Clasifica el siguiente informe médico en: BAJO, MEDIO o ALTO riesgo.

Ejemplos:

BAJO: Presión 118/75, IMC 23.5, sin antecedentes
MEDIO: Presión 135/85, IMC 27.2, colesterol elevado
ALTO: Presión 155/95, IMC 32.1, diabetes tipo 2

Ahora clasifica este informe:
[informe actual]
```

#### Paso 1: Desplegar Stack de Clasificación

```bash
cd cdk
cdk deploy AIClassificationStack
```

#### Paso 2: Revisar Prompt de Clasificación

Abre [`prompts/classification.txt`](prompts/classification.txt):

```
Eres un médico ocupacional experto en evaluar riesgos laborales.

Clasifica el siguiente informe en uno de estos niveles:
- BAJO: Parámetros normales, apto sin restricciones
- MEDIO: Parámetros limítrofes, requiere seguimiento
- ALTO: Parámetros alterados, requiere atención inmediata

EJEMPLOS:

[Ejemplo BAJO con datos específicos]
[Ejemplo MEDIO con datos específicos]
[Ejemplo ALTO con datos específicos]

CONTEXTO HISTÓRICO:
[Informes anteriores del trabajador - proporcionado por RAG]

INFORME ACTUAL:
[Datos del informe]

Responde en formato JSON:
{
  "nivel_riesgo": "BAJO|MEDIO|ALTO",
  "justificacion": "explicación detallada"
}
```

**Nota:** El contexto histórico viene de RAG.

#### Paso 3: Clasificar un Informe

```bash
# Clasificar informe
aws lambda invoke \
  --function-name classify-risk \
  --payload '{"informe_id": 1}' \
  response.json

# Ver resultado
cat response.json
```

#### Paso 4: Verificar Clasificación en Aurora

```bash
psql -h <aurora-endpoint> -U postgres -d medical_reports

SELECT 
  id,
  trabajador_nombre,
  nivel_riesgo,
  justificacion_riesgo
FROM informes_completos
WHERE id = 1;
```

#### Ejercicio: Comparar Versiones de Prompts

Revisa las 3 versiones del prompt de clasificación:

**Versión 1** ([`prompts/classification_v1.txt`](prompts/classification_v1.txt)):
- Sin ejemplos
- Resultados inconsistentes

**Versión 2** ([`prompts/classification_v2.txt`](prompts/classification_v2.txt)):
- Con ejemplos básicos
- Mejor, pero sin contexto histórico

**Versión 3** ([`prompts/classification.txt`](prompts/classification.txt)):
- Con ejemplos detallados
- Con contexto histórico (RAG)
- Resultados precisos y consistentes

**Lección:** Few-shot learning + RAG = Clasificación precisa

---

### Módulo 5: Resúmenes y Emails Personalizados (30 min)

#### Objetivo
Generar resúmenes ejecutivos y emails personalizados según el nivel de riesgo.

#### Paso 1: Desplegar Stacks de Resumen y Email

```bash
cd cdk
cdk deploy AISummaryStack
cdk deploy AIEmailStack
```

#### Paso 2: Generar Resumen Ejecutivo

```bash
# Generar resumen
aws lambda invoke \
  --function-name generate-summary \
  --payload '{"informe_id": 1}' \
  response.json

# Ver resultado
cat response.json
```

**Características del resumen:**
- Máximo 150 palabras
- Lenguaje claro y no técnico
- Incluye tendencias históricas (RAG)
- Enfocado en lo más importante

#### Paso 3: Revisar Prompt de Resumen

Abre [`prompts/summary.txt`](prompts/summary.txt):

```
Genera un resumen ejecutivo del informe médico.

REQUISITOS:
- Máximo 150 palabras
- Lenguaje claro, no técnico
- Enfócate en hallazgos principales
- Incluye tendencias si hay informes anteriores

CONTEXTO HISTÓRICO:
[Informes anteriores - proporcionado por RAG]

INFORME ACTUAL:
[Datos del informe]

FORMATO:
Párrafo único, directo y accionable.
```

**Parámetros:**
- `temperature: 0.5` (balanceado entre precisión y fluidez)
- `maxTokens: 300`

#### Paso 4: Enviar Email Personalizado

```bash
# Enviar email
aws lambda invoke \
  --function-name send-email \
  --payload '{"informe_id": 1}' \
  response.json
```

#### Paso 5: Revisar Prompts de Email

Hay 3 prompts diferentes según el nivel de riesgo:

**Email Riesgo ALTO** ([`prompts/email_high.txt`](prompts/email_high.txt)):
```
Genera un email URGENTE para el contratista.

TONO: Urgente pero profesional
OBJETIVO: Acción inmediata

Incluye:
- Hallazgos críticos
- Acciones requeridas INMEDIATAMENTE
- Consecuencias de no actuar
```

**Email Riesgo MEDIO** ([`prompts/email_medium.txt`](prompts/email_medium.txt)):
```
Genera un email PROFESIONAL para el contratista.

TONO: Profesional y constructivo
OBJETIVO: Seguimiento programado

Incluye:
- Hallazgos que requieren atención
- Recomendaciones de seguimiento
- Plazo sugerido
```

**Email Riesgo BAJO** ([`prompts/email_low.txt`](prompts/email_low.txt)):
```
Genera un email TRANQUILIZADOR para el contratista.

TONO: Positivo y alentador
OBJETIVO: Confirmar estado saludable

Incluye:
- Confirmación de parámetros normales
- Felicitación por mantener salud
- Recordatorio de controles periódicos
```

**Parámetros:**
- `temperature: 0.7` (más creativo para personalización)
- `maxTokens: 500`

#### Paso 6: Verificar Email Recibido

Revisa tu bandeja de entrada. Deberías recibir un email personalizado según el nivel de riesgo del informe.

---

### 🎨 Experimentación Libre (30 min)

Ahora es tu turno de experimentar. Aquí hay algunas ideas:

#### Experimento 1: Modificar Tono de Emails

1. Abre [`prompts/email_high.txt`](prompts/email_high.txt)
2. Cambia "URGENTE" por "IMPORTANTE"
3. Re-despliega: `cdk deploy AIEmailStack`
4. Envía otro email y compara

#### Experimento 2: Ajustar Longitud de Resúmenes

1. Abre [`prompts/summary.txt`](prompts/summary.txt)
2. Cambia "Máximo 150 palabras" a "Máximo 50 palabras"
3. Re-despliega: `cdk deploy AISummaryStack`
4. Genera otro resumen y compara

#### Experimento 3: Agregar Más Ejemplos a Clasificación

1. Abre [`prompts/classification.txt`](prompts/classification.txt)
2. Agrega un 4to ejemplo con un caso específico
3. Re-despliega: `cdk deploy AIClassificationStack`
4. Clasifica varios informes y observa mejoras

#### Experimento 4: Cambiar Temperature

Prueba diferentes valores de temperature:

| Temperature | Uso Ideal | Resultado |
|-------------|-----------|-----------|
| 0.0 - 0.2 | Extracción, clasificación | Determinístico, preciso |
| 0.3 - 0.5 | Resúmenes, análisis | Balanceado |
| 0.6 - 0.8 | Emails, contenido | Creativo, variado |
| 0.9 - 1.0 | Brainstorming | Muy creativo |

#### Experimento 5: Comparar Con y Sin RAG

1. Modifica [`lambda/ai/classify_risk/index.py`](lambda/ai/classify_risk/index.py)
2. Comenta la sección que agrega contexto histórico
3. Re-despliega y compara resultados

**Pregunta:** ¿Cómo mejora RAG la precisión?

---

## 🔧 Troubleshooting

### Problema 1: "Lambda not found" o "Function not found"

**Causa:** La Lambda no se desplegó correctamente o estás usando el prefijo incorrecto.

**Solución:**
```bash
# 1. Verifica que usaste tu prefijo correcto
# Ejemplo: participant-1, participant-2, etc.

# 2. Verifica que las Lambdas existen
aws lambda list-functions --query 'Functions[?contains(FunctionName, `participant-1`)].FunctionName'

# 3. Si no aparecen, re-despliega los AI Stacks
cd cdk
npx cdk deploy participant-1-AIClassificationStack participant-1-AISummaryStack --require-approval never
```

**Checklist:**
- ✅ ¿Usaste el prefijo correcto en todos los comandos?
- ✅ ¿Completaste el despliegue del Paso 4 del Setup?
- ✅ ¿Estás en la región correcta (us-east-2)?

---

### Problema 2: "Access denied to Aurora" o "Database connection failed"

**Causa:** La Lambda no tiene permisos para acceder a Aurora o hay un problema de red.

**Solución:**
```bash
# 1. Verifica que el LegacyStack se desplegó correctamente
aws cloudformation describe-stacks \
  --stack-name participant-1-MedicalReportsLegacyStack \
  --query 'Stacks[0].StackStatus'

# Debe retornar: "CREATE_COMPLETE" o "UPDATE_COMPLETE"

# 2. Verifica que Aurora está disponible
aws cloudformation describe-stacks \
  --stack-name participant-1-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`AuroraEndpoint`].OutputValue' \
  --output text

# 3. Si el problema persiste, contacta al instructor
```

**Nota:** El instructor desplegó tu LegacyStack antes del workshop. Si hay problemas, es probable que necesite re-desplegarlo.

---

### Problema 3: "Bedrock access denied" o "Model access denied"

**Causa:** Tu cuenta no tiene acceso al modelo Nova Pro o la región es incorrecta.

**Solución:**
```bash
# 1. Verifica que estás en us-east-2
aws configure get region

# 2. Verifica acceso a Bedrock
aws bedrock list-foundation-models --region us-east-2 \
  --query 'modelSummaries[?contains(modelId, `nova-pro`)].modelId'

# 3. Si no aparece, contacta al instructor
# El instructor debe habilitar el modelo en la cuenta
```

**Nota:** El acceso a Bedrock debe estar configurado por el instructor antes del workshop.

---

### Problema 4: Los logs no aparecen en CloudWatch

**Causa:** Los logs pueden tardar 1-2 minutos en aparecer después de invocar la Lambda.

**Solución:**
```bash
# 1. Espera 1-2 minutos después de invocar la Lambda

# 2. Verifica que la Lambda se ejecutó
aws lambda invoke \
  --function-name participant-1-classify-risk \
  --payload '{"informe_id": 1}' \
  response.json

# 3. Intenta ver los logs nuevamente
aws logs tail /aws/lambda/participant-1-classify-risk --follow

# 4. Si aún no aparecen, verifica el nombre del log group
aws logs describe-log-groups \
  --log-group-name-prefix /aws/lambda/participant-1
```

**Tip:** Presiona Ctrl+C para salir del comando `--follow`.

---

### Problema 5: La App Web no carga o muestra error

**Causa:** La URL es incorrecta o el bucket S3 no está configurado correctamente.

**Solución:**
```bash
# 1. Obtén la URL correcta de tu app web
aws cloudformation describe-stacks \
  --stack-name participant-1-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`WebsiteURL`].OutputValue' \
  --output text

# 2. Copia y pega la URL en tu navegador

# 3. Si muestra error 403 o 404, contacta al instructor
```

---

### Problema 6: "Informe not classified" al generar resumen

**Causa:** Estás intentando generar un resumen de un informe que no ha sido clasificado.

**Solución:**
```bash
# 1. Primero clasifica el informe
aws lambda invoke \
  --function-name participant-1-classify-risk \
  --payload '{"informe_id": 1}' \
  response.json

# 2. Verifica que se clasificó correctamente
cat response.json

# 3. Ahora genera el resumen
aws lambda invoke \
  --function-name participant-1-generate-summary \
  --payload '{"informe_id": 1}' \
  summary.json
```

**Regla:** Siempre debes clasificar un informe antes de generar su resumen.

---

### Problema 7: Comandos de CloudShell no funcionan

**Causa:** Sintaxis incorrecta o variables no definidas.

**Solución:**
```bash
# 1. Verifica que definiste las variables de entorno
echo $CLUSTER_ARN
echo $SECRET_ARN

# 2. Si están vacías, defínelas nuevamente
CLUSTER_ARN=$(aws cloudformation describe-stacks \
  --stack-name participant-1-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`ClusterArn`].OutputValue' \
  --output text)

SECRET_ARN=$(aws cloudformation describe-stacks \
  --stack-name participant-1-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`SecretArn`].OutputValue' \
  --output text)

# 3. Verifica que ahora tienen valores
echo $CLUSTER_ARN
echo $SECRET_ARN
```

---

### Checklist General de Verificación

Si tienes problemas, verifica estos puntos en orden:

1. **✅ Prefijo correcto:** ¿Estás usando `participant-1`, `participant-2`, etc. según tu asignación?
2. **✅ Región correcta:** ¿Estás en `us-east-2`?
3. **✅ Sesión AWS activa:** ¿Puedes ejecutar `aws sts get-caller-identity` sin errores?
4. **✅ Stacks desplegados:** ¿Completaste el Paso 4 del Setup (despliegue de AI Stacks)?
5. **✅ Logs recientes:** ¿Esperaste 1-2 minutos para que aparezcan los logs?

---

### Comandos Útiles para Debugging

```bash
# Ver todos tus stacks
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
  --query 'StackSummaries[?contains(StackName, `participant-1`)].StackName'

# Ver todas tus Lambdas
aws lambda list-functions \
  --query 'Functions[?contains(FunctionName, `participant-1`)].FunctionName'

# Ver outputs de un stack
aws cloudformation describe-stacks \
  --stack-name participant-1-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs'

# Ver últimos logs de una Lambda (sin follow)
aws logs tail /aws/lambda/participant-1-classify-risk --since 5m
```

---

### ¿Cuándo pedir ayuda al instructor?

Pide ayuda si:
- ❌ Los comandos de verificación muestran que faltan recursos
- ❌ Ves errores de permisos IAM o Bedrock
- ❌ La App Web no carga después de verificar la URL
- ❌ Los problemas persisten después de seguir las soluciones

**No te preocupes:** Estos workshops tienen muchas partes móviles. El instructor está para ayudarte! 🙂

---

## 📋 Ejemplos de Output Esperado

Esta sección muestra ejemplos de outputs correctos para que puedas verificar que todo funciona bien.

### Output 1: Clasificación Exitosa

**Comando:**
```bash
aws lambda invoke \
  --function-name participant-1-classify-risk \
  --payload '{"informe_id": 1}' \
  response.json && cat response.json
```

**Output esperado:**
```json
{
  "statusCode": 200,
  "body": {
    "informe_id": 1,
    "nivel_riesgo": "ALTO",
    "justificacion": "El trabajador presenta hipertensión arterial severa (165/102 mmHg) que supera significativamente los valores normales. Además, se observa obesidad grado I (IMC 32.9) y diabetes mellitus descompensada. Estos factores combinados representan un riesgo cardiovascular elevado que requiere intervención médica inmediata.",
    "tiempo_procesamiento": "2.3s",
    "informes_anteriores_encontrados": 2
  }
}
```

**Qué verificar:**
- ✅ `statusCode: 200` (éxito)
- ✅ `nivel_riesgo` es uno de: BAJO, MEDIO, ALTO
- ✅ `justificacion` tiene sentido médicamente
- ✅ `tiempo_procesamiento` es razonable (1-5 segundos)

---

### Output 2: Generación de Resumen Exitosa

**Comando:**
```bash
aws lambda invoke \
  --function-name participant-1-generate-summary \
  --payload '{"informe_id": 1}' \
  summary.json && cat summary.json
```

**Output esperado:**
```json
{
  "statusCode": 200,
  "body": {
    "informe_id": 1,
    "resumen": "El trabajador Carlos Rodríguez presenta múltiples factores de riesgo que requieren atención médica inmediata. Se detecta hipertensión arterial severa (165/102 mmHg) y obesidad grado I (IMC: 32.9). Los exámenes de laboratorio revelan diabetes mellitus descompensada. Comparado con su examen anterior hace 6 meses, se observa deterioro significativo en todos los parámetros. Se recomienda restricción inmediata de actividades de alto riesgo y evaluación médica urgente.",
    "palabras": 87,
    "tiempo_procesamiento": "1.8s",
    "incluye_contexto_historico": true
  }
}
```

**Qué verificar:**
- ✅ `statusCode: 200` (éxito)
- ✅ `resumen` es claro y no técnico
- ✅ `palabras` está entre 80-180
- ✅ Menciona el nivel de riesgo y acciones recomendadas

---

### Output 3: Logs de Clasificación

**Comando:**
```bash
aws logs tail /aws/lambda/participant-1-classify-risk --since 5m
```

**Output esperado (fragmentos clave):**
```
2024-12-02T10:15:23.456Z [INFO] Lambda invocation started
2024-12-02T10:15:23.567Z [INFO] Loading informe ID: 1
2024-12-02T10:15:23.678Z [INFO] Worker ID: 3, searching for historical reports
2024-12-02T10:15:23.789Z [INFO] RAG: Retrieved 2 previous reports
2024-12-02T10:15:23.890Z [INFO] Loading classification prompt from S3
2024-12-02T10:15:23.991Z [INFO] Few-shot examples loaded: 3 examples
2024-12-02T10:15:24.102Z [INFO] Invoking Bedrock with inference profile: us.amazon.nova-pro-v1:0
2024-12-02T10:15:25.234Z [INFO] Bedrock response received
2024-12-02T10:15:25.345Z [INFO] Classification result: ALTO
2024-12-02T10:15:25.456Z [INFO] Saving to Aurora database
2024-12-02T10:15:25.567Z [INFO] Lambda execution completed successfully
```

**Qué buscar:**
- ✅ `RAG: Retrieved X previous reports` (contexto histórico)
- ✅ `Few-shot examples loaded` (prompt con ejemplos)
- ✅ `Invoking Bedrock` (llamada a IA)
- ✅ `Classification result: BAJO/MEDIO/ALTO` (resultado)
- ✅ `Lambda execution completed successfully` (éxito)

---

### Output 4: Query a Aurora

**Comando:**
```bash
aws rds-data execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database medical_reports \
  --sql "SELECT id, nivel_riesgo, LENGTH(resumen_ejecutivo) as resumen_length FROM informes_medicos WHERE id = 1"
```

**Output esperado:**
```json
{
  "records": [
    [
      {"longValue": 1},
      {"stringValue": "ALTO"},
      {"longValue": 523}
    ]
  ],
  "columnMetadata": [
    {"name": "id", "type": 4},
    {"name": "nivel_riesgo", "type": 12},
    {"name": "resumen_length", "type": 4}
  ]
}
```

**Qué verificar:**
- ✅ `nivel_riesgo` tiene un valor (BAJO/MEDIO/ALTO)
- ✅ `resumen_length` es mayor a 0 (si ya generaste el resumen)

---

### Output 5: Lista de Informes (App Web)

**Endpoint:** `GET /informes`

**Output esperado:**
```json
{
  "informes": [
    {
      "id": 1,
      "trabajador_nombre": "Juan Pérez Gómez",
      "tipo_examen": "Examen Ocupacional Periódico",
      "presion_arterial": "165/102",
      "nivel_riesgo": "ALTO",
      "fecha_examen": "2024-12-01T10:00:00Z"
    },
    {
      "id": 2,
      "trabajador_nombre": "María González López",
      "tipo_examen": "Examen Pre-Ocupacional",
      "presion_arterial": "135/85",
      "nivel_riesgo": "MEDIO",
      "fecha_examen": "2024-12-01T11:00:00Z"
    },
    ...
  ]
}
```

**Qué verificar:**
- ✅ Array con 10 informes
- ✅ Cada informe tiene datos completos
- ✅ Algunos tienen `nivel_riesgo` null (no clasificados aún)

---

### Errores Comunes y Sus Outputs

#### Error 1: Lambda no encontrada
```json
{
  "errorMessage": "Function not found: arn:aws:lambda:us-east-2:123456789012:function:participant-1-classify-risk",
  "errorType": "ResourceNotFoundException"
}
```
**Solución:** Verifica el prefijo y que desplegaste los AI Stacks.

#### Error 2: Informe no clasificado
```json
{
  "statusCode": 400,
  "body": {
    "error": "InformeNotClassifiedError",
    "message": "El informe debe ser clasificado antes de generar resumen",
    "informe_id": 1
  }
}
```
**Solución:** Clasifica el informe primero con `classify-risk`.

#### Error 3: Bedrock access denied
```json
{
  "statusCode": 502,
  "body": {
    "error": "BedrockInvocationError",
    "message": "Access denied to Bedrock model",
    "model_id": "us.amazon.nova-pro-v1:0"
  }
}
```
**Solución:** Contacta al instructor para habilitar acceso a Bedrock.

---

## 🧹 Limpieza de Recursos

Al finalizar el workshop, elimina todos los recursos:

```bash
cd cdk

# Eliminar todos los stacks
cdk destroy --all

# Confirmar: y

# Verificar que todo se eliminó
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE
```

**Importante:** Aurora se eliminará automáticamente sin crear snapshots (configurado para la demo).

---

## 📊 Resumen de Conceptos Aprendidos

### Servicios AWS
- ✅ **Amazon Bedrock** - LLMs como servicio
- ✅ **Amazon Nova Pro** - Modelo de lenguaje avanzado
- ✅ **Amazon Titan Embeddings** - Generación de embeddings
- ✅ **Amazon Textract** - OCR para PDFs
- ✅ **Aurora Serverless v2** - Base de datos con pgvector
- ✅ **Lambda** - Funciones serverless
- ✅ **S3** - Almacenamiento de objetos
- ✅ **SES** - Envío de emails
- ✅ **CDK** - Infraestructura como código

### Técnicas de IA Generativa
- ✅ **Prompt Engineering** - Diseño de prompts efectivos
- ✅ **Few-Shot Learning** - Aprendizaje con pocos ejemplos
- ✅ **RAG** - Retrieval-Augmented Generation
- ✅ **Embeddings Vectoriales** - Representación de texto
- ✅ **Temperature Control** - Control de aleatoriedad
- ✅ **Token Management** - Gestión de longitud de respuestas

### Mejores Prácticas
- ✅ Prompts específicos con ejemplos
- ✅ Temperature baja para precisión
- ✅ RAG para reducir alucinaciones
- ✅ Iteración de prompts
- ✅ Validación de salidas
- ✅ Monitoreo con CloudWatch

---

## 🎯 Próximos Pasos

Después del workshop, puedes:

1. **Experimentar más** con diferentes prompts y parámetros
2. **Agregar nuevos casos de uso** (ej: análisis de tendencias)
3. **Integrar con otros servicios** (ej: Step Functions para orquestación)
4. **Optimizar costos** ajustando modelos y parámetros
5. **Implementar en producción** con mejores prácticas de seguridad

---

## 📚 Recursos Adicionales

- [Amazon Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Prompt Engineering Guide](https://www.promptingguide.ai/)
- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/)
- [pgvector Documentation](https://github.com/pgvector/pgvector)
- [RAG Best Practices](https://aws.amazon.com/blogs/machine-learning/rag-best-practices/)

---

## ❓ Preguntas Frecuentes

**P: ¿Cuánto cuesta ejecutar esta demo?**
R: Aproximadamente $5-10 USD por participante (Aurora + Bedrock + otros servicios).

**P: ¿Puedo usar otros modelos de Bedrock?**
R: Sí, puedes cambiar el modelId en el código. Ejemplos: Claude, Llama, etc.

**P: ¿Funciona en otras regiones?**
R: Sí, pero verifica disponibilidad de Bedrock en tu región.

**P: ¿Cómo escalo esto a producción?**
R: Agrega: autenticación, rate limiting, monitoreo avanzado, CI/CD, y backups.

**P: ¿Puedo usar mis propios PDFs?**
R: Sí, sube cualquier PDF médico a S3 en la carpeta `/external-reports/`.

---

**¡Felicitaciones!** 🎉 Has completado el workshop de Automatización de Informes Médicos con AWS y Amazon Bedrock.

¿Preguntas? Consulta con el instructor o revisa la [Guía del Instructor](INSTRUCTOR_GUIDE.md).


---

## 🏗️ Arquitectura del Workshop (Información Adicional)

### ¿Por qué el despliegue es tan rápido ahora?

El workshop usa una **arquitectura optimizada** que separa la infraestructura en dos capas:

#### Capa 1: Infraestructura Base (Desplegada por el Instructor)
- **SharedNetworkStack:** VPC compartida para todos los participantes
- **LegacyStack:** Tu Aurora, S3, API Gateway y Lambdas Legacy
- **Tiempo:** ~15 minutos por participante (desplegado antes del workshop)

#### Capa 2: AI Stacks (Desplegada por Ti)
- **5 AI Stacks:** Lambdas de procesamiento de IA
- **Tiempo:** ~5-8 minutos (desplegado durante el workshop)

### Beneficios de esta Arquitectura

✅ **Más tiempo para aprender:** 70-80% menos tiempo de despliegue en vivo
✅ **Recursos compartidos:** VPC compartida reduce costos
✅ **Aislamiento completo:** Cada participante tiene su propia Aurora y S3
✅ **Despliegue paralelo:** El instructor puede preparar múltiples participantes simultáneamente

### Recursos que Tienes

Después del despliegue, tienes acceso a:

**Base de Datos:**
- Aurora Serverless v2 (PostgreSQL 15.8 con pgvector)
- Credenciales en AWS Secrets Manager
- Tablas: `patients`, `exams`, `exam_embeddings`

**Almacenamiento:**
- S3 Bucket individual: `<tu-prefix>-medical-reports-<account-id>`
- Carpetas: `external-reports/`, `generated-reports/`

**APIs:**
- API Gateway con endpoints:
  - `POST /examenes` - Registrar examen
  - `POST /examenes/generar-prueba` - Generar datos de prueba

**Lambdas de IA:**
- `extract-pdf` - Extracción con Textract + Bedrock
- `generate-embeddings` - Embeddings con Titan
- `classify-risk` - Clasificación con Nova Pro
- `generate-summary` - Resúmenes con Nova Pro
- `send-email` - Emails con Nova Pro + SES

### Documentación Adicional

- **Modos de despliegue:** Ver [`cdk/DEPLOY_MODES.md`](cdk/DEPLOY_MODES.md)
- **Guía del instructor:** Ver [`INSTRUCTOR_GUIDE.md`](INSTRUCTOR_GUIDE.md)
- **Arquitectura técnica:** Ver [`.kiro/specs/workshop-deployment-optimization/design.md`](.kiro/specs/workshop-deployment-optimization/design.md)

---

## 🆘 Soporte

Si tienes problemas durante el workshop:

1. **Revisa la sección de Troubleshooting** en el Setup Inicial
2. **Verifica CloudFormation** en la consola AWS
3. **Consulta CloudWatch Logs** para errores de Lambda
4. **Contacta al instructor** para ayuda

---

**¡Disfruta el workshop y aprende mucho! 🚀**
