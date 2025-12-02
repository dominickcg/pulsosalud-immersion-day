# Scripts de Ejemplo - Medical Reports Workshop

Este directorio contiene scripts de ejemplo y helpers para facilitar la interacción con los recursos AWS durante el workshop.

## 📋 Contenido

| Script | Descripción | Uso |
|--------|-------------|-----|
| `setup-env-vars-cloudshell.sh` | Configura variables de entorno en CloudShell (bash) | **Para participantes en CloudShell** |
| `setup-env-vars.ps1` | Configura variables de entorno en PowerShell local | **Para instructores/desarrollo local** |
| `invoke-classify.ps1` | Invoca la Lambda de clasificación de riesgo | Probar clasificación de informes |
| `invoke-summary.ps1` | Invoca la Lambda de generación de resúmenes | Probar generación de resúmenes |
| `view-logs.ps1` | Visualiza logs de CloudWatch de las Lambdas | Debugging y monitoreo |
| `queries.sql` | Colección de queries SQL para verificación | Consultar datos en Aurora |

## 🚀 Inicio Rápido

### 1. Configurar Variables de Entorno

**Antes de usar cualquier script**, debes configurar tus variables de entorno:

#### Para Participantes (CloudShell - bash)

```bash
# 1. Editar el script y reemplazar "participant-X" con tu prefijo
nano setup-env-vars-cloudshell.sh

# 2. Ejecutar el script (IMPORTANTE: usar 'source' para que las variables persistan)
source setup-env-vars-cloudshell.sh
```

#### Para Instructores/Desarrollo Local (PowerShell)

```powershell
# 1. Editar el script y reemplazar "participant-X" con tu prefijo
notepad setup-env-vars.ps1

# 2. Ejecutar el script
.\setup-env-vars.ps1
```

Esto configurará automáticamente:
- `$CLUSTER_ARN` (bash) o `$env:CLUSTER_ARN` (PowerShell) - ARN del cluster Aurora
- `$SECRET_ARN` (bash) o `$env:SECRET_ARN` (PowerShell) - ARN del secret de Aurora
- `$DATABASE_NAME` (bash) o `$env:DATABASE_NAME` (PowerShell) - Nombre de la base de datos
- `$API_GATEWAY_URL` (bash) o `$env:API_GATEWAY_URL` (PowerShell) - URL de API Gateway
- `$WEBSITE_URL` (bash) o `$env:WEBSITE_URL` (PowerShell) - URL de la App Web

### 2. Clasificar un Informe

```powershell
# 1. Editar el script y reemplazar "participant-X" con tu prefijo
notepad invoke-classify.ps1

# 2. Opcionalmente, cambiar el ID del informe (línea 14)
# $INFORME_ID = 1

# 3. Ejecutar el script
.\invoke-classify.ps1
```

**Salida esperada:**
```
🔍 Clasificando informe médico #1...

📤 Invocando Lambda: participant-1-classify-risk
✅ Lambda invocada exitosamente!

📄 Respuesta:
   Informe ID: 1
   Nivel de Riesgo: MEDIO
   Justificación:
   El trabajador presenta presión arterial elevada (140/90 mmHg)...
   
   Tiempo de procesamiento: 2.3s
```

### 3. Generar un Resumen

```powershell
# 1. Editar el script y reemplazar "participant-X" con tu prefijo
notepad invoke-summary.ps1

# 2. Opcionalmente, cambiar el ID del informe (línea 14)
# $INFORME_ID = 1

# 3. Ejecutar el script
.\invoke-summary.ps1
```

**Nota:** El informe debe estar clasificado antes de generar el resumen.

### 4. Ver Logs de CloudWatch

```powershell
# 1. Editar el script y reemplazar "participant-X" con tu prefijo
notepad view-logs.ps1

# 2. Ejecutar el script
.\view-logs.ps1

# 3. Seleccionar la Lambda que quieres monitorear
# 4. Elegir si quieres ver logs históricos o seguir en tiempo real
```

### 5. Consultar la Base de Datos

```powershell
# Opción A: Ejecutar una query específica
aws rds-data execute-statement \
  --resource-arn $env:CLUSTER_ARN \
  --secret-arn $env:SECRET_ARN \
  --database $env:DATABASE_NAME \
  --sql "SELECT * FROM trabajadores" \
  --output table

# Opción B: Usar las queries del archivo queries.sql
# Abre queries.sql, copia la query que necesites, y ejecútala
```

## 📝 Personalización

### Cambiar el Prefijo del Participante

Todos los scripts tienen una variable `$PARTICIPANT_PREFIX` al inicio:

```powershell
# IMPORTANTE: Reemplaza "participant-X" con tu prefijo asignado
$PARTICIPANT_PREFIX = "participant-X"
```

Cambia `"participant-X"` por tu prefijo asignado (ej: `"participant-1"`).

### Probar Diferentes Informes

En los scripts de invocación, puedes cambiar el ID del informe:

```powershell
# ID del informe a clasificar (1-10 disponibles en la base de datos)
$INFORME_ID = 1  # Cambiar a 2, 3, 4, etc.
```

Los informes disponibles son:
- **Informes 1-3:** Riesgo BAJO
- **Informes 4-7:** Riesgo MEDIO
- **Informes 8-10:** Riesgo ALTO

## 🔍 Troubleshooting

### Error: "Lambda not found"

**Causa:** El prefijo del participante es incorrecto o el stack no está desplegado.

**Solución:**
```powershell
# Verificar que el stack está desplegado
aws cloudformation describe-stacks --stack-name participant-X-AIClassificationStack

# Listar tus Lambdas
aws lambda list-functions --query 'Functions[?contains(FunctionName, `participant-X`)]'
```

### Error: "Access denied to Aurora"

**Causa:** Las variables de entorno no están configuradas o son incorrectas.

**Solución:**
```powershell
# Re-ejecutar el script de configuración
.\setup-env-vars.ps1

# Verificar que las variables están configuradas
echo $env:CLUSTER_ARN
echo $env:SECRET_ARN
```

### Error: "Informe not classified"

**Causa:** Intentaste generar un resumen antes de clasificar el informe.

**Solución:**
```powershell
# Primero clasificar
.\invoke-classify.ps1

# Luego generar resumen
.\invoke-summary.ps1
```

### Los logs no aparecen

**Causa:** Los logs de CloudWatch pueden tardar 1-2 minutos en aparecer.

**Solución:**
- Espera un momento y vuelve a intentar
- Verifica que la Lambda se ejecutó correctamente
- Usa `--since 5m` para ver logs más recientes

## 💡 Tips y Trucos

### 1. Automatizar el Flujo Completo

```powershell
# Clasificar y generar resumen en un solo comando
.\invoke-classify.ps1; Start-Sleep -Seconds 3; .\invoke-summary.ps1
```

### 2. Procesar Múltiples Informes

```powershell
# Clasificar informes del 1 al 5
1..5 | ForEach-Object {
    Write-Host "Procesando informe $_..."
    # Modificar $INFORME_ID en el script antes de ejecutar
}
```

### 3. Monitorear en Tiempo Real

```powershell
# Abrir dos ventanas de PowerShell:
# Ventana 1: Seguir logs
.\view-logs.ps1  # Seleccionar opción 2 (seguir en tiempo real)

# Ventana 2: Invocar Lambdas
.\invoke-classify.ps1
```

### 4. Exportar Resultados

```powershell
# Guardar respuesta en archivo
.\invoke-classify.ps1 > resultado-clasificacion.txt

# Guardar logs en archivo
aws logs tail /aws/lambda/participant-X-classify-risk --since 1h > logs.txt
```

### 5. Verificar Estado de Todos los Informes

```powershell
# Usar query SQL para ver estado
aws rds-data execute-statement \
  --resource-arn $env:CLUSTER_ARN \
  --secret-arn $env:SECRET_ARN \
  --database $env:DATABASE_NAME \
  --sql "SELECT id, nivel_riesgo, CASE WHEN resumen_ejecutivo IS NOT NULL THEN 'Sí' ELSE 'No' END as tiene_resumen FROM informes_medicos ORDER BY id" \
  --output table
```

## 📚 Recursos Adicionales

- **[PARTICIPANT_GUIDE.md](../../PARTICIPANT_GUIDE.md)** - Guía completa del workshop
- **[INSTRUCTOR_GUIDE.md](../../INSTRUCTOR_GUIDE.md)** - Guía para instructores
- **[AWS CLI Reference](https://docs.aws.amazon.com/cli/)** - Documentación de AWS CLI
- **[RDS Data API](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/data-api.html)** - Documentación de RDS Data API

## 🤝 Soporte

Si encuentras problemas con estos scripts:

1. Verifica que tu prefijo de participante es correcto
2. Asegúrate de que los stacks están desplegados correctamente
3. Revisa los logs de CloudWatch para más detalles
4. Consulta la sección de Troubleshooting en [PARTICIPANT_GUIDE.md](../../PARTICIPANT_GUIDE.md)
5. Pregunta al instructor durante el workshop

---

**¡Feliz aprendizaje!** 🚀
