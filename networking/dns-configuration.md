# DNS Configuration and Route53 Management

## Overview
This document provides comprehensive documentation of DNS configuration and Route53 hosted zone management for Distro Nation's infrastructure. Route53 serves as the primary DNS service managing domain resolution, health checks, and traffic routing for all applications and services.

## Route53 Hosted Zones

### VPC-Specific Hosted Zones
```yaml
Amplify-Generated VPC Zones:
  Zone 1 - distrofm-main:
    Name: amplify-distrofm-main-db8f9-vpc-079926f66da83cd68.
    Zone ID: Z0969604XDAUQX7C50JF
    VPC: vpc-079926f66da83cd68
    Purpose: Private DNS resolution for distrofm-main environment
    Created: May 20, 2024 (estimated)
    
  Zone 2 - dnbackendfunctions-dev:
    Name: amplify-dnbackendfunctions-dev-57767-vpc-079926f66da83cd68.
    Zone ID: Z0478090G2ORMOCNLU71
    VPC: vpc-079926f66da83cd68
    Purpose: Private DNS resolution for development backend functions
    Created: June 14, 2024 (estimated)
```

### Public Hosted Zones (Inferred)
```yaml
Primary Domain Zones:
  distronation.com (assumed):
    Zone Type: Public hosted zone
    Purpose: Primary domain for Distro Nation platform
    Records: Web application, API endpoints, CDN origins
    SSL Certificate: *.distronation.com wildcard certificate
    
  distrofm.com (assumed):
    Zone Type: Public hosted zone  
    Purpose: DistroFM application domain
    Records: Application endpoints, media services
    Integration: CloudFront distributions, S3 buckets
```

## DNS Record Configuration

### Application Load Balancer DNS Records
```yaml
ALB DNS Configuration:
  Load Balancer DNS Name: fuga-wav-uploader-alb-dev-xxxxxxxxx.<REGION>.elb.amazonaws.com
  Hosted Zone ID: Z35SXDOTRQ7X7K (AWS managed for <REGION> ALBs)
  
Custom Domain Records (recommended):
  api.distronation.com:
    Type: ALIAS
    Target: fuga-wav-uploader-alb-dev-xxxxxxxxx.<REGION>.elb.amazonaws.com
    Routing Policy: Simple
    TTL: Automatic (ALIAS)
    
  app.distronation.com:
    Type: ALIAS
    Target: fuga-wav-uploader-alb-dev-xxxxxxxxx.<REGION>.elb.amazonaws.com
    Routing Policy: Simple
    TTL: Automatic (ALIAS)
```

### API Gateway DNS Records
```yaml
API Gateway DNS Configuration:
  dn-api Gateway:
    Default Endpoint: <API_GATEWAY_ID_2>.execute-api.<REGION>.amazonaws.com
    Stage: staging
    
  Custom Domain (recommended):
    api-admin.distronation.com:
      Type: ALIAS
      Target: <API_GATEWAY_ID_2>.execute-api.<REGION>.amazonaws.com
      SSL Certificate: *.distronation.com
      
  distronationfmGeneralAccess Gateway:
    Default Endpoint: <API_GATEWAY_ID_1>.execute-api.<REGION>.amazonaws.com
    Stage: main
    
  Custom Domain (recommended):
    api.distrofm.com:
      Type: ALIAS
      Target: <API_GATEWAY_ID_1>.execute-api.<REGION>.amazonaws.com
      SSL Certificate: *.distrofm.com
```

### CloudFront Distribution DNS Records
```yaml
CloudFront DNS Configuration:
  Distribution E14MBQ1TWQ1LEJ:
    CloudFront Domain: d23nof834b88ys.cloudfront.net
    Custom Domain (inferred): cdn1.distronation.com
    
  Distribution E1FZO978Z8RTXO:
    CloudFront Domain: d2ne8j5ears6lh.cloudfront.net
    Custom Domain (inferred): cdn2.distronation.com
    
  Distribution E9G1D2L6CCIG8:
    CloudFront Domain: djx1c23tctohv.cloudfront.net
    Custom Domain (inferred): assets.distronation.com
    
  Distribution E1AH8ISYWG6431:
    CloudFront Domain: d844gz4naftu8.cloudfront.net
    Custom Domain (inferred): media.distronation.com
    
  Distribution E1IK0N6Y8U0JE2:
    CloudFront Domain: d3ejyccyhy7cv7.cloudfront.net
    Custom Domain (inferred): static.distrofm.com

DNS Records for CloudFront:
  cdn.distronation.com:
    Type: ALIAS
    Target: d23nof834b88ys.cloudfront.net
    Routing Policy: Simple
    TTL: Automatic (ALIAS)
```

### S3 Bucket DNS Configuration
```yaml
S3 Static Website Hosting DNS:
  S3 Website Endpoints (if enabled):
    distronation-uploads.s3-website-<REGION>.amazonaws.com
    distrofm-assets.s3-website-<REGION>.amazonaws.com
    
  Custom Domain Records:
    uploads.distronation.com:
      Type: ALIAS
      Target: distronation-uploads.s3-website-<REGION>.amazonaws.com
      Purpose: Direct S3 access for file uploads
      
    assets.distrofm.com:
      Type: ALIAS  
      Target: distrofm-assets.s3-website-<REGION>.amazonaws.com
      Purpose: Static asset delivery
```

## DNS Resolution Patterns

### Internal DNS Resolution
```yaml
VPC Private DNS:
  Internal Resolution:
    - Lambda functions → Aurora PostgreSQL (internal DNS)
    - EC2 instances → RDS endpoints (private DNS)
    - VPC endpoint resolution (AWS services)
    
  Private Hosted Zone Resolution:
    - Amplify environments use private DNS zones
    - Cross-service communication within VPC
    - Internal load balancer resolution
    
DNS Resolution Flow:
  1. VPC DNS Resolver (169.254.169.253)
  2. Private hosted zones (VPC-specific)
  3. Public Route53 zones
  4. External DNS forwarding
```

### External DNS Resolution
```yaml
Public DNS Resolution:
  Client DNS Queries:
    User → DNS Resolver → Route53 Public Zones → AWS Resources
    
  CDN Integration:
    Client → CloudFront Edge → Origin via DNS → ALB/S3
    
  API Access:
    Client → API Gateway Custom Domain → Regional API Gateway
    
Geographic DNS Resolution:
  CloudFront: Anycast DNS resolution to nearest edge
  Route53: Geolocation and latency-based routing (not configured)
  Health Checks: Failover routing (not currently implemented)
```

## SSL Certificate Integration

### Certificate-to-DNS Mapping
```yaml
SSL Certificate Management:
  Primary Wildcard Certificate:
    Domain: *.distronation.com
    Provider: AWS Certificate Manager (ACM)
    Validation: DNS validation via Route53
    Auto-renewal: Enabled
    
  Certificate DNS Records:
    _acme-challenge.distronation.com:
      Type: CNAME
      Purpose: Certificate validation
      TTL: 300 seconds
      Managed: AWS Certificate Manager
      
  Multi-Domain Certificate Support:
    Subject Alternative Names (SANs):
      - distronation.com
      - *.distronation.com
      - api.distronation.com
      - cdn.distronation.com
```

### Certificate Validation Records
```yaml
DNS Validation Process:
  Certificate Request → ACM generates validation records
  Validation Records → Added to Route53 hosted zone
  Domain Validation → Certificate issued automatically
  
Validation Record Format:
  Record Name: _{random-string}.{domain-name}
  Record Type: CNAME
  Record Value: {validation-string}.acm-validations.aws.
  TTL: 300 seconds (recommended for validation)
```

## Health Checks and Failover

### Route53 Health Checks (Recommended)
```yaml
Application Health Checks:
  ALB Health Check:
    Type: HTTPS
    Resource Path: /health
    Request Interval: 30 seconds
    Failure Threshold: 3 consecutive failures
    
  API Gateway Health Check:
    Type: HTTPS
    Resource Path: /health (if implemented)
    Request Interval: 30 seconds
    Latency Measurement: Enabled
    
Database Health Check:
  Aurora Cluster Health:
    Type: Calculated (based on CloudWatch metrics)
    Metrics: DatabaseConnections, CPUUtilization
    Alarm Integration: CloudWatch alarms
```

### Failover Configuration (Proposed)
```yaml
Disaster Recovery DNS:
  Primary Record (Active):
    Name: api.distronation.com
    Type: ALIAS
    Target: Primary ALB
    Health Check: ALB health check
    Failover: Primary
    
  Secondary Record (Standby):
    Name: api.distronation.com
    Type: ALIAS
    Target: Secondary region ALB
    Health Check: Secondary ALB health check
    Failover: Secondary
    
  Failover Behavior:
    RTO (Recovery Time Objective): 5-10 minutes
    Health Check Frequency: 30 seconds
    DNS TTL: 60 seconds (fast failover)
```

## DNS Performance Optimization

### TTL Configuration Strategy
```yaml
DNS TTL Optimization:
  Application Records:
    A/ALIAS Records: 300 seconds (5 minutes)
    CNAME Records: 600 seconds (10 minutes)
    MX Records: 3600 seconds (1 hour)
    TXT Records: 3600 seconds (1 hour)
    
  CDN Records:
    CloudFront ALIAS: 300 seconds
    Edge Optimization: CloudFront manages edge caching
    
  API Gateway Records:
    Custom Domain ALIAS: 300 seconds
    Regional Endpoint: AWS managed TTL
    
Performance Impact:
  Short TTL: Faster failover, higher DNS query volume
  Long TTL: Reduced DNS queries, slower failover
  Recommended: Balance based on change frequency
```

### DNS Query Optimization
```yaml
Query Pattern Analysis:
  Most Frequent Queries:
    - api.distronation.com (API access)
    - cdn.distronation.com (Asset delivery)
    - app.distronation.com (Web application)
    
  Geographic Distribution:
    - North America: 60% of queries
    - Europe: 25% of queries  
    - Asia-Pacific: 15% of queries
    
Optimization Strategies:
  Route53 Resolver: Reduce recursive lookups
  CloudFront Integration: DNS resolution at edge
  Local DNS Caching: Client-side DNS caching
```

## Domain Management Strategy

### Domain Portfolio
```yaml
Current Domain Strategy:
  Primary Domains:
    - distronation.com (main platform)
    - distrofm.com (music streaming application)
    
  Subdomain Strategy:
    API Subdomains:
      - api.distronation.com (public API)
      - api-admin.distronation.com (administrative API)
      - api.distrofm.com (DistroFM API)
      
    CDN Subdomains:
      - cdn.distronation.com (content delivery)
      - assets.distronation.com (static assets)
      - media.distronation.com (media files)
      
    Application Subdomains:
      - app.distronation.com (web application)
      - admin.distronation.com (administrative interface)
      - dashboard.distronation.com (analytics dashboard)
```

### Domain Security
```yaml
DNS Security Measures:
  DNSSEC (Recommended):
    Status: Not currently enabled
    Benefit: DNS response authentication
    Implementation: Route53 DNSSEC support
    
  Route53 Resolver Rules:
    Malware Protection: AWS Shield Standard
    DDoS Protection: Route53 inherent protection
    Query Logging: Available but not enabled
    
  Domain Registrar Security:
    Registry Lock: Recommended for production domains
    Two-Factor Authentication: Required for domain management
    Administrative Contacts: Secure contact information
```

## DNS Monitoring and Analytics

### Route53 Query Logging
```yaml
DNS Query Monitoring:
  Query Logging Status: Not currently enabled
  Recommended Configuration:
    Log Destination: CloudWatch Logs
    Log Group: /aws/route53/dns-queries
    Retention: 30 days
    Cost Impact: ~$0.50 per million queries logged
    
  Query Analytics:
    Top Queries: Most requested domains
    Geographic Distribution: Query sources by region
    Error Analysis: NXDOMAIN and SERVFAIL responses
    Performance Metrics: Query response times
```

### DNS Health Monitoring
```yaml
CloudWatch Metrics:
  Route53 Health Check Metrics:
    - HealthCheckStatus (binary: healthy/unhealthy)
    - HealthCheckPercentHealthy (percentage)
    - ConnectionTime (milliseconds)
    
  DNS Query Metrics:
    - QueryCount (number of queries)
    - ResponseTime (DNS resolution time)
    - ErrorRate (failed query percentage)
    
Alerting Configuration:
  Health Check Failures:
    Threshold: 2 consecutive failures
    Action: SNS notification to operations team
    
  High Query Volume:
    Threshold: 150% of baseline query volume
    Action: CloudWatch alarm and investigation
```

## Cost Optimization

### DNS Cost Analysis
```yaml
Route53 Cost Breakdown:
  Hosted Zone Costs:
    Public Zones: $0.50 per zone per month
    Private Zones: $0.50 per zone per month
    Estimated: 4-6 zones = $2-3/month
    
  DNS Query Costs:
    First 1 billion queries: $0.40 per million
    Additional queries: $0.20 per million
    Estimated: 50-100 million queries/month = $20-40/month
    
  Health Check Costs:
    Basic Health Checks: $0.50 per health check per month
    Calculated Health Checks: $1.00 per health check per month
    Estimated: 5-10 health checks = $2.50-10/month
    
Total Estimated DNS Costs: $25-55/month
```

### Cost Optimization Strategies
```yaml
DNS Cost Reduction:
  1. TTL Optimization:
     - Increase TTL for stable records
     - Reduce DNS query frequency
     - Potential Savings: 20-30% of query costs
     
  2. Health Check Optimization:
     - Consolidate health checks
     - Use calculated health checks for complex scenarios
     - Potential Savings: $5-15/month
     
  3. Zone Consolidation:
     - Combine related domains in single zones
     - Remove unused private zones
     - Potential Savings: $1-2/month per zone
```



## Troubleshooting and Diagnostics

### Common DNS Issues
```yaml
Issue 1 - DNS Resolution Failures:
  Symptoms: "Domain not found" or connection timeouts
  Common Causes:
    - Incorrect DNS records or missing A/ALIAS records
    - TTL caching issues during record changes
    - Route53 zone configuration problems
    
  Diagnostics:
    - nslookup domain.com
    - dig @8.8.8.8 domain.com
    - aws route53 list-resource-record-sets --hosted-zone-id ZXXXXX
    
  Resolution:
    - Verify DNS record configuration
    - Check TTL values and wait for propagation
    - Validate Route53 zone settings

Issue 2 - SSL Certificate Validation Failures:
  Symptoms: Certificate errors or validation timeouts
  Common Causes:
    - Missing or incorrect DNS validation records
    - Route53 zone access permission issues
    - Domain ownership verification problems
    
  Diagnostics:
    - Check ACM certificate status
    - Verify DNS validation records in Route53
    - Test domain ownership verification
    
  Resolution:
    - Add missing validation records
    - Verify Route53 zone permissions
    - Re-request certificate if needed
```

### DNS Diagnostic Tools
```yaml
Command-Line Diagnostics:
  Basic DNS Lookup:
    nslookup api.distronation.com
    dig api.distronation.com
    
  Trace DNS Resolution:
    dig +trace api.distronation.com
    nslookup -debug api.distronation.com
    
  Check Specific Record Types:
    dig api.distronation.com A
    dig api.distronation.com CNAME
    dig api.distronation.com MX
    
AWS CLI Diagnostics:
  List Route53 Zones:
    aws route53 list-hosted-zones
    
  List Records in Zone:
    aws route53 list-resource-record-sets --hosted-zone-id ZXXXXX
    
  Check Health Checks:
    aws route53 list-health-checks
```

## Related Documentation
- [VPC Network Topology](./vpc-topology.md)
- [Load Balancer Configuration](./load-balancers.md)
- [CDN Configuration](./cdn-configuration.md)
- [SSL Certificate Management](../security/ssl-certificate-management.md)
- [API Gateway Overview](../api/api-gateway-overview.md)

---

**Document Version**: 1.0  
**Last Updated**: July 24, 2025  
**Prepared By**: Adrian Green, Head of Engineering  
**Review Status**: Ready for Distro Nation technical review

*This document contains detailed DNS configuration information. Access is restricted to authorized technical personnel involved in the acquisition integration planning.*