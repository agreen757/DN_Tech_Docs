# distronationfmGeneralAccess OpenAPI Specification

## API Overview
- **API Name**: distronationfmGeneralAccess
- **Base URL**: `https://<API_GATEWAY_ID_1>.execute-api.<REGION>.amazonaws.com/main`
- **Version**: 2018-05-24T17:52:00Z
- **Description**: DistroFM application-specific API for content operations and media management
- **Authentication**: AWS IAM (Signature Version 4)

## OpenAPI 3.0 Specification

```yaml
openapi: 3.0.0
info:
  title: DistroFM General Access API
  description: DistroFM application-specific API for content operations and media management
  version: 2018-05-24T17:52:00Z
  contact:
    name: Distro Nation Engineering
    email: adrian@distronation.com

servers:
  - url: https://<API_GATEWAY_ID_1>.execute-api.<REGION>.amazonaws.com/main
    description: Production main environment

security:
  - AWSSignatureAuth: []

paths:
  /artist-info/{id}:
    get:
      summary: Get Artist Information
      description: Retrieve detailed information about a specific artist
      operationId: getArtistInfo
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
          description: Unique artist identifier
        - name: includeMetrics
          in: query
          schema:
            type: boolean
            default: false
          description: Include performance metrics in response
        - name: platform
          in: query
          schema:
            type: string
            enum: [youtube, spotify, tiktok, all]
          description: Filter data by platform
      responses:
        '200':
          description: Artist information retrieved successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ArtistInfoResponse'
        '404':
          description: Artist not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '403':
          description: Access denied
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      tags:
        - Artist Management

    post:
      summary: Update Artist Information
      description: Update artist profile and metadata
      operationId: updateArtistInfo
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UpdateArtistRequest'
      responses:
        '200':
          description: Artist updated successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/SuccessResponse'
        '400':
          description: Invalid artist data
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      tags:
        - Artist Management

    options:
      summary: CORS Preflight
      description: Handle CORS preflight requests for artist info endpoint
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
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

  /artist-info/{id}/{proxy+}:
    get:
      summary: Get Artist Info with Proxy Path
      description: Retrieve artist information with additional proxy path parameters
      operationId: getArtistInfoProxy
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
          description: Artist identifier
        - name: proxy+
          in: path
          required: true
          schema:
            type: string
          description: Additional path parameters for specific data requests
      responses:
        '200':
          description: Artist information with proxy data
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ProxyResponse'
      tags:
        - Artist Management

    post:
      summary: Update Artist Info via Proxy
      description: Update artist information through proxy path
      operationId: updateArtistInfoProxy
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
        - name: proxy+
          in: path
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ProxyRequest'
      responses:
        '200':
          description: Update successful
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/SuccessResponse'
      tags:
        - Artist Management

    options:
      summary: CORS Preflight for Proxy
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
        - name: proxy+
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: CORS headers

  /submit-video:
    post:
      summary: Submit Video
      description: Submit video content for processing and distribution
      operationId: submitVideo
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/VideoSubmissionRequest'
          multipart/form-data:
            schema:
              type: object
              properties:
                file:
                  type: string
                  format: binary
                metadata:
                  type: string
                  description: JSON string with video metadata
      responses:
        '201':
          description: Video submitted successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/VideoSubmissionResponse'
        '400':
          description: Invalid video data
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '413':
          description: File too large
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      tags:
        - Content Management

    get:
      summary: Get Video Submissions
      description: Retrieve list of video submissions
      operationId: getVideoSubmissions
      parameters:
        - name: status
          in: query
          schema:
            type: string
            enum: [pending, processing, completed, failed]
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
      responses:
        '200':
          description: List of video submissions
          content:
            application/json:
              schema:
                type: object
                properties:
                  submissions:
                    type: array
                    items:
                      $ref: '#/components/schemas/VideoSubmission'
                  total:
                    type: integer
                  limit:
                    type: integer
                  offset:
                    type: integer
      tags:
        - Content Management

    options:
      summary: CORS Preflight
      responses:
        '200':
          description: CORS headers

  /submit-video/{proxy+}:
    post:
      summary: Submit Video with Proxy Path
      description: Submit video with additional processing parameters
      operationId: submitVideoProxy
      parameters:
        - name: proxy+
          in: path
          required: true
          schema:
            type: string
          description: Processing parameters and options
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/VideoSubmissionRequest'
      responses:
        '201':
          description: Video submitted with proxy processing
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/VideoSubmissionResponse'
      tags:
        - Content Management

    options:
      summary: CORS Preflight for Video Proxy
      parameters:
        - name: proxy+
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: CORS headers

  /parse/{id}:
    get:
      summary: Parse Content
      description: Parse and analyze content by ID
      operationId: parseContent
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
          description: Content identifier to parse
        - name: format
          in: query
          schema:
            type: string
            enum: [json, xml, text]
            default: json
          description: Output format for parsed content
        - name: includeMetadata
          in: query
          schema:
            type: boolean
            default: true
          description: Include metadata in parse results
      responses:
        '200':
          description: Content parsed successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ParsedContentResponse'
        '404':
          description: Content not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      tags:
        - Content Processing

    post:
      summary: Parse Content with Parameters
      description: Parse content with custom parsing parameters
      operationId: parseContentWithParams
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ParseRequest'
      responses:
        '200':
          description: Content parsed with custom parameters
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ParsedContentResponse'
      tags:
        - Content Processing

    options:
      summary: CORS Preflight
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: CORS headers

  /parse/{id}/{proxy+}:
    get:
      summary: Parse Content with Proxy Path
      description: Parse content with additional proxy parameters
      operationId: parseContentProxy
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
        - name: proxy+
          in: path
          required: true
          schema:
            type: string
          description: Additional parsing parameters
      responses:
        '200':
          description: Content parsed with proxy parameters
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ProxyResponse'
      tags:
        - Content Processing

    post:
      summary: Parse Content via Proxy
      description: Parse content through proxy path with custom data
      operationId: parseContentViaProxy
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
        - name: proxy+
          in: path
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ProxyRequest'
      responses:
        '200':
          description: Content parsed via proxy
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ProxyResponse'
      tags:
        - Content Processing

    options:
      summary: CORS Preflight for Parse Proxy
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
        - name: proxy+
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: CORS headers

  /evalvideoid/{id}:
    get:
      summary: Evaluate Video ID
      description: Evaluate and validate video ID for processing
      operationId: evaluateVideoId
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
          description: Video ID to evaluate
        - name: platform
          in: query
          schema:
            type: string
            enum: [youtube, vimeo, tiktok]
          description: Platform where video exists
        - name: validateExistence
          in: query
          schema:
            type: boolean
            default: true
          description: Validate if video exists on platform
      responses:
        '200':
          description: Video ID evaluation complete
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/VideoEvaluationResponse'
        '400':
          description: Invalid video ID format
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '404':
          description: Video not found on platform
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      tags:
        - Video Processing

    post:
      summary: Evaluate Video ID with Data
      description: Evaluate video ID with additional validation data
      operationId: evaluateVideoIdWithData
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/VideoEvaluationRequest'
      responses:
        '200':
          description: Video ID evaluated with additional data
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/VideoEvaluationResponse'
      tags:
        - Video Processing

    options:
      summary: CORS Preflight
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: CORS headers

  /evalvideoid/{id}/{proxy+}:
    get:
      summary: Evaluate Video ID with Proxy
      description: Evaluate video ID with proxy path parameters
      operationId: evaluateVideoIdProxy
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
        - name: proxy+
          in: path
          required: true
          schema:
            type: string
          description: Additional evaluation parameters
      responses:
        '200':
          description: Video ID evaluated with proxy parameters
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ProxyResponse'
      tags:
        - Video Processing

    post:
      summary: Evaluate Video ID via Proxy
      description: Evaluate video ID through proxy with custom parameters
      operationId: evaluateVideoIdViaProxy
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
        - name: proxy+
          in: path
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ProxyRequest'
      responses:
        '200':
          description: Video ID evaluated via proxy
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ProxyResponse'
      tags:
        - Video Processing

    options:
      summary: CORS Preflight for Video Eval Proxy
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
        - name: proxy+
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: CORS headers

components:
  securitySchemes:
    AWSSignatureAuth:
      type: apiKey
      name: Authorization
      in: header
      description: AWS Signature Version 4 authentication

  schemas:
    ArtistInfoResponse:
      type: object
      properties:
        response:
          type: string
          description: Base response wrapper
        artist:
          type: object
          properties:
            id:
              type: string
            name:
              type: string
            bio:
              type: string
            genres:
              type: array
              items:
                type: string
            socialMedia:
              type: object
              properties:
                youtube:
                  type: string
                spotify:
                  type: string
                tiktok:
                  type: string
                instagram:
                  type: string
            metrics:
              type: object
              properties:
                totalViews:
                  type: integer
                totalStreams:
                  type: integer
                monthlyListeners:
                  type: integer
                followers:
                  type: object
        metadata:
          type: object
          properties:
            lastUpdated:
              type: string
              format: date-time
            dataSource:
              type: string

    UpdateArtistRequest:
      type: object
      properties:
        request:
          type: string
          description: Base request wrapper
        artistData:
          type: object
          properties:
            name:
              type: string
            bio:
              type: string
            genres:
              type: array
              items:
                type: string
            socialMedia:
              type: object
            profileImage:
              type: string
              format: uri

    VideoSubmissionRequest:
      type: object
      properties:
        title:
          type: string
        description:
          type: string
        tags:
          type: array
          items:
            type: string
        artistId:
          type: string
        category:
          type: string
          enum: [music, interview, live, behind-scenes]
        visibility:
          type: string
          enum: [public, private, unlisted]
        scheduledAt:
          type: string
          format: date-time
        thumbnailUrl:
          type: string
          format: uri
        metadata:
          type: object

    VideoSubmissionResponse:
      type: object
      properties:
        response:
          type: string
        submissionId:
          type: string
        status:
          type: string
          enum: [pending, processing, completed, failed]
        uploadUrl:
          type: string
          format: uri
        processingEstimate:
          type: integer
          description: Estimated processing time in minutes

    VideoSubmission:
      type: object
      properties:
        id:
          type: string
        title:
          type: string
        artistId:
          type: string
        status:
          type: string
          enum: [pending, processing, completed, failed]
        submittedAt:
          type: string
          format: date-time
        processedAt:
          type: string
          format: date-time
        fileSize:
          type: integer
        duration:
          type: integer
        formats:
          type: array
          items:
            type: string

    ParsedContentResponse:
      type: object
      properties:
        response:
          type: string
        contentId:
          type: string
        parsedData:
          type: object
        metadata:
          type: object
          properties:
            parseTime:
              type: number
            contentType:
              type: string
            size:
              type: integer
        errors:
          type: array
          items:
            type: object
            properties:
              code:
                type: string
              message:
                type: string
              line:
                type: integer

    ParseRequest:
      type: object
      properties:
        request:
          type: string
        options:
          type: object
          properties:
            format:
              type: string
            validation:
              type: boolean
            extractMetadata:
              type: boolean
            customRules:
              type: array
              items:
                type: object

    VideoEvaluationResponse:
      type: object
      properties:
        response:
          type: string
        videoId:
          type: string
        platform:
          type: string
        valid:
          type: boolean
        exists:
          type: boolean
        metadata:
          type: object
          properties:
            title:
              type: string
            duration:
              type: string
            publishedAt:
              type: string
              format: date-time
            viewCount:
              type: integer
            quality:
              type: string
        recommendations:
          type: array
          items:
            type: string

    VideoEvaluationRequest:
      type: object
      properties:
        request:
          type: string
        validationOptions:
          type: object
          properties:
            checkExists:
              type: boolean
            fetchMetadata:
              type: boolean
            validateQuality:
              type: boolean
            platform:
              type: string

    ProxyRequest:
      type: object
      properties:
        request:
          type: string
        proxyData:
          type: object
        parameters:
          type: object

    ProxyResponse:
      type: object
      properties:
        response:
          type: string
        proxyResult:
          type: object
        metadata:
          type: object

    SuccessResponse:
      type: object
      properties:
        response:
          type: string
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
        response:
          type: string
        success:
          type: boolean
          example: false
        error:
          type: object
          properties:
            code:
              type: string
            message:
              type: string
            details:
              type: object

  responses:
    BadRequest:
      description: Bad request
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'

    Unauthorized:
      description: Unauthorized - AWS IAM authentication required
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'

    Forbidden:
      description: Access denied
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

    TooManyRequests:
      description: Rate limit exceeded
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
  - name: Artist Management
    description: Artist profile and information management
  - name: Content Management
    description: Video and content submission operations
  - name: Content Processing
    description: Content parsing and analysis
  - name: Video Processing
    description: Video ID evaluation and validation
```

## Authentication & Security

### AWS IAM Authentication
- **Type**: AWS Signature Version 4
- **Headers**: Authorization header with AWS signature
- **Scope**: All endpoints require AWS IAM authentication
- **Permissions**: Access controlled via IAM policies

### Rate Limiting
- **Burst Limit**: 5,000 requests
- **Rate Limit**: 10,000 requests per second
- **Throttling**: Applied at method level

### CORS Configuration
- **Preflight Requests**: OPTIONS method available on all endpoints
- **Headers**: Standard CORS headers supported
- **Origins**: Configured via CloudFormation

## Request/Response Patterns

### Standard Request Schema
All POST requests use the RequestSchema pattern:
```json
{
  "request": "string_value"
}
```

### Standard Response Schema
All responses use the ResponseSchema pattern:
```json
{
  "response": "string_value"
}
```

### Proxy Path Pattern
Endpoints with `{proxy+}` accept additional path parameters for flexible routing and parameter passing.

## Usage Examples

### Get Artist Information (with AWS CLI)
```bash
aws apigatewayv2 invoke \
  --api-id <API_GATEWAY_ID_1> \
  --stage main \
  --route-key "GET /artist-info/12345" \
  response.json
```

### Submit Video (with signature)
```bash
curl -X POST "https://<API_GATEWAY_ID_1>.execute-api.<REGION>.amazonaws.com/main/submit-video" \
  -H "Authorization: AWS4-HMAC-SHA256 ..." \
  -H "Content-Type: application/json" \
  -d '{
    "title": "New Music Video",
    "description": "Latest single release",
    "artistId": "artist123",
    "category": "music",
    "visibility": "public"
  }'
```

### Parse Content
```bash
curl -X GET "https://<API_GATEWAY_ID_1>.execute-api.<REGION>.amazonaws.com/main/parse/content123?format=json&includeMetadata=true" \
  -H "Authorization: AWS4-HMAC-SHA256 ..."
```

## Lambda Function Integration

### Primary Functions
- **distrofmFetchArtistInfo-main**: Handles artist information requests
- **Video Processing Functions**: Handle video submission and evaluation
- **Content Parsing Functions**: Process and analyze content

### Integration Pattern
- **Type**: AWS_PROXY integration
- **Timeout**: 29 seconds
- **Error Handling**: Lambda functions return formatted error responses
- **Logging**: CloudWatch logs with INFO level enabled

## Data Flow Architecture

### Artist Information Flow
1. **Request**: Client → API Gateway → Lambda
2. **Processing**: Lambda → Aurora PostgreSQL → External APIs
3. **Response**: Formatted data → API Gateway → Client

### Video Submission Flow
1. **Submission**: Client → API Gateway → Lambda
2. **Storage**: Lambda → S3 bucket → Processing queue
3. **Processing**: Async processing → Database updates
4. **Notification**: Status updates via WebSocket or polling

### Content Parsing Flow
1. **Request**: Client → API Gateway → Lambda
2. **Parsing**: Lambda → Content analysis → Metadata extraction
3. **Storage**: Results → Database → Search index
4. **Response**: Parsed data → Client

## Performance Characteristics

### API Gateway Limits
- **Request Size**: 10MB maximum
- **Response Size**: 10MB maximum  
- **Timeout**: 29 seconds
- **Concurrent Executions**: Based on Lambda limits

### Caching Strategy
- **Cache TTL**: 300 seconds (5 minutes)
- **Cache Keys**: Based on request parameters
- **Invalidation**: Manual or time-based

### Monitoring
- **Metrics**: Request count, latency, error rate
- **Logging**: INFO level with data trace enabled
- **Alarms**: CloudWatch alarms for error thresholds

## Integration Recommendations

### Immediate Improvements
1. **API Documentation**: Generate interactive documentation from OpenAPI spec
2. **Client SDKs**: Generate client libraries for common languages
3. **Testing**: Implement automated API testing suite
4. **Monitoring**: Enhanced monitoring and alerting

### Security Enhancements
1. **Request Validation**: Implement JSON schema validation
2. **Response Filtering**: Add response data filtering
3. **Audit Logging**: Enhanced logging for compliance
4. **Rate Limiting**: Fine-tune rate limits based on usage patterns

### Performance Optimization
1. **Connection Pooling**: Optimize Lambda database connections
2. **Async Processing**: Move heavy operations to background processing
3. **CDN Integration**: Leverage CloudFront for caching
4. **Regional Deployment**: Consider multi-region deployment for global users