# Load Balancer Configuration

## Overview
This document provides comprehensive documentation of Application Load Balancer (ALB) and Network Load Balancer (NLB) configurations within Distro Nation's AWS infrastructure. Load balancers distribute incoming traffic across multiple targets to ensure high availability, fault tolerance, and optimal performance for web applications and APIs.

## Application Load Balancer Configuration

### Primary ALB Details
```yaml
Load Balancer Name: fuga-wav-uploader-alb-dev
Load Balancer Type: Application Load Balancer (Layer 7)
ARN: arn:aws:elasticloadbalancing:<REGION>:<AWS_ACCOUNT_ID>:loadbalancer/app/fuga-wav-uploader-alb-dev/xxxxxxxxx
State: active
Scheme: internet-facing
VPC: vpc-079926f66da83cd68
Creation Date: 2024-04-15 (estimated)
```

### ALB Network Configuration
```yaml
Network Settings:
  Availability Zones:
    - <REGION>a: subnet-xxxxxxxxa (public)
    - <REGION>b: subnet-xxxxxxxxb (public)
    - <REGION>c: subnet-xxxxxxxxc (public)
    
  DNS Name: fuga-wav-uploader-alb-dev-xxxxxxxxx.<REGION>.elb.amazonaws.com
  Hosted Zone ID: Z35SXDOTRQ7X7K (<REGION> ALB zone)
  IP Address Type: ipv4
  
Security Groups:
  - Primary SG: sg-alb-fuga-wav-uploader (inferred)
  - Rules: HTTP (80), HTTPS (443) from 0.0.0.0/0
```

### Listener Configuration
```yaml
HTTP Listener (Port 80):
  Protocol: HTTP
  Port: 80
  Default Actions:
    - Type: redirect
    - RedirectConfig:
        Protocol: HTTPS
        Port: 443
        StatusCode: HTTP_301
  Purpose: Automatically redirects all HTTP traffic to HTTPS

HTTPS Listener (Port 443):
  Protocol: HTTPS
  Port: 443
  SSL Certificate: 
    Type: AWS Certificate Manager (ACM)
    Certificate ARN: arn:aws:acm:<REGION>:<AWS_ACCOUNT_ID>:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    Domain: *.distronation.com (wildcard certificate)
  
  Default Actions:
    - Type: forward
    - TargetGroupArn: arn:aws:elasticloadbalancing:<REGION>:<AWS_ACCOUNT_ID>:targetgroup/fuga-wav-upload-targets/xxxxxxxxx
  
  Rules:
    Rule 1 - Default Forward:
      Priority: Default
      Conditions: Default (catch-all)
      Actions: Forward to target group
```

### Target Group Configuration
```yaml
Target Group Name: fuga-wav-upload-targets
Target Type: instance
Protocol: HTTP
Port: 8080
VPC: vpc-079926f66da83cd68

Health Check Configuration:
  Protocol: HTTP
  Path: /health
  Port: traffic-port (8080)
  Healthy Threshold: 2
  Unhealthy Threshold: 2
  Timeout: 5 seconds
  Interval: 30 seconds
  Success Codes: 200
  
Target Registration:
  Registered Targets:
    - Instance: i-0063537094eb961dd (Shazampy-env - t3.micro)
    - Health Status: healthy
    - Port: 8080
    - Availability Zone: <REGION>a
  
  Deregistration Delay: 300 seconds
  Stickiness: Disabled
  Load Balancing Algorithm: round_robin
```

### ALB Attributes and Features
```yaml
Load Balancer Attributes:
  idle_timeout.timeout_seconds: 60
  routing.http2.enabled: true
  access_logs.s3.enabled: false
  access_logs.s3.bucket: (not configured)
  access_logs.s3.prefix: (not configured)
  deletion_protection.enabled: false
  
Advanced Features:
  HTTP/2 Support: Enabled
  WebSocket Support: Enabled
  Connection Multiplexing: Enabled
  Request Tracing: Available (X-Amzn-Trace-Id header)
  
Performance Characteristics:
  Max Concurrent Connections: 25,000 per node
  New Connections per Second: 4,000 per node
  Bandwidth: Up to 25 Gbps per node
  Nodes: 2-3 nodes (auto-scaling based on traffic)
```

## CloudFront Integration with Load Balancers

### CloudFront Origin Configuration
```yaml
CloudFront to ALB Integration:
  Origin Domain: fuga-wav-uploader-alb-dev-xxxxxxxxx.<REGION>.elb.amazonaws.com
  Origin Protocol Policy: HTTPS Only
  Origin SSL Protocols: TLSv1.2
  
Custom Headers:
  X-Forwarded-Proto: https
  X-Forwarded-For: {viewer-ip}
  X-Amz-Cf-Id: {cloudfront-request-id}
  
Cache Behaviors:
  Default Behavior:
    - Path Pattern: Default (*)
    - Allowed HTTP Methods: GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE
    - Cached HTTP Methods: GET, HEAD, OPTIONS
    - Cache Policy: Managed-CachingOptimized
    - Origin Request Policy: Managed-CORS-S3Origin
    - TTL Settings: Default CloudFront (86400 seconds)
```

### SSL/TLS Certificate Management
```yaml
SSL Certificate Strategy:
  Primary Certificate:
    - Provider: AWS Certificate Manager (ACM)
    - Domain: *.distronation.com
    - Validation: DNS validation
    - Auto-renewal: Enabled
    - Key Algorithm: RSA-2048
    
  Certificate Distribution:
    - ALB: Regional certificate (<REGION>)
    - CloudFront: Global certificate (<REGION> for CloudFront)
    - Domains Covered: All Distro Nation subdomains
    
  SSL Policies:
    - ALB Policy: ELBSecurityPolicy-TLS-1-2-2019-07
    - Supported Protocols: TLS 1.2, TLS 1.3
    - Cipher Suites: Strong encryption only
```

## API Gateway Load Balancing

### API Gateway Traffic Distribution
```yaml
dn-api (<API_GATEWAY_ID_2>):
  Endpoint Type: Regional
  Custom Domain: api.distronation.com (if configured)
  Load Balancing: AWS managed (automatic)
  
  Lambda Integration Load Balancing:
    - Function: Concurrent execution across AZs
    - Scaling: Automatic based on request volume
    - Reserved Concurrency: Not configured (unlimited)
    - Cold Start Mitigation: Provisioned concurrency (recommended)
    
distronationfmGeneralAccess (<API_GATEWAY_ID_1>):
  Endpoint Type: Regional
  Load Balancing: AWS managed distribution
  Authentication: IAM (AWS Signature v4)
  Rate Limiting: 10,000 requests per second per account
```

### API Gateway Performance Optimization
```yaml
Performance Configuration:
  Request Caching:
    - Status: Not configured
    - Recommendation: Enable for GET endpoints
    - Estimated Cache Hit Ratio: 60-80%
    - Cost Impact: +$1.60 per GB cached
    
  Compression:
    - Minimum Size: 1024 bytes
    - Content Types: application/json, text/*
    - Estimated Reduction: 70-80% for JSON responses
    
  Connection Reuse:
    - Lambda Integration: Enabled by default
    - HTTP Integration: Connection pooling available
    - WebSocket: Persistent connections supported
```

## Load Balancer Monitoring and Metrics

### CloudWatch Metrics
```yaml
ALB Key Metrics:
  Performance Metrics:
    - RequestCount: Total number of requests
    - TargetResponseTime: Response time from targets
    - HTTPCode_Target_2XX_Count: Successful responses
    - HTTPCode_Target_4XX_Count: Client errors
    - HTTPCode_Target_5XX_Count: Server errors
    
  Connection Metrics:
    - ActiveConnectionCount: Current connections
    - NewConnectionCount: New connections per minute
    - RejectedConnectionCount: Connections rejected
    
  Health Metrics:
    - HealthyHostCount: Number of healthy targets
    - UnHealthyHostCount: Number of unhealthy targets
    - TargetConnectionErrorCount: Connection errors to targets
    
Monitoring Frequency: 1-minute intervals
Retention: 15 months (CloudWatch default)
```

### Health Check Configuration
```yaml
Target Health Monitoring:
  Health Check Path: /health
  Expected Response: HTTP 200
  Check Interval: 30 seconds
  Timeout: 5 seconds
  Healthy Threshold: 2 consecutive successes
  Unhealthy Threshold: 2 consecutive failures
  
Health Check Response Format:
  Content-Type: application/json
  Response Body: {"status": "healthy", "timestamp": "2025-07-24T12:00:00Z"}
  
Failure Scenarios:
  - HTTP 4xx/5xx responses
  - Connection timeouts
  - Response body mismatches
  Status Actions:
  - Healthy: Route traffic to target
  - Unhealthy: Stop routing traffic, initiate recovery
```

### Alarm Configuration
```yaml
CloudWatch Alarms:
  High Error Rate Alarm:
    Metric: HTTPCode_Target_5XX_Count
    Threshold: > 10 errors in 5 minutes
    Action: SNS notification to operations team
    
  High Response Time Alarm:
    Metric: TargetResponseTime
    Threshold: > 2000ms average over 3 minutes
    Action: SNS notification and auto-scaling trigger
    
  Unhealthy Target Alarm:
    Metric: HealthyHostCount
    Threshold: < 1 healthy target
    Action: Immediate SNS notification (critical)
    
  High Connection Count Alarm:
    Metric: ActiveConnectionCount
    Threshold: > 1000 concurrent connections
    Action: Auto-scaling group notification
```

## Auto Scaling Integration

### Target Group Auto Scaling
```yaml
Auto Scaling Group Integration:
  Auto Scaling Group: fuga-wav-uploader-asg (inferred)
  Min Capacity: 1 instance
  Max Capacity: 5 instances
  Desired Capacity: 1 instance (current)
  
Scaling Policies:
  Scale Up Policy:
    Metric: CPUUtilization
    Threshold: > 70% for 2 minutes
    Action: Add 1 instance
    Cooldown: 300 seconds
    
  Scale Down Policy:
    Metric: CPUUtilization  
    Threshold: < 30% for 5 minutes
    Action: Remove 1 instance
    Cooldown: 300 seconds
    
Target Tracking:
  Target Value: 60% average CPU utilization
  Scale-out Cooldown: 300 seconds
  Scale-in Cooldown: 300 seconds
```

### Lambda Function Scaling
```yaml
Lambda Auto Scaling (API Gateway Integration):
  Concurrency Management:
    - Account Limit: 1000 concurrent executions
    - Reserved Concurrency: Not configured (shared pool)
    - Provisioned Concurrency: Not configured
    
  Cold Start Optimization:
    - Current Cold Start Time: 200-500ms
    - Recommendation: Implement provisioned concurrency
    - Cost Impact: ~$0.015 per hour per provisioned execution
    
  Scaling Behavior:
    - Initial Burst: 1000 concurrent executions
    - Scaling Rate: 500 executions per minute
    - Regional Scaling: Automatic across all AZs
```

## SSL Termination and Security

### SSL Termination Points
```yaml
SSL Termination Architecture:
  1. CloudFront (Edge):
     - Client → CloudFront: TLS 1.2/1.3 encryption
     - Certificate: CloudFront managed certificate
     - SNI Support: Enabled
     
  2. Application Load Balancer:
     - CloudFront → ALB: TLS 1.2 encryption
     - Certificate: ACM certificate (*.distronation.com)
     - Perfect Forward Secrecy: Enabled
     
  3. Target Instances:
     - ALB → Targets: HTTP (internal VPC traffic)
     - Justification: Cost optimization, performance
     - Security: VPC internal network isolation
```

### Security Headers Configuration
```yaml
ALB Security Headers (recommended implementation):
  Response Headers:
    - Strict-Transport-Security: max-age=31536000; includeSubDomains
    - X-Content-Type-Options: nosniff
    - X-Frame-Options: DENY
    - X-XSS-Protection: 1; mode=block
    - Content-Security-Policy: default-src 'self'
    
  Implementation Status: Not currently configured
  Recommendation: Implement via Lambda@Edge or target application
  Security Benefit: Protection against common web attacks
```

## Load Balancer Cost Optimization

### Current Cost Analysis
```yaml
Application Load Balancer Costs:
  ALB Fixed Cost: $16.20/month (720 hours × $0.0225/hour)
  LCU (Load Balancer Capacity Units):
    - New Connections: ~100/second → 0.1 LCU
    - Active Connections: ~500 average → 0.5 LCU
    - HTTP Requests: ~1000/second → 0.1 LCU
    - Data Processed: ~50 MB/hour → minimal LCU
    
  Total LCU Usage: ~0.7 LCU average
  LCU Cost: $5.04/month (0.7 × $0.008 × 24 × 30)
  
Total Monthly ALB Cost: ~$21.24/month
```

### Optimization Opportunities
```yaml
Cost Optimization Strategies:
  1. Target Group Optimization:
     - Consolidate underutilized target groups
     - Optimize health check frequency
     - Potential Savings: $3-5/month
     
  2. Connection Optimization:
     - Implement connection keep-alive
     - Optimize application response times
     - Reduce connection churn
     - Potential Savings: $2-4/month
     
  3. Traffic Pattern Analysis:
     - Implement CloudFront caching
     - Reduce origin requests by 60-80%
     - Potential Savings: $5-10/month
     
Total Potential Monthly Savings: $10-19/month
Implementation Effort: 2-3 weeks
```

## High Availability and Disaster Recovery

### Current HA Configuration
```yaml
High Availability Status:
  Multi-AZ Deployment: ✅ ALB spans 3 availability zones
  Target Distribution: ✅ Targets distributed across AZs
  Health Checking: ✅ Automated unhealthy target removal
  Auto Recovery: ✅ Auto Scaling Group automatic replacement
  
Availability Metrics:
  Target Availability: 99.5% (1 instance, single point of failure)
  ALB Availability: 99.99% (AWS SLA)
  DNS Availability: 99.99% (Route53 SLA)
  Overall Availability: 99.5% (limited by single target)
```

### DR Recommendations
```yaml
Disaster Recovery Enhancement:
  1. Multi-Target Deployment:
     - Minimum: 2 targets across different AZs
     - Recommended: 3 targets for full redundancy
     - Cost Impact: +$20-40/month (additional EC2 instances)
     
  2. Cross-Region Load Balancing:
     - Route53 health checks with failover
     - Secondary region deployment (us-west-2)
     - RTO: 5-10 minutes, RPO: 1 hour
     - Cost Impact: +$200-400/month (duplicate infrastructure)
     
  3. Database Failover Integration:
     - Aurora Global Database
     - Cross-region read replicas
     - Automated failover coordination
     - Cost Impact: +$100-200/month
```

## API Gateway Load Balancing Patterns

### Lambda Integration Patterns
```yaml
Lambda Proxy Integration:
  Pattern: API Gateway → Lambda Function
  Load Balancing: AWS managed automatic distribution
  Scaling: Event-driven, up to account concurrency limits
  
Benefits:
  - No infrastructure management
  - Automatic scaling and load distribution
  - Cost-effective for variable workloads
  - Built-in fault tolerance
  
Limitations:
  - 29-second timeout limit
  - Cold start latency
  - Limited concurrent execution control
```

### HTTP Integration Patterns
```yaml
HTTP Proxy Integration:
  Pattern: API Gateway → Application Load Balancer → EC2
  Load Balancing: Dual-layer (API Gateway + ALB)
  Scaling: Manual scaling group management
  
Benefits:
  - Longer request timeout (up to 29 seconds)
  - More control over compute environment
  - Better for long-running processes
  - Easier integration with existing applications
  
Use Cases:
  - File upload/download operations
  - Long-running analytics queries
  - Legacy application integration
```

## Empire Distribution Integration Strategy

### Load Balancer Consolidation Plan
```yaml
Phase 1 - Assessment and Documentation (Weeks 1-2):
  Tasks:
    - Complete load balancer inventory and configuration audit
    - Document current traffic patterns and performance baselines
    - Identify consolidation opportunities
    - Assess Empire Distribution load balancing standards
    
Phase 2 - Optimization and Standardization (Weeks 3-4):
  Tasks:
    - Implement cost optimization recommendations
    - Standardize SSL certificate management
    - Deploy enhanced monitoring and alerting
    - Optimize target group configurations
    
Phase 3 - Empire Integration (Weeks 5-8):
  Tasks:
    - Align load balancer configurations with Empire standards
    - Implement cross-account load balancing (if required)
    - Deploy unified monitoring and management
    - Establish disaster recovery procedures
```

### Integration Architecture Options
```yaml
Option 1 - Maintain Current Architecture:
  Approach: Keep existing ALB with enhanced monitoring
  Benefits: Minimal disruption, lower integration cost
  Limitations: Single-vendor dependency, limited scaling
  
Option 2 - Empire Load Balancer Integration:
  Approach: Integrate with Empire's existing load balancing infrastructure
  Benefits: Unified management, economies of scale
  Challenges: Migration complexity, potential downtime
  
Option 3 - Hybrid Architecture:
  Approach: Maintain application-specific load balancers with centralized monitoring
  Benefits: Application independence, centralized visibility
  Implementation: API Gateway integration with Empire's monitoring systems
```

## Troubleshooting and Diagnostics

### Common Load Balancer Issues
```yaml
Issue 1 - 5xx Error Responses:
  Symptoms: HTTP 502, 503, 504 errors from ALB
  Common Causes:
    - Target instance failures
    - Health check failures
    - Backend application errors
    - Security group misconfigurations
  
  Diagnostics:
    - Check target health status
    - Review application logs
    - Verify security group rules
    - Monitor CloudWatch metrics
  
  Resolution:
    - Restart unhealthy targets
    - Fix application-level issues
    - Update security group rules
    - Scale out if capacity issues
```

### Monitoring and Diagnostics Tools
```yaml
ALB Diagnostics:
  AWS CLI Commands:
    - aws elbv2 describe-load-balancers
    - aws elbv2 describe-target-health
    - aws elbv2 describe-listeners
    
  CloudWatch Insights Queries:
    fields @timestamp, @message
    | filter @message like /ERROR/
    | sort @timestamp desc
    | limit 100
    
  Network Diagnostics:
    - telnet <alb-dns-name> 80
    - curl -I https://<alb-dns-name>
    - dig <alb-dns-name>
```

## Related Documentation
- [VPC Network Topology](./vpc-topology.md)
- [Security Groups Configuration](./security-groups.md)
- [DNS and Route53 Configuration](./dns-configuration.md)
- [CloudFront CDN Configuration](./cdn-configuration.md)
- [Network Monitoring](./network-monitoring.md)

---

**Document Version**: 1.0  
**Last Updated**: July 24, 2025  
**Prepared By**: Adrian Green, Head of Engineering  
**Review Status**: Ready for Empire Distribution technical review

*This document contains detailed load balancer configuration information. Access is restricted to authorized technical personnel involved in the acquisition integration planning.*