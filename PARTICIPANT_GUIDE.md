# 🎓 Guía para Participantes - Medical Reports Automation Workshop

Bienvenido al workshop de **Automatización de Informes Médicos con AWS y Amazon Bedrock**. Esta guía te llevará paso a paso a través de la implementación de un sistema completo de IA Generativa.

## 📅 Estructura del Workshop

**Duración Total:** 3 horas 15 minutos (dividido en 2 días)

### Día 1 (1h 15min)
- ⏱️ **5 min** - Setup inicial y despliegue del sistema legacy
- ⏱️ **30 min** - Módulo 1: Extracción de PDFs con Textract y Bedrock
- ⏱️ **30 min** - Módulo 2: Prompt Engineering y experimentación
- ⏱️ **10 min** - Checkpoint Día 1 y Q&A

### Día 2 (2h)
- ⏱️ **30 min** - Módulo 3: RAG con embeddings vectoriales
- ⏱️ **30 min** - Módulo 4: Clasificación de riesgo con few-shot learning
- ⏱️ **30 min** - Módulo 5: Generación de resúmenes y emails personalizados
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

El instructor te habrá proporcionado:

1. **Acceso a AWS Console:**
   - Usuario: `workshop-user-X` (donde X es tu número asignado)
   - Contraseña temporal
   - Link: https://console.aws.amazon.com/

2. **Tu PARTICIPANT_PREFIX:** `participant-X` (ej: `participant-1`, `participant-2`)

3. **Email verificado:** El email del instructor (el mismo para todos los participantes)

4. **Link al repositorio** del workshop

**Ejemplo de información que recibirás:**
- Usuario AWS: `workshop-user-1`
- PARTICIPANT_PREFIX: `participant-1`
- Email del instructor: `instructor@example.com` ← **Este es el email del instructor, NO tu email personal**

**⚠️ IMPORTANTE:** El instructor ya desplegó la infraestructura base (VPC, Aurora, S3) antes del workshop. Tú solo desplegarás los AI Stacks durante esta sesión.

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

### Paso 3: Instalar AWS CDK

CloudShell no tiene CDK pre-instalado. Instálalo localmente en el proyecto:

```bash
# Instalar CDK localmente en el proyecto
cd cdk
npm install

# Verificar instalación (usar npx para ejecutar)
npx cdk --version
```

**Nota:** Usaremos `npx cdk` en lugar de solo `cdk` para ejecutar comandos CDK.

**Tiempo:** ~2-3 minutos

### Paso 4: Desplegar AI Stacks

El instructor ya desplegó:
- ✅ VPC compartida
- ✅ Aurora Serverless v2 (tu base de datos)
- ✅ S3 Bucket (tu almacenamiento)
- ✅ API Gateway y Lambdas Legacy

Tú solo necesitas desplegar los **AI Stacks** (las Lambdas de procesamiento de IA):

```bash
# Volver al directorio raíz del proyecto
cd ..

# Dar permisos de ejecución al script (necesario en CloudShell)
chmod +x ./scripts/participant-deploy-ai.sh

# Ejecutar el script automatizado
./scripts/participant-deploy-ai.sh participant-1 instructor@example.com
```

Ver script: [`scripts/participant-deploy-ai.sh`](scripts/participant-deploy-ai.sh) o [`scripts/participant-deploy-ai.ps1`](scripts/participant-deploy-ai.ps1) (PowerShell)

**Reemplaza:**
- `participant-1` con tu PARTICIPANT_PREFIX asignado
- `instructor@example.com` con el **email del instructor** (proporcionado por el instructor)

**Tiempo estimado:** 10-15 minutos ⏱️

**Recursos que se desplegarán:**
1. **AIExtractionStack** - Extracción de PDFs con Textract + Bedrock
2. **AIRAGStack** - Embeddings vectoriales con Titan
3. **AIClassificationStack** - Clasificación de riesgo con Nova Pro
4. **AISummaryStack** - Generación de resúmenes con Nova Pro
5. **AIEmailStack** - Emails personalizados con Nova Pro + SES

### Paso 5: Verificar Despliegue

Mientras se despliega, puedes ver el progreso en:
- **CloudShell:** Verás el progreso de cada stack en la terminal
- **Consola AWS:** Abre otra pestaña y ve a CloudFormation para ver el progreso visual

Una vez completado, verás los outputs de cada stack con los ARNs de las Lambdas.

## 📚 Día 1: Extracción y Prompt Engineering

**✅ Tu infraestructura ya está lista:** Si completaste el Setup Inicial, todos tus AI Stacks ya están desplegados y listos para usar.

### Módulo 1: Extracción de PDFs con Textract y Bedrock (25 min)

**Objetivo:** Procesar tu primer PDF junto con el instructor y ver el sistema funcionando en tiempo real.

**Conceptos Clave:**
```
Textract = "Lee" el texto del PDF (como un escáner inteligente)
Bedrock = "Entiende" qué significa cada dato (como un experto médico)

Juntos convierten un PDF en datos estructurados.
```

---

### Parte 1: Procesar un PDF (10 min)

El instructor y tú van a subir un PDF al mismo tiempo y ver cómo se procesa.

#### Paso 1: Obtener el nombre de tu bucket (1 min)

```bash
# Reemplaza participant-1 con tu prefijo
# En CloudShell, ejecuta:
aws cloudformation describe-stacks \
  --stack-name participant-1-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' \
  --output text
```

**✅ Guarda este nombre**, lo vas a usar en el siguiente paso.

---

#### Paso 2: Subir tu PDF (2 min)

```bash
# Reemplaza [TU-BUCKET] con el nombre que obtuviste
aws s3 cp sample_data/informe_alto_riesgo.pdf \
  s3://[TU-BUCKET]/external-reports/

# Confirmar que se subió
aws s3 ls s3://[TU-BUCKET]/external-reports/
```

---

#### Paso 3: Ver los logs en tiempo real (5 min)

**⏱️ Espera 1-2 minutos** después de subir el PDF para que la Lambda se ejecute automáticamente.

**Opción A: Desde CloudShell**
```bash
# Reemplaza participant-1 con tu prefijo
aws logs tail /aws/lambda/participant-1-extract-pdf --follow
```

**Opción B: Desde la Consola AWS**
1. Abre otra pestaña → CloudWatch
2. Log groups → `/aws/lambda/participant-1-extract-pdf`
3. Click en el log stream más reciente

```
"Aquí vemos que la Lambda se activó..."
→ Busca en tus logs: Lambda invocation started

"Textract está extrayendo el texto del PDF..."
→ Busca en tus logs: Textract completed

"Ahora Bedrock está estructurando esos datos..."
→ Busca en tus logs: Bedrock response received

"Y finalmente se está guardando en Aurora"
→ Busca en tus logs: Data inserted successfully
```

**✅ Si ves estos 4 mensajes: ¡Tu PDF se procesó correctamente!**

---

#### Paso 4: Verificar resultado en Aurora (2 min)

**👉 El instructor dirá: "Verifiquemos que los datos se guardaron"**

El instructor mostrará cómo consultar Aurora. Tú puedes hacer lo mismo (opcional):

```sql
-- El instructor mostrará esta consulta
SELECT 
  trabajador_nombre,
  presion_arterial,
  nivel_riesgo,
  fecha_examen
FROM informes_medicos 
WHERE origen='EXTERNO'
ORDER BY fecha_creacion DESC
LIMIT 1;
```

**💡 Punto clave:** El PDF se convirtió en datos estructurados que podemos consultar.

---

### Parte 2: Entender el Código (8 min)

**🎯 Ahora que viste cómo funciona, veamos el código**

**👉 El instructor dirá: "Déjenme mostrarles el código que hace esto posible"**

El instructor va a abrir `lambda/ai/extract_pdf/index.py` y explicar los 3 pasos. Tú puedes seguir abriendo el mismo archivo en CloudShell o en tu editor local.

**Paso 1: Textract Extrae Texto (2 min)**

```python
# Textract lee el PDF y extrae TODO el texto
response = textract_client.analyze_document(
    Document={'S3Object': {'Bucket': bucket, 'Name': key}},
    FeatureTypes=['TABLES', 'FORMS']
)
```

**💡 Mientras el instructor explica:**
- Textract lee el PDF y extrae TODO el texto, incluyendo tablas
- Pero solo extrae, no entiende qué significa cada cosa

---

**Paso 2: Bedrock Estructura Datos (4 min)**

```python
# Bedrock ENTIENDE el contexto y estructura en JSON
bedrock_response = bedrock_runtime.invoke_model(
    modelId='us.amazon.nova-pro-v1:0',
    body=json.dumps({
        "messages": [{"role": "user", "content": prompt}],
        "inferenceConfig": {
            "temperature": 0.1,  # Baja para precisión
            "maxTokens": 2000
        }
    })
)
```

**💡 Mientras el instructor explica:**
- Le decimos a Bedrock: "Toma este texto y extrae estos campos en JSON"
- Bedrock ENTIENDE que '140/90' es presión arterial, no un teléfono
- Temperature 0.1 = respuestas más precisas y consistentes

---

**Paso 3: Guardar en Aurora (2 min)**

```python
# Insertar en base de datos
cursor.execute("""
    INSERT INTO informes_medicos 
    (trabajador_nombre, presion_arterial, ...)
    VALUES (%s, %s, ...)
""", (datos['trabajador_nombre'], datos['presion_arterial'], ...))
```

**💡 Mientras el instructor explica:**
- Finalmente guardamos en la base de datos
- Ahora los datos están listos para consultar y analizar

---

### Parte 3: Ejercicio Individual (7 min)

**🎯 Ahora procesa otro PDF por tu cuenta**

**👉 El instructor dirá: "Ahora cada uno va a procesar un PDF diferente"**

#### Tu tarea:

1. **Sube otro PDF** (usa `informe_medio_riesgo.pdf` esta vez)
   ```bash
   aws s3 cp sample_data/informe_medio_riesgo.pdf \
     s3://[TU-BUCKET]/external-reports/
   ```

2. **Ve los logs** para confirmar que se procesó
   ```bash
   aws logs tail /aws/lambda/participant-1-extract-pdf --follow
   ```

3. **Levanta la mano virtual** o escribe en el chat cuando termines

**✅ Criterio de éxito:**
- Ves "Data inserted successfully" en los logs
- El instructor confirma que todos completaron

**❌ Si algo falla:**
- Verifica que el PDF está en `external-reports/`
- Verifica que usaste tu prefijo correcto
- Escribe en el chat o pide ayuda al instructor

---

### 🎓 Resumen del Módulo 1

**Lo que lograste:**
- ✅ Viste el sistema funcionando en tiempo real
- ✅ Entendiste cómo Textract y Bedrock trabajan juntos
- ✅ Procesaste tu primer PDF automáticamente
- ✅ Verificaste que los datos se guardaron en Aurora

**Concepto clave:** 
> Textract + Bedrock = PDF no estructurado → Datos estructurados utilizables

**Próximo módulo:** Vamos a aprender cómo mejorar la calidad de extracción con Prompt Engineering.

---

### ❓ Preguntas Frecuentes del Módulo 1

**P: ¿Por qué no veo logs inmediatamente?**
R: Los logs pueden tardar 1-2 minutos en aparecer. Ten paciencia.

**P: ¿Qué pasa si subo el PDF a otra carpeta?**
R: La Lambda solo se activa con PDFs en `external-reports/`. Otros folders no funcionarán.

**P: ¿Puedo subir mis propios PDFs?**
R: Sí, pero deben ser informes médicos similares a los ejemplos para que el prompt funcione bien.

**P: ¿Cuánto cuesta procesar un PDF?**
R: Aproximadamente $0.02-0.05 USD por PDF (Textract + Bedrock + almacenamiento).

---

### Módulo 2: Prompt Engineering y Experimentación (30 min)

#### Objetivo
Entender cómo iterar y mejorar prompts para obtener mejores resultados.

#### Ejercicio 1: Comparar Versiones de Prompts

Revisa las 3 versiones del prompt de extracción:

**Versión 1** ([`prompts/extraction_v1.txt`](prompts/extraction_v1.txt)):
```
Extrae datos del siguiente informe médico.
```
❌ Muy vago, resultados inconsistentes

**Versión 2** ([`prompts/extraction_v2.txt`](prompts/extraction_v2.txt)):
```
Extrae los siguientes campos del informe médico:
- Nombre del trabajador
- Presión arterial
...
Devuelve en formato JSON.
```
⚠️ Mejor, pero sin ejemplos

**Versión 3** ([`prompts/extraction.txt`](prompts/extraction.txt)):
```
Eres un asistente especializado en extraer datos de informes médicos.

Extrae la siguiente información y devuélvela en formato JSON:
{
  "trabajador_nombre": "string",
  "presion_arterial": "string",
  ...
}

IMPORTANTE: 
- Si un campo no está presente, usa null
- Mantén el formato exacto del JSON
- No inventes datos
```
✅ Específico, con estructura y reglas claras

**Lección:** Los prompts específicos con ejemplos y reglas producen mejores resultados.

#### Ejercicio 2: Experimentar con Temperature

La **temperature** controla la aleatoriedad de las respuestas:
- **0.0 - 0.3**: Determinístico, preciso (ideal para extracción)
- **0.4 - 0.7**: Balanceado (ideal para resúmenes)
- **0.8 - 1.0**: Creativo, variado (ideal para contenido)

**Práctica:**

1. Abre [`lambda/ai/extract_pdf/index.py`](lambda/ai/extract_pdf/index.py)
2. Cambia `temperature: 0.1` a `temperature: 0.8`
3. Re-despliega:
   ```bash
   cd cdk
   cdk deploy AIExtractionStack
   ```
4. Sube el mismo PDF otra vez
5. Compara resultados

**Pregunta:** ¿Qué diferencias notas?

#### Ejercicio 3: Experimentar con max_tokens

El parámetro **maxTokens** limita la longitud de la respuesta:

1. Cambia `maxTokens: 2000` a `maxTokens: 500`
2. Re-despliega
3. Observa si la respuesta se corta

**Lección:** Ajusta maxTokens según la complejidad de la tarea.

---

### 🎯 Checkpoint Día 1 (10 min)

Verifica que todo funciona:

```bash
# 1. Sistema legacy desplegado
aws cloudformation describe-stacks --stack-name LegacyStack

# 2. Sistema de extracción desplegado
aws cloudformation describe-stacks --stack-name AIExtractionStack

# 3. PDF procesado correctamente
psql -h <aurora-endpoint> -U postgres -d medical_reports \
  -c "SELECT COUNT(*) FROM informes_medicos WHERE origen='EXTERNO';"

# Debería retornar al menos 1
```

**Preguntas para reflexionar:**
- ¿Cómo funciona Textract vs Bedrock?
- ¿Por qué usamos temperature baja para extracción?
- ¿Qué hace que un prompt sea efectivo?

---

## 📚 Día 2: RAG, Clasificación y Personalización

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

### Error: "Model access denied"

**Causa:** Permisos IAM insuficientes.

**Solución:**
```bash
# Verifica que tu usuario tiene permisos bedrock:InvokeModel
# Los modelos se habilitan automáticamente en la primera invocación
```

### Error: "Database connection failed"

**Causa:** Lambda no puede conectar a Aurora.

**Solución:**
```bash
# Verifica que Lambda está en la misma VPC que Aurora
# Verifica security groups
```

### Error: "Email not verified"

**Causa:** No verificaste tu email en SES.

**Solución:**
```bash
aws ses verify-email-identity --email-address tu-email@ejemplo.com
# Confirma desde el email que recibirás
```

### Error: "S3 bucket already exists"

**Causa:** Otro participante usa el mismo prefijo.

**Solución:**
```bash
# Cambia tu prefijo único en cdk/bin/app.ts
# Ejemplo: 'participant-john-2'
```

### Logs no aparecen en CloudWatch

**Solución:**
```bash
# Espera 1-2 minutos para que aparezcan
# O usa:
aws logs tail /aws/lambda/<function-name> --follow
```

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
