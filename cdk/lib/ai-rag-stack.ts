import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { Construct } from 'constructs';

export interface AIRAGStackProps extends cdk.StackProps {
  participantPrefix: string;
  // Los recursos ahora se importan vía exports de CloudFormation
  // Ya no se pasan como referencias directas
}

export class AIRAGStack extends cdk.Stack {
  public readonly generateEmbeddingsLambda: lambda.Function;
  public readonly similaritySearchLayer: lambda.LayerVersion;

  constructor(scope: Construct, id: string, props: AIRAGStackProps) {
    super(scope, id, props);

    const { participantPrefix } = props;

    // ========================================
    // Importar recursos desde LegacyStack usando CloudFormation Exports
    // ========================================
    const bucketName = cdk.Fn.importValue(`${participantPrefix}-BucketName`);
    const vpcId = cdk.Fn.importValue(`${participantPrefix}-VpcId`);
    const privateSubnetIds = cdk.Fn.split(',', cdk.Fn.importValue(`${participantPrefix}-PrivateSubnetIds`));
    const availabilityZones = cdk.Fn.split(',', cdk.Fn.importValue(`${participantPrefix}-AvailabilityZones`));
    const dbSecretArn = cdk.Fn.importValue(`${participantPrefix}-DbSecretArn`);
    const dbClusterArn = cdk.Fn.importValue(`${participantPrefix}-DbClusterArn`);
    const databaseName = 'medical_reports';

    // Importar VPC
    const vpc = ec2.Vpc.fromVpcAttributes(this, 'ImportedVPC', {
      vpcId: vpcId,
      availabilityZones: availabilityZones,
      privateSubnetIds: privateSubnetIds,
    });

    // Importar bucket S3
    const bucket = s3.Bucket.fromBucketName(this, 'ImportedBucket', bucketName);

    // ========================================
    // Lambda Layer: Funciones compartidas de búsqueda por similitud
    // ========================================
    this.similaritySearchLayer = new lambda.LayerVersion(this, 'SimilaritySearchLayer', {
      layerVersionName: `${participantPrefix}-similarity-search`,
      code: lambda.Code.fromAsset('../lambda/shared'),
      compatibleRuntimes: [lambda.Runtime.PYTHON_3_11],
      description: 'Funciones compartidas para búsqueda por similitud con pgvector',
    });

    // ========================================
    // Lambda: Generador de Embeddings
    // ========================================
    this.generateEmbeddingsLambda = new lambda.Function(this, 'GenerateEmbeddingsFunction', {
      functionName: `${participantPrefix}-generate-embeddings`,
      runtime: lambda.Runtime.PYTHON_3_11,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('../lambda/ai/generate_embeddings'),
      timeout: cdk.Duration.minutes(5),
      memorySize: 1024,
      vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
      layers: [this.similaritySearchLayer],
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

    // Permiso para Bedrock (Amazon Titan Embeddings)
    this.generateEmbeddingsLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'bedrock:InvokeModel',
        ],
        resources: [
          `arn:aws:bedrock:${this.region}::foundation-model/amazon.titan-embed-text-v2:0`,
        ],
      })
    );

    // Permiso para Secrets Manager (leer credenciales de Aurora)
    this.generateEmbeddingsLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ['secretsmanager:GetSecretValue'],
        resources: [dbSecretArn],
      })
    );

    // Permiso para RDS Data API
    this.generateEmbeddingsLambda.addToRolePolicy(
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
    new cdk.CfnOutput(this, 'GenerateEmbeddingsLambdaArn', {
      value: this.generateEmbeddingsLambda.functionArn,
      description: 'ARN de la Lambda de generación de embeddings',
      exportName: `${participantPrefix}-GenerateEmbeddingsLambdaArn`,
    });

    new cdk.CfnOutput(this, 'GenerateEmbeddingsLambdaName', {
      value: this.generateEmbeddingsLambda.functionName,
      description: 'Nombre de la Lambda de generación de embeddings',
      exportName: `${participantPrefix}-GenerateEmbeddingsLambdaName`,
    });

    new cdk.CfnOutput(this, 'SimilaritySearchLayerArn', {
      value: this.similaritySearchLayer.layerVersionArn,
      description: 'ARN del Lambda Layer de búsqueda por similitud',
      exportName: `${participantPrefix}-SimilaritySearchLayerArn`,
    });
  }
}
