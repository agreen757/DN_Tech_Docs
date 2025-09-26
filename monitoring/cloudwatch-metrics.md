# CloudWatch Metrics and Monitoring Infrastructure

## Overview
This document provides comprehensive documentation of Amazon CloudWatch metrics, custom metrics, dashboards, and monitoring infrastructure for Distro Nation's AWS environment. CloudWatch serves as the primary observability platform, collecting and analyzing performance data across all AWS services and applications.

## CloudWatch Metrics Overview

### Current Metrics Summary
```yaml
CloudWatch Metrics Inventory:
  Account ID: <AWS_ACCOUNT_ID>
  Region: <REGION> (primary)
  Monthly Cost: $8.12 (27.068 custom metrics)
  Metric Retention: 15 months (CloudWatch default)
  Data Points: High-resolution metrics (1-minute intervals)
  
Metric Categories:
  AWS Service Metrics: 200+ standard metrics (free)
  Custom Metrics: 27+ application-specific metrics
  Log-derived Metrics: Filter-based metrics from application logs
  External API Metrics: Rate limiting and response time tracking
```

## AWS Service Metrics

### API Gateway Metrics
```yaml
dn-api Gateway (<API_GATEWAY_ID_2>):
  Request Metrics:
    - Count: Total number of API requests
    - IntegrationLatency: Backend service response time
    - Latency: Complete end-to-end request latency
    - CacheHitCount: API Gateway cache performance
    - CacheMissCount: Cache miss frequency
    
  Error Metrics:
    - 4XXError: Client error responses (authentication, validation)
    - 5XXError: Server error responses (backend failures)
    - DataProcessed: Total data transferred through API
    
  Threshold Baselines:
    - Average Latency: <500ms (current baseline)
    - Target Latency: <300ms (performance goal)
    - Error Rate: <5% (alert threshold)
    - Cache Hit Rate: >60% (cost optimization target)

distronationfmGeneralAccess Gateway (<API_GATEWAY_ID_1>):
  Request Metrics:
    - Count: DistroFM-specific API request volume
    - IntegrationLatency: Lambda function response times
    - Latency: End-to-end DistroFM API performance
    - Throttles: Rate limiting activations
    
  Performance Characteristics:
    - Rate Limit: 10,000 requests/second
    - Burst Limit: 5,000 requests
    - Average Response Time: <400ms
    - Peak Usage: 1,000-5,000 requests/hour
```

### Lambda Function Metrics
```yaml
Core Lambda Metrics (84+ Functions):
  Performance Metrics:
    - Duration: Function execution time
    - Throttles: Concurrent execution limit hits
    - IteratorAge: Event processing lag (for stream-based functions)
    - ConcurrentExecutions: Current function instances running
    
  Reliability Metrics:
    - Errors: Function execution failures
    - DeadLetterErrors: Failed message processing
    - DestinationDeliveryFailures: Async invocation failures
    
  Cost Metrics:
    - Invocations: Total function invocation count
    - PostRuntimeExtensionsReady: Cold start optimization metric
    
Key Function Performance:
  POSTGRESQL_LAMBDA:
    - Average Duration: 250ms
    - Error Rate: <1%
    - Concurrency: 5-15 concurrent executions
    - Memory Usage: 512MB allocated
    
  DN_Send_Mail:
    - Average Duration: 800ms
    - Error Rate: <2%
    - Throttling: Minimal (email rate limiting managed externally)
    
  dn_spotify_analytics:
    - Average Duration: 2,500ms
    - Error Rate: <5% (external API dependency)
    - Schedule: CloudWatch Events (hourly/daily)
    
  YouTube_API_Token:
    - Average Duration: 300ms
    - Error Rate: <3%
    - Rate Limiting: Managed at application level
```

### Aurora PostgreSQL Metrics
```yaml
Database Performance Metrics:
  Database Identifier: database-2-instance-1
  Engine: aurora-postgresql (serverless)
  
  Performance Insights Metrics:
    - DatabaseConnections: Current active connections
    - CPUUtilization: Database CPU usage percentage
    - ServerlessDatabaseCapacity: ACU (Aurora Capacity Units) usage
    - ReadLatency: Query execution response time
    - WriteLatency: Write operation response time
    
  Current Performance Baselines:
    - Average ACU Usage: 0.51 ACU
    - Connection Count: 5-25 concurrent connections
    - Query Response Time: <100ms (average)
    - CPU Utilization: <30% (typical)
    
  Serverless Scaling Metrics:
    - ScaleUpCount: Database scaling events
    - ScaleDownCount: Database downscaling events
    - ServerlessV2ScalingEnabled: Auto-scaling status
    - BackupRetentionPeriod: 7 days
```

### S3 Storage Metrics
```yaml
S3 Bucket Metrics (23+ Buckets):
  Storage Metrics:
    - BucketSizeBytes: Total storage consumption per bucket
    - NumberOfObjects: Object count per bucket
    - EncryptedObjectCount: Objects with server-side encryption
    
  Request Metrics:
    - AllRequests: Total API requests to S3
    - GetRequests: Object retrieval operations
    - PutRequests: Object upload operations
    - DeleteRequests: Object deletion operations
    
Key Bucket Performance:
  distronation-audio:
    - Storage: ~500GB (estimated)
    - Monthly Requests: 100,000-500,000
    - Transfer: 50-200GB/month
    
  distro-nation-upload:
    - Storage: ~200GB (estimated)  
    - Monthly Requests: 50,000-200,000
    - Transfer: 20-100GB/month
    
  distronationfm-profile-pictures:
    - Storage: ~10GB (estimated)
    - Monthly Requests: 10,000-50,000
    - Transfer: 5-25GB/month
```

### Application Load Balancer Metrics
```yaml
ALB Metrics (fuga-wav-uploader-alb-dev):
  Request Metrics:
    - RequestCount: Total requests processed
    - TargetResponseTime: Backend server response time
    - HTTPCode_Target_2XX_Count: Successful responses
    - HTTPCode_Target_4XX_Count: Client error responses
    - HTTPCode_Target_5XX_Count: Server error responses
    
  Connection Metrics:
    - ActiveConnectionCount: Current active connections
    - NewConnectionCount: New connections per minute
    - RejectedConnectionCount: Rejected connections
    - ClientTLSNegotiationErrorCount: SSL/TLS handshake failures
    
  Target Health Metrics:
    - HealthyHostCount: Number of healthy targets
    - UnHealthyHostCount: Number of unhealthy targets
    - TargetConnectionErrorCount: Backend connection failures
    
Performance Baselines:
  Average Response Time: <200ms
  Target Health: 1 healthy instance (current)
  Connection Rate: 10-100 new connections/minute
  Error Rate: <2% (5xx errors)
```

### CloudFront Distribution Metrics
```yaml
CloudFront Metrics (5 Distributions):
  Request Metrics:
    - Requests: Total requests to distribution
    - BytesDownloaded: Data transferred to viewers
    - BytesUploaded: Data uploaded by viewers
    
  Performance Metrics:
    - OriginLatency: Time to first byte from origin
    - CacheHitRate: Percentage of requests served from cache
    - 4xxErrorRate: Client error percentage
    - 5xxErrorRate: Server error percentage
    
Distribution Performance:
  E14MBQ1TWQ1LEJ (Primary Web):
    - Cache Hit Rate: 85-95%
    - Origin Latency: <200ms
    - Monthly Requests: 1-5 million
    
  E1FZO978Z8RTXO (API Content):
    - Cache Hit Rate: 20-40% (dynamic content)
    - Origin Latency: <300ms
    - Monthly Requests: 500K-2 million
    
  E9G1D2L6CCIG8 (Static Assets):
    - Cache Hit Rate: >95%
    - Origin Latency: <100ms
    - Monthly Requests: 2-10 million
```

## Custom Metrics

### Application-Level Custom Metrics
```yaml
Custom Metric Categories:
  Authentication Metrics:
    - api.authentication.success_rate
    - api.authentication.failure_count
    - api.authentication.token_refresh_rate
    
  Business Logic Metrics:
    - payout.processing.success_count
    - payout.processing.failure_count
    - payout.processing.amount_total
    
  External API Integration Metrics:
    - external_api.youtube.request_count
    - external_api.youtube.error_rate
    - external_api.spotify.rate_limit_hits
    - external_api.tiktok.response_time
    
  File Processing Metrics:
    - file.upload.success_count
    - file.upload.failure_count
    - file.processing.duration
    - file.validation.error_count

Custom Metric Implementation:
  Publishing Method: AWS SDK CloudWatch.putMetricData()
  Namespace: DistroNation/Application
  Dimensions: Environment, Service, Function
  Resolution: 1-minute standard resolution
  Cost: $0.30 per metric per month
```

### Rate Limiting Metrics
```yaml
API Rate Limiting Metrics:
  Three-Tier Rate Limiting:
    Tier 1 - Basic Rate Limiting:
      - api.rate_limit.tier1.requests_per_minute
      - api.rate_limit.tier1.throttled_requests
      
    Tier 2 - Burst Protection:
      - api.rate_limit.tier2.burst_requests
      - api.rate_limit.tier2.queue_depth
      
    Tier 3 - DDoS Protection:
      - api.rate_limit.tier3.blocked_ips
      - api.rate_limit.tier3.attack_patterns
      
External API Rate Limiting:
  YouTube API:
    - youtube.quota.daily_usage
    - youtube.quota.remaining
    - youtube.rate_limit.requests_per_second
    
  Spotify API:
    - spotify.quota.monthly_usage
    - spotify.rate_limit.requests_per_minute
    
  TikTok API:
    - tiktok.quota.daily_usage
    - tiktok.rate_limit.requests_per_hour
```

## Dashboard Configurations

### Executive Dashboard
```yaml
Dashboard: DistroNation-Executive-Overview
Widgets:
  System Health Overview:
    - API Gateway overall health status
    - Database connection health
    - External API availability
    - Error rate trending (7-day)
    
  Business Metrics:
    - Daily active users (if tracked)
    - File upload success rate
    - Payout processing volume
    - Revenue-impacting error rates
    
  Cost Monitoring:
    - Daily AWS spend trending
    - Lambda execution cost breakdown
    - S3 storage cost progression
    - Data transfer costs
    
Refresh Rate: 5 minutes
Access: Executive team, Head of Engineering
```

### Operations Dashboard
```yaml
Dashboard: DistroNation-Operations
Widgets:
  Real-Time System Status:
    - API response time (last 1 hour)
    - Lambda error rate (last 1 hour)
    - Database performance metrics
    - ALB target health status
    
  Infrastructure Performance:
    - EC2 instance health (Shazampy-env)
    - Aurora serverless scaling events
    - CloudFront cache performance
    - S3 request success rate
    
  Alerting Summary:
    - Active alarms count
    - Recent alarm state changes
    - Critical system alerts
    - Performance degradation indicators
    
Refresh Rate: 1 minute
Access: Engineering team, DevOps, Support
```

### Developer Dashboard
```yaml
Dashboard: DistroNation-Development
Widgets:
  API Performance:
    - Individual endpoint response times
    - Function-level Lambda metrics
    - Database query performance
    - External API response times
    
  Error Analysis:
    - Lambda function error breakdown
    - API Gateway 4xx/5xx analysis
    - Database connection failures
    - External API integration errors
    
  Deployment Metrics:
    - Build success/failure rates
    - Deployment frequency
    - Rollback incidents
    - Performance regression detection
    
Refresh Rate: 1 minute
Access: Development team, QA team
```

## Log-Derived Metrics

### Application Log Metrics
```yaml
Lambda Function Log Metrics:
  Error Pattern Metrics:
    - ERROR log level count
    - WARN log level count
    - Database connection error count
    - External API timeout count
    
  Performance Pattern Metrics:
    - Cold start duration
    - Database query execution time
    - External API response time
    - Memory usage patterns
    
  Business Logic Metrics:
    - User authentication events
    - File processing completion events
    - Payout calculation events
    - Error recovery events
    
Metric Filters:
  Database Error Filter:
    Filter Pattern: "ERROR" "database" "connection"
    Metric Name: DatabaseConnectionErrors
    Namespace: DistroNation/Database
    
  API Timeout Filter:
    Filter Pattern: "TIMEOUT" "external" "api"
    Metric Name: ExternalAPITimeouts
    Namespace: DistroNation/ExternalAPIs
```

### Security Log Metrics
```yaml
Security Event Metrics:
  Authentication Metrics:
    - Failed login attempts per IP
    - Successful authentication rate
    - Token expiration events
    - Suspicious authentication patterns
    
  Access Pattern Metrics:
    - API access by geographic region
    - Unusual request patterns
    - Rate limiting activations
    - Blocked request attempts
    
Implementation:
  Log Source: Lambda authorizer logs, API Gateway logs
  Processing: CloudWatch Logs Metric Filters
  Alerting: Security team notification on anomalies
  Retention: 90 days for security logs
```

## Metric Retention and Storage

### Retention Policies
```yaml
CloudWatch Metrics Retention:
  High-Resolution Metrics (1-minute): 15 days
  Standard Resolution (5-minute): 63 days
  1-Hour Resolution: 455 days (15 months)
  Daily Resolution: 15 months
  
Custom Metrics Retention:
  Business Metrics: 15 months (maximum)
  Operational Metrics: 15 months
  Security Metrics: 2 years (compliance requirement)
  Cost Metrics: 3 years (financial analysis)
  
Log Retention:
  Lambda Function Logs: 30 days (cost optimization)
  API Gateway Logs: 90 days
  Security Logs: 1 year
  Audit Logs: 7 years (compliance)
```

### Storage Optimization
```yaml
Metric Storage Strategy:
  High-Frequency Metrics: Critical system metrics (1-minute)
  Standard Metrics: Most application metrics (5-minute)
  Low-Frequency Metrics: Business intelligence metrics (1-hour)
  
Cost Optimization:
  Archive Strategy: Export to S3 for long-term analysis
  Metric Aggregation: Combine related metrics to reduce count
  Selective Monitoring: Monitor only critical metrics in development
  
Storage Costs:
  First 10,000 metrics: Free
  Additional metrics: $0.30 per metric per month
  Current cost: $8.12/month for 27 custom metrics
```

## Metric Access and Security

### IAM Permissions
```yaml
CloudWatch Access Roles:
  ReadOnlyAccess:
    Principal: Support team, external stakeholders
    Permissions: cloudwatch:GetMetricStatistics, cloudwatch:ListMetrics
    Resources: All metrics except sensitive business data
    
  OperationsAccess:
    Principal: Engineering team, DevOps
    Permissions: Full CloudWatch access except billing metrics
    Resources: All operational and performance metrics
    
  AdminAccess:
    Principal: Head of Engineering, System Administrators
    Permissions: Full CloudWatch access including configuration
    Resources: All metrics, dashboards, and alarms
    
Cross-Account Access:
  Implementation: Cross-account IAM roles with metric-specific permissions
  Security: Resource-based policies for sensitive business metrics
```

## Cost Analysis and Optimization

### Current CloudWatch Costs
```yaml
Monthly CloudWatch Costs:
  Custom Metrics: $8.12/month (27.068 metrics)
  API Requests: Minimal (included in free tier)
  Dashboard Usage: Free (within limits)
  Log Storage: ~$5-10/month (estimated)
  
Total Monthly Cost: ~$15-20/month

Cost Breakdown by Service:
  Lambda Metrics: ~40% of custom metric costs
  API Gateway Metrics: ~25% of custom metric costs
  Application Metrics: ~25% of custom metric costs
  Security Metrics: ~10% of custom metric costs
```

### Cost Optimization Opportunities
```yaml
Optimization Strategies:
  1. Metric Consolidation:
     - Combine related metrics using dimensions
     - Reduce duplicate metrics across environments
     - Potential Savings: 20-30% of metric costs
     
  2. Retention Optimization:
     - Adjust retention based on metric importance
     - Archive historical data to S3
     - Potential Savings: 15-25% of storage costs
     
  3. Selective Monitoring:
     - Monitor only critical metrics in development
     - Use conditional metric publishing
     - Potential Savings: 10-20% of total costs
     
  4. Dashboard Optimization:
     - Reduce widget refresh frequency for non-critical dashboards
     - Optimize query time ranges
     - Potential Savings: 5-10% of API request costs
```



## Related Documentation
- [Alerting Configuration](./alerting-configuration.md)
- [Performance Baselines](./performance-baselines.md)
- [Dashboard Configurations](./dashboard-configurations.md)
- [Logging Strategy](./logging-strategy.md)
- [AWS Infrastructure Inventory](../architecture/aws-infrastructure-inventory.md)

---

**Document Version**: 1.0  
**Last Updated**: July 24, 2025  
**Prepared By**: Adrian Green, Head of Engineering  
**Review Status**: Current

*This document contains detailed monitoring metric information. Access is restricted to authorized technical personnel.*