# Network Connectivity Patterns

## Overview
This document provides comprehensive documentation of network connectivity patterns and service-to-service communication within Distro Nation's infrastructure. Understanding these patterns is critical for troubleshooting, performance optimization, and integration planning with Empire Distribution.

## Service Communication Architecture

### High-Level Communication Flow
```yaml
User Request Flow:
  1. Client → CloudFront CDN (Global Edge Locations)
  2. CDN → Application Load Balancer (<REGION>)
  3. ALB → EC2 Instances or API Gateway
  4. API Gateway → Lambda Functions (VPC)
  5. Lambda → Aurora PostgreSQL Database
  6. Lambda → External APIs (YouTube, Spotify, TikTok)

Internal Service Flow:
  1. Lambda Functions → Aurora PostgreSQL (Port 5432)
  2. Lambda Functions → S3 Buckets (HTTPS API)
  3. Lambda Functions → Other Lambda Functions (Event-driven)
  4. EC2 Instances → Aurora PostgreSQL (Port 5432)
  5. Amplify Apps → Lambda Functions (API Gateway)
```

## API Gateway Communication Patterns

### dn-api Gateway Connectivity
```yaml
Gateway Configuration:
  API ID: <API_GATEWAY_ID_2>
  Endpoint: https://<API_GATEWAY_ID_2>.execute-api.<REGION>.amazonaws.com
  Stage: staging
  
Inbound Connections:
  Source: CloudFront Distribution (E1FZO978Z8RTXO)
  Protocol: HTTPS (Port 443)
  Authentication: API Key (header-based)
  Rate Limiting: AWS default throttling
  
Outbound Connections:
  Target: Lambda Functions (84+ functions)
  Integration Type: AWS_PROXY
  Timeout: 29 seconds
  Retry Logic: Exponential backoff (3 attempts)
  
Connection Patterns:
  Administrative Endpoints:
    /dn_users_list → Lambda: dn_users_list
    /dn_payouts_fetch → Lambda: dn_payouts_fetch
    /send-mail → Lambda: DN_Send_Mail
    
  Data Processing Endpoints:
    /dn_partner_list_korrect → Lambda: dn_partner_list_korrect
    /payout-audit → Lambda: dn_payout_audit
```

### distronationfmGeneralAccess Gateway Connectivity
```yaml
Gateway Configuration:
  API ID: <API_GATEWAY_ID_1>
  Endpoint: https://<API_GATEWAY_ID_1>.execute-api.<REGION>.amazonaws.com
  Stage: main
  
Inbound Connections:
  Source: CloudFront Distribution (E1IK0N6Y8U0JE2)
  Protocol: HTTPS (Port 443)
  Authentication: AWS_IAM (Signature v4)
  Rate Limiting: 10,000 requests/second, 5,000 burst
  
Outbound Connections:
  Target: Lambda Functions (DistroFM-specific)
  Integration Type: AWS_PROXY
  VPC Integration: Private subnet Lambda functions
  
Connection Patterns:
  Content Processing:
    /artist-info/{id} → Lambda: distrofmFetchArtistInfo-main
    /submit-video → Video processing Lambda chain
    /parse/{id} → Content parsing Lambda functions
    /evalvideoid/{id} → Video validation Lambda functions
```

## Lambda Function Connectivity Patterns

### Database Connectivity Pattern
```yaml
Lambda → Aurora PostgreSQL:
  Connection Protocol: PostgreSQL (TCP)
  Port: 5432
  Connection Pooling: Not implemented (recommended: RDS Proxy)
  SSL/TLS: Required (in-transit encryption)
  
Connection Details:
  Source: Lambda functions in private subnets
  Target: Aurora cluster (database-2-instance-1)
  Network Path: VPC internal routing
  Latency: <10ms within same AZ, <50ms cross-AZ
  
Connection Management:
  Max Connections per Lambda: 16 (default Aurora limit)
  Connection Timeout: 30 seconds
  Idle Timeout: 8 hours (Aurora default)
  Connection Reuse: Limited (cold start creates new connections)
  
Functions with Database Access:
  - POSTGRESQL_LAMBDA (primary database operations)
  - dn_spotify_analytics (analytics data storage)
  - dn_tiktok_analytics (analytics data storage)
  - dn_payouts_fetch (payout data retrieval)
  - distrofmFetchArtistInfo-main (artist data queries)
```

### S3 Connectivity Pattern
```yaml
Lambda → S3 Buckets:
  Connection Protocol: HTTPS (AWS API)
  Port: 443
  Endpoint: VPC Endpoint (recommended) or Internet Gateway
  Authentication: IAM roles and policies
  
S3 Access Patterns:
  Audio Storage Access:
    Bucket: distronation-audio
    Operations: GetObject, PutObject
    Lambda Functions: Audio processing, file upload handlers
    
  Upload Storage Access:
    Bucket: distro-nation-upload
    Operations: GetObject, PutObject, DeleteObject
    Lambda Functions: File upload processors, cleanup functions
    
  Profile Pictures Access:
    Bucket: distronationfm-profile-pictures
    Operations: GetObject, PutObject
    Lambda Functions: Profile management, image processing
    
  Backup Storage Access:
    Bucket: distronation-backup
    Operations: PutObject (write-only)
    Lambda Functions: Backup automation, data archival
    
Connection Optimization:
  VPC Endpoints: Recommended for cost reduction
  Current Routing: Via NAT Gateway (internet routing)
  Data Transfer: Internal AWS network preferred
  Cost Impact: ~$0.01 per GB via VPC Endpoint vs $0.045 per GB via NAT
```

### External API Connectivity Pattern
```yaml
Lambda → External APIs:
  Connection Protocol: HTTPS
  Port: 443
  Network Path: Private Subnet → NAT Gateway → Internet Gateway
  Rate Limiting: Application-level implementation
  
YouTube API Connectivity:
  Lambda Function: YouTube_API_Token
  Endpoint: https://www.googleapis.com/youtube/v3/
  Authentication: API Key + OAuth 2.0
  Rate Limits: 10,000 units per day (quota)
  Connection Pattern: RESTful API calls
  
Spotify API Connectivity:
  Lambda Function: dn_spotify_analytics
  Endpoint: https://api.spotify.com/v1/
  Authentication: Client Credentials OAuth flow
  Rate Limits: 10,000 requests per month
  Connection Pattern: Scheduled analytics data fetching
  
TikTok API Connectivity:
  Lambda Function: dn_tiktok_analytics
  Endpoint: https://open-api.tiktok.com/
  Authentication: App ID + Secret
  Rate Limits: Varies by endpoint
  Connection Pattern: Batch analytics processing
  
Connection Management:
  Connection Pooling: HTTP keep-alive (limited by Lambda runtime)
  Timeout Configuration: 30 seconds per request
  Retry Logic: Exponential backoff with jitter
  Error Handling: Circuit breaker pattern (recommended)
```

## Load Balancer Connectivity Patterns

### Application Load Balancer Connectivity
```yaml
ALB Inbound Connectivity:
  Load Balancer: fuga-wav-uploader-alb-dev
  Listeners:
    Port 80 (HTTP): Redirect to HTTPS
    Port 443 (HTTPS): Forward to target group
  
  Source Connections:
    CloudFront Distributions: Origin requests
    Direct Client Access: Public internet (if not behind CDN)
    Health Checks: ALB internal health checking
    
ALB Outbound Connectivity:
  Target Group: fuga-wav-upload-targets
  Protocol: HTTP (internal VPC traffic)
  Port: 8080
  Health Check Path: /health
  
  Target Instances:
    Instance: i-0063537094eb961dd (Shazampy-env)
    Health Status: healthy
    Connection Pattern: Round-robin load balancing
    
Load Balancing Algorithm:
  Method: Round Robin
  Sticky Sessions: Disabled
  Connection Draining: 300 seconds
  Cross-Zone Load Balancing: Enabled
```

### CloudFront to ALB Connectivity
```yaml
CloudFront → ALB Communication:
  Origin Protocol Policy: HTTPS Only
  Origin Domain: fuga-wav-uploader-alb-dev-xxxxxxxxx.<REGION>.elb.amazonaws.com
  Origin Port: 443
  Origin Path: / (root)
  
Connection Headers:
  X-Forwarded-Proto: https
  X-Forwarded-For: {client-ip}
  X-Amz-Cf-Id: {request-id}
  CloudFront-Viewer-Country: {country-code}
  
Connection Characteristics:
  Keep-Alive: Enabled (CloudFront manages connection pooling)
  Timeout: 30 seconds (origin request timeout)
  Retry Logic: 3 attempts for failed connections
  SSL/TLS: Full encryption end-to-end
```

## VPC Internal Connectivity

### Inter-Subnet Communication
```yaml
Public to Private Subnet Communication:
  Path: ALB (Public) → Lambda (Private)
  Routing: VPC internal routing table
  Security: Security group rules
  Latency: <1ms (same AZ), <5ms (cross-AZ)
  
Private Subnet Internal Communication:
  Lambda ↔ Lambda: Direct VPC routing
  Lambda ↔ Aurora: Direct VPC routing
  EC2 ↔ Aurora: Direct VPC routing
  
Cross-AZ Communication:
  Availability Zones: <REGION>a, <REGION>b, <REGION>c
  Network Performance: 25 Gbps between AZs
  Data Transfer Cost: $0.01 per GB between AZs
  Latency: 1-2ms typical between AZs
```

### VPC Endpoint Connectivity
```yaml
Current VPC Endpoints:
  Status: Not currently implemented
  Recommended Endpoints:
    S3 VPC Endpoint: Gateway endpoint for S3 access
    DynamoDB VPC Endpoint: Gateway endpoint (if DynamoDB used)
    Lambda VPC Endpoint: Interface endpoint for Lambda invocation
    
Proposed S3 VPC Endpoint:
  Type: Gateway Endpoint
  Route Table: Private subnet route table
  Policy: Allow access to required S3 buckets only
  Cost Savings: ~$20-30/month in NAT Gateway data charges
  
Proposed Lambda VPC Endpoint:
  Type: Interface Endpoint
  Subnets: Private subnets (<REGION>a, <REGION>b, <REGION>c)
  Security Group: Allow HTTPS (443) from Lambda functions
  DNS: Private DNS names enabled
```

## Database Connectivity Patterns

### Aurora PostgreSQL Connectivity
```yaml
Database Cluster Configuration:
  Identifier: database-2-instance-1
  Engine: aurora-postgresql
  Port: 5432
  Multi-AZ: Enabled (serverless automatically manages)
  
Connection Sources:
  Lambda Functions:
    Connection Pool: Individual connections per function instance
    SSL Mode: require
    Connection String: Host-based authentication
    Max Connections: Limited by Aurora connection limits
    
  EC2 Instances:
    Instance: i-0063537094eb961dd (if database access needed)
    Connection Type: Direct PostgreSQL connection
    Security Group: Restricted access from application security group
    
Connection Optimization Recommendations:
  RDS Proxy Implementation:
    Benefits: Connection pooling, automatic failover
    Cost: ~$0.015 per vCPU per hour
    Connection Limit: Up to 100 connections per proxy
    Latency Impact: <1ms additional latency
    
  Connection Pooling Strategy:
    pgBouncer: External connection pooler (if needed)
    Application-level: Connection reuse within Lambda runtime
    Database-level: Aurora connection management
```

## Network Performance Characteristics

### Latency Patterns
```yaml
Service-to-Service Latency:
  CloudFront → ALB: 50-200ms (geographic variation)
  ALB → EC2 Instance: <5ms (same AZ)
  API Gateway → Lambda: <10ms (cold start excluded)
  Lambda → Aurora PostgreSQL: <10ms (same AZ)
  Lambda → S3 (via NAT): <20ms
  Lambda → External APIs: 100-500ms (internet latency)
  
Cold Start Impact:
  Lambda Cold Start: 100-500ms additional latency
  Mitigation: Provisioned concurrency (not currently configured)
  Warm-up Strategies: CloudWatch Events for keep-alive
```

### Throughput Patterns
```yaml
Current Throughput Capacity:
  API Gateway: 10,000 requests per second per account
  Lambda Concurrent Executions: 1,000 (account limit)
  Aurora PostgreSQL: Variable (serverless scaling)
  ALB: 25,000 requests per second per node
  
Bottleneck Analysis:
  Primary Bottleneck: Lambda concurrency limits
  Secondary Bottleneck: Database connection limits
  Tertiary Bottleneck: NAT Gateway bandwidth (45 Gbps)
  
Scaling Patterns:
  Horizontal Scaling: Additional Lambda functions
  Vertical Scaling: Aurora serverless auto-scaling
  Geographic Scaling: CloudFront edge locations
```

## Security and Access Control

### Network Security Boundaries
```yaml
Security Zone Architecture:
  Internet Zone:
    Components: CloudFront, public Route53 records
    Access Control: WAF rules, CloudFront restrictions
    
  DMZ Zone (Public Subnets):
    Components: Application Load Balancer, NAT Gateway
    Access Control: Security groups, NACLs
    
  Application Zone (Private Subnets):
    Components: Lambda functions, EC2 instances
    Access Control: Security groups, IAM roles
    
  Data Zone:
    Components: Aurora PostgreSQL, S3 buckets
    Access Control: Database security groups, S3 bucket policies
```

### Connection Authentication
```yaml
Authentication Methods:
  CloudFront → ALB: No authentication (origin access)
  API Gateway → Lambda: AWS IAM integration
  Lambda → Aurora: IAM database authentication (recommended)
  Lambda → S3: IAM role-based access
  Lambda → External APIs: API keys, OAuth tokens
  
IAM Role-Based Access:
  Lambda Execution Roles: Principle of least privilege
  Cross-Service Permissions: Resource-specific policies
  Temporary Credentials: STS token refresh (automatic)
```

## Monitoring and Observability

### Connection Monitoring
```yaml
CloudWatch Metrics:
  API Gateway Metrics:
    - Count: Number of API calls
    - Latency: End-to-end request latency
    - Error: 4XX and 5XX error rates
    - IntegrationLatency: Backend integration time
    
  Lambda Metrics:
    - Duration: Function execution time
    - Errors: Function error count
    - Throttles: Concurrent execution limit hits
    - DeadLetterErrors: Failed message processing
    
  ALB Metrics:
    - RequestCount: Total requests processed
    - TargetResponseTime: Backend response time
    - HTTPCode_Target_2XX_Count: Successful responses
    - ActiveConnectionCount: Current connections
    
VPC Flow Logs:
  Status: Not currently enabled
  Recommendation: Enable for network traffic analysis
  Destination: CloudWatch Logs or S3 bucket
  Cost: ~$0.50 per GB of log data
```

### Performance Baselines
```yaml
Current Performance Baselines:
  API Response Time: <500ms (95th percentile)
  Database Query Time: <100ms (average)
  S3 Object Retrieval: <200ms (average)
  External API Response: 1-3 seconds (varies by service)
  
Alerting Thresholds:
  High Latency: >2 seconds API response time
  High Error Rate: >5% error rate over 5 minutes
  Connection Failures: >10 failed connections per minute
  Database Connection Issues: Connection pool exhaustion
```

## Empire Distribution Integration Planning

### Connectivity Assessment for Integration
```yaml
Phase 1 - Network Discovery (Weeks 1-2):
  Tasks:
    - Document all current connectivity patterns
    - Identify integration touchpoints with Empire systems
    - Assess network security requirements
    - Map data flow dependencies
    
Phase 2 - Integration Design (Weeks 3-4):
  Tasks:
    - Design cross-account connectivity patterns
    - Plan API gateway consolidation or federation
    - Design shared database access patterns
    - Plan unified monitoring and alerting
    
Phase 3 - Implementation (Weeks 5-8):
  Tasks:
    - Implement VPC peering or Transit Gateway
    - Deploy cross-account IAM roles and policies
    - Establish shared monitoring infrastructure
    - Implement unified logging and tracing
```

### Integration Architecture Patterns
```yaml
Cross-Account Connectivity Options:
  Option 1 - VPC Peering:
    Implementation: Direct network connection between VPCs
    Benefits: Low latency, high bandwidth, cost-effective
    Use Case: Direct service-to-service communication
    
  Option 2 - Transit Gateway:
    Implementation: Hub-and-spoke network architecture
    Benefits: Scalable, centralized routing, easier management
    Use Case: Multiple account/region connectivity
    
  Option 3 - API-Based Integration:
    Implementation: REST API federation between systems
    Benefits: Loose coupling, easier to manage
    Use Case: Service integration without network coupling
    
Shared Service Patterns:
  Shared Database Access:
    Pattern: Cross-account Aurora access via VPC peering
    Security: Cross-account security groups and IAM
    
  Shared Storage Access:
    Pattern: Cross-account S3 bucket policies
    Security: Bucket policies with account principals
    
  Shared API Access:
    Pattern: API Gateway resource policies
    Security: Cross-account API key sharing
```

## Related Documentation
- [VPC Network Topology](./vpc-topology.md)
- [Security Groups Configuration](./security-groups.md)
- [Load Balancer Configuration](./load-balancers.md)
- [DNS Configuration](./dns-configuration.md)
- [API Gateway Overview](../api/api-gateway-overview.md)

---

**Document Version**: 1.0  
**Last Updated**: July 24, 2025  
**Prepared By**: Adrian Green, Head of Engineering  
**Review Status**: Ready for Empire Distribution technical review

*This document contains detailed network connectivity information. Access is restricted to authorized technical personnel involved in the acquisition integration planning.*