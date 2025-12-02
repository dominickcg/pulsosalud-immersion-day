import { CloudFormationClient, DescribeStacksCommand, ListExportsCommand } from '@aws-sdk/client-cloudformation';

/**
 * Validador de dependencias entre stacks
 * Verifica que los stacks requeridos existen antes de desplegar
 */
export class StackValidator {
  private client: CloudFormationClient;

  constructor(region: string = 'us-east-2') {
    this.client = new CloudFormationClient({ region });
  }

  /**
   * Verifica si un stack existe y está en estado CREATE_COMPLETE o UPDATE_COMPLETE
   */
  async stackExists(stackName: string): Promise<boolean> {
    try {
      const command = new DescribeStacksCommand({ StackName: stackName });
      const response = await this.client.send(command);
      
      if (!response.Stacks || response.Stacks.length === 0) {
        return false;
      }

      const stack = response.Stacks[0];
      const validStatuses = ['CREATE_COMPLETE', 'UPDATE_COMPLETE'];
      
      return validStatuses.includes(stack.StackStatus || '');
    } catch (error: any) {
      // Stack no existe
      if (error.name === 'ValidationError' || error.message?.includes('does not exist')) {
        return false;
      }
      throw error;
    }
  }

  /**
   * Verifica si un export de CloudFormation existe
   */
  async exportExists(exportName: string): Promise<boolean> {
    try {
      const command = new ListExportsCommand({});
      const response = await this.client.send(command);
      
      if (!response.Exports) {
        return false;
      }

      return response.Exports.some(exp => exp.Name === exportName);
    } catch (error) {
      console.error(`Error verificando export ${exportName}:`, error);
      return false;
    }
  }

  /**
   * Valida que PulsoSaludNetworkStack existe antes de desplegar LegacyStack
   */
  async validateForLegacyStack(): Promise<void> {
    const stackName = 'PulsoSaludNetworkStack';
    const exists = await this.stackExists(stackName);

    if (!exists) {
      throw new Error(
        `❌ ERROR: ${stackName} no encontrado.\n\n` +
        `El PulsoSaludNetworkStack debe desplegarse primero antes de desplegar LegacyStacks.\n\n` +
        `Ejecutar:\n` +
        `  PowerShell: $env:DEPLOY_MODE = "network"; cdk deploy PulsoSaludNetworkStack\n` +
        `  Bash: export DEPLOY_MODE=network && cdk deploy PulsoSaludNetworkStack\n`
      );
    }

    // Verificar exports críticos
    const requiredExports = [
      'PulsoSaludNetworkStack-VpcId',
      'PulsoSaludNetworkStack-PrivateSubnetIds',
      'PulsoSaludNetworkStack-IsolatedSubnetIds',
    ];

    for (const exportName of requiredExports) {
      const exists = await this.exportExists(exportName);
      if (!exists) {
        throw new Error(
          `❌ ERROR: Export "${exportName}" no encontrado.\n\n` +
          `El PulsoSaludNetworkStack existe pero no tiene los exports necesarios.\n` +
          `Esto puede indicar que el stack está en un estado incompleto.\n`
        );
      }
    }

    console.log(`✅ Validación exitosa: PulsoSaludNetworkStack existe y tiene todos los exports necesarios`);
  }

  /**
   * Valida que LegacyStack existe antes de desplegar AI Stacks
   */
  async validateForAIStacks(participantPrefix: string): Promise<void> {
    const stackName = `${participantPrefix}-MedicalReportsLegacyStack`;
    const exists = await this.stackExists(stackName);

    if (!exists) {
      throw new Error(
        `❌ ERROR: ${stackName} no encontrado.\n\n` +
        `El LegacyStack para el participante "${participantPrefix}" debe desplegarse primero.\n` +
        `El instructor debe haber desplegado este stack antes del workshop.\n\n` +
        `Si eres el instructor, ejecutar:\n` +
        `  PowerShell: $env:DEPLOY_MODE = "legacy"; $env:PARTICIPANT_PREFIX = "${participantPrefix}"; cdk deploy ${stackName}\n` +
        `  Bash: export DEPLOY_MODE=legacy PARTICIPANT_PREFIX=${participantPrefix} && cdk deploy ${stackName}\n`
      );
    }

    // Verificar exports críticos del LegacyStack
    const requiredExports = [
      `${participantPrefix}-BucketName`,
      `${participantPrefix}-VpcId`,
      `${participantPrefix}-PrivateSubnetIds`,
      `${participantPrefix}-DbSecretArn`,
      `${participantPrefix}-DbClusterArn`,
    ];

    for (const exportName of requiredExports) {
      const exists = await this.exportExists(exportName);
      if (!exists) {
        throw new Error(
          `❌ ERROR: Export "${exportName}" no encontrado.\n\n` +
          `El LegacyStack existe pero no tiene los exports necesarios.\n` +
          `Esto puede indicar que el stack está en un estado incompleto o fue desplegado con una versión antigua.\n`
        );
      }
    }

    console.log(`✅ Validación exitosa: LegacyStack para "${participantPrefix}" existe y tiene todos los exports necesarios`);
  }

  /**
   * Valida dependencias según el modo de despliegue
   */
  async validateDeployMode(deployMode: string, participantPrefix: string): Promise<void> {
    console.log(`\n🔍 Validando dependencias para DEPLOY_MODE="${deployMode}"...\n`);

    switch (deployMode) {
      case 'network':
        // No hay dependencias para network
        console.log(`✅ Modo "network": No hay dependencias que validar`);
        break;

      case 'legacy':
        // LegacyStack requiere PulsoSaludNetworkStack
        await this.validateForLegacyStack();
        break;

      case 'ai':
        // AI Stacks requieren LegacyStack (que a su vez requiere PulsoSaludNetworkStack)
        await this.validateForAIStacks(participantPrefix);
        break;

      case 'all':
        // Modo "all" despliega todo en orden, no necesita validación previa
        console.log(`✅ Modo "all": Desplegará todos los stacks en orden correcto`);
        break;

      default:
        throw new Error(
          `❌ ERROR: DEPLOY_MODE inválido: "${deployMode}"\n\n` +
          `Valores válidos: "network", "legacy", "ai", "all"\n`
        );
    }

    console.log(`\n✅ Validación de dependencias completada exitosamente\n`);
  }
}
