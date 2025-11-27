import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3n from 'aws-cdk-lib/aws-s3-notifications';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import { Construct } from 'constructs';

export interface AIExtractionStackProps extends cdk.StackProps {
  participantPrefix: string;
  // Los recursos ahora se importan vía exports de CloudFormation
  // Ya no se pasan como referencias directas
}

export class AIExtractionStack extends cdk.Stack {
  public readonly extractPdfLambda: lambda.Function;

  constructor(scope: Construct, id: string, props: AIExtractionStackProps) {
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
    // Lambda: Extractor de PDFs con IA
    // ========================================
    this.extractPdfLambda = new lambda.Function(this, 'ExtractPdfFunction', {
      functionName: `${participantPrefix}-extract-pdf`,
      runtime: lambda.Runtime.PYTHON_3_11,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('../lambda/ai/extract_pdf'),
      timeout: cdk.Duration.minutes(5), // Textract puede tardar
      memorySize: 1024,
      vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
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

    // Permiso para leer del bucket S3
    bucket.grantRead(this.extractPdfLambda);

    // Permiso para Textract
    this.extractPdfLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'textract:DetectDocumentText',
          'textract:AnalyzeDocument',
          'textract:StartDocumentTextDetection',
          'textract:GetDocumentTextDetection',
        ],
        resources: ['*'], // Textract no soporta resource-level permissions
      })
    );

    // Permiso para Bedrock (Amazon Nova Pro)
    this.extractPdfLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'bedrock:InvokeModel',
          'bedrock:InvokeModelWithResponseStream',
        ],
        resources: [
          `arn:aws:bedrock:${this.region}::foundation-model/amazon.nova-pro-v1:0`,
          `arn:aws:bedrock:${this.region}::foundation-model/amazon.titan-embed-text-v2:0`,
        ],
      })
    );

    // Permiso para Secrets Manager (leer credenciales de Aurora)
    this.extractPdfLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ['secretsmanager:GetSecretValue'],
        resources: [dbSecretArn],
      })
    );

    // Permiso para RDS Data API
    this.extractPdfLambda.addToRolePolicy(
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
    // S3 Event Notification
    // Trigger cuando se sube un PDF a /external-reports/
    // ========================================
    bucket.addEventNotification(
      s3.EventType.OBJECT_CREATED,
      new s3n.LambdaDestination(this.extractPdfLambda),
      {
        prefix: 'external-reports/',
        suffix: '.pdf',
      }
    );

    // ========================================
    // Outputs
    // ========================================
    new cdk.CfnOutput(this, 'ExtractPdfLambdaArn', {
      value: this.extractPdfLambda.functionArn,
      description: 'ARN de la Lambda de extracción de PDFs',
    });

    new cdk.CfnOutput(this, 'ExtractPdfLambdaName', {
      value: this.extractPdfLambda.functionName,
      description: 'Nombre de la Lambda de extracción',
    });
  }
}
