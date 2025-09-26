# FUGA WAV Uploader Architecture Overview

## Application Summary
The FUGA WAV Uploader is a full-stack web application designed for music distributors working with the FUGA platform. It provides an efficient workflow for uploading WAV audio files and associated metadata directly to the FUGA music distribution system. The application enables users to upload multi-track album projects with comprehensive metadata, album artwork, and contributor information, streamlining the music distribution process from file upload to distribution setup.

## Technology Stack

### Frontend Framework
- **React 18** with TypeScript for type-safe development
- **Material-UI (MUI)** with Chakra UI components for consistent UI design
- **Styled-components** and Emotion for component styling
- **Create React App (react-scripts)** for build tooling
- **wavefile library** for WAV metadata extraction

### Backend Framework
- **Flask (Python 3.9)** web framework with modular blueprint architecture
- **Custom FUGA API client module** for music distribution integration
- **Session-based authentication** with FUGA API
- **Gunicorn WSGI server** for production deployment
- **Docker containerization** for consistent environments

### Infrastructure & Deployment
- **AWS ECS (Elastic Container Service)** for container orchestration
- **Amazon ECR** for container registry
- **Terraform** for Infrastructure as Code
- **CloudWatch** for monitoring and logging
- **Application Load Balancer** for traffic distribution

## Application Architecture

### Component Hierarchy
```
FUGA WAV Uploader (Root)
├── Flask Backend (app.py)
│   ├── Upload Routes Blueprint (upload_routes.py)
│   ├── FUGA Authentication Blueprint (fuga_auth_routes.py)
│   ├── Product Management Blueprint (fuga_product_routes.py)
│   ├── Asset Management Blueprint (fuga_asset_routes.py)
│   ├── Data Management Blueprint (fuga_data_routes.py)
│   ├── Search Routes Blueprint (fuga_search_routes.py)
│   └── Sync Routes Blueprint (fuga_sync_routes.py)
├── React Frontend
│   ├── TrackUploader (Main Upload Interface)
│   ├── Album Components
│   │   ├── AlbumImageUploader
│   │   ├── AlbumMetadataForm
│   │   └── AlbumSummary
│   ├── Track Components
│   │   ├── TrackItem
│   │   ├── TrackList
│   │   └── TrackMetadataForm
│   ├── Common Components
│   │   ├── FileUploadButton
│   │   ├── ProgressIndicator
│   │   ├── StyledComponents
│   │   └── UploadErrorHandler
│   └── Input Components
│       ├── ChipInput
│       ├── LabelAutocomplete
│       ├── PersonChipInput
│       ├── StringChipInput
│       └── TerritoriesChipInput
└── Shared Utilities
    ├── AWS Utils (aws_utils.py)
    ├── File Utils (file_utils.py)
    ├── FUGA Utils (fuga_utils.py)
    └── Shared State (shared_state.py)
```

### Module Organization
```
Backend Modules:
├── blueprints/ (Modular route handlers)
├── utils/ (Shared utility functions)
├── modules/fuga/ (FUGA API Python client)
└── config.py (Configuration management)

Frontend Modules:
├── components/ (React UI components)
├── hooks/ (Custom React hooks)
├── services/ (API service layer)
├── types/ (TypeScript definitions)
├── utils/ (Utility functions)
├── validations/ (Form validation logic)
└── modules/fuga_api/ (FUGA API TypeScript client)
```

## Data Flow Architecture

### Authentication Flow
1. User provides FUGA API credentials through the interface
2. Flask backend authenticates with FUGA API using session management
3. Authentication token stored in backend session for subsequent requests
4. Frontend receives authentication status and enables upload functionality

### File Upload and Processing Flow
1. **File Selection & Validation**
   - User selects WAV files through drag-and-drop interface
   - Frontend validates file format and detects floating point WAV files
   - Audio metadata extracted using wavefile library
   - Files staged for upload with progress tracking

2. **Direct FUGA Upload**
   - Validated WAV files uploaded directly to Flask backend
   - Backend processes files and uploads directly to FUGA platform
   - No intermediate storage - streamlined direct integration
   - Real-time progress updates sent to frontend

3. **Metadata Processing**
   - Album-level metadata (UPC, release date, label) processed first
   - FUGA product (album) created with comprehensive metadata
   - Album artwork uploaded and associated with product
   - Individual track assets created with detailed metadata

4. **Asset Management**
   - Each WAV file becomes a FUGA asset with metadata
   - Contributors (artists, producers, writers) assigned to tracks
   - Distribution territories configured for release
   - Audio files directly uploaded to FUGA asset endpoints

### Data Synchronization
- FUGA reference data (artists, labels, people, genres) cached locally
- Automatic refresh based on configurable schedule (default: 24 hours)
- Search functionality for existing entities with auto-completion
- Backup and synchronization of cached data with version control

## Integration Points

### FUGA API Integration
- **Authentication**: Session-based login with credential management
- **Product Management**: Album creation, metadata assignment, territory configuration
- **Asset Management**: Track creation, audio upload, contributor assignment
- **Data Fetching**: Artists, labels, people, genres with caching and search
- **Error Handling**: Comprehensive FUGA API error parsing and user feedback

### AWS Services Integration
- **ECS**: Container orchestration for backend and frontend services
- **ECR**: Container image registry with automated build pipelines
- **Application Load Balancer**: Traffic distribution with health checks
- **CloudWatch**: Application logging, monitoring, and alerting
- **Route 53**: DNS management for custom domain routing

### Development Tools Integration
- **Docker Compose**: Local development environment with hot reload
- **Terraform**: Infrastructure as Code with state management
- **GitHub Actions**: CI/CD pipeline integration (if configured)

## Performance Considerations

### Frontend Optimization
- **Lazy Loading**: Components loaded on demand for faster initial render
- **Progress Tracking**: Real-time upload progress with network quality indicators
- **Error Recovery**: Retry mechanisms for failed uploads with state preservation
- **Responsive Design**: Mobile and desktop compatibility with optimized layouts
- **Caching**: Local caching of FUGA reference data for improved performance

### Backend Optimization
- **Modular Architecture**: Blueprint-based organization for maintainability
- **Connection Pooling**: Efficient FUGA API connection management
- **File Streaming**: Direct file streaming to FUGA without temporary storage
- **Data Caching**: Local storage of frequently accessed FUGA reference data
- **Error Handling**: Graceful error handling with detailed user feedback

### Infrastructure Optimization
- **Container Optimization**: Multi-stage Docker builds for smaller image sizes
- **Auto Scaling**: ECS service auto-scaling based on demand
- **Health Checks**: Comprehensive health monitoring for high availability
- **Load Balancing**: Efficient request distribution across container instances

## Development Workflow

### Local Development
- **Docker Compose**: Containerized development environment
- **Hot Reload**: Live code changes for both frontend and backend
- **Environment Variables**: Secure configuration management
- **Testing Suite**: Comprehensive API testing with FUGA integration tests

### Build and Deployment
- **Multi-stage Builds**: Optimized Docker images for production
- **Infrastructure as Code**: Terraform-managed AWS infrastructure
- **Blue-Green Deployment**: Zero-downtime deployment strategies
- **Rollback Procedures**: Quick rollback capabilities for production issues

## Monitoring and Observability

### Application Monitoring
- **CloudWatch Metrics**: Custom metrics for upload success rates, processing times
- **Health Endpoints**: Application health checks for load balancer integration
- **Error Tracking**: Comprehensive error logging with stack traces
- **Performance Metrics**: Response time monitoring and optimization insights

### Infrastructure Monitoring
- **ECS Service Monitoring**: Container health and resource utilization
- **Load Balancer Metrics**: Traffic patterns and response time analysis
- **Log Aggregation**: Centralized logging with search and alerting capabilities
- **Cost Monitoring**: AWS cost tracking and optimization recommendations

## Future Enhancements

### Planned Features
- **Batch Processing**: Multiple album upload support with queue management
- **Advanced Validation**: Enhanced audio file validation and format conversion
- **Analytics Dashboard**: Upload statistics and performance analytics
- **User Management**: Multi-user support with role-based access control

### Technical Improvements
- **API Rate Limiting**: Advanced rate limiting for FUGA API integration
- **Caching Layer**: Redis integration for improved data caching
- **Message Queuing**: Asynchronous processing for large file uploads
- **Microservices Architecture**: Service separation for improved scalability

### Integration Enhancements
- **Additional Distributors**: Support for multiple music distribution platforms
- **Metadata Standards**: Extended metadata support (DDEX, ISNI)
- **Quality Assurance**: Automated audio quality checks and validation
- **Workflow Automation**: Automated distribution workflow management