# Data Flow Patterns

## Report Processing Pipeline

### Overview

The report processing pipeline handles CSV files from S3, parses video metadata, enriches data via YouTube API, and updates the database with comprehensive audit trails.

### Complete Flow Diagram

```
┌──────────────────────────────────────────────────────┐
│ 1. USER INITIATES PROCESSING                         │
│    POST /api/process-report {files: [...]}           │
└────────────────┬─────────────────────────────────────┘
                 │
┌────────────────▼─────────────────────────────────────┐
│ 2. REPORT RECORDS CREATED                            │
│    - Status: 'pending'                               │
│    - Stored in Report table                          │
│    - Returns report IDs to client                    │
└────────────────┬─────────────────────────────────────┘
                 │
┌────────────────▼─────────────────────────────────────┐
│ 3. BACKGROUND PROCESSOR DETECTS JOBS                 │
│    - Background thread monitors Report table         │
│    - Queries for status='pending'                    │
│    - Spawns worker threads (MAX_CONCURRENT: env var) │
└────────────────┬─────────────────────────────────────┘
                 │
┌────────────────▼─────────────────────────────────────┐
│ 4. DOWNLOAD FROM S3                                  │
│    - boto3 S3 client fetches file from S3 bucket     │
│    - Decompresses if gzipped (.csv.gz)               │
│    - UTF-8 validation                                │
└────────────────┬─────────────────────────────────────┘
                 │
┌────────────────▼─────────────────────────────────────┐
│ 5. PARSE CSV & TRANSFORM DATA                        │
│    - Read CSV with pandas/csv module                 │
│    - Extract video IDs                               │
│    - Filter YouTube Shorts (optional)                │
│    - Build Video objects from CSV rows               │
│    - Batch processing (100 rows/batch)               │
└────────────────┬─────────────────────────────────────┘
                 │
┌────────────────▼─────────────────────────────────────┐
│ 6. UPDATE VIDEO CATALOG                              │
│    - INSERT or UPDATE Video records                  │
│    - Handle integrity constraints                    │
│    - Create MetadataSync audit records               │
│    - Manage duplicate entries                        │
└────────────────┬─────────────────────────────────────┘
                 │
┌────────────────▼─────────────────────────────────────┐
│ 7. ENRICH METADATA                                   │
│    - Call YouTube API for asset metadata             │
│    - Rate limit compliance (9500 req/day)            │
│    - Update UPC, ISRC, Genre fields                  │
│    - Create ProcessingQueue tasks                    │
└────────────────┬─────────────────────────────────────┘
                 │
┌────────────────▼─────────────────────────────────────┐
│ 8. COMPLETION & NOTIFICATION                         │
│    - Set Report status: 'completed'                  │
│    - Emit Socket.IO events to connected clients      │
│    - Log audit trail                                 │
└──────────────────────────────────────────────────────┘
```

---

## YouTube API Sync Flow

### Metadata Synchronization Pipeline

```
┌────────────────────────────────────────────────────┐
│ ProcessingQueue Task Created (metadata_sync type)   │
│ status: 'pending'                                  │
└────────────────┬───────────────────────────────────┘
                 │
┌────────────────▼─────────────────────────────────────┐
│ Queue Processor Thread Picks Up Task                 │
│ Updates status: 'processing'                        │
└────────────────┬─────────────────────────────────────┘
                 │
┌────────────────▼─────────────────────────────────────┐
│ Fetch Token via TokenFetcher                        │
│ (OAuth token management for YouTube API)            │
└────────────────┬─────────────────────────────────────┘
                 │
┌────────────────▼─────────────────────────────────────┐
│ Call YouTube Partner API v3                         │
│ Request video details, monetization, ownership      │
│ Apply rate limiting (min_delay: 0.1s)              │
└────────────────┬─────────────────────────────────────┘
                 │
┌────────────────▼─────────────────────────────────────┐
│ Parse Response & Build Changes Delta                │
│ Compare with current database state                 │
│ Track what fields changed                           │
└────────────────┬─────────────────────────────────────┘
                 │
┌────────────────▼─────────────────────────────────────┐
│ Create MetadataSync Record                          │
│ Store JSON changes for audit trail                  │
│ Update Video record with new values                 │
└────────────────┬─────────────────────────────────────┘
                 │
┌────────────────▼─────────────────────────────────────┐
│ Update Queue Status & Notify                        │
│ status: 'completed', result: JSON                   │
│ Emit Socket.IO event to browser                     │
└────────────────────────────────────────────────────┘
```

---

## User Authentication Flow

### Session-Based Authentication (Flask-Security)

```
┌─────────────────────────────────────────────┐
│ 1. User Submits Login Form                 │
│    POST /login {email, password}            │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 2. Password Validation                      │
│    - Flask-Security hashes input with Argon2│
│    - Compares with stored hash              │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 3. Session Creation (if valid)              │
│    - Creates session cookie (secure, httponly)│
│    - Returns 302 redirect to /             │
│    - Tracks login metadata (IP, timestamp)  │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 4. Subsequent Requests                      │
│    - Browser sends session cookie           │
│    - Flask validates session                │
│    - Sets current_user in request context   │
└─────────────────────────────────────────────┘
```

### Firebase OAuth2 Authentication

```
┌─────────────────────────────────────────────┐
│ 1. User Clicks "Continue with Firebase"    │
│    Redirects to Firebase login UI          │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 2. Firebase Authentication                  │
│    User authenticates with Firebase         │
│    Returns auth token to client             │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 3. Token Verification                       │
│    POST /api/auth/firebase {id_token}       │
│    Server verifies with Firebase SDK        │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 4. User Record Sync                         │
│    - Create/update User with firebase_uid   │
│    - Create session cookie                  │
│    - Subsequent requests use session-based  │
└─────────────────────────────────────────────┘
```

---

## Real-time Update Flow

### WebSocket Event Broadcasting

```
┌─────────────────────────────────────────────┐
│ Background Process (Report/Queue Processor) │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ State Change Detected                       │
│ (e.g., report status: processing → completed)│
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ Emit Socket.IO Event                        │
│ socketio.emit('report_status_update', {...})│
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ WebSocket Broadcast                         │
│ Sent to all connected clients               │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ Client JavaScript Handler                   │
│ socket.on('report_status_update', (data) => {│
│   updateProgressBar(data.progress);         │
│   refreshTable();                           │
│ });                                         │
└─────────────────────────────────────────────┘
```

---

## S3 Report Discovery Flow

### S3 File Listing and Pagination

```
┌─────────────────────────────────────────────┐
│ 1. User Opens Report Upload Interface      │
│    GET /api/reports/s3-files?page=1         │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 2. S3 List Objects Request                  │
│    boto3.client('s3').list_objects_v2(...)  │
│    Prefix: 'reports/'                       │
│    MaxKeys: pageSize (default 25)           │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 3. Filter & Transform Results               │
│    - Filter by search term (filename)       │
│    - Extract: key, size, last_modified      │
│    - Sort by last_modified DESC             │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 4. Paginate Results                         │
│    - Calculate total pages                  │
│    - Return current page slice              │
│    - Include pagination metadata            │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 5. Return to Client                         │
│    {files: [...], total: N, page: 1}        │
└─────────────────────────────────────────────┘
```

---

## Video Search & Filter Flow

### Advanced Search Query Construction

```
┌─────────────────────────────────────────────┐
│ 1. User Enters Search Criteria              │
│    - Title: "music"                         │
│    - Channel: "my-channel"                  │
│    - Has Asset ID: Yes                      │
│    - Duration: medium                       │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 2. Build SQLAlchemy Query                   │
│    query = db.session.query(Video)          │
│    if search:                               │
│      query = query.filter(Video.title.ilike('%music%'))│
│    if channel_search:                       │
│      query = query.filter(Video.channel.ilike('%my-channel%'))│
│    if has_asset_id == 'yes':                │
│      query = query.filter(Video.asset_id.isnot(None))│
│    if duration == 'medium':                 │
│      query = query.filter(Video.video_length.between(240, 1200))│
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 3. Join with Latest Sync Metadata           │
│    latest_syncs = (subquery for latest sync)│
│    query = query.outerjoin(latest_syncs)    │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 4. Apply Sorting & Pagination               │
│    query = query.order_by(sort_field)       │
│    results = query.paginate(page, per_page) │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 5. Serialize & Return                       │
│    return {videos: [...], total: N, pages: M}│
└─────────────────────────────────────────────┘
```

---

## CSV Processing Batch Flow

### Batch Insert/Update Strategy

```
┌─────────────────────────────────────────────┐
│ 1. Parse CSV File                           │
│    csv.DictReader(file_content)             │
│    Validate structure (required columns)    │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 2. Group into Batches                       │
│    BATCH_SIZE = 100                         │
│    batches = [rows[i:i+100] for i in ...]   │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 3. Process Each Batch                       │
│    for batch in batches:                    │
│      with db.session.begin():               │
│        for row in batch:                    │
│          video = Video(**row)               │
│          db.session.merge(video)  # upsert  │
│      db.session.commit()                    │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 4. Emit Progress Events                     │
│    After each batch:                        │
│    socketio.emit('report_status_update', {  │
│      progress: {                            │
│        processed_rows: i * BATCH_SIZE,      │
│        total_rows: len(all_rows),           │
│        percentage: (i / total_batches) * 100│
│      }                                      │
│    })                                       │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 5. Error Handling                           │
│    try: ... except IntegrityError:          │
│      Log error, continue to next row        │
│    Rollback on critical failures            │
└─────────────────────────────────────────────┘
```

---

## Queue Processor Lifecycle

### Background Thread Management

```
┌─────────────────────────────────────────────┐
│ Application Startup                         │
│ app = create_app()                          │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ Initialize Queue Processor                  │
│ processor = QueueProcessor(app, socketio)   │
│ processor.start()                           │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ Background Thread Loop                      │
│ while not stopped:                          │
│   tasks = get_pending_tasks()               │
│   for task in tasks:                        │
│     process_task(task)                      │
│   sleep(5)  # Poll interval                 │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ Process Task                                │
│ 1. Update status: processing                │
│ 2. Execute task logic (YouTube API call)    │
│ 3. Update status: completed/failed          │
│ 4. Emit WebSocket event                     │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ Application Shutdown                        │
│ processor.stop()                            │
│ Wait for current tasks to finish            │
│ Clean up resources                          │
└─────────────────────────────────────────────┘
```

---

## Asset Metadata Enrichment Flow

### YouTube API Asset Data Sync

```
┌─────────────────────────────────────────────┐
│ 1. Video Record Created/Updated             │
│    (from CSV import or manual entry)        │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 2. Check if Metadata Enrichment Needed      │
│    if video.asset_id and not video.upc:     │
│      create_enrichment_task(video_id)       │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 3. Queue Processor Picks Up Task            │
│    task_type: 'asset_enrichment'            │
│    payload: {video_id: 'xxx', asset_id: 'yyy'}│
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 4. YouTube API Asset Request                │
│    GET /youtube/partner/v1/assets/{asset_id}│
│    Headers: Authorization: Bearer {token}   │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 5. Extract Metadata                         │
│    upc = response['metadata']['upc']        │
│    isrc = response['metadata']['isrc']      │
│    genres = response['metadata']['genres']  │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 6. Update Video Record                      │
│    video.upc = upc                          │
│    video.isrc = isrc                        │
│    video.genre = genres                     │
│    db.session.commit()                      │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 7. Create MetadataSync Audit Record         │
│    changes = {                              │
│      'upc': [null, upc],                    │
│      'isrc': [null, isrc],                  │
│      'genre': [[], genres]                  │
│    }                                        │
│    MetadataSync(..., changes=changes).save()│
└─────────────────────────────────────────────┘
```

---

## Export Flow

### CSV Export Generation

```
┌─────────────────────────────────────────────┐
│ 1. User Requests Export                     │
│    GET /api/export?channel_search=myChannel │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 2. Build Query with Filters                 │
│    query = db.session.query(Video)          │
│    Apply user filters (same as search)      │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 3. Fetch All Results (no pagination)        │
│    videos = query.all()                     │
│    (Limited to reasonable size)             │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 4. Generate CSV Content                     │
│    csv_buffer = StringIO()                  │
│    writer = csv.DictWriter(csv_buffer, ...)  │
│    writer.writeheader()                     │
│    for video in videos:                     │
│      writer.writerow(video.to_dict())       │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 5. Return as Download                       │
│    return Response(                         │
│      csv_buffer.getvalue(),                 │
│      mimetype='text/csv',                   │
│      headers={                              │
│        'Content-Disposition':               │
│          'attachment; filename=export.csv'  │
│      }                                      │
│    )                                        │
└─────────────────────────────────────────────┘
```

---

## Concurrency & Threading Model

### Thread Pool Executor Pattern

```
┌─────────────────────────────────────────────┐
│ Main Application Thread                     │
│ - Flask app server                          │
│ - Handles HTTP requests                     │
│ - Manages WebSocket connections             │
└────────────────┬────────────────────────────┘
                 │
                 ├──────────────────────────┐
                 │                          │
┌────────────────▼────────────┐  ┌──────────▼──────────────┐
│ Queue Processor Thread      │  │ Report Processor Pool   │
│ - Monitors ProcessingQueue  │  │ - ThreadPoolExecutor    │
│ - Executes metadata sync    │  │ - MAX_CONCURRENT workers│
│ - Emits WebSocket events    │  │ - Process CSV reports   │
└─────────────────────────────┘  └─────────────────────────┘
        │                                 │
        │                                 ├──> Worker Thread 1
        │                                 ├──> Worker Thread 2
        │                                 └──> Worker Thread N
        │
        └──> Shared Database Connection Pool (10 connections)
```

**Key Characteristics:**
- Non-blocking report processing
- Graceful shutdown (waits for active tasks)
- Thread-safe database access via connection pool
- Real-time status updates via WebSocket

---

## Summary

The Catalog Tool employs sophisticated data flow patterns optimized for:

- **Asynchronous Processing**: Background threads handle long-running tasks without blocking the UI
- **Real-time Communication**: WebSocket events provide instant feedback on processing status
- **Batch Operations**: Efficient CSV processing with configurable batch sizes
- **Rate Limiting**: YouTube API compliance with 9500 req/day limit
- **Audit Trails**: Every metadata change tracked in MetadataSync table
- **Scalability**: Thread pool executors and database connection pooling support high concurrency

These patterns enable the system to handle large-scale video catalogs (100,000+ videos) while maintaining responsive user interactions and comprehensive audit capabilities.
