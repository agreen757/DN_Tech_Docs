# YouTube CMS Metadata Management Tool - Component Catalog

## Overview

This document provides a comprehensive catalog of all components within the YouTube CMS Metadata Management Tool, organized by functional areas and technical layers. Each component is documented with its purpose, dependencies, and integration points.

## Database Models

### Video Model (`models.py`)

**Purpose**: Core entity representing YouTube videos with comprehensive metadata management.

**Key Attributes**:
```python
class Video(db.Model):
    # Identity & Basic Info
    id = db.Column(db.Integer, primary_key=True)
    video_id = db.Column(db.String(20), unique=True, nullable=False)
    asset_id = db.Column(db.String(50), nullable=True)
    title = db.Column(db.String(200))
    custom_id = db.Column(db.String(100), nullable=True)
    
    # Content Metadata (Music Industry Standards)
    artist = db.Column(db.ARRAY(db.String(200)), nullable=True)  # Multiple artists
    genre = db.Column(db.ARRAY(db.String(100)), nullable=True)   # Multiple genres
    label = db.Column(db.String(200), nullable=True)             # Record label
    upc = db.Column(db.String(20), nullable=True)               # Universal Product Code
    isrc = db.Column(db.String(12), nullable=True)              # International Standard Recording Code
    
    # Content Status & Ownership
    privacy_status = db.Column(db.String(20))
    claimed_status = db.Column(db.String(10), nullable=True)
    other_owners_claiming = db.Column(db.Text, nullable=True)
    claimed_by_another_owner = db.Column(db.String(10), nullable=True)
    
    # Content Settings
    embedding_allowed = db.Column(db.String(10), nullable=True)
    ratings_allowed = db.Column(db.String(10), nullable=True)
    comments_allowed = db.Column(db.String(10), nullable=True)
    
    # Monetization Configuration
    effective_policy = db.Column(db.Text, default='')
    third_party_ads_enabled = db.Column(db.String(10), nullable=True)
    display_ads_enabled = db.Column(db.String(10), nullable=True)
    sponsored_cards_enabled = db.Column(db.String(10), nullable=True)
    overlay_ads_enabled = db.Column(db.String(10), nullable=True)
    # ... additional ad configuration fields
    
    # Video Properties
    category = db.Column(db.String(50), nullable=True, index=True)
    video_length = db.Column(db.Integer, nullable=True)  # Duration in seconds
    is_short = db.Column(db.Boolean, default=False)
    is_live_stream = db.Column(db.Boolean, default=False)
    
    # Management Fields
    notes = db.Column(db.String(500), nullable=True)
    administered = db.Column(db.Boolean, default=False)
    administered_at = db.Column(db.DateTime, nullable=True)
    hidden = db.Column(db.Boolean, default=False)
    
    # Timestamps
    time_published = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
```

**Usage Patterns**:
- Primary entity for all video-related operations
- Complex filtering and search operations
- Bulk update operations for metadata management
- Real-time synchronization with YouTube API

### Channel Model (`models.py`)

**Purpose**: Manages YouTube channel information and analytics tracking.

**Key Attributes**:
```python
class Channel(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    channel_id = db.Column(db.String(100), unique=True, nullable=False)
    name = db.Column(db.String(200), nullable=False)
    image_url = db.Column(db.String(500))
    
    # Analytics Data (BigInteger for large numbers)
    subscriber_count = db.Column(db.BigInteger)
    video_count = db.Column(db.BigInteger)
    view_count = db.Column(db.BigInteger)
    
    # Status Information
    is_monetized = db.Column(db.Boolean, default=False)
    hidden = db.Column(db.Boolean, default=False)
    description = db.Column(db.Text)
    country = db.Column(db.String(2))  # Country code
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
```

**Usage Patterns**:
- Channel discovery and management
- Analytics tracking and reporting
- Monetization status monitoring
- Cross-reference with video content

### Report Model (`models.py`)

**Purpose**: Tracks file processing operations and status monitoring.

**Key Attributes**:
```python
class Report(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    filename = db.Column(db.String(200))
    processed_at = db.Column(db.DateTime, default=datetime.utcnow)
    status = db.Column(db.String(20))  # processing, completed, error
    error_message = db.Column(db.Text, nullable=True)
```

**Usage Patterns**:
- S3 report processing workflow
- Error tracking and debugging
- Processing status monitoring
- Audit trail for file operations

### Specialized Content Models

#### YouTubeShorts Model (`models.py`)
**Purpose**: Dedicated tracking for YouTube Shorts content detection.

```python
class YouTubeShorts(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    video_id = db.Column(db.String(20), unique=True, nullable=False)
    detected_at = db.Column(db.DateTime, default=datetime.utcnow)
```

#### NonYouTubeShorts Model (`models.py`)
**Purpose**: Manual verification system for non-Shorts content.

```python
class NonYouTubeShorts(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    video_id = db.Column(db.String(20), unique=True, nullable=False)
    verified_at = db.Column(db.DateTime, default=datetime.utcnow)
```

#### MetadataSync Model (`models.py`)
**Purpose**: Tracks synchronization operations between internal database and YouTube API.

**Features**:
- Synchronization timestamp tracking
- Change detection and logging
- Sync status monitoring
- Error handling for failed synchronizations

## Route Handlers & API Endpoints

### Video Management Routes (`routes.py`)

#### GET /api/videos
**Purpose**: Retrieve paginated video list with advanced filtering capabilities.

**Query Parameters**:
```python
- page: int (default: 1) - Page number for pagination
- per_page: int (default: 20) - Results per page
- search: str - Title search term
- channel_search: str - Channel name search
- category: str - Video category filter
- duration: str - Duration filter (short/medium/long)
- video_id: str - Specific video ID search
- asset_id: str - Asset ID search
- has_asset_id: str - Filter by asset ID presence (yes/no)
- policy: str - Monetization policy filter
- date_from: str - Start date filter (YYYY-MM-DD)
- date_to: str - End date filter (YYYY-MM-DD)
- claimed_by_another: str - Ownership claim filter
- sort_by: str - Sort field
- order: str - Sort direction (asc/desc)
```

**Response Format**:
```json
{
    "videos": [
        {
            "id": "integer",
            "video_id": "string",
            "title": "string",
            "artist": ["string"],
            "genre": ["string"],
            "privacy_status": "string",
            "monetization_status": "string",
            "last_synced": "datetime",
            "administered": "boolean"
        }
    ],
    "pagination": {
        "page": "integer",
        "per_page": "integer",
        "total": "integer",
        "pages": "integer"
    }
}
```

**Features**:
- Complex filtering with multiple criteria
- Full-text search capabilities
- Pagination with configurable page sizes
- Sorting by multiple fields
- Real-time data with sync status

#### POST /api/videos/update-status
**Purpose**: Bulk update video status and administration flags.

**Request Body**:
```json
{
    "video_ids": ["string"],
    "notes": "string",
    "administered": "boolean"
}
```

**Features**:
- Bulk operations for efficiency
- Audit trail logging
- Real-time notifications
- Error handling for partial failures

#### POST /api/videos/{video_id}/sync
**Purpose**: Synchronize individual video metadata with YouTube API.

**Request Body**:
```json
{
    "artist": "string",
    "customId": "string",
    "isrc": "string",
    "upc": "string"
}
```

**Features**:
- Individual video synchronization
- Metadata validation
- Error handling and reporting
- Status tracking in MetadataSync model

### Channel Management Routes (`routes.py`)

#### GET /api/admin/channels
**Purpose**: Administrative interface for channel management.

**Query Parameters**:
```python
- page: int - Page number
- per_page: int - Results per page
- search: str - Channel name search
- monetization: str - Monetization status filter
```

**Features**:
- Administrative access control
- Channel analytics display
- Monetization status tracking
- Bulk channel operations

#### POST /api/admin/channels/{channel_name}/update
**Purpose**: Update channel information and settings.

**Request Body**:
```json
{
    "new_name": "string"
}
```

### Report Processing Routes (`routes.py`)

#### POST /api/process-report
**Purpose**: Initiate report processing from S3 storage.

**Features**:
- S3 file detection and download
- CSV parsing and data extraction
- Database bulk operations
- Error handling and logging
- Real-time progress updates

#### GET /api/process-status
**Purpose**: Check current report processing status.

**Response Format**:
```json
{
    "status": "string",  // completed, processing, error
    "processed_at": "datetime",
    "error_message": "string"
}
```

## Utility Modules

### S3 Integration (`utils/s3.py`)

**Purpose**: Handle all AWS S3 operations for report processing and file management.

**Key Functions**:
```python
def download_s3_report():
    """Download latest report from S3 bucket"""
    
def upload_backup_file():
    """Upload database backup to S3"""
    
def list_available_reports():
    """List all available reports in S3 bucket"""
```

**Features**:
- Secure credential management
- Error handling and retries
- File validation and verification
- Progress tracking for large files

### Database Backup (`utils/db_backup.py`)

**Purpose**: Automated database backup and recovery operations.

**Key Functions**:
```python
class DatabaseBackup:
    def create_backup():
        """Create timestamped database backup"""
        
    def restore_backup():
        """Restore from specific backup file"""
        
    def schedule_backups():
        """Schedule automated backup operations"""
```

**Features**:
- Automated scheduling
- Compression and optimization
- S3 integration for remote storage
- Recovery verification

### Token Management (`token_fetcher.py`)

**Purpose**: Secure handling of API credentials and tokens.

**Key Functions**:
```python
class TokenFetcher:
    def get_youtube_token():
        """Retrieve YouTube API access token"""
        
    def refresh_token():
        """Refresh expired tokens"""
        
    def validate_credentials():
        """Validate API credentials"""
```

**Features**:
- Secure credential storage
- Token refresh automation
- Error handling for expired tokens
- Multi-service token management

## Frontend Components

### Main Interface (`templates/index.html`)

**Purpose**: Primary user interface for video metadata management.

**Key Features**:
- Video listing with advanced filtering
- Real-time search functionality
- Bulk selection and operations
- Responsive design for mobile access
- WebSocket integration for live updates

**JavaScript Components**:
```javascript
// Real-time updates
const socket = io();
socket.on('video_update', function(data) {
    updateVideoRow(data);
});

// Advanced filtering
function applyFilters() {
    const filters = {
        search: $('#search').val(),
        category: $('#category').val(),
        duration: $('#duration').val()
    };
    loadVideos(filters);
}

// Bulk operations
function bulkUpdateVideos() {
    const selectedIds = getSelectedVideoIds();
    performBulkUpdate(selectedIds);
}
```

### Admin Interface (`templates/admin.html`)

**Purpose**: Administrative dashboard for system management.

**Key Features**:
- Channel management interface
- Report processing controls
- System status monitoring
- User access management
- Database operation controls

**Administrative Functions**:
```javascript
// Report processing
function processReport() {
    fetch('/api/process-report', {method: 'POST'})
        .then(response => response.json())
        .then(data => updateProcessingStatus(data));
}

// Channel management
function updateChannel(channelId, data) {
    fetch(`/api/admin/channels/${channelId}/update`, {
        method: 'POST',
        body: JSON.stringify(data)
    });
}
```

### Styling Components (`static/css/`)

**Purpose**: Responsive and accessible user interface styling.

**Key Features**:
- Mobile-first responsive design
- Accessibility compliance (WCAG 2.1)
- Dark/light theme support
- Print-friendly layouts
- Loading states and animations

## Real-time Components

### WebSocket Handler (`app.py`)

**Purpose**: Real-time bidirectional communication between client and server.

**Event Types**:
```python
@socketio.on('connect')
def handle_connect():
    """Handle client connection"""
    
@socketio.on('disconnect')
def handle_disconnect():
    """Handle client disconnection"""
    
def emit_video_update(video_data):
    """Broadcast video updates to all clients"""
    socketio.emit('video_update', video_data)
    
def emit_processing_status(status):
    """Broadcast processing status updates"""
    socketio.emit('processing_update', status)
```

**Features**:
- Connection management
- Room-based messaging
- Error handling and reconnection
- Performance optimization

## Database Components

### Migration System (`migrations/`)

**Purpose**: Database schema versioning and evolution management.

**Key Files**:
- `env.py`: Migration environment configuration
- `alembic.ini`: Migration settings and connection parameters
- `versions/`: Individual migration scripts
- `script.py.mako`: Migration template

**Migration Features**:
- Automatic schema detection
- Rollback capabilities
- Data migration support
- Multi-environment support

### Database Configuration (`database.py`)

**Purpose**: Database connection and configuration management.

```python
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

# Connection pooling configuration
SQLALCHEMY_ENGINE_OPTIONS = {
    "pool_recycle": 300,
    "pool_pre_ping": True,
    "pool_size": 10,
    "max_overflow": 20,
    "pool_timeout": 30,
}
```

## Integration Components

### YouTube API Integration

**Purpose**: Bidirectional synchronization with YouTube Content Management System.

**Key Operations**:
- Metadata retrieval and updates
- Content ownership verification
- Monetization policy synchronization
- Status monitoring and reporting

### AWS Services Integration

**Purpose**: Cloud storage and processing capabilities.

**Integrated Services**:
- **S3**: Report storage and backup management
- **IAM**: Access control and security
- **CloudWatch**: Monitoring and logging (future enhancement)

## Error Handling Components

### Global Error Handler (`app.py`)

**Purpose**: Centralized error handling and logging system.

**Features**:
```python
@app.errorhandler(404)
def not_found_error(error):
    return render_template('404.html'), 404

@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    return render_template('500.html'), 500

# Database error handling
@app.errorhandler(IntegrityError)
def handle_db_error(error):
    db.session.rollback()
    return jsonify({'error': 'Database constraint violation'}), 400
```

### Logging Configuration

**Purpose**: Comprehensive logging for debugging and monitoring.

```python
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Custom log formatting
formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
```

## Performance Components

### Database Optimization

**Purpose**: Query optimization and performance monitoring.

**Features**:
- Strategic indexing on frequently queried fields
- Query optimization for complex filters
- Connection pooling configuration
- Lazy loading for related data

### Caching Strategy

**Purpose**: Response time optimization for frequently accessed data.

**Implementation Areas**:
- Static asset caching
- Database query result caching
- API response caching
- Session data optimization

This comprehensive component catalog provides detailed insight into every aspect of the YouTube CMS Metadata Management Tool, enabling efficient development, maintenance, and enhancement of the system.