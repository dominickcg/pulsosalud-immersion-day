import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import { Construct } from 'constructs';

export interface AIClassificationStackProps extends cdk.StackProps {
  participantPrefix: string;
}

export class AIClassificationStack extends cdk.Stack {
  public readonly classifyRiskLambda: lambda.Function;

  constructor(scope: Construct, id: string, props: AIClassificationStackProps) {
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

    // Importar bucket S3 (para leer prompts)
    const bucket = s3.Bucket.fromBucketName(this, 'ImportedBucket', bucketName);

    // ========================================
    // Lambda: Clasificador de Riesgo con RAG
    // ========================================
    this.classifyRiskLambda = new lambda.Function(this, 'ClassifyRiskFunction', {
      functionName: `${participantPrefix}-classify-risk`,
      runtime: lambda.Runtime.PYTHON_3_11,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('../lambda/ai/classify_risk'),
      timeout: cdk.Duration.seconds(30),
      memorySize: 1024,
      vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
      environment: {
        DB_SECRET_ARN: dbSecretArn,
        DB_CLUSTER_ARN: dbClusterArn,
        DATABASE_NAME: databaseName,
        PROMPTS_BUCKET: bucket.bucketName,
      },
    });

    // ========================================
    // Permisos IAM
    // ========================================

    // Permiso para Bedrock (Amazon Nova Pro)
    this.classifyRiskLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ['bedrock:InvokeModel'],
        resources: [
          `arn:aws:bedrock:${this.region}::foundation-model/us.amazon.nova-pro-v1:0`,
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

    // Permiso para S3 (leer prompts)
    bucket.grantRead(this.classifyRiskLambda);

    // ========================================
    // API Gateway Integration
    // ========================================
    
    // Importar API Gateway desde LegacyStack
    const apiId = cdk.Fn.importValue(`${participantPrefix}-ApiId`);
    const apiRootResourceId = cdk.Fn.importValue(`${participantPrefix}-ApiRootResourceId`);
    const apiUrl = cdk.Fn.importValue(`${participantPrefix}-ApiUrl`);
    
    const api = apigateway.RestApi.fromRestApiAttributes(this, 'ImportedApi', {
      restApiId: apiId,
      rootResourceId: apiRootResourceId,
    });

    // Crear recurso /classify
    const classifyResource = api.root.addResource('classify', {
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: ['POST', 'OPTIONS'],
        allowHeaders: ['Content-Type', 'X-Amz-Date', 'Authorization', 'X-Api-Key', 'X-Amz-Security-Token'],
      },
    });
    
    // Agregar método POST con integración Lambda
    classifyResource.addMethod('POST', new apigateway.LambdaIntegration(this.classifyRiskLambda, {
      proxy: true,
    }), {
      apiKeyRequired: false,
      methodResponses: [{
        statusCode: '200',
        responseParameters: {
          'method.response.header.Access-Control-Allow-Origin': true,
          'method.response.header.Access-Control-Allow-Methods': true,
          'method.response.header.Access-Control-Allow-Headers': true,
        },
      }],
    });

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

    new cdk.CfnOutput(this, 'ClassifyEndpoint', {
      value: `${apiUrl}classify`,
      description: 'URL del endpoint de clasificación',
    });
  }
}
