import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as events from 'aws-cdk-lib/aws-events';
import * as targets from 'aws-cdk-lib/aws-events-targets';
import { Construct } from 'constructs';

export interface AIClassificationStackProps extends cdk.StackProps {
  participantPrefix: string;
  // Los recursos ahora se importan vía exports de CloudFormation
  // Ya no se pasan como referencias directas
}

export class AIClassificationStack extends cdk.Stack {
  public readonly classifyRiskLambda: lambda.Function;

  constructor(scope: Construct, id: string, props: AIClassificationStackProps) {
    super(scope, id, props);

    const { participantPrefix } = props;

    // ========================================
    // Importar recursos desde LegacyStack y RAGStack usando CloudFormation Exports
    // ========================================
    const bucketName = cdk.Fn.importValue(`${participantPrefix}-BucketName`);
    const vpcId = cdk.Fn.importValue(`${participantPrefix}-VpcId`);
    const privateSubnetIds = cdk.Fn.split(',', cdk.Fn.importValue(`${participantPrefix}-PrivateSubnetIds`));
    const availabilityZones = cdk.Fn.split(',', cdk.Fn.importValue(`${participantPrefix}-AvailabilityZones`));
    const dbSecretArn = cdk.Fn.importValue(`${participantPrefix}-DbSecretArn`);
    const dbClusterArn = cdk.Fn.importValue(`${participantPrefix}-DbClusterArn`);
    const similaritySearchLayerArn = cdk.Fn.importValue(`${participantPrefix}-SimilaritySearchLayerArn`);
    const databaseName = 'medical_reports';

    // Importar VPC
    const vpc = ec2.Vpc.fromVpcAttributes(this, 'ImportedVPC', {
      vpcId: vpcId,
      availabilityZones: availabilityZones,
      privateSubnetIds: privateSubnetIds,
    });

    // Importar bucket S3
    const bucket = s3.Bucket.fromBucketName(this, 'ImportedBucket', bucketName);

    // Importar Lambda Layer de búsqueda por similitud
    const similaritySearchLayer = lambda.LayerVersion.fromLayerVersionArn(
      this,
      'ImportedSimilaritySearchLayer',
      similaritySearchLayerArn
    );

    // ========================================
    // Lambda: Clasificador de Riesgo
    // ========================================
    this.classifyRiskLambda = new lambda.Function(this, 'ClassifyRiskFunction', {
      functionName: `${participantPrefix}-classify-risk`,
      runtime: lambda.Runtime.PYTHON_3_11,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('../lambda/ai/classify_risk'),
      timeout: cdk.Duration.minutes(5),
      memorySize: 1024,
      vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
      layers: [similaritySearchLayer],
      environment: {
        DB_SECRET_ARN: dbSecretArn,
        DB_CLUSTER_ARN: dbClusterArn,
        DATABASE_NAME: databaseName,
        BUCKET_NAME: bucket.bucketName,
      },
    });

    // ========================================
    // Permisos IAM
    // ========================================

    // Permiso para Bedrock (Amazon Nova Pro)
    this.classifyRiskLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'bedrock:InvokeModel',
        ],
        resources: [
          `arn:aws:bedrock:${this.region}::foundation-model/amazon.nova-pro-v1:0`,
          `arn:aws:bedrock:${this.region}::foundation-model/amazon.titan-embed-text-v2:0`,
        ],
      })
    );

    // Permiso para Secrets Manager (leer credenciales de Aurora)
    this.classifyRiskLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ['secretsmanager:GetSecretValue'],
        resources: [dbSecretArn],
      })
    );

    // Permiso para RDS Data API
    this.classifyRiskLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'rds-data:ExecuteStatement',
          'rds-data:BatchExecuteStatement',
        ],
        resources: [dbClusterArn],
      })
    );

    // ========================================
    // EventBridge Rule (Opcional)
    // Trigger automático cada hora para procesar informes sin clasificar
    // ========================================
    const classificationRule = new events.Rule(this, 'ClassificationScheduleRule', {
      ruleName: `${participantPrefix}-classification-schedule`,
      description: 'Trigger clasificación de riesgo cada hora',
      schedule: events.Schedule.rate(cdk.Duration.hours(1)),
      enabled: false, // Deshabilitado por defecto, se puede habilitar manualmente
    });

    classificationRule.addTarget(new targets.LambdaFunction(this.classifyRiskLambda));

    // ========================================
    // Outputs
    // ========================================
    new cdk.CfnOutput(this, 'ClassifyRiskLambdaArn', {
      value: this.classifyRiskLambda.functionArn,
      description: 'ARN de la Lambda de clasificación de riesgo',
      exportName: `${participantPrefix}-ClassifyRiskLambdaArn`,
    });

    new cdk.CfnOutput(this, 'ClassifyRiskLambdaName', {
      value: this.classifyRiskLambda.functionName,
      description: 'Nombre de la Lambda de clasificación',
      exportName: `${participantPrefix}-ClassifyRiskLambdaName`,
    });

    new cdk.CfnOutput(this, 'ClassificationRuleName', {
      value: classificationRule.ruleName,
      description: 'Nombre de la regla EventBridge para clasificación automática',
      exportName: `${participantPrefix}-ClassificationRuleName`,
    });
  }
}
