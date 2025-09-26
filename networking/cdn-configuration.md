# CloudFront CDN Configuration

## Overview
This document provides comprehensive documentation of Amazon CloudFront Content Delivery Network (CDN) configurations for Distro Nation's infrastructure. CloudFront serves as the primary content delivery mechanism, providing global edge caching, SSL termination, and performance optimization for web applications, APIs, and media content.

## CloudFront Distributions

### Active Distribution Inventory
```yaml
Distribution Portfolio:
  Distribution 1 (E14MBQ1TWQ1LEJ):
    Domain: d23nof834b88ys.cloudfront.net
    Status: Deployed
    Purpose: Primary web application delivery
    Created: 2024-02-15 (estimated)
    
  Distribution 2 (E1FZO978Z8RTXO):
    Domain: d2ne8j5ears6lh.cloudfront.net
    Status: Deployed
    Purpose: API and dynamic content delivery
    Created: 2024-04-20 (estimated)
    
  Distribution 3 (E9G1D2L6CCIG8):
    Domain: djx1c23tctohv.cloudfront.net
    Status: Deployed
    Purpose: Static asset and media delivery
    Created: 2024-05-10 (estimated)
    
  Distribution 4 (E1AH8ISYWG6431):
    Domain: d844gz4naftu8.cloudfront.net
    Status: Deployed
    Purpose: User-generated content delivery
    Created: 2024-06-01 (estimated)
    
  Distribution 5 (E1IK0N6Y8U0JE2):
    Domain: d3ejyccyhy7cv7.cloudfront.net
    Status: Deployed
    Purpose: DistroFM application delivery
    Created: 2024-06-14 (estimated)
```

## Distribution Configuration Details

### Primary Web Application Distribution (E14MBQ1TWQ1LEJ)
```yaml
Distribution Configuration:
  Distribution ID: E14MBQ1TWQ1LEJ
  Domain Name: d23nof834b88ys.cloudfront.net
  Status: Deployed
  Price Class: PriceClass_All (global distribution)
  HTTP Version: HTTP/2 enabled
  IPv6: Enabled
  
Origins:
  Primary Origin:
    Domain Name: fuga-wav-uploader-alb-dev-xxxxxxxxx.<REGION>.elb.amazonaws.com
    Origin ID: ALB-Origin-1
    Protocol Policy: HTTPS Only
    Origin Path: /
    Custom Headers:
      X-Forwarded-Proto: https
      X-CloudFront-Distribution-ID: E14MBQ1TWQ1LEJ
      
Default Cache Behavior:
  Target Origin: ALB-Origin-1
  Viewer Protocol Policy: Redirect HTTP to HTTPS
  Allowed HTTP Methods: GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE
  Cached HTTP Methods: GET, HEAD, OPTIONS
  Cache Policy: Managed-CachingOptimized
  Origin Request Policy: Managed-CORS-S3Origin
  TTL Settings:
    Default TTL: 86400 seconds (24 hours)
    Maximum TTL: 31536000 seconds (1 year)
    Minimum TTL: 0 seconds
  Compress Objects: Enabled
  
SSL Certificate:
  Certificate Source: AWS Certificate Manager (ACM)
  Certificate Domain: *.distronation.com
  Minimum Protocol Version: TLSv1.2
  SSL Support Method: SNI Only
  Certificate ARN: arn:aws:acm:<REGION>:<AWS_ACCOUNT_ID>:certificate/xxxxxxxx
```

### API Content Distribution (E1FZO978Z8RTXO)
```yaml
Distribution Configuration:
  Distribution ID: E1FZO978Z8RTXO
  Domain Name: d2ne8j5ears6lh.cloudfront.net
  Status: Deployed
  Price Class: PriceClass_100 (North America and Europe)
  HTTP Version: HTTP/2 enabled
  
Origins:
  API Gateway Origin:
    Domain Name: <API_GATEWAY_ID_2>.execute-api.<REGION>.amazonaws.com
    Origin ID: APIGateway-Origin-1
    Protocol Policy: HTTPS Only
    Origin Path: /staging
    Custom Headers:
      X-API-Key: [Configured if required]
      Authorization: [Passed through from viewer]
      
Cache Behaviors:
  Default Behavior:
    Target Origin: APIGateway-Origin-1
    Viewer Protocol Policy: HTTPS Only
    Allowed HTTP Methods: GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE
    Cached HTTP Methods: GET, HEAD
    Cache Policy: Managed-CachingDisabled (API responses)
    Origin Request Policy: Managed-AllViewerExceptHostHeader
    TTL Settings:
      Default TTL: 0 seconds (no caching for dynamic content)
      Maximum TTL: 0 seconds
      Minimum TTL: 0 seconds
      
  Static Assets Behavior:
    Path Pattern: /assets/*
    Viewer Protocol Policy: Redirect HTTP to HTTPS
    Cache Policy: Managed-CachingOptimized
    TTL Settings:
      Default TTL: 86400 seconds (24 hours)
```

### Static Asset Distribution (E9G1D2L6CCIG8)
```yaml
Distribution Configuration:
  Distribution ID: E9G1D2L6CCIG8
  Domain Name: djx1c23tctohv.cloudfront.net
  Status: Deployed
  Price Class: PriceClass_All (global distribution)
  
Origins:
  S3 Bucket Origin:
    Domain Name: distronation-audio.s3.amazonaws.com
    Origin ID: S3-Audio-Origin
    Origin Access Control: Enabled (OAC)
    S3 Origin Config:
      Origin Access Identity: Deprecated (using OAC)
      
  S3 Assets Origin:
    Domain Name: distro-nation-upload.s3.amazonaws.com
    Origin ID: S3-Upload-Origin
    Origin Access Control: Enabled (OAC)
    
Cache Behaviors:
  Audio Files Behavior:
    Path Pattern: /audio/*
    Target Origin: S3-Audio-Origin
    Viewer Protocol Policy: HTTPS Only
    Cache Policy: Managed-CachingOptimized
    TTL Settings:
      Default TTL: 86400 seconds (24 hours)
      Maximum TTL: 31536000 seconds (1 year)
    Compress Objects: Enabled
    
  Upload Files Behavior:
    Path Pattern: /uploads/*
    Target Origin: S3-Upload-Origin
    Viewer Protocol Policy: HTTPS Only
    Cache Policy: Managed-CachingOptimizedForUncompressedObjects
    TTL Settings:
      Default TTL: 3600 seconds (1 hour)
      Maximum TTL: 86400 seconds (24 hours)
```

### Media Content Distribution (E1AH8ISYWG6431)
```yaml
Distribution Configuration:
  Distribution ID: E1AH8ISYWG6431
  Domain Name: d844gz4naftu8.cloudfront.net
  Status: Deployed
  Price Class: PriceClass_All (global distribution)
  
Origins:
  Profile Pictures Origin:
    Domain Name: distronationfm-profile-pictures.s3.amazonaws.com
    Origin ID: S3-Profiles-Origin
    Origin Access Control: Enabled (OAC)
    
  Media Assets Origin:
    Domain Name: distrofmb1ec38f05cba40828e65a98e039c6de4db8f9-main.s3.amazonaws.com
    Origin ID: S3-DistroFM-Origin
    Origin Access Control: Enabled (OAC)
    
Cache Behaviors:
  Profile Images Behavior:
    Path Pattern: /profiles/*
    Target Origin: S3-Profiles-Origin
    Viewer Protocol Policy: HTTPS Only
    Cache Policy: Managed-CachingOptimized
    TTL Settings:
      Default TTL: 604800 seconds (7 days)
      Maximum TTL: 31536000 seconds (1 year)
    Image Optimization: Enabled (if available)
    
  Media Files Behavior:
    Path Pattern: /media/*
    Target Origin: S3-DistroFM-Origin
    Viewer Protocol Policy: HTTPS Only
    Cache Policy: Custom-MediaOptimized
    TTL Settings:
      Default TTL: 86400 seconds (24 hours)
      Maximum TTL: 2592000 seconds (30 days)
```

### DistroFM Application Distribution (E1IK0N6Y8U0JE2)
```yaml
Distribution Configuration:
  Distribution ID: E1IK0N6Y8U0JE2
  Domain Name: d3ejyccyhy7cv7.cloudfront.net
  Status: Deployed
  Price Class: PriceClass_All (global distribution)
  
Origins:
  DistroFM API Origin:
    Domain Name: <API_GATEWAY_ID_1>.execute-api.<REGION>.amazonaws.com
    Origin ID: DistroFM-API-Origin
    Protocol Policy: HTTPS Only
    Origin Path: /main
    Custom Headers:
      X-Forwarded-Proto: https
      
  DistroFM Static Origin:
    Domain Name: distrofmb1ec38f05cba40828e65a98e039c6de4db8f9-main.s3.amazonaws.com
    Origin ID: DistroFM-Static-Origin
    Origin Access Control: Enabled (OAC)
    
Cache Behaviors:
  API Behavior:
    Path Pattern: /api/*
    Target Origin: DistroFM-API-Origin
    Viewer Protocol Policy: HTTPS Only
    Cache Policy: Managed-CachingDisabled
    Origin Request Policy: Managed-AllViewerExceptHostHeader
    
  Static Assets Behavior:
    Path Pattern: /static/*
    Target Origin: DistroFM-Static-Origin
    Viewer Protocol Policy: HTTPS Only
    Cache Policy: Managed-CachingOptimized
    TTL Settings:
      Default TTL: 86400 seconds (24 hours)
      Maximum TTL: 31536000 seconds (1 year)
```

## Cache Policies and Optimization

### Managed Cache Policies
```yaml
AWS Managed Policies Used:
  CachingOptimized:
    Cache Key: Host, CloudFront-Viewer-Country
    TTL: 24 hours default, 1 year maximum
    Compression: Enabled
    Use Case: Static assets, images, CSS, JS
    
  CachingDisabled:
    Cache Key: All query strings, headers, cookies
    TTL: 0 seconds (no caching)
    Use Case: Dynamic content, API responses
    
  CachingOptimizedForUncompressedObjects:
    Cache Key: Host header only
    TTL: 24 hours default, 1 year maximum
    Compression: Disabled
    Use Case: Pre-compressed files, binary content
```

### Custom Cache Policies
```yaml
Custom-MediaOptimized (recommended):
  Cache Key Components:
    Query Strings: All (for dynamic resizing parameters)
    Headers: Accept, CloudFront-Viewer-Country
    Cookies: None
  TTL Settings:
    Default TTL: 86400 seconds (24 hours)
    Maximum TTL: 2592000 seconds (30 days)
    Minimum TTL: 0 seconds
  Compression: Disabled (media files pre-compressed)
  
Custom-APIWithAuth (recommended):
  Cache Key Components:
    Query Strings: All
    Headers: Authorization, Accept, Content-Type
    Cookies: None
  TTL Settings:
    Default TTL: 300 seconds (5 minutes)
    Maximum TTL: 3600 seconds (1 hour)
    Minimum TTL: 0 seconds
  Use Case: Cacheable API responses with authentication
```

## Origin Request Policies

### Current Origin Request Policies
```yaml
Managed-CORS-S3Origin:
  Headers: Access-Control-Request-Headers, Access-Control-Request-Method, Origin
  Query Strings: None
  Cookies: None
  Use Case: S3 origins with CORS requirements
  
Managed-AllViewerExceptHostHeader:
  Headers: All viewer headers except Host
  Query Strings: All
  Cookies: All
  Use Case: API Gateway origins requiring full request forwarding
  
Custom-ALBOriginPolicy (recommended):
  Headers: CloudFront-Viewer-Country, CloudFront-Is-Mobile-Viewer, X-Forwarded-Proto
  Query Strings: All
  Cookies: None
  Use Case: ALB origins with geographic and device awareness
```

## Edge Locations and Performance

### Geographic Distribution
```yaml
CloudFront Edge Locations:
  North America: 70+ locations
    Major Hubs: Ashburn, Chicago, Dallas, Los Angeles, New York, Seattle
    Coverage: United States, Canada, Mexico
    
  Europe: 30+ locations
    Major Hubs: Amsterdam, Frankfurt, London, Madrid, Paris
    Coverage: EU, UK, Eastern Europe
    
  Asia Pacific: 25+ locations
    Major Hubs: Hong Kong, Mumbai, Seoul, Singapore, Tokyo
    Coverage: Asia, Australia, India
    
  South America: 10+ locations
    Major Hubs: São Paulo, Buenos Aires
    Coverage: Brazil, Argentina, Chile
    
  Africa: 5+ locations
    Major Hubs: Cape Town, Johannesburg
    Coverage: South Africa, Kenya
```

### Performance Metrics
```yaml
Current Performance Characteristics:
  Cache Hit Ratio: 85-95% (estimated for static content)
  Edge Response Time: 10-50ms (varies by location)
  Origin Shield: Not configured (recommended for high-traffic origins)
  
Geographic Performance:
  North America: <50ms average response time
  Europe: <100ms average response time
  Asia Pacific: <150ms average response time
  Other Regions: <200ms average response time
  
Bandwidth Capabilities:
  Per Edge Location: Up to 100 Gbps
  Global Capacity: Multi-terabit aggregate
  Content Types: All file types supported
```

## Security Configuration

### Web Application Firewall (WAF)
```yaml
WAF Integration:
  Current Status: Not configured
  Recommended Implementation:
    WAF Name: DistroNation-WebACL
    Rules:
      - AWS Managed - Core Rule Set
      - AWS Managed - Known Bad Inputs
      - Rate Limiting: 2000 requests per 5 minutes per IP
      - Geo Blocking: None (global access required)
      
  Custom Rules (recommended):
    API Protection Rule:
      Action: Block
      Conditions: SQL injection patterns in query strings
      
    File Upload Protection:
      Action: Rate Limit
      Conditions: POST requests to /upload/* paths
      Rate: 100 requests per 5 minutes per IP
```

### Origin Access Control (OAC)
```yaml
S3 Origin Access Control:
  OAC ID: oac-xxxxxxxxx (auto-generated)
  Purpose: Restrict S3 bucket access to CloudFront only
  
S3 Bucket Policies:
  distronation-audio bucket:
    Principal: cloudfront.amazonaws.com
    Condition: StringEquals aws:SourceArn
    Action: s3:GetObject
    
  distro-nation-upload bucket:
    Principal: cloudfront.amazonaws.com
    Condition: StringEquals aws:SourceArn
    Action: s3:GetObject, s3:PutObject
    
  distronationfm-profile-pictures bucket:
    Principal: cloudfront.amazonaws.com
    Condition: StringEquals aws:SourceArn
    Action: s3:GetObject
```

### SSL/TLS Configuration
```yaml
SSL Certificate Configuration:
  Certificate Provider: AWS Certificate Manager (ACM)
  Certificate Type: Wildcard certificate (*.distronation.com)
  Minimum Protocol Version: TLSv1.2
  Security Policy: CloudFront-TLS-1-2-2021-01
  
Supported Cipher Suites:
  TLS 1.3:
    - TLS_AES_128_GCM_SHA256
    - TLS_AES_256_GCM_SHA384
    - TLS_CHACHA20_POLY1305_SHA256
    
  TLS 1.2:
    - ECDHE-RSA-AES128-GCM-SHA256
    - ECDHE-RSA-AES256-GCM-SHA384
    - ECDHE-RSA-CHACHA20-POLY1305
    
HSTS Configuration (recommended):
  Strict-Transport-Security: max-age=31536000; includeSubDomains
  Implementation: Via Lambda@Edge or origin response headers
```

## Custom Domain Configuration

### Alternate Domain Names (CNAMEs)
```yaml
Current Custom Domains (inferred):
  Primary Web Application:
    - app.distronation.com
    - www.distronation.com
    
  API Services:
    - api.distronation.com
    - api-cdn.distronation.com
    
  Media Delivery:
    - cdn.distronation.com
    - assets.distronation.com
    - media.distronation.com
    
  DistroFM Application:
    - app.distrofm.com
    - cdn.distrofm.com
    
Route53 DNS Records:
  app.distronation.com:
    Type: ALIAS
    Target: d23nof834b88ys.cloudfront.net
    Zone: distronation.com hosted zone
    
  cdn.distronation.com:
    Type: ALIAS
    Target: djx1c23tctohv.cloudfront.net
    Zone: distronation.com hosted zone
```

## Lambda@Edge Functions

### Current Lambda@Edge Usage
```yaml
Lambda@Edge Functions:
  Status: Not currently deployed
  Recommended Implementations:
    Origin Request Function:
      Purpose: Request routing and header manipulation
      Runtime: Node.js 18.x
      Timeout: 5 seconds
      
    Viewer Response Function:
      Purpose: Security headers injection
      Runtime: Node.js 18.x
      Code: Add HSTS, CSP, X-Frame-Options headers
      
    Origin Response Function:
      Purpose: Cache header optimization
      Runtime: Node.js 18.x
      Code: Dynamic cache-control based on content type
```

### Recommended Lambda@Edge Implementations
```yaml
Security Headers Function:
  Trigger: Viewer Response
  Purpose: Add security headers to all responses
  Headers Added:
    - Strict-Transport-Security: max-age=31536000; includeSubDomains
    - X-Content-Type-Options: nosniff
    - X-Frame-Options: DENY
    - X-XSS-Protection: 1; mode=block
    - Content-Security-Policy: default-src 'self'
    
Image Optimization Function:
  Trigger: Origin Request
  Purpose: Dynamic image resizing and format conversion
  Parameters: Width, height, quality, format
  Example: /image.jpg?w=300&h=200&q=80&f=webp
  
A/B Testing Function:
  Trigger: Viewer Request
  Purpose: Route users to different origins for testing
  Logic: Cookie-based or percentage-based routing
```

## Monitoring and Analytics

### CloudWatch Metrics
```yaml
CloudFront Metrics:
  Request Metrics:
    - Requests: Total number of requests
    - BytesDownloaded: Data transferred to viewers
    - BytesUploaded: Data transferred from viewers
    
  Performance Metrics:
    - OriginLatency: Time to first byte from origin
    - CacheHitRate: Percentage of requests served from cache
    - ErrorRate: Percentage of 4xx and 5xx responses
    
  Geographic Metrics:
    - RequestsByCountry: Request distribution by country
    - BytesDownloadedByCountry: Data transfer by country
    
Monitoring Frequency: 1-minute intervals
Retention Period: 15 months
```

### Real User Monitoring (RUM)
```yaml
CloudWatch RUM Integration:
  Status: Not currently configured
  Recommended Configuration:
    App Monitor Name: DistroNation-WebApp
    Domain: app.distronation.com
    Metrics Collected:
      - Core Web Vitals (LCP, FID, CLS)
      - Navigation timing
      - Resource loading times
      - JavaScript errors
      
  Performance Insights:
    Page Load Time: Target <2 seconds
    First Contentful Paint: Target <1.5 seconds
    Largest Contentful Paint: Target <2.5 seconds
    Cumulative Layout Shift: Target <0.1
```

## Cost Optimization

### Current Cost Analysis
```yaml
CloudFront Cost Breakdown:
  Request Costs:
    HTTP/HTTPS Requests: $0.0075 per 10,000 requests
    Estimated Monthly Requests: 10-50 million
    Request Cost: $7.50-37.50/month
    
  Data Transfer Costs:
    First 10 TB: $0.085 per GB
    Next 40 TB: $0.080 per GB
    Estimated Monthly Transfer: 1-5 TB
    Data Transfer Cost: $85-400/month
    
  SSL Certificate Costs:
    Custom SSL Certificate: $600/month (dedicated IP)
    SNI SSL Certificate: Free (recommended)
    
Total Estimated CloudFront Costs: $95-440/month
```

### Cost Optimization Strategies
```yaml
Cost Reduction Opportunities:
  1. Price Class Optimization:
     Current: PriceClass_All (global)
     Recommendation: PriceClass_100 for non-global content
     Potential Savings: 20-30% of data transfer costs
     
  2. Origin Shield Implementation:
     Cost: $0.09 per 10,000 requests
     Benefit: Reduced origin requests by 50-80%
     Net Savings: $20-50/month for high-traffic origins
     
  3. Compression Optimization:
     Enable compression for text-based content
     Estimated Reduction: 60-80% for CSS, JS, HTML
     Data Transfer Savings: 20-40% overall
     
  4. Cache Optimization:
     Increase cache hit ratio from 85% to 95%
     Origin Request Reduction: 60% fewer origin hits
     Cost Savings: $15-30/month in reduced ALB costs
```

## Disaster Recovery and High Availability

### Multi-Origin Configuration
```yaml
Current HA Status:
  Primary Origins: Single origin per distribution
  Failover: Not configured
  Health Checks: Not implemented
  
Recommended HA Configuration:
  Primary Origin Group:
    Primary Origin: fuga-wav-uploader-alb-dev (<REGION>)
    Failover Origin: Standby ALB (us-west-2)
    Failover Criteria: 4xx/5xx responses, timeouts
    
  Origin Group Failover:
    Failover Time: 30 seconds
    Health Check: HTTP 200 response from /health
    Automatic Failback: 5 minutes after primary recovery
```

### Cache Invalidation Strategy
```yaml
Invalidation Patterns:
  Application Deployments:
    Paths: /*, /static/*, /api/*
    Frequency: 2-5 times per week
    Cost: First 1,000 paths free, then $0.005 per path
    
  Content Updates:
    Paths: /media/*, /profiles/*
    Frequency: As needed
    Strategy: Use versioned URLs to avoid invalidations
    
  Emergency Invalidations:
    Process: Immediate invalidation for security issues
    Paths: /* (full cache clear)
    Time to Complete: 10-15 minutes globally
```

## CDN Distribution Overview

### CDN Consolidation Strategy
```yaml
Phase 1 - CDN Assessment and Optimization (Weeks 1-2):
  Tasks:
    - Complete CloudFront distribution audit
    - Analyze traffic patterns and cache performance
    - Identify consolidation opportunities
    - Benchmark current performance metrics
    
Phase 2 - Performance and Security Enhancement (Weeks 3-4):
  Tasks:
    - Implement WAF protection
    - Deploy Lambda@Edge functions
    - Optimize cache policies and TTL values
    - Enable comprehensive monitoring and alerting
    
Phase 3 - System Optimization (Weeks 5-8):
  Tasks:
    - Optimize CDN performance and caching
    - Implement advanced SSL certificate management
    - Deploy failover capabilities
    - Establish comprehensive performance monitoring
```



## Troubleshooting and Diagnostics

### Common CloudFront Issues
```yaml
Issue 1 - High Cache Miss Ratio:
  Symptoms: Poor performance, high origin load
  Common Causes:
    - Frequent cache invalidations
    - Dynamic query parameters in URLs
    - Incorrect cache policies
    
  Diagnostics:
    - CloudWatch CacheHitRate metric analysis
    - Access log analysis for cache status
    - Origin request pattern review
    
  Resolution:
    - Optimize cache policies and TTL values
    - Implement URL normalization
    - Use versioned URLs for static assets

Issue 2 - Origin Connection Failures:
  Symptoms: 5xx errors, timeout responses
  Common Causes:
    - Origin server capacity issues
    - Security group misconfiguration
    - SSL certificate problems
    
  Diagnostics:
    - CloudWatch OriginLatency metrics
    - ALB target health checks
    - SSL certificate validation
    
  Resolution:
    - Scale origin infrastructure
    - Verify security group rules
    - Implement origin failover
```

### Diagnostic Tools and Commands
```yaml
CloudFront Diagnostics:
  AWS CLI Commands:
    aws cloudfront list-distributions
    aws cloudfront get-distribution --id E14MBQ1TWQ1LEJ
    aws cloudfront create-invalidation --distribution-id E14MBQ1TWQ1LEJ --paths "/*"
    
  Browser Developer Tools:
    Response Headers: CF-Cache-Status, CF-Ray, CF-Pop
    Network Tab: Request timing and cache status
    
  Third-Party Tools:
    GTmetrix: Performance testing with waterfall charts
    WebPageTest: Multi-location performance analysis
    Pingdom: Global response time monitoring
```

## Related Documentation
- [Load Balancer Configuration](./load-balancers.md)
- [DNS Configuration](./dns-configuration.md)
- [VPC Network Topology](./vpc-topology.md)
- [Security Groups Configuration](./security-groups.md)
- [AWS Infrastructure Inventory](../architecture/aws-infrastructure-inventory.md)

---

**Document Version**: 1.0  
**Last Updated**: July 24, 2025  
**Prepared By**: Adrian Green, Head of Engineering  
**Review Status**: Ready for technical review

*This document contains detailed CloudFront configuration information. Access is restricted to authorized technical personnel.*
