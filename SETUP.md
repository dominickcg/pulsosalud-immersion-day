# Setup Instructions

## Prerequisitos

Antes de comenzar, asegúrate de tener instalado:

1. **Node.js** (versión 18 o superior)
   - Descarga desde: https://nodejs.org/
   - Verifica la instalación: `node --version`

2. **AWS CLI** configurado con credenciales
   - Descarga desde: https://aws.amazon.com/cli/
   - Configura: `aws configure`

3. **AWS CDK CLI**
   ```bash
   npm install -g aws-cdk
   ```

## Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd pulsosalud-immersion-day
   ```

2. **Instalar dependencias de CDK**
   ```bash
   cd cdk
   npm install
   ```

3. **Configurar prefijo único del participante**
   ```bash
   export PARTICIPANT_PREFIX="participante-01"
   ```
   
   O en Windows PowerShell:
   ```powershell
   $env:PARTICIPANT_PREFIX="participante-01"
   ```

4. **Bootstrap CDK (solo la primera vez)**
   ```bash
   cdk bootstrap
   ```

5. **Desplegar el sistema legacy**
   ```bash
   cdk deploy
   ```

## Verificación

Después del despliegue, deberías ver outputs con:
- URL del API Gateway
- Nombre del bucket S3
- ARN del cluster Aurora
- ARN del secreto de la base de datos

## Limpieza

Para eliminar todos los recursos:
```bash
cdk destroy
```

**Nota:** Aurora se eliminará completamente sin crear snapshots gracias a la configuración `removalPolicy: DESTROY`.

## Troubleshooting

### Error: "npm no se reconoce"
- Instala Node.js desde https://nodejs.org/
- **Importante:** Después de instalar Node.js, **reinicia tu terminal/IDE** para que el PATH se actualice
- Si el problema persiste, verifica que Node.js esté en el PATH del sistema

### Error: "la ejecución de scripts está deshabilitada"
- En Windows, usa el archivo `.cmd` directamente:
  ```powershell
  & "C:\Program Files\nodejs\npm.cmd" install
  ```
- O habilita la ejecución de scripts (como administrador):
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

### Error: "cdk no se reconoce"
- Instala AWS CDK globalmente: `npm install -g aws-cdk`
- O usa npx: `npx cdk deploy`

### Error: "Need to perform AWS calls for account..."
- Ejecuta: `cdk bootstrap`

### Error de permisos IAM
- Verifica que tu usuario IAM tenga permisos para crear recursos (VPC, RDS, Lambda, S3, API Gateway)

### Errores de TypeScript en el IDE
- Asegúrate de haber ejecutado `npm install` en el directorio `cdk/`
- Los errores deberían desaparecer automáticamente después de instalar las dependencias
