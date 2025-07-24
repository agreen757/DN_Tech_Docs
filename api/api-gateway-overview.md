# API Gateway Overview

## Summary
Distro Nation operates two primary API Gateways that serve different functional areas of the platform:

1. **dn-api** - Backend administrative functions and core platform operations
2. **distronationfmGeneralAccess** - DistroFM application-specific endpoints

## API Gateway Configuration

### dn-api (Core Platform API)
- **API ID**: <API_GATEWAY_ID_2>
- **Created**: February 8, 2024
- **Description**: Distro Nation Functional API. This API is used to launch back-end admin functions and tasks
- **Endpoint Type**: EDGE (CloudFront distribution)
- **Base URL**: `https://<API_GATEWAY_ID_2>.execute-api.<REGION>.amazonaws.com`
- **Deployment Stage**: `staging`
- **API Key Source**: HEADER
- **Root Resource ID**: bhwsy6typa

### distronationfmGeneralAccess (DistroFM API)
- **API ID**: <API_GATEWAY_ID_1>  
- **Created**: June 14, 2024
- **Version**: 2018-05-24T17:52:00Z
- **Endpoint Type**: EDGE (CloudFront distribution)
- **Base URL**: `https://<API_GATEWAY_ID_1>.execute-api.<REGION>.amazonaws.com`
- **Deployment Stage**: `main`
- **API Key Source**: HEADER
- **Root Resource ID**: vs4lq7ol18
- **CloudFormation Managed**: Yes (Amplify deployment)

## Endpoint Summary

### dn-api Endpoints
| Endpoint | Methods | Lambda Function | Purpose |
|----------|---------|-----------------|---------|
| `/channels` | POST | N/A | Channel management |
| `/update-dnfm-user` | POST | N/A | DistroFM user updates |
| `/dn_users_list` | ANY | dn_users_list | User listing operations |
| `/dn_payouts_fetch` | ANY | dn_payouts_fetch | Payout data retrieval |
| `/dn_partner_list_korrect` | GET, OPTIONS | dn_partner_list_korrect | Partner list management |
| `/payout-audit` | POST | dn_payout_audit | Payout auditing |
| `/hollow` | GET, OPTIONS | N/A | Health check/placeholder |
| `/send-mail` | POST, OPTIONS | DN_Send_Mail | Email notifications |
| `/ikey` | GET, PUT, OPTIONS | N/A | API key management |

### distronationfmGeneralAccess Endpoints
| Endpoint | Methods | Lambda Function | Purpose |
|----------|---------|-----------------|---------|
| `/artist-info/{id}` | ANY, OPTIONS | distrofmFetchArtistInfo-main | Artist information retrieval |
| `/artist-info/{id}/{proxy+}` | ANY, OPTIONS | distrofmFetchArtistInfo-main | Artist info with proxy paths |
| `/submit-video` | ANY, OPTIONS | N/A | Video submission |
| `/submit-video/{proxy+}` | ANY, OPTIONS | N/A | Video submission with proxy |
| `/parse/{id}` | ANY, OPTIONS | N/A | Content parsing |
| `/parse/{id}/{proxy+}` | ANY, OPTIONS | N/A | Content parsing with proxy |
| `/evalvideoid/{id}` | ANY, OPTIONS | N/A | Video ID evaluation |
| `/evalvideoid/{id}/{proxy+}` | ANY, OPTIONS | N/A | Video ID evaluation with proxy |

## Authentication & Authorization

### dn-api
- **Authorization Type**: NONE (most endpoints)
- **API Key Required**: false
- **CORS**: Enabled on most endpoints
- **Rate Limiting**: Not explicitly configured

### distronationfmGeneralAccess  
- **Authorization Type**: AWS_IAM
- **API Key Required**: false
- **CORS**: Enabled on all endpoints
- **Rate Limiting**: Configured
  - **Burst Limit**: 5,000 requests
  - **Rate Limit**: 10,000 requests/second
- **Logging Level**: INFO
- **Data Trace**: Enabled

## Integration Patterns

### Lambda Proxy Integration
Both APIs primarily use **AWS_PROXY** integration pattern:
- Direct Lambda function invocation
- 29-second timeout
- Pass-through behavior for unmatched requests
- Standard HTTP response codes

### CORS Configuration
- **Access-Control-Allow-Origin**: '*' (wildcard)
- **OPTIONS** methods implemented for preflight requests
- Standard CORS headers in responses

## Data Models

### dn-api Models
- **Empty**: Default empty schema for simple responses
- **Error**: Standard error response schema with message field

### distronationfmGeneralAccess Models
- **RequestSchema**: Simple request wrapper with required "request" string field
- **ResponseSchema**: Simple response wrapper with required "response" string field

## Deployment & Environments

### dn-api Deployment
- **Stage**: staging
- **Deployment ID**: mejmls
- **Cache**: Enabled via stage variable (`apiCache: true`)
- **Created**: February 9, 2024
- **Last Updated**: May 10, 2024

### distronationfmGeneralAccess Deployment
- **Stage**: main
- **Deployment ID**: x4418m
- **Cache**: TTL 300 seconds, disabled by default
- **CloudFormation Stack**: amplify-distrofm-main-db8f9
- **Created**: June 14, 2024
- **Last Updated**: October 9, 2024

## Architecture Characteristics

### Performance
- **Edge-optimized**: Both APIs use CloudFront for global distribution
- **Caching**: Configurable at method level
- **Timeout**: 29-second Lambda timeout for all integrations

### Monitoring
- **CloudWatch Integration**: Automatic metrics and logging
- **X-Ray Tracing**: Available but not explicitly enabled
- **Data Tracing**: Enabled on distronationfmGeneralAccess

### Security
- **TLS**: HTTPS only via API Gateway
- **IAM Integration**: AWS_IAM auth on distronationfmGeneralAccess
- **API Keys**: Header-based key source (not required)

## Usage Patterns

### dn-api Usage
- **Administrative Functions**: User management, payouts, partner operations
- **Backend Operations**: Email sending, data auditing
- **Internal Tools**: API key management, system health checks

### distronationfmGeneralAccess Usage
- **Content Operations**: Artist info, video processing
- **Media Analysis**: Video ID evaluation, content parsing
- **User-Facing Features**: Video submission, content management

## Integration Recommendations

### For Empire Distribution
1. **Authentication Migration**: Consider consolidating auth patterns
2. **Rate Limiting**: Implement consistent rate limiting across both APIs
3. **Monitoring**: Enable X-Ray tracing for better observability
4. **Documentation**: Generate OpenAPI specs for developer onboarding
5. **Testing**: Implement automated API testing for critical endpoints

### Security Enhancements
1. **API Keys**: Consider requiring API keys for administrative functions
2. **Request Validation**: Implement request schema validation
3. **Response Filtering**: Add response filtering for sensitive data
4. **Audit Logging**: Enhanced logging for administrative operations