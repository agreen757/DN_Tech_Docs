# AppSync Channel API Operations Runbook

## Overview
This runbook provides operational procedures for managing and troubleshooting the AppSync Channel API service. The API provides secure external access to channel data through a REST interface backed by AWS Lambda and AppSync GraphQL.

## Service Architecture

### Components
- **API Gateway**: REST endpoint with custom domain and throttling
- **Lambda Function**: `appsyncChannelApi-prod` (Node.js 20.x)
- **AppSync GraphQL API**: Internal data access layer
- **DynamoDB**: Data persistence
- **SSM Parameter Store**: API key management
- **CloudWatch**: Monitoring and logging

### Security Model
```
External Client → Client API Key → API Gateway → Lambda → AppSync API Key → AppSync/DynamoDB
```

## Monitoring and Alerting

### Key Metrics to Monitor

#### API Gateway Metrics
- **4XXError**: Client errors (target: < 5%)
- **5XXError**: Server errors (target: < 1%)
- **Count**: Total requests per minute
- **Latency**: Response time (target: < 500ms)
- **IntegrationLatency**: Backend processing time

#### Lambda Metrics
- **Duration**: Function execution time
- **Errors**: Function errors
- **Throttles**: Concurrent execution limits
- **ConcurrentExecutions**: Active function instances

#### Custom Application Metrics
- **API Key Validation Failures**: Authentication errors
- **AppSync Connection Errors**: Backend connectivity issues
- **Rate Limit Violations**: Client throttling events

### CloudWatch Alarms

#### Critical Alarms (Immediate Response)
```bash
# High error rate
aws cloudwatch put-metric-alarm \
  --alarm-name "AppSyncChannelAPI-HighErrorRate" \
  --alarm-description "API error rate > 5%" \
  --metric-name 4XXError \
  --namespace AWS/ApiGateway \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2

# Service unavailable
aws cloudwatch put-metric-alarm \
  --alarm-name "AppSyncChannelAPI-ServiceUnavailable" \
  --alarm-description "API 5XX errors > 1%" \
  --metric-name 5XXError \
  --namespace AWS/ApiGateway \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1
```

#### Warning Alarms (Monitor Closely)
```bash
# High response time
aws cloudwatch put-metric-alarm \
  --alarm-name "AppSyncChannelAPI-HighLatency" \
  --alarm-description "API latency > 2 seconds" \
  --metric-name Latency \
  --namespace AWS/ApiGateway \
  --statistic Average \
  --period 300 \
  --threshold 2000 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 3
```

### Log Analysis

#### Key Log Patterns
```bash
# Authentication failures
aws logs filter-log-events \
  --log-group-name "/aws/lambda/appsyncChannelApi-prod" \
  --filter-pattern "INVALID_API_KEY" \
  --start-time $(date -d '1 hour ago' +%s)000

# Rate limit violations
aws logs filter-log-events \
  --log-group-name "/aws/apigateway/appsync-channel-api" \
  --filter-pattern "429" \
  --start-time $(date -d '1 hour ago' +%s)000

# AppSync connection errors
aws logs filter-log-events \
  --log-group-name "/aws/lambda/appsyncChannelApi-prod" \
  --filter-pattern "AppSync.*error" \
  --start-time $(date -d '1 hour ago' +%s)000
```

## Operational Procedures

### Health Check Verification

#### Manual Health Check
```bash
# Test API health endpoint
curl -H "X-API-Key: your-api-key" \
     "https://api.distronation.com/channels/health"

# Expected response
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0",
  "uptime": 3600,
  "dependencies": {
    "appsync": "healthy",
    "dynamodb": "healthy"
  }
}
```

#### Automated Health Monitoring
```bash
# CloudWatch Synthetics canary for continuous monitoring
aws synthetics create-canary \
  --name "appsync-channel-api-health" \
  --code S3Bucket=monitoring-bucket,S3Key=health-check.zip \
  --execution-role-arn arn:aws:iam::ACCOUNT:role/CloudWatchSyntheticsRole \
  --schedule Expression="rate(5 minutes)" \
  --runtime-version syn-nodejs-puppeteer-3.8
```

### API Key Management

#### Client API Key Operations
```bash
# List all client API keys
aws ssm get-parameter \
  --name "/appsync-channel-api/client-keys" \
  --with-decryption

# Add new client API key
aws ssm put-parameter \
  --name "/appsync-channel-api/client-keys" \
  --value '{"client-1": "key-value", "client-2": "key-value"}' \
  --type SecureString \
  --overwrite

# Rotate client API key
# 1. Generate new key
NEW_KEY=$(openssl rand -hex 32)

# 2. Update parameter with new key
aws ssm put-parameter \
  --name "/appsync-channel-api/client-keys" \
  --value "{\"client-1\": \"$NEW_KEY\"}" \
  --type SecureString \
  --overwrite

# 3. Notify client of new key
# 4. Remove old key after grace period
```

#### AppSync API Key Management
```bash
# Check AppSync API key status
aws ssm get-parameter \
  --name "/distro-nation/appsync/api-key" \
  --with-decryption

# The Lambda function automatically manages AppSync keys:
# - Creates new keys if none exist
# - Rotates keys before expiration
# - Updates SSM parameter with new keys
# - Logs all operations for audit
```

### Performance Optimization

#### Lambda Function Optimization
```bash
# Check function configuration
aws lambda get-function-configuration \
  --function-name appsyncChannelApi-prod

# Update memory allocation if needed
aws lambda update-function-configuration \
  --function-name appsyncChannelApi-prod \
  --memory-size 512

# Enable provisioned concurrency for consistent performance
aws lambda put-provisioned-concurrency-config \
  --function-name appsyncChannelApi-prod \
  --provisioned-concurrency-config ProvisionedConcurrencyCount=5
```

#### API Gateway Optimization
```bash
# Enable caching for GET requests
aws apigateway put-method \
  --rest-api-id API_ID \
  --resource-id RESOURCE_ID \
  --http-method GET \
  --caching-enabled \
  --cache-ttl-in-seconds 300
```

### Troubleshooting Guide

#### Common Issues and Solutions

##### 1. High Error Rate (4XX/5XX)

**Symptoms:**
- Increased 4XX/5XX error metrics
- Client complaints about API failures
- Error logs in CloudWatch

**Investigation Steps:**
```bash
# Check recent error patterns
aws logs filter-log-events \
  --log-group-name "/aws/lambda/appsyncChannelApi-prod" \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s)000

# Check API Gateway access logs
aws logs filter-log-events \
  --log-group-name "API-Gateway-Execution-Logs_API_ID/prod" \
  --filter-pattern "[timestamp, requestId, ip, user, timestamp, method, resource, protocol, status=4*, size, responseTime]"
```

**Common Causes and Solutions:**
- **Invalid API Keys**: Verify client API keys in SSM Parameter Store
- **AppSync Connection Issues**: Check AppSync API key validity and rotation
- **Rate Limiting**: Review throttling settings and client usage patterns
- **Lambda Errors**: Check function logs for application-specific errors

##### 2. High Latency

**Symptoms:**
- Increased response times
- Timeout errors
- Poor user experience

**Investigation Steps:**
```bash
# Check Lambda duration metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=appsyncChannelApi-prod \
  --start-time $(date -d '1 hour ago' --iso-8601) \
  --end-time $(date --iso-8601) \
  --period 300 \
  --statistics Average,Maximum

# Check AppSync query performance
aws logs filter-log-events \
  --log-group-name "/aws/lambda/appsyncChannelApi-prod" \
  --filter-pattern "GraphQL.*duration"
```

**Solutions:**
- **Cold Starts**: Enable provisioned concurrency
- **Database Performance**: Check DynamoDB throttling and capacity
- **Memory Allocation**: Increase Lambda memory if CPU-bound
- **Query Optimization**: Review GraphQL query efficiency

##### 3. Authentication Failures

**Symptoms:**
- 401 Unauthorized responses
- INVALID_API_KEY errors in logs
- Client authentication complaints

**Investigation Steps:**
```bash
# Check authentication error patterns
aws logs filter-log-events \
  --log-group-name "/aws/lambda/appsyncChannelApi-prod" \
  --filter-pattern "INVALID_API_KEY" \
  --start-time $(date -d '1 hour ago' +%s)000

# Verify client API keys
aws ssm get-parameter \
  --name "/appsync-channel-api/client-keys" \
  --with-decryption
```

**Solutions:**
- **Expired Keys**: Rotate client API keys
- **Missing Keys**: Ensure X-API-Key header is included
- **Invalid Format**: Verify key format and encoding
- **SSM Issues**: Check SSM parameter accessibility

### Deployment Procedures

#### Production Deployment
```bash
# 1. Deploy Lambda function
aws lambda update-function-code \
  --function-name appsyncChannelApi-prod \
  --zip-file fileb://deployment-package.zip

# 2. Update function configuration if needed
aws lambda update-function-configuration \
  --function-name appsyncChannelApi-prod \
  --environment Variables='{NODE_ENV=production}'

# 3. Update API Gateway if needed
aws apigateway create-deployment \
  --rest-api-id API_ID \
  --stage-name prod

# 4. Verify deployment
curl -H "X-API-Key: test-key" \
     "https://api.distronation.com/channels/health"
```

#### Rollback Procedures
```bash
# 1. Identify previous version
aws lambda list-versions-by-function \
  --function-name appsyncChannelApi-prod

# 2. Update alias to previous version
aws lambda update-alias \
  --function-name appsyncChannelApi-prod \
  --name PROD \
  --function-version PREVIOUS_VERSION

# 3. Verify rollback
curl -H "X-API-Key: test-key" \
     "https://api.distronation.com/channels/health"
```

### Security Procedures

#### Security Incident Response

##### 1. Suspected API Key Compromise
```bash
# 1. Immediately rotate affected keys
aws ssm put-parameter \
  --name "/appsync-channel-api/client-keys" \
  --value '{"client-1": "new-secure-key"}' \
  --type SecureString \
  --overwrite

# 2. Review access logs for suspicious activity
aws logs filter-log-events \
  --log-group-name "/aws/apigateway/appsync-channel-api" \
  --filter-pattern "[timestamp, requestId, ip, user, timestamp, method, resource, protocol, status, size, responseTime]" \
  --start-time $(date -d '24 hours ago' +%s)000

# 3. Block suspicious IP addresses if needed
aws wafv2 update-ip-set \
  --scope REGIONAL \
  --id IP_SET_ID \
  --addresses "suspicious.ip.address/32"
```

##### 2. DDoS Attack Response
```bash
# 1. Enable AWS Shield Advanced if not already enabled
aws shield subscribe-to-proactive-engagement

# 2. Implement rate limiting at WAF level
aws wafv2 create-rate-based-rule \
  --scope REGIONAL \
  --rule-name "DDoSProtection" \
  --metric-name "DDoSProtection" \
  --rate-limit 1000

# 3. Monitor attack patterns
aws logs filter-log-events \
  --log-group-name "/aws/apigateway/appsync-channel-api" \
  --filter-pattern "429"
```

### Maintenance Procedures

#### Regular Maintenance Tasks

##### Weekly Tasks
- Review CloudWatch metrics and alarms
- Check error logs for patterns
- Verify API key rotation schedules
- Monitor cost and usage trends

##### Monthly Tasks
- Review and update documentation
- Analyze performance trends
- Update security configurations
- Test disaster recovery procedures

##### Quarterly Tasks
- Security audit and penetration testing
- Capacity planning review
- Update monitoring and alerting thresholds
- Review and update runbooks

#### Scheduled Maintenance Windows
```bash
# 1. Notify clients of maintenance window
# 2. Enable maintenance mode (optional)
aws lambda update-function-configuration \
  --function-name appsyncChannelApi-prod \
  --environment Variables='{MAINTENANCE_MODE=true}'

# 3. Perform maintenance tasks
# 4. Disable maintenance mode
aws lambda update-function-configuration \
  --function-name appsyncChannelApi-prod \
  --environment Variables='{MAINTENANCE_MODE=false}'

# 5. Verify service functionality
curl -H "X-API-Key: test-key" \
     "https://api.distronation.com/channels/health"
```

## Emergency Contacts

### Escalation Matrix
1. **Level 1**: On-call engineer (immediate response)
2. **Level 2**: Senior engineer (15 minutes)
3. **Level 3**: Engineering manager (30 minutes)
4. **Level 4**: CTO (1 hour)

### Contact Information
- **On-call Engineer**: Pager system notification
- **Engineering Team**: Slack #api-alerts channel
- **AWS Support**: Enterprise support case
- **Client Communications**: Customer success team

## Documentation Updates

### Change Log
- **v1.0.0**: Initial production deployment
- **v1.0.1**: Added health check endpoint
- **v1.0.2**: Enhanced error handling and logging

### Related Documentation
- [API Specification](./appsync-channel-api-specification.md)
- [OpenAPI Schema](./appsync-channel-api-openapi.yaml)
- [Lambda Services Catalog](./lambda-services-catalog.md)
- [Security Policies](../security/security-policies.md)