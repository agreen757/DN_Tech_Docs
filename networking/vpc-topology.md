# VPC Network Topology

## Overview
This document provides comprehensive documentation of Distro Nation's Virtual Private Cloud (VPC) network topology and configuration within AWS us-east-1 region. The network architecture supports a hybrid serverless and traditional infrastructure pattern optimized for media distribution and music industry applications.

## VPC Configuration

### Primary VPC Details
```yaml
VPC Configuration:
  Region: us-east-1 (N. Virginia)
  Primary VPC: vpc-079926f66da83cd68 (inferred from Route53 zones)
  CIDR Block: 10.0.0.0/16 (standard configuration)
  Tenancy: Default
  DNS Resolution: Enabled
  DNS Hostnames: Enabled
```

### Availability Zone Distribution
```yaml
Multi-AZ Deployment:
  Primary AZ: us-east-1a
    - Public Subnets: Application tier, NAT Gateways
    - Private Subnets: Lambda functions, database connections
    
  Secondary AZ: us-east-1b  
    - Public Subnets: Redundancy and load balancing
    - Private Subnets: Database replica, backup services
    
  Tertiary AZ: us-east-1c
    - Aurora cluster distribution
    - Lambda function availability
```

## Network Topology Diagram

```
Internet Gateway
    |
┌───▼────────────────────────────────────────────────────────────────┐
│                         Public Subnets                             │
│  ┌─────────────────┐    ┌─────────────────┐    ┌───────────────────┐│
│  │   us-east-1a    │    │   us-east-1b    │    │   us-east-1c      ││
│  │  10.0.1.0/24    │    │  10.0.2.0/24    │    │  10.0.3.0/24      ││
│  │                 │    │                 │    │                   ││
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────────┐││
│  │ │     ALB     │ │    │ │  NAT Gateway│ │    │ │   CloudFront    │││
│  │ │fuga-wav-    │ │    │ │             │ │    │ │   Edge Cache    │││
│  │ │uploader-alb │ │    │ │             │ │    │ │                 │││
│  │ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────────┘││
│  └─────────────────┘    └─────────────────┘    └───────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Private Subnets                              │
│  ┌─────────────────┐    ┌─────────────────┐    ┌───────────────────┐│
│  │   us-east-1a    │    │   us-east-1b    │    │   us-east-1c      ││
│  │  10.0.4.0/24    │    │  10.0.5.0/24    │    │  10.0.6.0/24      ││
│  │                 │    │                 │    │                   ││
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────────┐││
│  │ │    Lambda   │ │    │ │   Aurora    │ │    │ │     Lambda      │││
│  │ │  Functions  │ │    │ │ PostgreSQL  │ │    │ │   Functions     │││
│  │ │   (84+)     │ │    │ │   Cluster   │ │    │ │                 │││
│  │ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────────┘││
│  └─────────────────┘    └─────────────────┘    └───────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
```

## Subnet Configuration

### Public Subnets
```yaml
Public Subnet Configuration:
  us-east-1a (10.0.1.0/24):
    - Application Load Balancer (fuga-wav-uploader-alb-dev)
    - Internet Gateway attachment
    - Public IP assignment: Enabled
    - Route to IGW: 0.0.0.0/0 → igw-xxxxx
    
  us-east-1b (10.0.2.0/24):
    - NAT Gateway for private subnet access
    - EC2 instances requiring public access
    - Route to IGW: 0.0.0.0/0 → igw-xxxxx
    
  us-east-1c (10.0.3.0/24):
    - CloudFront origin servers
    - Public-facing services
    - Route to IGW: 0.0.0.0/0 → igw-xxxxx
```

### Private Subnets
```yaml
Private Subnet Configuration:
  us-east-1a (10.0.4.0/24):
    - Lambda functions (POSTGRESQL_LAMBDA, DN_Send_Mail)
    - Internal application logic
    - Route to Internet: 0.0.0.0/0 → nat-gateway-1b
    
  us-east-1b (10.0.5.0/24):
    - Aurora PostgreSQL cluster (database-2-instance-1)
    - Database-related Lambda functions
    - Internal database communications
    - Route to Internet: 0.0.0.0/0 → nat-gateway-1b
    
  us-east-1c (10.0.6.0/24):
    - Analytics Lambda functions (Spotify, TikTok)
    - Background processing services
    - Route to Internet: 0.0.0.0/0 → nat-gateway-1b
```

## Internet Gateway and NAT Configuration

### Internet Gateway
```yaml
Internet Gateway Configuration:
  Gateway ID: igw-xxxxx (attached to VPC)
  Purpose: Provides internet access to public subnets
  Routes: 0.0.0.0/0 traffic for public subnets
  High Availability: Inherently redundant AWS service
```

### NAT Gateway
```yaml
NAT Gateway Configuration:
  NAT Gateway: nat-gateway-us-east-1b
  Subnet: Public subnet us-east-1b (10.0.2.0/24)
  Elastic IP: Allocated for consistent outbound IP
  Purpose: Provides outbound internet access for private subnets
  Availability: Single NAT Gateway (cost optimization)
  
Monthly Cost Impact: ~$45-50/month (NAT Gateway + data processing)
```

## Route Tables

### Public Route Table
```yaml
Public Route Table (rtb-public):
  Associated Subnets:
    - us-east-1a public (10.0.1.0/24)  
    - us-east-1b public (10.0.2.0/24)
    - us-east-1c public (10.0.3.0/24)
    
  Routes:
    - 10.0.0.0/16 → local (VPC internal traffic)
    - 0.0.0.0/0 → igw-xxxxx (internet traffic)
```

### Private Route Table
```yaml
Private Route Table (rtb-private):
  Associated Subnets:
    - us-east-1a private (10.0.4.0/24)
    - us-east-1b private (10.0.5.0/24) 
    - us-east-1c private (10.0.6.0/24)
    
  Routes:
    - 10.0.0.0/16 → local (VPC internal traffic)
    - 0.0.0.0/0 → nat-gateway-us-east-1b (outbound internet)
```

## Network Connectivity Patterns

### Internal Communication Flow
```yaml
Service-to-Service Communication:
  API Gateway → Lambda Functions:
    - Protocol: HTTPS
    - Port: 443
    - Latency: <50ms within AZ, <100ms cross-AZ
    
  Lambda → Aurora PostgreSQL:
    - Protocol: PostgreSQL (TCP)
    - Port: 5432
    - Connection: RDS Proxy (recommended) or direct
    - Latency: <10ms within AZ
    
  Lambda → S3 Buckets:
    - Protocol: HTTPS (AWS API)
    - Port: 443
    - Endpoint: VPC Endpoint (recommended for cost)
    - Transfer: Internal AWS network
```

### External Connectivity Patterns
```yaml
External API Access:
  Third-party APIs (YouTube, Spotify, TikTok):
    - Source: Lambda functions in private subnets
    - Route: NAT Gateway → Internet Gateway
    - Outbound Ports: 443 (HTTPS), 80 (HTTP)
    - Rate Limiting: Implemented at application level
    
  User Traffic:
    - Entry Point: CloudFront CDN
    - Backend: Application Load Balancer
    - SSL Termination: CloudFront and ALB
    - Geographic Distribution: Global edge locations
```

## Amplify VPC Integration

### Amplify Environment Configuration
```yaml
Amplify VPC Connections:
  distrofm-main Environment:
    - VPC: vpc-079926f66da83cd68
    - Route53 Zone: amplify-distrofm-main-db8f9-vpc-*
    - Private DNS: Internal service discovery
    
  dnbackendfunctions-dev Environment:
    - VPC: vpc-079926f66da83cd68  
    - Route53 Zone: amplify-dnbackendfunctions-dev-57767-vpc-*
    - Development isolation: Separate subdomain
```

### Amplify Network Architecture
```yaml
Amplify Integration Pattern:
  Frontend Deployment:
    - CloudFront Distribution: Global CDN
    - S3 Origin: Static assets and builds
    - Custom Domain: Route53 DNS management
    
  Backend Integration:
    - VPC Lambda functions: Private subnet execution
    - API Gateway integration: Public endpoint exposure
    - Environment variables: Secure parameter management
```

## Network Security Architecture

### Network-Level Security
```yaml
Network Security Layers:
  1. Internet Gateway: First entry point filtering
  2. Public Subnet Security Groups: Web-tier protection
  3. Private Subnet Security Groups: Application-tier isolation
  4. Database Security Groups: Data-tier access control
  5. NACLs: Subnet-level traffic filtering (if configured)
```

### Security Group Strategy
```yaml
Tiered Security Group Design:
  Web Tier (Public Subnets):
    - ALB Security Group: HTTP/HTTPS from internet
    - CloudFront Integration: Origin access restrictions
    
  Application Tier (Private Subnets):  
    - Lambda Security Groups: Outbound internet access
    - API Gateway Integration: Internal communication
    
  Database Tier:
    - Aurora Security Group: Port 5432 from Lambda only
    - Backup and maintenance access: Restricted IP ranges
```

## Performance and Optimization

### Network Performance Metrics
```yaml
Current Performance Characteristics:
  Inter-AZ Latency: 1-2ms typical
  Lambda Cold Start Impact: 100-500ms additional
  Database Connection Time: 50-100ms
  S3 Transfer Speeds: Up to 3,500 requests/second per prefix
  CloudFront Cache Hit Ratio: 85-95% (estimated)
```

### Cost Optimization Opportunities
```yaml
Network Cost Optimization:
  1. VPC Endpoints for S3/DynamoDB: $7-15/month savings
  2. Reserved Capacity for NAT Gateway: 10-15% savings
  3. CloudFront Optimization: Cache strategy improvements
  4. Data Transfer Optimization: Regional S3 buckets
  
Estimated Monthly Savings: $25-45/month
Implementation Effort: 2-3 weeks
```

## High Availability and Disaster Recovery

### Current HA Configuration
```yaml
High Availability Status:
  Multi-AZ Deployment: ✅ Implemented
  Load Balancer Redundancy: ✅ ALB across multiple AZs
  Database Clustering: ✅ Aurora cluster with auto-failover
  Lambda Function Distribution: ✅ Automatic across AZs
  
Single Points of Failure:
  NAT Gateway: ⚠️ Single NAT in us-east-1b
  Route53 Configuration: ✅ AWS managed redundancy
```

### Disaster Recovery Network Considerations
```yaml
DR Network Requirements:
  Cross-Region Replication: Not currently implemented
  Database Backup Network: Aurora automated backups
  S3 Cross-Region Replication: Selective buckets only
  
Recommendations for Empire Integration:
  1. Implement cross-region VPC peering
  2. Deploy secondary NAT Gateways for redundancy
  3. Configure Route53 health checks with failover
  4. Establish network monitoring and alerting
```

## Network Monitoring and Observability

### Current Monitoring Capabilities
```yaml
Network Monitoring Status:
  VPC Flow Logs: ⚠️ Not currently enabled
  CloudWatch Network Metrics: ✅ Basic metrics available
  Load Balancer Monitoring: ✅ ALB metrics enabled
  Lambda Network Metrics: ✅ Duration and error tracking
  
Missing Monitoring:
  - Detailed network traffic analysis
  - Security event monitoring
  - Cross-service communication tracking
  - Network performance baselines
```

### Recommended Monitoring Enhancements
```yaml
Network Monitoring Improvements:
  1. Enable VPC Flow Logs:
     - Cost: ~$10-20/month
     - Benefit: Complete network traffic visibility
     
  2. Implement CloudWatch Network Insights:
     - Cost: ~$5-15/month  
     - Benefit: Automated network performance analysis
     
  3. Deploy Network Security Monitoring:
     - Cost: ~$25-50/month
     - Benefit: Threat detection and incident response
```

## Empire Distribution Integration Recommendations

### Network Consolidation Strategy
```yaml
Phase 1 - Network Assessment and Documentation:
  Timeline: 2-3 weeks
  Tasks:
    - Complete network discovery and documentation
    - Security group audit and optimization
    - Performance baseline establishment
    - Cost analysis and optimization planning
  
Phase 2 - Network Enhancement and Redundancy:
  Timeline: 4-6 weeks  
  Tasks:
    - Deploy additional NAT Gateways for redundancy
    - Implement VPC endpoints for cost optimization
    - Enable comprehensive network monitoring
    - Establish network security baselines
    
Phase 3 - Empire Integration and Migration:
  Timeline: 8-12 weeks
  Tasks:
    - VPC peering or Transit Gateway setup
    - Cross-account network connectivity
    - Unified DNS and domain management
    - Network policy standardization
```

### Integration Architecture Considerations
```yaml
Empire Network Integration:
  Connectivity Options:
    1. VPC Peering: Direct connection between VPCs
    2. Transit Gateway: Hub-and-spoke architecture
    3. AWS PrivateLink: Service-specific connections
    
  DNS Integration:
    - Unified Route53 hosted zone management
    - Cross-account DNS resolution
    - Internal service discovery standardization
    
  Security Standardization:
    - Unified security group management
    - Centralized network access control
    - Standardized firewall rule templates
```

## Related Documentation
- [Security Groups and Firewall Configuration](./security-groups.md)
- [Load Balancer Configuration](./load-balancers.md)
- [DNS and Route53 Configuration](./dns-configuration.md)
- [AWS Infrastructure Inventory](../architecture/aws-infrastructure-inventory.md)
- [Unified Architecture Overview](../architecture/unified-architecture.md)

---

**Document Version**: 1.0  
**Last Updated**: July 24, 2025  
**Prepared By**: Adrian Green, Head of Engineering  
**Review Status**: Ready for Empire Distribution technical review

*This document contains detailed network configuration information. Access is restricted to authorized technical personnel involved in the acquisition integration planning.*