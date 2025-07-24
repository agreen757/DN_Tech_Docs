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

### Lambda Functions (Key Functions - 84 total)
| Function | Runtime | Purpose |
|----------|---------|---------|
| POSTGRESQL_LAMBDA | nodejs20.x | Database operations |
| DN_Send_Mail | python3.12 | Email notifications |
| YouTube_API_Token | nodejs18.x | YouTube API integration |
| dn_payouts_fetch | python3.12 | Payout processing |
| dn_spotify_analytics | nodejs18.x | Spotify data analytics |
| dn_tiktok_analytics | nodejs18.x | TikTok data analytics |

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

### Key Patterns
- **Serverless-first architecture** with extensive Lambda usage
- **Multi-environment setup** (dev, staging, main) using Amplify
- **Media-focused infrastructure** with specialized buckets for audio, video, images
- **Analytics integration** with YouTube, Spotify, TikTok platforms
- **PostgreSQL Aurora** as primary database with serverless scaling