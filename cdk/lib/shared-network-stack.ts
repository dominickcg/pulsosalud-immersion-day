import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import { Construct } from 'constructs';

/**
 * SharedNetworkStack - VPC compartida para todos los participantes del workshop
 * 
 * Este stack crea la infraestructura de red que será compartida por todos los participantes:
 * - VPC con CIDR 192.168.0.0/16
 * - 2 Subnets públicas (para NAT Gateway, API Gateway)
 * - 2 Subnets privadas (para Lambdas)
 * - 2 Subnets aisladas (para Aurora)
 * - 1 NAT Gateway (para minimizar costos)
 * - 1 Internet Gateway
 * 
 * Los recursos se exportan como CloudFormation exports para que otros stacks los importen.
 */
export interface SharedNetworkStackProps extends cdk.StackProps {
  // No se necesitan props adicionales
}

export class PulsoSaludNetworkStack extends cdk.Stack {
  public readonly vpc: ec2.Vpc;

  constructor(scope: Construct, id: string, props?: SharedNetworkStackProps) {
    super(scope, id, props);

    // ========================================
    // VPC Compartida
    // ========================================
    this.vpc = new ec2.Vpc(this, 'SharedVPC', {
      ipAddresses: ec2.IpAddresses.cidr('192.168.0.0/16'),
      maxAzs: 2,
      natGateways: 1, // Solo 1 NAT Gateway para minimizar costos
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC,
        },
        {
          cidrMask: 24,
          name: 'Private',
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
        },
        {
          cidrMask: 24,
          name: 'Isolated',
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
        },
      ],
    });

    // ========================================
    // CloudFormation Exports
    // ========================================
    
    // Export VPC ID
    new cdk.CfnOutput(this, 'VpcId', {
      value: this.vpc.vpcId,
      description: 'ID de la VPC compartida',
      exportName: 'PulsoSaludNetworkStack-VpcId',
    });

    // Export Public Subnet IDs (separados por comas)
    new cdk.CfnOutput(this, 'PublicSubnetIds', {
      value: this.vpc.publicSubnets.map(subnet => subnet.subnetId).join(','),
      description: 'IDs de las subnets públicas (separados por comas)',
      exportName: 'PulsoSaludNetworkStack-PublicSubnetIds',
    });

    // Export Private Subnet IDs (separados por comas)
    new cdk.CfnOutput(this, 'PrivateSubnetIds', {
      value: this.vpc.privateSubnets.map(subnet => subnet.subnetId).join(','),
      description: 'IDs de las subnets privadas (separados por comas)',
      exportName: 'PulsoSaludNetworkStack-PrivateSubnetIds',
    });

    // Export Isolated Subnet IDs (separados por comas)
    new cdk.CfnOutput(this, 'IsolatedSubnetIds', {
      value: this.vpc.isolatedSubnets.map(subnet => subnet.subnetId).join(','),
      description: 'IDs de las subnets aisladas (separados por comas)',
      exportName: 'PulsoSaludNetworkStack-IsolatedSubnetIds',
    });

    // Export Availability Zones (separadas por comas)
    new cdk.CfnOutput(this, 'AvailabilityZones', {
      value: this.vpc.availabilityZones.join(','),
      description: 'Zonas de disponibilidad de la VPC (separadas por comas)',
      exportName: 'PulsoSaludNetworkStack-AvailabilityZones',
    });

    // Export VPC CIDR Block
    new cdk.CfnOutput(this, 'VpcCidrBlock', {
      value: this.vpc.vpcCidrBlock,
      description: 'CIDR block de la VPC compartida',
      exportName: 'PulsoSaludNetworkStack-VpcCidrBlock',
    });
  }
}
