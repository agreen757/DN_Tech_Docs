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
      summary: List Users
      description: Retrieve list of users with optional filtering
      operationId: listUsers
      parameters:
        - name: limit
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
        - name: offset
          in: query
          schema:
            type: integer
            minimum: 0
            default: 0
        - name: filter
          in: query
          schema:
            type: string
      responses:
        '200':
          description: List of users
          content:
            application/json:
              schema:
                type: object
                properties:
                  users:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
                  total:
                    type: integer
                  limit:
                    type: integer
                  offset:
                    type: integer
      tags:
        - User Management
    
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