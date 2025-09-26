# EventBridge Scheduled Tasks

## Overview

This document catalogs all EventBridge rules configured for automated task execution in the Distro Nation infrastructure.

## Active Schedules

### Claims Report Processing

**Rule Configuration:**
- **Name**: `dn-claims-report`
- **Schedule Expression**: `rate(7 days)`
- **Description**: Weekly processing of claims reports for viral content detection and dispute prevention
- **State**: ENABLED
- **Target Type**: ECS Task
- **Created**: Automated infrastructure deployment

### Custom ID Cleanup Workflow

**Event Bus**: `dn-backend-workflow-bus-dev`

#### channelbackfill Success Trigger

**Rule Configuration:**
- **Name**: `channelbackfill-success-trigger-dev`
- **Event Pattern**: 
  ```json
  {
    "detail-type": ["Channel Backfill Completed"],
    "source": ["dn.backend.channelbackfill"],
    "detail": {
      "status": ["success"]
    }
  }
  ```
- **Description**: Triggers CMS cleanup when channelbackfill completes successfully
- **State**: ENABLED
- **Target Type**: ECS Task
- **Created**: Custom ID cleanup workflow implementation

**Target Configuration:**
- **ECS Cluster**: `amplify-dnbackendfunctions-dev-57767-NetworkStack-1WQ2JX5JBEL8C-Cluster-o2oPTAWsP4AL`
- **Task Definition**: `cmscustomidcleanup-task:2`
- **Launch Type**: FARGATE
- **Task Count**: 1
- **Role ARN**: `arn:aws:iam::<AWS_ACCOUNT_ID>:role/ecsTaskExecutionRole`

#### channelbackfill Failure Alert

**Rule Configuration:**
- **Name**: `channelbackfill-failure-alert-dev`
- **Event Pattern**:
  ```json
  {
    "detail-type": ["Channel Backfill Failed"],
    "source": ["dn.backend.channelbackfill"],
    "detail": {
      "status": ["failed"]
    }
  }
  ```
- **Description**: Captures channelbackfill failures for alerting
- **State**: ENABLED
- **Target Type**: SNS/CloudWatch (future implementation)
- **Created**: Custom ID cleanup workflow implementation

**Target Configuration:**
- **ECS Cluster**: Default cluster
- **Task Definition**: `dn-task-claims-report-process:4`
- **Launch Type**: FARGATE
- **Platform Version**: LATEST
- **Task Count**: 1

**Resource Requirements:**
- **CPU**: 1024 units (1 vCPU)
- **Memory**: 3072 MB (3 GB)
- **Execution Role**: ECS Task Execution Role with appropriate permissions
- **Task Role**: Task-specific role for accessing required AWS services

**Network Configuration:**
- **Network Mode**: awsvpc
- **Assign Public IP**: ENABLED
- **Security Groups**: Configured for minimal required access
- **Subnets**: Private subnets with NAT gateway access

#### Custom ID Cleanup Network Configuration
- **Network Mode**: awsvpc
- **VPC Configuration**:
  - **Subnets**: 
    - subnet-0614f6234c8532909 (<REGION>a)
    - subnet-07af64e6a2897f64c (<REGION>b) 
    - subnet-05e6b470667a77016 (<REGION>c)
  - **Security Groups**: sg-0e95bc87b1582a935
- **Assign Public IP**: ENABLED

## Schedule Patterns

### Weekly Schedules
- **Claims Report Processing**: Every 7 days for comprehensive rights analysis
- **Performance Trending**: Weekly aggregation of content performance metrics
- **Rights Database Sync**: Weekly synchronization with external rights databases

### Daily Schedules
- **Analytics Collection**: Daily social media platform data harvesting
- **Content Metadata Updates**: Daily synchronization of content information
- **User Engagement Processing**: Daily aggregation of user interaction metrics

### Hourly Schedules
- **Real-time Monitoring**: Hourly health checks and performance monitoring
- **Data Quality Validation**: Continuous data integrity checks
- **Cache Refresh**: Hourly refresh of frequently accessed cached data

## Monitoring and Management

### EventBridge Metrics
- **Invocations**: Total number of rule executions
- **Successes**: Successful target invocations
- **Failures**: Failed target invocations
- **Matched Events**: Events matching rule patterns

### CloudWatch Integration
- **Log Groups**: Centralized logging for all scheduled task executions
- **Alarms**: Automated alerting for failed executions
- **Dashboards**: Visual monitoring of schedule execution patterns

### Error Handling
- **Retry Policy**: Automatic retry with exponential backoff
- **Dead Letter Queue**: Failed events captured for analysis
- **Alert Escalation**: Immediate notification for critical failures

## Troubleshooting

### Common Issues

**Task Execution Failures:**
1. Verify ECS task definition exists and is active
2. Check IAM permissions for EventBridge service role
3. Validate network configuration and security group rules
4. Review task resource requirements and cluster capacity

**Schedule Drift:**
1. Monitor EventBridge rule execution timing
2. Check for resource contention during scheduled execution
3. Validate timezone settings for schedule expressions
4. Review task execution duration trends

**Resource Constraints:**
1. Monitor ECS cluster capacity and utilization
2. Check Fargate service limits and quotas
3. Validate memory and CPU allocation efficiency
4. Review cost optimization opportunities

### Emergency Procedures

**Immediate Task Failure Response:**
1. Check EventBridge rule status and recent executions
2. Review CloudWatch logs for error details
3. Verify target service availability
4. Execute manual task if required
5. Implement temporary workarounds if necessary

**Schedule Modification:**
1. Assess impact of schedule changes on dependent systems
2. Test schedule modifications in development environment
3. Implement changes during maintenance windows
4. Monitor execution patterns after changes
5. Rollback procedures for problematic modifications

## Security Considerations

### IAM Permissions
- EventBridge service requires minimal permissions to invoke targets
- ECS tasks use dedicated execution and task roles
- Principle of least privilege applied to all configurations
- Regular audit of permissions and access patterns

#### Custom ID Cleanup IAM Configuration
**ecsTaskExecutionRole Trust Policy**:
```json
{
  "Version": "2008-10-17", 
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com",
          "events.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Required Policies**:
- `AmazonECSTaskExecutionRolePolicy` (AWS managed)
- `ECS-EventBridge-PutEvents-Policy` (custom)
- `EventBridge-ECS-RunTask-Policy` (custom)

### Network Security
- Tasks execute in private subnets with controlled internet access
- Security groups restrict traffic to required services only
- VPC Flow Logs enabled for network traffic monitoring
- Regular security group rule reviews and cleanup

### Data Protection
- Claims data processed with encryption in transit and at rest
- Sensitive data handling follows established data protection policies
- Access logging enabled for all data processing operations
- Regular data access audits and compliance reviews