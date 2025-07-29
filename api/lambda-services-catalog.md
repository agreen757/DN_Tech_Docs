# Lambda Services Catalog

## Overview
Distro Nation operates 84+ Lambda functions organized into functional service domains. This catalog categorizes all functions by their primary purpose and documents their interfaces.

## Service Categories

### 1. Authentication & Authorization Services

#### Core Authentication Functions
| Function | Runtime | Purpose | Trigger |
|----------|---------|---------|---------|
| `amplify-login-verify-auth-challenge-fa2a624e` | nodejs20.x | Verify authentication challenges | Cognito trigger |
| `amplify-login-define-auth-challenge-fa2a624e` | nodejs20.x | Define custom auth challenge | Cognito trigger |
| `amplify-login-create-auth-challenge-fa2a624e` | nodejs20.x | Create auth challenge | Cognito trigger |
| `amplify-login-custom-message-fa2a624e` | nodejs20.x | Custom auth messages | Cognito trigger |
| `amplify-login-verify-auth-challenge-e02d8782` | nodejs20.x | Verify auth challenge (alt) | Cognito trigger |
| `amplify-login-define-auth-challenge-e02d8782` | nodejs20.x | Define auth challenge (alt) | Cognito trigger |
| `amplify-login-create-auth-challenge-e02d8782` | nodejs20.x | Create auth challenge (alt) | Cognito trigger |
| `amplify-login-custom-message-e02d8782` | nodejs20.x | Custom auth message (alt) | Cognito trigger |

#### User Management Functions
| Function | Runtime | Purpose | API Endpoint |
|----------|---------|---------|--------------|
| `distrofm9c985681PreSignup-main` | nodejs18.x | Pre-signup processing | Cognito trigger |
| `distrofm9c985681PostConfirmation-main` | nodejs18.x | Post-confirmation processing | Cognito trigger |
| `distrofm9c985681PreSignup-dev` | nodejs18.x | Pre-signup (dev env) | Cognito trigger |
| `distrofm9c985681PostConfirmation-dev` | nodejs18.x | Post-confirmation (dev env) | Cognito trigger |
| `dn_update_user` | nodejs18.x | User data updates | `/update-dnfm-user` |
| `dn_users_list` | nodejs20.x | User listing operations | `/dn_users_list` |
| `dn_db_get_user` | nodejs18.x | User data retrieval | Internal |
| `dn_get_user_names` | nodejs18.x | User name lookup | Internal |

### 2. Analytics & External API Integration Services

#### Social Media Analytics
| Function | Runtime | Purpose | External API |
|----------|---------|---------|-------------|
| `dn_spotify_analytics` | nodejs18.x | Spotify data collection | Spotify Web API |
| `dn_tiktok_analytics` | nodejs18.x | TikTok analytics processing | TikTok API |
| `dn_yt_analytics_update` | nodejs18.x | YouTube analytics updates | YouTube Analytics API |
| `dn_lnvn_youtube_analytics_topvids` | nodejs18.x | Top videos analytics | YouTube API |
| `dn_social_analytics` | nodejs18.x | Consolidated social analytics | Multiple APIs |
| `dn_ig_fetch` | nodejs18.x | Instagram data fetching | Instagram API |

#### Media Processing Analytics
| Function | Runtime | Purpose | Data Source |
|----------|---------|---------|-------------|
| `dn_video_stats` | nodejs18.x | Video performance statistics | Internal DB |
| `dn_asset_report_stats` | nodejs18.x | Asset reporting statistics | Internal DB |
| `dnvideoreportprocess-dev` | nodejs18.x | Video report processing | Internal processing |

#### External API Management
| Function | Runtime | Purpose | API Integration |
|----------|---------|---------|----------------|
| `YouTube_API_Token` | nodejs18.x | YouTube API token management | YouTube API |
| `dn-youtube-token` | nodejs16.x | YouTube token (legacy) | YouTube API |
| `dn_channels_fetch` | nodejs18.x | Channel data fetching | Multiple platforms |
| `dn_get_channels` | nodejs18.x | Channel information retrieval | Internal DB |

### 3. Media & Content Management Services

#### Content Processing
| Function | Runtime | Purpose | Content Type |
|----------|---------|---------|--------------|
| `distrofmFetchYoutubeInfo-main` | nodejs18.x | YouTube content metadata | Video metadata |
| `distrofmFetchYTVideoInfo-main` | nodejs18.x | YouTube video information | Video data |
| `distrofmFetchArtistInfo-main` | nodejs18.x | Artist information retrieval | Artist data |
| `distrofmVideoUpdaterAirtableToGraphQL-main` | nodejs18.x | Video data synchronization | Video metadata |
| `distrofmAppendVideoAirtable-main` | nodejs18.x | Video record creation | Video records |
| `amplifydistrofmlikevideo-main` | nodejs18.x | Video interaction handling | User interactions |

#### Media Upload & Storage
| Function | Runtime | Purpose | Storage Target |
|----------|---------|---------|----------------|
| `distrofmAlbumFill-main` | nodejs18.x | Album metadata processing | Database |
| `amplifyDistroFMTrackAlbumFill-main` | nodejs18.x | Track/album data filling | Database |
| `amplifyDistroFMClaimsReportFill-main` | nodejs18.x | Claims report processing | Database |
| `amplifyDistroFMYoutubeChannelParse-main` | nodejs18.x | YouTube channel parsing | Database |

#### Content Management System
| Function | Runtime | Purpose | CMS Operation | Status |
|----------|---------|---------|---------------|---------|
| ~~`cmsCustomidCleanup-dev`~~ | ~~nodejs18.x~~ | ~~CMS custom ID cleanup~~ | ~~Data maintenance~~ | **Migrated to ECS** |
| `cmscustomidupdate-dev` | nodejs18.x | CMS custom ID updates | Data updates | Active |
| `dnbackendUpdateCMSCustomId-dev` | nodejs18.x | Backend CMS ID updates | Data synchronization | Active |
| `dnbackendUpdateChannelsCustomIds-dev` | nodejs18.x | Channel ID updates | Channel management | Active |

**Migration Note**: `cmsCustomidCleanup-dev` was migrated to ECS due to Lambda's 15-minute execution timeout limit. The function processes large datasets (38,000+ videos) requiring unlimited execution time.

### 4. Database & Data Management Services

#### Core Database Operations
| Function | Runtime | Purpose | Database |
|----------|---------|---------|----------|
| `POSTGRESQL_LAMBDA` | nodejs20.x | Primary PostgreSQL operations | Aurora PostgreSQL |
| `POSTGRESQL_DNFM_UPDATE` | nodejs20.x | DistroFM data updates | Aurora PostgreSQL |
| `lambda_scratch` | nodejs20.x | Database scratch operations | Aurora PostgreSQL |

#### Data Synchronization
| Function | Runtime | Purpose | Sync Target |
|----------|---------|---------|-------------|
| `amplify-dnbackendfunction-OpenSearchStreamingLambd-t1u7bDVoyMxM` | python3.8 | OpenSearch data streaming | ElasticSearch |
| `amplify-dnbackendfunction-OpenSearchStreamingLambd-wXlS5nEBCpTF` | python3.8 | OpenSearch streaming (alt) | ElasticSearch |
| `amplify-distrofm-main-db8-OpenSearchStreamingLambd-OEes1hTyGR9B` | python3.8 | DistroFM OpenSearch sync | ElasticSearch |

#### Data Processing & ETL
| Function | Runtime | Purpose | Data Flow |
|----------|---------|---------|-----------|
| `dn_master_list_update` | nodejs18.x | Master data list updates | Data consolidation |
| `dn_write_conflicts` | nodejs18.x | Conflict resolution | Data integrity |
| `dn_ct_update` | nodejs18.x | Catalog tool updates | Catalog management |
| `dn_ct_web_update` | nodejs18.x | Web catalog updates | Web interface |
| `dn_ct_asset_update` | nodejs18.x | Asset catalog updates | Asset management |
| `dn_ct_update_classification` | nodejs18.x | Classification updates | Data categorization |

### 5. Financial & Business Operations Services

#### Payout Management
| Function | Runtime | Purpose | API Endpoint |
|----------|---------|---------|--------------|
| `dn_payouts_fetch` | python3.12 | Payout data retrieval | `/dn_payouts_fetch` |
| `dn_payout_audit` | nodejs20.x | Payout auditing | `/payout-audit` |
| `dn_partner_list_korrect` | nodejs20.x | Partner list management | `/dn_partner_list_korrect` |

#### Reporting & Analytics
| Function | Runtime | Purpose | Report Type |
|----------|---------|---------|-------------|
| `dnbackendCatalogToolAirtableUpdate-dev` | nodejs18.x | Catalog tool reporting | Airtable sync |
| `dnbackendCatalogToolVideoReport-dev` | nodejs18.x | Video reporting | Video analytics |

### 6. Communication & Notification Services

#### Email Services
| Function | Runtime | Purpose | API Endpoint |
|----------|---------|---------|--------------|
| `DN_Send_Mail` | python3.12 | Email sending service | `/send-mail` |

#### Content Management
| Function | Runtime | Purpose | Content Type |
|----------|---------|---------|--------------|
| `dn_blog_pull` | nodejs18.x | Blog content retrieval | Blog posts |
| `dn_blog_update` | nodejs18.x | Blog content updates | Blog posts |
| `distrofmBlogUpdate-main` | nodejs18.x | DistroFM blog updates | Blog content |

### 7. Administrative & System Services

#### User Management
| Function | Runtime | Purpose | Admin Function |
|----------|---------|---------|----------------|
| `amplifyDistroFmArtistUpdateBulk-main` | nodejs18.x | Bulk artist updates | Artist management |
| `amplifyDistroFMArtistBioUpdate-main` | nodejs18.x | Artist bio updates | Profile management |
| `amplifyDistroFMArtistImageMod-main` | nodejs18.x | Artist image modification | Media management |
| `amplifyDistrofmUserImageUpdate-main` | nodejs20.x | User image updates | Profile images |

#### System Utilities
| Function | Runtime | Purpose | Utility Type | Status |
|----------|---------|---------|--------------|---------|
| `test` | python3.12 | Testing function | Development | Active |
| ~~`channelbackfill-dev`~~ | ~~nodejs18.x~~ | ~~Channel data backfill~~ | ~~Data migration~~ | **Migrated to ECS** |
| `dn_lnvn_shorts_backfill` | nodejs18.x | Shorts content backfill | Content migration | Active |
| `dn_lnvn_livestream_write` | nodejs18.x | Livestream data writing | Live content | Active |

**Migration Note**: `channelbackfill-dev` was migrated to ECS as part of the custom ID cleanup workflow. It triggers `cmsCustomidCleanup` via EventBridge after completion.

### 8. Infrastructure & Framework Services

#### Amplify Framework Functions
| Function | Runtime | Purpose | Framework Component |
|----------|---------|---------|-------------------|
| `amplify-distrofm-main-db8-UpdateRolesWithIDPFuncti-puW25nE7saZS` | nodejs18.x | IDP role updates | Identity management |
| `amplify-distrofm-dev-e443-UpdateRolesWithIDPFuncti-INcwy8evZKgT` | nodejs18.x | IDP role updates (dev) | Identity management |
| `amplify-dnbackendfunctions-PreDeployLambdaF7CAA99F-HH8WTe3h9Odb` | nodejs18.x | Pre-deployment tasks | CI/CD pipeline |
| `amplify-distrofm-main-db8f-PreDeployLambdaF7CAA99F-vUBscx7gGCbf` | nodejs18.x | Pre-deployment (main) | CI/CD pipeline |

#### Custom Resource Handlers
| Function | Runtime | Purpose | Resource Type |
|----------|---------|---------|---------------|
| `amplify-distrofm-main-db8-AwaiterCustomCompleteHan-W5LskNHq6IjZ` | nodejs18.x | Custom resource completion | CloudFormation |
| `amplify-distrofm-main-db8-AwaiterCustomEventHandle-DjUgUo8kqmPV` | nodejs18.x | Custom event handling | CloudFormation |
| `amplify-distrofm-main-db8-HostedUIProvidersCustomR-hQ1dqOwlfRgW` | nodejs18.x | Hosted UI customization | Authentication UI |

## Service Dependencies

### External API Dependencies
- **YouTube Data API v3**: Video metadata, analytics, channel information
- **Spotify Web API**: Artist data, track analytics, playlist information  
- **TikTok API**: Video analytics, user engagement metrics
- **Instagram Basic Display API**: Media fetching, user data
- **Airtable API**: Content management, reporting synchronization

### AWS Service Dependencies
- **Aurora PostgreSQL**: Primary database for all services
- **OpenSearch**: Search and analytics indexing
- **S3**: Media storage and file operations
- **Cognito**: User authentication and authorization
- **API Gateway**: HTTP endpoint exposure
- **CloudWatch**: Logging and monitoring
- **Amazon ECS**: Containerized task execution for long-running processes
- **Amazon ECR**: Container image storage and management
- **Amazon EventBridge**: Event-driven workflow orchestration

### Internal Service Communication
- **Database Layer**: PostgreSQL Lambda functions serve as data access layer
- **Authentication Layer**: Cognito triggers handle user lifecycle
- **Media Layer**: Content processing functions interact with storage services
- **Analytics Layer**: External API functions feed into reporting services

## Performance Characteristics

### Runtime Distribution
- **Node.js 18.x**: 52 functions (63%) - 2 migrated to ECS
- **Node.js 20.x**: 18 functions (22%)
- **Python 3.8**: 3 functions (4%)
- **Python 3.12**: 4 functions (5%)
- **Node.js 16.x**: 1 function (1%)
- **Unknown/None**: 4 functions (5%)
- **ECS Containers**: 2 tasks (2%) - channelbackfill, cmsCustomidCleanup

### Concurrency Patterns
- **High Concurrency**: Analytics and data processing functions
- **Medium Concurrency**: API endpoint handlers and user management
- **Low Concurrency**: Administrative and batch processing functions

### Memory and Timeout Configuration
- **Standard Timeout**: 29 seconds (API Gateway integration limit)
- **Memory Allocation**: Varies by function complexity (needs analysis)
- **Cold Start Optimization**: Node.js functions for faster startup

## Security Model

### IAM Roles and Permissions
- **Lambda Execution Roles**: Function-specific permissions
- **Database Access**: PostgreSQL connection permissions
- **External API Access**: Secrets Manager integration for API keys
- **S3 Access**: Bucket-specific read/write permissions

### Authentication Integration
- **Cognito Integration**: User pool triggers and custom auth flows
- **API Gateway Authorization**: IAM and custom authorizers
- **Internal Service Auth**: Service-to-service communication patterns

## Monitoring and Observability

### CloudWatch Integration
- **Metrics**: Duration, errors, invocations for all functions
- **Logs**: Structured logging patterns (needs standardization)
- **Alarms**: Error rate and duration thresholds (needs implementation)

### Distributed Tracing
- **X-Ray Integration**: Available but not consistently implemented
- **Correlation IDs**: Request tracking across service boundaries
- **Performance Monitoring**: End-to-end request tracing

## Recommendations for Empire Integration

### Immediate Actions
1. **Function Consolidation**: Review similar functions for consolidation opportunities
2. **Runtime Standardization**: Migrate older Node.js versions to latest LTS
3. **Monitoring Enhancement**: Implement consistent logging and metrics
4. **Documentation**: Create function-level API documentation

### Optimization Opportunities
1. **Right-sizing**: Analyze memory allocation and timeout settings
2. **Cold Start Reduction**: Implement provisioned concurrency for critical functions
3. **Code Sharing**: Extract common functionality into Lambda layers
4. **Error Handling**: Standardize error responses and retry logic

### Security Enhancements
1. **Secrets Management**: Centralize API key and credential management
2. **Network Security**: Implement VPC configuration where appropriate  
3. **Audit Logging**: Enhanced logging for security-sensitive operations
4. **Principle of Least Privilege**: Review and tighten IAM permissions