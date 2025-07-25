# dn-api OpenAPI Specification

## API Overview
- **API Name**: dn-api
- **Base URL**: `https://<API_GATEWAY_ID_2>.execute-api.<REGION>.amazonaws.com/staging`
- **Version**: 1.0.0
- **Description**: Distro Nation Functional API for backend admin functions and tasks

## OpenAPI 3.0 Specification

```yaml
openapi: 3.0.0
info:
  title: Distro Nation Admin API
  description: Distro Nation Functional API. This API is used to launch back-end admin functions and tasks
  version: 1.0.0
  contact:
    name: Distro Nation Engineering
    email: adrian@distronation.com

servers:
  - url: https://<API_GATEWAY_ID_2>.execute-api.<REGION>.amazonaws.com/staging
    description: Production staging environment

security:
  - ApiKeyAuth: []

paths:
  /channels:
    post:
      summary: Channel Management
      description: Manage channel operations and configurations
      operationId: manageChannels
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                action:
                  type: string
                  enum: [create, update, delete, list]
                channelId:
                  type: string
                channelData:
                  type: object
      responses:
        '200':
          description: Successful operation
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/SuccessResponse'
        '400':
          description: Bad request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      tags:
        - Channel Management

  /update-dnfm-user:
    post:
      summary: Update DistroFM User
      description: Update user information in the DistroFM system
      operationId: updateDnfmUser
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                userId:
                  type: string
                userData:
                  type: object
                  properties:
                    name:
                      type: string
                    email:
                      type: string
                    profile:
                      type: object
      responses:
        '200':
          description: User updated successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/SuccessResponse'
        '404':
          description: User not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      tags:
        - User Management

  /dn_users_list:
    get:
      summary: List Users for Email Campaigns
      description: |
        Retrieve list of users for email campaign targeting. Used by CRM application
        to populate recipient lists for email campaigns. Returns user data with
        email preferences and subscription status.
      operationId: listUsers
      parameters:
        - name: limit
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
          description: Maximum number of users to return
        - name: offset
          in: query
          schema:
            type: integer
            minimum: 0
            default: 0
          description: Number of users to skip for pagination
        - name: filter
          in: query
          schema:
            type: string
          description: Filter users by name, email, or subscription status
        - name: subscriptionStatus
          in: query
          schema:
            type: string
            enum: [active, inactive, pending, unsubscribed]
          description: Filter users by subscription status
        - name: emailType
          in: query
          schema:
            type: string
            enum: [financial, newsletter, all]
          description: Filter users by email type preferences
      responses:
        '200':
          description: List of users retrieved successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  users:
                    type: array
                    items:
                      type: object
                      properties:
                        id:
                          type: string
                          description: Unique user identifier
                        email:
                          type: string
                          format: email
                          description: User email address
                        firstName:
                          type: string
                          description: User first name
                        lastName:
                          type: string
                          description: User last name
                        subscriptionStatus:
                          type: string
                          enum: [active, inactive, pending, unsubscribed]
                          description: Current subscription status
                        preferences:
                          type: object
                          properties:
                            financialEmails:
                              type: boolean
                              description: Opt-in for financial email campaigns
                            newsletterEmails:
                              type: boolean
                              description: Opt-in for newsletter campaigns
                            marketingEmails:
                              type: boolean
                              description: Opt-in for marketing campaigns
                        createdAt:
                          type: string
                          format: date-time
                          description: Account creation timestamp
                        lastLoginAt:
                          type: string
                          format: date-time
                          description: Last login timestamp
                  total:
                    type: integer
                    description: Total number of users matching filter
                  limit:
                    type: integer
                    description: Applied limit parameter
                  offset:
                    type: integer
                    description: Applied offset parameter
                  hasMore:
                    type: boolean
                    description: Whether more results are available
        '400':
          description: Invalid query parameters
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '401':
          description: Authentication required
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      tags:
        - User Management
        - CRM Integration
        - Email Campaigns
    
    post:
      summary: Create User
      description: Create a new user in the system
      operationId: createUser
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
      responses:
        '201':
          description: User created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '400':
          description: Invalid user data
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      tags:
        - User Management

  /send-mail:
    post:
      summary: Send Email Campaign
      description: Send email campaigns via Mailgun integration for CRM application
      operationId: sendEmailCampaign
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                to:
                  type: array
                  items:
                    type: string
                    format: email
                  description: Array of recipient email addresses
                subject:
                  type: string
                  description: Email subject line
                html:
                  type: string
                  description: HTML email content
                text:
                  type: string
                  description: Plain text email content
                from:
                  type: string
                  format: email
                  description: Sender email address
                replyTo:
                  type: string
                  format: email
                  description: Reply-to email address
                campaign:
                  type: object
                  properties:
                    name:
                      type: string
                      description: Campaign name for tracking
                    type:
                      type: string
                      enum: [financial, newsletter]
                      description: Type of email campaign
                    month:
                      type: string
                      description: Campaign month (for financial emails)
                    year:
                      type: string
                      description: Campaign year (for financial emails)
              required: [to, subject, html, from, campaign]
      responses:
        '200':
          description: Email campaign sent successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                  messageId:
                    type: string
                    description: Mailgun message ID
                  recipientCount:
                    type: integer
                    description: Number of recipients
                  estimatedDeliveryTime:
                    type: string
                    description: Estimated delivery time
                  campaign:
                    type: object
                    properties:
                      id:
                        type: string
                      status:
                        type: string
                        enum: [queued, sending, sent, failed]
        '400':
          description: Invalid email data
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      tags:
        - Email Campaigns
        - CRM Integration

  /dn_payouts_fetch:
    get:
      summary: Fetch Payout Data
      description: Retrieve payout information for analysis and reporting
      operationId: fetchPayouts
      parameters:
        - name: startDate
          in: query
          schema:
            type: string
            format: date
        - name: endDate
          in: query
          schema:
            type: string
            format: date
        - name: userId
          in: query
          schema:
            type: string
        - name: status
          in: query
          schema:
            type: string
            enum: [pending, completed, failed]
      responses:
        '200':
          description: Payout data retrieved successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  payouts:
                    type: array
                    items:
                      $ref: '#/components/schemas/Payout'
                  summary:
                    type: object
                    properties:
                      totalAmount:
                        type: number
                      totalCount:
                        type: integer
                      byStatus:
                        type: object
      tags:
        - Financial Operations

    post:
      summary: Process Payout
      description: Process payout requests and update status
      operationId: processPayouts
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                payoutIds:
                  type: array
                  items:
                    type: string
                action:
                  type: string
                  enum: [approve, reject, process]
      responses:
        '200':
          description: Payouts processed successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/BatchOperationResponse'
      tags:
        - Financial Operations

  /dn_partner_list_korrect:
    get:
      summary: Get Partner List
      description: Retrieve and correct partner information
      operationId: getPartnerList
      responses:
        '200':
          description: Partner list retrieved successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  partners:
                    type: array
                    items:
                      $ref: '#/components/schemas/Partner'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      tags:
        - Partner Management

    options:
      summary: CORS Preflight
      description: Handle CORS preflight requests
      responses:
        '200':
          description: CORS headers
          headers:
            Access-Control-Allow-Origin:
              schema:
                type: string
            Access-Control-Allow-Methods:
              schema:
                type: string
            Access-Control-Allow-Headers:
              schema:
                type: string

  /payout-audit:
    post:
      summary: Audit Payouts
      description: Perform payout auditing and compliance checks
      operationId: auditPayouts
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                auditType:
                  type: string
                  enum: [compliance, accuracy, fraud]
                dateRange:
                  type: object
                  properties:
                    start:
                      type: string
                      format: date
                    end:
                      type: string
                      format: date
                filters:
                  type: object
      responses:
        '200':
          description: Audit completed successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  auditId:
                    type: string
                  results:
                    type: object
                  issues:
                    type: array
                    items:
                      type: object
      tags:
        - Financial Operations

  /send-mail:
    post:
      summary: Send Email
      description: Send email notifications and communications
      operationId: sendMail
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - to
                - subject
                - body
              properties:
                to:
                  type: array
                  items:
                    type: string
                    format: email
                cc:
                  type: array
                  items:
                    type: string
                    format: email
                bcc:
                  type: array
                  items:
                    type: string
                    format: email
                subject:
                  type: string
                body:
                  type: string
                isHtml:
                  type: boolean
                  default: false
                templateId:
                  type: string
                templateData:
                  type: object
      responses:
        '200':
          description: Email sent successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  messageId:
                    type: string
                  status:
                    type: string
          headers:
            Access-Control-Allow-Origin:
              schema:
                type: string
                example: '*'
        '400':
          description: Invalid email data
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      tags:
        - Communication

    options:
      summary: CORS Preflight
      description: Handle CORS preflight for email endpoint
      responses:
        '200':
          description: CORS headers
          headers:
            Access-Control-Allow-Origin:
              schema:
                type: string
                example: '*'
            Access-Control-Allow-Methods:
              schema:
                type: string
            Access-Control-Allow-Headers:
              schema:
                type: string

  /ikey:
    get:
      summary: Get API Key
      description: Retrieve API key information
      operationId: getApiKey
      responses:
        '200':
          description: API key information
          content:
            application/json:
              schema:
                type: object
                properties:
                  keyId:
                    type: string
                  status:
                    type: string
                  permissions:
                    type: array
                    items:
                      type: string
      tags:
        - API Management

    put:
      summary: Update API Key
      description: Update API key configuration
      operationId: updateApiKey
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                permissions:
                  type: array
                  items:
                    type: string
                status:
                  type: string
                  enum: [active, inactive]
      responses:
        '200':
          description: API key updated successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/SuccessResponse'
      tags:
        - API Management

    options:
      summary: CORS Preflight
      description: Handle CORS preflight for API key endpoint
      responses:
        '200':
          description: CORS headers

  /hollow:
    get:
      summary: Health Check
      description: Health check endpoint for system monitoring
      operationId: healthCheck
      responses:
        '200':
          description: System is healthy
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                    example: healthy
                  timestamp:
                    type: string
                    format: date-time
      tags:
        - System

    options:
      summary: CORS Preflight
      responses:
        '200':
          description: CORS headers

components:
  securitySchemes:
    ApiKeyAuth:
      type: apiKey
      in: header
      name: x-api-key
      description: API key required for authentication. Contact admin for access.

  schemas:
    User:
      type: object
      properties:
        id:
          type: string
        name:
          type: string
        email:
          type: string
          format: email
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time
        profile:
          type: object
        status:
          type: string
          enum: [active, inactive, suspended]

    CreateUserRequest:
      type: object
      required:
        - name
        - email
      properties:
        name:
          type: string
        email:
          type: string
          format: email
        profile:
          type: object

    Payout:
      type: object
      properties:
        id:
          type: string
        userId:
          type: string
        amount:
          type: number
        currency:
          type: string
        status:
          type: string
          enum: [pending, completed, failed]
        createdAt:
          type: string
          format: date-time
        processedAt:
          type: string
          format: date-time
        metadata:
          type: object

    Partner:
      type: object
      properties:
        id:
          type: string
        name:
          type: string
        type:
          type: string
        status:
          type: string
        contactInfo:
          type: object
        contractDetails:
          type: object

    SuccessResponse:
      type: object
      properties:
        success:
          type: boolean
          example: true
        message:
          type: string
        data:
          type: object

    ErrorResponse:
      type: object
      properties:
        success:
          type: boolean
          example: false
        message:
          type: string
        error:
          type: object
          properties:
            code:
              type: string
            details:
              type: string

    BatchOperationResponse:
      type: object
      properties:
        success:
          type: boolean
        processed:
          type: integer
        failed:
          type: integer
        results:
          type: array
          items:
            type: object

  responses:
    BadRequest:
      description: Bad request
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'

    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'

    ServerError:
      description: Internal server error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'

tags:
  - name: User Management
    description: User-related operations
  - name: Financial Operations
    description: Payout and financial operations
  - name: Partner Management
    description: Partner and relationship management
  - name: Channel Management
    description: Channel operations and configurations
  - name: Communication
    description: Email and notification services
  - name: API Management
    description: API key and access management
  - name: System
    description: System utilities and health checks
```

## Authentication & Security

### Current Authentication
- **Type**: API Key authentication required via x-api-key header
- **Implementation**: AWS Lambda custom authorizer
- **CORS**: Enabled with wildcard (*) origin (maintained for compatibility)
- **Rate Limiting**: Three-tier usage plans (100/1000/10000 requests per minute)

### Implemented Security Features
1. ✅ **API Key Authentication**: All endpoints require valid API key
2. ✅ **Rate Limiting**: Three-tier usage plans implemented
3. ✅ **Audit Logging**: Lambda authorizer logs all authentication events
4. 🔄 **Request Validation**: Schema validation planned for Phase 2
5. 🔄 **CORS Restriction**: Deferred for compatibility, ready for future implementation

## Error Handling

### Standard Error Format
```json
{
  "success": false,
  "message": "Error description",
  "error": {
    "code": "ERROR_CODE",
    "details": "Additional error details"
  }
}
```

### Common HTTP Status Codes
- **200**: Success
- **400**: Bad Request (invalid parameters)
- **401**: Unauthorized (missing or invalid API key)
- **403**: Forbidden (valid API key but insufficient permissions)
- **404**: Not Found
- **429**: Too Many Requests (rate limit exceeded)
- **500**: Internal Server Error

## Usage Examples

### Fetch Users
```bash
curl -X GET "https://<API_GATEWAY_ID_2>.execute-api.<REGION>.amazonaws.com/staging/dn_users_list?limit=10&offset=0" \
  -H "x-api-key: your-api-key-here"
```

### Send Email
```bash
curl -X POST "https://<API_GATEWAY_ID_2>.execute-api.<REGION>.amazonaws.com/staging/send-mail" \
  -H "Content-Type: application/json" \
  -H "x-api-key: your-api-key-here" \
  -d '{
    "to": ["user@example.com"],
    "subject": "Test Email",
    "body": "This is a test email",
    "isHtml": false
  }'
```

### Health Check
```bash
curl -X GET "https://<API_GATEWAY_ID_2>.execute-api.<REGION>.amazonaws.com/staging/hollow" \
  -H "x-api-key: your-api-key-here"
```

### Authentication Error Examples
```bash
# Missing API key - Returns 401
curl -X GET "https://<API_GATEWAY_ID_2>.execute-api.<REGION>.amazonaws.com/staging/dn_users_list"

# Invalid API key - Returns 403  
curl -X GET "https://<API_GATEWAY_ID_2>.execute-api.<REGION>.amazonaws.com/staging/dn_users_list" \
  -H "x-api-key: invalid-key"
```

## Integration Notes

### Lambda Function Mapping
- Each endpoint is backed by a specific Lambda function
- AWS_PROXY integration used for most endpoints
- Standard 29-second timeout applies
- Functions handle their own error responses

### Database Access
- Functions access Aurora PostgreSQL via connection pooling
- Database connections managed within Lambda execution context
- Connection secrets stored in AWS Secrets Manager

### External Service Integration
- Email sending via AWS SES
- File storage operations via S3
- Analytics data from external APIs (YouTube, Spotify)

### YouTube CMS Integration Patterns

The dn-api serves as a central integration point for YouTube CMS Metadata Management Tool operations:

#### Video Metadata Synchronization
- **Endpoint Integration**: `/send-mail` endpoint used for automated notifications about metadata sync status
- **Report Processing**: S3 integration supports YouTube CMS report ingestion workflows
- **User Management**: `/dn_users_list` provides user data for content ownership verification

#### Content Management Workflows
- **Asset Association**: API supports linking YouTube videos with internal asset management
- **Monetization Tracking**: Endpoints provide data for revenue and monetization analysis
- **Channel Management**: Integration with YouTube channel data and analytics

#### Real-time Communication Support
- **Email Notifications**: Automated alerts for sync failures, processing completion, and policy changes
- **Campaign Integration**: YouTube CMS events trigger email campaigns via CRM application
- **Audit Trail**: API calls logged for compliance and tracking purposes

#### Data Flow Integration
```
YouTube CMS Tool → dn-api → Email Notifications
YouTube CMS Tool → dn-api → User Verification
YouTube CMS Tool → dn-api → Audit Logging
```

#### Authentication & Access Patterns
- **Service Authentication**: YouTube CMS tool uses dedicated API key with appropriate permissions
- **Rate Limiting**: Configured to handle bulk synchronization operations
- **Error Handling**: Comprehensive error responses for YouTube API failures and sync issues

## Migration Considerations for Empire

### API Evolution
1. **Versioning Strategy**: Implement API versioning for backward compatibility
2. **Authentication Migration**: Plan transition to authenticated API
3. **Monitoring**: Add comprehensive API monitoring and alerting
4. **Documentation**: Maintain OpenAPI spec with code generation

### Performance Optimization
1. **Caching**: Implement response caching for frequently accessed data
2. **Connection Pooling**: Optimize database connection management
3. **Async Processing**: Move heavy operations to async processing
4. **CDN Integration**: Leverage CloudFront for global distribution