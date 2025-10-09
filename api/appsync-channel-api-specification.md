# AppSync Channel API Specification

## Overview
The AppSync Channel API provides secure, external access to Distro Nation's channel and video data through a REST API interface. This service acts as a controlled gateway to the internal AppSync GraphQL API, enabling external applications to access channel information without exposing the main GraphQL endpoint.

## Architecture

### Security Model
```
External App → Client API Key → Lambda Function → AppSync API Key → AppSync/DynamoDB
```

The API implements a two-layer security approach:
1. **Client Authentication**: External applications authenticate using client API keys
2. **Internal Authentication**: Lambda function uses managed AppSync API keys for internal operations

### Infrastructure Components
- **API Gateway**: REST endpoint exposure with CORS and throttling
- **Lambda Function**: Request processing and GraphQL integration
- **SSM Parameter Store**: Secure API key management
- **AppSync GraphQL API**: Internal data access layer
- **DynamoDB**: Data persistence layer

## API Endpoints

### Base URL
```
https://api.distronation.com/channels
```

### Authentication
All requests require a valid client API key in the header:
```
X-API-Key: your-client-api-key
```

### Endpoints

#### 1. List All Channels
```http
GET /channels
```

**Description**: Retrieve all partner channels with pagination support.

**Query Parameters**:
- `limit` (optional): Number of results per page (default: 50, max: 100)
- `nextToken` (optional): Pagination token for subsequent pages

**Response**:
```json
{
  "data": {
    "channels": [
      {
        "id": "channel-uuid",
        "channelId": "youtube-channel-id",
        "customId": "custom-identifier",
        "displayName": "Channel Display Name",
        "createdAt": "2024-01-15T10:30:00Z",
        "updatedAt": "2024-01-15T10:30:00Z"
      }
    ],
    "nextToken": "pagination-token",
    "totalCount": 150
  },
  "status": "success",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

#### 2. Get Channel by ID
```http
GET /channels/{channelId}
```

**Description**: Retrieve a specific channel by its unique identifier.

**Path Parameters**:
- `channelId`: The unique channel identifier

**Response**:
```json
{
  "data": {
    "channel": {
      "id": "channel-uuid",
      "channelId": "youtube-channel-id",
      "customId": "custom-identifier",
      "displayName": "Channel Display Name",
      "createdAt": "2024-01-15T10:30:00Z",
      "updatedAt": "2024-01-15T10:30:00Z"
    }
  },
  "status": "success",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

#### 3. Search Channels by Custom ID
```http
GET /channels/search?customId={customId}
```

**Description**: Find channels by their custom identifier.

**Query Parameters**:
- `customId`: The custom identifier to search for

**Response**:
```json
{
  "data": {
    "channels": [
      {
        "id": "channel-uuid",
        "channelId": "youtube-channel-id",
        "customId": "custom-identifier",
        "displayName": "Channel Display Name",
        "createdAt": "2024-01-15T10:30:00Z",
        "updatedAt": "2024-01-15T10:30:00Z"
      }
    ]
  },
  "status": "success",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

#### 4. Get Custom IDs List
```http
GET /channels/custom-ids
```

**Description**: Retrieve a list of all custom IDs for batch processing operations.

**Query Parameters**:
- `format` (optional): Response format (`json` or `csv`, default: `json`)
- `limit` (optional): Number of results per page (default: 1000, max: 5000)

**Response (JSON)**:
```json
{
  "data": {
    "customIds": [
      "custom-id-1",
      "custom-id-2",
      "custom-id-3"
    ],
    "totalCount": 150
  },
  "status": "success",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**Response (CSV)**:
```csv
customId
custom-id-1
custom-id-2
custom-id-3
```

#### 5. Health Check
```http
GET /channels/health
```

**Description**: API health and status endpoint.

**Response**:
```json
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

## Error Responses

### Standard Error Format
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": "Additional error context"
  },
  "status": "error",
  "timestamp": "2024-01-15T10:30:00Z",
  "requestId": "unique-request-identifier"
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_API_KEY` | 401 | Invalid or missing client API key |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `CHANNEL_NOT_FOUND` | 404 | Requested channel does not exist |
| `INVALID_PARAMETERS` | 400 | Invalid request parameters |
| `INTERNAL_ERROR` | 500 | Internal server error |
| `SERVICE_UNAVAILABLE` | 503 | Downstream service unavailable |

## Rate Limiting

### Default Limits
- **Per API Key**: 1000 requests per hour
- **Burst Capacity**: 100 requests per minute
- **Global Limit**: 10,000 requests per hour

### Rate Limit Headers
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1642248600
```

## Client Integration

### Node.js Example
```javascript
const axios = require('axios');

class ChannelAPIClient {
  constructor(apiKey, baseURL = 'https://api.distronation.com/channels') {
    this.apiKey = apiKey;
    this.baseURL = baseURL;
    this.client = axios.create({
      baseURL: this.baseURL,
      headers: {
        'X-API-Key': this.apiKey,
        'Content-Type': 'application/json'
      }
    });
  }

  async getAllChannels(limit = 50, nextToken = null) {
    const params = { limit };
    if (nextToken) params.nextToken = nextToken;
    
    const response = await this.client.get('/channels', { params });
    return response.data;
  }

  async getChannel(channelId) {
    const response = await this.client.get(`/channels/${channelId}`);
    return response.data;
  }

  async searchByCustomId(customId) {
    const response = await this.client.get('/channels/search', {
      params: { customId }
    });
    return response.data;
  }

  async getCustomIds(format = 'json') {
    const response = await this.client.get('/channels/custom-ids', {
      params: { format }
    });
    return response.data;
  }

  async healthCheck() {
    const response = await this.client.get('/channels/health');
    return response.data;
  }
}

// Usage
const client = new ChannelAPIClient('your-api-key');
const channels = await client.getAllChannels();
```

### Python Example
```python
import requests
from typing import Optional, Dict, Any

class ChannelAPIClient:
    def __init__(self, api_key: str, base_url: str = "https://api.distronation.com/channels"):
        self.api_key = api_key
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            'X-API-Key': api_key,
            'Content-Type': 'application/json'
        })

    def get_all_channels(self, limit: int = 50, next_token: Optional[str] = None) -> Dict[str, Any]:
        params = {'limit': limit}
        if next_token:
            params['nextToken'] = next_token
        
        response = self.session.get(f"{self.base_url}/channels", params=params)
        response.raise_for_status()
        return response.json()

    def get_channel(self, channel_id: str) -> Dict[str, Any]:
        response = self.session.get(f"{self.base_url}/channels/{channel_id}")
        response.raise_for_status()
        return response.json()

    def search_by_custom_id(self, custom_id: str) -> Dict[str, Any]:
        params = {'customId': custom_id}
        response = self.session.get(f"{self.base_url}/channels/search", params=params)
        response.raise_for_status()
        return response.json()

    def get_custom_ids(self, format_type: str = 'json') -> Dict[str, Any]:
        params = {'format': format_type}
        response = self.session.get(f"{self.base_url}/channels/custom-ids", params=params)
        response.raise_for_status()
        return response.json()

    def health_check(self) -> Dict[str, Any]:
        response = self.session.get(f"{self.base_url}/channels/health")
        response.raise_for_status()
        return response.json()

# Usage
client = ChannelAPIClient('your-api-key')
channels = client.get_all_channels()
```

### cURL Examples
```bash
# Get all channels
curl -H "X-API-Key: your-api-key" \
     "https://api.distronation.com/channels"

# Get specific channel
curl -H "X-API-Key: your-api-key" \
     "https://api.distronation.com/channels/channel-id"

# Search by custom ID
curl -H "X-API-Key: your-api-key" \
     "https://api.distronation.com/channels/search?customId=custom-123"

# Get custom IDs as CSV
curl -H "X-API-Key: your-api-key" \
     "https://api.distronation.com/channels/custom-ids?format=csv"

# Health check
curl -H "X-API-Key: your-api-key" \
     "https://api.distronation.com/channels/health"
```

## Monitoring and Observability

### CloudWatch Metrics
- **Request Count**: Total API requests per endpoint
- **Error Rate**: Percentage of failed requests
- **Response Time**: Average and P99 response times
- **Throttling**: Rate limit violations
- **Authentication Failures**: Invalid API key attempts

### CloudWatch Logs
- **Request Logs**: All API requests with sanitized parameters
- **Error Logs**: Detailed error information and stack traces
- **Audit Logs**: API key usage and authentication events
- **Performance Logs**: Response times and resource utilization

### Alarms
- **High Error Rate**: > 5% error rate over 5 minutes
- **High Response Time**: > 2 seconds average over 5 minutes
- **API Key Failures**: > 10 authentication failures per minute
- **Service Unavailable**: AppSync or DynamoDB connectivity issues

## Security Considerations

### API Key Management
- **Rotation**: Client API keys should be rotated every 90 days
- **Scope**: Keys are scoped to specific operations and rate limits
- **Monitoring**: All API key usage is logged and monitored
- **Revocation**: Keys can be immediately revoked if compromised

### Data Protection
- **Encryption in Transit**: All API communications use HTTPS/TLS 1.2+
- **Encryption at Rest**: Data stored in DynamoDB is encrypted
- **No Sensitive Data**: API responses contain no sensitive information
- **Audit Trail**: All data access is logged for compliance

### Network Security
- **CORS**: Configured for specific allowed origins
- **IP Allowlisting**: Optional IP-based access restrictions
- **DDoS Protection**: AWS Shield Standard protection
- **WAF Integration**: Web Application Firewall for additional protection

## Compliance and Governance

### Data Handling
- **Data Minimization**: Only necessary data is exposed via API
- **Retention**: API logs retained for 90 days
- **Access Control**: Role-based access to API management
- **Audit Requirements**: All access logged for compliance

### SLA and Support
- **Availability**: 99.9% uptime SLA
- **Response Time**: < 500ms average response time
- **Support**: Business hours support for API issues
- **Documentation**: Comprehensive API documentation and examples

## Deployment Information

### Environment Details
- **Production URL**: `https://api.distronation.com/channels`
- **Staging URL**: `https://staging-api.distronation.com/channels`
- **Version**: 1.0.0
- **Deployment Date**: January 2024
- **Last Updated**: January 2024

### Infrastructure
- **AWS Region**: Primary deployment region
- **Lambda Runtime**: Node.js 20.x
- **API Gateway**: REST API with custom domain
- **Monitoring**: CloudWatch integration
- **Backup**: Automated daily backups

### Change Management
- **Version Control**: All changes tracked in version control
- **Testing**: Comprehensive test suite for all endpoints
- **Deployment**: Automated CI/CD pipeline
- **Rollback**: Automated rollback capability for issues

## Future Enhancements

### Planned Features
- **Webhook Support**: Real-time notifications for channel updates
- **Batch Operations**: Bulk channel operations for efficiency
- **Advanced Filtering**: Enhanced search and filtering capabilities
- **GraphQL Endpoint**: Optional GraphQL interface for advanced users

### Performance Improvements
- **Caching**: Response caching for frequently accessed data
- **CDN Integration**: Global content delivery for improved performance
- **Connection Pooling**: Optimized database connections
- **Compression**: Response compression for reduced bandwidth

### Security Enhancements
- **OAuth 2.0**: Advanced authentication options
- **Field-Level Encryption**: Additional data protection
- **Advanced Monitoring**: Enhanced security monitoring and alerting
- **Compliance**: Additional compliance certifications