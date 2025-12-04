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
git clone https://github.com/tu-organizacion/pulsosalud-immersion-day.git
cd pulsosalud-immersion-day

# Verificar que estás autenticado
aws sts get-caller-identity
```

**Deberías ver tu información de cuenta AWS.**

### Paso 3: Instalar Dependencias del Proyecto

```bash
# Instalar dependencias de CDK
cd cdk
npm install

# Verificar instalación
npx cdk --version
```

**Output esperado:** `2.x.x (build xxxxx)`

**Nota:** En CloudShell usamos `npx cdk` en lugar de solo `cdk` para ejecutar comandos CDK.

**Tiempo:** ~2-3 minutos

Mientras se instala, el instructor explicará la arquitectura del workshop.

### Paso 4: Desplegar AI Stacks del Día 1

El instructor ya desplegó:
- ✅ VPC compartida (PulsoSaludNetworkStack)
- ✅ Aurora Serverless v2 con datos de ejemplo (10 informes médicos)
- ✅ S3 Buckets para almacenamiento
- ✅ API Gateway con endpoints
- ✅ App Web para visualizar y ejecutar acciones
- ✅ Lambdas Legacy (registro de exámenes, listado)

Tú solo necesitas desplegar los **AI Stacks del Día 1** (3 stacks):

```bash
# Asegúrate de estar en el directorio CDK
cd ~/pulsosalud-immersion-day/cdk

# Configurar variables de entorno (IMPORTANTE)
# Reemplaza participant-1 con tu PARTICIPANT_PREFIX
export PARTICIPANT_PREFIX=participant-1
export DEPLOY_MODE=ai

# Desplegar los AI Stacks del Día 1
# Nota: AIRAGStack se despliega automáticamente como dependencia
npx cdk deploy $PARTICIPANT_PREFIX-AIClassificationStack $PARTICIPANT_PREFIX-AISummaryStack --require-approval never
```

**⚠️ IMPORTANTE:** Reemplaza `participant-1` con tu PARTICIPANT_PREFIX asignado por el instructor (ej: `participant-2`, `participant-3`, etc.)

**Tiempo estimado:** 6-8 minutos

**Recursos que se desplegarán:**
1. **AIRAGStack** (dependencia) - Lambda generate-embeddings + Layer de similarity search
2. **AIClassificationStack** - Lambda classify-risk con Bedrock Nova Pro
3. **AISummaryStack** - Lambda generate-summary con Bedrock Nova Pro

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
  --stack-name $PARTICIPANT_PREFIX-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`AppWebUrl`].OutputValue' \
  --output text
```

**Output esperado:**
```
http://participant-1-app-web-123456789012.s3-website.us-east-2.amazonaws.com
```

**Copia la URL** y ábrela en una nueva pestaña de tu navegador.

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

#### Paso 1: Configurar variables de entorno para Aurora (1 min)

**Opción A: Usar el script de configuración automática (Recomendado)**

```bash
# Navegar al directorio de scripts
cd ~/pulsosalud-immersion-day/scripts/examples

# Ejecutar el script (detecta automáticamente tu prefijo desde tu usuario IAM)
source setup-env-vars-cloudshell.sh
```

El script detectará automáticamente tu prefijo de participante extrayendo el número de tu usuario IAM (ej: `workshop-user-1` → `participant-1`).

**Salida esperada:**
```
🔍 Detectando tu prefijo de participante...
👤 Usuario detectado: workshop-user-1
✅ Prefijo detectado automáticamente: participant-1
�  Configurando variables de entorno para participant-1...
📊 Obteniendo ARN del cluster Aurora...
✅ CLUSTER_ARN: arn:aws:rds:us-east-2:...
✅ SECRET_ARN: arn:aws:secretsmanager:us-east-2:...
✅ DATABASE_NAME: medical_reports
✅ API_GATEWAY_URL: https://...
✅ WEBSITE_URL: http://...
```

**Opción B: Configurar manualmente (si el script automático falla)**

```bash
# Configurar variables de entorno usando tu PARTICIPANT_PREFIX
export PARTICIPANT_PREFIX=participant-1  # Reemplaza con tu prefijo

export CLUSTER_ARN=$(aws cloudformation describe-stacks \
  --stack-name $PARTICIPANT_PREFIX-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`DatabaseClusterArn`].OutputValue' \
  --output text)

export SECRET_ARN=$(aws cloudformation describe-stacks \
  --stack-name $PARTICIPANT_PREFIX-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`DatabaseSecretArn`].OutputValue' \
  --output text)

export DATABASE_NAME="medical_reports"

# Verificar que se configuraron correctamente
echo "Participant: $PARTICIPANT_PREFIX"
echo "Cluster ARN: $CLUSTER_ARN"
echo "Secret ARN: $SECRET_ARN"
echo "Database: $DATABASE_NAME"
```

**✅ Estas variables las usarás para consultas a la base de datos.**

---

#### Paso 2: Ver informes existentes (2 min)

```bash
# Ver informes en la base de datos usando las variables configuradas en el Paso 1
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
  --function-name $PARTICIPANT_PREFIX-classify-risk \
  --cli-binary-format raw-in-base64-out \
  --payload '{"informe_id": 1}' \
  response.json

# Ver resultado
cat response.json | python3 -m json.tool
```

**Tip:** Usamos `python3 -m json.tool` para formatear el JSON y hacerlo más legible.

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
# Ver logs de la Lambda (últimos 5 minutos)
aws logs tail /aws/lambda/$PARTICIPANT_PREFIX-classify-risk --since 5m --follow
```

Busca en los logs:
- `Invoking Bedrock with inference profile` → Llamada a Bedrock
- `Few-shot examples loaded` → Ejemplos de entrenamiento
- `RAG context retrieved` → Informes anteriores del trabajador
- `Classification result` → Resultado final

**Presiona Ctrl+C para salir del modo follow**

---

#### Paso 3: Verificar resultado en Aurora (2 min)

```bash
# Ver el informe clasificado
aws rds-data execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database $DATABASE_NAME \
  --sql "SELECT id, nivel_riesgo, justificacion_riesgo FROM informes_medicos WHERE id = 1" \
  | python3 -m json.tool
```

**✅ El informe ahora tiene:**
- `nivel_riesgo`: BAJO, MEDIO o ALTO
- `justificacion_riesgo`: Explicación detallada

**Nota:** El output de RDS Data API es JSON con formato especial. Busca los valores en `stringValue` dentro de `records`.

---

### Parte 3: Entender Cómo Funciona (10 min)

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
  --cli-binary-format raw-in-base64-out \
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
  --cli-binary-format raw-in-base64-out \
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
  --cli-binary-format raw-in-base64-out \
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
  --cli-binary-format raw-in-base64-out \
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

Bienvenido al Día 2 del workshop. Hoy exploraremos capacidades avanzadas de IA que llevan el sistema al siguiente nivel:

**Objetivos del Día 2:**
- 🔍 Entender búsqueda semántica con embeddings vectoriales (RAG avanzado)
- 📧 Generar emails personalizados según nivel de riesgo
- 🔒 Comprender consideraciones de privacidad médica
- 🎨 Experimentar con prompts y modelos de IA

**Estructura:**
- ⏱️ **10 min** - Setup: Despliegue de AI Stacks del Día 2
- ⏱️ **40 min** - Módulo 3: RAG Avanzado con Embeddings Vectoriales
- ⏱️ **40 min** - Módulo 4: Emails Personalizados
- ⏱️ **20 min** - Integración y Discusión
- ⏱️ **10 min** - Experimentación Libre

---

## 🚀 Setup del Día 2 (10 minutos)

### Paso 1: Desplegar AI Stacks del Día 2

```bash
# Asegúrate de estar en el directorio CDK
cd ~/pulsosalud-immersion-day/cdk

# Configurar email verificado (reemplaza con tu email)
export VERIFIED_EMAIL="tu-email@example.com"

# Desplegar AI Stacks del Día 2
# Nota: AIRAGStack ya fue desplegado en el Día 1 como dependencia
npx cdk deploy $PARTICIPANT_PREFIX-AIEmailStack --require-approval never --context verifiedEmail=$VERIFIED_EMAIL
```

**⚠️ IMPORTANTE:** Reemplaza `tu-email@example.com` con un email que puedas verificar.

**Recursos que se desplegarán:**
- **AIEmailStack**: Lambda para generar y enviar emails personalizados

**Tiempo estimado:** 3-5 minutos

**Nota:** El AIRAGStack (embeddings) ya fue desplegado en el Día 1 como dependencia de los otros stacks.

### Paso 2: Verificar Despliegue

El despliegue mostrará los outputs al finalizar:

```
✅ participant-X-AIEmailStack

Outputs:
participant-X-AIEmailStack.SendEmailLambdaName = participant-X-send-email
participant-X-AIEmailStack.VerifiedEmail = tu@email.com
```

### Paso 3: Verificar Email en SES

Antes de poder enviar emails, debes verificar tu email en Amazon SES:

```bash
# Verificar tu email en SES
aws ses verify-email-identity --email-address $VERIFIED_EMAIL

# Verificar estado
aws ses list-identities
```

---

## 🔍 Módulo 3: RAG Avanzado con Embeddings Vectoriales (40 min)

### Objetivo

Entender por qué necesitamos embeddings vectoriales para búsqueda semántica y cómo implementarlos.

### Parte 1: ¿Por qué SQL no es suficiente? (10 min)

#### El Problema con SQL

En el Día 1, usamos SQL para buscar informes del MISMO trabajador:

```sql
SELECT * FROM informes_medicos 
WHERE trabajador_id = 123
```

**Limitaciones:**
- ❌ Solo busca coincidencias EXACTAS
- ❌ No entiende sinónimos ("dolor lumbar" ≠ "molestias en espalda")
- ❌ Trabajadores nuevos = Sin contexto histórico
- ❌ No puede encontrar casos SIMILARES de otros trabajadores

#### Demostración: SQL vs Embeddings

**Opción 1: Usar el script de demostración (recomendado)**

```bash
# 1. Navegar al directorio de scripts de ejemplo
cd ~/pulsosalud-immersion-day/scripts/examples

# 2. Configurar variables de entorno (si no lo hiciste antes)
# El script detecta automáticamente tu prefijo de participante
source setup-env-vars-cloudshell.sh

# 3. Hacer el script ejecutable
chmod +x demo-rag-comparison.sh

# 4. Ejecutar demo de comparación
./demo-rag-comparison.sh
```

**💡 Tip:** El script `setup-env-vars-cloudshell.sh` detecta automáticamente tu prefijo extrayendo el número de tu usuario IAM (ej: `workshop-user-5` → `participant-5`).

Este script muestra:
1. **Búsqueda SQL**: Solo encuentra informes del mismo trabajador
2. **Búsqueda con Embeddings**: Encuentra casos similares de CUALQUIER trabajador
3. **Tabla comparativa**: SQL vs Embeddings
4. **Ejemplo concreto**: Por qué SQL no puede entender similitud semántica

**Opción 2: Comandos manuales (si el script no funciona)**

```bash
# 1. Buscar informes del mismo trabajador (SQL - Día 1)
aws rds-data execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database $DATABASE_NAME \
  --sql "SELECT * FROM informes_medicos WHERE trabajador_id = 1 ORDER BY fecha_examen DESC"

# 2. Verificar embeddings disponibles
aws rds-data execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database $DATABASE_NAME \
  --sql "SELECT COUNT(*) FROM informes_embeddings"

# 3. Buscar casos similares (Embeddings - Día 2)
# Nota: Requiere que hayas generado embeddings primero
aws rds-data execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database $DATABASE_NAME \
  --sql "SELECT im.id, im.trabajador_nombre, 1 - (ie1.embedding <=> ie2.embedding) as similarity FROM informes_medicos im JOIN informes_embeddings ie1 ON im.id = ie1.informe_id CROSS JOIN informes_embeddings ie2 WHERE ie2.informe_id = 1 AND im.id != 1 ORDER BY similarity DESC LIMIT 5"
```

**Pregunta clave**: ¿Cómo buscarías con SQL casos similares a "dolor lumbar por postura prolongada"?

**Respuesta**: No puedes. SQL no entiende que:
- "dolor lumbar" ≈ "molestias en espalda baja"
- "postura prolongada" ≈ "largas jornadas sentado"

### Parte 2: ¿Qué son los Embeddings? (10 min)

**Embeddings** son representaciones vectoriales de texto que capturan el significado semántico.

```python
# Texto original
"Dolor lumbar ocasional por postura prolongada en cabina"

# Embedding (vector de 1024 dimensiones)
[0.123, -0.456, 0.789, ..., 0.234]
```

**Ventaja clave**: Textos con significado similar tienen vectores cercanos en el espacio vectorial.

**Ejemplo**:
- "Dolor lumbar por postura prolongada" → Vector A
- "Molestias en espalda baja por jornadas sentado" → Vector B
- Similitud de coseno (A, B) = 0.89 (muy similar!)

**Modelo usado**: Amazon Titan Embeddings v2
- Dimensiones: 1024
- Optimizado para español e inglés
- Captura contexto y sinónimos

### Parte 3: Generar Embeddings (10 min)

#### Paso 1: Generar Embedding para un Informe

```bash
# Invocar Lambda para generar embedding
aws lambda invoke \
  --function-name $PARTICIPANT_PREFIX-generate-embeddings \
  --cli-binary-format raw-in-base64-out \
  --payload '{"informe_id": 1}' \
  embeddings_response.json

# Ver resultado
cat embeddings_response.json | python3 -m json.tool
```

**Output esperado**:
```
========================================
  Resultado de Generación de Embeddings
========================================

Estado: ÉXITO
Informe ID: 1
Dimensiones del vector: 1024
✓ Vector tiene las dimensiones correctas (1024)

Tiempo de procesamiento: 1.8s

Preview del contenido usado:
Trabajador: Juan Pérez
Tipo de examen: Ocupacional Anual
Observaciones: Dolor lumbar ocasional...

✓ Embedding almacenado correctamente en la base de datos
```

#### Paso 2: Verificar en Base de Datos

```bash
# Ver embeddings generados
aws rds-data execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database $DATABASE_NAME \
  --sql "SELECT ie.informe_id, im.trabajador_nombre, im.tipo_examen, LENGTH(ie.embedding::text) as embedding_size FROM informes_embeddings ie JOIN informes_medicos im ON ie.informe_id = im.id LIMIT 5" \
  | python3 -m json.tool
```

**Qué verificar:**
- ✅ `informe_id` del informe que procesaste
- ✅ `embedding_size` debería ser grande (el vector tiene 1024 dimensiones)

### Parte 4: Buscar Casos Similares (10 min)

#### Paso 1: Ejecutar Búsqueda de Similitud

```bash
# Buscar los 5 informes más similares al informe ID 1
aws rds-data execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database $DATABASE_NAME \
  --sql "SELECT im.id, im.trabajador_nombre, im.tipo_examen, im.nivel_riesgo, ROUND((1 - (ie1.embedding <=> ie2.embedding))::numeric, 4) as similarity FROM informes_medicos im JOIN informes_embeddings ie1 ON im.id = ie1.informe_id CROSS JOIN informes_embeddings ie2 WHERE ie2.informe_id = 1 AND im.id != 1 ORDER BY similarity DESC LIMIT 5" \
  | python3 -m json.tool
```

**Output esperado**:
```
========================================
  Resultados de Búsqueda de Similitud
========================================

Encontrados 5 informes similares
Tiempo de búsqueda: 45.23 ms

[1] Trabajador: Pedro García (Informe #3)
    Similitud: 0.8934
    Tipo examen: Ocupacional Anual
    Nivel riesgo: MEDIO
    Observaciones: Molestias en espalda baja por jornadas...

[2] Trabajador: Carlos López (Informe #7)
    Similitud: 0.8521
    Tipo examen: Ocupacional Periódico
    Nivel riesgo: MEDIO
    Observaciones: Dolor lumbar por vibración constante...

[...]

--- Estadísticas ---
Similitud promedio: 0.8234
Similitud máxima: 0.8934
Similitud mínima: 0.7456
```

#### Paso 2: Entender la Query

La query usa el operador `<=>` de pgvector:

```sql
SELECT 
    im.id,
    t.nombre as trabajador,
    im.tipo_examen,
    1 - (ie1.embedding <=> ie2.embedding) as similarity_score
FROM informes_medicos im
JOIN informes_embeddings ie1 ON im.id = ie1.informe_id
CROSS JOIN informes_embeddings ie2
WHERE ie2.informe_id = 1  -- Informe de referencia
  AND im.id != 1          -- Excluir el mismo informe
ORDER BY similarity_score DESC
LIMIT 5;
```

**Conceptos clave**:
- `<=>`: Operador de distancia de coseno (0 = idénticos, 2 = opuestos)
- `1 - distancia`: Convertir distancia en similitud (1 = idénticos, 0 = no relacionados)
- `CROSS JOIN`: Comparar con todos los embeddings

### Parte 5: Consideraciones de Privacidad (10 min)

#### IMPORTANTE: RAG es Herramienta INTERNA del Médico

**✅ Para el MÉDICO (Uso Interno)**:
- SÍ puede ver casos similares anonimizados
- SÍ puede usar patrones históricos para decisiones
- SÍ puede anticipar riesgos basado en casos similares

**❌ Para el EMPLEADO (Email/Comunicación)**:
- NO puede recibir información de otros empleados
- NO puede saber que existen casos similares
- SÍ puede recibir mejores recomendaciones (sin mencionar origen)

**Ejemplo - Vista del Médico (Correcto)**:
```
Informe: Juan Pérez
Casos similares encontrados (5):
1. Trabajador #145 (similarity: 0.89)
   - Perfil similar, mejoró con pausas ergonómicas
2. Trabajador #203 (similarity: 0.85)
   - Perfil similar, requirió seguimiento cardiológico
```

**Ejemplo - Email al Empleado (Correcto)**:
```
Estimado Juan,
Tu examen muestra presión arterial elevada.

Recomendaciones:
1. Consulta con cardiólogo en 2 semanas
2. Pausas ergonómicas cada 2 horas

[NO se menciona que hay casos similares]
[NO se comparte información de otros empleados]
```

**Documentación completa**: Ver `docs/RAG_PRIVACY.md`

---

## 📧 Módulo 4: Emails Personalizados (40 min)

### Objetivo

Generar emails personalizados según el nivel de riesgo del trabajador, respetando la privacidad médica.

### Parte 1: Personalización por Nivel de Riesgo (10 min)

#### ¿Por qué Personalizar Emails?

Cada nivel de riesgo requiere un tono y contenido diferente:

| Nivel | Tono | Objetivo | Urgencia |
|-------|------|----------|----------|
| **ALTO** | Serio pero tranquilizador | Acción inmediata | 48-72 horas |
| **MEDIO** | Informativo y preventivo | Seguimiento programado | 1-2 semanas |
| **BAJO** | Positivo y motivacional | Mantener buenos hábitos | Próximo examen anual |

#### Prompts Específicos por Nivel

Tenemos 3 prompts diferentes:

**1. Email Riesgo ALTO** (`prompts/email-alto-riesgo.txt`):
```
Eres un asistente médico especializado en comunicación urgente.

CONTEXTO: El empleado tiene resultados que requieren atención inmediata.
TONO: Serio pero tranquilizador, sin generar pánico.

ESTRUCTURA:
- Asunto: "Importante: Resultados de tu examen - Seguimiento requerido"
- Explicación clara de hallazgos
- Importancia del seguimiento INMEDIATO
- Recomendaciones urgentes con plazos específicos
- Información de contacto

IMPORTANTE - PRIVACIDAD:
- NUNCA menciones casos de otros empleados
- NUNCA digas "encontramos casos similares"
- Solo usa datos del trabajador actual
```

**2. Email Riesgo MEDIO** (`prompts/email-medio-riesgo.txt`):
```
Eres un asistente médico especializado en comunicación preventiva.

CONTEXTO: El empleado tiene resultados que requieren monitoreo preventivo.
TONO: Informativo, preventivo y motivacional.

ESTRUCTURA:
- Asunto: "Resultados de tu examen - Recomendaciones preventivas"
- Resumen positivo con áreas de atención
- Importancia de la prevención
- Recomendaciones de estilo de vida
- Plan de seguimiento en 1-2 semanas
```

**3. Email Riesgo BAJO** (`prompts/email-bajo-riesgo.txt`):
```
Eres un asistente médico especializado en comunicación positiva.

CONTEXTO: El empleado tiene resultados excelentes.
TONO: Positivo, felicitatorio y motivacional.

ESTRUCTURA:
- Asunto: "¡Excelentes resultados en tu examen!"
- Felicitación por buenos resultados
- Reconocimiento de buenos hábitos
- Tips para mantener la salud
- Recordatorio de próximo examen
```

### Parte 2: Generar y Enviar Email (15 min)

#### Paso 1: Generar Email para un Informe

```bash
# Generar y enviar email para el informe ID 1
aws lambda invoke \
  --function-name $PARTICIPANT_PREFIX-send-email \
  --cli-binary-format raw-in-base64-out \
  --payload '{"informe_id": 1}' \
  email_response.json

# Ver resultado
cat email_response.json | python3 -m json.tool
```

**Output esperado**:
```
========================================
  Resultado de Envío de Email
========================================

Estado: ÉXITO
Informe ID: 1
Destinatario: trabajador@empresa.com
Nivel de riesgo: ALTO
Message ID (SES): <mensaje-id-ses>

Tiempo de procesamiento: 2.1s

========================================
  Preview del Email Generado
========================================

Asunto: Importante: Resultados de tu examen médico - Seguimiento requerido

Cuerpo (primeros 500 caracteres):
Estimado Juan Pérez,

Te escribo en relación a tu examen médico ocupacional realizado 
el 15 de noviembre de 2024.

RESULTADOS:
• Presión arterial: 165/105 mmHg (significativamente elevada)
• IMC: 31.2 (obesidad grado I)
...

✓ Base de datos actualizada correctamente
  Fecha envío: 2024-12-04 10:30:00
  Message ID: <mensaje-id-ses>
```

#### Paso 2: Verificar Email Recibido

1. Revisa tu bandeja de entrada
2. Busca el email con el asunto correspondiente
3. Verifica que el tono es apropiado para el nivel de riesgo
4. Confirma que NO menciona información de otros empleados

#### Paso 3: Verificar en Base de Datos

```bash
# Ver informes con emails enviados
aws rds-data execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database $DATABASE_NAME \
  --sql "SELECT im.id, im.trabajador_nombre, im.nivel_riesgo, im.email_enviado, im.fecha_email_enviado, im.email_message_id FROM informes_medicos WHERE im.email_enviado = TRUE" \
  | python3 -m json.tool
```

**Qué verificar:**
- ✅ `email_enviado` = true
- ✅ `fecha_email_enviado` tiene timestamp
- ✅ `email_message_id` tiene el ID de SES

### Parte 3: Privacidad Médica en Emails (10 min)

#### CRÍTICO: Emails NO Deben Violar Privacidad

**Regla de Oro**: Los empleados NUNCA deben recibir información de otros empleados.

#### ✅ Email CORRECTO (Riesgo ALTO)

```
Estimado Juan Pérez,

Tu examen médico ocupacional del 15 de noviembre muestra:

RESULTADOS:
• Presión arterial: 165/105 mmHg (significativamente elevada)
• IMC: 31.2 (obesidad grado I)

RECOMENDACIONES URGENTES:
1. Consulta con cardiólogo en las próximas 48-72 horas
2. Exámenes adicionales requeridos
3. Cambios inmediatos en estilo de vida

Estas recomendaciones están basadas en las mejores prácticas 
médicas para tu perfil de salud y tipo de trabajo.

[✓ Solo datos del empleado actual]
[✓ NO menciona casos similares]
[✓ Recomendaciones sin revelar origen]
```

#### ❌ Email INCORRECTO (Viola privacidad)

```
Estimado Juan,

Tu presión arterial (165/105) es similar a la de otros 4 empleados.

Hemos encontrado casos similares:
• Pedro García tuvo presión similar y mejoró con...
• Carlos López también requirió seguimiento...

[❌ NUNCA mencionar otros empleados]
[❌ NUNCA compartir información de terceros]
[❌ NUNCA revelar que se usó RAG]
```

#### Frases Prohibidas

NUNCA usar en emails:
- "Encontramos casos similares al tuyo..."
- "Otros empleados con tu perfil..."
- "Basándonos en casos previos de..."
- "Comparado con tus compañeros..."
- "El promedio de los empleados..."

#### Frases Correctas

SÍ usar en emails:
- "Basándonos en las mejores prácticas médicas..."
- "Estas recomendaciones están diseñadas para tu perfil..."
- "Según las guías clínicas actuales..."
- "Para tu tipo de trabajo y perfil de salud..."

**Documentación completa**: Ver `docs/EMAIL_EXAMPLES.md`

### Parte 4: Verificar Emails en Amazon SES (5 min)

#### Paso 1: Acceder a SES Console

1. Abre AWS Console
2. Navega a Amazon SES
3. Ve a "Email sending" → "Sending statistics"

#### Paso 2: Verificar Estadísticas

Verás:
- Emails enviados
- Emails entregados
- Bounces (rebotes)
- Complaints (quejas)

#### Paso 3: Ver Detalles de un Email

```bash
# Ver estadísticas de envío de SES
aws ses get-send-statistics
```

---

## 🔗 Integración y Discusión (20 min)

### Cómo los Módulos Trabajan Juntos

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUJO COMPLETO DÍA 2                     │
└─────────────────────────────────────────────────────────────┘

1. CLASIFICACIÓN (Día 1)
   └─> Informe clasificado como ALTO/MEDIO/BAJO

2. GENERACIÓN DE EMBEDDINGS (Día 2 - Módulo 3)
   └─> Vector de 1024 dimensiones almacenado en BD

3. BÚSQUEDA DE SIMILITUD (Día 2 - Módulo 3)
   └─> Médico ve 5 casos similares (USO INTERNO)
   └─> Contexto para mejores decisiones

4. GENERACIÓN DE EMAIL (Día 2 - Módulo 4)
   └─> Email personalizado según nivel de riesgo
   └─> SIN mencionar casos similares (PRIVACIDAD)
   └─> Empleado recibe mejores recomendaciones

5. ENVÍO VIA SES (Día 2 - Módulo 4)
   └─> Email entregado al empleado
   └─> Tracking con Message ID
```

### Casos de Uso Reales

#### Caso 1: Trabajador Nuevo con Riesgo Alto

**Sin RAG**:
- Médico no tiene contexto histórico
- Recomendaciones genéricas
- Seguimiento estándar

**Con RAG**:
- Sistema encuentra 5 casos similares
- Médico ve que 4/5 mejoraron con pausas ergonómicas
- Médico ve que 1/5 requirió seguimiento cardiológico
- **Recomendación mejorada**: Pausas ergonómicas + seguimiento preventivo
- **Email al empleado**: Solo recomendaciones, sin mencionar casos similares

#### Caso 2: Trabajador con Historial

**Sin RAG**:
- Médico revisa manualmente informes anteriores
- Proceso lento y propenso a errores

**Con RAG**:
- Sistema automáticamente encuentra informes anteriores
- Médico ve tendencias (mejorando/empeorando)
- Recomendaciones basadas en evolución
- **Email al empleado**: Menciona su propia evolución, no otros casos

### Mejoras Futuras

Ideas para explorar después del workshop:

1. **RAG en Emails**: Usar casos similares para generar recomendaciones (sin violarlas privacidad)
2. **Análisis de Tendencias**: Identificar patrones ocupacionales por tipo de trabajo
3. **Alertas Proactivas**: Notificar cuando un trabajador se acerca a umbrales de riesgo
4. **Dashboard para Médicos**: Visualizar casos similares y tendencias
5. **Feedback Loop**: Aprender de qué recomendaciones funcionan mejor

---

## 🎨 Experimentación Libre (10 min)

### Ideas para Experimentar

#### 1. Modificar Prompts de Emails

```bash
# Editar prompt (usa nano en CloudShell)
nano prompts/email-alto-riesgo.txt

# Cambiar tono (más empático, más técnico, más simple)
# Guardar cambios: Ctrl+X, Y, Enter

# Re-desplegar el stack para aplicar cambios
cd ~/pulsosalud-immersion-day/cdk
npx cdk deploy $PARTICIPANT_PREFIX-AIEmailStack --require-approval never

# Probar nuevo email
cd ~/pulsosalud-immersion-day/scripts/examples
aws lambda invoke \
  --function-name $PARTICIPANT_PREFIX-send-email \
  --cli-binary-format raw-in-base64-out \
  --payload '{"informe_id": 1}' \
  email_test.json

cat email_test.json | python3 -m json.tool
```

#### 2. Comparar Similarity Scores

```bash
# Generar embeddings para varios informes
for i in {1..5}; do
  echo "=== Generando embedding para Informe $i ==="
  aws lambda invoke \
    --function-name $PARTICIPANT_PREFIX-generate-embeddings \
    --cli-binary-format raw-in-base64-out \
    --payload "{\"informe_id\": $i}" \
    embedding_$i.json
  cat embedding_$i.json | python3 -m json.tool
  echo ""
done

# Buscar similares para cada uno
for i in {1..5}; do
  echo "=== Similares para Informe $i ==="
  aws lambda invoke \
    --function-name $PARTICIPANT_PREFIX-generate-embeddings \
    --cli-binary-format raw-in-base64-out \
    --payload "{\"informe_id\": $i, \"action\": \"similarity_search\", \"top_k\": 5}" \
    similarity_$i.json
  cat similarity_$i.json | python3 -m json.tool
  echo ""
done

# Analizar: ¿Qué hace que dos casos sean similares?
```

#### 3. Validar Privacidad

```bash
# Generar varios emails y validar privacidad
for i in {1..5}; do
    echo ""
    echo "=== Email para Informe $i ==="
    aws lambda invoke \
      --function-name $PARTICIPANT_PREFIX-send-email \
      --cli-binary-format raw-in-base64-out \
      --payload "{\"informe_id\": $i}" \
      email_$i.json
    
    # Revisar manualmente el contenido:
    echo "Revisando email_$i.json:"
    cat email_$i.json | python3 -m json.tool | grep -A 20 "body"
    
    # Verificar:
    # - ¿Menciona otros empleados? ❌
    # - ¿Dice "casos similares"? ❌
    # - ¿Solo datos del empleado actual? ✅
    echo "---"
done
```

### Recursos para Experimentación

- **Guía de Experimentación**: `docs/EXPERIMENTATION_GUIDE.md`
- **Ejemplos de Prompts**: `docs/PROMPT_EXAMPLES.md`
- **Ejemplos de Emails**: `docs/EMAIL_EXAMPLES.md`
- **Privacidad RAG**: `docs/RAG_PRIVACY.md`

---

## 📋 Resumen del Día 2

### Lo que Aprendiste

✅ **RAG Avanzado con Embeddings**:
- Por qué SQL no es suficiente para búsqueda semántica
- Cómo funcionan los embeddings vectoriales
- Búsqueda de similitud con pgvector
- Consideraciones de privacidad médica

✅ **Emails Personalizados**:
- Personalización por nivel de riesgo
- Prompts específicos para cada nivel
- Generación y envío con Amazon SES
- Validación de privacidad en emails

✅ **Integración**:
- Cómo los módulos trabajan juntos
- Flujo completo del sistema
- Casos de uso reales
- Mejoras futuras

### Próximos Pasos

1. **Experimenta** con los scripts y prompts
2. **Revisa** la documentación adicional en `docs/`
3. **Comparte** tus descubrimientos con otros participantes
4. **Considera** cómo aplicar esto en tu organización

### Recursos Adicionales

- [Amazon Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [pgvector Documentation](https://github.com/pgvector/pgvector)
- [Amazon SES Documentation](https://docs.aws.amazon.com/ses/)
- [Prompt Engineering Guide](https://www.promptingguide.ai/)

---
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

# 2. Verifica que las variables de entorno están configuradas
echo $CLUSTER_ARN
echo $SECRET_ARN

# 3. Si están vacías, configúralas nuevamente (ver Módulo 1, Parte 1, Paso 1)

# 4. Si el problema persiste, contacta al instructor
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
  --cli-binary-format raw-in-base64-out \
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
  --cli-binary-format raw-in-base64-out \
  --payload '{"informe_id": 1}' \
  response.json

# 2. Verifica que se clasificó correctamente
cat response.json

# 3. Ahora genera el resumen
aws lambda invoke \
  --function-name participant-1-generate-summary \
  --cli-binary-format raw-in-base64-out \
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
export CLUSTER_ARN=$(aws cloudformation describe-stacks \
  --stack-name participant-1-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`DatabaseClusterArn`].OutputValue' \
  --output text)

export SECRET_ARN=$(aws cloudformation describe-stacks \
  --stack-name participant-1-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`DatabaseSecretArn`].OutputValue' \
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
  --cli-binary-format raw-in-base64-out \
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
  --cli-binary-format raw-in-base64-out \
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
