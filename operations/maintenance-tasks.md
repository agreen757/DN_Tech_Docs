# Maintenance Operations

## Overview

This document details scheduled maintenance operations that support Distro Nation's content management and claims processing infrastructure.

## Claims Report Processing

### Purpose
Weekly automated processing of claims reports to identify content performance anomalies, detect viral content trends, and flag potential disputes before they escalate.

### Technical Implementation

#### EventBridge Schedule
- **Rule Name**: `dn-claims-report`
- **Schedule**: `rate(7 days)` (Weekly execution)
- **Target**: ECS Fargate Task
- **State**: ENABLED

#### ECS Task Configuration
- **Task Definition**: `dn-task-claims-report-process:4`
- **Platform**: AWS Fargate
- **CPU**: 1024 units (1 vCPU)
- **Memory**: 3072 MB (3 GB)
- **Container Image**: `agreen757dn/claims-report:latest`

#### Network Configuration
- **Network Mode**: awsvpc
- **Subnets**: Configured for secure VPC access
- **Security Groups**: Restricted access to required services only
- **Public IP**: ENABLED for external API access

### Processing Objectives

#### Viral Content Detection
The claims report processing analyzes content performance metrics to identify:
- Sudden spikes in view counts or engagement
- Cross-platform viral propagation patterns
- Content that may trigger additional rights claims
- Performance anomalies requiring immediate attention

#### Dispute Prevention
Early warning system for potential disputes by monitoring:
- Unusual claims patterns on specific content
- Rights conflicts across multiple platforms
- Performance discrepancies that may indicate rights issues
- Content flagged by automated content ID systems

### Data Sources
- YouTube Content ID claims data
- Platform analytics and performance metrics
- Internal content management database
- Rights management system records

### Output and Notifications
- Weekly summary reports of processed claims
- Automated alerts for high-priority content requiring review
- Performance trend analysis for strategic decision making
- Dispute risk assessment for proactive rights management

### Monitoring and Alerting
- Task execution status monitoring via CloudWatch
- Failed execution alerts with automatic retry logic
- Performance metrics tracking for optimization
- Data quality validation and error reporting

## Custom ID Cleanup Process

### Purpose
Automated daily workflow for processing channel data and updating YouTube CMS custom IDs. This two-stage process ensures accurate metadata synchronization between Distro Nation's internal systems and YouTube's Content Management System.

### Technical Implementation

#### Workflow Architecture
The custom ID cleanup process uses an event-driven architecture with two sequential ECS tasks:

1. **channelbackfill** → processes channel data from CSV files
2. **cmsCustomidCleanup** → updates video metadata based on processed channel data

#### EventBridge Integration
- **Event Bus**: `dn-backend-workflow-bus-dev`
- **Trigger Pattern**: channelbackfill completion event automatically triggers cmsCustomidCleanup
- **Event-driven execution**: No manual intervention required between stages

#### ECS Task Specifications

**channelbackfill Task**:
- **Task Definition**: `channelbackfill-task:2`
- **Platform**: AWS Fargate
- **CPU**: 2048 units (2 vCPU)
- **Memory**: 4096 MB (4 GB)
- **Container Image**: `<AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/amplify-dnbackendfunctions-dev-57767-api-channelbackfill-api:latest`
- **Execution Time**: ~10-15 minutes for typical dataset

**cmsCustomidCleanup Task**:
- **Task Definition**: `cmscustomidcleanup-task:2`
- **Platform**: AWS Fargate
- **CPU**: 4096 units (4 vCPU)
- **Memory**: 8192 MB (8 GB)
- **Container Image**: `<AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/amplify-dnbackendfunctions-dev-57767-api-cmscustomidupdate-api:latest`
- **Execution Time**: ~2-4 hours for 38,000+ video dataset

#### Network Configuration
- **ECS Cluster**: `amplify-dnbackendfunctions-dev-57767-NetworkStack-1WQ2JX5JBEL8C-Cluster-o2oPTAWsP4AL`
- **Network Mode**: awsvpc
- **Subnets**: 
  - subnet-0614f6234c8532909 (<REGION>a)
  - subnet-07af64e6a2897f64c (<REGION>b)
  - subnet-05e6b470667a77016 (<REGION>c)
- **Security Groups**: sg-0e95bc87b1582a935
- **Public IP**: ENABLED for external API access

### Process Flow

#### Stage 1: Channel Data Processing (channelbackfill)
1. **Input**: CSV file containing channel mappings (channelID, customID, displayName)
2. **Processing**: 
   - Reads channel data from `./channels_customids.csv`
   - Creates or updates partner channel records in GraphQL database
   - Processes ~372 channel records
3. **Output**: Success/failure event published to EventBridge
4. **Event Structure**:
   ```json
   {
     "Source": "dn.backend.channelbackfill",
     "DetailType": "Channel Backfill Completed",
     "Detail": {
       "status": "success",
       "processedCount": 368,
       "errorCount": 0,
       "totalCount": 372,
       "timestamp": "2025-07-29T18:45:00.000Z"
     }
   }
   ```

#### Stage 2: CMS Custom ID Cleanup (cmsCustomidCleanup)
1. **Trigger**: EventBridge event from completed channelbackfill
2. **Input Validation**: Verifies event source and success status
3. **Processing**:
   - Retrieves partner channel data from GraphQL database
   - Downloads video report from S3 (`youtube-reporting-main/reports/video_report_Indmusic_V_v1-3.csv`)
   - Filters videos belonging to partner channels
   - Updates YouTube CMS custom IDs via API calls
   - Processes ~38,000+ video records
4. **Output**: 
   - Updated CMS metadata in YouTube
   - Local file export (`/tmp/[filterTarget].json`)
   - Processing statistics

### Data Sources and APIs

#### Input Data Sources
- **Channel CSV**: `./channels_customids.csv` - Channel ID to custom ID mappings
- **S3 Video Report**: `youtube-reporting-main/reports/video_report_Indmusic_V_v1-3.csv`
- **GraphQL Database**: Partner channel records and relationships

#### External API Integrations
- **YouTube Partner API**: CMS metadata updates
- **YouTube Data API v3**: Video information retrieval
- **AWS S3**: Report file downloads
- **Distro Nation GraphQL API**: Channel and video data access

### Monitoring and Alerting

#### CloudWatch Metrics
- **Task Execution Status**: Success/failure tracking for both tasks
- **Duration Metrics**: Processing time monitoring
- **Resource Utilization**: CPU and memory usage patterns
- **Error Rates**: API call failures and data processing errors

#### CloudWatch Logs
- **channelbackfill logs**: `/ecs/channelbackfill`
- **cmsCustomidCleanup logs**: `/ecs/cmscustomidcleanup`
- **Log Retention**: 30 days (configurable)

#### EventBridge Monitoring
- **Rule Execution**: Success/failure of event pattern matching
- **Target Invocation**: ECS task trigger success rates
- **Event Publishing**: channelbackfill event emission tracking

### Error Handling and Recovery

#### channelbackfill Failures
1. **Immediate Response**: Failure event published to EventBridge
2. **Error Logging**: Detailed error information in CloudWatch logs
3. **Notification**: Captured by `channelbackfill-failure-alert-dev` rule
4. **Recovery**: Manual investigation and potential data source correction

#### cmsCustomidCleanup Failures
1. **Event Filtering**: Skips processing if channelbackfill was not successful
2. **API Error Handling**: Retry logic with exponential backoff
3. **Token Refresh**: Automatic YouTube API token renewal on authentication errors
4. **Partial Processing**: Continues processing remaining videos on individual failures

#### Network and Infrastructure Failures
1. **ECS Service Resilience**: Automatic task restart on infrastructure failures
2. **Multi-AZ Deployment**: Tasks can run across multiple availability zones
3. **Security Group Recovery**: Network connectivity troubleshooting procedures

### Performance Optimization

#### Resource Allocation
- **channelbackfill**: Optimized for I/O operations (CSV processing, API calls)
- **cmsCustomidCleanup**: Optimized for sustained processing (large dataset iteration)
- **Memory Management**: Efficient processing of large CSV files in memory

#### API Rate Limiting
- **YouTube API**: Implements request throttling and quota management
- **Retry Strategy**: Exponential backoff for rate limit and temporary failures
- **Batch Processing**: Optimized API call patterns for throughput

### Migration from Lambda

#### Rationale for ECS Migration
- **Timeout Limitations**: Lambda 15-minute maximum execution time insufficient
- **Large Dataset Processing**: 38,000+ video records require unlimited execution time
- **Resource Requirements**: Higher CPU and memory needs for efficient processing
- **Cost Optimization**: ECS more cost-effective for long-running processes

#### Architecture Benefits
- **Event-driven Workflow**: Maintained through EventBridge integration
- **Unlimited Execution Time**: No timeout constraints for data processing
- **Resource Scaling**: Flexible CPU and memory allocation
- **Container Portability**: Easy deployment and environment consistency

## Additional Maintenance Tasks

### Daily Operations
- Social media analytics collection and processing
- Content metadata synchronization across platforms
- User engagement metrics aggregation

### Weekly Operations
- Claims report processing (detailed above)
- Performance trending analysis
- Rights management database updates

### Monthly Operations
- Comprehensive data quality audits
- Performance optimization reviews
- Infrastructure cost analysis and optimization

## Emergency Procedures

### Claims Processing Failures
1. Verify ECS task execution status in AWS Console
2. Check CloudWatch logs for error details
3. Validate data source availability
4. Execute manual processing if required
5. Update stakeholders on processing delays

### Data Quality Issues
1. Implement immediate data validation checks
2. Quarantine suspect data for review
3. Execute data reconciliation procedures
4. Generate impact assessment report
5. Implement corrective measures