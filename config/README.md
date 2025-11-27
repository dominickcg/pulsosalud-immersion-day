# Configuración de Participantes del Workshop

Este directorio contiene la configuración de los participantes del workshop.

## Archivo: participants.json

Este archivo define la lista de participantes que tendrán infraestructura desplegada para el workshop.

### Formato

```json
{
  "participants": [
    {
      "prefix": "participant-1",
      "email": "participant1@example.com",
      "iamUsername": "workshop-participant-1"
    }
  ]
}
```

### Campos

#### `prefix` (requerido)
- **Tipo:** String
- **Descripción:** Identificador único del participante usado para nombrar todos sus recursos
- **Formato:** Debe seguir el patrón `participant-X` o similar
- **Restricciones:** 
  - Solo letras minúsculas, números y guiones
  - Debe ser único entre todos los participantes
  - Máximo 20 caracteres (para evitar límites de nombres de recursos AWS)
- **Ejemplos:** 
  - `participant-1`
  - `participant-juan`
  - `participant-maria`

#### `email` (requerido)
- **Tipo:** String
- **Descripción:** Email verificado en SES para envío de notificaciones
- **Formato:** Dirección de email válida
- **Nota:** **Usa el email del instructor** (el mismo para todos los participantes)
- **Ventaja:** Solo necesitas verificar un email en SES, no uno por participante
- **Ejemplos:**
  - `instructor@example.com` (el mismo para todos)
  - `workshop-admin@company.com` (el mismo para todos)

#### `iamUsername` (opcional)
- **Tipo:** String
- **Descripción:** Nombre de usuario IAM del participante (si se usan usuarios IAM individuales)
- **Formato:** Nombre de usuario IAM válido
- **Nota:** Solo necesario si cada participante tiene su propio usuario IAM
- **Ejemplos:**
  - `workshop-participant-1`
  - `juan-workshop`

## Uso

### Para el Instructor

Este archivo es usado por los scripts de despliegue y limpieza:

```powershell
# Desplegar LegacyStacks para todos los participantes
.\scripts\instructor-deploy-legacy.ps1

# Limpiar todos los recursos
.\scripts\instructor-cleanup.ps1
```

Los scripts leerán automáticamente `config/participants.json` para obtener la lista de participantes.

### Preparación Antes del Workshop

1. **Editar participants.json** con la lista real de participantes
2. **Verificar emails en SES** para cada participante:
   ```powershell
   aws ses verify-email-identity --email-address participant@example.com --profile pulsosalud-immersion
   ```
3. **Crear usuarios IAM** (si es necesario) para cada participante
4. **Desplegar infraestructura** usando los scripts del instructor

## Ejemplo Completo (Usuarios Genéricos - Recomendado)

```json
{
  "participants": [
    {
      "prefix": "participant-1",
      "email": "instructor@company.com",
      "iamUsername": "workshop-user-1"
    },
    {
      "prefix": "participant-2",
      "email": "instructor@company.com",
      "iamUsername": "workshop-user-2"
    },
    {
      "prefix": "participant-3",
      "email": "instructor@company.com",
      "iamUsername": "workshop-user-3"
    },
    {
      "prefix": "participant-4",
      "email": "instructor@company.com",
      "iamUsername": "workshop-user-4"
    },
    {
      "prefix": "participant-5",
      "email": "instructor@company.com",
      "iamUsername": "workshop-user-5"
    }
  ]
}
```

**Ventajas de este enfoque:**
- ✅ Solo necesitas verificar un email en SES (el del instructor)
- ✅ Usuarios genéricos reutilizables para múltiples workshops
- ✅ No necesitas recopilar emails de participantes
- ✅ Más fácil de gestionar y mantener

## Límites y Consideraciones

### Límites de AWS CloudFormation
- **Máximo de exports por región:** 200
- **Exports por participante:** 6 (del LegacyStack)
- **Exports compartidos:** 4 (del SharedNetworkStack)
- **Máximo teórico de participantes:** (200 - 4) / 6 = 32 participantes

### Límites de VPC
- **CIDR de VPC:** 10.0.0.0/16 (65,536 IPs)
- **IPs por participante:** ~10 ENIs (Elastic Network Interfaces)
- **Máximo práctico de participantes:** ~6,500 (muy por encima de las necesidades)

### Recomendaciones
- **Para workshops pequeños (< 10 participantes):** Sin problemas
- **Para workshops medianos (10-20 participantes):** Considerar despliegue en lotes
- **Para workshops grandes (> 20 participantes):** Considerar múltiples regiones o cuentas

## Troubleshooting

### Error: "Export already exists"
**Causa:** Dos participantes tienen el mismo prefix  
**Solución:** Asegurar que todos los prefix son únicos

### Error: "Email not verified in SES"
**Causa:** El email del participante no está verificado en Amazon SES  
**Solución:** Verificar el email antes del workshop:
```powershell
aws ses verify-email-identity --email-address EMAIL --profile pulsosalud-immersion
```

### Error: "Invalid prefix format"
**Causa:** El prefix contiene caracteres no permitidos  
**Solución:** Usar solo letras minúsculas, números y guiones

## Scripts que Usan Este Archivo

- `scripts/instructor-deploy-legacy.ps1` - Despliegue de LegacyStacks
- `scripts/instructor-deploy-legacy.sh` - Despliegue de LegacyStacks (Bash)
- `scripts/instructor-cleanup.ps1` - Limpieza de recursos
- `scripts/instructor-cleanup.sh` - Limpieza de recursos (Bash)

## Plantilla para Copiar

```json
{
  "participants": [
    {
      "prefix": "participant-NOMBRE",
      "email": "email@example.com",
      "iamUsername": "workshop-NOMBRE"
    }
  ]
}
```

Reemplazar `NOMBRE` y `email@example.com` con los datos reales de cada participante.
