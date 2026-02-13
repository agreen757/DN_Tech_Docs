# API Reference

## Videos API (`/api/videos`)

### Get Videos List

```http
GET /api/videos?page=1&per_page=20&search=query
```

**Authentication:** Required (login_required)

**Query Parameters:**

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| page | int | Page number (1-indexed) | 1 |
| per_page | int | Results per page (1-100) | 20 |
| search | string | Title substring search | "music video" |
| channel_search | string | Channel name search | "my-channel" |
| video_id | string | YouTube video ID search | "dQw4w9WgXcQ" |
| asset_id | string | Asset ID search | "AS123456" |
| custom_id | string | Custom ID search | "CUSTOM-001" |
| has_asset_id | string | Filter by asset ownership | "yes" or "no" |
| category | string | Video category | "Music" |
| duration | string | Video length range | "short" / "medium" / "long" |
| policy | string | Effective policy | "monetize" / "block" / "track" |
| sort | string | Sort field and direction | "title:asc" |

**Response (200 OK):**

```json
{
  "status": "success",
  "videos": [
    {
      "id": 1,
      "video_id": "dQw4w9WgXcQ",
      "title": "Sample Video",
      "channel_display_name": "My Channel",
      "asset_id": "AS123456",
      "custom_id": "CUSTOM-001",
      "artist": ["Artist Name"],
      "genre": ["Music"],
      "label": "Label Name",
      "upc": "123456789012",
      "isrc": "USRC12345678",
      "privacy_status": "public",
      "claimed_status": "claimed",
      "claimed_by_another_owner": "No",
      "other_owners_claiming": "Owner A, Owner B",
      "embedding_allowed": "Yes",
      "ratings_allowed": "Yes",
      "comments_allowed": "Yes",
      "effective_policy": "monetize",
      "category": "Music",
      "video_length": 180,
      "views": 1500000,
      "is_short": false,
      "is_live_stream": false,
      "administered": false,
      "administered_at": null,
      "notes": "User notes about this video",
      "ad_settings": {
        "third_party_ads_enabled": "Yes",
        "display_ads_enabled": "Yes",
        "sponsored_cards_enabled": "Yes",
        "overlay_ads_enabled": "Yes",
        "nonskippable_video_ads_enabled": "Yes",
        "long_nonskippable_video_ads_enabled": "Yes",
        "skippable_video_ads_enabled": "Yes",
        "prerolls_enabled": "Yes",
        "midrolls_enabled": "Yes",
        "postrolls_enabled": "Yes"
      },
      "last_synced": "2026-02-13T15:30:00Z",
      "last_changes": {
        "views": [1400000, 1500000],
        "privacy_status": ["unlisted", "public"]
      }
    }
  ],
  "total": 150,
  "pages": 8,
  "current_page": 1
}
```

**Error Response (400 Bad Request):**

```json
{
  "status": "error",
  "message": "Invalid filter parameter",
  "details": "duration must be one of: short, medium, long"
}
```

---

### Update Video Metadata

```http
POST /api/videos/{video_id}/update
Content-Type: application/json

{
  "title": "Updated Title",
  "notes": "Updated notes",
  "custom_id": "NEW-CUSTOM-001",
  "asset_id": "AS789012",
  "artist": ["New Artist"],
  "genre": ["Pop"],
  "label": "New Label",
  "category": "Pop"
}
```

**Response (200 OK):**

```json
{
  "status": "success",
  "message": "Video updated successfully",
  "video": {
    "video_id": "dQw4w9WgXcQ",
    "title": "Updated Title",
    "updated_at": "2026-02-13T16:45:00Z"
  }
}
```

**Error Response (404 Not Found):**

```json
{
  "status": "error",
  "message": "Video not found",
  "video_id": "dQw4w9WgXcQ"
}
```

---

### Sync Video from YouTube API

```http
POST /api/videos/{video_id}/sync
```

**Authentication:** Required

**Response (200 OK):**

```json
{
  "status": "success",
  "message": "Sync task created",
  "task_id": 42,
  "video_id": "dQw4w9WgXcQ",
  "queue_position": 5
}
```

**Response (202 Accepted):**

```json
{
  "status": "accepted",
  "message": "Sync in progress",
  "task": {
    "id": 42,
    "video_id": "dQw4w9WgXcQ",
    "status": "processing",
    "started_at": "2026-02-13T16:50:00Z"
  }
}
```

---

### Delete Video

```http
DELETE /api/videos/{video_id}
```

**Response (200 OK):**

```json
{
  "status": "success",
  "message": "Video deleted",
  "video_id": "dQw4w9WgXcQ"
}
```

---

## Reports API (`/api/reports`)

### List S3 Report Files

```http
GET /api/reports/s3-files?page=1&pageSize=25&search=report
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| page | int | Page number (1-indexed) |
| pageSize | int | Results per page (1-500) |
| search | string | Filename search (case-insensitive) |

**Response (200 OK):**

```json
{
  "status": "success",
  "files": [
    {
      "key": "reports/video_report_Channel1_v1-0.csv",
      "size": 2048576,
      "last_modified": "2026-02-13T10:00:00Z"
    },
    {
      "key": "reports/video_report_Channel2_v1-0.csv.gz",
      "size": 512000,
      "last_modified": "2026-02-12T15:30:00Z"
    }
  ],
  "count": 2,
  "total": 25,
  "page": 1,
  "pageSize": 25
}
```

**Error Response (500 Internal Server Error):**

```json
{
  "status": "error",
  "error": "Failed to connect to S3: InvalidAccessKeyId"
}
```

---

### Queue Reports for Processing

```http
POST /api/process-report
Content-Type: application/json

{
  "files": [
    "reports/video_report_Channel1_v1-0.csv",
    "reports/video_report_Channel2_v1-0.csv.gz"
  ]
}
```

**Response (200 OK):**

```json
{
  "status": "success",
  "message": "Reports queued for processing",
  "report_ids": [101, 102],
  "queued_files": 2,
  "processor_status": "processing"
}
```

**Error Response (400 Bad Request):**

```json
{
  "status": "error",
  "error": "No files selected"
}
```

---

### Get Report Processing Status

```http
GET /api/process-status/{report_id}
```

**Response (200 OK - Pending):**

```json
{
  "status": "success",
  "report": {
    "id": 101,
    "filename": "reports/video_report_Channel1_v1-0.csv",
    "status": "pending",
    "created_at": "2026-02-13T16:50:00Z",
    "processed_at": null,
    "error_message": null
  }
}
```

**Response (200 OK - Processing):**

```json
{
  "status": "success",
  "report": {
    "id": 101,
    "filename": "reports/video_report_Channel1_v1-0.csv",
    "status": "processing",
    "created_at": "2026-02-13T16:50:00Z",
    "processed_at": "2026-02-13T16:50:30Z",
    "progress": {
      "processed_rows": 250,
      "total_rows": 1000,
      "percentage": 25,
      "videos_created": 200,
      "videos_updated": 50,
      "errors": 0
    },
    "error_message": null
  }
}
```

**Response (200 OK - Completed):**

```json
{
  "status": "success",
  "report": {
    "id": 101,
    "filename": "reports/video_report_Channel1_v1-0.csv",
    "status": "completed",
    "created_at": "2026-02-13T16:50:00Z",
    "processed_at": "2026-02-13T17:15:00Z",
    "summary": {
      "total_rows": 1000,
      "videos_created": 800,
      "videos_updated": 150,
      "videos_skipped": 50,
      "errors": 0,
      "processing_time_seconds": 1500,
      "youtube_api_calls": 950
    },
    "error_message": null
  }
}
```

**Response (200 OK - Error):**

```json
{
  "status": "success",
  "report": {
    "id": 101,
    "filename": "reports/video_report_Channel1_v1-0.csv",
    "status": "error",
    "created_at": "2026-02-13T16:50:00Z",
    "processed_at": "2026-02-13T16:51:00Z",
    "error_message": "Invalid CSV structure: missing 'video_id' column",
    "progress": {
      "processed_rows": 0,
      "total_rows": 1000,
      "percentage": 0
    }
  }
}
```

---

### Export Videos as CSV

```http
GET /api/export?channel_search=myChannel&sort=title:asc
```

**Response (200 OK):**

```csv
Content-Type: text/csv
Content-Disposition: attachment; filename="video_export_2026-02-13.csv"

video_id,title,channel,asset_id,custom_id,artist,genre,label,upc,isrc,privacy_status,claimed_status,views,administered,notes
dQw4w9WgXcQ,Sample Video,My Channel,AS123456,CUSTOM-001,Artist Name,Music,Label Name,123456789012,USRC12345678,public,claimed,1500000,false,Notes here
...
```

**Error Response (400 Bad Request):**

```json
{
  "status": "error",
  "message": "No videos match the specified filters"
}
```

---

## Admin API (`/api/admin`)

### List Administered Assets

```http
GET /api/admin/administered?page=1&per_page=20&search=query
```

**Response (200 OK):**

```json
{
  "status": "success",
  "assets": [
    {
      "video_id": "dQw4w9WgXcQ",
      "title": "Sample Video",
      "notes": "Administrative notes",
      "administered": true,
      "administered_at": "2026-02-10T14:30:00Z"
    }
  ],
  "total": 15,
  "pages": 1,
  "current_page": 1
}
```

---

### Update Channel Information

```http
POST /api/admin/channels/{channel_name}/update
Content-Type: application/json

{
  "new_name": "Updated Channel Name",
  "description": "New description",
  "image_url": "[IMAGE_URL]"
}
```

**Response (200 OK):**

```json
{
  "status": "success",
  "message": "Channel updated successfully",
  "channel": {
    "channel_id": "UCxxxxxxxxxxxxxx",
    "name": "Updated Channel Name",
    "updated_at": "2026-02-13T17:00:00Z"
  }
}
```

---

### Hide/Show Channel

```http
POST /api/admin/channels/{channel_name}/hide
Content-Type: application/json

{
  "hidden": true
}
```

**Response (200 OK):**

```json
{
  "status": "success",
  "message": "Channel hidden successfully",
  "channel": {
    "name": "My Channel",
    "hidden": true
  }
}
```

---

### Bulk YouTube API Sync

```http
POST /api/admin/sync/all
Content-Type: application/json

{
  "channels": ["channel1", "channel2"],
  "priority": "high",
  "force_refresh": true
}
```

**Response (202 Accepted):**

```json
{
  "status": "accepted",
  "message": "Sync jobs created",
  "channels": ["channel1", "channel2"],
  "jobs_created": 2500,
  "estimated_completion": "2026-02-13T19:00:00Z"
}
```

---

## System API (`/api/system`)

### Health Check

```http
GET /health
```

**Response (200 OK):**

```json
{
  "status": "healthy",
  "timestamp": "2026-02-13T17:05:00Z",
  "database": "connected",
  "version": "1.0.0",
  "response_time_seconds": 0.045
}
```

**Response (503 Service Unavailable):**

```json
{
  "status": "unhealthy",
  "timestamp": "2026-02-13T17:05:00Z",
  "database": "disconnected",
  "version": "1.0.0",
  "response_time_seconds": 30.001
}
```

---

### Get YouTube API Token

```http
GET /api/get-token
```

**Response (200 OK):**

```json
{
  "status": "success",
  "token": "[TOKEN_STRING]"
}
```

**Error Response (500 Internal Server Error):**

```json
{
  "status": "error",
  "error": "TokenFetcher error: Invalid refresh token"
}
```

---

### Clear Database

```http
POST /api/clear-database
```

**⚠️ WARNING: Destructive Operation**

**Response (200 OK):**

```json
{
  "status": "success",
  "message": "Database cleared successfully",
  "details": {
    "videos_removed": 2500,
    "reports_removed": 15
  }
}
```

---

## WebSocket Events (Socket.IO)

### Real-time Processing Updates

#### Client → Server

**Request Processor Status:**

```javascript
socket.emit('request_processor_status', {}, (response) => {
  console.log('Processor status:', response);
});
```

**Cancel Report Processing:**

```javascript
socket.emit('cancel_report', {report_id: 101}, (response) => {
  console.log('Cancel result:', response);
});
```

#### Server → Client

**Report Status Update:**

```javascript
socket.on('report_status_update', (data) => {
  // data: {
  //   report_id: 101,
  //   filename: "video_report.csv",
  //   status: "processing",
  //   progress: {
  //     processed_rows: 250,
  //     total_rows: 1000,
  //     percentage: 25
  //   }
  // }
});
```

**Queue Task Completion:**

```javascript
socket.on('queue_task_complete', (data) => {
  // data: {
  //   task_id: 42,
  //   video_id: "dQw4w9WgXcQ",
  //   status: "completed",
  //   result: {...}
  // }
});
```

**Processor Status Broadcast:**

```javascript
socket.on('processor_status', (data) => {
  // data: {
  //   running: true,
  //   tasks_processed: 150,
  //   last_activity: "2026-02-13T17:10:00Z",
  //   queue_length: {
  //     pending: 25,
  //     processing: 3,
  //     completed: 500,
  //     failed: 2,
  //     total: 530
  //   }
  // }
});
```

**Metadata Sync Complete:**

```javascript
socket.on('sync_complete', (data) => {
  // data: {
  //   video_id: "dQw4w9WgXcQ",
  //   changes: {
  //     views: [1400000, 1500000],
  //     privacy_status: ["unlisted", "public"],
  //     claimed_status: ["unclaimed", "claimed"]
  //   },
  //   sync_time: "2026-02-13T17:15:00Z"
  // }
});
```

**Error Notification:**

```javascript
socket.on('sync_error', (data) => {
  // data: {
  //   video_id: "dQw4w9WgXcQ",
  //   error: "Rate limit exceeded",
  //   retry_at: "2026-02-13T17:30:00Z"
  // }
});
```

---

## CSV Report Format Specification

### Expected Input CSV Schema

```csv
video_id,title,channel_id,channel_name,published_at,duration,views,likes,comments,privacy_status,embedding_allowed,ratings_allowed,comments_allowed,claimed_status,effective_policy
```

### Column Details

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| video_id | String(20) | Yes | YouTube video ID (11 chars for videos) |
| title | String | Yes | Video title |
| channel_id | String | No | YouTube channel ID |
| channel_name | String | Yes | Human-readable channel name |
| published_at | ISO8601 | Yes | Publication timestamp |
| duration | Integer | No | Duration in seconds |
| views | Integer | No | View count |
| likes | Integer | No | Like count |
| comments | Integer | No | Comment count |
| privacy_status | String | No | public/private/unlisted |
| embedding_allowed | String(3) | No | Yes/No |
| ratings_allowed | String(3) | No | Yes/No |
| comments_allowed | String(3) | No | Yes/No |
| claimed_status | String | No | claimed/unclaimed/dispute/appeal |
| effective_policy | String | No | monetize/block/track |

### Processing Rules

1. **Deduplication**: Latest record per video_id wins
2. **Validation**: Missing video_id causes row rejection
3. **YouTube Shorts**: Filtered if length < 60 seconds and is_short flag set
4. **Asset Enrichment**: After import, YouTube API called for UPC/ISRC/genres
5. **Error Handling**: 
   - Malformed rows skipped with logging
   - Invalid video_ids rejected
   - Blank rows ignored
   - Invalid dates set to null

---

## Error Codes & Messages

### HTTP Status Codes

| Code | Meaning | Use Case |
|------|---------|----------|
| 200 | OK | Successful request |
| 201 | Created | Resource created |
| 202 | Accepted | Async task queued |
| 204 | No Content | Successful delete |
| 400 | Bad Request | Invalid parameters |
| 401 | Unauthorized | Not authenticated |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 500 | Internal Server Error | Server error |
| 503 | Service Unavailable | Database down |

### Custom Error Codes (in response body)

```json
{
  "status": "error",
  "error_code": "VALIDATION_ERROR",
  "message": "Invalid video_id format",
  "details": {
    "field": "video_id",
    "rule": "must be 11 characters",
    "value": "abc123"
  }
}
```

---

## Performance Metrics

### Expected Response Times

| Endpoint | Complexity | Expected Time |
|----------|-----------|---|
| GET /api/videos (20 items) | Low | 50-100ms |
| GET /api/videos (with search) | Medium | 100-300ms |
| POST /api/process-report (single) | High | 200-500ms |
| POST /api/videos/{id}/sync | Very High | 500-2000ms |
| GET /health | Minimal | 10-50ms |

### Pagination Defaults

- Default page size: 20 items
- Max page size: 100 items
- Offset: (page - 1) * per_page

---

## Rate Limiting & Throttling

### YouTube API Rate Limits

```python
class RateLimiter:
    max_requests_per_day = 9500
    min_delay = 0.1  # seconds between requests
    window = 86400   # 24 hours
    
    def wait_if_needed():
        # Check daily limit
        if requests_today >= 9500:
            sleep_until_oldest_request_expires()
        
        # Enforce min delay
        if time_since_last_request < 0.1:
            sleep(0.1 - time_since_last_request)
```

### Implementation in CSV Processor

```python
for video_id in video_ids:
    rate_limiter.wait_if_needed()  # Enforces delays
    response = youtube_api.get_video(video_id)  # Make API call
    process_response(response)
```

---

## Summary

The Catalog Tool API provides a comprehensive REST interface for managing YouTube video catalogs with:

- **Rich filtering & search** across multiple video attributes
- **Asynchronous report processing** with real-time status updates
- **Background synchronization** with YouTube's Partner API
- **Audit trails** via MetadataSync records
- **Multi-user support** with role-based access control
- **Real-time WebSocket** communication for interactive updates

All endpoints follow consistent response formats, implement comprehensive error handling, and support pagination for scalability.
