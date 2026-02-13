# Architecture Overview

## Executive Summary

The **YouTube Content Management System (CMS)** is a comprehensive Flask-based web application for managing YouTube video metadata, monetization settings, and content claims. The "catalog tool" refers to the core data management and API infrastructure that organizes, stores, and retrieves video catalogs from YouTube channels.

**Technology Stack:**
- **Backend**: Flask 3.x, Python 3.11+, SQLAlchemy ORM
- **Database**: PostgreSQL with Alembic migrations
- **Frontend**: Jinja2 templates, Bootstrap 5, ES6 JavaScript modules
- **Real-time**: Socket.IO for WebSocket communication
- **Cloud**: AWS S3 for report storage, boto3 for S3 integration
- **Authentication**: Hybrid Flask-Security/Firebase authentication
- **Background Processing**: Custom queue processor with APScheduler

---

## High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Web Interface Layer                       │
│   (Jinja2 Templates + Bootstrap 5 + ES6 Modules)           │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│              Flask Application (app.py)                      │
│  ┌─────────────────────────────────────────────────────────┐│
│  │            API Blueprints (api/ module)                  ││
│  │  ┌──────────┬──────────┬──────────┬──────────┬────────┐  ││
│  │  │  main    │ videos   │ reports  │  admin   │ system │  ││
│  │  └──────────┴──────────┴──────────┴──────────┴────────┘  ││
│  └─────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────┐│
│  │         Authentication & Security Layer                  ││
│  │  (Flask-Security + Firebase Auth + Password Recovery)   ││
│  └─────────────────────────────────────────────────────────┘│
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│            Database Abstraction Layer (SQLAlchemy)           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │            PostgreSQL Database                        │  │
│  │  ┌──────────┬──────────┬───────┬──────────┬────────┐  │  │
│  │  │ Video    │ Channel  │ User  │ Reports  │ Queues │  │  │
│  │  └──────────┴──────────┴───────┴──────────┴────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────────┘
                     │
   ┌─────────────────┼─────────────────┐
   │                 │                 │
   ▼                 ▼                 ▼
┌────────────┐   ┌────────────┐   ┌────────────┐
│  AWS S3    │   │ YouTube    │   │ Background │
│  Reports   │   │  Partner   │   │ Queue      │
│  Storage   │   │   API      │   │ Processor  │
└────────────┘   └────────────┘   └────────────┘
```

---

## API Architecture

### Blueprint Organization (api/ module)

The Flask application uses a **modular blueprint architecture** for better maintainability:

#### 1. **main_bp** (`api/main.py`)
**Purpose**: Core application pages
- `GET /` → Render index.html (dashboard)
- `GET /admin` → Render admin.html (admin interface)

#### 2. **videos_bp** (`api/videos.py`)
**Purpose**: Video catalog operations
- `GET /api/videos` → Paginated video listing with advanced filtering
- `POST /api/videos/<video_id>/update` → Update video metadata
- `POST /api/videos/<video_id>/sync` → Sync video metadata from YouTube API
- `DELETE /api/videos/<video_id>` → Delete video
- `GET /api/videos/search` → Advanced search with filters

**Filter Capabilities:**
- Video ID search
- Title search
- Channel search
- Asset ID filtering
- Custom ID filtering
- Category filtering
- Duration filtering
- Asset ownership status (has_asset_id)
- Claim status filtering
- Monetization status

#### 3. **reports_bp** (`api/reports.py`)
**Purpose**: CSV report processing and export
- `GET /api/reports/s3-files` → List S3 reports (paginated, searchable)
- `POST /api/process-report` → Queue reports for processing
- `GET /api/process-status/:report_id` → Get processing status
- `GET /api/reports/history` → Processing history
- `GET /api/export` → Export video data as CSV

**Processing Flow:**
1. User selects S3 report files
2. Report records created in database (pending status)
3. Background processor threads pick up tasks
4. CSV parsed and data updated in Video table
5. Status transitions: pending → processing → completed/error

#### 4. **admin_bp** (`api/admin.py`)
**Purpose**: Administrative operations
- `GET /api/admin/administered` → List administered assets
- `POST /api/admin/channels/<name>/update` → Update channel info
- `POST /api/admin/channels/<name>/hide` → Hide/show channel
- `GET /api/admin/channels` → List all channels
- `POST /api/admin/sync/all` → Bulk sync YouTube data
- `POST /api/admin/<asset_type>/update` → Update asset metadata

#### 5. **system_bp** (`api/system.py`)
**Purpose**: System maintenance
- `POST /api/clear-database` → Clear all video/report data
- `GET /api/get-token` → Fetch fresh YouTube API token
- `GET /health` → Comprehensive health check

---

## Key Components

### 1. Utilities Module (`utils/`)

#### **s3.py** - AWS S3 Integration
```python
def list_s3_reports(prefix='reports/')
  → List all CSV files in S3 bucket with pagination

def list_s3_reports_paginated(page, page_size, search_term)
  → Server-side paginated S3 listing with search filtering

def download_s3_report(file_key)
  → Download and validate S3 file content (boto3)
```

**Integration Points:**
- Uses `boto3` client with AWS credentials from environment
- Handles `.csv` and `.csv.gz` formats
- Paging to avoid memory overload on large buckets

#### **csv_processor.py** - Report Processing Engine
```python
class RateLimiter
  → Enforces YouTube API rate limits (9500 req/day)
  → Min delay between requests (0.1s)

def process_csv_file(file_content)
  → Parse CSV, create Video records, call YouTube API
  → Batch processing with transaction management
  → YouTube Shorts filtering (optional)

def process_report_async(file_content)
  → Queue report for background processing

def process_reports_async(report_ids)
  → Thread pool executor for concurrent report processing
  → Configurable via MAX_CONCURRENT_REPORTS env var
```

**Processing Logic:**
1. Read CSV and extract video IDs
2. Query YouTube API for each video (with rate limiting)
3. Transform API response to Video model fields
4. Batch insert/update with constraint handling
5. Create MetadataSync audit records
6. Enrich with asset metadata (UPC, ISRC, genres)

#### **queue_processor.py** - Background Task Engine
```python
class QueueProcessor
  → Thread-based background task processor
  → Monitors ProcessingQueue table for pending tasks
  → Executes metadata_sync and ownership_update tasks
  → Reports status via Socket.IO WebSocket events

Methods:
  start()      → Start background thread
  stop()       → Gracefully stop processor
  status()    → Return processor and queue statistics
  _process_queue_loop()  → Main processing loop
```

**Architecture:**
- Single background thread per app instance
- Polls ProcessingQueue table every 5-10 seconds
- Transactional task execution with error handling
- WebSocket event emission for real-time UI updates
- Graceful shutdown on app termination

#### **metadata.py** - Asset Metadata Enrichment
```python
def get_asset_metadata(video_id, token)
  → Query YouTube API for asset details
  → Extract: UPC, ISRC, genres, labels
  → Enrich Video record with music metadata
```

#### **filter_youtube_shorts.py** - Content Classification
```python
def extract_video_ids_from_csv(content)
  → Parse video IDs from CSV content

def get_known_classifications()
  → Load YouTube Shorts classification database

def filter_csv_content(csv_content, exclude_shorts=True)
  → Filter shorts from CSV based on classification

def get_classification_statistics(content)
  → Count shorts vs regular videos
```

### 2. Real-time Communication

**Socket.IO Integration:**
- Persistent WebSocket connections between client and server
- Event-driven architecture for real-time updates
- Used for:
  - Report processing status updates
  - Queue processor status broadcasting
  - Metadata sync notifications
  - Error notifications

**Event Types:**
```javascript
// Server → Client
'report_status_update' → {report_id, status, progress}
'queue_task_complete' → {task_id, video_id, result}
'processor_status' → {running, tasks_processed, queue_length}
'sync_complete' → {video_id, changes}

// Client → Server
'request_processor_status' → {}
'cancel_report' → {report_id}
```

### 3. Video Filtering & Search

**Advanced Filter System:**
The `/api/videos` endpoint supports multiple filter combinations:

```
Query Parameters:
  search              → Title substring search (ILIKE)
  channel_search      → Channel name search
  category            → Video category filter
  duration            → Video length range
  video_id            → Exact/partial video ID match
  asset_id            → Exact/partial asset ID match
  has_asset_id        → 'yes'/'no' ownership filter
  custom_id           → Custom ID search
  policy              → Effective policy filter
  sort                → Field and direction (asc/desc)
  page                → Page number (1-indexed)
  per_page            → Results per page (max 100)
```

**Implementation:**
```python
# Subquery for latest metadata sync
latest_syncs = db.session.query(
    MetadataSync.video_id, 
    MetadataSync.sync_time.label('last_synced'),
    MetadataSync.changes.label('last_changes')
).distinct(MetadataSync.video_id).order_by(
    MetadataSync.video_id,
    MetadataSync.sync_time.desc()
).subquery()

# Main query with outer join
query = db.session.query(
    Video, 
    latest_syncs.c.last_synced,
    latest_syncs.c.last_changes
).outerjoin(latest_syncs, ...)
```

This allows returning:
- Latest sync metadata alongside video data
- Audit trail of changes
- Efficient pagination with metadata

---

## Frontend Architecture

### Page Structure

#### **index.html** - Dashboard
- Video catalog table with pagination
- Advanced search and filtering UI
- Dynamic column configuration
- Report upload interface
- Real-time queue status display

**Key UI Components:**
- Filterable data table (100+ videos per page)
- Search box with multi-field search
- Column selector for customization
- Pagination controls
- Status badges for claims, monetization

#### **admin.html** - Administrative Interface
- Channel management
- Bulk operations (sync, update, hide)
- Administered assets management
- System controls (clear database)
- Token management

#### **hybrid_login.html** - Authentication
- Dual auth method support (Flask-Security + Firebase)
- Login form with email/username
- Registration interface
- Password recovery flow
- "Continue with Firebase" button

### JavaScript Modules (`static/js/`)

```
modules/
├── api.js              → API client wrapper (fetch abstractions)
├── columns.js          → Dynamic column management
├── events.js           → Event binding and handling
├── pagination.js       → Pagination logic
├── queue.js            → Queue processor status monitoring
├── ui.js               → DOM utilities and helpers
├── ui-components.js    → Reusable UI component creation
└── utils.js            → Common utilities and helpers

main.js                → Application initialization
videos.js             → Video page-specific logic
firebase-auth.js      → Firebase authentication client
```

**Architecture Pattern:**
```javascript
// Module pattern with IIFE and exports
const APIModule = (() => {
    const request = async (method, url, data) => {
        // Fetch wrapper with error handling
    };
    
    return {
        getVideos: (params) => request('GET', '/api/videos', null),
        updateVideo: (id, data) => request('POST', `/api/videos/${id}/update`, data),
        // ... more methods
    };
})();

// Usage
APIModule.getVideos({page: 1, per_page: 20}).then(data => {
    UIModule.renderTable(data);
});
```

---

## Configuration Management

### Environment Variables

**Database:**
```bash
SQLALCHEMY_DATABASE_URI=postgresql://user:pass@host:5432/catalogtool
DATABASE_URL=postgresql://...  # Alembic migrations
```

**AWS S3:**
```bash
AWS_ACCESS_KEY_ID=[CONFIGURED_VIA_ENV]
AWS_SECRET_ACCESS_KEY=[CONFIGURED_VIA_ENV]
CUSTOM_AWS_ACCESS_KEY=[CONFIGURED_VIA_ENV]
CUSTOM_AWS_SECRET_KEY=[CONFIGURED_VIA_ENV]
```

**Application:**
```bash
FLASK_ENV=dev|prod
SECRET_KEY=[CONFIGURED_VIA_ENV]
SECURITY_PASSWORD_SALT=[CONFIGURED_VIA_ENV]
```

**Email (Password Recovery):**
```bash
MAIL_SERVER=smtp.example.com
MAIL_PORT=587
MAIL_USE_TLS=true
MAIL_USERNAME=[CONFIGURED_VIA_ENV]
MAIL_PASSWORD=[CONFIGURED_VIA_ENV]
MAIL_DEFAULT_SENDER=noreply@distro-nation.com
```

**Processing:**
```bash
MAX_CONCURRENT_REPORTS=1-4  # Concurrent report processors
FLASK_ENV=dev|prod
FLASK_SKIP_DB_INIT=1  # Skip DB init for migrations
```

**YouTube API:**
```bash
# TokenFetcher config (in tokenfetcher/config.py)
CLIENT_ID=[CONFIGURED_VIA_ENV]
CLIENT_SECRET=[CONFIGURED_VIA_ENV]
REFRESH_TOKEN=[CONFIGURED_VIA_ENV]
```

### Configuration Files

**config.py** - Flask Configuration
```python
class Config:
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ECHO = False
    MAX_CONTENT_LENGTH = 50 * 1024 * 1024  # 50MB max
    
class DevelopmentConfig(Config):
    DEBUG = True
    TESTING = False
    
class ProductionConfig(Config):
    DEBUG = False
    TESTING = False
```

**alembic.ini** - Database Migrations
- Migration version tracking
- Database URL configuration
- Python path setup for migrations module

---

## Security & Compliance

### Security Layers

1. **Authentication**
   - Password hashing with Argon2
   - Session-based authentication
   - CSRF protection enabled
   - Firebase OAuth2 support

2. **Authorization**
   - @login_required decorator on protected routes
   - Role-based access control (admin, user)
   - Database-backed permissions

3. **Input Validation**
   - Marshmallow schemas for JSON payloads
   - CSV content validation (UTF-8, structure)
   - SQL injection prevention via SQLAlchemy parameterization

4. **Data Protection**
   - No sensitive info in logs (API keys, usernames redacted)
   - Environment-based credential management
   - S3 file encryption at rest

### Audit Trail

**MetadataSync Table:**
- Tracks every video metadata change
- Stores JSON diff of changes
- Records sync timestamp and source
- Enables compliance and debugging

---

## Performance Optimization

### Database Optimizations

1. **Indexing:**
   ```sql
   -- Implicit indexes on foreign keys
   CREATE INDEX idx_video_video_id ON video(video_id)
   CREATE INDEX idx_video_channel ON video(channel_display_name)
   CREATE INDEX idx_video_category ON video(category)
   CREATE INDEX idx_sync_video_time ON metadata_sync(video_id, sync_time DESC)
   ```

2. **Query Optimization:**
   - Distinct subqueries for latest syncs (avoid N+1)
   - Outer joins to include related metadata
   - Pagination to limit result sets
   - Lazy loading relationships

3. **Connection Pooling:**
   - SQLAlchemy connection pool (default: 10 connections)
   - Pool pre-ping for stale connection detection
   - Pool recycling to prevent timeout issues

### Frontend Performance

1. **JavaScript Module Loading:**
   - ES6 modules (native browser support)
   - Async module imports
   - Code splitting by page

2. **Data Transfer:**
   - Paginated API responses (default: 20 items)
   - JSON compression (Flask-Compress capable)
   - Selective column loading

3. **Rendering:**
   - Virtual scrolling for large tables
   - Event delegation for dynamic content
   - Debounced search and filter operations

### Background Processing

1. **Concurrency:**
   - Thread pool executor (configurable workers)
   - Non-blocking report processing
   - Graceful shutdown with pending task completion

2. **Rate Limiting:**
   - YouTube API rate limiter (9500 req/day limit)
   - Min delay between requests (0.1s)
   - 24-hour rolling window tracking

---

## Error Handling & Exceptions

### Custom Exception Hierarchy

```python
# exceptions.py
class AppException(Exception)              # Base exception
    ├── ValidationError                   # Input validation
    ├── DatabaseError                     # Database operations
    ├── VideoNotFoundError                # Video lookup
    ├── ChannelNotFoundError              # Channel lookup
    ├── YouTubeAPIError                   # YouTube API calls
    ├── TokenFetchError                   # Token management
    ├── S3ProcessingError                 # S3 operations
    ├── FileProcessingError               # File processing
    └── ExternalServiceError              # External services
```

### Error Handler Registration

```python
# error_handlers.py
def register_error_handlers(app):
    @app.errorhandler(ValidationError)
    def handle_validation_error(error):
        return jsonify({'status': 'error', 'message': str(error)}), 400
    
    @app.errorhandler(DatabaseError)
    def handle_database_error(error):
        return jsonify({'status': 'error', 'message': str(error)}), 500
    
    # ... more handlers
```

---

## Summary

The **YouTube Content Management System** is a robust, modular Flask application designed for managing large-scale video catalogs. Its architecture emphasizes:

- **Modularity**: Blueprint-based organization for clear separation of concerns
- **Scalability**: Background processing, connection pooling, efficient queries
- **Security**: Hybrid authentication, input validation, audit trails
- **Maintainability**: Custom exception hierarchy, structured logging, comprehensive documentation
- **Extensibility**: Plugin-like blueprint system for adding new features

The "catalog tool" at its core is a sophisticated video metadata management system that integrates YouTube's Partner API with PostgreSQL for persistent storage, AWS S3 for report processing, and WebSocket real-time communication for interactive UI updates.
