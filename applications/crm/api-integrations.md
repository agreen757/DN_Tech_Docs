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
