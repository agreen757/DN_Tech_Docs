# Database Schema

## Core Models

### 1. **Video Model** (Core Catalog Entity)

```python
class Video(db.Model):
    # YouTube Identifiers
    video_id: String(20) - YouTube video ID (primary identifier)
    asset_id: String(50) - Asset management ID
    custom_id: String(100) - User-defined identifier
    
    # Content Metadata
    title: String(200) - Video title
    artist: Array[String(200)] - Artist names
    genre: Array[String(100)] - Genre categories
    label: String(200) - Record label
    channel_display_name: String(100) - Channel name
    category: String(50) - Video category
    
    # Identifiers for Rights Management
    upc: String(20) - Universal Product Code
    isrc: String(12) - International Standard Recording Code
    
    # Ownership & Claim Status
    claimed_status: String(10) - claim/appeal/dispute
    claimed_by_another_owner: String(10) - Yes/No
    other_owners_claiming: Text - List of claimants
    
    # Monetization Settings
    third_party_ads_enabled: String(10)
    display_ads_enabled: String(10)
    sponsored_cards_enabled: String(10)
    overlay_ads_enabled: String(10)
    nonskippable_video_ads_enabled: String(10)
    long_nonskippable_video_ads_enabled: String(10)
    skippable_video_ads_enabled: String(10)
    prerolls_enabled: String(10)
    midrolls_enabled: String(10)
    postrolls_enabled: String(10)
    
    # Engagement Settings
    embedding_allowed: String(10)
    ratings_allowed: String(10)
    comments_allowed: String(10)
    
    # Metadata
    privacy_status: String(20) - public/private/unlisted
    effective_policy: Text - Active content policy
    video_length: Integer - Duration in seconds
    views: BigInteger - View count from reports
    
    # Operational Flags
    hidden: Boolean - Hide from interface
    administered: Boolean - Administrative flag
    administered_at: DateTime
    is_short: Boolean - YouTube Shorts indicator
    is_live_stream: Boolean - Live stream indicator
    upload_source: String(20) - Upload or live stream origin
    
    # Housekeeping
    time_published: DateTime
    updated_at: DateTime
    notes: String(500) - User notes
```

**Key Characteristics:**
- **Primary Key**: `id` (auto-increment)
- **Unique Constraint**: `video_id` (enforces one record per YouTube video)
- **Indexes**: video_id, channel_display_name, category, asset_id
- **Nullable Fields**: Most metadata fields (gracefully handle incomplete data)
- **Array Fields**: artist, genre (PostgreSQL array type)

---

### 2. **Channel Model**

```python
class Channel(db.Model):
    channel_id: String(100) - YouTube channel ID
    name: String(200) - Channel name
    image_url: String(500) - Channel thumbnail
    
    # Statistics
    subscriber_count: BigInteger
    video_count: BigInteger
    view_count: BigInteger
    
    # Metadata
    description: Text
    country: String(2) - Country code
    is_monetized: Boolean
    hidden: Boolean - Hide from interface
    
    # Housekeeping
    created_at: DateTime
    updated_at: DateTime
```

**Key Characteristics:**
- **Primary Key**: `id` (auto-increment)
- **Unique Constraint**: `channel_id`
- **Relationship**: One-to-many with Video (via channel_display_name)
- **Purpose**: Channel aggregation and metadata storage

---

### 3. **MetadataSync Model** (Audit Trail)

```python
class MetadataSync(db.Model):
    video_id: String(20) - FK to Video
    channel_display_name: String(100)
    video_title: String(200)
    sync_time: DateTime - When sync occurred
    changes: JSON - Delta of changes
```

**Key Characteristics:**
- **Primary Key**: `id` (auto-increment)
- **Foreign Key**: `video_id` → `Video.video_id`
- **Index**: Composite index on (video_id, sync_time DESC) for efficient queries
- **Purpose**: 
  - Audit trail for all metadata changes
  - Track what changed and when
  - Enable compliance and rollback capabilities

**Changes JSON Structure:**
```json
{
  "views": [1400000, 1500000],
  "privacy_status": ["unlisted", "public"],
  "claimed_status": ["unclaimed", "claimed"]
}
```

---

### 4. **ProcessingQueue Model** (Background Tasks)

```python
class ProcessingQueue(db.Model):
    video_id: String(20) - FK to Video
    task_type: String(50) - metadata_sync, ownership_update, etc.
    status: String(20) - pending/processing/completed/failed
    priority: Integer - Higher = higher priority
    
    # Execution Tracking
    created_at: DateTime
    started_at: DateTime
    completed_at: DateTime
    
    # Data & Results
    payload: JSON - Task-specific data
    result: JSON - Operation results
    error_message: Text
    retry_count: Integer
    created_by: Integer (FK to User)
```

**Key Characteristics:**
- **Primary Key**: `id` (auto-increment)
- **Foreign Keys**: 
  - `video_id` → `Video.video_id`
  - `created_by` → `User.id`
- **Indexes**: status, created_at, priority
- **Purpose**: Asynchronous task management for metadata sync

**Task Types:**
- `metadata_sync` - Sync video metadata from YouTube API
- `ownership_update` - Update ownership/claim information
- `asset_enrichment` - Fetch UPC/ISRC/genre data

**Status Flow:**
```
pending → processing → completed
                    └→ failed (retry_count incremented)
```

---

### 5. **User & Role Models** (Authentication)

```python
class User(db.Model):
    email: String(255) - Unique email
    username: String(255) - Unique username
    password: String(255) - Hashed password (Flask-Security)
    firebase_uid: String(128) - Firebase UID (nullable)
    auth_method: String(20) - 'flask-security' or 'firebase'
    is_admin: Boolean
    roles: Relationship[Role] - Many-to-many
    
    # Tracking
    current_login_at: DateTime
    last_login_at: DateTime
    current_login_ip: String(100)
    last_login_ip: String(100)
    login_count: Integer
    created_at: DateTime
```

**Key Characteristics:**
- **Primary Key**: `id` (auto-increment)
- **Unique Constraints**: email, username, firebase_uid
- **Relationship**: Many-to-many with Role via `roles_users` join table
- **Password**: Hashed with Argon2 (Flask-Security default)

```python
class Role(db.Model):
    name: String(80) - 'admin' or 'user'
    description: String(255)
```

**Key Characteristics:**
- **Primary Key**: `id` (auto-increment)
- **Unique Constraint**: name
- **Default Roles**: admin, user

**Join Table (roles_users):**
```python
roles_users = db.Table('roles_users',
    db.Column('user_id', db.Integer(), db.ForeignKey('user.id')),
    db.Column('role_id', db.Integer(), db.ForeignKey('role.id'))
)
```

---

### 6. **Report Model** (Processing State)

```python
class Report(db.Model):
    filename: String(255) - S3 key
    status: String(20) - pending/processing/completed/error
    processed_at: DateTime
    error_message: Text
    created_at: DateTime
```

**Key Characteristics:**
- **Primary Key**: `id` (auto-increment)
- **Index**: status, created_at
- **Purpose**: Track CSV report processing from S3

**Status Values:**
- `pending` - Queued but not started
- `processing` - Currently being processed
- `completed` - Successfully processed
- `error` - Failed with error_message populated

---

## Data Model Relationships

```
User
├─→ Role (many-to-many via roles_users)
└─→ ProcessingQueue (created_by foreign key)

Channel
└─→ Video (one-to-many via channel_display_name)

Video
├─→ MetadataSync (one-to-many via video_id)
└─→ ProcessingQueue (one-to-many via video_id)

ProcessingQueue
├─→ Video (foreign key)
└─→ User (foreign key created_by)

Report
└─(no foreign keys, references S3 files)
```

---

## Database Indexes

### Performance-Critical Indexes

```sql
-- Video Model
CREATE INDEX idx_video_video_id ON video(video_id);
CREATE INDEX idx_video_channel ON video(channel_display_name);
CREATE INDEX idx_video_category ON video(category);
CREATE INDEX idx_video_asset_id ON video(asset_id);
CREATE INDEX idx_video_custom_id ON video(custom_id);

-- MetadataSync Model
CREATE INDEX idx_sync_video_time ON metadata_sync(video_id, sync_time DESC);

-- ProcessingQueue Model
CREATE INDEX idx_queue_status ON processing_queue(status);
CREATE INDEX idx_queue_created ON processing_queue(created_at);
CREATE INDEX idx_queue_priority ON processing_queue(priority DESC);

-- Report Model
CREATE INDEX idx_report_status ON report(status);
CREATE INDEX idx_report_created ON report(created_at);

-- Channel Model
CREATE INDEX idx_channel_id ON channel(channel_id);
```

---

## Database Migrations (Alembic)

### Migration Files Structure

```
migrations/
├── alembic.ini
├── env.py
├── script.py.mako
└── versions/
    ├── 001_initial_schema.py
    ├── 002_add_firebase_auth.py
    ├── 003_add_processing_queue.py
    └── 004_add_metadata_sync.py
```

### Running Migrations

```bash
# Generate new migration
flask db migrate -m "Add new field to Video"

# Apply migrations
flask db upgrade head

# Rollback one version
flask db downgrade -1

# View migration history
flask db history
```

---

## Database Constraints

### Integrity Constraints

1. **Video Model:**
   - `UNIQUE(video_id)` - Prevent duplicate YouTube videos
   - `CHECK(video_length >= 0)` - Positive duration
   - `CHECK(views >= 0)` - Positive view count

2. **User Model:**
   - `UNIQUE(email)` - Prevent duplicate accounts
   - `UNIQUE(username)` - Unique usernames
   - `UNIQUE(firebase_uid)` - Firebase integration integrity

3. **ProcessingQueue:**
   - `CHECK(retry_count >= 0)` - Non-negative retries
   - `CHECK(priority >= 0)` - Positive priority

### Cascading Deletes

```python
# MetadataSync cascades on Video delete
video_id = db.Column(db.String(20), db.ForeignKey('video.video_id', ondelete='CASCADE'))

# ProcessingQueue cascades on Video delete
video_id = db.Column(db.String(20), db.ForeignKey('video.video_id', ondelete='CASCADE'))
```

---

## Query Optimization Patterns

### Efficient Latest Sync Query

```python
# Subquery for latest metadata sync per video
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
).outerjoin(
    latest_syncs, 
    Video.video_id == latest_syncs.c.video_id
).filter(Video.hidden == False)
```

**Benefits:**
- Avoids N+1 query problem
- Returns latest sync metadata efficiently
- Scalable to 100,000+ videos

### Pagination with Metadata

```python
paginated = query.paginate(
    page=page,
    per_page=per_page,
    error_out=False
)

return {
    'videos': [v.to_dict() for v in paginated.items],
    'total': paginated.total,
    'pages': paginated.pages,
    'current_page': paginated.page
}
```

---

## Database Backup & Maintenance

### Backup Strategy

```bash
# Full database backup
pg_dump -U postgres -d catalogtool -F c -b -v -f backup_$(date +%Y%m%d).dump

# Restore from backup
pg_restore -U postgres -d catalogtool -v backup_20260213.dump

# Incremental backup (WAL archiving)
# Configure in postgresql.conf:
archive_mode = on
archive_command = 'cp %p /backup/wal_archive/%f'
```

### Maintenance Tasks

```sql
-- Vacuum and analyze (run weekly)
VACUUM ANALYZE video;
VACUUM ANALYZE metadata_sync;
VACUUM ANALYZE processing_queue;

-- Reindex (run monthly)
REINDEX TABLE video;
REINDEX TABLE metadata_sync;

-- Check database size
SELECT pg_size_pretty(pg_database_size('catalogtool'));

-- Check table sizes
SELECT 
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
```

---

## Data Archival Strategy

### Archive Old MetadataSync Records

```sql
-- Archive syncs older than 6 months
INSERT INTO metadata_sync_archive
SELECT * FROM metadata_sync
WHERE sync_time < NOW() - INTERVAL '6 months';

DELETE FROM metadata_sync
WHERE sync_time < NOW() - INTERVAL '6 months';
```

### Archive Completed Reports

```sql
-- Archive reports older than 3 months
INSERT INTO report_archive
SELECT * FROM report
WHERE status = 'completed' 
  AND processed_at < NOW() - INTERVAL '3 months';

DELETE FROM report
WHERE status = 'completed' 
  AND processed_at < NOW() - INTERVAL '3 months';
```

---

## Summary

The Catalog Tool database schema is designed for:

- **Scalability**: Efficient indexing and query patterns support 100,000+ videos
- **Integrity**: Foreign key constraints and unique indexes prevent data corruption
- **Auditability**: MetadataSync tracks all changes with full history
- **Flexibility**: JSON fields enable extensible metadata without schema changes
- **Performance**: Strategic indexes and optimized queries ensure sub-100ms response times

The PostgreSQL backend with SQLAlchemy ORM provides a robust foundation for the YouTube Content Management System's data layer.
