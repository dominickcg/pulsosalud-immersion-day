# Modos de Despliegue - Workshop Medical Reports Automation

Este proyecto soporta diferentes modos de despliegue para optimizar el tiempo durante el workshop.

## Variables de Entorno

- `DEPLOY_MODE`: Controla qué stacks se despliegan (`network`, `legacy`, `ai`, `all`)
- `PARTICIPANT_PREFIX`: Identificador único del participante (ej: `participant-1`, `participant-2`)
- `VERIFIED_EMAIL`: Email verificado en SES (típicamente el email del instructor, el mismo para todos)

## Modos de Despliegue

### 1. Modo `network` - Desplegar VPC Compartida

**Quién:** Instructor antes del workshop  
**Cuándo:** Una sola vez antes del workshop  
**Tiempo:** ~8 minutos

```powershell
# PowerShell
$env:DEPLOY_MODE = "network"
cdk deploy SharedNetworkStack --profile pulsosalud-immersion
```

```bash
# Bash
export DEPLOY_MODE=network
cdk deploy SharedNetworkStack --profile pulsosalud-immersion
```

**Recursos creados:**
- VPC compartida (10.0.0.0/16)
- 2 Subnets públicas
- 2 Subnets privadas
- 2 Subnets aisladas
- 1 NAT Gateway
- 1 Internet Gateway

---

### 2. Modo `legacy` - Desplegar Stack Legacy por Participante

**Quién:** Instructor antes del workshop  
**Cuándo:** Para cada participante antes del workshop  
**Tiempo:** ~15 minutos por participante

```powershell
# PowerShell - Un participante
$env:DEPLOY_MODE = "legacy"
$env:PARTICIPANT_PREFIX = "participant-1"
cdk deploy participant-1-MedicalReportsLegacyStack --profile pulsosalud-immersion

# PowerShell - Múltiples participantes en paralelo (usuarios genéricos)
$env:DEPLOY_MODE = "legacy"
cdk deploy `
  participant-1-MedicalReportsLegacyStack `
  participant-2-MedicalReportsLegacyStack `
  participant-3-MedicalReportsLegacyStack `
  --concurrency 3 `
  --profile pulsosalud-immersion
```

```bash
# Bash - Un participante
export DEPLOY_MODE=legacy
export PARTICIPANT_PREFIX=participant-1
cdk deploy participant-1-MedicalReportsLegacyStack --profile pulsosalud-immersion

# Bash - Múltiples participantes en paralelo (usuarios genéricos)
export DEPLOY_MODE=legacy
cdk deploy \
  participant-1-MedicalReportsLegacyStack \
  participant-2-MedicalReportsLegacyStack \
  participant-3-MedicalReportsLegacyStack \
  --concurrency 3 \
  --profile pulsosalud-immersion
```

**Recursos creados por participante:**
- Aurora Serverless v2 (en VPC compartida)
- S3 Bucket individual
- API Gateway
- 3 Lambdas Legacy (register-exam, generate-pdf, generate-test-data)
- Security Groups individuales

---

### 3. Modo `ai` - Desplegar AI Stacks

**Quién:** Participantes durante el workshop  
**Cuándo:** Durante el Día 1 del workshop  
**Tiempo:** ~5-8 minutos  
**Dónde:** AWS CloudShell (recomendado) o terminal local

```bash
# CloudShell (Recomendado - No requiere instalaciones)
# CloudShell ya tiene credenciales configuradas automáticamente
export DEPLOY_MODE=ai
export PARTICIPANT_PREFIX=participant-1  # Tu número asignado
export VERIFIED_EMAIL=instructor@example.com  # Email del instructor
cdk deploy --all --require-approval never
```

```powershell
# PowerShell (Si usas tu máquina local)
$env:DEPLOY_MODE = "ai"
$env:PARTICIPANT_PREFIX = "participant-1"
$env:VERIFIED_EMAIL = "instructor@example.com"
cdk deploy --all --profile pulsosalud-immersion
```

```bash
# Bash
export DEPLOY_MODE=ai
export PARTICIPANT_PREFIX=participant-juan
export VERIFIED_EMAIL=juan@example.com
cdk deploy --all --profile pulsosalud-immersion
```

**Recursos creados:**
- 5 AI Stacks con Lambdas de procesamiento de IA:
  - AIExtractionStack (extract-pdf)
  - AIRAGStack (generate-embeddings + similarity-search layer)
  - AIClassificationStack (classify-risk)
  - AISummaryStack (generate-summary)
  - AIEmailStack (send-email)

---

### 4. Modo `all` - Desplegar Todo (Compatibilidad hacia atrás)

**Quién:** Desarrollo local o testing  
**Cuándo:** Para probar el sistema completo  
**Tiempo:** ~25-35 minutos

```powershell
# PowerShell
$env:DEPLOY_MODE = "all"
$env:PARTICIPANT_PREFIX = "demo"
$env:VERIFIED_EMAIL = "demo@example.com"
cdk deploy --all --profile pulsosalud-immersion
```

```bash
# Bash
export DEPLOY_MODE=all
export PARTICIPANT_PREFIX=demo
export VERIFIED_EMAIL=demo@example.com
cdk deploy --all --profile pulsosalud-immersion
```

**Recursos creados:**
- SharedNetworkStack
- LegacyStack
- Todos los AI Stacks

---

## Flujo de Trabajo del Workshop

### Antes del Workshop (Instructor)

1. **Desplegar VPC compartida** (una sola vez):
   ```powershell
   $env:DEPLOY_MODE = "network"
   cdk deploy SharedNetworkStack --profile pulsosalud-immersion
   ```

2. **Desplegar LegacyStacks** (para todos los participantes):
   ```powershell
   $env:DEPLOY_MODE = "legacy"
   cdk deploy `
     participant-1-MedicalReportsLegacyStack `
     participant-2-MedicalReportsLegacyStack `
     participant-3-MedicalReportsLegacyStack `
     --concurrency 3 `
     --profile pulsosalud-immersion
   ```

### Durante el Workshop (Participantes)

**Día 1 - Primeros 8 minutos:**
```powershell
$env:DEPLOY_MODE = "ai"
$env:PARTICIPANT_PREFIX = "participant-X"  # Asignado por el instructor
$env:VERIFIED_EMAIL = "tu-email@example.com"
cdk deploy --all --profile pulsosalud-immersion
```

---

## Limpieza Después del Workshop

**Orden correcto:** AI Stacks → Legacy Stacks → Network Stack

```powershell
# 1. Eliminar AI Stacks de todos los participantes
$env:DEPLOY_MODE = "ai"
$env:PARTICIPANT_PREFIX = "participant-1"
cdk destroy --all --profile pulsosalud-immersion

# 2. Eliminar Legacy Stacks
$env:DEPLOY_MODE = "legacy"
cdk destroy participant-1-MedicalReportsLegacyStack --profile pulsosalud-immersion

# 3. Eliminar Network Stack (al final)
$env:DEPLOY_MODE = "network"
cdk destroy SharedNetworkStack --profile pulsosalud-immersion
```

---

## Verificación de Dependencias

Antes de desplegar, verificar que las dependencias existen:

```powershell
# Verificar que SharedNetworkStack existe antes de desplegar Legacy
aws cloudformation describe-stacks --stack-name SharedNetworkStack --profile pulsosalud-immersion

# Verificar que LegacyStack existe antes de desplegar AI
aws cloudformation describe-stacks --stack-name participant-juan-MedicalReportsLegacyStack --profile pulsosalud-immersion
```

---

## Troubleshooting

### Error: "Export SharedNetworkStack-VpcId not found"

**Causa:** SharedNetworkStack no está desplegado  
**Solución:** Desplegar primero con `DEPLOY_MODE=network`

### Error: "Export participant-X-BucketName not found"

**Causa:** LegacyStack del participante no está desplegado  
**Solución:** El instructor debe desplegar primero con `DEPLOY_MODE=legacy`

### Error: "Stack already exists"

**Causa:** Intentando desplegar un stack que ya existe  
**Solución:** Usar `cdk deploy` sin `--all` para actualizar, o `cdk destroy` para eliminar primero


---

## 🌐 Usando AWS CloudShell (Recomendado para Participantes)

AWS CloudShell es un terminal basado en navegador que viene pre-configurado con AWS CLI y credenciales.

### Ventajas de CloudShell

✅ **Sin instalaciones**: No necesitas instalar AWS CLI, Node.js, o Python localmente
✅ **Credenciales automáticas**: Ya está autenticado con tu usuario AWS
✅ **Mismo entorno para todos**: Todos los participantes usan el mismo entorno
✅ **Acceso desde cualquier lugar**: Solo necesitas un navegador web

### Cómo Usar CloudShell

1. **Abrir CloudShell:**
   - Inicia sesión en AWS Console
   - Haz clic en el ícono de terminal (>_) en la barra superior derecha
   - O busca "CloudShell" en la barra de búsqueda

2. **Instalar CDK (solo primera vez):**
   ```bash
   npm install -g aws-cdk
   cdk --version
   ```

3. **Clonar repositorio:**
   ```bash
   git clone <repository-url>
   cd medical-reports-automation
   ```

4. **Desplegar:**
   ```bash
   ./scripts/participant-deploy-ai.sh participant-1 instructor@example.com
   ```

### Limitaciones de CloudShell

- ⚠️ Se desconecta después de ~20 minutos de inactividad (solo recarga la página)
- ⚠️ 1 GB de almacenamiento persistente en `/home/cloudshell-user`
- ⚠️ Puede ser más lento que tu máquina local para `npm install`

### Troubleshooting CloudShell

**"CloudShell no está disponible en mi región"**
- CloudShell está disponible en us-east-2 (Ohio)
- Cambia a una región soportada desde el selector de región

**"npm install está tardando mucho"**
- Es normal en CloudShell, puede tardar 2-3 minutos
- Solo espera, eventualmente completará

**"Se desconectó mi sesión"**
- Recarga la página del navegador
- Tus archivos en `/home/cloudshell-user` se mantienen

---

## 📝 Usuarios Genéricos vs Específicos

### Enfoque Recomendado: Usuarios Genéricos

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
    }
  ]
}
```

**Ventajas:**
- ✅ Solo necesitas verificar un email en SES (el del instructor)
- ✅ Usuarios reutilizables para múltiples workshops
- ✅ No necesitas recopilar emails de participantes
- ✅ Más fácil de gestionar

**Flujo:**
1. Instructor verifica su email en SES
2. Instructor crea usuarios IAM genéricos (`workshop-user-1`, `workshop-user-2`, etc.)
3. Instructor despliega LegacyStacks con el mismo email para todos
4. Participantes usan su número asignado y el email del instructor

### Enfoque Alternativo: Usuarios Específicos

Si prefieres usar emails individuales de participantes:

```json
{
  "participants": [
    {
      "prefix": "participant-juan",
      "email": "juan@example.com",
      "iamUsername": "workshop-juan"
    }
  ]
}
```

**Desventajas:**
- ❌ Necesitas verificar cada email en SES
- ❌ Necesitas recopilar emails de participantes antes del workshop
- ❌ Usuarios no reutilizables

---

## 🎯 Resumen de Mejores Prácticas

### Para el Instructor

1. **Usa usuarios genéricos** (`participant-1`, `participant-2`, etc.)
2. **Verifica solo tu email** en SES (no el de cada participante)
3. **Usa los scripts automatizados** para despliegue y limpieza
4. **Despliega en paralelo** con `--concurrency` para ahorrar tiempo

### Para los Participantes

1. **Usa AWS CloudShell** (no requiere instalaciones)
2. **Usa el script automatizado** `participant-deploy-ai.sh`
3. **Usa el número asignado** por el instructor
4. **Usa el email del instructor** (no tu email personal)

---

**Documentación adicional:**
- Ver `INSTRUCTOR_GUIDE.md` para preparación completa del workshop
- Ver `PARTICIPANT_GUIDE.md` para instrucciones de participantes
- Ver `config/README.md` para formato de configuración
