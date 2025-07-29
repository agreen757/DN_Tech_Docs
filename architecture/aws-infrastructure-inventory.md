# AWS Infrastructure Inventory

**Account ID:** <AWS_ACCOUNT_ID>  
**Primary Region:** <REGION>  
**User:** <ADMIN_USER>

## Compute Resources

### EC2 Instances
| Instance ID | Type | State | Name | Purpose |
|-------------|------|-------|------|---------|
| i-03e7077c18246e75b | t2.micro | stopped | dn-ec2-ddb-instance | Database operations |
| i-090b84df011c67d5e | t2.micro | stopped | dn-ec2-priv-main | Private main server |
| i-03dd62734a34f0c0b | t2.xlarge | stopped | dn-ssss | Large compute instance |
| i-090dc75e90525eb5e | t2.micro | stopped | vpn | VPN server |
| i-0063537094eb961dd | t3.micro | **running** | Shazampy-env | Active environment |

### ECS Clusters
| Cluster Name | ARN | Status | Platform | Purpose |
|-------------|-----|--------|----------|---------|
| amplify-dnbackendfunctions-dev-57767-NetworkStack-1WQ2JX5JBEL8C-Cluster-o2oPTAWsP4AL | arn:aws:ecs:<REGION>:<AWS_ACCOUNT_ID>:cluster/amplify-dnbackendfunctions-dev-57767-NetworkStack-1WQ2JX5JBEL8C-Cluster-o2oPTAWsP4AL | **active** | AWS Fargate | Long-running tasks and batch processing |

### ECS Task Definitions
| Task Definition | Revision | CPU | Memory | Purpose |
|----------------|----------|-----|--------|---------|
| channelbackfill-task | 2 | 2048 | 4096 | Channel data backfill processing |
| cmscustomidcleanup-task | 2 | 4096 | 8192 | YouTube CMS custom ID cleanup |

### Container Registry (ECR)
| Repository Name | URI | Purpose |
|----------------|-----|---------|
| amplify-dnbackendfunctions-dev-57767-api-channelbackfill-api | <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/amplify-dnbackendfunctions-dev-57767-api-channelbackfill-api | Channel backfill container images |
| amplify-dnbackendfunctions-dev-57767-api-cmscustomidupdate-api | <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/amplify-dnbackendfunctions-dev-57767-api-cmscustomidupdate-api | CMS custom ID cleanup container images |

### Lambda Functions (Key Functions - 82 total, 2 migrated to ECS)
| Function | Runtime | Purpose | Migration Status |
|----------|---------|---------|------------------|
| POSTGRESQL_LAMBDA | nodejs20.x | Database operations | Active |
| DN_Send_Mail | python3.12 | Email notifications | Active |
| YouTube_API_Token | nodejs18.x | YouTube API integration | Active |
| dn_payouts_fetch | python3.12 | Payout processing | Active |
| dn_spotify_analytics | nodejs18.x | Spotify data analytics | Active |
| dn_tiktok_analytics | nodejs18.x | TikTok data analytics | Active |
| ~~channelbackfill-dev~~ | ~~nodejs18.x~~ | ~~Channel data backfill~~ | **Migrated to ECS** |
| ~~cmsCustomidCleanup-dev~~ | ~~nodejs18.x~~ | ~~CMS custom ID cleanup~~ | **Migrated to ECS** |

## Database Resources

### RDS Aurora
| Identifier | Class | Engine | Status |
|------------|-------|--------|--------|
| database-2-instance-1 | db.serverless | aurora-postgresql | available |

## Storage Resources

### S3 Buckets (Key Buckets - 23 total)
| Bucket Name | Created | Purpose |
|-------------|---------|---------|
| distronation-audio | 2024-02-22 | Audio file storage |
| distronation-backup | 2024-01-26 | Backup storage |
| distronation-reporting | 2024-04-18 | Analytics and reporting |
| distro-nation-upload | 2025-04-09 | File uploads |
| distrofmb1ec38f05cba40828e65a98e039c6de4db8f9-main | 2024-05-20 | DistroFM main files |
| distronationfm-profile-pictures | 2024-05-10 | User profile images |
| amplify-* (multiple) | Various | Amplify deployments |

## Network Resources

### Load Balancers
| Name | Type | State |
|------|------|-------|
| fuga-wav-uploader-alb-dev | application | active |

### CloudFront Distributions
| Distribution ID | Domain | Status |
|-----------------|--------|--------|
| E14MBQ1TWQ1LEJ | d23nof834b88ys.cloudfront.net | Deployed |
| E1FZO978Z8RTXO | d2ne8j5ears6lh.cloudfront.net | Deployed |
| E9G1D2L6CCIG8 | djx1c23tctohv.cloudfront.net | Deployed |
| E1AH8ISYWG6431 | d844gz4naftu8.cloudfront.net | Deployed |
| E1IK0N6Y8U0JE2 | d3ejyccyhy7cv7.cloudfront.net | Deployed |

### API Gateway
| API Name | ID | Created |
|----------|----|---------| 
| dn-api | <API_GATEWAY_ID_2> | 2024-02-08 |
| distronationfmGeneralAccess | <API_GATEWAY_ID_1> | 2024-06-14 |

### Route53 Hosted Zones
| Zone | ID |
|------|---|
| amplify-distrofm-main-db8f9-vpc-079926f66da83cd68. | /hostedzone/Z0969604XDAUQX7C50JF |
| amplify-dnbackendfunctions-dev-57767-vpc-079926f66da83cd68. | /hostedzone/Z0478090G2ORMOCNLU71 |

## Architecture Summary

### Primary Data Flow
1. **Users** → CloudFront CDN → Application Load Balancer → EC2 instances
2. **API Requests** → API Gateway → Lambda Functions → Aurora PostgreSQL
3. **File Storage** → S3 Buckets (audio, uploads, profiles, backups)
4. **External Integrations** → YouTube, Spotify, TikTok APIs via Lambda
5. **Batch Processing** → EventBridge → ECS Fargate Tasks → Aurora PostgreSQL
6. **Long-running Tasks** → ECS Cluster → Container processing → S3/Database

### Key Patterns
- **Hybrid serverless architecture** with Lambda for APIs and ECS for long-running tasks
- **Multi-environment setup** (dev, staging, main) using Amplify
- **Media-focused infrastructure** with specialized buckets for audio, video, images
- **Analytics integration** with YouTube, Spotify, TikTok platforms
- **PostgreSQL Aurora** as primary database with serverless scaling
- **Event-driven processing** using EventBridge for workflow orchestration
- **Containerized batch processing** for tasks exceeding Lambda timeout limits