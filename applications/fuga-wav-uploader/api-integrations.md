# FUGA WAV Uploader API Integrations

## Overview

The FUGA WAV Uploader integrates with multiple APIs and services to provide a comprehensive music distribution workflow. The primary integration is with the FUGA API for music distribution, complemented by AWS services for infrastructure and deployment.

## FUGA API Integration

### Authentication and Session Management

#### Login Endpoint Integration
**Endpoint**: `POST /api/fuga/login`
**Purpose**: Authenticate with FUGA API and establish session
**Request Format**:
```json
{
  "username": "your_fuga_username",
  "password": "your_fuga_password"
}
```
**Response Format**:
```json
{
  "success": true,
  "token": "session_token",
  "user_info": {
    "username": "user",
    "permissions": ["upload", "manage"]
  }
}
```
**Integration Details**:
- Session-based authentication with token management
- Automatic token refresh and expiration handling
- Secure credential storage in backend sessions
- Frontend authentication state management

#### Session Validation
**Implementation**: Middleware validation for all FUGA API requests
**Features**:
- Automatic session validation before API calls
- Token refresh on expiration
- Graceful authentication failure handling
- User notification for authentication issues

### Product Management Integration

#### Product Creation
**Endpoint**: `POST /api/fuga/products`
**Purpose**: Create album/product in FUGA system
**Request Format**:
```json
{
  "name": "Album Title",
  "label": "Record Label",
  "upc": "123456789012",
  "p_line_text": "℗ 2024 Record Label",
  "p_line_year": 2024,
  "release_date": "2024-12-01",
  "genre": "Electronic",
  "language": "en"
}
```
**Response Format**:
```json
{
  "success": true,
  "product": {
    "id": 12345,
    "name": "Album Title",
    "status": "created",
    "fuga_url": "https://fuga.com/products/12345"
  }
}
```
**Integration Features**:
- Comprehensive album metadata validation
- UPC code format validation and generation
- Label and artist reference validation
- Territory configuration management

#### Product Retrieval
**Endpoint**: `GET /api/fuga/products/<id>`
**Purpose**: Retrieve existing product information
**Integration Features**:
- Product status tracking
- Metadata synchronization
- Distribution status monitoring
- Update conflict resolution

#### Territory Management
**Endpoint**: `PUT /api/fuga/products/<id>/territories`
**Purpose**: Configure distribution territories
**Request Format**:
```json
{
  "territories": [
    {"code": "US", "enabled": true},
    {"code": "CA", "enabled": true},
    {"code": "GB", "enabled": false}
  ]
}
```
**Integration Features**:
- Global territory selection interface
- Region-based territory grouping
- Territory validation and constraints
- Distribution scope management

#### Album Artwork Upload
**Endpoint**: `POST /api/fuga/products/<id>/image`
**Purpose**: Upload album artwork to FUGA product
**Integration Features**:
- Image format validation (JPEG, PNG)
- Image resolution requirements (minimum 1400x1400)
- Automatic image optimization
- Preview and confirmation workflow

### Asset Management Integration

#### Asset Creation
**Endpoint**: `POST /api/fuga/assets`
**Purpose**: Create track/asset in FUGA system
**Request Format**:
```json
{
  "name": "Track Title",
  "isrc": "USRC17607839",
  "duration": 180000,
  "genre": "Electronic",
  "language": "en",
  "explicit": false
}
```
**Response Format**:
```json
{
  "success": true,
  "asset": {
    "id": 67890,
    "name": "Track Title",
    "status": "created",
    "isrc": "USRC17607839"
  }
}
```
**Integration Features**:
- ISRC code validation and generation
- Track metadata validation
- Duration calculation from audio files
- Explicit content flagging

#### Asset Assignment to Products
**Endpoint**: `POST /api/fuga/products/<id>/assets`
**Purpose**: Add asset to product (album)
**Integration Features**:
- Track ordering within albums
- Asset-product relationship management
- Bulk asset assignment
- Track listing validation

#### Audio File Upload
**Endpoint**: `POST /api/fuga/assets/<id>/audio`
**Purpose**: Upload audio file directly to FUGA asset
**Integration Features**:
- Direct WAV file streaming to FUGA
- Audio format validation (PCM WAV only)
- Floating point WAV rejection with user feedback
- Upload progress tracking and error handling
- File integrity validation

#### Audio Format Validation
**Implementation**: ffmpeg integration for audio analysis
**Validation Process**:
1. Audio file analysis using ffmpeg probe
2. Codec detection for floating point formats
3. Sample rate and bit depth validation
4. Duration and channel configuration verification
5. User-friendly error messages for format issues

**Supported Formats**:
- PCM WAV files (16-bit, 24-bit, 32-bit integer)
- Standard sample rates (44.1kHz, 48kHz, 96kHz, etc.)
- Mono and stereo channel configurations

**Rejected Formats**:
- Floating point WAV files (32-bit float, 64-bit float)
- Compressed audio formats (MP3, FLAC, AAC)
- Non-standard sample rates or configurations

#### Contributor Management
**Endpoint**: `POST /api/fuga/assets/<id>/contributors`
**Purpose**: Add contributors to track assets
**Request Format**:
```json
{
  "contributors": [
    {
      "person_id": 123,
      "role": "primary_artist",
      "name": "Artist Name"
    },
    {
      "person_id": 456,
      "role": "producer",
      "name": "Producer Name"
    }
  ]
}
```
**Integration Features**:
- Multiple contributor roles per track
- Artist and person reference validation
- Role-specific metadata requirements
- Contributor credit management

### Data Management Integration

#### Reference Data Caching
**Endpoints**:
- `GET /api/fuga/artists` - Cached artists list
- `GET /api/fuga/labels` - Cached labels list  
- `GET /api/fuga/people` - Cached people/contributors list
- `GET /api/fuga/genres` - Cached genres list

**Integration Features**:
- Local JSON file caching for performance
- Automatic refresh scheduling (default: 24 hours)
- Manual refresh triggers
- Data backup and versioning
- Search and filtering capabilities

#### Search Functionality
**Endpoints**:
- `GET /api/fuga/artist/<name>/search` - Artist search
- `GET /api/fuga/person/<name>/search` - Person search  
- `GET /api/fuga/labels/<name>/search` - Label search

**Integration Features**:
- Fuzzy matching algorithms
- Real-time search suggestions
- Result ranking and scoring
- Performance-optimized local search

#### Data Synchronization
**Endpoints**:
- `POST /api/fuga/refresh-data` - Manual data refresh
- `GET /api/fuga/data-status` - Sync status information

**Integration Features**:
- Scheduled automatic synchronization
- Manual refresh capabilities
- Sync status tracking and reporting
- Error handling for sync failures
- Data consistency validation

## Error Handling and Response Processing

### FUGA API Error Parsing
**Implementation**: Comprehensive error response parsing
**Error Categories**:
- Authentication errors (invalid credentials, expired sessions)
- Validation errors (invalid UPC, ISRC, metadata)
- File format errors (floating point WAV, invalid formats)
- Rate limiting errors (API quota exceeded)
- Server errors (FUGA service unavailability)

**Error Response Format**:
```json
{
  "success": false,
  "error": "Detailed error message",
  "error_code": "FUGA_ERROR_CODE",
  "context": {
    "field": "upc",
    "value": "invalid_upc_code",
    "constraint": "UPC_CODE_WRONG"
  }
}
```

### User-Friendly Error Messages
**Implementation**: Error message translation and formatting
**Features**:
- Technical error translation to user-friendly language
- Actionable error messages with resolution steps
- Context-aware error handling
- Error categorization for appropriate user responses

**Example Error Translations**:
- `UPC_CODE_WRONG` → "UPC code format is invalid. Please check the 12-digit code."
- `FIELD_VALUE_NOT_IN_RANGE` → "P Line Year must be a valid 4-digit year."
- `Floating point detected` → "WAV file is in floating point format. Please convert to integer PCM format."

## AWS Services Integration

### ECS (Elastic Container Service)
**Purpose**: Container orchestration and deployment
**Integration Features**:
- Containerized backend and frontend services
- Auto-scaling based on demand
- Health check integration
- Zero-downtime deployments
- Resource management and optimization

### ECR (Elastic Container Registry)
**Purpose**: Container image storage and management
**Integration Features**:
- Automated image builds and pushes
- Image versioning and tagging
- Security scanning integration
- Multi-stage build optimization

### Application Load Balancer
**Purpose**: Traffic distribution and SSL termination
**Integration Features**:
- HTTPS certificate management
- Health check endpoints
- Request routing and load balancing
- SSL/TLS termination

### CloudWatch
**Purpose**: Monitoring and logging
**Integration Features**:
- Application performance metrics
- Error rate monitoring
- Custom metrics for upload success rates
- Log aggregation and analysis
- Alert configuration for critical issues

## API Rate Limiting and Performance

### Rate Limiting Strategy
**Implementation**: Respectful API usage with FUGA platform
**Features**:
- Request throttling to prevent API quota exhaustion
- Retry logic with exponential backoff
- Queue management for bulk operations
- User feedback for rate limiting situations

### Performance Optimization
**Strategies**:
- Local caching of reference data to reduce API calls
- Batch operations for multiple track uploads
- Efficient error handling to prevent unnecessary retries
- Connection pooling for API requests

### Monitoring and Analytics
**Metrics Tracked**:
- API response times and success rates
- Upload completion rates and error frequency
- User workflow completion statistics
- System performance and resource utilization

## Security Considerations

### Credential Management
**Implementation**: Secure handling of sensitive information
**Features**:
- Environment variable configuration for credentials
- No hardcoded API keys or passwords in code
- Session-based authentication with secure token storage
- Automatic credential rotation support

### Data Protection
**Measures**:
- HTTPS enforcement for all API communications
- Secure session management with appropriate expiration
- Input validation and sanitization
- Protection against injection attacks

### Access Control
**Implementation**:
- Role-based access to FUGA API functions
- User permission validation
- Secure API endpoint access control
- Audit logging for administrative actions

## Integration Testing and Validation

### API Testing Suite
**Implementation**: Comprehensive test coverage for all integrations
**Test Coverage**:
- Authentication flow validation
- Product and asset creation workflows
- File upload and validation processes
- Error handling and recovery scenarios
- Data synchronization and caching

### Integration Health Monitoring
**Monitoring Points**:
- FUGA API availability and response times
- Upload success rates and error frequencies
- Data synchronization status and freshness
- System resource utilization and performance

This comprehensive API integration documentation ensures reliable, secure, and efficient communication between the FUGA WAV Uploader and all external services, providing users with a seamless music distribution experience.