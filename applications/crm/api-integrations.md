# Distro Nation CRM API Integrations

## Overview
The Distro Nation CRM integrates with multiple APIs to provide comprehensive functionality for email campaigns, user management, content generation, and analytics. This document details all API integrations, authentication methods, usage patterns, and implementation specifics.

## Recent Updates

### CloudFront Signed URLs Implementation (August 12, 2025)
**Major Enhancement**: Replaced email attachments with secure CloudFront signed URLs for financial report distribution.

**Benefits Achieved**:
- ✅ **50% faster Lambda execution** (no S3 file downloads)
- ✅ **70% less memory usage** (no file attachment processing)  
- ✅ **25-day secure access** (extended from 7-day S3 limit)
- ✅ **Global CDN performance** (CloudFront edge locations)
- ✅ **Smaller email size** (links instead of attachments)

### SES Unsubscribe Infrastructure (November 14, 2025)
**Status**: 100% complete (Task Master tag `email_unsubscribe_feature`, 11/11 deliverables shipped across infrastructure, Lambdas, and UI)

- ✅ Terraform now provisions the shared SES contact list, DynamoDB audit log, and dedicated KMS alias powering encrypted unsubscribe tokens.
- ✅ Shared Lambda layer `unsubscribe-utils-layer` exposes contact list utilities, encryption helpers, and Firebase-authenticated handlers for both finance and outreach stacks.
- ✅ `/outreach/unsubscribe`, `/financial/unsubscribe`, and `/financial/add-contact` endpoints are live with GET (302 → CRM UI) and POST (List-Unsubscribe=One-Click) flows plus mailto/SNS ingestion.
- ✅ Outreach and Finance SES senders automatically gate sends on contact status, attach dual `List-Unsubscribe` headers, and append branded unsubscribe footer + text copy.
- ✅ CRM now includes `/unsubscribe` confirmation + resubscribe UI that calls the add-contact API for reinstatement and preference management.

## AWS API Gateway Integration

### dn-api Core Integration
**Base URL**: `https://<API_GATEWAY_ID_2>.execute-api.<REGION>.amazonaws.com/staging`  
**Authentication**: API Key via `x-api-key` header  
**Configuration Location**: `src/config/api.config.ts`

### Outreach API Integration (NEW)
**Base URL**: `https://<OUTREACH_API_GATEWAY_ID>.execute-api.<REGION>.amazonaws.com/dev`  
**Authentication**: JWT Bearer Token via `Authorization` header  
**Service**: `payouts-mailer-outreach`  
**Configuration Location**: `lambda/outreach/serverless.yml`

#### Outreach API Endpoints

##### `/outreach/send-email` - Direct Email Sending
**Method**: POST  
**Purpose**: Send individual emails via Mailgun with full customization  
**Lambda Function**: `sendEmail` (Node.js 18.x)  
**Authentication**: Required (JWT Bearer Token)

**Request Payload**:
```typescript
interface SendEmailRequest {
  to: string | string[];
  subject: string;
  html?: string;
  text?: string;
  from?: string;
  replyTo?: string;
  tags?: string[];
  customVariables?: Record<string, string>;
  trackingSettings?: {
    opens: boolean;
    clicks: boolean;
    unsubscribes: boolean;
  };
}
```

**Example Request**:
```bash
curl -X POST https://your-api-gateway-url/dev/outreach/send-email \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "to": ["recipient@example.com"],
    "subject": "Welcome to Our Platform",
    "html": "<h1>Welcome!</h1><p>Thank you for joining us.</p>",
    "text": "Welcome! Thank you for joining us.",
    "from": "noreply@yourdomain.com",
    "tags": ["welcome", "onboarding"],
    "trackingSettings": {
      "opens": true,
      "clicks": true,
      "unsubscribes": true
    }
  }'
```

**Response**:
```typescript
interface SendEmailResponse {
  success: boolean;
  messageId?: string;
  message: string;
  data?: {
    id: string;
    message: string;
  };
  timestamp: string;
  version: string;
}
```

**Example Response**:
```json
{
  "success": true,
  "message": "Email sent successfully",
  "messageId": "20231024.1234567890.abcdef@mg.yourdomain.com",
  "data": {
    "id": "20231024.1234567890.abcdef@mg.yourdomain.com",
    "message": "Queued. Thank you."
  },
  "timestamp": "2023-10-24T15:30:45.123Z",
  "version": "1.0.0"
}
```

**Error Responses**:
```json
// 400 Bad Request
{
  "success": false,
  "error": "Either text or html content is required",
  "timestamp": "2023-10-24T15:30:45.123Z",
  "version": "1.0.0"
}

// 401 Unauthorized
{
  "success": false,
  "error": "Authorization token is required",
  "timestamp": "2023-10-24T15:30:45.123Z",
  "version": "1.0.0"
}

// 403 Forbidden
{
  "success": false,
  "error": "Email verification required for outreach operations",
  "timestamp": "2023-10-24T15:30:45.123Z",
  "version": "1.0.0"
}
```

##### `/outreach/send-template-email` - Template-Based Email Sending
**Method**: POST  
**Purpose**: Send emails using predefined Mailgun templates  
**Lambda Function**: `sendTemplateEmail` (Node.js 18.x)  
**Authentication**: Required (JWT Bearer Token)

**Request Payload**:
```typescript
interface SendTemplateEmailRequest {
  to: string | string[];
  template: string;
  subject?: string;
  templateVariables?: Record<string, any>;
  from?: string;
  replyTo?: string;
  tags?: string[];
  trackingSettings?: {
    opens: boolean;
    clicks: boolean;
    unsubscribes: boolean;
  };
}
```

**Example Request**:
```bash
curl -X POST https://your-api-gateway-url/dev/outreach/send-template-email \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "to": ["user@example.com"],
    "template": "welcome-template",
    "templateVariables": {
      "user_name": "John Doe",
      "company_name": "Acme Corp",
      "activation_link": "https://yourapp.com/activate/abc123"
    },
    "tags": ["template", "welcome"],
    "trackingSettings": {
      "opens": true,
      "clicks": true,
      "unsubscribes": true
    }
  }'
```

**Example Response**:
```json
{
  "success": true,
  "message": "Template email sent successfully",
  "messageId": "20231024.1234567890.template@mg.yourdomain.com",
  "data": {
    "id": "20231024.1234567890.template@mg.yourdomain.com",
    "message": "Queued. Thank you."
  },
  "timestamp": "2023-10-24T15:35:12.456Z",
  "version": "1.0.0"
}
```

##### `/outreach/campaign-stats` - Campaign Analytics
**Method**: GET  
**Purpose**: Retrieve campaign performance metrics and statistics  
**Lambda Function**: `campaignStats` (Node.js 18.x)  
**Authentication**: Required (JWT Bearer Token)

**Query Parameters**:
```typescript
interface CampaignStatsQuery {
  campaignId?: string;
  startDate?: string; // ISO 8601 format
  endDate?: string;   // ISO 8601 format
  tags?: string[];
  limit?: number;
  offset?: number;
}
```

**Example Request**:
```bash
curl -X GET "https://your-api-gateway-url/dev/outreach/campaign-stats?startDate=2023-10-01T00:00:00Z&endDate=2023-10-31T23:59:59Z&limit=100" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

**Response**:
```typescript
interface CampaignStatsResponse {
  success: boolean;
  data: {
    totalSent: number;
    delivered: number;
    opens: number;
    clicks: number;
    bounces: number;
    complaints: number;
    unsubscribes: number;
    deliveryRate: number;
    openRate: number;
    clickRate: number;
    campaigns: CampaignMetrics[];
  };
  timestamp: string;
  version: string;
}
```

**Example Response**:
```json
{
  "success": true,
  "data": {
    "totalSent": 1250,
    "delivered": 1198,
    "opens": 456,
    "clicks": 89,
    "bounces": 32,
    "complaints": 2,
    "unsubscribes": 18,
    "deliveryRate": 95.84,
    "openRate": 38.06,
    "clickRate": 19.52,
    "campaigns": [
      {
        "name": "welcome-series",
        "sent": 500,
        "delivered": 485,
        "opens": 195,
        "clicks": 42
      },
      {
        "name": "newsletter-oct",
        "sent": 750,
        "delivered": 713,
        "opens": 261,
        "clicks": 47
      }
    ]
  },
  "timestamp": "2023-10-24T15:40:30.789Z",
  "version": "1.0.0"
}
```

##### `/outreach/tracking-data` - Message Tracking Information
**Method**: GET  
**Purpose**: Retrieve detailed tracking data for sent messages  
**Lambda Function**: `trackingData` (Node.js 18.x)  
**Authentication**: Required (JWT Bearer Token)

**Query Parameters**:
```typescript
interface TrackingDataQuery {
  messageId?: string;
  recipientEmail?: string;
  startDate?: string;
  endDate?: string;
  eventType?: 'delivered' | 'opened' | 'clicked' | 'bounced' | 'complained' | 'unsubscribed';
  limit?: number;
  offset?: number;
}
```

**Example Request**:
```bash
curl -X GET "https://your-api-gateway-url/dev/outreach/tracking-data?recipientEmail=user@example.com&eventType=opened&limit=50" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

**Example Response**:
```json
{
  "success": true,
  "data": {
    "events": [
      {
        "messageId": "20231024.1234567890.abcdef@mg.yourdomain.com",
        "event": "delivered",
        "timestamp": "2023-10-24T15:30:45.123Z",
        "recipient": "user@example.com",
        "tags": ["welcome", "onboarding"],
        "deliveryStatus": {
          "code": 250,
          "message": "OK",
          "description": "Message delivered successfully"
        }
      },
      {
        "messageId": "20231024.1234567890.abcdef@mg.yourdomain.com",
        "event": "opened",
        "timestamp": "2023-10-24T16:15:22.456Z",
        "recipient": "user@example.com",
        "clientInfo": {
          "clientName": "Gmail",
          "clientOs": "Windows",
          "deviceType": "desktop"
        },
        "geolocation": {
          "country": "US",
          "region": "CA",
          "city": "San Francisco"
        }
      }
    ],
    "pagination": {
      "total": 2,
      "limit": 50,
      "offset": 0,
      "hasMore": false
    }
  },
  "timestamp": "2023-10-24T16:20:15.789Z",
  "version": "1.0.0"
}
```

##### `/outreach/webhook` - Mailgun Event Webhooks
**Method**: POST  
**Purpose**: Receive and process Mailgun webhook events  
**Lambda Function**: `webhookHandler` (Node.js 18.x)  
**Authentication**: Mailgun signature verification (no CORS)  
**Note**: Server-to-server communication only

**Webhook Configuration**:
```bash
# Configure in Mailgun Dashboard
Webhook URL: https://your-api-gateway-url/dev/outreach/webhook
Events: delivered, opened, clicked, bounced, complained, unsubscribed
HTTP Method: POST
```

**Example Webhook Payload** (from Mailgun):
```json
{
  "signature": {
    "timestamp": "1698156045",
    "token": "abc123def456",
    "signature": "d2b1c8f9e3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0"
  },
  "event-data": {
    "event": "delivered",
    "timestamp": 1698156045.123,
    "id": "unique-event-id-12345",
    "message": {
      "headers": {
        "message-id": "20231024.1234567890.abcdef@mg.yourdomain.com",
        "to": "user@example.com",
        "from": "noreply@yourdomain.com",
        "subject": "Welcome to Our Platform"
      }
    },
    "recipient": "user@example.com",
    "domain": "yourdomain.com",
    "tags": ["welcome", "onboarding"],
    "delivery-status": {
      "attempt-no": 1,
      "message": "OK",
      "code": 250,
      "description": "Message delivered successfully"
    }
  }
}
```

**Webhook Response**:
```json
{
  "success": true,
  "message": "Webhook processed successfully",
  "eventId": "unique-event-id-12345",
  "eventType": "delivered",
  "timestamp": "2023-10-24T15:30:45.123Z",
  "version": "1.0.0"
}
```

**Security Features**:
- HMAC-SHA256 signature verification
- Timestamp validation to prevent replay attacks
- Required signature headers validation
- Timing-safe signature comparison

### OpenAPI Specification

**Complete OpenAPI 3.0 Specification for Outreach API:**

```yaml
openapi: 3.0.3
info:
  title: Distro Nation CRM Outreach API
  description: Secure REST API for email outreach operations via Mailgun integration
  version: 1.0.0
  contact:
    name: API Support
    email: support@distro-nation.com

servers:
  - url: https://your-api-gateway-url/dev
    description: Development server
  - url: https://your-api-gateway-url/prod
    description: Production server

security:
  - BearerAuth: []

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: Firebase JWT token

  schemas:
    SendEmailRequest:
      type: object
      required:
        - to
        - subject
      properties:
        to:
          oneOf:
            - type: string
              format: email
            - type: array
              items:
                type: string
                format: email
        subject:
          type: string
          maxLength: 998
        html:
          type: string
        text:
          type: string
        from:
          type: string
          format: email
        replyTo:
          type: string
          format: email
        tags:
          type: array
          items:
            type: string
        customVariables:
          type: object
          additionalProperties:
            type: string
        trackingSettings:
          type: object
          properties:
            opens:
              type: boolean
            clicks:
              type: boolean
            unsubscribes:
              type: boolean

    SendTemplateEmailRequest:
      type: object
      required:
        - to
        - template
      properties:
        to:
          oneOf:
            - type: string
              format: email
            - type: array
              items:
                type: string
                format: email
        template:
          type: string
        subject:
          type: string
        templateVariables:
          type: object
          additionalProperties: true
        from:
          type: string
          format: email
        replyTo:
          type: string
          format: email
        tags:
          type: array
          items:
            type: string
        trackingSettings:
          type: object
          properties:
            opens:
              type: boolean
            clicks:
              type: boolean
            unsubscribes:
              type: boolean

    EmailResponse:
      type: object
      properties:
        success:
          type: boolean
        message:
          type: string
        messageId:
          type: string
        data:
          type: object
          properties:
            id:
              type: string
            message:
              type: string
        timestamp:
          type: string
          format: date-time
        version:
          type: string

    CampaignStatsResponse:
      type: object
      properties:
        success:
          type: boolean
        data:
          type: object
          properties:
            totalSent:
              type: integer
            delivered:
              type: integer
            opens:
              type: integer
            clicks:
              type: integer
            bounces:
              type: integer
            complaints:
              type: integer
            unsubscribes:
              type: integer
            deliveryRate:
              type: number
              format: float
            openRate:
              type: number
              format: float
            clickRate:
              type: number
              format: float
            campaigns:
              type: array
              items:
                type: object
        timestamp:
          type: string
          format: date-time
        version:
          type: string

    ErrorResponse:
      type: object
      properties:
        success:
          type: boolean
          example: false
        error:
          type: string
        timestamp:
          type: string
          format: date-time
        version:
          type: string

paths:
  /outreach/send-email:
    post:
      summary: Send individual email
      description: Send a single email or bulk emails via Mailgun
      tags:
        - Email Sending
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/SendEmailRequest'
      responses:
        '200':
          description: Email sent successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/EmailResponse'
        '400':
          description: Bad request - validation error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '401':
          description: Unauthorized - invalid or missing token
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '403':
          description: Forbidden - insufficient permissions
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'

  /outreach/send-template-email:
    post:
      summary: Send template-based email
      description: Send emails using predefined Mailgun templates
      tags:
        - Email Sending
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/SendTemplateEmailRequest'
      responses:
        '200':
          description: Template email sent successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/EmailResponse'
        '400':
          description: Bad request - validation error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '401':
          description: Unauthorized - invalid or missing token
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '403':
          description: Forbidden - insufficient permissions
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'

  /outreach/campaign-stats:
    get:
      summary: Get campaign statistics
      description: Retrieve campaign performance metrics and analytics
      tags:
        - Analytics
      parameters:
        - name: campaignId
          in: query
          description: Specific campaign ID to filter by
          schema:
            type: string
        - name: startDate
          in: query
          description: Start date for statistics (ISO 8601)
          schema:
            type: string
            format: date-time
        - name: endDate
          in: query
          description: End date for statistics (ISO 8601)
          schema:
            type: string
            format: date-time
        - name: limit
          in: query
          description: Maximum number of results
          schema:
            type: integer
            minimum: 1
            maximum: 1000
            default: 100
        - name: offset
          in: query
          description: Number of results to skip
          schema:
            type: integer
            minimum: 0
            default: 0
      responses:
        '200':
          description: Campaign statistics retrieved successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/CampaignStatsResponse'
        '401':
          description: Unauthorized - invalid or missing token
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '403':
          description: Forbidden - insufficient permissions
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'

  /outreach/tracking-data:
    get:
      summary: Get message tracking data
      description: Retrieve detailed tracking information for sent messages
      tags:
        - Analytics
      parameters:
        - name: messageId
          in: query
          description: Specific message ID to track
          schema:
            type: string
        - name: recipientEmail
          in: query
          description: Filter by recipient email address
          schema:
            type: string
            format: email
        - name: eventType
          in: query
          description: Filter by event type
          schema:
            type: string
            enum: [delivered, opened, clicked, bounced, complained, unsubscribed]
        - name: startDate
          in: query
          description: Start date for tracking data (ISO 8601)
          schema:
            type: string
            format: date-time
        - name: endDate
          in: query
          description: End date for tracking data (ISO 8601)
          schema:
            type: string
            format: date-time
        - name: limit
          in: query
          description: Maximum number of results
          schema:
            type: integer
            minimum: 1
            maximum: 1000
            default: 100
        - name: offset
          in: query
          description: Number of results to skip
          schema:
            type: integer
            minimum: 0
            default: 0
      responses:
        '200':
          description: Tracking data retrieved successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                  data:
                    type: object
                    properties:
                      events:
                        type: array
                        items:
                          type: object
                      pagination:
                        type: object
                  timestamp:
                    type: string
                    format: date-time
                  version:
                    type: string
        '401':
          description: Unauthorized - invalid or missing token
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'

  /outreach/webhook:
    post:
      summary: Mailgun webhook endpoint
      description: Receive and process Mailgun webhook events (server-to-server only)
      tags:
        - Webhooks
      security: []  # No JWT auth - uses Mailgun signature verification
      requestBody:
        required: true
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: Webhook processed successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                  message:
                    type: string
                  eventId:
                    type: string
                  eventType:
                    type: string
                  timestamp:
                    type: string
                    format: date-time
                  version:
                    type: string
        '400':
          description: Bad request - invalid webhook payload
        '401':
          description: Unauthorized - invalid webhook signature
```

### API Testing and Validation

**Postman Collection**: Available for download with pre-configured requests and environment variables

**Testing Checklist**:
- [ ] Authentication with valid JWT tokens
- [ ] Authentication rejection with invalid tokens
- [ ] CORS headers present in all responses
- [ ] Rate limiting enforcement
- [ ] Input validation for all endpoints
- [ ] Error response format consistency
- [ ] Webhook signature verification
- [ ] Email delivery confirmation via Mailgun

**Environment Variables for Testing**:
```bash
# Base URL
API_BASE_URL=https://your-api-gateway-url/dev

# Authentication
JWT_TOKEN=your_firebase_jwt_token_here

# Test Data
TEST_EMAIL=test@example.com
TEST_TEMPLATE=welcome-template
```

**Throttling Limits**:
- **Send Operations**: 50 burst, 25 requests/second (rate-limited for email sending)
- **Read Operations**: 100 burst, 50 requests/second (more permissive for analytics)
- **Webhook Endpoint**: 200 burst, 100 requests/second (high volume expected)
- **Global Limits**: 200 burst, 100 requests/second with 10,000 daily quota

**CORS Configuration**:
```yaml
cors:
  origin: ${env:CORS_ALLOWED_ORIGINS, 'http://localhost:3000'}
  headers:
    - Content-Type
    - X-Amz-Date
    - Authorization
    - X-Api-Key
    - X-Amz-Security-Token
    - X-Requested-With
  allowCredentials: true
  maxAge: 86400  # 24-hour preflight caching
```

**Security Features**:
- JWT Bearer Token authentication for all client endpoints
- Environment-based CORS origin configuration
- Per-endpoint throttling based on usage patterns
- Usage plans with daily quotas
- Webhook signature verification for Mailgun events

#### Primary Endpoints Used by CRM

##### `/send-mail` - Email Campaign Execution with CloudFront Signed URLs
**Method**: POST  
**Purpose**: Send email campaigns via Mailgun integration with secure file download links  
**Used By**: `emailService.ts` service  
**Lambda Function**: `DN_Send_Mail` (Python 3.12)

**Request Payload** (Updated):
```typescript
interface SendMailRequest {
  to: string[];
  subject: string;
  html: string;
  text: string;
  from: string;
  replyTo?: string;
  // NOTE: attachments removed - now using CloudFront signed URLs
  campaign: {
    name: string;
    type: 'financial' | 'newsletter';
    month?: string;
    year?: string;
  };
  // NEW: CloudFront signed URL configuration
  attachReporting?: boolean;
  customIds?: string[];
  month?: string;
  year?: string;
}
```

#### CloudFront Signed URLs Implementation
**Purpose**: Secure, time-limited access to financial reports stored in S3  
**Lambda Function**: `DN_Send_Mail`  
**Location**: `/aws-toolkit-vscode/lambda/<REGION>/DN_Send_Mail/`

**Key Components**:

1. **Lambda Function Enhancement**:
   ```python
   # File: lambda_function.py (Lines 77-94 replaced)
   from cloudfront_signed_urls import generate_report_download_links
   
   # Replace S3 download + attachment logic
   if 'attachReporting' in event:
       download_links = generate_report_download_links(
           customIds, month, year, expires_in_days=25
       )
       html = mail_template(payout_values, message_greeting, message_body, download_links)
       response = requests.post(request_url, auth=request_auth, data=request_data)
   ```

2. **CloudFront Signed URL Generation**:
   ```python
   # File: cloudfront_signed_urls.py
   def generate_signed_url(resource_url, expires_in_days=25):
       cloudfront_signer = CloudFrontSigner(key_pair_id, rsa_signer)
       return cloudfront_signer.generate_presigned_url(
           resource_url, 
           date_less_than=datetime.utcnow() + timedelta(days=expires_in_days)
       )
   ```

3. **Security Configuration**:
   - **CloudFront Distribution**: Origin Access Control (OAC) restricts S3 access
   - **Private Key Storage**: AWS Secrets Manager (`cloudfront-private-key`)
   - **URL Expiration**: 25-day maximum access period
   - **HTTPS Enforcement**: All signed URLs require HTTPS

**Dependencies**:
```txt
boto3>=1.26.0
cryptography>=3.4.8
configparser>=5.3.0
```

**Lambda Layer**: Python 3.12 compatible `cryptography` layer (~5.4MB)

## Amazon SES Unsubscribe Feature

### Task Master Snapshot (email_unsubscribe_feature)
- **Status**: 11/11 tasks completed as of November 14, 2025 (contact list infra, encryption utilities, handlers, UI, and build tooling)
- **Scope Covered**:
  1. Terraform assets for SES contact lists, DynamoDB audit tables, and `alias/dn-unsubscribe` KMS key (Tasks 1-4, 11)
  2. Lambda handlers for GET/POST unsubscribe flows, mailto ingestion, and authenticated contact management (Tasks 5-7)
  3. SES sending utilities updated for outreach + finance stacks (Tasks 8-9)
  4. React unsubscribe confirmation experience with resubscribe action (Task 10)

### Shared Infrastructure & Libraries
- **Contact List + Audit Stack**: `terraform/outreach/main.tf` and `terraform/financial/main.tf` now provision the shared SES contact list (`var.unsubscribe_contact_list_name`), DynamoDB audit table (`var.unsubscribe_audit_table_name`), and IAM policies so every Lambda can log structured events.
- **KMS-backed Tokens**: `lambda/shared/unsubscribe/src/utils/encryption.ts` encrypts `{ email, topic, timestamp }` payloads using the configured KMS alias. Tokens expire after `UNSUBSCRIBE_TOKEN_MAX_AGE_DAYS` (default 30) and are embedded via the `data` query parameter.
- **Shared Lambda Layer**: The `unsubscribe-utils-layer` bundles contact list helpers, encryption logic, Firebase admin bootstrap, and auditing helpers so finance/outreach senders and handlers all import `@distronation/unsubscribe-utils`.
- **Configurable URLs**: `UNSUBSCRIBE_BASE_URL`/`UNSUBSCRIBE_CONFIRMATION_URL` control where GET requests redirect, while `UNSUBSCRIBE_TOKEN_MAX_AGE_DAYS`, `UNSUBSCRIBE_KMS_KEY_ID`, and `SES_CONTACT_LIST_NAME` tune expiry, encryption, and targeting without code changes.

### API Surface & Flows
| API Gateway Route | Method(s) | Handler | Purpose / Notes |
| --- | --- | --- | --- |
| `/financial/unsubscribe` | GET, POST | `lambda/shared/unsubscribe/src/handlers/unsubscribeHandler.ts` | GET decrypts the token and 302-redirects to the CRM confirmation page with `email`/`topic` query params; POST serves List-Unsubscribe=One-Click flows and returns 200 with strict headers. |
| `/outreach/unsubscribe` | GET, POST | Same handler as above | Mirrors the finance route for outreach mail streams; both stages share the same KMS + contact list configuration through Terraform locals. |
| `/financial/add-contact` (exposed to CRM via `REACT_APP_OUTREACH_ADD_CONTACT_PATH`) | POST | `lambda/shared/unsubscribe/src/handlers/addContactHandler.ts` | Firebase-authenticated endpoint that re-subscribes contacts, accepts optional topic overrides, and writes audit entries; CRM’s `resubscribeContact` service targets this path. |
| SES → SNS → Lambda | Event | `lambda/shared/unsubscribe/src/handlers/mailtoUnsubscribeHandler.ts` | Processes inbound “unsubscribe” emails caught by SES mail rules, infers topics from the subject/body, unsubscribes via the contact utility, and logs DynamoDB audit rows. |

### Email Sending Integration
- `lambda/outreach/src/utils/ses.ts` and `lambda/finance/src/utils/ses.ts` now call `ensureRecipientSubscription()` (wrapping `getContact`) before every send, short-circuiting deliveries for `unsubscribeAll` or OPT_OUT contacts and auto-creating missing contacts with default topic preferences.
- Each send generates a per-recipient unsubscribe URL (`generateUnsubscribeUrl`) plus a mailto fallback, injects HTML + plaintext footers, and attaches dual headers: `List-Unsubscribe` with both mailto/https links and `List-Unsubscribe-Post: List-Unsubscribe=One-Click`.
- `ListManagementOptions` are set whenever `SES_CONTACT_LIST_NAME` is available so Gmail renders native “Unsubscribe” affordances and updates feed back into the contact list automatically.
- Tags are sanitized to SES requirements and include `recipient_<email>` to keep event correlation intact without exposing PII in headers.

### CRM UI & Resubscribe Workflow
- **Unsubscribe Confirmation Page**: `src/pages/UnsubscribeConfirmation.tsx` reads the encrypted token output (email/topic), renders confirmation messaging, and allows users to request re-subscription with a single click.
- **Resubscribe Service**: `src/services/subscriptionService.ts` posts to `outreachApiConfig.addContactPath` (overrideable via `REACT_APP_OUTREACH_ADD_CONTACT_PATH`) and pipes success/failure messaging back into the UI. It shares the same payload shape required by `addContactHandler`.
- **Preference Links**: `outreachApiConfig.managePreferencesUrl` determines whether the CTA routes internally (React Router) or externally for full preference management.

### Auditability & Compliance
- Every add/remove/update/unsubscribe operation emits a structured record to the DynamoDB audit table via `logAuditEvent`/`logAuditFailure`, capturing request IDs, IPs, and opt-out topics for compliance.
- `mailtoUnsubscribeHandler` stores detection metadata (subject, inferred topics, detection reason) so support can trace automated unsubscribes triggered by free-form emails.
- CloudWatch log groups for `outreach-unsubscribeHandler`, `financial-unsubscribeHandler`, and `financial-addContactHandler` now include request IDs, token timestamps, and encrypted contact info for debugging without exposing raw payloads.

## AWS S3 SDK Direct Integration (NEW)

### S3 File Browser Implementation
**Purpose**: Direct frontend S3 integration for financial report browsing and bulk downloads  
**Implementation**: `@aws-sdk/client-s3` v3.x.x  
**Used By**: S3 File Browser module (`/components/s3/`)  
**Authentication**: AWS Amplify + Firebase bridge for credential management

#### S3Service Implementation
**Location**: `src/services/S3Service.ts`  
**Dependencies**:
```typescript
import { S3Client, ListObjectsV2Command, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
```

**Core Methods**:
```typescript
interface S3ServiceInterface {
  // File listing with hierarchical navigation
  listFiles(prefix?: string, maxKeys?: number): Promise<S3Object[]>;
  
  // Individual file download via signed URLs
  downloadFile(key: string): Promise<Blob>;
  
  // Secure signed URL generation
  generateSignedUrl(key: string, expiresIn?: number): Promise<string>;
  
  // Path validation and security
  validatePath(path: string): boolean;
  
  // File metadata retrieval
  getFileMetadata(key: string): Promise<S3Metadata>;
}
```

#### Authentication and Security
**Credential Management**: 
- Primary: Firebase Authentication
- AWS Integration: Amplify + Cognito Identity Pool
- Bridge Service: `amplifyFirebaseBridge.ts`

**Security Features**:
```typescript
interface S3SecurityConfig {
  // Time-limited signed URLs (default: 1 hour)
  signedUrlExpiration: 3600;
  
  // Path traversal prevention
  pathValidation: RegExp;
  
  // File type restrictions
  allowedFileTypes: string[];
  
  // Maximum file size for downloads
  maxFileSize: number;
  
  // Bucket access policies
  bucketPolicy: S3BucketPolicy;
}
```

**S3 Bucket Configuration**:
```yaml
# Required Environment Variables
REACT_APP_S3_BUCKET: distro-nation-reports
REACT_APP_S3_REGION: <REGION>
REACT_APP_S3_IDENTITY_POOL_ID: <REGION>:6ae2de80-824a-43d4-aef7-b825ef284cf5

# Bucket Policy (Applied via AWS Console)
- Effect: Allow
- Principal: Authenticated Cognito users only
- Actions: s3:GetObject, s3:ListBucket
- Resources: arn:aws:s3:::distro-nation-reports/*
```

**CORS Configuration**:
```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedOrigins": ["https://crm.distro-nation.com"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

#### File Browser Operations

**Hierarchical Navigation**:
```typescript
// List files and folders with prefix-based navigation
const listFiles = async (prefix = '', delimiter = '/') => {
  const command = new ListObjectsV2Command({
    Bucket: process.env.REACT_APP_S3_BUCKET,
    Prefix: prefix,
    Delimiter: delimiter,
    MaxKeys: 100
  });
  return await s3Client.send(command);
};
```

**Bulk Download Implementation**:
```typescript
// ZIP creation for multiple files
import JSZip from 'jszip';
import FileSaver from 'file-saver';

const downloadBulkFiles = async (selectedFiles: string[]) => {
  const zip = new JSZip();
  
  for (const fileKey of selectedFiles) {
    const fileBlob = await downloadFile(fileKey);
    const fileName = fileKey.split('/').pop();
    zip.file(fileName, fileBlob);
  }
  
  const zipBlob = await zip.generateAsync({ type: 'blob' });
  FileSaver.saveAs(zipBlob, `reports-${Date.now()}.zip`);
};
```

**Progress Tracking**:
```typescript
interface DownloadProgress {
  fileKey: string;
  progress: number; // 0-100
  status: 'pending' | 'downloading' | 'completed' | 'error';
  error?: string;
}
```

#### Error Handling and Resilience

**S3 Error Types Handled**:
```typescript
enum S3ErrorTypes {
  AccessDenied = 'Insufficient permissions to access file',
  NoSuchKey = 'File not found or has been moved',
  NetworkError = 'Network connectivity issue',
  InvalidRequest = 'Invalid file path or request',
  ThrottlingException = 'Too many requests, please try again'
}
```

**Retry Logic**:
- **Exponential Backoff**: 2^attempt * 1000ms delay
- **Max Retries**: 3 attempts
- **Retry Conditions**: Network errors, throttling, temporary failures
- **Circuit Breaker**: Disable service temporarily after repeated failures

#### Performance Optimizations

**Caching Strategy**:
```typescript
// File listing cache with TTL
const fileListCache = new Map<string, {
  data: S3Object[];
  timestamp: number;
  ttl: number; // 5 minutes
}>();

// Prefetch next page for pagination
const prefetchNextPage = async (currentPrefix: string) => {
  // Background prefetch logic
};
```

**Pagination Support**:
```typescript
interface PaginationOptions {
  maxKeys: 50; // Files per page
  continuationToken?: string;
  prefetchNext: true;
}
```

### Financial Mailer API Integration (NEW)

**Base URL**: `https://<API_GATEWAY_ID>.execute-api.<REGION>.amazonaws.com/dev`  
**Authentication**: Firebase JWT Bearer Token  
**Service**: Financial Report Distribution  
**Configuration Location**: `lambda/finance/serverless.yml`

#### Overview

The Financial Mailer infrastructure provides secure, scalable distribution of monthly financial reports to content creators via email. Reports are stored in S3, accessed through CloudFront signed URLs (25-day expiration), and delivered via AWS SES.

**Key Architecture:**
- **Storage:** S3 bucket with CloudFront distribution
- **Distribution:** CloudFront signed URLs for secure access
- **Email Delivery:** AWS SES with contact list management
- **Database:** DynamoDB for tracking, Firestore for user/channel mapping
- **Authentication:** Firebase JWT tokens

#### Financial API Endpoints

##### `/financial/send-report` - Send Financial Reports
**Method**: POST  
**Purpose**: Send monthly financial reports with CloudFront signed URLs  
**Lambda Function**: Financial report sender (Node.js 20.x, 512MB, 5min timeout)  
**Authentication**: Required (JWT Bearer Token with finance role)

**Request Payload**:
```typescript
interface FinancialReportRequest {
  to: string | string[];              // Recipient email(s)
  subject: string;                    // Email subject line
  message_greeting: string;           // Personalized greeting
  message_body: string;               // Email body content
  month: string;                      // Report month (e.g., "January", "01")
  year: string;                       // Report year (e.g., "2025")
  customIds?: string[];               // Array of custom IDs to include
  attachReporting?: boolean;          // Include financial reports (triggers S3 lookup)
  from?: string;                      // Optional sender email
  tags?: string[];                    // Email tracking tags
  campaignId?: string;                // Campaign identifier
  footerNote?: string;                // Additional footer text
}
```

**Response Schema**:
```typescript
interface FinancialReportResponse {
  success: boolean;
  message: string;
  data: {
    campaignId: string;
    batchId: string;
    provider: "SES";
    attachReporting: boolean;
    totalRecipients: number;
    successful: number;
    failed: number;
    duration: number;                 // Milliseconds
    month: string;
    year: string;
    customIds: string[];
    reporting: {
      payoutCount: number;            // Number of payout records processed
      downloadLinkGroups: number;     // Number of CloudFront signed URLs generated
    };
    results: {
      successful: SendResultEntry[];
      failed: SendResultEntry[];
    };
  };
}
```

**Example Request**:
```bash
curl -X POST https://{api-id}.execute-api.{region}.amazonaws.com/{stage}/financial/send-report \
  -H "Authorization: Bearer {firebase-jwt-token}" \
  -H "Content-Type: application/json" \
  -d '{
    "to": ["creator@example.com"],
    "subject": "Your January 2025 Financial Report",
    "message_greeting": "Hello Artist Name",
    "message_body": "Please find your monthly earnings summary below.",
    "month": "January",
    "year": "2025",
    "customIds": ["ARTISTID123"],
    "attachReporting": true
  }'
```

**Status Codes**:
- `200` - All emails sent successfully
- `207` - Partial success (some emails failed)
- `400` - Validation error (missing required fields)
- `401` - Authentication failed
- `403` - Insufficient permissions (requires finance role)
- `500` - Internal server error

##### `/financial/tracking-data` - Email Tracking Analytics
**Method**: GET  
**Purpose**: Retrieve email delivery/open/click tracking data  
**Authentication**: Firebase JWT  
**Lambda Function**: Financial tracking handler (Node.js 20.x)

**Query Parameters**:
```typescript
interface TrackingDataQuery {
  campaignId?: string;
  startDate?: string;  // ISO 8601 format
  endDate?: string;
  month?: string;
  year?: string;
  email?: string;
  limit?: number;
  offset?: number;
}
```

##### `/financial/unsubscribe` - Unsubscribe Management
**Methods**: GET, POST, OPTIONS  
**Purpose**: Handle unsubscribe requests (GET redirects to CRM, POST handles one-click)  
**Lambda Function**: Unsubscribe handler (shared with outreach)

##### `/financial/add-contact` - Contact Management
**Method**: POST  
**Purpose**: Re-subscribe contacts or update preferences  
**Authentication**: Firebase JWT  
**Lambda Function**: Contact management handler (shared with outreach)

#### CloudFront Signed URLs Implementation

**Purpose**: Secure, time-limited access to financial reports stored in S3  
**Lambda Module**: `lambda/finance/src/utils/cloudfront.ts`

**Key Features**:
- **Private Key Storage**: AWS Secrets Manager (secret name configured via environment)
- **URL Expiration**: 25-day maximum access period (configurable)
- **Security**: HTTPS-only enforcement, Origin Access Control (OAC)
- **Distribution**: CloudFront distribution domain (configured via environment)
- **Key Pair ID**: Configured via `CLOUDFRONT_KEY_PAIR_ID` environment variable

**URL Generation Flow**:
```typescript
// 1. Normalize custom IDs with special mappings
const SPECIAL_CUSTOM_ID_MAP: Record<string, string> = {
  // Custom ID aliases configured per deployment
  CUSTOM_ID_A: 'MAPPED_ID_1',
  CUSTOM_ID_B: 'MAPPED_ID_2',
};

// 2. Resolve S3 keys (checks multiple path patterns)
const pathPatterns = [
  'financial-reports/{year}/{month}/{customId}-youtube.pdf',
  'financial-reports/{year}/{month}/{customId}-distro.pdf',
  'Exports/{year}/{month}/{customId}/{customId}.zip',  // Legacy
];

// 3. Generate signed URL
import { getSignedUrl } from '@aws-sdk/cloudfront-signer';

const signedUrl = getSignedUrl({
  url: resourceUrl,
  keyPairId: process.env.CLOUDFRONT_KEY_PAIR_ID,
  privateKey: await getPrivateKey(),  // From Secrets Manager
  dateLessThan: new Date(Date.now() + 25 * 24 * 60 * 60 * 1000),
});
```

**Example Signed URL Output**:
```typescript
{
  custom_id: "ARTISTID123",
  links: [
    {
      type: "youtube",
      filename: "ARTISTID123-youtube.pdf",
      url: "https://{cloudfront-domain}/financial-reports/2025/January/ARTISTID123-youtube.pdf?Expires=1740000000&Signature=ABC123...&Key-Pair-Id={key-pair-id}",
      label: "YouTube Report"
    },
    {
      type: "distro",
      filename: "ARTISTID123-distro.pdf",
      url: "https://{cloudfront-domain}/financial-reports/2025/January/ARTISTID123-distro.pdf?...",
      label: "Distribution Report"
    }
  ]
}
```

#### Data Flow: Email → Custom ID → S3 Report

**Mapping Architecture**:

```
CRM Frontend (React + Firebase)
         ↓
Firestore: users/{uid}/creators[]/channels[]
         ↓ Extract customIDs
POST /financial/send-report
         ↓ Authentication & Validation
Lambda: Financial Report Handler
         ↓
[Parallel Processing]
├─→ Invoke Payouts Fetch Lambda (Aurora/MySQL)
│   Returns payout data by customId
│
└─→ Generate CloudFront Signed URLs
    ├─ Normalize custom IDs (special mappings applied)
    ├─ Resolve S3 keys (12+ path variants checked)
    ├─ Generate signed URLs (25-day expiration)
    └─ Group by custom ID
         ↓
Render HTML Email Template
├─ Embed payout data
├─ Embed signed download URLs
└─ Add unsubscribe footer
         ↓
Send via Amazon SES
├─ Check contact list (not unsubscribed)
├─ Rate limit: 100ms delay between sends
├─ Attach List-Unsubscribe headers
└─ Log to DynamoDB tracking table
         ↓
DynamoDB: Tracking Table
Record: campaignId, recipient, customIds, month, year, timestamp
```

**Firestore User Schema**:
```typescript
// Collection: users, Document ID: Firebase UID
interface EmailUser {
  userName: string;
  emailsUser: string;              // Primary email
  status: string;
  creators?: {
    channels?: {
      customID: string;            // ← Custom ID mapping key
      channelName?: string;
      platform?: string;
    }[];
  }[];
}
```

**Custom ID Resolution Algorithm**:

The Lambda checks multiple S3 path patterns to support both new and legacy structures:

```typescript
// New structure (preferred)
financial-reports/{year}/{month}/{customId}-youtube.pdf
financial-reports/{year}/{month}/{customId}-distro.pdf

// Legacy structure
Exports/{year}/{month}/{customId}/{customId}.zip
Distro/{year}/{month}/{customId}/{customId}.zip

// Variants checked for each:
// - Month: "January", "january", "JANUARY", "01"
// - Custom ID: uppercase, with/without dashes/underscores
```

#### S3 Bucket Structure

**Bucket Name**: Configured via `S3_BUCKET_NAME` environment variable

**Directory Organization**:
```
{s3-bucket}/
├── financial-reports/           # New organized structure
│   ├── 2025/
│   │   ├── January/
│   │   │   ├── ARTISTID123-youtube.pdf
│   │   │   ├── ARTISTID123-distro.pdf
│   │   │   └── ...
│   │   └── February/
│   └── 2024/
│
├── Exports/                     # Legacy YouTube reports
│   └── {year}/{month}/{customId}/{customId}.zip
│
├── Distro/                      # Legacy distribution reports
│   └── {year}/{month}/{customId}/{customId}.zip
│
└── financial/profile-pictures/  # Artist profile images
    ├── ARTISTID123.jpg
    └── ARTISTID456.png
```

#### DynamoDB Tables

**Table**: Configured via `FINANCIAL_CAMPAIGN_TRACKING_TABLE` environment variable

**Purpose**: Track email sends, opens, clicks, bounces

**Schema**:
```typescript
{
  campaignId: string;              // Hash key
  timestamp: number;               // Range key (Unix timestamp)
  email: string;                   // Recipient email
  recipient: string;               // Normalized recipient
  eventType: string;               // "financial_send", "open", "click", etc.
  sendStatus: "success" | "failed";
  sesMessageId?: string;           // SES message ID
  month: string;
  year: string;
  customIds: string[];
  tags: string[];
  provider: "SES";
  expirationTime: number;          // TTL (90 days default)
}
```

**Global Secondary Indexes**:
- `EmailIndex` - Hash: `email`
- `email-event-index` - Hash: `recipient`, Range: `timestamp`
- `MonthYearIndex` - Hash: `month`, Range: `year`

**TTL**: 90 days (configurable via `FINANCIAL_TRACKING_TTL_DAYS`)

**Table**: Configured via `FINANCIAL_SUPPRESSION_TABLE` environment variable

**Purpose**: Store bounced/complained email addresses

**Schema**:
```typescript
{
  email: string;                   // Hash key
  reason: string;                  // "bounce" | "complaint"
  timestamp: number;
  expirationTime: number;          // TTL
}
```

#### Environment Variables

**Required Lambda Configuration**:
```bash
# S3 & CloudFront
S3_BUCKET_NAME={your-s3-bucket-name}
FINANCIAL_REPORTS_PREFIX=financial-reports
CLOUDFRONT_DOMAIN_NAME={your-cloudfront-distribution}.cloudfront.net
CLOUDFRONT_KEY_PAIR_ID={your-cloudfront-key-pair-id}
CLOUDFRONT_PRIVATE_KEY_SECRET={secretsmanager-secret-name}

# Firebase
FIREBASE_PROJECT_ID={your-firebase-project-id}
FIREBASE_SERVICE_ACCOUNT_SECRET={secretsmanager-path-to-firebase-creds}
FIREBASE_DATABASE_URL=https://{your-firebase-project}.firebaseio.com

# SES
SES_SECRETS_MANAGER_SECRET_NAME={secretsmanager-path-to-ses-creds}
SES_CONFIGURATION_SET={your-ses-configuration-set}
SES_CONTACT_LIST_NAME={your-ses-contact-list}
FINANCIAL_SES_RATE_LIMIT_MS=100

# DynamoDB
FINANCIAL_CAMPAIGN_TRACKING_TABLE={your-tracking-table-name}
FINANCIAL_SUPPRESSION_TABLE={your-suppression-table-name}
FINANCIAL_TRACKING_TTL_DAYS=90

# Lambda Dependencies
PAYOUTS_FETCH_LAMBDA_NAME={your-payouts-lambda-name}

# Unsubscribe
UNSUBSCRIBE_BASE_URL=https://{api-id}.execute-api.{region}.amazonaws.com/{stage}/financial/unsubscribe
UNSUBSCRIBE_KMS_KEY_ID=alias/{your-kms-alias}
UNSUBSCRIBE_CONFIRMATION_URL=https://{your-crm-domain}/unsubscribe/confirmation
```

#### Lambda Dependencies

**Lambda Layers**:
- `aws_sdk_nodejs20` - AWS SDK v3
- `axios_node` - HTTP client
- `financial-custom-layer` - Firebase Admin, CloudFront signer
- `unsubscribe-utils-layer` - SES contact list utilities

**Key NPM Packages**:
```json
{
  "@aws-sdk/client-s3": "^3.x",
  "@aws-sdk/client-secrets-manager": "^3.x",
  "@aws-sdk/client-ses": "^3.x",
  "@aws-sdk/client-lambda": "^3.x",
  "@aws-sdk/cloudfront-signer": "^3.x",
  "firebase-admin": "^11.x"
}
```

#### Security Features

**CloudFront Security**:
- Private keys stored in AWS Secrets Manager
- Origin Access Control (OAC) restricts S3 access to CloudFront only
- HTTPS-only enforcement on all signed URLs
- 25-day maximum URL expiration
- Quarterly key rotation schedule

**Authentication & Authorization**:
- Firebase JWT token validation on all endpoints
- Finance role requirement for sending reports
- Rate limiting: 25 requests/minute per user
- Request validation and XSS prevention

**Email Security**:
- SES contact list integration for opt-outs
- Dual List-Unsubscribe headers (mailto + HTTPS)
- Suppression list checking before sends
- Encrypted unsubscribe tokens (KMS)

#### Monitoring & Metrics

**CloudWatch Metrics Tracked**:
- Lambda invocation counts and success rates
- Email delivery rates via SES
- CloudFront cache hit rates and 4xx/5xx errors
- DynamoDB read/write capacity usage
- Authentication failures

**Custom Metrics**:
```typescript
interface FinancialMailerMetrics {
  emailsSent: number;
  emailDeliveryRate: number;
  averageResponseTime: number;
  cloudfrontSignedUrlsGenerated: number;
  s3PathResolutionSuccessRate: number;
  errorRate: number;
}
```

**Alerting Thresholds**:
- Email delivery rate < 95%
- Lambda error rate > 1%
- CloudFront 4xx/5xx errors > 1%
- Response time P95 > 5 seconds

#### Deployment Configuration

**Service Name**: Configurable (set in serverless.yml)  
**Deployment Framework**: Serverless Framework  
**Runtime**: Node.js 20.x  
**Region**: Configurable per deployment  
**Stage**: Configurable (dev/staging/prod)

**Deployment Command**:
```bash
cd lambda/finance
npm install
serverless deploy --stage dev
```

**Post-Deployment Steps**:
1. Configure Secrets Manager with CloudFront private key
2. Set up SES contact list and configuration set
3. Create DynamoDB tables with GSIs
4. Configure CloudWatch alarms
5. Update CRM frontend with API endpoint URLs

#### Known Issues & Limitations

**Legacy Structure Support**:
- System currently checks 12+ S3 path variants for backward compatibility
- Performance impact: ~100-200ms per custom ID resolution
- **Recommendation**: Migrate all reports to new structure, deprecate legacy paths

**Custom ID Mappings**:
- Hardcoded special custom ID aliases in Lambda code
- **Recommendation**: Move mappings to DynamoDB or Firestore for easier management

**Equity Distribution**:
- Hardcoded equity recipient emails in Lambda code
- **Recommendation**: Store in environment variables or database

**Rate Limiting**:
- 100ms delay between sends = ~600 emails/minute maximum
- Large campaigns may take significant time
- **Recommendation**: Implement batch processing with SES SendBulkEmail API

#### Documentation References

**Related Documentation**:
- [Data Flow Patterns](./data-flow-patterns.md#financial-mailer-flow) - Complete sequence diagrams
- [CloudFront Signed URLs Implementation](./data-flow-patterns.md#cloudfront-security) - Security details
- Complete technical report: `docs/FINANCIAL_MAILER_TECHNICAL_REPORT.md`

**Key Files**:
- Handler: `lambda/finance/src/handlers/` (financial report sender)
- CloudFront Utils: `lambda/finance/src/utils/cloudfront.ts`
- Payout Data: `lambda/finance/src/utils/payoutData.ts`
- Infrastructure: `terraform/financial/main.tf`

---

## Third-Party API Integrations

### Mailgun API Integration
**Purpose**: Email delivery service  
**Implementation**: Via dn-api proxy for security

**Features Used**:
- Email sending with HTML/text content
- Campaign tracking and analytics
- **NEW**: CloudFront signed URLs for secure file access

**Integration Pattern** (Updated):
```typescript
// CRM -> dn-api -> Lambda -> CloudFront signed URLs -> Mailgun
const sendEmail = async (emailData: EmailRequest) => {
  return await axios.post(`${dnApiConfig.baseUrl}/send-mail`, emailData);
};
```

### YouTube Data API v3 Integration
**Purpose**: YouTube channel search and discovery for outreach campaigns  
**Base URL**: `https://www.googleapis.com/youtube/v3`  
**Authentication**: OAuth 2.0 Access Token (Bearer Token)  
**Configuration Location**: `src/config/api.config.ts` (youtubeAuthConfig)

#### YouTube API Endpoints Used

##### Search API - Channel Discovery
**Endpoint**: `GET /youtube/v3/search`  
**Purpose**: Search for YouTube channels based on query terms  
**Required Parameters**:
- `part=snippet` - Returns basic channel information
- `type=channel` - Limits results to channels only
- `q={query}` - Search query string
- `order={order}` - Sort order (relevance, viewCount, title)
- `maxResults={1-50}` - Number of results per page

**Example Request**:
```bash
GET https://www.googleapis.com/youtube/v3/search?part=snippet&type=channel&q=music+reaction&order=relevance&maxResults=20
Authorization: Bearer {access_token}
```

**Response Structure**:
```typescript
interface YouTubeSearchAPIResponse {
  items: Array<{
    id: {
      channelId: string;
    };
    snippet: {
      title: string;
      description: string;
      thumbnails: {
        medium: { url: string };
      };
    };
  }>;
  nextPageToken?: string;
  prevPageToken?: string;
}
```

##### Channels API - Detailed Channel Information
**Endpoint**: `GET /youtube/v3/channels`  
**Purpose**: Fetch detailed statistics and metadata for specific channels  
**Required Parameters**:
- `part=snippet,statistics` - Returns channel details and statistics
- `id={channelIds}` - Comma-separated list of channel IDs (up to 50)

**Example Request**:
```bash
GET https://www.googleapis.com/youtube/v3/channels?part=snippet,statistics&id=UCxxxxxx,UCyyyyyy
Authorization: Bearer {access_token}
```

**Response Structure**:
```typescript
interface YouTubeChannelsAPIResponse {
  items: Array<{
    id: string;
    snippet: {
      title: string;
      description: string;
      customUrl?: string;
      country?: string;
      publishedAt: string;
      thumbnails: {
        default: { url: string };
        medium: { url: string };
        high: { url: string };
      };
    };
    statistics: {
      subscriberCount: string;
      viewCount: string;
      videoCount: string;
    };
  }>;
}
```

##### Channels API - Single Channel Details
**Endpoint**: `GET /youtube/v3/channels`  
**Purpose**: Fetch comprehensive details for a single channel (includes contentDetails)  
**Required Parameters**:
- `part=snippet,contentDetails,statistics` - Returns full channel information
- `id={channelId}` - Single channel ID

**Used For**: Loading detailed view when user selects a channel from search results

#### Authentication Flow

**Token Management**:
- Access tokens are obtained from an internal token service
- Tokens are cached in-memory with expiry tracking
- 30-second buffer before expiry triggers automatic refresh
- Invalid/expired tokens trigger re-authentication

**Implementation** (`src/services/outreach/integrations/youtubeAuth.ts`):
```typescript
interface YouTubeAuthConfig {
  tokenUrl: string;        // Internal service endpoint
  apiKey: string;          // API key for token service
}

// Token caching with expiry
let cachedToken: string | null = null;
let tokenExpiresAt = 0;

async function getYouTubeAccessToken(): Promise<string> {
  if (isTokenValid()) {
    return cachedToken;
  }
  
  // Request new token from internal service
  const response = await fetch(tokenUrl, {
    headers: { 'x-api-key': apiKey }
  });
  
  const { token, expires_in } = await response.json();
  cachedToken = token;
  tokenExpiresAt = Date.now() + expires_in * 1000;
  
  return token;
}
```

#### Error Handling

**API Error Responses**:
- `400` - Invalid parameters (e.g., bad page token)
- `401` - Unauthorized (token expired or invalid)
- `403` - Quota exceeded or access forbidden
- `429` - Rate limited

**Retry Strategy**:
```typescript
// Exponential backoff for rate limits (429)
async function fetchWithRetry(url: string, retries = 3): Promise<Response> {
  try {
    const response = await fetch(url);
    
    if (response.status === 429 && retries > 0) {
      const delay = Math.pow(2, 4 - retries) * 1000;  // 2s, 4s, 8s
      await new Promise(resolve => setTimeout(resolve, delay));
      return fetchWithRetry(url, retries - 1);
    }
    
    return response;
  } catch (error) {
    if (retries > 0) {
      const delay = Math.pow(2, 4 - retries) * 1000;
      await new Promise(resolve => setTimeout(resolve, delay));
      return fetchWithRetry(url, retries - 1);
    }
    throw error;
  }
}
```

**Token Refresh on Auth Errors**:
```typescript
// Automatic token refresh on 401/403
if (response.status === 401 || response.status === 403) {
  clearCachedYouTubeToken();
  accessToken = await getYouTubeAccessToken();
  response = await fetchWithRetry(url);  // Retry with new token
}
```

#### Data Processing

**Topic Channel Filtering**:
YouTube Topic channels (auto-generated by YouTube) are automatically filtered from search results to ensure only real content creator channels are displayed.

```typescript
function filterTopicChannels(channels: YouTubeSearchResult[]): YouTubeSearchResult[] {
  return channels.filter(channel => {
    const title = channel.channelTitle.toLowerCase();
    const description = channel.channelDescription.toLowerCase();
    return !title.includes('topic') && !description.includes('topic');
  });
}
```

**Email Extraction**:
Channel descriptions are scanned for email addresses to facilitate outreach:

```typescript
function extractEmailFromDescription(description: string): string | undefined {
  const emailRegex = /([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9._-]+)/gi;
  const emails = description.match(emailRegex);
  return emails && emails.length > 0 ? emails[0] : undefined;
}
```

#### Rate Limiting & Quotas

**YouTube API Quotas**:
- Default: 10,000 units per day
- Search operation: ~100 units per request
- Channels operation: ~1 unit per request

**Client-Side Optimizations**:
- Results cached by query/sort/page in sessionStorage
- Pagination tokens stored to avoid redundant searches
- Statistics fetched in bulk (up to 50 channels per request)

#### Integration Architecture

See [Data Flow Patterns](./data-flow-patterns.md#youtube-channel-search-flow) for complete sequence diagram.

**Key Files**:
- `src/services/outreach/integrations/youtubeSearch.ts` - API client
- `src/services/outreach/integrations/youtubeAuth.ts` - Token management
- `src/hooks/useYouTubeSearch.ts` - React hook with caching
- `src/components/outreach/YouTubeSearchModal.tsx` - UI component

### Korrect API Endpoints

#### Overview
The Korrect API provides access to DistroNation user data and payout information, enabling the CRM to retrieve user information, email lists for campaign targeting, and financial payout totals. These endpoints proxy authenticated calls to the external Korrect API system. This is the primary data source for email recipient management and financial reporting across outreach and financial mailer operations.

**Note**: These endpoints handle authentication and communication with the external Korrect API. For detailed information about the underlying Korrect API integration, contact Distro Nation.

**Base URL**: `https://cjed05n28l.execute-api.us-east-1.amazonaws.com/staging`  
**Authentication**: API Key via `x-api-key` header  
**Service**: DistroNation User Management & Payout Data  
**Configuration Location**: `src/services/emailService.ts`, `src/components/mailer/MailerTemplate.tsx`, `src/components/newsletter/NewsletterForm_old.js`

#### Primary Email Recipient Endpoint

##### `/dn_users_list` - Fetch DistroNation Users
**Method**: GET  
**Purpose**: Retrieve list of active DistroNation users with email addresses for campaign targeting  
**Used By**: Mailer Template, Newsletter Forms, Email Service  
**Authentication**: Required (API Key in `x-api-key` header)

**Request**:
```bash
GET https://cjed05n28l.execute-api.us-east-1.amazonaws.com/staging/dn_users_list
x-api-key: {REACT_APP_DN_API_KEY}
```

**No Query Parameters Required**: Endpoint returns all users, filtering applied client-side

**Response Structure**:
```typescript
interface UserAPIResponse {
  statusCode: number;
  body: EmailUser[];
}

interface EmailUser {
  userName: string;              // Display name
  status: string;                // Account status ("active", "inactive", etc.)
  emailsUser: string;            // Primary email address
  creators?: {                   // Optional nested creator/channel data
    channels?: {
      customID: string;          // Channel custom ID (links to reports)
      channelName?: string;
      platform?: string;         // "youtube", "spotify", etc.
    }[];
  }[];
}
```

**Example Response**:
```json
{
  "statusCode": 200,
  "body": [
    {
      "userName": "Artist Name",
      "status": "active",
      "emailsUser": "artist@example.com",
      "creators": [
        {
          "channels": [
            {
              "customID": "ARTISTID123",
              "channelName": "Official Channel",
              "platform": "youtube"
            }
          ]
        }
      ]
    },
    {
      "userName": "Creator Two",
      "status": "active",
      "emailsUser": "creator2@example.com"
    }
  ]
}
```

#### Client-Side Filtering Rules

The CRM applies automatic filtering to the user list to ensure only valid recipients are included:

**Filtering Criteria**:
1. **Active Status Only**: `status === "active"`
2. **Non-Empty Email**: `emailsUser !== null && emailsUser !== ""`
3. **Hardcoded Exclusions**: 5 specific user emails excluded (internal test accounts)

**Implementation** (`src/services/emailService.ts`):
```typescript
const EXCLUDED_EMAILS = [
  'excluded1@example.com',
  'excluded2@example.com',
  'excluded3@example.com',
  'excluded4@example.com',
  'excluded5@example.com'
];

function filterValidRecipients(users: EmailUser[]): EmailUser[] {
  return users.filter(user => 
    user.status === 'active' &&
    user.emailsUser &&
    user.emailsUser.trim() !== '' &&
    !EXCLUDED_EMAILS.includes(user.emailsUser.toLowerCase())
  );
}
```

#### Usage Patterns

**Primary Use Cases**:

1. **Financial Mailer Campaigns**:
   - Fetch all active users
   - Extract `customID` values from nested `creators.channels` structure
   - Map customIDs to financial reports in S3
   - Send personalized financial reports with CloudFront signed URLs

2. **Outreach Campaigns**:
   - Fetch all active users for bulk email campaigns
   - Use `userName` for email personalization
   - Target specific user segments based on creator/channel data

3. **Newsletter Distribution**:
   - Retrieve all valid email addresses
   - Apply additional opt-in/opt-out filtering
   - Send mass communications

**Data Flow Example** (Financial Mailer):
```
1. GET /dn_users_list → Fetch all users
2. Filter active users with valid emails
3. Extract customIDs from creators.channels[]
4. POST /financial/send-report with customIDs
5. Lambda resolves customIDs → S3 report paths
6. Generate CloudFront signed URLs for reports
7. Send personalized emails with download links
```

#### Environment Configuration

**Required Environment Variable**:
```bash
# .env file
REACT_APP_DN_API_KEY=your-api-key-here
```

**API Configuration** (`src/config/api.config.ts`):
```typescript
export const dnApiConfig = {
  baseUrl: 'https://cjed05n28l.execute-api.us-east-1.amazonaws.com/staging',
  endpoints: {
    usersList: '/dn_users_list',
    sendMail: '/send-mail',
    // ... other endpoints
  },
  headers: {
    'x-api-key': process.env.REACT_APP_DN_API_KEY || '',
    'Content-Type': 'application/json'
  }
};
```

#### Error Handling

**HTTP Status Codes**:
- `200` - Success, returns user list
- `401` - Unauthorized (missing or invalid API key)
- `403` - Forbidden (API key lacks permissions)
- `500` - Internal server error
- `503` - Service temporarily unavailable

**Error Response Format**:
```typescript
interface ErrorResponse {
  statusCode: number;
  message: string;
  error?: string;
}
```

**Client-Side Error Handling**:
```typescript
try {
  const response = await fetch(dnApiConfig.baseUrl + '/dn_users_list', {
    headers: { 'x-api-key': dnApiConfig.headers['x-api-key'] }
  });
  
  if (!response.ok) {
    throw new Error(`API request failed: ${response.status} ${response.statusText}`);
  }
  
  const data: UserAPIResponse = await response.json();
  const validUsers = filterValidRecipients(data.body);
  return validUsers;
  
} catch (error) {
  console.error('Failed to fetch users:', error);
  // Fallback: Use cached data or show user-friendly error
  throw new Error('Unable to load recipient list. Please try again.');
}
```

#### Data Privacy & Security

**Sensitive Data Handling**:
- Email addresses are PII (Personally Identifiable Information)
- API key must never be exposed in client-side code (use environment variables only)
- User data should be cached securely (memory only, never localStorage for PII)
- Email lists must not be logged or exposed in error messages

**API Key Security**:
- Rotate API keys quarterly
- Use separate keys for dev/staging/production
- Monitor API usage for anomalies
- Revoke compromised keys immediately

**Compliance**:
- GDPR: Users have right to access/delete their data
- CAN-SPAM: All emails must include unsubscribe mechanism
- SES Contact List: Respect opt-out preferences before sending

#### Payout Totals Endpoint

##### `/dn_payouts_fetch` - Fetch Payout Totals by Custom ID
**Method**: POST  
**Purpose**: Retrieve total payout amounts per custom ID for a specified time period  
**Used By**: Financial Mailer, Payout Reports  
**Authentication**: Required (API Key in `x-api-key` header)

**Request**:
```bash
POST https://cjed05n28l.execute-api.us-east-1.amazonaws.com/staging/dn_payouts_fetch
x-api-key: {REACT_APP_DN_API_KEY}
Content-Type: application/json
```

**Request Payload**:
```typescript
interface PayoutFetchRequest {
  payoutType: string;              // Type of payout to retrieve
  startMonth: string;              // Start month (numeric "1"-"12" or name "January")
  endMonth: string;                // End month (numeric "1"-"12" or name "December")
  startYear: string;               // Start year (e.g., "2025")
  endYear: string;                 // End year (e.g., "2025")
  customIds: string[];             // Array of custom IDs to fetch payouts for
}
```

**Example Request**:
```json
{
  "payoutType": "youtube",
  "startMonth": "12",
  "endMonth": "12",
  "startYear": "2025",
  "endYear": "2025",
  "customIds": ["DYLVN"]
}
```

**Response Structure**:
```typescript
interface PayoutFetchResponse {
  statusCode: number;
  body: string;                    // JSON string of PayoutData[]
}

interface PayoutData {
  customId: string;
  payout: {
    // Payout details from external API
    [key: string]: any;
  };
}
```

**Example Response** (DYLVN, December 2025):
```json
{
  "statusCode": 200,
  "body": "[{\"customId\":\"DYLVN\",\"payout\":[{\"contractCode\":\"ART001-DYLVN\",\"yearPart\":2025,\"monthPart\":12,\"openingBal\":1250.00,\"paymentsAll\":-1250.00,\"performanceRoy\":0.0,\"subscriptionRoy\":0.0,\"paidFeatures\":0.0,\"royEarnings\":450.50,\"pubEarnings\":0.0,\"recoupables\":0.0,\"periodBal\":-799.50,\"totalBal\":450.50,\"royaltyPeriod\":202512,\"totalViews\":3500.0,\"totalUnits\":0.0,\"totalRows\":0,\"totalGross\":500.55,\"shortsEarnings\":0.0},{\"contractCode\":\"YT-DYLVN-0001\",\"yearPart\":2025,\"monthPart\":12,\"openingBal\":980.00,\"paymentsAll\":-980.00,\"performanceRoy\":125.75,\"subscriptionRoy\":320.25,\"paidFeatures\":0.0,\"royEarnings\":0.0,\"pubEarnings\":0.0,\"recoupables\":0.0,\"periodBal\":-534.00,\"totalBal\":446.00,\"royaltyPeriod\":202512,\"totalViews\":52000.0,\"totalUnits\":0.0,\"totalRows\":0,\"totalGross\":496.00,\"shortsEarnings\":0.0}]}]"
}
```

**Formatted Response Example** (easier to read):
```json
{
  "statusCode": 200,
  "body": [
    {
      "customId": "DYLVN",
      "payout": [
        {
          "contractCode": "ART001-DYLVN",
          "yearPart": 2025,
          "monthPart": 12,
          "openingBal": 1250.00,
          "paymentsAll": -1250.00,
          "performanceRoy": 0.0,
          "subscriptionRoy": 0.0,
          "paidFeatures": 0.0,
          "royEarnings": 450.50,
          "pubEarnings": 0.0,
          "recoupables": 0.0,
          "periodBal": -799.50,
          "totalBal": 450.50,
          "royaltyPeriod": 202512,
          "totalViews": 3500.0,
          "shortsEarnings": 0.0
        },
        {
          "contractCode": "YT-DYLVN-0001",
          "yearPart": 2025,
          "monthPart": 12,
          "openingBal": 980.00,
          "paymentsAll": -980.00,
          "performanceRoy": 125.75,
          "subscriptionRoy": 320.25,
          "paidFeatures": 0.0,
          "royEarnings": 0.0,
          "pubEarnings": 0.0,
          "recoupables": 0.0,
          "periodBal": -534.00,
          "totalBal": 446.00,
          "royaltyPeriod": 202512,
          "totalViews": 52000.0,
          "shortsEarnings": 0.0
        }
      ]
    }
  ]
}
```

**Special Custom ID Mappings**:
The Lambda function applies automatic custom ID transformations:
- `MOLS` → `MOL`
- `JODYHIGHROLLER` → `RIFFRAFF`

**Backend Integration**:
- Authenticates with external Korrect API (`lne.onkorrect.com`)
- Fetches payout data per custom ID for specified date range
- Returns aggregated payout totals

**Month Format Support**:
Accepts both numeric (`"1"`, `"12"`) and text formats (`"January"`, `"December"`) for month parameters.

#### Related Endpoints & Integrations

**Downstream Dependencies**:
1. **Financial Mailer API** (`/financial/send-report`):
   - Uses customIDs extracted from user list
   - Maps customIDs to S3 financial reports
   - Sends personalized financial emails

2. **Outreach API** (`/outreach/send-email`):
   - Uses email addresses from user list
   - Sends bulk outreach campaigns
   - Tracks email engagement metrics

3. **SES Contact List Integration**:
   - Cross-references with SES contact list for opt-out status
   - Ensures compliance with unsubscribe requests
   - Syncs user preferences bidirectionally

**Related Documentation**:
- [Financial Mailer API Integration](#financial-mailer-api-integration-new) - Custom ID to report mapping
- [Outreach API Integration](#outreach-api-integration-new) - Email campaign execution
- [Data Flow Patterns](./data-flow-patterns.md#email-recipient-flow) - Complete sequence diagrams

---

## Security Considerations

### Outreach API Security (NEW)
**Authentication Method**: JWT Bearer Token validation  
**Implementation**: Firebase Authentication integration  
**Token Validation**: Server-side verification in Lambda functions

**Security Features**:
```typescript
interface OutreachSecurityConfig {
  // JWT token validation
  firebaseAuth: {
    projectId: string;
    serviceAccountSecret: string; // AWS Secrets Manager
    tokenValidation: 'strict';
  };
  
  // Rate limiting per authenticated user
  rateLimiting: {
    sendEmail: '25 requests/minute';
    templateEmail: '25 requests/minute';
    analytics: '50 requests/minute';
  };
  
  // CORS security
  corsPolicy: {
    allowedOrigins: string[]; // Environment configurable
    allowCredentials: true;
    maxAge: 86400; // 24 hours
  };
  
  // Request validation
  inputValidation: {
    emailAddresses: 'RFC 5322 compliant';
    templateVariables: 'XSS prevention';
    customVariables: 'Injection prevention';
  };
}
```

**Authentication Flow**:
1. Frontend obtains Firebase ID token
2. Token sent as `Authorization: Bearer <token>` header
3. Lambda function validates token with Firebase Admin SDK
4. User context extracted for logging and rate limiting
5. Request processed with authenticated user context

**Error Handling**:
```typescript
enum AuthenticationErrors {
  InvalidToken = 'Invalid or expired authentication token',
  MissingToken = 'Authorization header required',
  InsufficientPermissions = 'User lacks required permissions',
  RateLimitExceeded = 'Too many requests from this user'
}
```

### CloudFront Security (NEW)
- **Private Key Management**: RSA private keys in AWS Secrets Manager
- **Key Rotation**: Quarterly rotation schedule
- **URL Expiration**: 25-day maximum access period
- **Origin Access Control**: S3 bucket restricted to CloudFront only
- **HTTPS Only**: All signed URLs enforce HTTPS transport
- **Access Logging**: CloudFront access logs monitored

### API Key Management
- **Environment Variables Only**: All API keys in environment variables
- **No Hardcoded Keys**: Never commit secrets to version control
- **Key Rotation**: Regular rotation schedule (quarterly minimum)

## Monitoring and Observability

### Outreach API Monitoring (NEW)
**CloudWatch Metrics Tracked**:
- **Lambda Invocations**: Per-function invocation counts and success rates
- **Authentication Failures**: Failed JWT token validations
- **Rate Limiting Events**: Throttled requests per endpoint
- **Email Delivery Metrics**: Success/failure rates via Mailgun webhooks
- **Response Times**: P50, P95, P99 latencies per endpoint
- **Error Rates**: 4xx/5xx error percentages

**Custom Metrics**:
```typescript
interface OutreachMetrics {
  // Email sending metrics
  emailsSent: number;
  emailDeliveryRate: number;
  templateUsage: Record<string, number>;
  
  // API performance
  averageResponseTime: number;
  errorRate: number;
  authenticationSuccessRate: number;
  
  // User activity
  activeUsers: number;
  requestsPerUser: Record<string, number>;
  
  // Campaign effectiveness
  openRates: number;
  clickRates: number;
  bounceRates: number;
}
```

**Alerting Thresholds**:
- **Authentication Failures > 5%**: Potential security issue
- **Email Delivery Rate < 95%**: Mailgun integration problem
- **Lambda Error Rate > 1%**: Function reliability issue
- **Response Time P95 > 5 seconds**: Performance degradation
- **Rate Limiting Events > 100/hour**: Potential abuse or frontend issue

**Dashboard Components**:
1. **Real-time Email Sending Volume**
2. **Authentication Success/Failure Rates**
3. **API Response Time Trends**
4. **Campaign Performance Metrics**
5. **Error Rate by Endpoint**
6. **User Activity Heatmap**

### API Performance Monitoring (Updated)
**New Metrics Tracked**:
- **CloudFront cache hit rates**
- **S3 access patterns via CloudFront**
- **Signed URL generation performance**
- **Outreach API endpoint performance**
- **JWT token validation latency**

**New Alerting Thresholds**:
- **CloudFront 4xx/5xx errors > 1%**
- **Lambda execution time improvements (targeting 50% reduction)**
- **Outreach API authentication failures > 5%**
- **Email delivery rate via Outreach API < 95%**

## Deployment and Migration Notes

### Outreach API Deployment (NEW)
**Service Name**: `payouts-mailer-outreach`  
**Deployment Framework**: Serverless Framework  
**Runtime**: Node.js 18.x  
**Region**: <REGION>  
**Stage**: dev (configurable via `--stage` parameter)

**Deployment Command**:
```bash
cd lambda/outreach
npm install
serverless deploy --stage dev
```

**Environment Variables Required**:
```bash
# Mailgun Configuration
MAILGUN_API_KEY=key-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
MAILGUN_DOMAIN=mg.yourdomain.com
MAILGUN_WEBHOOK_SIGNING_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# AWS Secrets Manager
SECRETS_MANAGER_SECRET_NAME=payouts-mailer/mailgun-secrets
FIREBASE_SERVICE_ACCOUNT_SECRET=payouts-mailer/firebase-service-account

# Firebase Configuration
FIREBASE_DATABASE_URL=https://your-project.firebaseio.com

# CORS Configuration
CORS_ALLOWED_ORIGINS=https://crm.distro-nation.com,http://localhost:3000

# Stage
STAGE=dev
```

**AWS Resources Created**:
1. **Lambda Functions**: 5 functions (sendEmail, sendTemplateEmail, campaignStats, trackingData, webhookHandler)
2. **API Gateway**: REST API with CORS and throttling configuration
3. **IAM Roles**: Lambda execution roles with Secrets Manager permissions
4. **CloudWatch Log Groups**: Per-function logging
5. **Usage Plans**: API throttling and quota management

**Post-Deployment Configuration**:
1. **Secrets Manager Setup**: Store Mailgun and Firebase credentials
2. **DNS Configuration**: Point custom domain to API Gateway (optional)
3. **Monitoring Setup**: Configure CloudWatch alarms and dashboards
4. **Frontend Integration**: Update API endpoints in CRM configuration

**Testing Checklist**:
- [ ] All endpoints respond with 200 status for valid requests
- [ ] Authentication properly rejects invalid JWT tokens
- [ ] CORS headers present for browser requests
- [ ] Rate limiting enforced per endpoint
- [ ] Webhook signature verification working
- [ ] Email sending functional via Mailgun
- [ ] Campaign stats retrieving data correctly
- [ ] Error responses properly formatted

### CloudFront Signed URLs Migration
**Migration Date**: August 12, 2025  
**Migration Type**: Breaking change - replaced email attachments with secure download links

**Performance Impact**:
- **Lambda Execution Time**: Reduced by ~50%
- **Memory Usage**: Reduced by ~70%
- **Email Delivery Speed**: Improved by ~30%
- **Global Download Performance**: Significantly improved via CloudFront CDN

**Files Modified/Created**:
1. **`cloudfront_signed_urls.py`** - NEW: CloudFront URL generation
2. **`lambda_function.py`** - Modified: Replaced S3 downloads with signed URLs
3. **`template.py`** - Modified: Added download links to email template
4. **`config.ini`** - Added: CloudFront configuration
5. **`requirements.txt`** - NEW: Dependency specifications

**Rollback Plan**:
- Revert Lambda code to previous version
- Monitor email delivery rates and user feedback
- Maintain hybrid support if needed

This documentation reflects the successful implementation of CloudFront signed URLs for secure financial report distribution, improving performance while maintaining security standards.
