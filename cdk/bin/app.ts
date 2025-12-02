#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { PulsoSaludNetworkStack } from '../lib/shared-network-stack';
import { LegacyStack } from '../lib/legacy-stack';
import { AIExtractionStack } from '../lib/ai-extraction-stack';
import { AIRAGStack } from '../lib/ai-rag-stack';
import { AIClassificationStack } from '../lib/ai-classification-stack';
import { AISummaryStack } from '../lib/ai-summary-stack';
import { AIEmailStack } from '../lib/ai-email-stack';
import { StackValidator } from '../lib/stack-validator';

async function main() {
  const app = new cdk.App();

  // ========================================
  // Configuración de Despliegue
  // ========================================

  // Obtener el prefijo único del participante desde el contexto o variable de entorno
  // Por defecto usa 'demo' si no se especifica
  const participantPrefix = app.node.tryGetContext('participantPrefix') || process.env.PARTICIPANT_PREFIX || 'demo';

  // Obtener el modo de despliegue desde el contexto o variable de entorno
  // Modos disponibles: 'network', 'legacy', 'ai', 'all'
  // Por defecto usa 'all' para compatibilidad hacia atrás
  const deployMode = app.node.tryGetContext('deployMode') || process.env.DEPLOY_MODE || 'all';

  const env = {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-2',
  };

  // ========================================
  // Validación de Dependencias
  // ========================================
  
  // Solo validar si no estamos en modo synth (para evitar errores en CI/CD)
  const shouldValidate = process.argv.includes('deploy') || process.argv.includes('diff');
  
  if (shouldValidate) {
    try {
      const validator = new StackValidator(env.region);
      await validator.validateDeployMode(deployMode, participantPrefix);
    } catch (error: any) {
      console.error(error.message);
      process.exit(1);
    }
  }

  // ========================================
  // Despliegue Condicional según DEPLOY_MODE
  // ========================================

  // Modo 'network': Solo desplegar PulsoSaludNetworkStack (instructor antes del workshop)
  if (deployMode === 'network' || deployMode === 'all') {
    new PulsoSaludNetworkStack(app, 'PulsoSaludNetworkStack', {
      env,
      description: 'VPC compartida para todos los participantes del workshop',
    });
  }

  // Modo 'legacy': Solo desplegar LegacyStack para un participante (instructor antes del workshop)
  if (deployMode === 'legacy' || deployMode === 'all') {
    // Soportar múltiples participantes separados por comas
    const participantPrefixes = participantPrefix.split(',').map((p: string) => p.trim());
    
    for (const prefix of participantPrefixes) {
      new LegacyStack(app, `${prefix}-MedicalReportsLegacyStack`, {
        participantPrefix: prefix,
        env,
        description: 'Sistema Legacy de Gestión de Exámenes Médicos Ocupacionales',
      });
    }
  }

  // Modo 'ai': Solo desplegar AI Stacks para un participante (participantes durante el workshop)
  if (deployMode === 'ai' || deployMode === 'all') {
    // En modo 'ai', solo se despliega para un participante a la vez
    // (cada participante ejecuta su propio despliegue durante el workshop)
    
    // Stack 1: Sistema de Extracción con IA (Textract + Bedrock)
    // Los recursos se importan automáticamente desde LegacyStack usando CloudFormation exports
    const extractionStack = new AIExtractionStack(app, `${participantPrefix}-AIExtractionStack`, {
      participantPrefix,
      env,
      description: 'Sistema de Extracción de PDFs con IA (Textract + Bedrock)',
    });

    // Stack 2: Sistema RAG con Embeddings (Titan Embeddings + pgvector)
    // Los recursos se importan automáticamente desde LegacyStack usando CloudFormation exports
    const ragStack = new AIRAGStack(app, `${participantPrefix}-AIRAGStack`, {
      participantPrefix,
      env,
      description: 'Sistema RAG con Embeddings para búsqueda semántica',
    });

    // Stack 3: Sistema de Clasificación de Riesgo con IA (Nova Pro + RAG)
    // Los recursos se importan automáticamente desde LegacyStack y RAGStack usando CloudFormation exports
    // DEPENDENCIA: Requiere que RAGStack se despliegue primero (SimilaritySearchLayer)
    const classificationStack = new AIClassificationStack(app, `${participantPrefix}-AIClassificationStack`, {
      participantPrefix,
      env,
      description: 'Sistema de Clasificación de Riesgo con IA y contexto histórico',
    });
    classificationStack.addDependency(ragStack);

    // Stack 4: Sistema de Generación de Resúmenes con IA (Nova Pro + RAG)
    // Los recursos se importan automáticamente desde LegacyStack y RAGStack usando CloudFormation exports
    // DEPENDENCIA: Requiere que RAGStack se despliegue primero (SimilaritySearchLayer)
    const summaryStack = new AISummaryStack(app, `${participantPrefix}-AISummaryStack`, {
      participantPrefix,
      env,
      description: 'Sistema de Generación de Resúmenes Ejecutivos con IA',
    });
    summaryStack.addDependency(ragStack);

    // Stack 5: Sistema de Emails Personalizados con IA (Nova Pro + SES)
    // Los recursos se importan automáticamente desde LegacyStack usando CloudFormation exports
    const emailStack = new AIEmailStack(app, `${participantPrefix}-AIEmailStack`, {
      participantPrefix,
      env,
      verifiedEmailAddress: process.env.VERIFIED_EMAIL || 'noreply@example.com',
      description: 'Sistema de Emails Personalizados con IA',
    });
  }

  app.synth();
}

// Ejecutar la función principal
main().catch((error) => {
  console.error('Error fatal durante la inicialización:', error);
  process.exit(1);
});
