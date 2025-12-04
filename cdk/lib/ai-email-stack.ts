import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as ses from 'aws-cdk-lib/aws-ses';
import { Construct } from 'constructs';

export interface AIEmailStackProps extends cdk.StackProps {
  participantPrefix: string;
  verifiedEmailAddress: string; // Este sigue siendo necesario como parámetro
  // Los demás recursos ahora se importan vía exports de CloudFormation
}

export class AIEmailStack extends cdk.Stack {
  public readonly sendEmailLambda: lambda.Function;

  constructor(scope: Construct, id: string, props: AIEmailStackProps) {
    super(scope, id, props);

    const { participantPrefix, verifiedEmailAddress } = props;

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

    // Lambda: Enviador de Emails
    this.sendEmailLambda = new lambda.Function(this, 'SendEmailFunction', {
      functionName: `${participantPrefix}-send-email`,
      runtime: lambda.Runtime.PYTHON_3_11,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('../lambda/ai/send_email'),
      timeout: cdk.Duration.minutes(5),
      memorySize: 1024,
      vpc,
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
      environment: {
        DB_SECRET_ARN: dbSecretArn,
        DB_CLUSTER_ARN: dbClusterArn,
        DATABASE_NAME: databaseName,
        BUCKET_NAME: bucket.bucketName,
        VERIFIED_EMAIL: verifiedEmailAddress,
      },
    });

    // Permisos IAM
    this.sendEmailLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ['bedrock:InvokeModel'],
        resources: [`arn:aws:bedrock:${this.region}::foundation-model/amazon.nova-pro-v1:0`],
      })
    );

    this.sendEmailLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ['ses:SendEmail', 'ses:SendRawEmail'],
        resources: ['*'],
      })
    );

    this.sendEmailLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ['secretsmanager:GetSecretValue'],
        resources: [dbSecretArn],
      })
    );

    this.sendEmailLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ['rds-data:ExecuteStatement', 'rds-data:BatchExecuteStatement'],
        resources: [dbClusterArn],
      })
    );

    // Outputs
    new cdk.CfnOutput(this, 'SendEmailLambdaArn', {
      value: this.sendEmailLambda.functionArn,
      description: 'ARN de la Lambda de envío de emails',
      exportName: `${participantPrefix}-SendEmailLambdaArn`,
    });

    new cdk.CfnOutput(this, 'SendEmailLambdaName', {
      value: this.sendEmailLambda.functionName,
      description: 'Nombre de la Lambda de envío de emails',
      exportName: `${participantPrefix}-SendEmailLambdaName`,
    });

    new cdk.CfnOutput(this, 'VerifiedEmail', {
      value: verifiedEmailAddress,
      description: 'Email verificado en SES',
      exportName: `${participantPrefix}-VerifiedEmail`,
    });

    new cdk.CfnOutput(this, 'EmailEndpoint', {
      value: `https://console.aws.amazon.com/lambda/home?region=${this.region}#/functions/${this.sendEmailLambda.functionName}`,
      description: 'URL de la consola de Lambda para send-email',
    });
  }
}
