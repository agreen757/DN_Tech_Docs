# Security Groups and Network Access Control

## Overview
This document provides comprehensive documentation of AWS Security Groups, Network Access Control Lists (NACLs), and firewall configurations for Distro Nation's infrastructure. Security Groups act as virtual firewalls controlling inbound and outbound traffic at the instance level, while NACLs provide subnet-level network filtering.

## Security Group Architecture

### Tiered Security Model
```yaml
Security Group Hierarchy:
  Tier 1 - Internet-Facing (Public Subnets):
    - Web-tier security groups
    - Load balancer security groups
    - CloudFront origin access
    
  Tier 2 - Application Layer (Private Subnets):
    - Lambda function security groups
    - API Gateway integration security groups
    - Internal service communication
    
  Tier 3 - Data Layer:
    - Database security groups (Aurora PostgreSQL)
    - Backup and maintenance access
    - Cross-service data access
```

## Load Balancer Security Groups

### Application Load Balancer Security Group
```yaml
Security Group Name: fuga-wav-uploader-alb-sg
Security Group ID: sg-xxxxxxxxx (inferred)
Description: Security group for Application Load Balancer (fuga-wav-uploader-alb-dev)

Inbound Rules:
  Rule 1 - HTTP Traffic:
    Type: HTTP
    Protocol: TCP
    Port: 80
    Source: 0.0.0.0/0 (Internet)
    Description: Public HTTP access for redirect to HTTPS
    
  Rule 2 - HTTPS Traffic:
    Type: HTTPS  
    Protocol: TCP
    Port: 443
    Source: 0.0.0.0/0 (Internet)
    Description: Public HTTPS access for secure web traffic
    
  Rule 3 - Health Check:
    Type: Custom TCP
    Protocol: TCP
    Port: 8080
    Source: 10.0.0.0/16 (VPC CIDR)
    Description: ALB health check access to targets

Outbound Rules:
  Rule 1 - All Traffic:
    Type: All Traffic
    Protocol: All
    Port: All
    Destination: 0.0.0.0/0
    Description: Allow all outbound traffic for target communication
```

### CloudFront Origin Security Group
```yaml
Security Group Name: cloudfront-origin-sg
Security Group ID: sg-yyyyyyyyy (inferred)
Description: Security group for CloudFront origin servers

Inbound Rules:
  Rule 1 - CloudFront HTTP:
    Type: HTTP
    Protocol: TCP
    Port: 80
    Source: CloudFront IP ranges (managed prefix list)
    Description: HTTP access from CloudFront edge locations
    
  Rule 2 - CloudFront HTTPS:
    Type: HTTPS
    Protocol: TCP  
    Port: 443
    Source: CloudFront IP ranges (managed prefix list)
    Description: HTTPS access from CloudFront edge locations

Outbound Rules:
  Rule 1 - Database Access:
    Type: PostgreSQL
    Protocol: TCP
    Port: 5432
    Destination: sg-database-aurora
    Description: Database connection for dynamic content
    
  Rule 2 - Internet Access:
    Type: HTTPS
    Protocol: TCP
    Port: 443
    Destination: 0.0.0.0/0
    Description: External API calls and updates
```

## Lambda Function Security Groups

### Primary Lambda Security Group
```yaml
Security Group Name: lambda-functions-sg
Security Group ID: sg-zzzzzzzzz (inferred)
Description: Security group for Lambda functions (84+ functions)

Inbound Rules:
  Rule 1 - API Gateway Access:
    Type: HTTPS
    Protocol: TCP
    Port: 443
    Source: API Gateway service (vpce-xxxxxx)
    Description: Inbound requests from API Gateway
    
  Rule 2 - Internal Lambda Communication:
    Type: All Traffic
    Protocol: All
    Port: All
    Source: sg-lambda-functions-sg (self-reference)
    Description: Inter-Lambda function communication

Outbound Rules:
  Rule 1 - Database Access:
    Type: PostgreSQL
    Protocol: TCP
    Port: 5432
    Destination: sg-database-aurora
    Description: Aurora PostgreSQL database connections
    
  Rule 2 - S3 Access:
    Type: HTTPS
    Protocol: TCP
    Port: 443
    Destination: S3 service (com.amazonaws.<REGION>.s3)
    Description: S3 bucket operations via VPC endpoint
    
  Rule 3 - External API Access:
    Type: HTTPS
    Protocol: TCP
    Port: 443
    Destination: 0.0.0.0/0
    Description: Third-party API calls (YouTube, Spotify, TikTok)
    
  Rule 4 - Email Service:
    Type: SMTP
    Protocol: TCP
    Port: 587
    Destination: 0.0.0.0/0
    Description: Outbound email via Amazon SES
```

### Analytics Lambda Security Group
```yaml
Security Group Name: lambda-analytics-sg
Security Group ID: sg-aaaaaaaaa (inferred)
Description: Security group for analytics Lambda functions (Spotify, TikTok, YouTube)

Inbound Rules:
  Rule 1 - Scheduled Invocation:
    Type: All Traffic
    Protocol: All
    Port: All
    Source: 10.0.0.0/16 (VPC CIDR)
    Description: CloudWatch Events and scheduled triggers

Outbound Rules:
  Rule 1 - External Analytics APIs:
    Type: HTTPS
    Protocol: TCP
    Port: 443
    Destination: 0.0.0.0/0
    Description: Spotify, YouTube, TikTok API access
    
  Rule 2 - Database Writes:
    Type: PostgreSQL
    Protocol: TCP
    Port: 5432
    Destination: sg-database-aurora
    Description: Analytics data storage in Aurora
    
  Rule 3 - S3 Report Storage:
    Type: HTTPS
    Protocol: TCP
    Port: 443
    Destination: S3 service prefix list
    Description: Analytics report storage in S3
```

## Database Security Groups

### Aurora PostgreSQL Security Group
```yaml
Security Group Name: aurora-postgresql-sg
Security Group ID: sg-bbbbbbbbbb (inferred)
Description: Security group for Aurora PostgreSQL cluster (database-2-instance-1)

Inbound Rules:
  Rule 1 - Lambda Function Access:
    Type: PostgreSQL
    Protocol: TCP
    Port: 5432
    Source: sg-lambda-functions-sg
    Description: Lambda function database connections
    
  Rule 2 - Analytics Lambda Access:
    Type: PostgreSQL
    Protocol: TCP
    Port: 5432
    Source: sg-lambda-analytics-sg
    Description: Analytics Lambda database operations
    
  Rule 3 - Admin SSH Tunnel (if configured):
    Type: PostgreSQL
    Protocol: TCP
    Port: 5432
    Source: sg-admin-bastion (if exists)
    Description: Administrative database access
    
  Rule 4 - Application Server Access:
    Type: PostgreSQL
    Protocol: TCP
    Port: 5432
    Source: sg-app-servers
    Description: Direct application server connections

Outbound Rules:
  Rule 1 - No outbound rules required:
    Description: Database servers typically don't initiate outbound connections
    Note: Aurora managed service handles backups and replication internally
```

## EC2 Instance Security Groups

### General EC2 Security Group
```yaml
Security Group Name: ec2-instances-sg
Security Group ID: sg-cccccccccc (inferred)
Description: Security group for EC2 instances (5 instances, 1 running)

Inbound Rules:
  Rule 1 - SSH Access:
    Type: SSH
    Protocol: TCP
    Port: 22
    Source: Admin IP ranges (specific IPs)
    Description: Administrative SSH access
    
  Rule 2 - Application Traffic:
    Type: Custom TCP
    Protocol: TCP
    Port: 8080
    Source: sg-alb-security-group
    Description: Traffic from Application Load Balancer
    
  Rule 3 - Internal Communication:
    Type: All Traffic
    Protocol: All
    Port: All
    Source: 10.0.0.0/16 (VPC CIDR)
    Description: Internal VPC communication

Outbound Rules:
  Rule 1 - All Internet Access:
    Type: All Traffic
    Protocol: All
    Port: All
    Destination: 0.0.0.0/0
    Description: Outbound internet access for updates and APIs
```

### VPN Server Security Group
```yaml
Security Group Name: vpn-server-sg
Security Group ID: sg-dddddddddd (inferred)
Description: Security group for VPN server (i-090dc75e90525eb5e)

Inbound Rules:
  Rule 1 - OpenVPN:
    Type: Custom UDP
    Protocol: UDP
    Port: 1194
    Source: 0.0.0.0/0 (or specific IP ranges)
    Description: OpenVPN client connections
    
  Rule 2 - SSH Management:
    Type: SSH
    Protocol: TCP
    Port: 22
    Source: Admin IP ranges
    Description: Administrative access to VPN server

Outbound Rules:
  Rule 1 - All Traffic:
    Type: All Traffic
    Protocol: All
    Port: All
    Destination: 0.0.0.0/0
    Description: VPN traffic routing and internet access
```

## API Gateway Security Groups

### API Gateway VPC Integration
```yaml
API Gateway Network Configuration:
  dn-api (<API_GATEWAY_ID_2>):
    Integration Type: AWS_PROXY (Lambda integration)
    VPC Integration: Not applicable (Lambda proxy)
    Security: Custom API key authentication
    
  distronationfmGeneralAccess (<API_GATEWAY_ID_1>):
    Integration Type: AWS IAM authentication
    VPC Integration: Private Lambda functions
    Security: IAM signature v4 required

Note: API Gateway is a managed service and doesn't use traditional security groups
Security is managed through:
- Custom authorizers (Lambda functions)
- IAM policies
- API keys and usage plans
- Resource policies (if configured)
```

## Network Access Control Lists (NACLs)

### Default NACL Configuration
```yaml
Default NACL (nacl-xxxxxxxxx):
  Associated Subnets: All subnets (default behavior)
  
Inbound Rules:
  Rule 100:
    Type: All Traffic
    Protocol: All
    Port Range: All
    Source: 0.0.0.0/0
    Action: ALLOW
    
Outbound Rules:
  Rule 100:
    Type: All Traffic
    Protocol: All
    Port Range: All
    Destination: 0.0.0.0/0
    Action: ALLOW

Status: Default permissive configuration
Recommendation: Implement custom NACLs for enhanced security
```

### Recommended Custom NACL Configuration
```yaml
Public Subnet NACL (proposed):
  Associated Subnets: Public subnets (<REGION>a, 1b, 1c)
  
Inbound Rules:
  Rule 100 - HTTP:
    Protocol: TCP
    Port: 80
    Source: 0.0.0.0/0
    Action: ALLOW
    
  Rule 110 - HTTPS:
    Protocol: TCP
    Port: 443
    Source: 0.0.0.0/0
    Action: ALLOW
    
  Rule 120 - SSH (Admin):
    Protocol: TCP
    Port: 22
    Source: Admin IP ranges
    Action: ALLOW
    
  Rule 900 - Ephemeral Ports:
    Protocol: TCP
    Port: 1024-65535
    Source: 0.0.0.0/0
    Action: ALLOW
    
Outbound Rules:
  Rule 100 - All Traffic:
    Protocol: All
    Port: All
    Destination: 0.0.0.0/0
    Action: ALLOW
```

## Firewall Rules by Service

### Web Tier Firewall Rules
```yaml
CloudFront Distributions:
  Allowed Origins: S3 buckets, ALB origins
  Blocked Countries: None (global distribution)
  Rate Limiting: 10,000 requests per 5 minutes per IP
  
Application Load Balancer:
  HTTP → HTTPS Redirect: Automatic
  SSL Termination: CloudFront and ALB
  Sticky Sessions: Not configured
  Connection Draining: 300 seconds
```

### Application Tier Firewall Rules
```yaml
Lambda Functions:
  Execution Environment: VPC (private subnets)
  Internet Access: Via NAT Gateway
  Service Access: VPC Endpoints (S3, DynamoDB)
  
API Gateway:
  Throttling: 10,000 requests per second (burst)
  Authentication: Custom authorizers + API keys
  CORS: Configured per endpoint
  Request Validation: Basic (to be enhanced)
```

### Data Tier Firewall Rules
```yaml
Aurora PostgreSQL:
  Network Isolation: Private subnets only
  Encryption: In-transit and at-rest
  Access Control: IAM database authentication
  Port Access: 5432 from application security groups only
  
S3 Buckets:
  Bucket Policies: Restrict public access
  VPC Endpoints: Cost-optimized internal access
  Cross-Region Replication: Selective buckets
  Lifecycle Policies: Automated data archival
```

## Security Monitoring and Compliance

### Security Group Change Monitoring
```yaml
CloudWatch Events:
  Security Group Changes: Monitored via CloudTrail
  Alerting: SNS notifications for unauthorized changes
  Logging: All security group modifications logged
  
Compliance Checks:
  Automated Scanning: AWS Config rules
  Open Port Detection: Regular security scans
  Compliance Standards: SOC 2 Type II preparation
```

### Network Security Monitoring
```yaml
VPC Flow Logs:
  Status: Not currently enabled
  Recommendation: Enable for security monitoring
  Cost Impact: ~$10-20/month
  Benefit: Complete network traffic visibility
  
Security Scanning:
  Port Scanning: Regular automated scans
  Vulnerability Assessment: Monthly penetration testing
  Intrusion Detection: CloudWatch anomaly detection
```

## Cost Optimization for Security

### Security Group Optimization
```yaml
Current Security Groups: 15-20 estimated
Optimization Opportunities:
  1. Consolidate similar security groups
  2. Remove unused security groups
  3. Optimize rule specificity
  4. Implement security group templates

Cost Impact: Minimal direct cost, operational efficiency gains
Implementation Effort: 1-2 weeks
```

### VPC Endpoint Security
```yaml
VPC Endpoints for Security:
  S3 VPC Endpoint: Avoid internet routing
  DynamoDB VPC Endpoint: Internal AWS traffic
  Lambda VPC Endpoint: Reduce NAT Gateway usage
  
Security Benefits:
  - Traffic remains within AWS network
  - Reduced attack surface
  - No internet gateway dependency
  
Cost Benefits:
  - Reduced NAT Gateway data charges
  - Lower data transfer costs
  - Estimated savings: $15-25/month
```

## Empire Distribution Integration

### Security Standardization Plan
```yaml
Phase 1 - Security Assessment (Weeks 1-2):
  - Complete security group audit
  - Document all firewall rules
  - Identify security gaps and redundancies
  - Baseline security posture assessment
  
Phase 2 - Security Enhancement (Weeks 3-4):
  - Implement missing security controls
  - Enable VPC Flow Logs and monitoring
  - Deploy automated security scanning
  - Create security group templates
  
Phase 3 - Empire Integration (Weeks 5-8):
  - Align security policies with Empire standards
  - Implement cross-account security groups
  - Deploy unified security monitoring
  - Establish security incident response
```

### Cross-Account Security Architecture
```yaml
Empire Integration Security:
  Cross-Account Access:
    - IAM cross-account roles
    - Security group references across accounts
    - Centralized security group management
    
  Unified Security Policies:
    - Standardized security group templates
    - Consistent firewall rule naming
    - Centralized security monitoring
    
  Compliance and Governance:
    - Automated compliance checking
    - Security policy enforcement
    - Regular security assessments
```

## Troubleshooting and Diagnostics

### Common Security Group Issues
```yaml
Issue 1 - Connection Timeouts:
  Symptoms: Lambda functions timing out
  Cause: Missing outbound rules in security groups
  Solution: Add HTTPS (443) outbound rule to 0.0.0.0/0
  
Issue 2 - Database Connection Failures:
  Symptoms: "Connection refused" errors
  Cause: Database security group not allowing Lambda access
  Solution: Add PostgreSQL (5432) inbound rule from Lambda SG
  
Issue 3 - API Gateway 5xx Errors:
  Symptoms: Internal server errors from API Gateway
  Cause: Lambda function network connectivity issues
  Solution: Verify Lambda security group outbound rules
```

### Security Group Validation
```yaml
Validation Commands:
  List Security Groups:
    aws ec2 describe-security-groups --region <REGION>
    
  Check Security Group Rules:
    aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx
    
  Validate Network Connectivity:
    aws ec2 describe-network-interfaces --region <REGION>
    
  Test Port Connectivity:
    telnet <target-ip> <port>
    nc -zv <target-ip> <port>
```

## Related Documentation
- [VPC Network Topology](./vpc-topology.md)
- [Load Balancer Configuration](./load-balancers.md)
- [Network Monitoring and Security](./network-monitoring.md)
- [Security Policies Framework](../security/security-policies.md)
- [Access Control Matrix](../security/access-control-matrix.md)

---

**Document Version**: 1.0  
**Last Updated**: July 24, 2025  
**Prepared By**: Adrian Green, Head of Engineering  
**Review Status**: Ready for Empire Distribution technical review

*This document contains detailed security configuration information. Access is restricted to authorized security and network personnel involved in the acquisition integration planning.*