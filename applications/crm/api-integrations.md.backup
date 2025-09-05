# Distro Nation CRM API Integrations

## Overview
The Distro Nation CRM integrates with multiple APIs to provide comprehensive functionality for email campaigns, user management, content generation, and analytics. This document details all API integrations, authentication methods, usage patterns, and implementation specifics.

## AWS API Gateway Integration

### dn-api Core Integration
**Base URL**: `https://cjed05n28l.execute-api.us-east-1.amazonaws.com/staging`  
**Authentication**: API Key via `x-api-key` header  
**Configuration Location**: `src/config/api.config.ts`

```typescript
export const dnApiConfig = {
  apiKey: process.env.REACT_APP_DN_API_KEY,
  baseUrl: "https://cjed05n28l.execute-api.us-east-1.amazonaws.com/staging",
};

// SECURITY: Validate required environment variable
if (!dnApiConfig.apiKey) {
  throw new Error('REACT_APP_DN_API_KEY environment variable is required');
}
```

#### Primary Endpoints Used by CRM

##### `/dn_users_list` - User List Retrieval
**Method**: GET  
**Purpose**: Fetch recipient list for email campaigns  
**Used By**: `MailerTemplate.tsx` component  
**Implementation**:
```typescript
// Location: src/components/mailer/MailerTemplate.tsx:127-135
const response = await axios.get<EmailUser[]>(
  "https://cjed05n28l.execute-api.us-east-1.amazonaws.com/staging/dn_users_list",
  {
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': dnApiConfig.apiKey
    }
  }
);
```

**Response Format**:
```typescript
interface EmailUser {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  subscriptionStatus: string;
  preferences: object;
}
```

**Error Handling**:
- Network timeout: 30 seconds
- Retry mechanism: 3 attempts with exponential backoff
- Fallback: Local cached user list if available

##### `/send-mail` - Email Campaign Execution
**Method**: POST  
**Purpose**: Send email campaigns via Mailgun integration  
**Used By**: `emailService.ts` service  
**Implementation**:
```typescript
// Location: src/services/emailService.ts:66-77
const response = await axios.post(
  "https://cjed05n28l.execute-api.us-east-1.amazonaws.com/staging/send-mail",
  options,
  {
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': dnApiConfig.apiKey
    }
  }
);
```

**Request Payload**:
```typescript
interface SendMailRequest {
  to: string[];
  subject: string;
  html: string;
  text: string;
  from: string;
  replyTo?: string;
  attachments?: Attachment[];
  campaign: {
    name: string;
    type: 'financial' | 'newsletter';
    month?: string;
    year?: string;
  };
}
```

**Response Format**:
```typescript
interface SendMailResponse {
  success: boolean;
  messageId: string;
  recipientCount: number;
  estimatedDeliveryTime: string;
  campaign: {
    id: string;
    status: 'queued' | 'sending' | 'sent' | 'failed';
  };
}
```

### API Gateway Security Implementation
**CORS Configuration**: Configured to allow origins from CRM application domains  
**Rate Limiting**: 1000 requests per minute per API key  
**Authentication**: Custom Lambda authorizer validates API keys  
**Monitoring**: CloudWatch metrics for request/response tracking

## Firebase Integration

### Authentication Service
**Configuration Location**: `src/config/firebase.config.ts`  
**SDK Version**: Firebase 11.4.0  
**Services Used**: Authentication, Firestore, Cloud Functions

```typescript
// Firebase configuration
const firebaseConfig = {
  apiKey: process.env.REACT_APP_FIREBASE_API_KEY,
  authDomain: "distro-nation-crm.firebaseapp.com",
  projectId: "distro-nation-crm",
  storageBucket: "distro-nation-crm.appspot.com",
  messagingSenderId: process.env.REACT_APP_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.REACT_APP_FIREBASE_APP_ID
};
```

#### Authentication Implementation
**Primary Authentication Provider**: Firebase Auth  
**Supported Methods**: Email/Password, Google OAuth  
**Session Management**: JWT tokens with automatic refresh  
**Used By**: `AuthContext.tsx`, `Login.tsx`, `Register.tsx`

```typescript
// Authentication context implementation
export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  // Firebase auth state listener
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      setCurrentUser(user);
      setLoading(false);
    });
    return unsubscribe;
  }, []);
};
```

#### Firestore Database Integration
**Purpose**: Real-time data synchronization for campaigns and user preferences  
**Collections Used**:
- `campaigns`: Email campaign metadata and tracking
- `userPreferences`: User notification and email preferences
- `campaignAnalytics`: Real-time campaign performance metrics

**Implementation Example**:
```typescript
// Real-time campaign updates
const campaignRef = doc(db, 'campaigns', campaignId);
const unsubscribe = onSnapshot(campaignRef, (doc) => {
  if (doc.exists()) {
    setCampaignData(doc.data());
  }
});
```

### Cloud Functions Integration
**Purpose**: Server-side business logic and background processing  
**Functions Used by CRM**:
- `onCampaignCreate`: Triggered when new campaign is created
- `updateCampaignAnalytics`: Real-time analytics data processing
- `syncUserPreferences`: Synchronize preferences with Aurora database

## AWS Amplify Integration

### Cognito Integration
**Purpose**: Secondary authentication provider for admin features  
**Configuration**: `src/utils/amplify.ts`  
**Version**: AWS Amplify 6.13.2

```typescript
import { Amplify } from 'aws-amplify';

Amplify.configure({
  Auth: {
    Cognito: {
      userPoolId: process.env.REACT_APP_USER_POOL_ID,
      userPoolClientId: process.env.REACT_APP_USER_POOL_CLIENT_ID,
      region: 'us-east-1',
    }
  }
});
```

**Use Cases**:
- Administrative panel access
- Enhanced security for sensitive operations
- Multi-factor authentication for admin users

## Third-Party API Integrations

### Mailgun API Integration
**Purpose**: Email delivery service  
**Configuration Location**: `src/config/api.config.ts`  
**Implementation**: Via dn-api proxy for security

```typescript
export const mailgunConfig = {
  apiKey: process.env.REACT_APP_MAILGUN_API_KEY,
  domain: process.env.REACT_APP_MAILGUN_DOMAIN || "mg.distro-nation.com",
};

// SECURITY NOTE: API key must be provided via environment variables
// Application will fail to initialize if REACT_APP_MAILGUN_API_KEY is not set
if (!mailgunConfig.apiKey) {
  throw new Error('REACT_APP_MAILGUN_API_KEY environment variable is required');
}
```

**Features Used**:
- Email sending with HTML/text content
- Campaign tracking and analytics
- Delivery status webhooks
- Bounce and complaint handling

**Integration Pattern**:
```typescript
// Indirect integration via dn-api
const sendEmail = async (emailData: EmailRequest) => {
  // CRM -> dn-api -> Lambda -> Mailgun
  return await axios.post(`${dnApiConfig.baseUrl}/send-mail`, emailData);
};
```

### OpenAI API Integration
**Purpose**: AI-powered content generation and optimization  
**Configuration**: `src/services/openaiService.ts`  
**API Key**: Stored in environment variables

```typescript
export const openAIKey = process.env.REACT_APP_OPENAI_API_KEY;

// SECURITY: Validate required environment variable
if (!openAIKey) {
  throw new Error('REACT_APP_OPENAI_API_KEY environment variable is required');
}
```

**Features Implemented**:
- Email subject line generation
- Content suggestions and improvements
- Template creation assistance
- A/B testing content variants

**Usage Example**:
```typescript
const generateSubjectLine = async (emailContent: string) => {
  const response = await axios.post('https://api.openai.com/v1/completions', {
    model: 'gpt-3.5-turbo',
    prompt: `Generate an engaging email subject line for: ${emailContent}`,
    max_tokens: 50
  }, {
    headers: {
      'Authorization': `Bearer ${openAIKey}`,
      'Content-Type': 'application/json'
    }
  });
  return response.data.choices[0].text.trim();
};
```

### YouTube API Integration
**Purpose**: Content analytics and channel management  
**Configuration**: `src/config/api.config.ts`  
**Quota Management**: 10,000 units per day

```typescript
export const YOUTUBE_API_KEY = process.env.REACT_APP_YOUTUBE_API_KEY;

// SECURITY: Validate required environment variable
if (!YOUTUBE_API_KEY) {
  throw new Error('REACT_APP_YOUTUBE_API_KEY environment variable is required');
}
```

**Data Retrieved**:
- Channel subscriber counts
- Video performance metrics
- Content upload notifications
- Audience demographics

**Integration Points**:
- Dashboard analytics display
- Campaign targeting based on video performance
- Content calendar synchronization

### Spotify API Integration
**Purpose**: Music platform analytics and content synchronization  
**Authentication**: OAuth 2.0 Client Credentials flow  
**Configuration**: `src/config/api.config.ts`

```typescript
export const spotifyConfig = {
  clientId: process.env.REACT_APP_SPOTIFY_CLIENT_ID,
  clientSecret: process.env.REACT_APP_SPOTIFY_CLIENT_SECRET,
};

// SECURITY: Validate required environment variables
if (!spotifyConfig.clientId || !spotifyConfig.clientSecret) {
  throw new Error('REACT_APP_SPOTIFY_CLIENT_ID and REACT_APP_SPOTIFY_CLIENT_SECRET environment variables are required');
}
```

**Data Integration**:
- Artist streaming statistics
- Playlist placement tracking
- Release performance metrics
- Audience engagement data

**Authentication Flow**:
```typescript
const getSpotifyToken = async () => {
  const response = await axios.post('https://accounts.spotify.com/api/token', {
    grant_type: 'client_credentials'
  }, {
    headers: {
      'Authorization': `Basic ${btoa(`${spotifyConfig.clientId}:${spotifyConfig.clientSecret}`)}`,
      'Content-Type': 'application/x-www-form-urlencoded'
    }
  });
  return response.data.access_token;
};
```

### SimilarWeb API Integration
**Purpose**: Competitive intelligence and market analytics  
**Configuration**: `src/config/api.config.ts`  
**Rate Limits**: 100 requests per month

```typescript
export const similarwebConfig = {
  apiKey: process.env.REACT_APP_SIMILARWEB_API_KEY,
};

// SECURITY: Validate required environment variable
if (!similarwebConfig.apiKey) {
  throw new Error('REACT_APP_SIMILARWEB_API_KEY environment variable is required');
}
```

**Analytics Data**:
- Website traffic analysis
- Competitor performance metrics
- Market share insights
- User behavior patterns

## API Integration Patterns

### Authentication Pattern
**Multi-Provider Strategy**: Primary (Firebase) + Secondary (Cognito) + API Keys
```typescript
interface AuthConfig {
  firebase: FirebaseAuth;
  cognito: CognitoAuth;
  apiKeys: {
    dnApi: string;
    mailgun: string;
    openai: string;
    youtube: string;
    spotify: { clientId: string; clientSecret: string; };
    similarweb: string;
  };
}
```

### Error Handling Pattern
**Centralized Error Management**: Consistent error handling across all API integrations
```typescript
interface APIError {
  service: string;
  endpoint: string;
  status: number;
  message: string;
  timestamp: Date;
  retryable: boolean;
}

const handleAPIError = (error: any, service: string) => {
  const apiError: APIError = {
    service,
    endpoint: error.config?.url || 'unknown',
    status: error.response?.status || 0,
    message: error.message,
    timestamp: new Date(),
    retryable: error.response?.status >= 500
  };
  
  // Log error for monitoring
  console.error('API Error:', apiError);
  
  // Show user-friendly message
  toast.error(`${service} service temporarily unavailable`);
  
  return apiError;
};
```

### Rate Limiting Strategy
**Service-Specific Limits**: Each API integration respects individual rate limits
```typescript
const rateLimits = {
  dnApi: { requests: 1000, window: 60000 }, // 1000 per minute
  youtube: { requests: 100, window: 86400000 }, // 100 per day
  spotify: { requests: 100, window: 3600000 }, // 100 per hour
  similarweb: { requests: 100, window: 2592000000 }, // 100 per month
};
```

### Caching Strategy
**Multi-Level Caching**: API responses cached for performance optimization
```typescript
interface CacheConfig {
  localStorage: {
    userList: { ttl: 300000 }, // 5 minutes
    campaignTemplates: { ttl: 3600000 }, // 1 hour
  };
  sessionStorage: {
    authTokens: { ttl: 900000 }, // 15 minutes
    analyticsData: { ttl: 600000 }, // 10 minutes
  };
}
```

## Security Considerations

### API Key Management
- **Environment Variables Only**: All API keys MUST be stored in environment variables with NO fallback values
- **No Hardcoded Keys**: Never commit API keys, tokens, or secrets to version control
- **Key Rotation**: Regular rotation schedule for sensitive keys (quarterly minimum)
- **Access Control**: Role-based access to different API endpoints
- **Monitoring**: API key usage monitoring and alerting
- **Validation**: Application startup validation ensures all required API keys are present
- **Git History**: Regular scanning for accidentally committed secrets

### Data Protection
- **Encryption in Transit**: All API communications use HTTPS/TLS
- **Data Sanitization**: Input validation and sanitization for all API requests
- **Sensitive Data Handling**: PII data encrypted before API transmission
- **Audit Logging**: All API interactions logged for security auditing

### CORS Configuration
- **Allowed Origins**: Restricted to authorized CRM application domains
- **Allowed Methods**: Limited to required HTTP methods per endpoint
- **Credential Handling**: Secure credential transmission for authenticated requests

## Monitoring and Observability

### API Performance Monitoring
**Metrics Tracked**:
- Request/response times per API endpoint
- Success/failure rates by service
- Authentication failure rates
- Rate limit violations

**Alerting Thresholds**:
- Response time > 5 seconds
- Error rate > 5% over 5-minute window
- Authentication failures > 10 per minute
- API quota usage > 80%

### Health Checks
**Endpoint Health Monitoring**: Regular health checks for all integrated APIs
```typescript
const healthCheck = {
  dnApi: async () => {
    try {
      await axios.get(`${dnApiConfig.baseUrl}/health`);
      return { status: 'healthy', timestamp: new Date() };
    } catch (error) {
      return { status: 'unhealthy', error: error.message, timestamp: new Date() };
    }
  }
};
```

### Usage Analytics
**Integration Usage Tracking**:
- API call frequency by endpoint
- Feature usage patterns
- User behavior analytics
- Performance bottleneck identification

This comprehensive API integration documentation ensures all developers understand how the CRM application connects to and utilizes external services while maintaining security, performance, and reliability standards.