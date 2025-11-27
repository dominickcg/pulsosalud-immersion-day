# 👨‍🏫 Guía para Instructor - Medical Reports Automation Workshop

Esta guía proporciona todo lo necesario para impartir el workshop de **Automatización de Informes Médicos con AWS y Amazon Bedrock**.

## 📋 Información General

**Duración Total:** 3 horas 15 minutos (dividido en 2 días)
**Nivel:** Intermedio
**Audiencia:** Desarrolladores con conocimientos básicos de AWS
**Tamaño de grupo:** 10-30 participantes

## 🎯 Objetivos de Aprendizaje

Al finalizar el workshop, los participantes podrán:

1. Desplegar infraestructura serverless con AWS CDK
2. Integrar Amazon Bedrock en aplicaciones reales
3. Implementar RAG con embeddings vectoriales
4. Aplicar técnicas de prompt engineering
5. Usar Amazon Textract para OCR
6. Implementar clasificación con few-shot learning
7. Generar contenido personalizado con LLMs
8. Experimentar con parámetros de modelos
9. Iterar y mejorar prompts
10. Construir flujos de trabajo de IA end-to-end

## 📚 Prerequisitos para Participantes

### Conocimientos Técnicos
- ✅ Conocimientos básicos de AWS (Lambda, S3, IAM)
- ✅ Experiencia con línea de comandos
- ✅ Familiaridad con Python (lectura de código)
- ✅ Conceptos básicos de APIs REST

### Herramientas Requeridas
- ✅ **Navegador web** (Chrome, Firefox, Edge, Safari)
- ✅ **Acceso a AWS Console** (proporcionado por ti)

**¡Eso es todo!** Los participantes usarán **AWS CloudShell**, que ya incluye:
- ✅ AWS CLI pre-configurado
- ✅ Node.js y npm
- ✅ Python 3
- ✅ Git
- ✅ Solo necesitan instalar CDK (1 minuto)

**No se requieren instalaciones locales** - Todo funciona desde el navegador.

### Cuenta AWS
- ✅ Cuenta AWS con permisos de administrador
- ✅ Acceso a Amazon Bedrock habilitado
- ✅ Límites de servicio verificados

## 🛠️ Preparación del Instructor

### 1 Semana Antes

- [ ] Verificar acceso a Amazon Bedrock en la región del workshop
- [ ] Solicitar aumento de límites si es necesario (Bedrock, Lambda)
- [ ] Preparar cuenta AWS de demostración
- [ ] Probar despliegue completo en cuenta de prueba
- [ ] Preparar slides de presentación
- [ ] Enviar email a participantes con:
  - Link a AWS Console
  - Credenciales de acceso (usuario IAM o SSO)
  - Su PARTICIPANT_PREFIX asignado
  - **Nota:** Solo necesitan navegador web, usarán CloudShell

### 1 Día Antes

- [ ] Desplegar sistema en cuenta de demostración
- [ ] Preparar PDFs de ejemplo adicionales
- [ ] Revisar últimas actualizaciones de servicios AWS

### Día del Workshop

- [ ] Conectarse 15 minutos antes
- [ ] Tener consola AWS, CloudWatch Logs y terminal listos para compartir
- [ ] Tener documentación de Bedrock a mano

---

## 🏗️ Preparación de Infraestructura Antes del Workshop (NUEVO)

**⚠️ IMPORTANTE:** El workshop ahora usa una arquitectura optimizada que separa el despliegue en dos fases:

1. **Instructor (ANTES del workshop):** Despliega VPC compartida y LegacyStacks (~30 minutos total)
2. **Participantes (DURANTE el workshop):** Despliegan solo AI Stacks (~5-8 minutos)

Esta separación reduce el tiempo de despliegue en vivo de ~25-35 minutos a solo ~5-8 minutos, permitiendo más tiempo para los módulos pedagógicos.

### Arquitectura Optimizada

```
ANTES DEL WORKSHOP (Instructor):
├── SharedNetworkStack (una vez)
│   └── VPC compartida para todos
│       Tiempo: ~8 minutos
│
└── LegacyStack × N participantes
    ├── Aurora Serverless v2
    ├── S3 Bucket
    ├── API Gateway
    └── Lambdas Legacy
    Tiempo: ~15 min cada uno (en paralelo)

DURANTE EL WORKSHOP (Participantes):
└── AI Stacks (5 stacks)
    ├── AIExtractionStack
    ├── AIRAGStack
    ├── AIClassificationStack
    ├── AISummaryStack
    └── AIEmailStack
    Tiempo: ~5-8 minutos total
```

### Paso 1: Configurar Lista de Participantes

Edita el archivo [`config/participants.json`](config/participants.json) con usuarios genéricos:

```json
{
  "participants": [
    {
      "prefix": "participant-1",
      "email": "instructor@example.com",
      "iamUsername": "workshop-user-1"
    },
    {
      "prefix": "participant-2",
      "email": "instructor@example.com",
      "iamUsername": "workshop-user-2"
    },
    {
      "prefix": "participant-3",
      "email": "instructor@example.com",
      "iamUsername": "workshop-user-3"
    }
  ]
}
```

**Campos:**
- `prefix`: Identificador único genérico (`participant-1`, `participant-2`, etc.)
- `email`: **Tu email como instructor** (el mismo para todos)
- `iamUsername`: Usuario IAM genérico del workshop

**💡 Ventaja:** Usas usuarios genéricos reutilizables, no necesitas emails individuales.

### Paso 2: Verificar TU Email en SES (Una Sola Vez)

Solo necesitas verificar **tu email como instructor** (no el de cada participante):

```powershell
# PowerShell - Solo una vez
aws ses verify-email-identity --email-address tu-email-instructor@example.com --profile <tu-perfil-aws> --region us-east-2

# Recibirás un email de verificación. Haz clic en el enlace para confirmar.
```

**Nota:** Todos los participantes usarán el mismo email verificado (el tuyo) para las notificaciones de SES durante el workshop.

### Paso 3: Desplegar SharedNetworkStack (Una Sola Vez)

Despliega la VPC compartida que usarán todos los participantes:

```powershell
# PowerShell
.\scripts\instructor-deploy-network.ps1

# O con parámetros personalizados:
.\scripts\instructor-deploy-network.ps1 -Profile <tu-perfil-aws> -Region us-east-2
```

Ver script: [`scripts/instructor-deploy-network.ps1`](scripts/instructor-deploy-network.ps1)

```bash
# Bash (Linux/Mac)
./scripts/instructor-deploy-network.sh

# O con parámetros:
./scripts/instructor-deploy-network.sh <tu-perfil-aws> us-east-2
```

Ver script: [`scripts/instructor-deploy-network.sh`](scripts/instructor-deploy-network.sh)

**Tiempo estimado:** ~8 minutos

**Recursos creados:**
- VPC compartida (10.0.0.0/16)
- 2 Subnets públicas
- 2 Subnets privadas  
- 2 Subnets aisladas
- 1 NAT Gateway
- 1 Internet Gateway

### Paso 4: Desplegar LegacyStacks para Todos los Participantes

Despliega la infraestructura base (Aurora, S3, Lambdas) para cada participante:

```powershell
# PowerShell - Despliega para todos los participantes en config/participants.json
.\scripts\instructor-deploy-legacy.ps1

# Con parámetros personalizados:
.\scripts\instructor-deploy-legacy.ps1 -ConfigFile config/participants.json -Profile <tu-perfil-aws> -Concurrency 3

# O para participantes específicos:
.\scripts\instructor-deploy-legacy.ps1 -Participants "participant-juan","participant-maria"
```

Ver script: [`scripts/instructor-deploy-legacy.ps1`](scripts/instructor-deploy-legacy.ps1)

```bash
# Bash (Linux/Mac)
./scripts/instructor-deploy-legacy.sh

# Con parámetros:
./scripts/instructor-deploy-legacy.sh config/participants.json <tu-perfil-aws> us-east-2 3
```

Ver script: [`scripts/instructor-deploy-legacy.sh`](scripts/instructor-deploy-legacy.sh)

**Tiempo estimado:** ~15 minutos por participante (se despliegan en paralelo)
- Con 3 participantes y concurrencia 3: ~15 minutos total
- Con 10 participantes y concurrencia 5: ~30 minutos total

**Recursos creados por participante:**
- Aurora Serverless v2 (PostgreSQL con pgvector)
- S3 Bucket individual
- API Gateway
- 3 Lambdas Legacy (register-exam, generate-pdf, generate-test-data)
- Security Groups individuales

**Outputs:**
El script genera un reporte JSON con los outputs de cada stack:
- `deployment-report-legacy-YYYYMMDD-HHMMSS.json`

### Paso 5: Compartir Información con Participantes

Envía a cada participante un email con:

1. **Acceso a AWS Console:**
   - Link: https://console.aws.amazon.com/
   - Usuario genérico: `workshop-user-1` (o el número asignado)
   - Contraseña: [proporcionada por separado]

2. **Su PARTICIPANT_PREFIX:** `participant-1` (o el número asignado)

3. **Email verificado:** `tu-email-instructor@example.com` (el mismo para todos)

4. **Link al repositorio** del workshop

5. **Instrucciones simples:**
   ```
   1. Inicia sesión en AWS Console con tu usuario
   2. Abre CloudShell (ícono >_ en la esquina superior derecha)
   3. Clona el repositorio: git clone <url>
   4. cd medical-reports-automation
   5. Ejecuta: ./scripts/participant-deploy-ai.sh participant-1 instructor@example.com
      (Reemplaza participant-1 con tu número asignado)
   6. Espera 5-8 minutos
   ```

**Ventajas de usuarios genéricos:**
- ✅ No necesitas emails individuales de participantes
- ✅ Usuarios reutilizables para futuros workshops
- ✅ Todos usan el mismo email verificado (el tuyo)
- ✅ Más fácil de gestionar

**Nota para participantes:** No necesitan instalar nada localmente, todo funciona desde CloudShell en el navegador.

### Verificación Pre-Workshop

Antes del workshop, verifica que todo está listo:

```powershell
# Verificar que SharedNetworkStack existe
aws cloudformation describe-stacks --stack-name SharedNetworkStack --profile <tu-perfil-aws>

# Verificar LegacyStack de un participante
aws cloudformation describe-stacks --stack-name participant-juan-MedicalReportsLegacyStack --profile <tu-perfil-aws>

# Listar todos los stacks
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --profile <tu-perfil-aws>
```

### Tiempos Estimados

| Fase | Quién | Cuándo | Tiempo |
|------|-------|--------|--------|
| SharedNetworkStack | Instructor | Antes del workshop | ~8 min |
| LegacyStacks (10 participantes) | Instructor | Antes del workshop | ~20 min |
| AI Stacks | Participantes | Durante Día 1 | ~5-8 min |
| **Total para instructor** | | | **~30 min** |
| **Total para participantes** | | | **~5-8 min** |

### Troubleshooting

**Error: "SharedNetworkStack no encontrado"**
- Asegúrate de haber ejecutado `instructor-deploy-network.ps1` primero

**Error: "Export not found"**
- Verifica que SharedNetworkStack está en estado CREATE_COMPLETE
- Ejecuta: `aws cloudformation describe-stacks --stack-name SharedNetworkStack`

**Error: "Token expirado"**
- Los scripts renuevan automáticamente la sesión SSO
- Si falla, ejecuta manualmente: `aws sso login --profile <tu-perfil-aws>`

**Despliegue lento**
- Aumenta la concurrencia: `-Concurrency 5` (PowerShell)
- Verifica límites de servicio en tu cuenta AWS

---

## 🚀 Despliegue Completo del Sistema (Método Tradicional)

Esta sección explica cómo desplegar todo el sistema en tu cuenta de demostración **antes del workshop**. Durante el workshop, los participantes desplegarán los stacks uno por uno siguiendo los módulos pedagógicos.

### Paso 1: Configurar Credenciales AWS

**IMPORTANTE:** Debes configurar tus credenciales de AWS antes de continuar.

Tienes dos opciones para configurar el acceso a AWS:

#### Opción A: Usuario IAM con Credenciales

Si usas un usuario IAM con access keys:

```bash
# Configurar credenciales
aws configure

# Ingresar:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region: us-east-2
# - Default output format: json

# Verificar configuración
aws sts get-caller-identity
```

Si el comando anterior funciona correctamente, tus credenciales están configuradas.

#### Opción B: AWS SSO (Identity Center)

Si tu organización usa AWS SSO (recomendado para cuentas empresariales):

```bash
# Configurar perfil SSO
aws configure sso

# Ingresar:
# - SSO start URL: https://tu-organizacion.awsapps.com/start
# - SSO Region: us-east-2 (o tu región)
# - Seleccionar cuenta y rol
# - CLI default region: us-east-2
# - CLI output format: json
# - Profile name: workshop-demo (o el nombre que prefieras)

# Iniciar sesión
aws sso login --profile workshop-demo

# Verificar configuración
aws sts get-caller-identity --profile workshop-demo
```

**Nota:** Si usas SSO, deberás configurar la variable de entorno antes de cada comando:

```bash
# Linux/Mac
export AWS_PROFILE=workshop-demo

# Windows PowerShell
$env:AWS_PROFILE = "workshop-demo"

# Windows CMD
set AWS_PROFILE=workshop-demo
```

**Troubleshooting:**
- Si recibes "Unable to locate credentials", ejecuta `aws configure` o `aws sso login`
- Si usas SSO y el token expira, ejecuta `aws sso login --profile <tu-perfil>` nuevamente

### Paso 2: Verificar Email en Amazon SES

**Nota:** Asegúrate de haber completado el Paso 1 antes de continuar.

El sistema envía emails personalizados, por lo que necesitas verificar tu dirección de email:

```bash
# Verificar tu email (reemplaza con tu email real)
aws ses verify-email-identity --email-address tu-email@ejemplo.com --region us-east-2

# Si usas perfil SSO, agrega --profile:
aws ses verify-email-identity --email-address tu-email@ejemplo.com --region us-east-2 --profile workshop-demo

# Recibirás un email de verificación. Haz clic en el enlace para confirmar.

# Verificar estado de verificación
aws ses get-identity-verification-attributes \
  --identities tu-email@ejemplo.com \
  --region us-east-2

# Con perfil específico:
aws ses get-identity-verification-attributes \
  --identities tu-email@ejemplo.com \
  --region us-east-2 \
  --profile workshop-demo
```

**Importante:** Si tu cuenta de AWS está en el **SES Sandbox** (cuentas nuevas), solo podrás enviar emails a direcciones verificadas. Para enviar a cualquier dirección, solicita salir del sandbox:

1. Consola AWS → Amazon SES → Account dashboard
2. Haz clic en **Request production access**
3. Completa el formulario (toma ~24 horas)

Para el workshop, puedes quedarte en sandbox y usar solo emails verificados.

### Paso 3: Instalar Dependencias

```bash
# Navegar al directorio CDK
cd cdk

# Instalar dependencias de Node.js
npm install

# Verificar instalación de CDK
cdk --version
# Esperado: 2.x.x o superior
```

### Paso 4: Bootstrap CDK (Solo Primera Vez)

Si es la primera vez que usas CDK en esta cuenta/región:

```bash
# Bootstrap CDK
cdk bootstrap

# Si usas perfil específico:
cdk bootstrap --profile workshop-demo

# Esto crea recursos necesarios para CDK (bucket S3, roles IAM, etc.)
```

### Paso 5: Desplegar Todos los Stacks

Tienes tres opciones para desplegar:

#### Opción A: Usar el Script de Despliegue (Recomendado para Windows)

```powershell
# Windows PowerShell
cd cdk
.\deploy.ps1
```

**Nota:** El script [`deploy.ps1`](cdk/deploy.ps1) está configurado con un perfil específico. Edítalo si usas un perfil diferente:

```powershell
# Editar deploy.ps1 y cambiar esta línea:
$env:AWS_PROFILE = "tu-perfil-aqui"
```

#### Opción B: Comando CDK Directo

```bash
# Linux/Mac
cd cdk
export AWS_PROFILE=workshop-demo  # Si usas perfil específico
cdk deploy --all --require-approval never

# Windows PowerShell
cd cdk
$env:AWS_PROFILE = "workshop-demo"  # Si usas perfil específico
cdk deploy --all --require-approval never

# Windows CMD
cd cdk
set AWS_PROFILE=workshop-demo
cdk deploy --all --require-approval never
```

#### Opción C: Desplegar con Prefijo Personalizado

Si quieres usar un prefijo diferente a 'demo':

```bash
# Con contexto CDK
cdk deploy --all --require-approval never -c participantPrefix=instructor

# O configurar variable de entorno
export PARTICIPANT_PREFIX=instructor
cdk deploy --all --require-approval never
```

### Paso 6: Verificar Despliegue

El despliegue completo toma aproximadamente **25-35 minutos** (el LegacyStack con Aurora puede tomar 15-20 minutos solo). Verifica que todos los stacks se desplegaron correctamente:

```bash
# Listar todos los stacks
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE \
  --query 'StackSummaries[?contains(StackName, `Stack`)].StackName'

# Deberías ver 6 stacks:
# - demo-MedicalReportsLegacyStack (o tu-prefijo-MedicalReportsLegacyStack)
# - demo-AIExtractionStack
# - demo-AIRAGStack
# - demo-AIClassificationStack
# - demo-AISummaryStack
# - demo-AIEmailStack
```

### Paso 7: Obtener Información de Despliegue

Guarda esta información para usarla durante el workshop:

```bash
# Obtener URL del API Gateway
aws cloudformation describe-stacks \
  --stack-name demo-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiUrl`].OutputValue' \
  --output text

# Obtener nombre del bucket S3
aws cloudformation describe-stacks \
  --stack-name demo-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' \
  --output text

# Obtener endpoint de Aurora
aws cloudformation describe-stacks \
  --stack-name demo-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`DatabaseEndpoint`].OutputValue' \
  --output text
```

### Paso 8: Inicializar Base de Datos (Opcional)

Si quieres tener datos de ejemplo pre-cargados:

```bash
# Obtener endpoint de Aurora
DB_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name demo-MedicalReportsLegacyStack \
  --query 'Stacks[0].Outputs[?OutputKey==`DatabaseEndpoint`].OutputValue' \
  --output text)

# Conectar a la base de datos
psql -h $DB_ENDPOINT -U postgres -d medical_reports

# Ejecutar scripts SQL
\i ../database/schema.sql
\i ../database/seed_data.sql
```

### Paso 9: Probar el Sistema

Verifica que todo funciona correctamente:

```bash
# 1. Subir un PDF de prueba
aws s3 cp sample_data/informe_alto_riesgo.pdf \
  s3://demo-medical-reports-<account-id>/external-reports/

# 2. Verificar logs de extracción
aws logs tail /aws/lambda/demo-extract-pdf --follow

# 3. Verificar que se guardó en la base de datos
psql -h $DB_ENDPOINT -U postgres -d medical_reports \
  -c "SELECT COUNT(*) FROM informes_medicos WHERE origen='EXTERNO';"
```

### Troubleshooting del Despliegue

#### Error: "ExpiredToken" o "InvalidClientTokenId"

**Causa:** Credenciales expiradas (común con SSO).

**Solución:**
```bash
# Renovar sesión SSO
aws sso login --profile workshop-demo

# Reintentar despliegue
cdk deploy --all --require-approval never
```

#### Error: "Model access denied"

**Causa:** Permisos insuficientes para Bedrock.

**Solución:** Verifica que tu usuario/rol tenga permisos `bedrock:InvokeModel`. Los modelos se habilitan automáticamente en la primera invocación.

#### Error: "Bucket already exists"

**Causa:** El prefijo 'demo' ya está en uso en tu cuenta.

**Solución:** Usa un prefijo diferente:
```bash
cdk deploy --all -c participantPrefix=instructor
```

#### Error: "Insufficient permissions"

**Causa:** Tu usuario/rol no tiene permisos suficientes.

**Solución:** Necesitas permisos de administrador o al menos:
- CloudFormation: Full access
- Lambda: Full access
- S3: Full access
- RDS: Full access
- IAM: Create roles and policies
- Bedrock: Full access
- SES: Full access

### Resumen del Despliegue

Una vez completados todos los pasos:

- ✅ 6 stacks desplegados en CloudFormation
- ✅ Modelos de Bedrock habilitados
- ✅ Email verificado en SES
- ✅ Base de datos Aurora con schema creado
- ✅ Sistema probado con un PDF de ejemplo

**Tiempo total estimado:** 40-50 minutos (incluyendo esperas de despliegue - Aurora toma 15-20 min)

**Próximos pasos:**
1. Preparar slides de presentación
2. Preparar PDFs de ejemplo adicionales
3. Tener consola AWS abierta con CloudWatch Logs
4. Revisar el plan detallado del workshop (siguiente sección)

---

## 📅 Plan Detallado del Workshop

### Día 1: Fundamentos y Extracción (1h 15min)

#### Módulo 0: Introducción y Setup (5 min)

**Objetivos:**
- Dar bienvenida y contexto
- Verificar que todos tienen prerequisitos
- Explicar estructura del workshop

**Script:**

```
¡Bienvenidos! En este workshop vamos a construir un sistema real de automatización
de informes médicos usando servicios de AWS y Amazon Bedrock.

El caso de uso: Una empresa de salud ocupacional recibe informes médicos en PDF
de diferentes clínicas. Necesitan:
1. Extraer datos automáticamente
2. Clasificar el nivel de riesgo
3. Generar resúmenes ejecutivos
4. Enviar notificaciones personalizadas

Vamos a resolver esto usando IA Generativa.

Antes de empezar, verifiquemos que todos tienen:
- AWS CLI configurado ✓
- CDK instalado ✓
- Acceso a Bedrock habilitado ✓
```

**Demostración en vivo:**
1. Mostrar arquitectura completa en diagrama
2. Explicar flujo de datos
3. Mostrar resultado final (email recibido)

**Tiempo:** 5 minutos

---

#### Módulo 1: Extracción con Textract y Bedrock (30 min)

**Objetivos:**
- Entender diferencia entre OCR y estructuración
- Aprender a usar Amazon Textract
- Integrar Amazon Bedrock para estructurar datos
- Ver el flujo completo de extracción

**Conceptos Clave a Explicar:**

1. **Amazon Textract**
   - Servicio de OCR (Optical Character Recognition)
   - Extrae texto, tablas y formularios
   - No entiende el contexto, solo extrae

2. **Amazon Bedrock**
   - Servicio de LLMs (Large Language Models)
   - Entiende contexto y estructura
   - Transforma texto no estructurado en JSON

3. **Por qué necesitamos ambos:**
   - Textract: Extrae el texto del PDF
   - Bedrock: Entiende qué significa cada dato

**Script:**

```
Imaginen que tienen un PDF médico. Textract es como un escáner inteligente
que lee todo el texto, pero no sabe qué es "presión arterial" vs "peso".

Bedrock es como un médico que lee ese texto y dice: "Ah, esto es presión
arterial, esto es peso, esto es una observación médica".

Juntos, convierten un PDF en datos estructurados que podemos guardar en
una base de datos.
```

**Demostración en vivo:**

1. **Desplegar Stack de Extracción** (5 min)
   ```bash
   cd cdk
   cdk deploy AIExtractionStack
   ```
   
   Mientras despliega, explicar:
   - Lambda con trigger S3
   - Permisos IAM para Textract y Bedrock
   - Variables de entorno

2. **Revisar Código** (10 min)
   
   Abrir [`lambda/ai/extract_pdf/index.py`](lambda/ai/extract_pdf/index.py):
   
   ```python
   # Paso 1: Textract extrae texto
   response = textract_client.analyze_document(...)
   
   # Paso 2: Construir prompt para Bedrock
   prompt = f"""
   Extrae datos del siguiente texto médico:
   {texto_extraido}
   """
   
   # Paso 3: Bedrock estructura en JSON
   bedrock_response = bedrock_runtime.invoke_model(...)
   ```
   
   **Puntos a destacar:**
   - `analyze_document` vs `detect_document_text`
   - Construcción del prompt
   - Parámetros: temperature, maxTokens

3. **Subir PDF y Ver Logs** (10 min)
   ```bash
   aws s3 cp sample_data/informe_alto_riesgo.pdf \
     s3://bucket/external-reports/
   ```
   
   Abrir CloudWatch Logs en vivo:
   - Mostrar log de Textract
   - Mostrar prompt enviado a Bedrock
   - Mostrar JSON estructurado
   - Mostrar inserción en Aurora

4. **Verificar en Base de Datos** (5 min)
   ```sql
   SELECT * FROM informes_medicos WHERE origen='EXTERNO';
   ```

**Ejercicio para Participantes:**
- Subir su propio PDF
- Verificar en CloudWatch
- Consultar en base de datos

**Tiempo:** 30 minutos

---


#### Módulo 2: Prompt Engineering (30 min)

**Objetivos:**
- Entender qué es prompt engineering
- Ver evolución de prompts (v1 → v2 → v3)
- Experimentar con parámetros
- Aprender mejores prácticas

**Conceptos Clave a Explicar:**

1. **¿Qué es un Prompt?**
   - Instrucciones que le das al modelo
   - Como hablarle a un asistente muy inteligente
   - La calidad del prompt determina la calidad de la respuesta

2. **Componentes de un Buen Prompt:**
   - Rol/Contexto: "Eres un experto en..."
   - Tarea: "Extrae los siguientes datos..."
   - Formato: "Devuelve en JSON..."
   - Restricciones: "Si no encuentras un dato, usa null"
   - Ejemplos: "Por ejemplo: {...}"

3. **Parámetros Importantes:**
   - **temperature**: Control de aleatoriedad (0.0 = determinístico, 1.0 = creativo)
   - **maxTokens**: Longitud máxima de respuesta
   - **topP**: Control de diversidad

**Script:**

```
Prompt engineering es el arte de comunicarte efectivamente con un LLM.
Es como aprender a dar instrucciones claras a un asistente muy capaz
pero que necesita contexto específico.

Un mal prompt: "Dame los datos"
Un buen prompt: "Eres un experto en informes médicos. Extrae estos campos
específicos en formato JSON. Si un campo no existe, usa null."

La diferencia es enorme en la calidad de resultados.
```

**Demostración en vivo:**

1. **Comparar Versiones de Prompts** (15 min)
   
   Mostrar lado a lado:
   
   **Versión 1** ([`prompts/extraction_v1.txt`](prompts/extraction_v1.txt)):
   ```
   Extrae datos del siguiente informe médico.
   ```
   
   Resultado: ❌ Inconsistente, formato variable
   
   **Versión 2** ([`prompts/extraction_v2.txt`](prompts/extraction_v2.txt)):
   ```
   Extrae los siguientes campos:
   - Nombre del trabajador
   - Presión arterial
   ...
   Devuelve en formato JSON.
   ```
   
   Resultado: ⚠️ Mejor, pero aún inconsistente
   
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
   
   Resultado: ✅ Consistente, preciso, confiable

2. **Experimentar con Temperature** (10 min)
   
   Modificar en vivo:
   ```python
   # Temperature baja (0.1) - Determinístico
   "inferenceConfig": {"temperature": 0.1}
   
   # Temperature alta (0.8) - Creativo
   "inferenceConfig": {"temperature": 0.8}
   ```
   
   Desplegar y comparar resultados:
   ```bash
   cdk deploy AIExtractionStack
   aws s3 cp sample_data/informe_medio_riesgo.pdf s3://bucket/external-reports/
   ```
   
   **Mostrar diferencias:**
   - Temperature 0.1: Siempre extrae igual
   - Temperature 0.8: Puede variar en formato

3. **Cuándo Usar Cada Temperature** (5 min)
   
   Mostrar tabla en pantalla compartida:
   ```
   Temperature | Uso Ideal           | Ejemplo
   ------------|---------------------|------------------
   0.0 - 0.2   | Extracción, datos   | PDFs, formularios
   0.3 - 0.5   | Análisis, resúmenes | Informes ejecutivos
   0.6 - 0.8   | Contenido, emails   | Comunicaciones
   0.9 - 1.0   | Creativo, ideas     | Brainstorming
   ```

**Ejercicio para Participantes:**
1. Modificar temperature en su código
2. Re-desplegar
3. Comparar resultados
4. Discutir diferencias

**Tiempo:** 30 minutos

---

#### Checkpoint Día 1 (10 min)

**Objetivos:**
- Verificar que todos completaron los módulos
- Responder preguntas
- Preparar para Día 2

**Checklist:**
```bash
# 1. Sistema legacy desplegado
aws cloudformation describe-stacks --stack-name LegacyStack

# 2. Sistema de extracción desplegado
aws cloudformation describe-stacks --stack-name AIExtractionStack

# 3. Al menos 1 PDF procesado
psql -h <endpoint> -U postgres -d medical_reports \
  -c "SELECT COUNT(*) FROM informes_medicos WHERE origen='EXTERNO';"
```

**Preguntas para Reflexión:**
1. ¿Qué hace Textract que Bedrock no puede hacer?
2. ¿Por qué usamos temperature baja para extracción?
3. ¿Qué componentes hacen que un prompt sea efectivo?

**Tarea para Día 2:**
- Revisar documentación de pgvector
- Leer sobre RAG (Retrieval-Augmented Generation)

**Tiempo:** 10 minutos

---


### Día 2: RAG, Clasificación y Personalización (2h)

#### Módulo 3: RAG con Embeddings Vectoriales (30 min)

**Objetivos:**
- Entender qué es RAG y por qué es importante
- Aprender sobre embeddings vectoriales
- Implementar búsqueda por similitud con pgvector
- Ver cómo RAG mejora las respuestas

**Conceptos Clave a Explicar:**

1. **¿Qué es RAG?**
   - RAG = Retrieval-Augmented Generation
   - Retrieval: Buscar información relevante
   - Augmented: Agregar esa información al prompt
   - Generation: Generar respuesta con contexto
   
2. **Problema que Resuelve:**
   - LLMs tienen conocimiento limitado (fecha de corte)
   - LLMs pueden "alucinar" (inventar información)
   - RAG proporciona contexto específico y verificable

3. **Embeddings Vectoriales:**
   - Representación numérica de texto
   - Textos similares → vectores similares
   - Permite búsqueda semántica (por significado, no por palabras)

**Script:**

```
Imaginen que le preguntan a un médico sobre un paciente sin darle
el historial médico. Puede dar una opinión general, pero no específica.

RAG es como darle al médico el historial completo antes de que opine.
El médico (LLM) ahora tiene contexto real y puede dar una respuesta
mucho más precisa y personalizada.

Los embeddings son la forma de buscar ese historial de manera inteligente.
No buscamos por palabras exactas, sino por significado.
```

**Demostración en vivo:**

1. **Explicar Embeddings con Ejemplo** (10 min)
   
   Mostrar en pantalla compartida:
   ```
   Texto 1: "Presión arterial: 140/90 mmHg"
   Embedding 1: [0.123, -0.456, 0.789, ..., 0.234]
   
   Texto 2: "PA: 142/88 mmHg"
   Embedding 2: [0.125, -0.450, 0.792, ..., 0.230]
   
   Similitud: 0.98 (muy similar)
   
   Texto 3: "Peso: 75 kg"
   Embedding 3: [-0.234, 0.567, -0.123, ..., 0.890]
   
   Similitud con Texto 1: 0.12 (muy diferente)
   ```
   
   **Punto clave:** Embeddings capturan el significado, no las palabras exactas.

2. **Desplegar Stack RAG** (5 min)
   ```bash
   cd cdk
   cdk deploy AIRAGStack
   ```
   
   Explicar mientras despliega:
   - Lambda para generar embeddings
   - Uso de Amazon Titan Embeddings v2
   - Tabla informes_embeddings con pgvector

3. **Generar Embeddings** (5 min)
   ```bash
   # Generar embeddings para informes existentes
   aws lambda invoke \
     --function-name generate-embeddings \
     --payload '{"informe_id": 1}' \
     response.json
   ```
   
   Mostrar en CloudWatch:
   - Llamada a Titan Embeddings
   - Vector de 1024 dimensiones
   - Inserción en pgvector

4. **Demostrar Búsqueda por Similitud** (10 min)
   
   Abrir [`lambda/shared/similarity_search.py`](lambda/shared/similarity_search.py):
   ```python
   sql = """
       SELECT 
           ie.informe_id,
           ie.contenido,
           1 - (ie.embedding <=> %s::vector) as similarity
       FROM informes_embeddings ie
       WHERE ie.trabajador_id = %s
       ORDER BY ie.embedding <=> %s::vector
       LIMIT 3
   """
   ```
   
   **Explicar:**
   - `<=>` es el operador de distancia coseno
   - Menor distancia = mayor similitud
   - Filtramos por trabajador_id para contexto relevante
   
   Ejecutar búsqueda en vivo:
   ```sql
   SELECT 
     informe_id,
     contenido,
     1 - (embedding <=> '[0.123, -0.456, ...]'::vector) as similarity
   FROM informes_embeddings
   WHERE trabajador_id = 1
   ORDER BY embedding <=> '[0.123, -0.456, ...]'::vector
   LIMIT 3;
   ```

**Ejercicio para Participantes:**
1. Generar embeddings para sus informes
2. Ejecutar búsqueda por similitud
3. Observar qué informes son similares

**Tiempo:** 30 minutos

---


#### Módulo 4: Clasificación con Few-Shot Learning (30 min)

**Objetivos:**
- Entender few-shot learning
- Ver cómo RAG mejora la clasificación
- Implementar clasificador de riesgo
- Comparar resultados con y sin RAG

**Conceptos Clave a Explicar:**

1. **Few-Shot Learning:**
   - Enseñar al modelo con pocos ejemplos
   - Ejemplos en el prompt, no en entrenamiento
   - Muy efectivo para tareas de clasificación

2. **Tipos de Learning:**
   - **Zero-shot**: Sin ejemplos (solo instrucciones)
   - **One-shot**: Un ejemplo
   - **Few-shot**: Varios ejemplos (2-5 típicamente)
   - **Fine-tuning**: Entrenar el modelo (no cubierto aquí)

3. **Por qué Funciona:**
   - LLMs aprenden patrones de los ejemplos
   - Generalizan a nuevos casos
   - Más ejemplos = mejor precisión (hasta cierto punto)

**Script:**

```
Few-shot learning es como mostrarle a alguien ejemplos antes de pedirle
que haga algo.

Sin ejemplos: "Clasifica este informe" → Resultados inconsistentes
Con ejemplos: "Aquí hay 3 ejemplos de BAJO, MEDIO y ALTO riesgo.
               Ahora clasifica este" → Resultados consistentes

Es la diferencia entre decir "dibuja un perro" vs mostrar 3 fotos
de perros y luego decir "dibuja uno similar".
```

**Demostración en vivo:**

1. **Desplegar Stack de Clasificación** (5 min)
   ```bash
   cd cdk
   cdk deploy AIClassificationStack
   ```

2. **Revisar Prompt de Clasificación** (10 min)
   
   Abrir [`prompts/classification.txt`](prompts/classification.txt):
   
   ```
   Eres un médico ocupacional experto en evaluar riesgos laborales.
   
   Clasifica el siguiente informe en uno de estos niveles:
   - BAJO: Parámetros normales, apto sin restricciones
   - MEDIO: Parámetros limítrofes, requiere seguimiento
   - ALTO: Parámetros alterados, requiere atención inmediata
   
   EJEMPLOS:
   
   [Ejemplo BAJO]
   Trabajador: Juan Pérez
   Presión: 118/75 mmHg
   IMC: 23.5
   Colesterol: 180 mg/dL
   Clasificación: BAJO
   Justificación: Todos los parámetros dentro de rangos normales...
   
   [Ejemplo MEDIO]
   Trabajador: María García
   Presión: 135/85 mmHg
   IMC: 27.2
   Colesterol: 215 mg/dL
   Clasificación: MEDIO
   Justificación: Presión en rango de pre-hipertensión...
   
   [Ejemplo ALTO]
   Trabajador: Carlos López
   Presión: 155/95 mmHg
   IMC: 32.1
   Glucosa: 145 mg/dL
   Clasificación: ALTO
   Justificación: Hipertensión grado 1, obesidad...
   
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
   
   **Puntos a destacar:**
   - Definiciones claras de cada nivel
   - Ejemplos específicos con datos reales
   - Contexto histórico de RAG
   - Formato de salida estructurado

3. **Clasificar Informe** (10 min)
   ```bash
   # Clasificar informe
   aws lambda invoke \
     --function-name classify-risk \
     --payload '{"informe_id": 1}' \
     response.json
   
   # Ver resultado
   cat response.json
   ```
   
   Mostrar en CloudWatch:
   - Búsqueda RAG de informes anteriores
   - Prompt completo con contexto
   - Respuesta de Bedrock
   - Actualización en Aurora

4. **Comparar Con y Sin RAG** (5 min)
   
   Modificar código temporalmente para omitir RAG:
   ```python
   # Sin RAG
   prompt = f"""
   Clasifica este informe:
   {informe_actual}
   """
   
   # Con RAG
   prompt = f"""
   Contexto histórico:
   {informes_anteriores}
   
   Clasifica este informe:
   {informe_actual}
   ```
   
   **Mostrar diferencia:**
   - Sin RAG: Clasificación basada solo en valores actuales
   - Con RAG: Clasificación considerando tendencias

**Ejercicio para Participantes:**
1. Clasificar varios informes
2. Observar justificaciones
3. Verificar en base de datos

**Tiempo:** 30 minutos

---


#### Módulo 5: Resúmenes y Emails Personalizados (30 min)

**Objetivos:**
- Generar resúmenes ejecutivos concisos
- Personalizar emails según nivel de riesgo
- Entender control de tono con prompts
- Ver flujo completo end-to-end

**Conceptos Clave a Explicar:**

1. **Generación de Resúmenes:**
   - Condensar información compleja
   - Lenguaje claro y no técnico
   - Enfoque en lo accionable
   - Incluir tendencias históricas

2. **Personalización de Contenido:**
   - Mismo dato, diferentes tonos
   - Adaptación a la audiencia
   - Control de urgencia y emoción
   - Mantener profesionalismo

3. **Temperature para Creatividad:**
   - Resúmenes: 0.5 (balanceado)
   - Emails: 0.7 (más creativo)
   - Permite variación natural

**Script:**

```
Ahora vamos a cerrar el círculo. Tenemos datos extraídos, clasificados,
y ahora necesitamos comunicarlos efectivamente.

Un resumen ejecutivo es para el gerente que tiene 2 minutos.
Un email es para el contratista que necesita actuar.

La clave es adaptar el mensaje a la audiencia y al nivel de urgencia.
Un informe de ALTO riesgo necesita un tono urgente.
Un informe de BAJO riesgo puede ser tranquilizador.
```

**Demostración en vivo:**

1. **Desplegar Stacks** (5 min)
   ```bash
   cd cdk
   cdk deploy AISummaryStack
   cdk deploy AIEmailStack
   ```

2. **Generar Resumen Ejecutivo** (10 min)
   
   ```bash
   aws lambda invoke \
     --function-name generate-summary \
     --payload '{"informe_id": 1}' \
     response.json
   ```
   
   Revisar prompt ([`prompts/summary.txt`](prompts/summary.txt)):
   ```
   Genera un resumen ejecutivo del informe médico.
   
   REQUISITOS:
   - Máximo 150 palabras
   - Lenguaje claro, no técnico
   - Enfócate en hallazgos principales
   - Incluye tendencias si hay informes anteriores
   
   CONTEXTO HISTÓRICO:
   [Informes anteriores - RAG]
   
   INFORME ACTUAL:
   [Datos]
   
   FORMATO:
   Párrafo único, directo y accionable.
   ```
   
   **Mostrar resultado:**
   - Resumen conciso
   - Sin jerga médica
   - Incluye tendencias
   - Accionable

3. **Enviar Emails Personalizados** (15 min)
   
   Mostrar los 3 prompts diferentes:
   
   **ALTO Riesgo** ([`prompts/email_high.txt`](prompts/email_high.txt)):
   ```
   Genera un email URGENTE para el contratista.
   
   TONO: Urgente pero profesional
   OBJETIVO: Acción inmediata
   
   Incluye:
   - Hallazgos críticos destacados
   - Acciones requeridas INMEDIATAMENTE
   - Consecuencias de no actuar
   - Contacto para seguimiento
   
   ESTRUCTURA:
   - Asunto: [URGENTE] ...
   - Saludo formal
   - Párrafo de urgencia
   - Lista de acciones
   - Cierre con contacto
   ```
   
   **MEDIO Riesgo** ([`prompts/email_medium.txt`](prompts/email_medium.txt)):
   ```
   Genera un email PROFESIONAL para el contratista.
   
   TONO: Profesional y constructivo
   OBJETIVO: Seguimiento programado
   
   Incluye:
   - Hallazgos que requieren atención
   - Recomendaciones de seguimiento
   - Plazo sugerido (30-60 días)
   - Disponibilidad para consultas
   ```
   
   **BAJO Riesgo** ([`prompts/email_low.txt`](prompts/email_low.txt)):
   ```
   Genera un email TRANQUILIZADOR para el contratista.
   
   TONO: Positivo y alentador
   OBJETIVO: Confirmar estado saludable
   
   Incluye:
   - Confirmación de parámetros normales
   - Felicitación por mantener salud
   - Recordatorio de controles periódicos
   - Mensaje motivacional
   ```
   
   Enviar email:
   ```bash
   aws lambda invoke \
     --function-name send-email \
     --payload '{"informe_id": 1}' \
     response.json
   ```
   
   **Mostrar email recibido (compartir pantalla):**
   - Abrir bandeja de entrada en pantalla compartida
   - Mostrar personalización
   - Destacar tono apropiado
   - Señalar elementos clave

**Ejercicio para Participantes:**
1. Generar resúmenes de sus informes
2. Enviar emails
3. Comparar tonos según nivel de riesgo

**Tiempo:** 30 minutos

---

#### Experimentación Libre (30 min)

**Objetivos:**
- Permitir exploración autónoma
- Responder preguntas específicas
- Facilitar experimentación con prompts
- Compartir descubrimientos

**Actividades Sugeridas:**

1. **Modificar Prompts:**
   - Cambiar tono de emails
   - Ajustar longitud de resúmenes
   - Agregar más ejemplos a clasificación

2. **Experimentar con Parámetros:**
   - Probar diferentes temperatures
   - Ajustar maxTokens
   - Comparar resultados

3. **Crear Nuevos Casos:**
   - Subir PDFs propios
   - Generar datos de prueba
   - Ver flujo completo

4. **Optimizar Prompts:**
   - Iterar sobre prompts existentes
   - Medir mejoras
   - Documentar cambios

**Rol del Instructor:**
- Monitorear el chat y preguntas
- Responder preguntas en tiempo real
- Sugerir experimentos
- Facilitar discusiones en grupo
- Compartir mejores prácticas
- Usar breakout rooms si es necesario

**Tiempo:** 30 minutos

---


## 💡 Puntos Clave de Explicación

### Servicios AWS

#### Amazon Bedrock
**Qué es:**
- Servicio totalmente administrado para usar LLMs
- Acceso a múltiples modelos (Amazon, Anthropic, Meta, etc.)
- Sin necesidad de gestionar infraestructura

**Cuándo explicar:**
- Módulo 1 (primera vez que se usa)
- Enfatizar: "Serverless para IA"

**Puntos clave:**
- No necesitas entrenar modelos
- Pagas por uso (por token)
- Modelos pre-entrenados listos para usar

#### Amazon Nova Pro
**Qué es:**
- Modelo de lenguaje de Amazon
- Optimizado para tareas empresariales
- Multimodal (texto, imágenes)

**Cuándo explicar:**
- Módulo 1 (al invocar por primera vez)

**Puntos clave:**
- Balanceo entre costo y capacidad
- Bueno para tareas complejas
- Soporta español nativamente

#### Amazon Titan Embeddings v2
**Qué es:**
- Modelo para generar embeddings
- Vectores de 1024 dimensiones
- Optimizado para búsqueda semántica

**Cuándo explicar:**
- Módulo 3 (RAG)

**Puntos clave:**
- Convierte texto en números
- Permite búsqueda por significado
- Base de RAG

#### Amazon Textract
**Qué es:**
- Servicio de OCR (Optical Character Recognition)
- Extrae texto, tablas y formularios
- Entiende estructura de documentos

**Cuándo explicar:**
- Módulo 1 (extracción)

**Puntos clave:**
- Más que OCR simple
- Entiende tablas y formularios
- No entiende contexto (por eso necesitamos Bedrock)

#### Aurora Serverless v2
**Qué es:**
- PostgreSQL serverless
- Escala automáticamente
- Soporta pgvector para embeddings

**Cuándo explicar:**
- Setup inicial
- Módulo 3 (cuando se usa pgvector)

**Puntos clave:**
- Escala de 0.5 a 128 ACUs
- Pagas por uso
- pgvector permite búsqueda vectorial

---

### Conceptos de IA Generativa

#### LLMs (Large Language Models)
**Explicación simple:**
```
Un LLM es como un asistente muy inteligente que ha leído millones
de libros y puede entender y generar texto de manera natural.

No es una base de datos que busca respuestas exactas.
Es un modelo que entiende patrones y genera respuestas coherentes.
```

**Analogía:**
- Base de datos = Biblioteca con índice
- LLM = Persona que leyó toda la biblioteca y puede conversar

#### Prompt Engineering
**Explicación simple:**
```
Prompt engineering es el arte de comunicarte efectivamente con un LLM.
Es como aprender a dar instrucciones claras a un asistente muy capaz.

Mal prompt: "Dame datos"
Buen prompt: "Eres un experto en X. Extrae estos campos específicos
              en formato Y. Si no encuentras algo, usa Z."
```

**Mejores prácticas:**
1. Dar contexto/rol
2. Ser específico
3. Proporcionar ejemplos
4. Definir formato de salida
5. Establecer restricciones

#### RAG (Retrieval-Augmented Generation)
**Explicación simple:**
```
RAG es como darle a un médico el historial del paciente antes
de que dé su diagnóstico.

Sin RAG: Opinión general basada en conocimiento general
Con RAG: Opinión específica basada en datos reales del paciente
```

**Componentes:**
1. **Retrieval**: Buscar información relevante
2. **Augmented**: Agregar al prompt
3. **Generation**: Generar respuesta con contexto

**Beneficios:**
- Reduce alucinaciones
- Proporciona contexto específico
- Mejora precisión
- Permite personalización

#### Few-Shot Learning
**Explicación simple:**
```
Few-shot learning es enseñar con ejemplos en lugar de entrenar.

Es como mostrarle a alguien 3 fotos de perros y luego pedirle
que identifique perros en nuevas fotos.

No necesitas miles de ejemplos, solo unos pocos buenos.
```

**Tipos:**
- **Zero-shot**: Sin ejemplos
- **One-shot**: Un ejemplo
- **Few-shot**: 2-5 ejemplos
- **Many-shot**: 10+ ejemplos

#### Temperature
**Explicación simple:**
```
Temperature controla qué tan "creativo" o "aleatorio" es el modelo.

Temperature 0.0: Siempre da la misma respuesta (determinístico)
Temperature 1.0: Respuestas muy variadas (creativo)

Es como el volumen de creatividad.
```

**Guía de uso:**
```
0.0 - 0.2: Extracción de datos, clasificación
0.3 - 0.5: Análisis, resúmenes
0.6 - 0.8: Contenido, emails
0.9 - 1.0: Brainstorming, ideas
```

#### Embeddings Vectoriales
**Explicación simple:**
```
Un embedding es una representación numérica de texto.

Texto: "Presión arterial alta"
Embedding: [0.123, -0.456, 0.789, ..., 0.234]

Textos similares tienen embeddings similares.
Permite buscar por significado, no por palabras exactas.
```

**Analogía:**
- Palabras = Direcciones
- Embeddings = Coordenadas GPS
- Similitud = Distancia entre coordenadas

---


## 🎓 Snippets de Código Comentados

### Extracción con Textract y Bedrock

```python
def extract_pdf_data(bucket, key):
    """
    Extrae datos estructurados de un PDF médico.
    
    Flujo:
    1. Textract extrae texto del PDF
    2. Bedrock estructura el texto en JSON
    3. Guardar en Aurora
    """
    
    # Paso 1: Extraer texto con Textract
    # analyze_document es más potente que detect_document_text
    # porque entiende tablas y formularios
    response = textract_client.analyze_document(
        Document={'S3Object': {'Bucket': bucket, 'Name': key}},
        FeatureTypes=['TABLES', 'FORMS']  # Extraer tablas y formularios
    )
    
    # Convertir respuesta de Textract a texto plano
    texto_extraido = extract_text_from_textract(response)
    
    # Paso 2: Estructurar con Bedrock
    # Leer prompt desde archivo (facilita iteración)
    with open('prompts/extraction.txt', 'r') as f:
        prompt_template = f.read()
    
    # Construir prompt con el texto extraído
    prompt = prompt_template.replace('{texto}', texto_extraido)
    
    # Invocar Bedrock Nova Pro
    bedrock_response = bedrock_runtime.invoke_model(
        modelId='us.amazon.nova-pro-v1:0',
        body=json.dumps({
            "messages": [
                {"role": "user", "content": prompt}
            ],
            "inferenceConfig": {
                "temperature": 0.1,  # Baja para precisión
                "maxTokens": 2000,   # Suficiente para JSON
                "topP": 0.9
            }
        })
    )
    
    # Parsear respuesta
    response_body = json.loads(bedrock_response['body'].read())
    datos_estructurados = json.loads(response_body['output']['message']['content'][0]['text'])
    
    # Paso 3: Guardar en Aurora
    save_to_aurora(datos_estructurados)
    
    return datos_estructurados
```

### Generación de Embeddings

```python
def generate_embedding(texto):
    """
    Genera embedding vectorial de un texto usando Titan.
    
    Retorna un vector de 1024 dimensiones que representa
    el significado semántico del texto.
    """
    
    # Invocar Titan Embeddings v2
    response = bedrock_runtime.invoke_model(
        modelId='amazon.titan-embed-text-v2:0',
        body=json.dumps({
            "inputText": texto,
            "dimensions": 1024,  # Dimensiones del vector
            "normalize": True    # Normalizar para cosine similarity
        })
    )
    
    # Extraer embedding
    response_body = json.loads(response['body'].read())
    embedding = response_body['embedding']
    
    return embedding  # Lista de 1024 números
```

### Búsqueda RAG con pgvector

```python
def buscar_informes_similares(trabajador_id, embedding_actual, limit=3):
    """
    Busca informes anteriores similares usando pgvector.
    
    Usa distancia coseno para encontrar embeddings similares.
    Menor distancia = mayor similitud.
    """
    
    sql = """
        SELECT 
            ie.informe_id,
            ie.contenido,
            ie.fecha_examen,
            1 - (ie.embedding <=> %s::vector) as similarity
        FROM informes_embeddings ie
        WHERE ie.trabajador_id = %s
          AND ie.informe_id != %s
        ORDER BY ie.embedding <=> %s::vector  -- Ordenar por distancia
        LIMIT %s
    """
    
    # <=> es el operador de distancia coseno de pgvector
    # 1 - distancia = similitud (0 = diferente, 1 = idéntico)
    
    cursor.execute(sql, (
        embedding_actual,
        trabajador_id,
        informe_actual_id,
        embedding_actual,
        limit
    ))
    
    return cursor.fetchall()
```

### Clasificación con Few-Shot Learning

```python
def classify_risk(informe_id):
    """
    Clasifica nivel de riesgo usando few-shot learning y RAG.
    
    Combina:
    1. Ejemplos en el prompt (few-shot)
    2. Contexto histórico (RAG)
    3. Datos actuales
    """
    
    # Obtener datos del informe
    informe = get_informe(informe_id)
    
    # Buscar informes anteriores (RAG)
    embedding = generate_embedding(informe['contenido'])
    informes_anteriores = buscar_informes_similares(
        informe['trabajador_id'],
        embedding,
        limit=3
    )
    
    # Construir contexto histórico
    contexto = "\n".join([
        f"Fecha: {inf['fecha']}, Riesgo: {inf['nivel']}, "
        f"Observaciones: {inf['obs']}"
        for inf in informes_anteriores
    ])
    
    # Leer prompt con ejemplos (few-shot)
    with open('prompts/classification.txt', 'r') as f:
        prompt_template = f.read()
    
    # Reemplazar placeholders
    prompt = prompt_template.replace('{contexto}', contexto)
    prompt = prompt.replace('{informe}', json.dumps(informe))
    
    # Invocar Bedrock
    response = bedrock_runtime.invoke_model(
        modelId='us.amazon.nova-pro-v1:0',
        body=json.dumps({
            "messages": [{"role": "user", "content": prompt}],
            "inferenceConfig": {
                "temperature": 0.3,  # Baja pero no 0 para variación
                "maxTokens": 500
            }
        })
    )
    
    # Parsear y guardar
    result = parse_response(response)
    update_informe(informe_id, result)
    
    return result
```

---

## ❓ FAQ con Respuestas Técnicas

### Sobre Amazon Bedrock

**P: ¿Por qué usar Bedrock en lugar de llamar directamente a OpenAI?**

R: Varias razones:
1. **Integración nativa con AWS**: Permisos IAM, VPC, CloudWatch
2. **Múltiples modelos**: Amazon, Anthropic, Meta, Cohere en un solo lugar
3. **Cumplimiento**: Datos no se usan para entrenar modelos
4. **Soporte empresarial**: SLA, soporte técnico de AWS
5. **Costos**: Competitivos y facturados con AWS

**P: ¿Cuánto cuesta usar Bedrock?**

R: Precios aproximados (us-east-1):
- Nova Pro: $0.80 por 1M tokens de entrada, $3.20 por 1M tokens de salida
- Titan Embeddings: $0.10 por 1M tokens
- Para este workshop: ~$2-5 USD por participante

**P: ¿Qué modelos están disponibles en Bedrock?**

R: Principales modelos:
- **Amazon**: Nova Pro, Nova Lite, Titan
- **Anthropic**: Claude 3 (Opus, Sonnet, Haiku)
- **Meta**: Llama 3
- **Cohere**: Command, Embed
- **Stability AI**: Stable Diffusion (imágenes)

**P: ¿Cómo accedo a los modelos de Bedrock?**

R: Los modelos serverless se habilitan automáticamente en la primera invocación. Solo necesitas permisos IAM adecuados (`bedrock:InvokeModel`). No requiere activación manual.

### Sobre Prompts

**P: ¿Cuál es la longitud ideal de un prompt?**

R: Depende de la tarea:
- **Extracción simple**: 200-500 tokens
- **Clasificación con ejemplos**: 500-1000 tokens
- **Análisis complejo**: 1000-2000 tokens
- **Límite práctico**: 4000-8000 tokens (depende del modelo)

**P: ¿Cómo sé si mi prompt es bueno?**

R: Criterios:
1. **Consistencia**: ¿Da resultados similares con inputs similares?
2. **Precisión**: ¿Los resultados son correctos?
3. **Formato**: ¿Respeta el formato solicitado?
4. **Completitud**: ¿Incluye toda la información necesaria?

Prueba con 10-20 casos y mide estos criterios.

**P: ¿Debo usar JSON mode o parsear la respuesta?**

R: Depende:
- **JSON mode** (si está disponible): Garantiza JSON válido
- **Parsear**: Más flexible, permite explicaciones adicionales

En este workshop usamos parseo porque queremos ver el proceso.

### Sobre RAG

**P: ¿Cuántos documentos debo recuperar en RAG?**

R: Regla general:
- **3-5 documentos**: Balance entre contexto y ruido
- **Menos de 3**: Puede faltar contexto
- **Más de 10**: Puede confundir al modelo

En este workshop usamos 3.

**P: ¿Cómo sé si RAG está mejorando los resultados?**

R: Prueba A/B:
1. Clasificar 20 informes sin RAG
2. Clasificar los mismos 20 con RAG
3. Comparar precisión con evaluación humana

Típicamente RAG mejora 10-30% la precisión.

**P: ¿Puedo usar RAG con otros tipos de datos?**

R: Sí, RAG funciona con:
- Documentos (PDFs, Word)
- Código fuente
- Logs de sistema
- Conversaciones
- Cualquier texto estructurado

### Sobre Embeddings

**P: ¿Por qué 1024 dimensiones?**

R: Balance entre:
- **Más dimensiones**: Mayor precisión, más costo de almacenamiento
- **Menos dimensiones**: Menor precisión, menos costo

1024 es un buen balance para la mayoría de casos.

**P: ¿Puedo usar embeddings de OpenAI con pgvector?**

R: Sí, pgvector es agnóstico al modelo:
- OpenAI: 1536 dimensiones
- Titan v2: 1024 dimensiones
- Cohere: 768 dimensiones

Solo ajusta la dimensión en la tabla.

**P: ¿Cómo actualizo embeddings cuando cambia el contenido?**

R: Estrategias:
1. **Regenerar todo**: Simple pero costoso
2. **Incremental**: Solo nuevos/modificados
3. **Batch nocturno**: Actualizar en horario de baja demanda

En producción, usa estrategia incremental.

### Sobre Debugging

**P: ¿Cómo debuggeo prompts que no funcionan?**

R: Pasos:
1. **Ver logs en CloudWatch**: Prompt completo y respuesta
2. **Probar en consola de Bedrock**: Playground para iteración rápida
3. **Simplificar**: Remover complejidad hasta que funcione
4. **Agregar ejemplos**: Few-shot learning ayuda mucho
5. **Ajustar temperature**: Probar valores diferentes

**P: ¿Qué hago si Bedrock da errores de throttling?**

R: Soluciones:
1. **Implementar retry con backoff exponencial**
2. **Solicitar aumento de límites** (Service Quotas)
3. **Usar batch processing** en lugar de tiempo real
4. **Distribuir carga** entre múltiples regiones

**P: ¿Cómo monitoreo costos de Bedrock?**

R: Herramientas:
1. **Cost Explorer**: Ver costos por servicio
2. **CloudWatch Metrics**: Tokens procesados
3. **Budgets**: Alertas de presupuesto
4. **Tags**: Etiquetar recursos para tracking

---


## ⏱️ Tiempos Estimados por Módulo

### Día 1 (1h 15min)

| Módulo | Actividad | Tiempo | Acumulado |
|--------|-----------|--------|-----------|
| 0 | Introducción y bienvenida | 5 min | 5 min |
| 1 | Desplegar stack extracción | 5 min | 10 min |
| 1 | Explicar Textract vs Bedrock | 5 min | 15 min |
| 1 | Revisar código de extracción | 10 min | 25 min |
| 1 | Subir PDF y ver logs | 10 min | 35 min |
| 2 | Comparar versiones de prompts | 15 min | 50 min |
| 2 | Experimentar con temperature | 10 min | 60 min |
| 2 | Ejercicio participantes | 5 min | 65 min |
| - | Checkpoint y Q&A | 10 min | 75 min |

**Total Día 1:** 1h 15min

### Día 2 (2h)

| Módulo | Actividad | Tiempo | Acumulado |
|--------|-----------|--------|-----------|
| 3 | Explicar RAG y embeddings | 10 min | 10 min |
| 3 | Desplegar stack RAG | 5 min | 15 min |
| 3 | Generar embeddings | 5 min | 20 min |
| 3 | Demostrar búsqueda similitud | 10 min | 30 min |
| 4 | Explicar few-shot learning | 5 min | 35 min |
| 4 | Desplegar stack clasificación | 5 min | 40 min |
| 4 | Revisar prompt clasificación | 10 min | 50 min |
| 4 | Clasificar y comparar con/sin RAG | 10 min | 60 min |
| 5 | Desplegar stacks resumen y email | 5 min | 65 min |
| 5 | Generar resumen ejecutivo | 10 min | 75 min |
| 5 | Revisar prompts de email | 5 min | 80 min |
| 5 | Enviar emails y mostrar resultados | 10 min | 90 min |
| - | Experimentación libre | 30 min | 120 min |

**Total Día 2:** 2h

**Total Workshop:** 3h 15min

---

## 🎯 Checkpoints Funcionales

### Checkpoint Día 1

**Objetivo:** Verificar que el flujo de extracción funciona end-to-end.

**Verificaciones:**

```bash
# 1. Stacks desplegados
aws cloudformation describe-stacks \
  --stack-name LegacyStack \
  --query 'Stacks[0].StackStatus'
# Esperado: CREATE_COMPLETE

aws cloudformation describe-stacks \
  --stack-name AIExtractionStack \
  --query 'Stacks[0].StackStatus'
# Esperado: CREATE_COMPLETE

# 2. PDF procesado
aws s3 ls s3://<bucket>/external-reports/
# Esperado: Ver al menos 1 PDF

# 3. Datos en Aurora
psql -h <endpoint> -U postgres -d medical_reports \
  -c "SELECT COUNT(*) FROM informes_medicos WHERE origen='EXTERNO';"
# Esperado: >= 1

# 4. Logs en CloudWatch
aws logs tail /aws/lambda/extract-pdf --since 10m
# Esperado: Ver logs de procesamiento exitoso
```

**Criterios de Éxito:**
- ✅ Todos los stacks desplegados
- ✅ Al menos 1 PDF procesado
- ✅ Datos guardados en Aurora
- ✅ Logs muestran éxito

**Si algo falla:**
1. Verificar permisos IAM
2. Verificar modelos habilitados en Bedrock
3. Revisar logs de CloudWatch para errores
4. Verificar conectividad a Aurora

### Checkpoint Día 2

**Objetivo:** Verificar que el flujo completo funciona end-to-end.

**Verificaciones:**

```bash
# 1. Todos los stacks desplegados
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE \
  --query 'StackSummaries[?contains(StackName, `Stack`)].StackName'
# Esperado: 6 stacks (Legacy, Extraction, RAG, Classification, Summary, Email)

# 2. Embeddings generados
psql -h <endpoint> -U postgres -d medical_reports \
  -c "SELECT COUNT(*) FROM informes_embeddings;"
# Esperado: >= 1

# 3. Informes clasificados
psql -h <endpoint> -U postgres -d medical_reports \
  -c "SELECT COUNT(*) FROM informes_medicos WHERE nivel_riesgo IS NOT NULL;"
# Esperado: >= 1

# 4. Resúmenes generados
psql -h <endpoint> -U postgres -d medical_reports \
  -c "SELECT COUNT(*) FROM informes_medicos WHERE resumen_ejecutivo IS NOT NULL;"
# Esperado: >= 1

# 5. Emails enviados
psql -h <endpoint> -U postgres -d medical_reports \
  -c "SELECT COUNT(*) FROM historial_emails WHERE estado='ENVIADO';"
# Esperado: >= 1
```

**Criterios de Éxito:**
- ✅ Todos los stacks desplegados
- ✅ Embeddings generados
- ✅ Clasificación funcionando
- ✅ Resúmenes generados
- ✅ Emails enviados

**Si algo falla:**
1. Verificar que Día 1 funcionó correctamente
2. Verificar email verificado en SES
3. Revisar logs de cada Lambda
4. Verificar datos en Aurora

---

## 📊 Métricas de Éxito del Workshop

### Métricas Técnicas

- ✅ **100% de participantes** completan despliegue del sistema legacy
- ✅ **90%+ de participantes** procesan al menos 1 PDF exitosamente
- ✅ **80%+ de participantes** completan flujo end-to-end
- ✅ **70%+ de participantes** experimentan con prompts

### Métricas de Aprendizaje

Al final del workshop, los participantes deben poder:

- ✅ Explicar diferencia entre Textract y Bedrock
- ✅ Escribir un prompt efectivo
- ✅ Explicar qué es RAG y por qué es útil
- ✅ Describir few-shot learning
- ✅ Ajustar temperature según el caso de uso
- ✅ Desplegar infraestructura con CDK

### Métricas de Satisfacción

- ✅ **4.5+/5** en encuesta de satisfacción
- ✅ **90%+** recomendarían el workshop
- ✅ **80%+** sienten que pueden aplicar lo aprendido

---

## 🛠️ Troubleshooting para el Instructor

### Problema: Error "Model access denied" en Bedrock

**Causa:** Permisos IAM insuficientes.

**Solución:**
1. Verificar que el usuario tiene permisos `bedrock:InvokeModel`
2. Verificar región (us-east-2 o us-east-1 recomendadas)
3. Si es cuenta organizacional, verificar SCPs
4. Los modelos se habilitan automáticamente en la primera invocación

### Problema: Credenciales AWS expiradas durante el workshop

**Causa:** Sesión SSO expirada (común después de 8-12 horas).

**Solución:**
```bash
# Renovar sesión SSO
aws sso login --profile <nombre-perfil>

# Verificar que funciona
aws sts get-caller-identity --profile <nombre-perfil>

# Reintentar comando que falló
```

### Problema: CDK deploy falla con "bucket already exists"

**Causa:** Prefijo no único entre participantes.

**Solución:**
1. Pedir a participante cambiar prefijo en [`cdk/bin/app.ts`](cdk/bin/app.ts)
2. Sugerir formato: `participant-nombre-numero`
3. Verificar que sea único antes de re-desplegar

### Problema: Lambda no puede conectar a Aurora

**Causa:** Security group o VPC mal configurado.

**Solución:**
1. Verificar que Lambda está en la misma VPC que Aurora
2. Verificar security group permite tráfico desde Lambda
3. Verificar subnet tiene ruta a internet (para Bedrock)
4. Revisar logs de CloudWatch para error específico

### Problema: Textract falla con "InvalidS3ObjectException"

**Causa:** PDF corrupto o formato no soportado.

**Solución:**
1. Verificar que el archivo es un PDF válido
2. Probar con PDFs de ejemplo del repositorio
3. Verificar permisos de S3
4. Verificar que el PDF no está encriptado

### Problema: Bedrock responde con JSON inválido

**Causa:** Prompt no es suficientemente específico.

**Solución:**
1. Agregar más ejemplos al prompt
2. Bajar temperature a 0.1
3. Agregar instrucción explícita: "Responde SOLO con JSON válido"
4. Implementar retry con validación

### Problema: Emails no se envían

**Causa:** Email no verificado en SES o cuenta en sandbox.

**Solución:**
1. Verificar email en SES
2. Si está en sandbox, solo puede enviar a emails verificados
3. Solicitar salir de sandbox (toma 24h)
4. Como alternativa, usar SNS para notificaciones

### Problema: Costos más altos de lo esperado

**Causa:** Muchas invocaciones o tokens excesivos.

**Solución:**
1. Revisar CloudWatch Metrics para uso de Bedrock
2. Optimizar prompts para usar menos tokens
3. Implementar caching de respuestas
4. Configurar alertas de presupuesto

---

## 📚 Recursos Adicionales para el Instructor

### Documentación Oficial

- [Amazon Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Amazon Textract Documentation](https://docs.aws.amazon.com/textract/)
- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/)
- [pgvector Documentation](https://github.com/pgvector/pgvector)

### Guías de Prompt Engineering

- [Prompt Engineering Guide](https://www.promptingguide.ai/)
- [OpenAI Best Practices](https://platform.openai.com/docs/guides/prompt-engineering)
- [Anthropic Prompt Library](https://docs.anthropic.com/claude/prompt-library)

### Papers y Artículos

- [RAG: Retrieval-Augmented Generation](https://arxiv.org/abs/2005.11401)
- [Few-Shot Learning](https://arxiv.org/abs/2005.14165)
- [In-Context Learning](https://arxiv.org/abs/2301.00234)

### Comunidades

- [AWS re:Post - Bedrock](https://repost.aws/tags/TA4IHBWMFxRRKzKzuCJAV_Aw/amazon-bedrock)
- [AWS Samples GitHub](https://github.com/aws-samples)
- [Bedrock Workshop](https://catalog.workshops.aws/building-with-amazon-bedrock)

---

## ✅ Checklist Final

### Antes del Workshop

- [ ] Sistema desplegado en cuenta de demostración
- [ ] Email a participantes enviado con prerequisitos

### Durante el Workshop

- [ ] Conectarse 15 minutos antes
- [ ] Tener consola AWS, CloudWatch Logs y terminal listos

### Después del Workshop

- [ ] Enviar encuesta de satisfacción
- [ ] Compartir recursos adicionales
- [ ] Responder preguntas pendientes
- [ ] Recopilar feedback para mejoras
- [ ] Limpiar recursos de demostración

---

## 🎉 Conclusión

Este workshop proporciona una experiencia práctica completa de IA Generativa con AWS. Los participantes no solo aprenden conceptos, sino que construyen un sistema real end-to-end.

**Puntos clave para el éxito:**
1. Mantener el ritmo (3h 15min es ajustado)
2. Enfocarse en conceptos, no solo en código
3. Permitir experimentación
4. Responder preguntas con ejemplos prácticos
5. Conectar cada módulo con el caso de uso real

**Recuerda:** El objetivo no es que memoricen comandos, sino que entiendan los conceptos y puedan aplicarlos en sus propios proyectos.

¡Buena suerte con el workshop! 🚀


---

## 🧹 Limpieza de Recursos Después del Workshop

**⚠️ IMPORTANTE:** Elimina todos los recursos después del workshop para evitar costos innecesarios.

### Opción A: Script Automatizado (Recomendado)

El script elimina todos los recursos en el orden correcto: AI Stacks → Legacy Stacks → Network Stack

```powershell
# PowerShell - Elimina todos los recursos
.\scripts\instructor-cleanup.ps1

# Con parámetros personalizados:
.\scripts\instructor-cleanup.ps1 -ConfigFile config/participants.json -Profile <tu-perfil-aws> -Concurrency 5

# Para participantes específicos:
.\scripts\instructor-cleanup.ps1 -Participants "participant-juan","participant-maria"

# Sin confirmación (para automatización):
.\scripts\instructor-cleanup.ps1 -SkipConfirmation
```

Ver script: [`scripts/instructor-cleanup.ps1`](scripts/instructor-cleanup.ps1)

```bash
# Bash (Linux/Mac)
./scripts/instructor-cleanup.sh

# Con parámetros:
./scripts/instructor-cleanup.sh config/participants.json <tu-perfil-aws> us-east-2
```

Ver script: [`scripts/instructor-cleanup.sh`](scripts/instructor-cleanup.sh)

**Tiempo estimado:** Variable según número de participantes (~5-15 minutos)

**El script:**
- ✅ Elimina en el orden correcto (AI → Legacy → Network)
- ✅ Continúa si un stack falla
- ✅ Genera reporte de errores
- ✅ Verifica recursos huérfanos

### Opción B: Limpieza Manual

Si prefieres eliminar manualmente o el script falla:

#### 1. Eliminar AI Stacks de Cada Participante

```powershell
# PowerShell - Para cada participante
$env:DEPLOY_MODE = "ai"
$env:PARTICIPANT_PREFIX = "participant-juan"
cd cdk
cdk destroy --all --force --profile <tu-perfil-aws>
```

#### 2. Eliminar LegacyStacks

```powershell
# PowerShell - Para cada participante
$env:DEPLOY_MODE = "legacy"
$env:PARTICIPANT_PREFIX = "participant-juan"
cd cdk
cdk destroy participant-juan-MedicalReportsLegacyStack --force --profile <tu-perfil-aws>
```

#### 3. Eliminar SharedNetworkStack

```powershell
# PowerShell - Una sola vez al final
$env:DEPLOY_MODE = "network"
cd cdk
cdk destroy SharedNetworkStack --force --profile <tu-perfil-aws>
```

### Verificación de Limpieza

Verifica que no quedan recursos:

```powershell
# Listar stacks restantes
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --profile <tu-perfil-aws>

# Verificar buckets S3 (deben estar vacíos)
aws s3 ls --profile <tu-perfil-aws>

# Verificar bases de datos Aurora
aws rds describe-db-clusters --profile <tu-perfil-aws>
```

### Recursos que se Eliminan

Por cada participante:
- ✅ 5 AI Stacks (Lambdas de IA)
- ✅ 1 LegacyStack (Aurora, S3, API Gateway, Lambdas)
- ✅ Security Groups
- ✅ Roles y políticas IAM

Infraestructura compartida:
- ✅ SharedNetworkStack (VPC, NAT Gateway, subnets)

### Troubleshooting de Limpieza

**Error: "Stack cannot be deleted while it has dependent stacks"**
- Elimina primero los AI Stacks, luego Legacy, luego Network
- El script automatizado ya maneja este orden

**Error: "Bucket not empty"**
- Los buckets S3 tienen `autoDeleteObjects: true`
- Si falla, vacía manualmente: `aws s3 rm s3://bucket-name --recursive`

**Error: "Resource being used by another resource"**
- Espera unos minutos y reintenta
- Verifica en la consola de CloudFormation qué recurso está bloqueando

**Stacks en estado DELETE_FAILED**
- Revisa los eventos en CloudFormation para ver qué falló
- Elimina manualmente el recurso problemático
- Reintenta la eliminación del stack

### Costos Estimados

Si olvidas eliminar los recursos, los costos aproximados son:

| Recurso | Costo por hora | Costo por día |
|---------|----------------|---------------|
| Aurora Serverless v2 (0.5 ACU) | ~$0.06 | ~$1.44 |
| NAT Gateway | ~$0.045 | ~$1.08 |
| Lambdas (idle) | $0 | $0 |
| S3 (storage) | Mínimo | Mínimo |
| **Total por participante** | **~$0.06** | **~$1.44** |
| **10 participantes + VPC** | **~$0.65** | **~$15.60** |

**⚠️ Recomendación:** Elimina los recursos inmediatamente después del workshop para evitar costos innecesarios.

---

## 📊 Resumen de Comandos Rápidos

### Preparación Antes del Workshop

```powershell
# 1. Configurar participantes
# Editar: config/participants.json

# 2. Verificar emails en SES
aws ses verify-email-identity --email-address EMAIL --profile <tu-perfil-aws>

# 3. Desplegar VPC compartida (~8 min)
.\scripts\instructor-deploy-network.ps1

# 4. Desplegar LegacyStacks (~20 min para 10 participantes)
.\scripts\instructor-deploy-legacy.ps1

# 5. Verificar despliegue
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --profile <tu-perfil-aws>
```

### Durante el Workshop (Participantes)

```powershell
# Participantes despliegan AI Stacks (~5-8 min)
.\scripts\participant-deploy-ai.ps1 -ParticipantPrefix "participant-X" -VerifiedEmail "email@example.com"
```

### Después del Workshop

```powershell
# Limpieza completa
.\scripts\instructor-cleanup.ps1
```

---

## 📚 Documentación Adicional

- **Modos de despliegue:** Ver [`cdk/DEPLOY_MODES.md`](cdk/DEPLOY_MODES.md)
- **Configuración de participantes:** Ver [`config/README.md`](config/README.md)
- **Arquitectura técnica:** Ver [`.kiro/specs/workshop-deployment-optimization/design.md`](.kiro/specs/workshop-deployment-optimization/design.md)
- **Guía para participantes:** Ver [`PARTICIPANT_GUIDE.md`](PARTICIPANT_GUIDE.md)

---

## 🆘 Soporte Durante el Workshop

### Problemas Comunes

**"Mi despliegue está tardando mucho"**
- Tiempo normal: 5-8 minutos
- Si tarda >10 minutos, verificar CloudFormation en consola
- Posible causa: Límites de servicio alcanzados

**"Error: LegacyStack no encontrado"**
- El instructor debe haber desplegado el LegacyStack primero
- Verificar: `aws cloudformation describe-stacks --stack-name participant-X-MedicalReportsLegacyStack`

**"Error: Token expirado"**
- Renovar sesión: `aws sso login --profile <tu-perfil-aws>`
- Los scripts lo hacen automáticamente

**"No puedo enviar emails"**
- Verificar que el email está verificado en SES
- Si la cuenta está en SES Sandbox, solo se pueden enviar a emails verificados

### Contacto de Emergencia

Durante el workshop, ten a mano:
- Consola de CloudFormation
- CloudWatch Logs
- Documentación de Bedrock
- Este INSTRUCTOR_GUIDE.md

---

**¡Éxito con tu workshop! 🚀**
