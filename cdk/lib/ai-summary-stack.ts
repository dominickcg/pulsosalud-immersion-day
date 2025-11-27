import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { Construct } from 'constructs';

export interface AISummaryStackProps extends cdk.StackProps {
  participantPrefix: string;
  // Los recursos ahora se importan vía exports de CloudFormation
  // Ya no se pasan como referencias directas
}

export class AISummaryStack extends cdk.Stack {
  public readonly generateSummaryLambda: lambda.Function;

  constructor(scope: Construct, id: string, props: AISummaryStackProps) {
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
    // Lambda: Generador de Resúmenes
    // ========================================
    this.generateSummaryLambda = new lambda.Function(this, 'GenerateSummaryFunction', {
      functionName: `${participantPrefix}-generate-summary`,
      runtime: lambda.Runtime.PYTHON_3_11,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('../lambda/ai/generate_summary'),
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
    this.generateSummaryLambda.addToRolePolicy(
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
    this.generateSummaryLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ['secretsmanager:GetSecretValue'],
        resources: [dbSecretArn],
      })
    );

    // Permiso para RDS Data API
    this.generateSummaryLambda.addToRolePolicy(
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
    // Outputs
    // ========================================
    new cdk.CfnOutput(this, 'GenerateSummaryLambdaArn', {
      value: this.generateSummaryLambda.functionArn,
      description: 'ARN de la Lambda de generación de resúmenes',
      exportName: `${participantPrefix}-GenerateSummaryLambdaArn`,
    });

    new cdk.CfnOutput(this, 'GenerateSummaryLambdaName', {
      value: this.generateSummaryLambda.functionName,
      description: 'Nombre de la Lambda de generación de resúmenes',
      exportName: `${participantPrefix}-GenerateSummaryLambdaName`,
    });
  }
}
