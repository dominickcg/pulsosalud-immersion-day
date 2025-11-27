# Medical Reports Automation - CDK Infrastructure

Este directorio contiene la infraestructura como código (IaC) usando AWS CDK para el sistema de automatización de informes médicos.

## Estructura

- `bin/app.ts` - Punto de entrada de la aplicación CDK
- `lib/legacy-stack.ts` - Stack del sistema legacy (Aurora, S3, API Gateway, Lambdas)
- `lib/ai-extraction-stack.ts` - Stack para extracción con IA (Textract + Bedrock)
- `lib/ai-rag-stack.ts` - Stack para RAG con embeddings
- `lib/ai-classification-stack.ts` - Stack para clasificación de riesgo
- `lib/ai-summary-stack.ts` - Stack para generación de resúmenes
- `lib/ai-email-stack.ts` - Stack para envío de emails personalizados

## Prerequisitos

```bash
npm install -g aws-cdk
npm install
```

## Configuración del Prefijo Único

Cada participante debe usar un prefijo único para evitar conflictos de nombres:

```bash
export PARTICIPANT_PREFIX="participante-01"
```

O al desplegar:

```bash
cdk deploy --context participantPrefix=participante-01
```

## Comandos

```bash
# Compilar TypeScript
npm run build

# Sintetizar CloudFormation template
cdk synth

# Desplegar el stack legacy
cdk deploy

# Destruir todos los recursos (incluyendo Aurora sin snapshots)
cdk destroy
```

## Despliegue Progresivo (Para la Demo)

### Día 1 (1h 15min)

```bash
# 1. Desplegar sistema legacy (5 min)
cdk deploy *LegacyStack

# 2. Desplegar extracción con IA (resto del Día 1)
cdk deploy *AIExtractionStack
```

### Día 2 (2h)

```bash
# 3. Desplegar RAG
cdk deploy *AIRagStack

# 4. Desplegar clasificación
cdk deploy *AIClassificationStack

# 5. Desplegar resúmenes
cdk deploy *AISummaryStack

# 6. Desplegar emails
cdk deploy *AIEmailStack
```

## Notas Importantes

- Aurora Serverless v2 está configurado con escalado mínimo de 0.5 ACU y máximo de 1 ACU para optimizar costos
- Todos los recursos tienen `removalPolicy: DESTROY` para facilitar la limpieza después de la demo
- Los nombres de recursos incluyen el prefijo del participante para evitar conflictos en cuenta compartida
