# YouTube CMS Metadata Management Tool - API Integrations

## Overview

The YouTube CMS Metadata Management Tool integrates with multiple external services to provide comprehensive content management capabilities. This document details all API integrations, authentication patterns, data flow mechanisms, and error handling strategies.

## Core API Integrations

### 1. YouTube Data API v3 Integration

#### Authentication & Authorization

**SSM Parameter Store Integration**
```python
from aws_sdk import SSMClient, GetParameterCommand
from shared.keyManager import KeyManager

# Secure credential management with SSM Parameter Store
class YouTubeAPIClient:
    def __init__(self):
        self.ssm_client = SSMClient(region='<REGION>')
        self.key_manager = KeyManager(
            api_id=os.environ.get('API_ID'),
            appSyncClient=AppSyncClient(region='<REGION>'),
            ssmClient=self.ssm_client
        )
        self.base_url = 'https://www.googleapis.com/youtube/v3'
        
    async def get_youtube_api_key(self):
        """Retrieve YouTube API key from SSM Parameter Store"""
        try:
            return await self.key_manager.getApiKeyFromSSM('/distro-nation/youtube/api-key')
        except Exception as e:
            logger.error(f"Failed to retrieve YouTube API key from SSM: {e}")
            # Fallback to environment variable
            return os.environ.get('YOUTUBE_API_KEY')
```

**Legacy OAuth 2.0 Implementation (Deprecated)**
```python
# Legacy environment variable approach - being migrated to SSM
YOUTUBE_API_KEY = os.environ.get('YOUTUBE_API_KEY')
YOUTUBE_CLIENT_ID = os.environ.get('YOUTUBE_CLIENT_ID')
YOUTUBE_CLIENT_SECRET = os.environ.get('YOUTUBE_CLIENT_SECRET')
```

**Advanced Token Management with SSM Integration**
```python
from shared.classes import APIToken, GraphQL, Logger

class AdvancedTokenManager:
    def __init__(self):
        self.api_token = APIToken()
        self.graphql = GraphQL()
        self.logger = Logger({
            'service': 'TokenManager',
            'correlationId': f'token-mgr-{Date.now()}',
            'maskFields': ['apiKey', 'token', 'authorization', 'password', 'secret']
        })
    
    async def get_youtube_access_token(self):
        """Retrieve YouTube Content ID API access token with SSM integration"""
        try:
            self.logger.info('GET_YOUTUBE_TOKEN_ATTEMPT')
            
            # Get token from secure API endpoint using SSM-stored API key
            token = await self.api_token.getToken()
            
            self.logger.audit('YOUTUBE_TOKEN_RETRIEVED', {
                'resourceType': 'ACCESS_TOKEN',
                'action': 'RETRIEVE',
                'outcome': 'SUCCESS'
            })
            
            return token
        except Exception as e:
            self.logger.error('GET_YOUTUBE_TOKEN_ERROR', {}, e)
            
            self.logger.audit('YOUTUBE_TOKEN_RETRIEVAL_FAILED', {
                'resourceType': 'ACCESS_TOKEN',
                'action': 'RETRIEVE',
                'outcome': 'FAILURE',
                'errorMessage': str(e)
            })
            raise
    
    async def get_graphql_api_key(self):
        """Get or create AppSync GraphQL API key with automatic rotation"""
        try:
            self.logger.info('GET_GRAPHQL_API_KEY_ATTEMPT')
            
            # Initialize API key with automatic creation/rotation
            api_key = await self.graphql.initializeApiKey()
            
            if api_key:
                self.logger.info('GRAPHQL_API_KEY_SUCCESS')
                return api_key
            else:
                raise Exception("Failed to initialize GraphQL API key")
                
        except Exception as e:
            self.logger.error('GET_GRAPHQL_API_KEY_ERROR', {}, e)
            raise
```

**Legacy Token Management (Deprecated)**
```python
from token_fetcher import TokenFetcher, TokenFetchError

class LegacyTokenManager:
    def get_access_token(self):
        """Legacy token retrieval - being replaced by SSM integration"""
        try:
            token = self.token_fetcher.get_youtube_token()
            if self.is_token_expired(token):
                token = self.refresh_token(token)
            return token
        except TokenFetchError as e:
            logger.error(f"Token fetch failed: {e}")
            raise
```

#### Video Metadata Operations

**Video Information Retrieval**
```python
def get_video_details(video_id):
    """Retrieve comprehensive video metadata from YouTube API"""
    endpoint = f"{self.base_url}/videos"
    params = {
        'id': video_id,
        'part': 'snippet,contentDetails,status,statistics,monetizationDetails',
        'key': self.api_key
    }
    
    response = requests.get(endpoint, params=params)
    if response.status_code == 200:
        return response.json()
    else:
        raise YouTubeAPIError(f"Failed to fetch video details: {response.text}")

# Response structure
{
    "items": [
        {
            "id": "video_id",
            "snippet": {
                "title": "Video Title",
                "description": "Video Description",
                "publishedAt": "2024-01-01T00:00:00Z",
                "channelId": "channel_id",
                "channelTitle": "Channel Name",
                "tags": ["tag1", "tag2"],
                "categoryId": "10"
            },
            "contentDetails": {
                "duration": "PT4M13S",
                "definition": "hd",
                "caption": "false"
            },
            "status": {
                "uploadStatus": "processed",
                "privacyStatus": "public",
                "license": "youtube",
                "embeddable": true,
                "publicStatsViewable": true
            },
            "statistics": {
                "viewCount": "1000",
                "likeCount": "100",
                "commentCount": "50"
            }
        }
    ]
}
```

**Metadata Synchronization**
```python
def sync_video_metadata(video_id, metadata_updates):
    """Synchronize local metadata changes with YouTube"""
    # Prepare metadata for YouTube API format
    youtube_metadata = self.transform_metadata(metadata_updates)
    
    endpoint = f"{self.base_url}/videos"
    params = {'part': 'snippet,status'}
    
    payload = {
        'id': video_id,
        'snippet': youtube_metadata['snippet'],
        'status': youtube_metadata['status']
    }
    
    headers = {
        'Authorization': f'Bearer {self.get_access_token()}',
        'Content-Type': 'application/json'
    }
    
    response = requests.put(endpoint, json=payload, headers=headers, params=params)
    
    if response.status_code == 200:
        # Log successful sync
        self.log_sync_success(video_id, metadata_updates)
        return response.json()
    else:
        # Handle sync failure
        self.log_sync_failure(video_id, response.text)
        raise SyncError(f"Metadata sync failed: {response.text}")

def transform_metadata(internal_metadata):
    """Transform internal metadata format to YouTube API format"""
    return {
        'snippet': {
            'title': internal_metadata.get('title'),
            'description': internal_metadata.get('description'),
            'tags': internal_metadata.get('tags', []),
            'categoryId': internal_metadata.get('category_id')
        },
        'status': {
            'privacyStatus': internal_metadata.get('privacy_status'),
            'embeddable': internal_metadata.get('embedding_allowed'),
            'publicStatsViewable': internal_metadata.get('stats_viewable')
        }
    }
```

#### Content Management System Integration

**Asset Association**
```python
def associate_video_with_asset(video_id, asset_id):
    """Associate YouTube video with CMS asset"""
    endpoint = f"{self.base_url}/contentOwners/assets/{asset_id}/claims"
    
    payload = {
        'videoId': video_id,
        'assetId': asset_id,
        'contentType': 'audiovisual',
        'policy': {
            'id': 'monetize_policy'
        }
    }
    
    headers = {
        'Authorization': f'Bearer {self.get_access_token()}',
        'Content-Type': 'application/json'
    }
    
    response = requests.post(endpoint, json=payload, headers=headers)
    return self.handle_api_response(response)
```

**Monetization Policy Management**
```python
def update_monetization_policy(video_id, policy_settings):
    """Update video monetization settings"""
    endpoint = f"{self.base_url}/videos"
    
    monetization_config = {
        'id': video_id,
        'monetizationDetails': {
            'access': policy_settings.get('access', 'allowed')
        },
        'status': {
            'monetizationDetails': {
                'access': policy_settings.get('monetization_access', 'allowed')
            }
        }
    }
    
    return self.make_authenticated_request('PUT', endpoint, monetization_config)
```

#### Channel Information Management

**Channel Data Retrieval**
```python
def get_channel_details(channel_id):
    """Retrieve comprehensive channel information"""
    endpoint = f"{self.base_url}/channels"
    params = {
        'id': channel_id,
        'part': 'snippet,statistics,status,contentDetails,brandingSettings',
        'key': self.api_key
    }
    
    response = requests.get(endpoint, params=params)
    return self.process_channel_response(response)

# Channel response structure
{
    "items": [
        {
            "id": "channel_id",
            "snippet": {
                "title": "Channel Name",
                "description": "Channel Description",
                "thumbnails": {...},
                "publishedAt": "2020-01-01T00:00:00Z",
                "country": "US"
            },
            "statistics": {
                "viewCount": "1000000",
                "subscriberCount": "10000",
                "videoCount": "500"
            },
            "status": {
                "privacyStatus": "public",
                "isLinked": true
            }
        }
    ]
}
```

### 2. AWS Systems Manager (SSM) Parameter Store Integration

#### Secure Credential Management

**SSM Parameter Store Configuration**
```python
from aws_sdk import SSMClient, GetParameterCommand, PutParameterCommand
from shared.keyManager import KeyManager

class SSMParameterManager:
    def __init__(self):
        self.ssm_client = SSMClient(region='<REGION>')
        self.api_key_parameter_name = "/distro-nation/appsync/api-key"
        self.youtube_api_parameter_name = "/distro-nation/token-api/api-key"
        
    async def get_secure_parameter(self, parameter_name):
        """Retrieve encrypted parameter from SSM Parameter Store"""
        try:
            command = GetParameterCommand({
                'Name': parameter_name,
                'WithDecryption': True
            })
            
            response = await self.ssm_client.send(command)
            
            if response.Parameter and response.Parameter.Value:
                return response.Parameter.Value
            else:
                raise Exception(f"Parameter {parameter_name} has no value")
                
        except Exception as e:
            logger.error(f"Failed to retrieve SSM parameter {parameter_name}: {e}")
            raise
    
    async def store_secure_parameter(self, parameter_name, value):
        """Store encrypted parameter in SSM Parameter Store"""
        try:
            command = PutParameterCommand({
                'Name': parameter_name,
                'Value': value,
                'Type': 'SecureString',
                'Overwrite': True
            })
            
            await self.ssm_client.send(command)
            logger.info(f"Successfully stored parameter {parameter_name}")
            
        except Exception as e:
            logger.error(f"Failed to store SSM parameter {parameter_name}: {e}")
            raise
```

#### API Key Lifecycle Management

**Automatic Key Creation and Rotation**
```python
class APIKeyLifecycleManager:
    def __init__(self):
        self.key_manager = KeyManager(
            api_id=os.environ.get('API_ID'),
            appSyncClient=AppSyncClient(region='<REGION>'),
            ssmClient=SSMClient(region='<REGION>')
        )
        
    async def initialize_api_key(self, existing_key=None):
        """Initialize API key with automatic creation and rotation"""
        try:
            # Step 1: Try to get key from SSM Parameter Store
            api_key = await self.key_manager.getApiKeyFromSSM(
                '/distro-nation/appsync/api-key'
            )
            
            # Step 2: Validate existing key
            if api_key:
                is_valid = await self.key_manager.validateApiKey(api_key)
                if is_valid:
                    return api_key
                    
            # Step 3: Create new key if none exists or current is invalid
            new_key_id = await self.key_manager.createApiKey(
                'Auto-generated by Lambda function'
            )
            
            # Step 4: Store new key in SSM
            if new_key_id:
                await self.key_manager.storeApiKeyInSSM(
                    '/distro-nation/appsync/api-key',
                    new_key_id
                )
                return new_key_id
                
        except Exception as e:
            logger.error(f"API key initialization failed: {e}")
            
            # Fallback to environment variable
            fallback_key = os.environ.get('API_DNBACKENDFUNCTIONS_GRAPHQLAPIKEYOUTPUT')
            if fallback_key:
                logger.info('Using environment variable fallback')
                return fallback_key
            
            raise Exception("Failed to initialize API key through all available methods")
    
    async def rotate_expired_keys(self):
        """Automatically rotate keys that are expiring within 30 days"""
        try:
            # List all API keys
            api_keys = await self.key_manager.listApiKeys()
            
            thirty_days = 30 * 24 * 60 * 60
            now = int(time.time())
            
            for key_id in api_keys:
                # Check if key expires within 30 days
                key_details = await self.get_key_details(key_id)
                
                if key_details['expires'] - now < thirty_days:
                    logger.info(f"Rotating key {key_id} expiring soon")
                    
                    new_key = await self.key_manager.rotateApiKey(
                        key_id, 
                        f"Rotated key replacing {key_id}"
                    )
                    
                    if new_key:
                        await self.key_manager.storeApiKeyInSSM(
                            '/distro-nation/appsync/api-key',
                            new_key
                        )
                        
        except Exception as e:
            logger.error(f"Key rotation failed: {e}")
            raise
```

#### Security and Compliance

**Comprehensive Audit Logging**
```python
class SecurityAuditLogger:
    def __init__(self):
        self.logger = Logger({
            'service': 'SSMParameterManager',
            'maskFields': ['apiKey', 'token', 'authorization', 'password', 'secret']
        })
    
    def audit_parameter_access(self, operation, parameter_name, outcome, actor=None):
        """Log all SSM parameter operations for compliance"""
        self.logger.audit(f'SSM_PARAMETER_{operation.upper()}', {
            'parameterName': parameter_name,
            'resourceType': 'SSM_PARAMETER',
            'action': operation.upper(),
            'outcome': outcome,
            'actor': actor or 'system',
            'storageType': 'SSM_PARAMETER_STORE'
        })
    
    def audit_key_lifecycle_event(self, event_type, key_id, outcome, details=None):
        """Log API key lifecycle events"""
        self.logger.audit(f'API_KEY_{event_type.upper()}', {
            'apiKeyId': key_id,
            'resourceType': 'API_KEY',
            'action': event_type.upper(),
            'outcome': outcome,
            'details': details or {}
        })
```

### 3. AWS S3 Integration

#### Configuration & Authentication

**AWS SDK Configuration**
```python
import boto3
from botocore.exceptions import ClientError, NoCredentialsError

class S3Manager:
    def __init__(self):
        self.access_key_id = app.config['AWS_ACCESS_KEY_ID']
        self.secret_access_key = app.config['AWS_SECRET_ACCESS_KEY']
        self.bucket_name = app.config.get('S3_BUCKET_NAME', 'yt-cms-reports')
        self.region = app.config.get('AWS_REGION', '<REGION>')
        
        self.s3_client = boto3.client(
            's3',
            aws_access_key_id=self.access_key_id,
            aws_secret_access_key=self.secret_access_key,
            region_name=self.region
        )
```

#### Report Processing Operations

**Report Download and Processing**
```python
def download_s3_report(report_key):
    """Download report file from S3 for processing"""
    try:
        local_path = f'/tmp/{report_key}'
        self.s3_client.download_file(
            self.bucket_name, 
            report_key, 
            local_path
        )
        
        # Validate file integrity
        if self.validate_report_file(local_path):
            return local_path
        else:
            raise ReportValidationError("Downloaded file failed validation")
            
    except ClientError as e:
        logger.error(f"S3 download failed: {e}")
        raise S3OperationError(f"Failed to download report: {e}")

def process_csv_report(file_path):
    """Process CSV report and extract video metadata"""
    processed_videos = []
    
    with open(file_path, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        
        for row in reader:
            video_data = self.extract_video_data(row)
            if self.validate_video_data(video_data):
                processed_videos.append(video_data)
            else:
                logger.warning(f"Invalid video data: {video_data}")
    
    return processed_videos

def extract_video_data(csv_row):
    """Extract and transform video data from CSV row"""
    return {
        'video_id': csv_row.get('Video ID'),
        'title': csv_row.get('Video title'),
        'channel_id': csv_row.get('Channel ID'),
        'channel_name': csv_row.get('Channel name'),
        'privacy_status': csv_row.get('Privacy status'),
        'claimed_status': csv_row.get('Claimed status'),
        'monetization_policy': csv_row.get('Effective policy'),
        'upload_date': self.parse_date(csv_row.get('Time published')),
        'duration': self.parse_duration(csv_row.get('Video duration')),
        # Additional metadata fields...
    }
```

**Backup Operations**
```python
def upload_backup_to_s3(backup_file_path, backup_key):
    """Upload database backup to S3"""
    try:
        self.s3_client.upload_file(
            backup_file_path,
            self.bucket_name,
            f'backups/{backup_key}',
            ExtraArgs={
                'ServerSideEncryption': 'AES256',
                'StorageClass': 'STANDARD_IA'
            }
        )
        
        logger.info(f"Backup uploaded successfully: {backup_key}")
        return True
        
    except ClientError as e:
        logger.error(f"Backup upload failed: {e}")
        return False

def list_available_backups():
    """List all available backup files in S3"""
    try:
        response = self.s3_client.list_objects_v2(
            Bucket=self.bucket_name,
            Prefix='backups/'
        )
        
        backups = []
        for obj in response.get('Contents', []):
            backups.append({
                'key': obj['Key'],
                'size': obj['Size'],
                'last_modified': obj['LastModified'],
                'storage_class': obj.get('StorageClass', 'STANDARD')
            })
        
        return sorted(backups, key=lambda x: x['last_modified'], reverse=True)
        
    except ClientError as e:
        logger.error(f"Failed to list backups: {e}")
        return []
```

### 3. Database Integration Patterns

#### Connection Management

**PostgreSQL Configuration**
```python
# Database connection configuration
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ.get("DATABASE_URL")
app.config["SQLALCHEMY_ENGINE_OPTIONS"] = {
    "pool_recycle": 300,        # Recycle connections every 5 minutes
    "pool_pre_ping": True,      # Validate connections before use
    "pool_size": 10,            # Maintain 10 connections in pool
    "max_overflow": 20,         # Allow up to 20 additional connections
    "pool_timeout": 30,         # 30 second timeout for getting connection
}

# Advanced database features
class DatabaseManager:
    def __init__(self):
        self.db = db
    
    def bulk_insert_videos(self, video_data_list):
        """Efficiently insert multiple videos"""
        try:
            db.session.bulk_insert_mappings(Video, video_data_list)
            db.session.commit()
            logger.info(f"Bulk inserted {len(video_data_list)} videos")
        except IntegrityError as e:
            db.session.rollback()
            logger.error(f"Bulk insert failed: {e}")
            raise
    
    def execute_complex_query(self, query_params):
        """Execute complex filtered queries with pagination"""
        query = db.session.query(Video)
        
        # Apply filters dynamically
        if query_params.get('search'):
            query = query.filter(Video.title.ilike(f"%{query_params['search']}%"))
        
        if query_params.get('category'):
            query = query.filter(Video.category == query_params['category'])
        
        # Apply sorting
        sort_field = getattr(Video, query_params.get('sort_by', 'updated_at'))
        if query_params.get('order') == 'desc':
            query = query.order_by(desc(sort_field))
        else:
            query = query.order_by(asc(sort_field))
        
        # Execute with pagination
        page = query_params.get('page', 1)
        per_page = query_params.get('per_page', 20)
        
        return query.paginate(
            page=page,
            per_page=per_page,
            error_out=False
        )
```

#### Metadata Synchronization Tracking

**Sync Status Management**
```python
class MetadataSync(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    video_id = db.Column(db.String(20), nullable=False)
    sync_time = db.Column(db.DateTime, default=datetime.utcnow)
    changes = db.Column(db.JSON)  # Store what was changed
    status = db.Column(db.String(20))  # success, failed, pending
    error_message = db.Column(db.Text, nullable=True)

def log_sync_operation(video_id, changes, status, error_message=None):
    """Log synchronization operation for audit trail"""
    sync_record = MetadataSync(
        video_id=video_id,
        changes=changes,
        status=status,
        error_message=error_message
    )
    
    db.session.add(sync_record)
    db.session.commit()
    
    # Emit real-time update
    socketio.emit('sync_status_update', {
        'video_id': video_id,
        'status': status,
        'timestamp': sync_record.sync_time.isoformat()
    })
```

## Real-time Communication

### WebSocket Integration

**Real-time Event System**
```python
from flask_socketio import SocketIO, emit

socketio = SocketIO(app, cors_allowed_origins="*")

@socketio.on('connect')
def handle_connect():
    """Handle client connection"""
    logger.info(f"Client connected: {request.sid}")
    emit('connection_status', {'status': 'connected'})

@socketio.on('disconnect')
def handle_disconnect():
    """Handle client disconnection"""
    logger.info(f"Client disconnected: {request.sid}")

def broadcast_video_update(video_data):
    """Broadcast video updates to all connected clients"""
    socketio.emit('video_update', {
        'video_id': video_data['video_id'],
        'title': video_data['title'],
        'status': video_data['status'],
        'last_updated': datetime.utcnow().isoformat()
    })

def broadcast_processing_status(status_data):
    """Broadcast report processing status"""
    socketio.emit('processing_update', {
        'status': status_data['status'],
        'progress': status_data.get('progress', 0),
        'message': status_data.get('message', ''),
        'timestamp': datetime.utcnow().isoformat()
    })
```

**Client-side WebSocket Handling**
```javascript
// Initialize WebSocket connection
const socket = io();

socket.on('connect', function() {
    console.log('Connected to server');
    updateConnectionStatus('connected');
});

socket.on('video_update', function(data) {
    updateVideoRow(data.video_id, data);
    showNotification(`Video ${data.video_id} updated`, 'success');
});

socket.on('processing_update', function(data) {
    updateProcessingProgress(data.progress);
    if (data.status === 'completed') {
        showNotification('Report processing completed', 'success');
        refreshVideoList();
    } else if (data.status === 'error') {
        showNotification(`Processing failed: ${data.message}`, 'error');
    }
});

socket.on('sync_status_update', function(data) {
    updateVideoSyncStatus(data.video_id, data.status);
    if (data.status === 'failed') {
        showSyncError(data.video_id);
    }
});
```

## Error Handling & Monitoring

### API Error Management

**Comprehensive Error Handling**
```python
class APIErrorHandler:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
    
    def handle_youtube_api_error(self, response):
        """Handle YouTube API specific errors"""
        if response.status_code == 401:
            raise AuthenticationError("YouTube API authentication failed")
        elif response.status_code == 403:
            raise AuthorizationError("Insufficient permissions for YouTube API")
        elif response.status_code == 429:
            raise RateLimitError("YouTube API rate limit exceeded")
        elif response.status_code >= 500:
            raise YouTubeServiceError("YouTube API server error")
        else:
            raise YouTubeAPIError(f"YouTube API error: {response.text}")
    
    def handle_s3_error(self, error):
        """Handle AWS S3 specific errors"""
        error_code = error.response['Error']['Code']
        
        if error_code == 'NoSuchBucket':
            raise S3ConfigError("S3 bucket does not exist")
        elif error_code == 'AccessDenied':
            raise S3PermissionError("Insufficient S3 permissions")
        elif error_code == 'NoSuchKey':
            raise S3FileNotFoundError("Requested file not found in S3")
        else:
            raise S3OperationError(f"S3 operation failed: {error}")
    
    def handle_database_error(self, error):
        """Handle database operation errors"""
        if isinstance(error, IntegrityError):
            db.session.rollback()
            raise DataIntegrityError("Database constraint violation")
        elif isinstance(error, OperationalError):
            raise DatabaseConnectionError("Database connection failed")
        else:
            db.session.rollback()
            raise DatabaseError(f"Database operation failed: {error}")
```

### Monitoring & Logging

**Comprehensive Logging System**
```python
import logging
from logging.handlers import RotatingFileHandler

def setup_logging(app):
    """Configure comprehensive logging"""
    if not app.debug:
        # File logging
        file_handler = RotatingFileHandler(
            'logs/youtube_cms.log', 
            maxBytes=10240000, 
            backupCount=10
        )
        file_handler.setFormatter(logging.Formatter(
            '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'
        ))
        file_handler.setLevel(logging.INFO)
        app.logger.addHandler(file_handler)
        
        # Console logging
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.WARNING)
        app.logger.addHandler(console_handler)
        
        app.logger.setLevel(logging.INFO)
        app.logger.info('YouTube CMS Metadata Tool startup')

# Custom logging decorators
def log_api_call(func):
    """Decorator to log API calls"""
    def wrapper(*args, **kwargs):
        start_time = time.time()
        try:
            result = func(*args, **kwargs)
            duration = time.time() - start_time
            logger.info(f"API call {func.__name__} completed in {duration:.2f}s")
            return result
        except Exception as e:
            duration = time.time() - start_time
            logger.error(f"API call {func.__name__} failed after {duration:.2f}s: {e}")
            raise
    return wrapper

def log_database_operation(func):
    """Decorator to log database operations"""
    def wrapper(*args, **kwargs):
        try:
            result = func(*args, **kwargs)
            logger.info(f"Database operation {func.__name__} completed successfully")
            return result
        except Exception as e:
            logger.error(f"Database operation {func.__name__} failed: {e}")
            raise
    return wrapper
```

## Security Considerations

### Enhanced API Security with SSM Parameter Store

**SSM-Based Secure Credential Management**
```python
class EnhancedSecureCredentialManager:
    def __init__(self):
        self.ssm_client = SSMClient(region='<REGION>')
        self.app_sync_client = AppSyncClient(region='<REGION>')
        self.logger = Logger({
            'service': 'SecureCredentialManager',
            'maskFields': ['apiKey', 'token', 'authorization', 'password', 'secret']
        })
    
    async def get_encrypted_credential(self, parameter_name):
        """Retrieve encrypted credential from SSM Parameter Store"""
        try:
            self.logger.audit('CREDENTIAL_RETRIEVAL_INITIATED', {
                'parameterName': parameter_name,
                'resourceType': 'CREDENTIAL',
                'action': 'RETRIEVE',
                'storageType': 'SSM_PARAMETER_STORE'
            })
            
            command = GetParameterCommand({
                'Name': parameter_name,
                'WithDecryption': True  # SSM handles decryption with KMS
            })
            
            response = await self.ssm_client.send(command)
            
            if response.Parameter and response.Parameter.Value:
                self.logger.audit('CREDENTIAL_RETRIEVED', {
                    'parameterName': parameter_name,
                    'resourceType': 'CREDENTIAL',
                    'action': 'RETRIEVE',
                    'outcome': 'SUCCESS',
                    'storageType': 'SSM_PARAMETER_STORE'
                })
                
                return response.Parameter.Value
            else:
                raise Exception("Parameter value is empty")
                
        except Exception as e:
            self.logger.audit('CREDENTIAL_RETRIEVAL_FAILED', {
                'parameterName': parameter_name,
                'resourceType': 'CREDENTIAL',
                'action': 'RETRIEVE',
                'outcome': 'FAILURE',
                'errorMessage': str(e),
                'storageType': 'SSM_PARAMETER_STORE'
            })
            raise
    
    async def store_encrypted_credential(self, parameter_name, credential_value):
        """Store encrypted credential in SSM Parameter Store"""
        try:
            # Validate parameter name format
            if not re.match(r'^[a-zA-Z0-9_.\-/]+$', parameter_name):
                raise ValueError("Invalid parameter name format")
            
            if len(parameter_name) > 1024:
                raise ValueError("Parameter name too long")
            
            if len(credential_value) > 4096:
                raise ValueError("Credential value too long")
            
            self.logger.audit('CREDENTIAL_STORAGE_INITIATED', {
                'parameterName': parameter_name,
                'resourceType': 'CREDENTIAL',
                'action': 'STORE',
                'storageType': 'SSM_PARAMETER_STORE'
            })
            
            command = PutParameterCommand({
                'Name': parameter_name,
                'Value': credential_value,
                'Type': 'SecureString',  # Encrypted with KMS
                'Overwrite': True
            })
            
            await self.ssm_client.send(command)
            
            self.logger.audit('CREDENTIAL_STORED', {
                'parameterName': parameter_name,
                'resourceType': 'CREDENTIAL',
                'action': 'STORE',
                'outcome': 'SUCCESS',
                'storageType': 'SSM_PARAMETER_STORE'
            })
            
        except Exception as e:
            self.logger.audit('CREDENTIAL_STORAGE_FAILED', {
                'parameterName': parameter_name,
                'resourceType': 'CREDENTIAL',
                'action': 'STORE',
                'outcome': 'FAILURE',
                'errorMessage': str(e),
                'storageType': 'SSM_PARAMETER_STORE'
            })
            raise
    
    async def rotate_api_keys_automatically(self):
        """Advanced API key rotation with lifecycle management"""
        try:
            # List all AppSync API keys
            list_command = ListApiKeysCommand({
                'apiId': os.environ.get('API_ID')
            })
            
            response = await self.app_sync_client.send(list_command)
            
            if not response.apiKeys:
                # No keys exist, create one
                await self.create_new_api_key('Initial API Key')
                return
            
            now = int(time.time())
            thirty_days = 30 * 24 * 60 * 60
            
            for key in response.apiKeys:
                if key.expires and (key.expires - now) < thirty_days:
                    # Key expiring soon, rotate it
                    await self.rotate_specific_key(key.id, key.description)
                    
        except Exception as e:
            self.logger.error('AUTOMATIC_KEY_ROTATION_ERROR', {}, e)
            raise
    
    async def create_new_api_key(self, description):
        """Create new AppSync API key with secure storage"""
        try:
            # Create key with 365-day expiration
            expires = int(time.time()) + (365 * 24 * 60 * 60)
            
            create_command = CreateApiKeyCommand({
                'apiId': os.environ.get('API_ID'),
                'description': description,
                'expires': expires
            })
            
            response = await self.app_sync_client.send(create_command)
            
            if response.apiKey and response.apiKey.id:
                # Store the new key in SSM
                await self.store_encrypted_credential(
                    '/distro-nation/appsync/api-key',
                    response.apiKey.id
                )
                
                self.logger.audit('API_KEY_CREATED_AND_STORED', {
                    'apiKeyId': response.apiKey.id,
                    'resourceType': 'API_KEY',
                    'action': 'CREATE',
                    'outcome': 'SUCCESS',
                    'expiresAt': datetime.fromtimestamp(expires).isoformat()
                })
                
                return response.apiKey.id
                
        except Exception as e:
            self.logger.error('NEW_API_KEY_CREATION_ERROR', {}, e)
            raise
```

**Legacy Secure Credential Management (Deprecated)**
```python
class LegacySecureCredentialManager:
    def __init__(self):
        self.encryption_key = os.environ.get('ENCRYPTION_KEY')
    
    def encrypt_credentials(self, credentials):
        """Encrypt sensitive credentials - replaced by SSM Parameter Store"""
        from cryptography.fernet import Fernet
        f = Fernet(self.encryption_key)
        return f.encrypt(credentials.encode())
```

**Request Validation**
```python
from marshmallow import Schema, fields, validate

class VideoUpdateSchema(Schema):
    video_id = fields.Str(required=True, validate=validate.Length(min=1, max=20))
    title = fields.Str(validate=validate.Length(max=200))
    privacy_status = fields.Str(validate=validate.OneOf(['public', 'private', 'unlisted']))
    artist = fields.List(fields.Str(validate=validate.Length(max=200)))
    genre = fields.List(fields.Str(validate=validate.Length(max=100)))

def validate_api_request(schema_class):
    """Decorator for API request validation"""
    def decorator(func):
        def wrapper(*args, **kwargs):
            schema = schema_class()
            try:
                validated_data = schema.load(request.json)
                return func(validated_data, *args, **kwargs)
            except ValidationError as e:
                return jsonify({'errors': e.messages}), 400
        return wrapper
    return decorator
```

## SSM Parameter Store Security Best Practices

### Parameter Naming Conventions
- **Use hierarchical naming**: `/distro-nation/service/parameter-type`
- **Environment separation**: `/distro-nation/prod/service/parameter` vs `/distro-nation/dev/service/parameter`
- **Descriptive names**: `/distro-nation/appsync/api-key` not `/distro-nation/key`

### Access Control and IAM Policies
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      "Resource": [
        "arn:aws:ssm:<REGION>:*:parameter/distro-nation/appsync/*",
        "arn:aws:ssm:<REGION>:*:parameter/distro-nation/token-api/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:PutParameter"
      ],
      "Resource": [
        "arn:aws:ssm:<REGION>:*:parameter/distro-nation/appsync/*"
      ],
      "Condition": {
        "StringEquals": {
          "ssm:ParameterType": "SecureString"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": [
        "arn:aws:kms:<REGION>:*:key/*"
      ],
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "ssm.<REGION>.amazonaws.com"
        }
      }
    }
  ]
}
```

### Encryption and Key Management
- **Always use SecureString type** for sensitive parameters
- **KMS encryption by default** for all credential storage
- **Separate KMS keys** for different environments (prod vs dev)
- **Key rotation policies** for both SSM parameters and KMS keys

### Monitoring and Alerting
```python
# CloudWatch metrics for parameter access
def setup_ssm_monitoring():
    """Setup monitoring for SSM parameter operations"""
    cloudwatch = CloudWatchClient()
    
    # Custom metrics for parameter access
    cloudwatch.put_metric_data(
        Namespace='DistroNation/SSM',
        MetricData=[
            {
                'MetricName': 'ParameterAccess',
                'Dimensions': [
                    {'Name': 'ParameterName', 'Value': parameter_name},
                    {'Name': 'Operation', 'Value': 'GetParameter'}
                ],
                'Value': 1.0,
                'Unit': 'Count'
            }
        ]
    )
    
    # Alerts for unusual parameter access patterns
    cloudwatch.put_alarm(
        AlarmName='SSM-UnusualParameterAccess',
        ComparisonOperator='GreaterThanThreshold',
        EvaluationPeriods=1,
        MetricName='ParameterAccess',
        Namespace='DistroNation/SSM',
        Period=300,
        Statistic='Sum',
        Threshold=100.0,
        ActionsEnabled=True,
        AlarmDescription='Unusual SSM parameter access detected'
    )
```

### Backup and Recovery
- **Parameter versioning** enabled for all SecureString parameters
- **Cross-region replication** for critical parameters
- **Automated backup scripts** for parameter restoration
- **Disaster recovery procedures** documented and tested

This comprehensive API integration documentation provides complete coverage of all external service interactions with enhanced SSM Parameter Store security, enabling secure, efficient, and reliable operations within the YouTube CMS Metadata Management Tool ecosystem.