# Client Integration Guide

## Overview
This guide provides comprehensive instructions for integrating with the Distro Nation API ecosystem. It covers both APIs, authentication methods, SDKs, error handling, and best practices for client applications.

## API Endpoints Summary

### dn-api (Administrative API)
- **Base URL**: `https://<API_GATEWAY_ID_2>.execute-api.<REGION>.amazonaws.com/staging`
- **Authentication**: None (currently open)
- **Rate Limiting**: None (currently)
- **CORS**: Enabled with wildcard origin
- **Primary Use**: Backend administrative operations

### distronationfmGeneralAccess (DistroFM API)
- **Base URL**: `https://<API_GATEWAY_ID_1>.execute-api.<REGION>.amazonaws.com/main`
- **Authentication**: AWS IAM (Signature V4)
- **Rate Limiting**: 5,000 burst, 10,000/second
- **CORS**: Enabled with preflight support
- **Primary Use**: Content and artist management

## Quick Start Guide

### 1. Basic Setup for dn-api

#### JavaScript/Node.js
```javascript
class DistroNationAPI {
  constructor() {
    this.baseURL = 'https://<API_GATEWAY_ID_2>.execute-api.<REGION>.amazonaws.com/staging';
  }
  
  async makeRequest(endpoint, method = 'GET', body = null) {
    const url = `${this.baseURL}${endpoint}`;
    const options = {
      method,
      headers: {
        'Content-Type': 'application/json',
      }
    };
    
    if (body) {
      options.body = JSON.stringify(body);
    }
    
    try {
      const response = await fetch(url, options);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      return await response.json();
    } catch (error) {
      console.error('API request failed:', error);
      throw error;
    }
  }
  
  // User management
  async getUsers(limit = 20, offset = 0) {
    return this.makeRequest(`/dn_users_list?limit=${limit}&offset=${offset}`);
  }
  
  async updateUser(userData) {
    return this.makeRequest('/update-dnfm-user', 'POST', userData);
  }
  
  // Email service
  async sendEmail(emailData) {
    return this.makeRequest('/send-mail', 'POST', emailData);
  }
  
  // Payout operations
  async getPayouts(filters = {}) {
    const params = new URLSearchParams(filters);
    return this.makeRequest(`/dn_payouts_fetch?${params}`);
  }
  
  // Health check
  async healthCheck() {
    return this.makeRequest('/hollow');
  }
}

// Usage
const api = new DistroNationAPI();

// Get users
const users = await api.getUsers(10, 0);
console.log('Users:', users);

// Send email
await api.sendEmail({
  to: ['user@example.com'],
  subject: 'Welcome to Distro Nation',
  body: 'Thank you for joining our platform!',
  isHtml: false
});
```

#### Python
```python
import requests
import json
from typing import Optional, Dict, Any

class DistroNationAPI:
    def __init__(self):
        self.base_url = 'https://<API_GATEWAY_ID_2>.execute-api.<REGION>.amazonaws.com/staging'
        self.session = requests.Session()
    
    def make_request(self, endpoint: str, method: str = 'GET', data: Optional[Dict] = None) -> Dict[str, Any]:
        url = f"{self.base_url}{endpoint}"
        
        try:
            response = self.session.request(
                method=method,
                url=url,
                json=data,
                headers={'Content-Type': 'application/json'}
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"API request failed: {e}")
            raise
    
    def get_users(self, limit: int = 20, offset: int = 0) -> Dict[str, Any]:
        return self.make_request(f'/dn_users_list?limit={limit}&offset={offset}')
    
    def update_user(self, user_data: Dict[str, Any]) -> Dict[str, Any]:
        return self.make_request('/update-dnfm-user', 'POST', user_data)
    
    def send_email(self, email_data: Dict[str, Any]) -> Dict[str, Any]:
        return self.make_request('/send-mail', 'POST', email_data)
    
    def get_payouts(self, **filters) -> Dict[str, Any]:
        params = '&'.join([f"{k}={v}" for k, v in filters.items()])
        endpoint = f'/dn_payouts_fetch?{params}' if params else '/dn_payouts_fetch'
        return self.make_request(endpoint)

# Usage
api = DistroNationAPI()

# Get users
users = api.get_users(limit=10)
print('Users:', users)

# Send email
api.send_email({
    'to': ['user@example.com'],
    'subject': 'Welcome to Distro Nation',
    'body': 'Thank you for joining our platform!',
    'isHtml': False
})
```

### 2. AWS IAM Setup for distronationfmGeneralAccess

#### Prerequisites
1. AWS Account with appropriate permissions
2. AWS CLI configured or AWS SDK credentials
3. IAM user with execute-api permissions

#### JavaScript with AWS SDK
```javascript
const AWS = require('aws-sdk');

class DistroFMAPI {
  constructor(credentials) {
    this.baseURL = 'https://<API_GATEWAY_ID_1>.execute-api.<REGION>.amazonaws.com/main';
    this.region = '<REGION>';
    
    // Configure AWS credentials
    AWS.config.update({
      accessKeyId: credentials.accessKeyId,
      secretAccessKey: credentials.secretAccessKey,
      region: this.region
    });
  }
  
  async makeSignedRequest(path, method = 'GET', body = null) {
    const endpoint = new AWS.Endpoint(this.baseURL.replace('https://', ''));
    const request = new AWS.HttpRequest(endpoint, this.region);
    
    request.method = method;
    request.path = path;
    request.headers['Host'] = endpoint.host;
    request.headers['Content-Type'] = 'application/json';
    
    if (body) {
      request.body = JSON.stringify(body);
    }
    
    // Sign the request
    const signer = new AWS.Signers.V4(request, 'execute-api');
    signer.addAuthorization(AWS.config.credentials, new Date());
    
    // Make the request
    const response = await fetch(`https://${request.headers.Host}${request.path}`, {
      method: request.method,
      headers: request.headers,
      body: request.body
    });
    
    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`HTTP ${response.status}: ${errorBody}`);
    }
    
    return response.json();
  }
  
  // Artist management
  async getArtistInfo(artistId, options = {}) {
    let path = `/artist-info/${artistId}`;
    if (Object.keys(options).length > 0) {
      const params = new URLSearchParams(options);
      path += `?${params}`;
    }
    return this.makeSignedRequest(path);
  }
  
  async updateArtistInfo(artistId, artistData) {
    return this.makeSignedRequest(`/artist-info/${artistId}`, 'POST', { artistData });
  }
  
  // Video operations
  async submitVideo(videoData) {
    return this.makeSignedRequest('/submit-video', 'POST', videoData);
  }
  
  async getVideoSubmissions(filters = {}) {
    const params = new URLSearchParams(filters);
    const path = `/submit-video?${params}`;
    return this.makeSignedRequest(path);
  }
  
  // Content parsing
  async parseContent(contentId, options = {}) {
    let path = `/parse/${contentId}`;
    if (Object.keys(options).length > 0) {
      const params = new URLSearchParams(options);
      path += `?${params}`;
    }
    return this.makeSignedRequest(path);
  }
  
  // Video evaluation
  async evaluateVideoId(videoId, options = {}) {
    let path = `/evalvideoid/${videoId}`;
    if (Object.keys(options).length > 0) {
      const params = new URLSearchParams(options);
      path += `?${params}`;
    }
    return this.makeSignedRequest(path);
  }
}

// Usage
const distroFM = new DistroFMAPI({
  accessKeyId: 'YOUR_ACCESS_KEY',
  secretAccessKey: 'YOUR_SECRET_KEY'
});

// Get artist information
const artistInfo = await distroFM.getArtistInfo('artist123', {
  includeMetrics: true,
  platform: 'youtube'
});

// Submit video
const videoSubmission = await distroFM.submitVideo({
  title: 'New Music Video',
  description: 'Latest single release',
  artistId: 'artist123',
  category: 'music',
  visibility: 'public'
});
```

#### Python with boto3
```python
import boto3
import requests
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
from urllib.parse import urlencode

class DistroFMAPI:
    def __init__(self, aws_access_key_id, aws_secret_access_key, region='<REGION>'):
        self.base_url = 'https://<API_GATEWAY_ID_1>.execute-api.<REGION>.amazonaws.com/main'
        self.region = region
        
        # Create AWS session
        self.session = boto3.Session(
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key,
            region_name=region
        )
        self.credentials = self.session.get_credentials()
    
    def make_signed_request(self, path, method='GET', data=None, params=None):
        # Build URL
        url = f"{self.base_url}{path}"
        if params:
            url += f"?{urlencode(params)}"
        
        # Create AWS request
        request = AWSRequest(
            method=method,
            url=url,
            data=data,
            headers={'Content-Type': 'application/json'} if data else {}
        )
        
        # Sign request
        SigV4Auth(self.credentials, 'execute-api', self.region).add_auth(request)
        
        # Make request
        response = requests.request(
            method=request.method,
            url=request.url,
            headers=dict(request.headers),
            data=request.body
        )
        
        response.raise_for_status()
        return response.json()
    
    def get_artist_info(self, artist_id, **options):
        return self.make_signed_request(f'/artist-info/{artist_id}', params=options)
    
    def update_artist_info(self, artist_id, artist_data):
        return self.make_signed_request(
            f'/artist-info/{artist_id}',
            method='POST',
            data=json.dumps({'artistData': artist_data})
        )
    
    def submit_video(self, video_data):
        return self.make_signed_request(
            '/submit-video',
            method='POST',
            data=json.dumps(video_data)
        )
    
    def parse_content(self, content_id, **options):
        return self.make_signed_request(f'/parse/{content_id}', params=options)
    
    def evaluate_video_id(self, video_id, **options):
        return self.make_signed_request(f'/evalvideoid/{video_id}', params=options)

# Usage
distro_fm = DistroFMAPI('YOUR_ACCESS_KEY', 'YOUR_SECRET_KEY')

# Get artist info
artist_info = distro_fm.get_artist_info('artist123', includeMetrics=True)
print('Artist Info:', artist_info)
```

## Error Handling Patterns

### Standard Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {
      "field": "Specific field error",
      "timestamp": "2024-07-24T12:00:00Z"
    }
  }
}
```

### Comprehensive Error Handling
```javascript
class APIError extends Error {
  constructor(status, response, originalError = null) {
    super(response.error?.message || 'API request failed');
    this.name = 'APIError';
    this.status = status;
    this.code = response.error?.code;
    this.details = response.error?.details;
    this.originalError = originalError;
  }
}

const handleAPIError = (error) => {
  if (error instanceof APIError) {
    switch (error.code) {
      case 'VALIDATION_ERROR':
        console.error('Invalid input data:', error.details);
        // Show user-friendly validation messages
        break;
      case 'RATE_LIMIT_EXCEEDED':
        console.warn('Rate limit exceeded, retrying after delay');
        // Implement exponential backoff
        break;
      case 'AUTHENTICATION_FAILED':
        console.error('Authentication failed, redirecting to login');
        // Redirect to authentication flow
        break;
      case 'RESOURCE_NOT_FOUND':
        console.error('Resource not found:', error.message);
        // Handle missing resources gracefully
        break;
      default:
        console.error('Unknown API error:', error);
        // Generic error handling
    }
  } else {
    console.error('Network or other error:', error);
    // Handle network errors, timeouts, etc.
  }
};

// Enhanced request method with retry logic
async function makeRequestWithRetry(requestFn, maxRetries = 3, baseDelay = 1000) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await requestFn();
    } catch (error) {
      if (attempt === maxRetries) {
        throw error;
      }
      
      // Determine if error is retryable
      const isRetryable = error.status >= 500 || 
                         error.code === 'RATE_LIMIT_EXCEEDED' ||
                         error.code === 'NETWORK_ERROR';
      
      if (!isRetryable) {
        throw error;
      }
      
      // Exponential backoff with jitter
      const delay = baseDelay * Math.pow(2, attempt - 1) + Math.random() * 1000;
      console.log(`Attempt ${attempt} failed, retrying after ${delay}ms`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}

// Usage
try {
  const result = await makeRequestWithRetry(() => api.getUsers());
  console.log('Success:', result);
} catch (error) {
  handleAPIError(error);
}
```

## Rate Limiting & Best Practices

### Rate Limiting Implementation
```javascript
class RateLimitedClient {
  constructor(requestsPerSecond = 10) {
    this.requestsPerSecond = requestsPerSecond;
    this.requestQueue = [];
    this.isProcessing = false;
    this.lastRequestTime = 0;
  }
  
  async makeRequest(requestFn) {
    return new Promise((resolve, reject) => {
      this.requestQueue.push({ requestFn, resolve, reject });
      this.processQueue();
    });
  }
  
  async processQueue() {
    if (this.isProcessing || this.requestQueue.length === 0) {
      return;
    }
    
    this.isProcessing = true;
    
    while (this.requestQueue.length > 0) {
      const now = Date.now();
      const timeSinceLastRequest = now - this.lastRequestTime;
      const minInterval = 1000 / this.requestsPerSecond;
      
      if (timeSinceLastRequest < minInterval) {
        await new Promise(resolve => 
          setTimeout(resolve, minInterval - timeSinceLastRequest)
        );
      }
      
      const { requestFn, resolve, reject } = this.requestQueue.shift();
      this.lastRequestTime = Date.now();
      
      try {
        const result = await requestFn();
        resolve(result);
      } catch (error) {
        reject(error);
      }
    }
    
    this.isProcessing = false;
  }
}

// Usage
const rateLimitedAPI = new RateLimitedClient(5); // 5 requests per second

// All requests will be automatically rate limited
const users = await rateLimitedAPI.makeRequest(() => api.getUsers());
const payouts = await rateLimitedAPI.makeRequest(() => api.getPayouts());
```

### Batch Operations
```javascript
class BatchProcessor {
  constructor(api, batchSize = 10, delayBetweenBatches = 1000) {
    this.api = api;
    this.batchSize = batchSize;
    this.delayBetweenBatches = delayBetweenBatches;
  }
  
  async processBatch(items, processFn) {
    const results = [];
    const errors = [];
    
    for (let i = 0; i < items.length; i += this.batchSize) {
      const batch = items.slice(i, i + this.batchSize);
      
      const batchPromises = batch.map(async (item, index) => {
        try {
          const result = await processFn(item);
          return { success: true, item, result, index: i + index };
        } catch (error) {
          return { success: false, item, error, index: i + index };
        }
      });
      
      const batchResults = await Promise.allSettled(batchPromises);
      
      batchResults.forEach(result => {
        if (result.status === 'fulfilled') {
          if (result.value.success) {
            results.push(result.value);
          } else {
            errors.push(result.value);
          }
        } else {
          errors.push({
            success: false,
            error: result.reason,
            item: null,
            index: -1
          });
        }
      });
      
      // Delay between batches
      if (i + this.batchSize < items.length) {
        await new Promise(resolve => setTimeout(resolve, this.delayBetweenBatches));
      }
    }
    
    return { results, errors, total: items.length };
  }
}

// Usage
const batchProcessor = new BatchProcessor(api, 5, 500);

const userIds = ['user1', 'user2', 'user3', /*...*/];
const batchResult = await batchProcessor.processBatch(
  userIds,
  async (userId) => {
    return api.updateUser({ userId, lastSeen: new Date() });
  }
);

console.log(`Processed ${batchResult.results.length} successfully`);
console.log(`Failed ${batchResult.errors.length} requests`);
```

## SDK and Code Generation

### TypeScript Definitions
```typescript
// types/distro-nation-api.ts
export interface User {
  id: string;
  name: string;
  email: string;
  createdAt: string;
  updatedAt: string;
  profile?: Record<string, any>;
  status: 'active' | 'inactive' | 'suspended';
}

export interface Payout {
  id: string;
  userId: string;
  amount: number;
  currency: string;
  status: 'pending' | 'completed' | 'failed';
  createdAt: string;
  processedAt?: string;
  metadata?: Record<string, any>;
}

export interface EmailRequest {
  to: string[];
  cc?: string[];
  bcc?: string[];
  subject: string;
  body: string;
  isHtml?: boolean;
  templateId?: string;
  templateData?: Record<string, any>;
}

export interface ArtistInfo {
  id: string;
  name: string;
  bio?: string;
  genres: string[];
  socialMedia: {
    youtube?: string;
    spotify?: string;
    tiktok?: string;
    instagram?: string;
  };
  metrics?: {
    totalViews: number;
    totalStreams: number;
    monthlyListeners: number;
    followers: Record<string, number>;
  };
}

export interface VideoSubmission {
  title: string;
  description?: string;
  tags?: string[];
  artistId: string;
  category: 'music' | 'interview' | 'live' | 'behind-scenes';
  visibility: 'public' | 'private' | 'unlisted';
  scheduledAt?: string;
  thumbnailUrl?: string;
  metadata?: Record<string, any>;
}

export interface APIResponse<T = any> {
  success: boolean;
  message?: string;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: Record<string, any>;
  };
}

// Main API client interfaces
export interface DistroNationAPIClient {
  // User management
  getUsers(limit?: number, offset?: number): Promise<APIResponse<{ users: User[]; total: number }>>;
  updateUser(userData: Partial<User>): Promise<APIResponse<User>>;
  
  // Email service
  sendEmail(emailData: EmailRequest): Promise<APIResponse<{ messageId: string }>>;
  
  // Payout operations
  getPayouts(filters?: Record<string, any>): Promise<APIResponse<{ payouts: Payout[]; summary: any }>>;
  
  // Health check
  healthCheck(): Promise<APIResponse<{ status: string; timestamp: string }>>;
}

export interface DistroFMAPIClient {
  // Artist management
  getArtistInfo(artistId: string, options?: Record<string, any>): Promise<APIResponse<ArtistInfo>>;
  updateArtistInfo(artistId: string, artistData: Partial<ArtistInfo>): Promise<APIResponse<ArtistInfo>>;
  
  // Video operations
  submitVideo(videoData: VideoSubmission): Promise<APIResponse<{ submissionId: string; status: string }>>;
  getVideoSubmissions(filters?: Record<string, any>): Promise<APIResponse<{ submissions: any[] }>>;
  
  // Content parsing
  parseContent(contentId: string, options?: Record<string, any>): Promise<APIResponse<any>>;
  
  // Video evaluation
  evaluateVideoId(videoId: string, options?: Record<string, any>): Promise<APIResponse<any>>;
}
```

### React Hook Examples
```typescript
// hooks/useDistroNationAPI.ts
import { useState, useCallback } from 'react';
import { DistroNationAPIClient, User, APIResponse } from '../types/distro-nation-api';

export const useDistroNationAPI = (client: DistroNationAPIClient) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const executeRequest = useCallback(async <T>(
    requestFn: () => Promise<APIResponse<T>>
  ): Promise<T | null> => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await requestFn();
      
      if (!response.success) {
        throw new Error(response.error?.message || 'API request failed');
      }
      
      return response.data || null;
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error';
      setError(errorMessage);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);
  
  const getUsers = useCallback((limit?: number, offset?: number) => {
    return executeRequest(() => client.getUsers(limit, offset));
  }, [client, executeRequest]);
  
  const updateUser = useCallback((userData: Partial<User>) => {
    return executeRequest(() => client.updateUser(userData));
  }, [client, executeRequest]);
  
  const sendEmail = useCallback((emailData: any) => {
    return executeRequest(() => client.sendEmail(emailData));
  }, [client, executeRequest]);
  
  return {
    loading,
    error,
    getUsers,
    updateUser,
    sendEmail,
    clearError: () => setError(null)
  };
};

// React component usage
import React from 'react';
import { useDistroNationAPI } from '../hooks/useDistroNationAPI';

const UsersList: React.FC = () => {
  const { loading, error, getUsers } = useDistroNationAPI(apiClient);
  const [users, setUsers] = useState<User[]>([]);
  
  useEffect(() => {
    const fetchUsers = async () => {
      const result = await getUsers(20, 0);
      if (result) {
        setUsers(result.users);
      }
    };
    
    fetchUsers();
  }, [getUsers]);
  
  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;
  
  return (
    <div>
      <h2>Users</h2>
      {users.map(user => (
        <div key={user.id}>
          <h3>{user.name}</h3>
          <p>{user.email}</p>
        </div>
      ))}
    </div>
  );
};
```

## Testing Strategies

### Unit Testing
```javascript
// tests/api-client.test.js
import { DistroNationAPI } from '../src/api-client';
import fetchMock from 'jest-fetch-mock';

describe('DistroNationAPI', () => {
  let api;
  
  beforeEach(() => {
    fetchMock.resetMocks();
    api = new DistroNationAPI();
  });
  
  describe('getUsers', () => {
    it('should fetch users successfully', async () => {
      const mockUsers = {
        users: [
          { id: '1', name: 'John Doe', email: 'john@example.com' }
        ],
        total: 1
      };
      
      fetchMock.mockResponseOnce(JSON.stringify(mockUsers));
      
      const result = await api.getUsers(10, 0);
      
      expect(fetchMock).toHaveBeenCalledWith(
        'https://<API_GATEWAY_ID_2>.execute-api.<REGION>.amazonaws.com/staging/dn_users_list?limit=10&offset=0',
        expect.objectContaining({
          method: 'GET',
          headers: { 'Content-Type': 'application/json' }
        })
      );
      
      expect(result).toEqual(mockUsers);
    });
    
    it('should handle API errors', async () => {
      fetchMock.mockRejectOnce(new Error('Network error'));
      
      await expect(api.getUsers()).rejects.toThrow('Network error');
    });
  });
  
  describe('sendEmail', () => {
    it('should send email successfully', async () => {
      const emailData = {
        to: ['test@example.com'],
        subject: 'Test',
        body: 'Test message'
      };
      
      fetchMock.mockResponseOnce(JSON.stringify({ success: true }));
      
      const result = await api.sendEmail(emailData);
      
      expect(fetchMock).toHaveBeenCalledWith(
        'https://<API_GATEWAY_ID_2>.execute-api.<REGION>.amazonaws.com/staging/send-mail',
        expect.objectContaining({
          method: 'POST',
          body: JSON.stringify(emailData)
        })
      );
      
      expect(result).toEqual({ success: true });
    });
  });
});
```

### Integration Testing
```javascript
// tests/integration.test.js
import { DistroNationAPI } from '../src/api-client';

describe('Integration Tests', () => {
  let api;
  
  beforeAll(() => {
    // Use test environment endpoints
    api = new DistroNationAPI({
      baseURL: process.env.TEST_API_URL || 'https://test-api.distronation.com'
    });
  });
  
  it('should perform complete user workflow', async () => {
    // Create user
    const newUser = await api.createUser({
      name: 'Test User',
      email: 'test@example.com'
    });
    
    expect(newUser.id).toBeDefined();
    expect(newUser.name).toBe('Test User');
    
    // Update user
    const updatedUser = await api.updateUser({
      ...newUser,
      name: 'Updated Test User'
    });
    
    expect(updatedUser.name).toBe('Updated Test User');
    
    // Fetch users and verify
    const users = await api.getUsers();
    const foundUser = users.users.find(u => u.id === newUser.id);
    
    expect(foundUser).toBeDefined();
    expect(foundUser.name).toBe('Updated Test User');
    
    // Cleanup
    await api.deleteUser(newUser.id);
  });
});
```

## Performance Optimization

### Caching Strategy
```javascript
class CachedAPIClient {
  constructor(apiClient, cacheConfig = {}) {
    this.api = apiClient;
    this.cache = new Map();
    this.cacheConfig = {
      defaultTTL: 5 * 60 * 1000, // 5 minutes
      maxSize: 1000,
      ...cacheConfig
    };
  }
  
  generateCacheKey(method, ...args) {
    return `${method}:${JSON.stringify(args)}`;
  }
  
  isCacheValid(entry) {
    return Date.now() - entry.timestamp < entry.ttl;
  }
  
  get(key) {
    const entry = this.cache.get(key);
    if (entry && this.isCacheValid(entry)) {
      return entry.data;
    }
    
    if (entry) {
      this.cache.delete(key);
    }
    
    return null;
  }
  
  set(key, data, ttl = this.cacheConfig.defaultTTL) {
    // Evict oldest entries if cache is full
    if (this.cache.size >= this.cacheConfig.maxSize) {
      const firstKey = this.cache.keys().next().value;
      this.cache.delete(firstKey);
    }
    
    this.cache.set(key, {
      data,
      timestamp: Date.now(),
      ttl
    });
  }
  
  async cachedRequest(method, args, options = {}) {
    const cacheKey = this.generateCacheKey(method, ...args);
    const ttl = options.ttl || this.cacheConfig.defaultTTL;
    
    // Try cache first
    const cached = this.get(cacheKey);
    if (cached) {
      return cached;
    }
    
    // Make API request
    const result = await this.api[method](...args);
    
    // Cache the result
    if (options.cache !== false) {
      this.set(cacheKey, result, ttl);
    }
    
    return result;
  }
  
  // Cached methods
  async getUsers(...args) {
    return this.cachedRequest('getUsers', args, { ttl: 2 * 60 * 1000 }); // 2 minutes
  }
  
  async getArtistInfo(...args) {
    return this.cachedRequest('getArtistInfo', args, { ttl: 10 * 60 * 1000 }); // 10 minutes
  }
  
  // Non-cached methods (mutations)
  async updateUser(...args) {
    const result = await this.api.updateUser(...args);
    // Invalidate related cache entries
    this.invalidatePattern('getUsers:');
    return result;
  }
  
  invalidatePattern(pattern) {
    for (const key of this.cache.keys()) {
      if (key.includes(pattern)) {
        this.cache.delete(key);
      }
    }
  }
  
  clearCache() {
    this.cache.clear();
  }
}

// Usage
const cachedAPI = new CachedAPIClient(api, {
  defaultTTL: 5 * 60 * 1000, // 5 minutes
  maxSize: 500
});

// First call hits the API
const users1 = await cachedAPI.getUsers();

// Second call returns cached result
const users2 = await cachedAPI.getUsers();
```

### Connection Pooling
```javascript
const https = require('https');

class HTTPSAgent {
  constructor(options = {}) {
    this.agent = new https.Agent({
      keepAlive: true,
      keepAliveMsecs: 30000,
      maxSockets: 50,
      timeout: 30000,
      ...options
    });
  }
  
  getAgent() {
    return this.agent;
  }
  
  destroy() {
    this.agent.destroy();
  }
}

// Use with fetch
const httpsAgent = new HTTPSAgent();

const apiClient = {
  async makeRequest(url, options = {}) {
    return fetch(url, {
      ...options,
      agent: httpsAgent.getAgent()
    });
  }
};
```

## Monitoring & Debugging

### Request Logging
```javascript
class LoggingAPIClient {
  constructor(apiClient, logger) {
    this.api = apiClient;
    this.logger = logger;
  }
  
  logRequest(method, args, startTime) {
    const duration = Date.now() - startTime;
    this.logger.info('API Request', {
      method,
      args: JSON.stringify(args),
      duration,
      timestamp: new Date().toISOString()
    });
  }
  
  logError(method, args, error, startTime) {
    const duration = Date.now() - startTime;
    this.logger.error('API Request Failed', {
      method,
      args: JSON.stringify(args),
      error: error.message,
      stack: error.stack,
      duration,
      timestamp: new Date().toISOString()
    });
  }
  
  createProxy() {
    return new Proxy(this.api, {
      get: (target, prop) => {
        if (typeof target[prop] === 'function') {
          return async (...args) => {
            const startTime = Date.now();
            
            try {
              const result = await target[prop](...args);
              this.logRequest(prop, args, startTime);
              return result;
            } catch (error) {
              this.logError(prop, args, error, startTime);
              throw error;
            }
          };
        }
        
        return target[prop];
      }
    });
  }
}

// Usage
const logger = {
  info: (message, data) => console.log(`[INFO] ${message}`, data),
  error: (message, data) => console.error(`[ERROR] ${message}`, data)
};

const loggingAPI = new LoggingAPIClient(api, logger);
const proxiedAPI = loggingAPI.createProxy();

// All API calls will be logged
const users = await proxiedAPI.getUsers();
```

### Health Monitoring
```javascript
class APIHealthMonitor {
  constructor(apiClient, config = {}) {
    this.api = apiClient;
    this.config = {
      checkInterval: 60000, // 1 minute
      healthEndpoint: '/hollow',
      alertThreshold: 3,
      ...config
    };
    
    this.failureCount = 0;
    this.isHealthy = true;
    this.monitoring = false;
  }
  
  async checkHealth() {
    try {
      await this.api.healthCheck();
      
      if (this.failureCount > 0) {
        console.log('API health restored');
        this.failureCount = 0;
        this.isHealthy = true;
      }
      
      return true;
    } catch (error) {
      this.failureCount++;
      
      if (this.failureCount >= this.config.alertThreshold && this.isHealthy) {
        this.isHealthy = false;
        console.error(`API health check failed ${this.failureCount} times`, error);
        await this.onHealthAlert(error);
      }
      
      return false;
    }
  }
  
  async onHealthAlert(error) {
    // Send alert notification
    console.error('API health alert triggered', {
      failureCount: this.failureCount,
      error: error.message,
      timestamp: new Date().toISOString()
    });
    
    // Could send to monitoring service, email, Slack, etc.
  }
  
  startMonitoring() {
    if (this.monitoring) return;
    
    this.monitoring = true;
    this.monitoringInterval = setInterval(() => {
      this.checkHealth();
    }, this.config.checkInterval);
    
    console.log('API health monitoring started');
  }
  
  stopMonitoring() {
    if (this.monitoringInterval) {
      clearInterval(this.monitoringInterval);
      this.monitoring = false;
      console.log('API health monitoring stopped');
    }
  }
  
  getStatus() {
    return {
      isHealthy: this.isHealthy,
      failureCount: this.failureCount,
      monitoring: this.monitoring,
      lastCheck: new Date().toISOString()
    };
  }
}

// Usage
const healthMonitor = new APIHealthMonitor(api);
healthMonitor.startMonitoring();

// Check status
console.log('Health status:', healthMonitor.getStatus());
```

## Migration Guide

### Phase 1: Assessment and Setup (Week 1-2)
1. **API Audit**: Review current integration patterns
2. **Security Assessment**: Evaluate authentication requirements
3. **Performance Baseline**: Establish current performance metrics
4. **Testing Infrastructure**: Set up comprehensive testing suite

### Phase 2: Enhanced Client Libraries (Week 3-4)
1. **TypeScript SDK**: Create fully-typed client libraries
2. **Error Handling**: Implement comprehensive error handling
3. **Rate Limiting**: Add client-side rate limiting
4. **Caching**: Implement intelligent caching strategies

### Phase 3: Security and Monitoring (Week 5-6)
1. **Authentication**: Implement secure authentication patterns
2. **Request Signing**: Add request signing for sensitive operations
3. **Monitoring**: Add comprehensive logging and monitoring
4. **Health Checks**: Implement API health monitoring

### Phase 4: Optimization and Documentation (Week 7-8)
1. **Performance**: Optimize connection pooling and caching
2. **Documentation**: Create interactive API documentation
3. **Testing**: Implement comprehensive integration testing
4. **Training**: Provide team training on new SDK and patterns

### Expected Outcomes
- **30-50% reduction** in API integration complexity
- **Improved security** with proper authentication and monitoring
- **Better performance** with caching and connection pooling
- **Enhanced reliability** with comprehensive error handling and retries
- **Easier maintenance** with TypeScript definitions and testing