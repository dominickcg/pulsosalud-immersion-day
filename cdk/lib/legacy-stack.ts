import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as cr from 'aws-cdk-lib/custom-resources';
import { Construct } from 'constructs';

export interface LegacyStackProps extends cdk.StackProps {
  participantPrefix: string;
  sharedVpcId?: string; // Opcional: si no se proporciona, importa de SharedNetworkStack
}

export class LegacyStack extends cdk.Stack {
  public readonly database: rds.DatabaseCluster;
  public readonly bucket: s3.Bucket;
  public readonly api: apigateway.RestApi;
  public readonly vpc: ec2.IVpc; // Cambiado de Vpc a IVpc (importado)

  constructor(scope: Construct, id: string, props: LegacyStackProps) {
    super(scope, id, props);

    const { participantPrefix } = props;

    // ========================================
    // Importar VPC Compartida desde SharedNetworkStack
    // ========================================
    const vpcId = props.sharedVpcId || cdk.Fn.importValue('SharedNetworkStack-VpcId');
    const vpcCidrBlock = cdk.Fn.importValue('SharedNetworkStack-VpcCidrBlock');
    
    // Importar subnet IDs como arrays de strings
    const publicSubnetId1 = cdk.Fn.select(0, cdk.Fn.split(',', cdk.Fn.importValue('SharedNetworkStack-PublicSubnetIds')));
    const publicSubnetId2 = cdk.Fn.select(1, cdk.Fn.split(',', cdk.Fn.importValue('SharedNetworkStack-PublicSubnetIds')));
    
    const privateSubnetId1 = cdk.Fn.select(0, cdk.Fn.split(',', cdk.Fn.importValue('SharedNetworkStack-PrivateSubnetIds')));
    const privateSubnetId2 = cdk.Fn.select(1, cdk.Fn.split(',', cdk.Fn.importValue('SharedNetworkStack-PrivateSubnetIds')));
    
    const isolatedSubnetId1 = cdk.Fn.select(0, cdk.Fn.split(',', cdk.Fn.importValue('SharedNetworkStack-IsolatedSubnetIds')));
    const isolatedSubnetId2 = cdk.Fn.select(1, cdk.Fn.split(',', cdk.Fn.importValue('SharedNetworkStack-IsolatedSubnetIds')));
    
    const az1 = cdk.Fn.select(0, cdk.Fn.split(',', cdk.Fn.importValue('SharedNetworkStack-AvailabilityZones')));
    const az2 = cdk.Fn.select(1, cdk.Fn.split(',', cdk.Fn.importValue('SharedNetworkStack-AvailabilityZones')));

    // Importar VPC usando fromVpcAttributes
    this.vpc = ec2.Vpc.fromVpcAttributes(this, 'ImportedVPC', {
      vpcId: vpcId,
      vpcCidrBlock: vpcCidrBlock,
      availabilityZones: [az1, az2],
      publicSubnetIds: [publicSubnetId1, publicSubnetId2],
      privateSubnetIds: [privateSubnetId1, privateSubnetId2],
      isolatedSubnetIds: [isolatedSubnetId1, isolatedSubnetId2],
    });

    // ========================================
    // Aurora Serverless v2 (PostgreSQL con pgvector)
    // ========================================
    
    // Security Group para Aurora
    const dbSecurityGroup = new ec2.SecurityGroup(this, 'DatabaseSecurityGroup', {
      vpc: this.vpc,
      description: 'Security group for Aurora Serverless v2',
      allowAllOutbound: true,
    });

    // Permitir conexiones desde Lambdas en la VPC
    dbSecurityGroup.addIngressRule(
      ec2.Peer.ipv4(this.vpc.vpcCidrBlock),
      ec2.Port.tcp(5432),
      'Allow PostgreSQL access from VPC'
    );

    // Credenciales de la base de datos
    const dbCredentials = rds.Credentials.fromGeneratedSecret('postgres', {
      secretName: `${participantPrefix}/aurora/credentials`,
    });

    // Cluster Aurora Serverless v2
    this.database = new rds.DatabaseCluster(this, 'AuroraCluster', {
      engine: rds.DatabaseClusterEngine.auroraPostgres({
        version: rds.AuroraPostgresEngineVersion.VER_15_8,
      }),
      credentials: dbCredentials,
      defaultDatabaseName: 'medical_reports',
      vpc: this.vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
      },
      securityGroups: [dbSecurityGroup],
      writer: rds.ClusterInstance.serverlessV2('writer', {
        scaleWithWriter: true,
      }),
      readers: [],
      serverlessV2MinCapacity: 0.5, // Mínimo 0.5 ACU para optimizar costos
      serverlessV2MaxCapacity: 1,   // Máximo 1 ACU para la demo
      removalPolicy: cdk.RemovalPolicy.DESTROY, // DESTROY para eliminar sin snapshots
      storageEncrypted: true,
      backup: {
        retention: cdk.Duration.days(1), // Mínimo backup para la demo
      },
    });

    // ========================================
    // Custom Resource: Inicialización de Base de Datos
    // ========================================
    const initDbLambda = new lambda.Function(this, 'InitDatabaseFunction', {
      functionName: `${participantPrefix}-init-database`,
      runtime: lambda.Runtime.PYTHON_3_11,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('../lambda/custom-resources/init-database'),
      timeout: cdk.Duration.minutes(5),
      memorySize: 512,
      vpc: this.vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
      environment: {
        DB_SECRET_ARN: this.database.secret!.secretArn,
        DB_CLUSTER_ARN: this.database.clusterArn,
        DATABASE_NAME: 'medical_reports',
      },
    });

    // Permisos para el Custom Resource
    this.database.secret!.grantRead(initDbLambda);
    this.database.grantDataApiAccess(initDbLambda);
    dbSecurityGroup.addIngressRule(
      ec2.Peer.securityGroupId(initDbLambda.connections.securityGroups[0].securityGroupId),
      ec2.Port.tcp(5432),
      'Allow Init Lambda access'
    );

    // Crear Custom Resource Provider
    const initDbProvider = new cr.Provider(this, 'InitDatabaseProvider', {
      onEventHandler: initDbLambda,
    });

    // Crear Custom Resource que se ejecuta en CREATE y UPDATE
    const initDbResource = new cdk.CustomResource(this, 'InitDatabaseResource', {
      serviceToken: initDbProvider.serviceToken,
      properties: {
        // Cambiar este valor fuerza re-ejecución en updates
        Timestamp: Date.now().toString(),
      },
    });

    // Asegurar que el Custom Resource se ejecuta después de que Aurora esté disponible
    initDbResource.node.addDependency(this.database);

    // ========================================
    // S3 Bucket con prefijo único
    // ========================================
    this.bucket = new s3.Bucket(this, 'ReportsBucket', {
      bucketName: `${participantPrefix}-medical-reports-${cdk.Aws.ACCOUNT_ID}`,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true, // Eliminar objetos al destruir el stack
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      versioned: false,
    });

    // ========================================
    // Lambda: Registro de Exámenes
    // ========================================
    // ========================================
    // Lambda: Generador de PDFs (debe crearse primero)
    // ========================================
    const generatePdfLambda = new lambda.Function(this, 'GeneratePdfFunction', {
      functionName: `${participantPrefix}-generate-pdf`,
      runtime: lambda.Runtime.PYTHON_3_11,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('../lambda/legacy/generate_pdf'),
      timeout: cdk.Duration.seconds(60),
      memorySize: 1024,
      vpc: this.vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
      environment: {
        DB_SECRET_ARN: this.database.secret!.secretArn,
        DB_CLUSTER_ARN: this.database.clusterArn,
        DATABASE_NAME: 'medical_reports',
        BUCKET_NAME: this.bucket.bucketName,
      },
    });

    this.database.secret!.grantRead(generatePdfLambda);
    this.database.grantDataApiAccess(generatePdfLambda);
    this.bucket.grantReadWrite(generatePdfLambda);
    dbSecurityGroup.addIngressRule(
      ec2.Peer.securityGroupId(generatePdfLambda.connections.securityGroups[0].securityGroupId),
      ec2.Port.tcp(5432),
      'Allow Lambda access'
    );

    // ========================================
    // Lambda: Registro de Exámenes
    // ========================================
    const registerExamLambda = new lambda.Function(this, 'RegisterExamFunction', {
      functionName: `${participantPrefix}-register-exam`,
      runtime: lambda.Runtime.PYTHON_3_11,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('../lambda/legacy/register_exam'),
      timeout: cdk.Duration.seconds(30),
      memorySize: 512,
      vpc: this.vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
      environment: {
        DB_SECRET_ARN: this.database.secret!.secretArn,
        DB_CLUSTER_ARN: this.database.clusterArn,
        DATABASE_NAME: 'medical_reports',
        BUCKET_NAME: this.bucket.bucketName,
        GENERATE_PDF_LAMBDA_ARN: generatePdfLambda.functionArn,
      },
    });

    // Permisos para acceder a Secrets Manager y Aurora
    this.database.secret!.grantRead(registerExamLambda);
    this.database.grantDataApiAccess(registerExamLambda);
    dbSecurityGroup.addIngressRule(
      ec2.Peer.securityGroupId(registerExamLambda.connections.securityGroups[0].securityGroupId),
      ec2.Port.tcp(5432),
      'Allow Lambda access'
    );

    // ========================================
    // Lambda: Generador de Datos de Prueba
    // ========================================
    const generateTestDataLambda = new lambda.Function(this, 'GenerateTestDataFunction', {
      functionName: `${participantPrefix}-generate-test-data`,
      runtime: lambda.Runtime.PYTHON_3_11,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('../lambda/legacy/generate_test_data'),
      timeout: cdk.Duration.seconds(30),
      memorySize: 512,
      vpc: this.vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
      environment: {
        DB_SECRET_ARN: this.database.secret!.secretArn,
        DB_CLUSTER_ARN: this.database.clusterArn,
        DATABASE_NAME: 'medical_reports',
        BUCKET_NAME: this.bucket.bucketName,
        GENERATE_PDF_LAMBDA_ARN: generatePdfLambda.functionArn,
      },
    });

    this.database.secret!.grantRead(generateTestDataLambda);
    this.database.grantDataApiAccess(generateTestDataLambda);
    dbSecurityGroup.addIngressRule(
      ec2.Peer.securityGroupId(generateTestDataLambda.connections.securityGroups[0].securityGroupId),
      ec2.Port.tcp(5432),
      'Allow Lambda access'
    );

    // Permitir a las Lambdas de registro invocar la Lambda de generación de PDF
    generatePdfLambda.grantInvoke(registerExamLambda);
    generatePdfLambda.grantInvoke(generateTestDataLambda);
    
    // Permitir a generate-test-data invocar register-exam
    registerExamLambda.grantInvoke(generateTestDataLambda);

    // ========================================
    // Lambda: Listar Informes (para App Web)
    // ========================================
    const listInformesLambda = new lambda.Function(this, 'ListInformesFunction', {
      functionName: `${participantPrefix}-list-informes`,
      runtime: lambda.Runtime.PYTHON_3_11,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('../lambda/legacy/list_informes'),
      timeout: cdk.Duration.seconds(10),
      memorySize: 512,
      vpc: this.vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
      environment: {
        DB_SECRET_ARN: this.database.secret!.secretArn,
        DB_CLUSTER_ARN: this.database.clusterArn,
        DATABASE_NAME: 'medical_reports',
      },
    });

    // Permisos para acceder a Aurora
    this.database.secret!.grantRead(listInformesLambda);
    this.database.grantDataApiAccess(listInformesLambda);
    dbSecurityGroup.addIngressRule(
      ec2.Peer.securityGroupId(listInformesLambda.connections.securityGroups[0].securityGroupId),
      ec2.Port.tcp(5432),
      'Allow Lambda access'
    );

    // ========================================
    // API Gateway
    // ========================================
    this.api = new apigateway.RestApi(this, 'LegacyApi', {
      restApiName: `${participantPrefix}-medical-reports-api`,
      description: 'API para el sistema legacy de informes médicos',
      deployOptions: {
        stageName: 'prod',
        throttlingRateLimit: 100,
        throttlingBurstLimit: 200,
      },
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
      },
    });

    // Endpoint: POST /examenes
    const examenesResource = this.api.root.addResource('examenes');
    examenesResource.addMethod('POST', new apigateway.LambdaIntegration(registerExamLambda), {
      apiKeyRequired: false,
    });

    // Endpoint: POST /examenes/generar-prueba
    const generarPruebaResource = examenesResource.addResource('generar-prueba');
    generarPruebaResource.addMethod('POST', new apigateway.LambdaIntegration(generateTestDataLambda), {
      apiKeyRequired: false,
    });

    // Endpoint: GET /informes (para App Web)
    const informesResource = this.api.root.addResource('informes');
    informesResource.addMethod('GET', new apigateway.LambdaIntegration(listInformesLambda), {
      apiKeyRequired: false,
    });

    // ========================================
    // App Web Estática en S3
    // ========================================
    
    // Bucket para la app web con static website hosting
    const appBucket = new s3.Bucket(this, 'AppWebBucket', {
      bucketName: `${participantPrefix}-app-web-${cdk.Aws.ACCOUNT_ID}`,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      websiteIndexDocument: 'index.html',
      websiteErrorDocument: 'index.html',
      publicReadAccess: true,
      blockPublicAccess: new s3.BlockPublicAccess({
        blockPublicAcls: false,
        blockPublicPolicy: false,
        ignorePublicAcls: false,
        restrictPublicBuckets: false,
      }),
      cors: [{
        allowedMethods: [s3.HttpMethods.GET],
        allowedOrigins: ['*'],
        allowedHeaders: ['*'],
      }],
    });

    // Desplegar app web con inyección de API Gateway URL
    new s3deploy.BucketDeployment(this, 'DeployAppWeb', {
      sources: [
        s3deploy.Source.asset('../frontend', {
          exclude: ['*.md', '.DS_Store'],
        }),
      ],
      destinationBucket: appBucket,
      // Inyectar API Gateway URL en el HTML
      contentLanguage: 'es',
      cacheControl: [
        s3deploy.CacheControl.setPublic(),
        s3deploy.CacheControl.maxAge(cdk.Duration.hours(1)),
      ],
      prune: true,
    });

    // Custom Resource para reemplazar placeholder de API Gateway URL
    const replaceApiUrlLambda = new lambda.Function(this, 'ReplaceApiUrlFunction', {
      runtime: lambda.Runtime.PYTHON_3_11,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
import boto3
import json

s3 = boto3.client('s3')

def handler(event, context):
    request_type = event['RequestType']
    
    if request_type == 'Delete':
        return {'PhysicalResourceId': 'replace-api-url'}
    
    bucket = event['ResourceProperties']['Bucket']
    api_url = event['ResourceProperties']['ApiUrl']
    
    try:
        # Descargar index.html
        response = s3.get_object(Bucket=bucket, Key='index.html')
        content = response['Body'].read().decode('utf-8')
        
        # Reemplazar placeholder
        content = content.replace('API_GATEWAY_URL_PLACEHOLDER', api_url)
        
        # Subir archivo modificado
        s3.put_object(
            Bucket=bucket,
            Key='index.html',
            Body=content.encode('utf-8'),
            ContentType='text/html',
            CacheControl='public, max-age=3600'
        )
        
        print(f'✓ API URL inyectada: {api_url}')
        return {'PhysicalResourceId': 'replace-api-url'}
        
    except Exception as e:
        print(f'Error: {str(e)}')
        raise
      `),
      timeout: cdk.Duration.seconds(30),
    });

    // Permisos para modificar el bucket
    appBucket.grantReadWrite(replaceApiUrlLambda);

    // Provider para el Custom Resource
    const replaceApiUrlProvider = new cr.Provider(this, 'ReplaceApiUrlProvider', {
      onEventHandler: replaceApiUrlLambda,
    });

    // Custom Resource que se ejecuta después del deployment
    const replaceApiUrlResource = new cdk.CustomResource(this, 'ReplaceApiUrlResource', {
      serviceToken: replaceApiUrlProvider.serviceToken,
      properties: {
        Bucket: appBucket.bucketName,
        ApiUrl: this.api.url,
        Timestamp: Date.now().toString(), // Forzar actualización
      },
    });

    // Asegurar que se ejecuta después del deployment
    replaceApiUrlResource.node.addDependency(appBucket);

    // ========================================
    // Outputs - CloudFormation Exports para AI Stacks
    // ========================================
    new cdk.CfnOutput(this, 'ApiUrl', {
      value: this.api.url,
      description: 'URL del API Gateway',
      exportName: `${participantPrefix}-ApiUrl`,
    });

    new cdk.CfnOutput(this, 'ApiId', {
      value: this.api.restApiId,
      description: 'ID del API Gateway',
      exportName: `${participantPrefix}-ApiId`,
    });

    new cdk.CfnOutput(this, 'ApiRootResourceId', {
      value: this.api.root.resourceId,
      description: 'ID del recurso raíz del API Gateway',
      exportName: `${participantPrefix}-ApiRootResourceId`,
    });

    new cdk.CfnOutput(this, 'BucketName', {
      value: this.bucket.bucketName,
      description: 'Nombre del bucket S3',
      exportName: `${participantPrefix}-BucketName`,
    });

    new cdk.CfnOutput(this, 'DatabaseSecretArn', {
      value: this.database.secret!.secretArn,
      description: 'ARN del secreto de la base de datos',
      exportName: `${participantPrefix}-DbSecretArn`,
    });

    new cdk.CfnOutput(this, 'DatabaseClusterArn', {
      value: this.database.clusterArn,
      description: 'ARN del cluster Aurora',
      exportName: `${participantPrefix}-DbClusterArn`,
    });

    new cdk.CfnOutput(this, 'VpcId', {
      value: this.vpc.vpcId,
      description: 'ID de la VPC',
      exportName: `${participantPrefix}-VpcId`,
    });

    new cdk.CfnOutput(this, 'PrivateSubnetIds', {
      value: this.vpc.privateSubnets.map(subnet => subnet.subnetId).join(','),
      description: 'IDs de las subnets privadas (separados por comas)',
      exportName: `${participantPrefix}-PrivateSubnetIds`,
    });

    new cdk.CfnOutput(this, 'IsolatedSubnetIds', {
      value: this.vpc.isolatedSubnets.map(subnet => subnet.subnetId).join(','),
      description: 'IDs de las subnets aisladas (separados por comas)',
      exportName: `${participantPrefix}-IsolatedSubnetIds`,
    });

    new cdk.CfnOutput(this, 'DbSecurityGroupId', {
      value: dbSecurityGroup.securityGroupId,
      description: 'ID del Security Group de la base de datos',
      exportName: `${participantPrefix}-DbSecurityGroupId`,
    });

    new cdk.CfnOutput(this, 'AvailabilityZones', {
      value: this.vpc.availabilityZones.join(','),
      description: 'Zonas de disponibilidad (separadas por comas)',
      exportName: `${participantPrefix}-AvailabilityZones`,
    });

    new cdk.CfnOutput(this, 'AppWebUrl', {
      value: appBucket.bucketWebsiteUrl,
      description: 'URL de la aplicación web',
    });
  }
}
