# Distro Nation CRM Data Flow Patterns

## Overview
This document details the comprehensive data flow patterns within the Distro Nation CRM application, including how data moves between components, external services, and the underlying infrastructure. Understanding these patterns is crucial for maintaining data consistency, optimizing performance, and ensuring reliable operation.

## Data Architecture Overview

### Data Sources and Destinations
The CRM application manages data flow between multiple sources:

```mermaid
graph TB
    subgraph "External APIs"
        Mailgun[Mailgun API]
        OpenAI[OpenAI API]
        YouTube[YouTube API]
        Spotify[Spotify API]
        SimilarWeb[SimilarWeb API]
    end
    
    subgraph "CRM Application"
        UI[React Components]
        State[Application State]
        Services[Service Layer]
        Cache[Local Cache]
    end
    
    subgraph "Backend Services"
        DNAPI[dn-api Gateway]
        Lambda[AWS Lambda]
        Aurora[Aurora PostgreSQL]
        Firebase[Firebase Services]
        S3[S3 Storage]
    end
    
    UI --> State
    State --> Services
    Services --> Cache
    Services --> DNAPI
    Services --> Firebase
    Services --> External APIs
    DNAPI --> Lambda
    Lambda --> Aurora
    Lambda --> S3
```

### Data Types and Categories
The CRM handles several categories of data:

1. **User Data**: Authentication, profiles, preferences, and permissions
2. **Campaign Data**: Email campaigns, templates, and performance metrics
3. **Analytics Data**: Performance metrics, user engagement, and business intelligence
4. **Configuration Data**: Application settings, feature flags, and system configuration
5. **Operational Data**: Logs, monitoring metrics, and system health data

## Core Data Flow Patterns

### 1. Email Campaign Creation and Execution Flow

#### Campaign Creation Data Flow
```mermaid
sequenceDiagram
    participant Admin as CRM Admin
    participant MT as MailerTemplate
    participant API as dn-api
    participant Lambda as AWS Lambda
    participant Aurora as Aurora DB
    participant Mailgun as Mailgun Service
    participant Firebase as Firebase

    Admin->>MT: Create new campaign
    MT->>API: GET /dn_users_list
    API->>Lambda: Invoke user list function
    Lambda->>Aurora: Query user table
    Aurora->>Lambda: Return user data
    Lambda->>API: Return formatted user list
    API->>MT: User list response
    MT->>Admin: Display recipient selection
    Admin->>MT: Configure campaign details
    MT->>API: POST /send-mail
    API->>Lambda: Invoke email campaign function
    Lambda->>Aurora: Store campaign metadata
    Lambda->>Mailgun: Send email batch
    Lambda->>Firebase: Update real-time campaign status
    Mailgun->>Lambda: Delivery webhooks
    Lambda->>Aurora: Update delivery status
    Lambda->>Firebase: Real-time status updates
    Firebase->>MT: Live campaign analytics
```

**Implementation Details**:
```typescript
// src/components/mailer/MailerTemplate.tsx
const MailerTemplate: React.FC = () => {
  const [formData, setFormData] = useState<NewsletterFormData>({
    email: "",
    user: null,
    content: "",
    subject: "",
    emailList: [],
```

### 2. YouTube Channel Search Flow

#### Overview
This flow describes how the CRM application integrates with the YouTube Data API v3 to enable users to search for YouTube channels, view their details, and add them to outreach categories. The process involves several client-side components and services, robust caching, and error handling.

#### Data Flow Diagram
```mermaid
%% This diagram is generated from /applications/crm/diagrams/youtube-search-sequence.mmd
sequenceDiagram
    participant User
    participant YouTubeSearchModal
    participant useYouTubeSearch
    participant youtubeSearch
    participant youtubeAuth
    participant YouTubeAPI as YouTube Data API v3
    
    User->>YouTubeSearchModal: Opens search modal
    YouTubeSearchModal->>useYouTubeSearch: Initialize hook
    useYouTubeSearch->>useYouTubeSearch: Load cached state from sessionStorage
    
    User->>YouTubeSearchModal: Enters search query
    User->>YouTubeSearchModal: Selects sort order (relevance/viewCount/title)
    User->>YouTubeSearchModal: Clicks search
    
    YouTubeSearchModal->>useYouTubeSearch: performSearch()
    useYouTubeSearch->>youtubeAuth: getYouTubeAccessToken()
    
    alt Token is cached and valid
        youtubeAuth-->>useYouTubeSearch: Return cached token
    else Token expired or missing
        youtubeAuth->>YouTubeAPI: Request new access token
        YouTubeAPI-->>youtubeAuth: Return access token + expiry
        youtubeAuth->>youtubeAuth: Cache token with expiry
        youtubeAuth-->>useYouTubeSearch: Return new token
    end
    
    useYouTubeSearch->>youtubeSearch: searchYouTubeChannels(params)
    youtubeSearch->>YouTubeAPI: GET /youtube/v3/search<br/>?part=snippet&type=channel&q={query}&order={order}
    
    alt Success (200)
        YouTubeAPI-->>youtubeSearch: Return search results with channel IDs
        youtubeSearch->>YouTubeAPI: GET /youtube/v3/channels<br/>?part=snippet,statistics&id={channelIds}
        YouTubeAPI-->>youtubeSearch: Return channel statistics
        youtubeSearch->>youtubeSearch: Map and merge data
        youtubeSearch->>youtubeSearch: Filter out Topic channels
        youtubeSearch-->>useYouTubeSearch: Return YouTubeSearchResponse
    else 401/403 (Auth error)
        YouTubeAPI-->>youtubeSearch: Auth error
        youtubeSearch->>youtubeAuth: clearCachedYouTubeToken()
        youtubeSearch->>youtubeAuth: getYouTubeAccessToken()
        youtubeSearch->>YouTubeAPI: Retry request with new token
    else 429 (Rate limit)
        YouTubeAPI-->>youtubeSearch: Rate limit error
        youtubeSearch->>youtubeSearch: Exponential backoff retry (3 attempts)
    else Other error
        YouTubeAPI-->>youtubeSearch: Error response
        youtubeSearch-->>useYouTubeSearch: Throw error with message
    end
    
    useYouTubeSearch->>useYouTubeSearch: Cache results by query/sort/page
    useYouTubeSearch->>useYouTubeSearch: Save state to sessionStorage
    useYouTubeSearch-->>YouTubeSearchModal: Update searchResults state
    
    YouTubeSearchModal->>YouTubeSearchResults: Render results in DataGrid
    YouTubeSearchResults-->>User: Display channel list
    
    User->>YouTubeSearchResults: Clicks on channel row
    YouTubeSearchResults->>YouTubeSearchModal: onChannelSelect(channelId)
    YouTubeSearchModal->>useYouTubeSearch: fetchChannelDetails(channelId)
    
    useYouTubeSearch->>youtubeSearch: getChannelDetailsById(channelId)
    youtubeSearch->>YouTubeAPI: GET /youtube/v3/channels<br/>?part=snippet,contentDetails,statistics&id={channelId}
    YouTubeAPI-->>youtubeSearch: Return full channel details
    youtubeSearch->>youtubeSearch: Extract email from description (regex)
    youtubeSearch-->>useYouTubeSearch: Return YouTubeChannelSearchDetails
    
    useYouTubeSearch-->>YouTubeSearchModal: Update selectedChannel state
    YouTubeSearchModal->>YouTubeChannelDetail: Render channel details
    YouTubeChannelDetail-->>User: Display full channel info
    
    User->>YouTubeChannelDetail: Clicks "Add to [Category]"
    YouTubeChannelDetail->>YouTubeSearchModal: onAddToCategory(category)
    YouTubeSearchModal->>ChannelConfirmationModal: Open with channel data
    User->>ChannelConfirmationModal: Reviews and confirms
    ChannelConfirmationModal->>YouTubeSearchModal: onConfirm(formValues)
    YouTubeSearchModal->>Firestore: addOutreachItem()
    Firestore-->>YouTubeSearchModal: Success
    YouTubeSearchModal-->>User: Show success notification
    YouTubeSearchModal->>YouTubeSearchModal: onChannelAdded() callback
```

#### Key Components and Data Flow

**1. `YouTubeSearchModal.tsx`**: The main UI component that orchestrates the YouTube search experience. It handles user input, displays search results, and manages the selection of channels.

**2. `useYouTubeSearch.ts`**: A custom React hook that encapsulates the core search logic, state management, and caching. It interacts with the `youtubeSearch` service and `sessionStorage` for persistence.

**3. `youtubeSearch.ts`**: The service layer module responsible for making direct calls to the YouTube Data API v3. It handles API request parameters, response parsing, error handling (including retries and token refresh), and post-processing like filtering out Topic channels and extracting emails.

**4. `youtubeAuth.ts`**: Manages the authentication process for the YouTube API. It interacts with an internal token service to acquire OAuth 2.0 access tokens, which are then cached in-memory with automatic refresh mechanisms.

**5. YouTube Data API v3**: The external API providing search functionality and detailed channel information. The CRM utilizes two main endpoints:
   - `GET /youtube/v3/search`: For initial channel discovery based on query.
   - `GET /youtube/v3/channels`: For fetching detailed statistics and metadata for specific channels, or comprehensive details for a single channel.

**6. `sessionStorage`**: Used by `useYouTubeSearch` to persist search state (query, results, pagination tokens, sort order) across page refreshes, enhancing user experience.

**7. Firebase Firestore**: Once a channel is confirmed by the user, its details are saved as an outreach item in Firestore via `firestore/crud.ts`.

**Error Handling and Retries**:
- The `youtubeSearch.ts` service implements robust error handling for YouTube API responses, including automatic token refresh on `401`/`403` errors and exponential backoff for `429` (rate limit) errors.
- The `useYouTubeSearch` hook provides user-friendly error messages and a retry mechanism.

For detailed information on API endpoints and authentication, refer to [API Integrations](./api-integrations.md#youtube-data-api-v3-integration).
For a catalog of related UI components and their props, see [Component Catalog](./component-catalog.md#youtubesearchmodal.tsx).
    sendAll: false,
    testing: false,
    emailType: "financial",
  });

  // Data flow: API → Component State → UI
  useEffect(() => {
    const fetchUserList = async () => {
      try {
        setEmailListLoading(true);
        
        // Fetch user data from dn-api
        const response = await axios.get<EmailUser[]>(
          `${dnApiConfig.baseUrl}/dn_users_list`,
          {
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': dnApiConfig.apiKey
            }
          }
        );
        
        // Update component state
        setFormData(prev => ({
          ...prev,
          emailList: response.data
        }));
        
      } catch (error) {
        console.error('Failed to fetch user list:', error);
        toast.error('Failed to load user list');
      } finally {
        setEmailListLoading(false);
      }
    };

    fetchUserList();
  }, []);

  // Data flow: Component State → API → Backend Services
  const handleSendEmail = async () => {
    try {
      setLoading(true);
      
      const campaignData = {
        to: formData.sendAll 
          ? formData.emailList.map(user => user.email)
          : [formData.user?.email].filter(Boolean),
        subject: formData.subject,
        html: formData.content,
        text: formData.content.replace(/<[^>]*>/g, ''),
        from: 'noreply@distro-nation.com',
        campaign: {
          name: `${formData.emailType}-${formData.month}-${formData.year}`,
          type: formData.emailType,
          month: formData.month,
          year: formData.year,
        }
      };
      
      // Send campaign data to backend
      const response = await sendEmail(campaignData);
      
      // Handle response and update UI
      if (response.success) {
        toast.success(`Campaign sent to ${response.recipientCount} recipients`);
        navigate('/confirmation', { 
          state: { 
            campaignId: response.campaign.id,
            recipientCount: response.recipientCount 
          } 
        });
      }
      
    } catch (error) {
      handleEmailError(error);
    } finally {
      setLoading(false);
    }
  };
};
```

### 2. User Management Data Flow

#### User List Retrieval and Caching
```mermaid
sequenceDiagram
    participant CRM as CRM Component
    participant Cache as Local Cache
    participant API as dn-api
    participant Lambda as User Service Lambda
    participant Aurora as Aurora DB

    CRM->>Cache: Check cached user list
    alt Cache Hit
        Cache->>CRM: Return cached data
    else Cache Miss
        CRM->>API: GET /dn_users_list?filter=active
        API->>Lambda: Invoke with filters
        Lambda->>Aurora: SELECT users WHERE status='active'
        Aurora->>Lambda: Return user records
        Lambda->>Lambda: Apply business logic & formatting
        Lambda->>API: Return formatted user list
        API->>CRM: User list response
        CRM->>Cache: Store in cache (TTL: 5min)
    end
    CRM->>CRM: Update component state
```

**Caching Strategy Implementation**:
```typescript
// src/hooks/useUserList.ts
export const useUserList = (filters?: UserFilters) => {
  const [users, setUsers] = useState<EmailUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Cache key generation based on filters
  const cacheKey = useMemo(() => 
    `user-list-${JSON.stringify(filters || {})}`, 
    [filters]
  );

  const fetchUsers = useCallback(async () => {
    try {
      // Check cache first
      const cachedData = localStorage.getItem(cacheKey);
      const cacheTimestamp = localStorage.getItem(`${cacheKey}-timestamp`);
      const cacheExpiry = 5 * 60 * 1000; // 5 minutes

      if (cachedData && cacheTimestamp) {
        const age = Date.now() - parseInt(cacheTimestamp);
        if (age < cacheExpiry) {
          setUsers(JSON.parse(cachedData));
          setLoading(false);
          return;
        }
      }

      // Fetch from API if cache miss or expired
      setLoading(true);
      const queryParams = new URLSearchParams();
      
      if (filters?.subscriptionStatus) {
        queryParams.append('subscriptionStatus', filters.subscriptionStatus);
      }
      if (filters?.emailType) {
        queryParams.append('emailType', filters.emailType);
      }
      if (filters?.limit) {
        queryParams.append('limit', filters.limit.toString());
      }

      const response = await axios.get<UserListResponse>(
        `${dnApiConfig.baseUrl}/dn_users_list?${queryParams}`,
        {
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': dnApiConfig.apiKey
          }
        }
      );

      // Update cache
      localStorage.setItem(cacheKey, JSON.stringify(response.data.users));
      localStorage.setItem(`${cacheKey}-timestamp`, Date.now().toString());

      setUsers(response.data.users);
      setError(null);

    } catch (err) {
      setError('Failed to fetch user list');
      console.error('User list fetch error:', err);
    } finally {
      setLoading(false);
    }
  }, [cacheKey, filters]);

  useEffect(() => {
    fetchUsers();
  }, [fetchUsers]);

  // Cache invalidation
  const invalidateCache = useCallback(() => {
    localStorage.removeItem(cacheKey);
    localStorage.removeItem(`${cacheKey}-timestamp`);
    fetchUsers();
  }, [cacheKey, fetchUsers]);

  return { users, loading, error, refetch: fetchUsers, invalidateCache };
};
```

### 3. Real-time Analytics Data Flow

#### Campaign Performance Tracking
```mermaid
sequenceDiagram
    participant Mailgun as Mailgun Webhooks
    participant Lambda as Analytics Lambda
    participant Aurora as Aurora DB
    participant Firebase as Firebase Realtime
    participant CRM as CRM Dashboard

    Mailgun->>Lambda: Email delivered webhook
    Lambda->>Aurora: UPDATE campaign_stats SET delivered = delivered + 1
    Lambda->>Firebase: Update real-time campaign data
    Firebase->>CRM: Real-time update event
    CRM->>CRM: Update dashboard metrics

    Mailgun->>Lambda: Email opened webhook
    Lambda->>Aurora: UPDATE campaign_stats SET opened = opened + 1
    Lambda->>Firebase: Update real-time analytics
    Firebase->>CRM: Live metrics update

    Mailgun->>Lambda: Link clicked webhook
    Lambda->>Aurora: INSERT INTO click_events
    Lambda->>Firebase: Update click tracking data
    Firebase->>CRM: Real-time engagement update
```

**Real-time Analytics Implementation**:
```typescript
// src/hooks/useRealTimeAnalytics.ts
export const useRealTimeAnalytics = (campaignId: string) => {
  const [analytics, setAnalytics] = useState<CampaignAnalytics | null>(null);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    if (!campaignId) return;

    // Subscribe to real-time updates via Firebase
    const analyticsRef = doc(db, 'campaignAnalytics', campaignId);
    
    const unsubscribe = onSnapshot(analyticsRef, (doc) => {
      if (doc.exists()) {
        const data = doc.data() as CampaignAnalytics;
        setAnalytics(data);
        setIsConnected(true);
        
        // Trigger UI updates with smooth animations
        triggerAnalyticsAnimation(data);
      }
    }, (error) => {
      console.error('Real-time analytics error:', error);
      setIsConnected(false);
    });

    return () => unsubscribe();
  }, [campaignId]);

  return { analytics, isConnected };
};

// src/components/analytics/AnalyticsDashboard.tsx
const AnalyticsDashboard: React.FC<{ campaignId: string }> = ({ campaignId }) => {
  const { analytics, isConnected } = useRealTimeAnalytics(campaignId);
  const [previousValues, setPreviousValues] = useState<CampaignAnalytics | null>(null);

  // Detect changes for animations
  useEffect(() => {
    if (analytics && previousValues) {
      const changes = detectAnalyticsChanges(previousValues, analytics);
      if (changes.length > 0) {
        animateMetricChanges(changes);
      }
    }
    setPreviousValues(analytics);
  }, [analytics, previousValues]);

  const detectAnalyticsChanges = (
    prev: CampaignAnalytics, 
    current: CampaignAnalytics
  ): MetricChange[] => {
    const changes: MetricChange[] = [];
    
    if (prev.delivered !== current.delivered) {
      changes.push({ metric: 'delivered', from: prev.delivered, to: current.delivered });
    }
    if (prev.opened !== current.opened) {
      changes.push({ metric: 'opened', from: prev.opened, to: current.opened });
    }
    if (prev.clicked !== current.clicked) {
      changes.push({ metric: 'clicked', from: prev.clicked, to: current.clicked });
    }
    
    return changes;
  };

  return (
    <Grid container spacing={3}>
      <Grid item xs={12} md={3}>
        <MetricCard
          title="Delivered"
          value={analytics?.delivered || 0}
          trend={calculateTrend(analytics?.delivered, previousValues?.delivered)}
          color="success"
          isLive={isConnected}
        />
      </Grid>
      <Grid item xs={12} md={3}>
        <MetricCard
          title="Opened"
          value={analytics?.opened || 0}
          trend={calculateTrend(analytics?.opened, previousValues?.opened)}
          color="info"
          isLive={isConnected}
        />
      </Grid>
      <Grid item xs={12} md={3}>
        <MetricCard
          title="Clicked"
          value={analytics?.clicked || 0}
          trend={calculateTrend(analytics?.clicked, previousValues?.clicked)}
          color="warning"
          isLive={isConnected}
        />
      </Grid>
      <Grid item xs={12} md={3}>
        <MetricCard
          title="Open Rate"
          value={analytics ? ((analytics.opened / analytics.delivered) * 100).toFixed(1) + '%' : '0%'}
          color="primary"
          isLive={isConnected}
        />
      </Grid>
    </Grid>
  );
};
```

### 4. Outreach Campaign Data Management

#### Campaign Lifecycle Data Flow
```mermaid
graph TD
    A[Campaign Creation] --> B[Draft Storage]
    B --> C[Campaign Configuration]
    C --> D[Recipient List Building]
    D --> E[Content Creation]
    E --> F[Preview & Testing]
    F --> G[Campaign Launch]
    G --> H[Real-time Tracking]
    H --> I[Performance Analysis]
    I --> J[Campaign Archive]
    
    subgraph "Data Storage"
        Firebase[(Firebase)]
        Aurora[(Aurora)]
        LocalStorage[(Local Storage)]
    end
    
    B --> LocalStorage
    C --> Firebase
    D --> Aurora
    E --> LocalStorage
    G --> Aurora
    H --> Firebase
    I --> Aurora
    J --> Aurora
```

**Campaign State Management**:
```typescript
// src/hooks/useOutreachData.ts
export const useOutreachData = () => {
  const [campaigns, setCampaigns] = useState<OutreachCampaign[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Create campaign with optimistic updates
  const createCampaign = async (campaignData: CreateCampaignRequest): Promise<OutreachCampaign> => {
    const tempId = `temp-${Date.now()}`;
    const optimisticCampaign: OutreachCampaign = {
      id: tempId,
      ...campaignData,
      status: 'draft',
      createdAt: new Date(),
      updatedAt: new Date(),
      metrics: {
        sent: 0,
        delivered: 0,
        opened: 0,
        clicked: 0,
        bounced: 0,
        unsubscribed: 0
      }
    };

    // Optimistic update
    setCampaigns(prev => [optimisticCampaign, ...prev]);

    try {
      // Create in Firebase for real-time collaboration
      const campaignRef = doc(db, 'campaigns', tempId);
      await setDoc(campaignRef, optimisticCampaign);

      // Create in Aurora for persistent storage
      const response = await axios.post<OutreachCampaign>(
        `${dnApiConfig.baseUrl}/campaigns`,
        campaignData,
        {
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': dnApiConfig.apiKey
          }
        }
      );

      // Update with real ID and data
      const realCampaign = response.data;
      setCampaigns(prev => 
        prev.map(campaign => 
          campaign.id === tempId ? realCampaign : campaign
        )
      );

      return realCampaign;

    } catch (error) {
      // Rollback optimistic update
      setCampaigns(prev => prev.filter(campaign => campaign.id !== tempId));
      throw error;
    }
  };

  // Update campaign with conflict resolution
  const updateCampaign = async (
    campaignId: string, 
    updates: Partial<OutreachCampaign>
  ): Promise<OutreachCampaign> => {
    try {
      // Check for concurrent modifications
      const campaignRef = doc(db, 'campaigns', campaignId);
      const currentDoc = await getDoc(campaignRef);
      
      if (!currentDoc.exists()) {
        throw new Error('Campaign not found');
      }

      const currentData = currentDoc.data() as OutreachCampaign;
      const lastModified = new Date(updates.updatedAt || 0);
      const currentModified = new Date(currentData.updatedAt);

      // Conflict detection
      if (lastModified < currentModified) {
        throw new Error('Campaign has been modified by another user');
      }

      const updatedCampaign = {
        ...currentData,
        ...updates,
        updatedAt: new Date()
      };

      // Update in Firebase
      await updateDoc(campaignRef, updatedCampaign);

      // Update in Aurora
      await axios.put(
        `${dnApiConfig.baseUrl}/campaigns/${campaignId}`,
        updatedCampaign,
        {
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': dnApiConfig.apiKey
          }
        }
      );

      // Update local state
      setCampaigns(prev => 
        prev.map(campaign => 
          campaign.id === campaignId ? updatedCampaign : campaign
        )
      );

      return updatedCampaign;

    } catch (error) {
      console.error('Campaign update failed:', error);
      throw error;
    }
  };

  return {
    campaigns,
    loading,
    error,
    createCampaign,
    updateCampaign,
    deleteCampaign,
    launchCampaign
  };
};
```

### 5. Third-Party API Integration Data Patterns

#### AI Content Generation Flow
```mermaid
sequenceDiagram
    participant User as CRM User
    participant CRM as CRM Interface
    participant OpenAI as OpenAI API
    participant Cache as Content Cache
    participant Firebase as Firebase Storage

    User->>CRM: Request content generation
    CRM->>Cache: Check for cached similar content
    alt Cache Hit
        Cache->>CRM: Return cached content
    else Cache Miss
        CRM->>OpenAI: Generate content request
        OpenAI->>CRM: Generated content response
        CRM->>Cache: Store generated content
        CRM->>Firebase: Store content with metadata
    end
    CRM->>User: Display generated content
    User->>CRM: Accept/Edit content
    CRM->>Firebase: Save final content version
```

**AI Content Generation Implementation**:
```typescript
// src/services/openaiService.ts
class OpenAIService {
  private cache = new Map<string, CachedContent>();
  private readonly CACHE_DURATION = 24 * 60 * 60 * 1000; // 24 hours

  async generateEmailContent(prompt: ContentPrompt): Promise<GeneratedContent> {
    const cacheKey = this.generateCacheKey(prompt);
    
    // Check cache first
    const cached = this.cache.get(cacheKey);
    if (cached && (Date.now() - cached.timestamp) < this.CACHE_DURATION) {
      return cached.content;
    }

    try {
      const response = await axios.post(
        'https://api.openai.com/v1/chat/completions',
        {
          model: 'gpt-3.5-turbo',
          messages: [
            {
              role: 'system',
              content: 'You are an email marketing expert creating engaging content for music industry professionals.'
            },
            {
              role: 'user',
              content: this.buildPrompt(prompt)
            }
          ],
          max_tokens: 1000,
          temperature: 0.7
        },
        {
          headers: {
            'Authorization': `Bearer ${openAIKey}`,
            'Content-Type': 'application/json'
          }
        }
      );

      const generatedContent: GeneratedContent = {
        subject: this.extractSubject(response.data.choices[0].message.content),
        body: this.extractBody(response.data.choices[0].message.content),
        metadata: {
          model: 'gpt-3.5-turbo',
          promptType: prompt.type,
          generatedAt: new Date(),
          tokens: response.data.usage.total_tokens
        }
      };

      // Cache the result
      this.cache.set(cacheKey, {
        content: generatedContent,
        timestamp: Date.now()
      });

      // Store in Firebase for team sharing
      await this.storeGeneratedContent(generatedContent, prompt);

      return generatedContent;

    } catch (error) {
      console.error('OpenAI content generation failed:', error);
      throw new Error('Failed to generate content');
    }
  }

  private async storeGeneratedContent(
    content: GeneratedContent, 
    prompt: ContentPrompt
  ): Promise<void> {
    try {
      const contentRef = doc(db, 'generatedContent', `${Date.now()}`);
      await setDoc(contentRef, {
        ...content,
        originalPrompt: prompt,
        usage: {
          usedCount: 0,
          lastUsed: null
        },
        sharing: {
          isPublic: false,
          sharedWith: []
        }
      });
    } catch (error) {
      console.warn('Failed to store generated content:', error);
    }
  }

  private generateCacheKey(prompt: ContentPrompt): string {
    return btoa(JSON.stringify({
      type: prompt.type,
      audience: prompt.audience,
      tone: prompt.tone,
      keyPoints: prompt.keyPoints?.sort()
    }));
  }
}
```

### 6. Analytics and Reporting Data Aggregation

#### Multi-Source Analytics Integration
```mermaid
graph TB
    subgraph "Data Sources"
        Mailgun[Mailgun Metrics]
        YouTube[YouTube Analytics]
        Spotify[Spotify Data]
        Firebase[Firebase Events]
        Aurora[Campaign Data]
    end
    
    subgraph "Data Processing"
        ETL[ETL Pipeline]
        Aggregator[Data Aggregator]
        Calculator[Metrics Calculator]
    end
    
    subgraph "Storage & Cache"
        AnalyticsDB[(Analytics Tables)]
        RedisCache[(Redis Cache)]
        LocalCache[Local Cache]
    end
    
    subgraph "CRM Interface"
        Dashboard[Analytics Dashboard]
        Reports[Custom Reports]
        Exports[Data Exports]
    end
    
    Mailgun --> ETL
    YouTube --> ETL
    Spotify --> ETL
    Firebase --> ETL
    Aurora --> ETL
    
    ETL --> Aggregator
    Aggregator --> Calculator
    Calculator --> AnalyticsDB
    Calculator --> RedisCache
    
    AnalyticsDB --> Dashboard
    RedisCache --> Dashboard
    Dashboard --> LocalCache
    Dashboard --> Reports
    Reports --> Exports
```

**Analytics Data Aggregation Service**:
```typescript
// src/services/analyticsService.ts
class AnalyticsService {
  private aggregationCache = new Map<string, AggregatedData>();
  private refreshIntervals = new Map<string, NodeJS.Timeout>();

  async getAggregatedAnalytics(
    timeRange: TimeRange,
    metrics: string[],
    filters?: AnalyticsFilters
  ): Promise<AggregatedAnalytics> {
    const cacheKey = this.buildCacheKey(timeRange, metrics, filters);
    
    // Return cached data if available and fresh
    if (this.aggregationCache.has(cacheKey)) {
      const cached = this.aggregationCache.get(cacheKey)!;
      if (Date.now() - cached.timestamp < 300000) { // 5 minutes
        return cached.data;
      }
    }

    try {
      // Fetch data from multiple sources in parallel
      const [
        emailMetrics,
        youtubeData,
        spotifyData,
        engagementData
      ] = await Promise.allSettled([
        this.fetchEmailMetrics(timeRange, filters),
        this.fetchYouTubeAnalytics(timeRange, filters),
        this.fetchSpotifyData(timeRange, filters),
        this.fetchEngagementData(timeRange, filters)
      ]);

      // Process and aggregate data
      const aggregatedData = this.aggregateMultiSourceData({
        email: emailMetrics.status === 'fulfilled' ? emailMetrics.value : null,
        youtube: youtubeData.status === 'fulfilled' ? youtubeData.value : null,
        spotify: spotifyData.status === 'fulfilled' ? spotifyData.value : null,
        engagement: engagementData.status === 'fulfilled' ? engagementData.value : null
      });

      // Calculate derived metrics
      const calculatedMetrics = this.calculateDerivedMetrics(aggregatedData);

      const result: AggregatedAnalytics = {
        ...aggregatedData,
        ...calculatedMetrics,
        metadata: {
          generatedAt: new Date(),
          dataFreshness: this.calculateDataFreshness(aggregatedData),
          completeness: this.calculateDataCompleteness(aggregatedData)
        }
      };

      // Cache the result
      this.aggregationCache.set(cacheKey, {
        data: result,
        timestamp: Date.now()
      });

      return result;

    } catch (error) {
      console.error('Analytics aggregation failed:', error);
      throw new Error('Failed to aggregate analytics data');
    }
  }

  private async fetchEmailMetrics(
    timeRange: TimeRange, 
    filters?: AnalyticsFilters
  ): Promise<EmailMetrics> {
    const response = await axios.get(
      `${dnApiConfig.baseUrl}/analytics/email`,
      {
        params: {
          startDate: timeRange.start.toISOString(),
          endDate: timeRange.end.toISOString(),
          ...filters
        },
        headers: {
          'x-api-key': dnApiConfig.apiKey
        }
      }
    );

    return response.data;
  }

  private aggregateMultiSourceData(sources: MultiSourceData): BaseAnalytics {
    return {
      totalCampaigns: sources.email?.totalCampaigns || 0,
      totalRecipients: sources.email?.totalRecipients || 0,
      deliveryRate: sources.email?.deliveryRate || 0,
      openRate: sources.email?.openRate || 0,
      clickRate: sources.email?.clickRate || 0,
      youtubeViews: sources.youtube?.totalViews || 0,
      spotifyStreams: sources.spotify?.totalStreams || 0,
      engagementScore: sources.engagement?.averageScore || 0
    };
  }

  private calculateDerivedMetrics(baseData: BaseAnalytics): DerivedMetrics {
    return {
      engagementTrend: this.calculateEngagementTrend(baseData),
      campaignEffectiveness: this.calculateCampaignEffectiveness(baseData),
      audienceGrowth: this.calculateAudienceGrowth(baseData),
      conversionFunnel: this.calculateConversionFunnel(baseData)
    };
  }

  // Real-time analytics updates
  setupRealTimeUpdates(callback: (update: AnalyticsUpdate) => void): () => void {
    const analyticsRef = collection(db, 'analyticsUpdates');
    const query = orderBy(analyticsRef, 'timestamp', 'desc');
    
    const unsubscribe = onSnapshot(query, (snapshot) => {
      snapshot.docChanges().forEach((change) => {
        if (change.type === 'added') {
          const update = change.doc.data() as AnalyticsUpdate;
          callback(update);
          
          // Invalidate relevant caches
          this.invalidateCache(update.affectedMetrics);
        }
      });
    });

    return unsubscribe;
  }
}
```

## Data Persistence Strategies

### 1. Multi-Tier Caching Architecture

#### Caching Layer Implementation
```typescript
// src/utils/cacheManager.ts
class CacheManager {
  // Layer 1: Memory cache (fastest, smallest)
  private memoryCache = new Map<string, CachedItem>();
  
  // Layer 2: Session storage (medium speed, session-scoped)
  private sessionCache = window.sessionStorage;
  
  // Layer 3: Local storage (slower, persistent)
  private localStorage = window.localStorage;

  async get<T>(key: string): Promise<T | null> {
    // Check memory cache first
    const memoryItem = this.memoryCache.get(key);
    if (memoryItem && !this.isExpired(memoryItem)) {
      return memoryItem.data as T;
    }

    // Check session storage
    const sessionItem = this.getFromStorage(this.sessionCache, key);
    if (sessionItem && !this.isExpired(sessionItem)) {
      // Promote to memory cache
      this.memoryCache.set(key, sessionItem);
      return sessionItem.data as T;
    }

    // Check local storage
    const localItem = this.getFromStorage(this.localStorage, key);
    if (localItem && !this.isExpired(localItem)) {
      // Promote to session cache
      this.setToStorage(this.sessionCache, key, localItem);
      return localItem.data as T;
    }

    return null;
  }

  async set<T>(
    key: string, 
    data: T, 
    options: CacheOptions = {}
  ): Promise<void> {
    const item: CachedItem = {
      data,
      timestamp: Date.now(),
      ttl: options.ttl || 300000, // 5 minutes default
      tags: options.tags || []
    };

    // Store in appropriate layers based on options
    if (options.memory !== false) {
      this.memoryCache.set(key, item);
    }

    if (options.session !== false) {
      this.setToStorage(this.sessionCache, key, item);
    }

    if (options.persistent) {
      this.setToStorage(this.localStorage, key, item);
    }
  }

  invalidateByTag(tag: string): void {
    // Invalidate memory cache
    for (const [key, item] of this.memoryCache.entries()) {
      if (item.tags.includes(tag)) {
        this.memoryCache.delete(key);
      }
    }

    // Invalidate storage caches
    this.invalidateStorageByTag(this.sessionCache, tag);
    this.invalidateStorageByTag(this.localStorage, tag);
  }

  // Cleanup expired items
  cleanup(): void {
    const now = Date.now();
    
    for (const [key, item] of this.memoryCache.entries()) {
      if (this.isExpired(item)) {
        this.memoryCache.delete(key);
      }
    }
  }

  private isExpired(item: CachedItem): boolean {
    return Date.now() - item.timestamp > item.ttl;
  }
}

// Usage in hooks
export const useCachedData = <T>(
  key: string,
  fetcher: () => Promise<T>,
  options: CacheOptions = {}
) => {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const cacheManager = useMemo(() => new CacheManager(), []);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      
      // Try cache first
      const cached = await cacheManager.get<T>(key);
      if (cached) {
        setData(cached);
        setLoading(false);
        return;
      }

      // Fetch fresh data
      const freshData = await fetcher();
      
      // Cache the result
      await cacheManager.set(key, freshData, options);
      
      setData(freshData);
      setError(null);
    } catch (err) {
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  }, [key, fetcher, options, cacheManager]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return { data, loading, error, refetch: fetchData };
};
```

### 2. Offline Data Synchronization

#### Offline-First Data Pattern
```typescript
// src/utils/offlineSync.ts
class OfflineSyncManager {
  private pendingOperations: PendingOperation[] = [];
  private syncQueue = new Queue<SyncOperation>();

  constructor() {
    this.setupOnlineListener();
    this.setupPeriodicSync();
  }

  // Queue operations for later sync
  async queueOperation(operation: DataOperation): Promise<void> {
    const pendingOp: PendingOperation = {
      id: generateId(),
      operation,
      timestamp: Date.now(),
      retryCount: 0,
      status: 'pending'
    };

    this.pendingOperations.push(pendingOp);
    
    // Store in local storage for persistence
    localStorage.setItem(
      'pending-operations', 
      JSON.stringify(this.pendingOperations)
    );

    // Try to sync immediately if online
    if (navigator.onLine) {
      this.processSyncQueue();
    }
  }

  // Process queued operations when back online
  private async processSyncQueue(): Promise<void> {
    if (!navigator.onLine || this.syncQueue.size === 0) {
      return;
    }

    const batchSize = 5;
    const batch = this.pendingOperations
      .filter(op => op.status === 'pending')
      .slice(0, batchSize);

    for (const pendingOp of batch) {
      try {
        await this.executePendingOperation(pendingOp);
        
        // Mark as completed
        pendingOp.status = 'completed';
        pendingOp.completedAt = Date.now();
        
      } catch (error) {
        console.error('Sync operation failed:', error);
        
        pendingOp.retryCount++;
        pendingOp.lastError = error.message;
        
        // Mark as failed after max retries
        if (pendingOp.retryCount >= 3) {
          pendingOp.status = 'failed';
        }
      }
    }

    // Clean up completed operations
    this.pendingOperations = this.pendingOperations
      .filter(op => op.status !== 'completed');
    
    localStorage.setItem(
      'pending-operations', 
      JSON.stringify(this.pendingOperations)
    );
  }

  private async executePendingOperation(pendingOp: PendingOperation): Promise<void> {
    const { operation } = pendingOp;
    
    switch (operation.type) {
      case 'CREATE_CAMPAIGN':
        await this.syncCreateCampaign(operation.data);
        break;
      case 'UPDATE_CAMPAIGN':
        await this.syncUpdateCampaign(operation.data);
        break;
      case 'SEND_EMAIL':
        await this.syncSendEmail(operation.data);
        break;
      default:
        throw new Error(`Unknown operation type: ${operation.type}`);
    }
  }

  private setupOnlineListener(): void {
    window.addEventListener('online', () => {
      console.log('Back online, processing sync queue');
      this.processSyncQueue();
    });

    window.addEventListener('offline', () => {
      console.log('Gone offline, queuing operations');
    });
  }
}
```

## Error Handling and Data Recovery

### Comprehensive Error Recovery Patterns
```typescript
// src/utils/errorRecovery.ts
class DataErrorRecovery {
  async recoverFromDataError(
    operation: FailedOperation,
    context: ErrorContext
  ): Promise<RecoveryResult> {
    try {
      switch (operation.type) {
        case 'FETCH_USER_LIST':
          return await this.recoverUserListFetch(operation, context);
        
        case 'SEND_EMAIL_CAMPAIGN':
          return await this.recoverEmailCampaign(operation, context);
        
        case 'UPDATE_ANALYTICS':
          return await this.recoverAnalyticsUpdate(operation, context);
        
        default:
          return this.fallbackRecovery(operation, context);
      }
    } catch (recoveryError) {
      console.error('Data recovery failed:', recoveryError);
      return {
        success: false,
        error: recoveryError.message,
        fallbackData: this.getFallbackData(operation.type)
      };
    }
  }

  private async recoverUserListFetch(
    operation: FailedOperation,
    context: ErrorContext
  ): Promise<RecoveryResult> {
    // Try alternative data sources
    const fallbackSources = [
      () => this.getFromCache('user-list'),
      () => this.getFromLocalStorage('user-list-backup'),
      () => this.getFromIndexedDB('users'),
      () => this.getMinimalUserList()
    ];

    for (const source of fallbackSources) {
      try {
        const data = await source();
        if (data && data.length > 0) {
          return {
            success: true,
            data,
            source: source.name,
            isStale: true
          };
        }
      } catch (sourceError) {
        console.warn(`Fallback source failed: ${source.name}`, sourceError);
      }
    }

    // Return minimal fallback data
    return {
      success: false,
      fallbackData: this.getEmptyUserList(),
      error: 'All user list sources unavailable'
    };
  }

  private async recoverEmailCampaign(
    operation: FailedOperation,
    context: ErrorContext
  ): Promise<RecoveryResult> {
    const campaignData = operation.data;
    
    // Check if campaign was partially sent
    const partialStatus = await this.checkCampaignStatus(campaignData.id);
    
    if (partialStatus.sent > 0) {
      // Resume from where it left off
      const remainingRecipients = campaignData.recipients.slice(partialStatus.sent);
      
      try {
        const resumeResult = await this.resumeCampaign({
          ...campaignData,
          recipients: remainingRecipients
        });
        
        return {
          success: true,
          data: resumeResult,
          message: `Campaign resumed, ${partialStatus.sent} already sent`
        };
      } catch (resumeError) {
        return {
          success: false,
          error: 'Failed to resume campaign',
          fallbackData: partialStatus
        };
      }
    }

    // Campaign not started, retry from beginning
    return this.retryWithBackoff(operation);
  }
}
```

## Performance Optimization Patterns

### Data Loading Optimization
```typescript
// src/hooks/useOptimizedDataLoading.ts
export const useOptimizedDataLoading = <T>(
  dataLoader: DataLoader<T>,
  options: OptimizationOptions = {}
) => {
  const [data, setData] = useState<T[]>([]);
  const [loading, setLoading] = useState(false);
  const [hasMore, setHasMore] = useState(true);

  // Implement virtual scrolling for large datasets
  const [visibleRange, setVisibleRange] = useState({ start: 0, end: 50 });
  
  // Batch API requests to reduce server load
  const debouncedLoader = useMemo(
    () => debounce(dataLoader.load, 300),
    [dataLoader]
  );

  // Implement intelligent prefetching
  const prefetchNext = useCallback(async () => {
    if (!hasMore || loading) return;
    
    const nextBatch = await dataLoader.prefetch(data.length, 50);
    if (nextBatch.length === 0) {
      setHasMore(false);
    }
  }, [data.length, hasMore, loading, dataLoader]);

  // Load visible data with intersection observer
  const loadVisibleData = useCallback(async () => {
    if (loading) return;
    
    setLoading(true);
    try {
      const batchData = await debouncedLoader({
        offset: visibleRange.start,
        limit: visibleRange.end - visibleRange.start
      });
      
      setData(prev => {
        const newData = [...prev];
        batchData.forEach((item, index) => {
          newData[visibleRange.start + index] = item;
        });
        return newData;
      });
      
      // Prefetch next batch
      if (visibleRange.end >= data.length - 10) {
        prefetchNext();
      }
      
    } catch (error) {
      console.error('Data loading failed:', error);
    } finally {
      setLoading(false);
    }
  }, [visibleRange, debouncedLoader, data.length, prefetchNext, loading]);

  // Update visible range based on scroll position
  const updateVisibleRange = useCallback((start: number, end: number) => {
    setVisibleRange({ start, end });
  }, []);

  useEffect(() => {
    loadVisibleData();
  }, [loadVisibleData]);

  return {
    data,
    loading,
    hasMore,
    updateVisibleRange,
    refresh: loadVisibleData
  };
};
```

This comprehensive data flow documentation provides detailed patterns for managing data throughout the CRM application, ensuring optimal performance, reliability, and user experience across all data operations.

<function_calls>
<invoke name="TodoWriter">
<parameter name="todos">[{"content": "Create Aurora PostgreSQL backup and recovery procedures documentation", "status": "completed", "priority": "high", "id": "70"}, {"content": "Document S3 storage backup and versioning strategies", "status": "completed", "priority": "high", "id": "71"}, {"content": "Create Firebase services backup and recovery procedures", "status": "completed", "priority": "high", "id": "72"}, {"content": "Document Infrastructure as Code backup and deployment procedures", "status": "completed", "priority": "high", "id": "73"}, {"content": "Create Lambda function backup and rollback procedures", "status": "completed", "priority": "high", "id": "74"}, {"content": "Create CRM architecture overview documentation", "status": "completed", "priority": "high", "id": "75"}, {"content": "Document CRM component catalog and structure", "status": "completed", "priority": "high", "id": "76"}, {"content": "Create CRM API integrations documentation", "status": "completed", "priority": "high", "id": "77"}, {"content": "Document CRM development setup and deployment procedures", "status": "completed", "priority": "high", "id": "78"}, {"content": "Update dn-api specification with CRM usage patterns", "status": "completed", "priority": "medium", "id": "79"}, {"content": "Update unified architecture documentation to include CRM", "status": "completed", "priority": "medium", "id": "80"}, {"content": "Create CRM authentication flows documentation", "status": "completed", "priority": "medium", "id": "81"}, {"content": "Create CRM data flow patterns documentation", "status": "completed", "priority": "medium", "id": "82"}]
### 8. CloudFront Signed URLs for Financial Reports (NEW - August 2025)

#### Enhanced Email Campaign Flow with Secure File Downloads
```mermaid
sequenceDiagram
    participant CRM as CRM Admin
    participant API as dn-api Gateway
    participant Lambda as DN_Send_Mail Lambda
    participant SM as Secrets Manager
    participant S3 as S3 Bucket
    participant CF as CloudFront
    participant MG as Mailgun
    participant User as Email Recipient

    CRM->>API: POST /send-mail (attachReporting=true)
    API->>Lambda: Invoke with campaign data
    Lambda->>S3: HeadObject (check file existence)
    S3-->>Lambda: File exists confirmation
    Lambda->>SM: GetSecretValue (CloudFront private key)
    SM-->>Lambda: Private key returned
    Lambda->>CF: Generate signed URLs (25-day expiry)
    CF-->>Lambda: Signed URLs created
    Lambda->>MG: Send email with download links
    MG-->>Lambda: Email delivery confirmation
    Lambda-->>API: Success response with link summary
    API-->>CRM: Campaign sent with download info
    
    Note over User: Email received with download links
    User->>CF: Click download link
    CF->>CF: Validate signature & expiry
    CF->>S3: Fetch file (via OAC)
    S3-->>CF: File content
    CF-->>User: File download starts
```

#### CloudFront Signed URL Generation Flow
```mermaid
graph TB
    subgraph "Lambda Function Process"
        A[Event Trigger] --> B{attachReporting?}
        B -->|Yes| C[Load Customer IDs]
        B -->|No| D[Standard Email Flow]
        C --> E[Check S3 File Existence]
        E --> F[Retrieve CloudFront Private Key]
        F --> G[Generate Signed URLs]
        G --> H[Build Download Links Array]
        H --> I[Update Email Template]
        I --> J[Send Email via Mailgun]
    end
    
    subgraph "Security Layer"
        K[AWS Secrets Manager]
        L[CloudFront Key Groups]
        M[Origin Access Control]
    end
    
    subgraph "Storage & CDN"
        N[S3 Bucket: distronation-audio]
        O[CloudFront Distribution]
    end
    
    F --> K
    G --> L
    E --> N
    O --> M
    M --> N
```

#### Data Structures for CloudFront Integration

**Download Links Structure**:
```typescript
interface DownloadLink {
  type: 'youtube' | 'distro';
  filename: string;
  url: string; // CloudFront signed URL
  custom_id: string;
  label: string; // "YouTube Report" | "Streaming Report"
}

interface DownloadLinkGroup {
  custom_id: string;
  links: DownloadLink[];
}

interface DownloadSummary {
  total_links: number;
  summary_text: string;
  links_available: boolean;
}
```

**S3 File Path Patterns**:
```typescript
// File path resolution for different report types
const filePathPatterns = {
  youtube: "Exports/{year}/{month}/{customId}/{customId}.zip",
  distro: "Distro/{year}/{month}/{customId}/{customId}.zip"
};

// Example resolved paths:
// YouTube: "Exports/2025/08/GRACEWEBER/GRACEWEBER.zip"
// Distro: "Distro/2025/08/GRACEWEBER/GRACEWEBER.zip"
```

#### Performance Metrics and Improvements

**Before CloudFront Implementation**:
- Lambda execution time: ~30-45 seconds (with file downloads)
- Memory usage: Up to 512MB-1GB (file buffering)
- Email size: Large (with binary attachments)
- Global performance: Variable (direct S3 access)

**After CloudFront Implementation**:
- Lambda execution time: ~15-20 seconds (50% improvement)
- Memory usage: ~150-300MB (70% improvement)
- Email size: Small (just links)
- Global performance: Optimized (CloudFront CDN)

**Security Enhancements**:
- **Extended Access Period**: 25 days vs previous 7-day S3 limit
- **No Direct S3 Access**: Origin Access Control blocks public access
- **Audit Trail**: CloudFront access logs for download tracking
- **Secure Key Management**: Private keys in AWS Secrets Manager
- **URL Validation**: Cryptographic signature verification

#### Error Handling and Recovery

**File Existence Validation**:
```python
def check_s3_object_exists(bucket_name, object_key):
    try:
        s3_client.head_object(Bucket=bucket_name, Key=object_key)
        return True
    except ClientError as e:
        if e.response['Error']['Code'] == '404':
            return False
        else:
            raise
```

**Graceful Degradation**:
- If CloudFront signing fails: Log error, continue with standard email
- If S3 files missing: Generate links only for available files
- If Secrets Manager unavailable: Fall back to environment variables (dev only)

**Monitoring and Alerting**:
- CloudWatch metrics for signed URL generation success/failure rates
- S3 access pattern monitoring via CloudFront logs
- Lambda execution time tracking for performance regression detection
- Email delivery rate monitoring to ensure no impact from changes

This enhanced data flow pattern demonstrates the integration of CloudFront signed URLs into the existing email campaign system, providing improved security, performance, and user experience for financial report distribution.

## 9. S3 File Browser Data Flow Patterns (NEW - August 2025)

### S3 Direct File Browser Integration
The S3 File Browser represents a new frontend integration allowing direct user interaction with S3 storage for financial report access and bulk downloads.

#### S3 File Browser Initialization and Authentication Flow
```mermaid
sequenceDiagram
    participant User as CRM User
    participant CRM as React Application
    participant Context as S3BrowserContext
    participant Bridge as AmplifyFirebaseBridge
    participant Cognito as AWS Cognito
    participant Firebase as Firebase Auth
    participant S3 as S3 Service

    User->>CRM: Navigate to Reports Download tab
    CRM->>Context: Initialize S3BrowserContext
    Context->>Bridge: Request AWS credentials
    Bridge->>Firebase: Get current user token
    Firebase-->>Bridge: Firebase ID token
    Bridge->>Cognito: Exchange for AWS credentials
    Cognito-->>Bridge: Temporary AWS credentials
    Bridge-->>Context: AWS credentials available
    Context->>S3: Initialize S3Client with credentials
    S3-->>Context: S3Client ready
    Context->>S3: Initial file listing request
    S3->>S3: ListObjectsV2(prefix="", maxKeys=50)
    S3-->>Context: File and folder listing
    Context-->>CRM: Update UI with files
    CRM-->>User: Display file browser interface
```

#### Hierarchical Navigation Data Flow
```mermaid
sequenceDiagram
    participant User as CRM User
    participant Table as S3FileTable
    participant Context as S3BrowserContext
    participant Service as S3Service
    participant Cache as S3Cache
    participant S3 as AWS S3

    User->>Table: Click folder to navigate
    Table->>Context: setCurrentPath(folderPath)
    Context->>Cache: Check cached folder contents
    alt Cache Hit
        Cache-->>Context: Return cached file listing
    else Cache Miss
        Context->>Service: listFiles(folderPath)
        Service->>S3: ListObjectsV2Command
        Note over S3: Prefix: folderPath/<br/>Delimiter: /
        S3-->>Service: S3 objects and common prefixes
        Service->>Service: Transform to UI format
        Service-->>Context: Formatted file listing
        Context->>Cache: Store in cache (TTL: 5min)
    end
    Context->>Context: Update files state
    Context-->>Table: Trigger re-render
    Table-->>User: Display folder contents
    
    Note over User: Breadcrumb navigation updated
    Context->>Context: Update breadcrumb path
```

#### File Selection and State Management Flow
```mermaid
graph TB
    subgraph "User Interactions"
        A[Individual File Select] --> B[Checkbox Toggle]
        C[Select All Button] --> D[Bulk Selection]
        E[Clear Selection] --> F[Reset State]
    end
    
    subgraph "State Management"
        G[S3BrowserContext]
        H[selectedFiles: Set&lt;string&gt;]
        I[downloadProgress: Map&lt;string, number&gt;]
    end
    
    subgraph "UI Updates"
        J[S3FileTable]
        K[S3DownloadManager]
        L[Breadcrumb Counter]
    end
    
    B --> G
    D --> G
    F --> G
    G --> H
    G --> I
    H --> J
    I --> K
    H --> L
    
    G --> M[Context Provider]
    M --> N[Child Components]
```

**File Selection Implementation**:
```typescript
// S3BrowserContext.tsx data flow
interface S3BrowserState {
  currentPath: string;
  files: S3Object[];
  selectedFiles: Set<string>;
  loading: boolean;
  error: string | null;
  downloadProgress: Map<string, number>;
}

const S3BrowserProvider: React.FC = ({ children }) => {
  const [state, setState] = useState<S3BrowserState>({
    currentPath: '',
    files: [],
    selectedFiles: new Set(),
    loading: false,
    error: null,
    downloadProgress: new Map()
  });

  // File selection flow
  const toggleFileSelection = useCallback((fileKey: string) => {
    setState(prev => {
      const newSelection = new Set(prev.selectedFiles);
      if (newSelection.has(fileKey)) {
        newSelection.delete(fileKey);
      } else {
        newSelection.add(fileKey);
      }
      
      // Persist selection in sessionStorage for navigation
      sessionStorage.setItem(
        's3-selected-files',
        JSON.stringify([...newSelection])
      );
      
      return {
        ...prev,
        selectedFiles: newSelection
      };
    });
  }, []);

  // Bulk selection flow
  const selectAllFiles = useCallback(() => {
    setState(prev => {
      const allFileKeys = prev.files
        .filter(file => !file.key.endsWith('/')) // Exclude folders
        .map(file => file.key);
      
      const newSelection = new Set(allFileKeys);
      
      sessionStorage.setItem(
        's3-selected-files',
        JSON.stringify([...newSelection])
      );
      
      return {
        ...prev,
        selectedFiles: newSelection
      };
    });
  }, []);

  return (
    <S3BrowserContext.Provider value={{
      ...state,
      toggleFileSelection,
      selectAllFiles,
      clearSelection,
      updateDownloadProgress
    }}>
      {children}
    </S3BrowserContext.Provider>
  );
};
```

#### Bulk Download Data Flow with ZIP Creation
```mermaid
sequenceDiagram
    participant User as CRM User
    participant DM as S3DownloadManager
    participant Service as S3Service
    participant S3 as AWS S3
    participant ZIP as JSZip Library
    participant FS as FileSaver

    User->>DM: Click "Download Selected" (5 files)
    DM->>DM: Initialize progress tracking
    
    loop For each selected file
        DM->>Service: downloadFile(fileKey)
        Service->>S3: GetObjectCommand with signed URL
        S3-->>Service: File blob data
        Service-->>DM: File blob + progress update
        DM->>DM: updateProgress(fileKey, progress)
        DM->>ZIP: Add file to archive
    end
    
    DM->>ZIP: Generate ZIP archive
    ZIP-->>DM: Completed ZIP blob
    DM->>FS: SaveAs(zipBlob, filename)
    FS-->>User: Browser download initiated
    
    Note over DM: Update download state
    DM->>DM: Clear progress tracking
    DM-->>User: Show success notification
```

**Bulk Download Implementation**:
```typescript
// S3DownloadManager component data flow
const S3DownloadManager: React.FC = () => {
  const { selectedFiles, downloadProgress, updateDownloadProgress } = useS3Browser();
  const [isDownloading, setIsDownloading] = useState(false);

  const handleBulkDownload = async () => {
    if (selectedFiles.size === 0) return;
    
    setIsDownloading(true);
    const zip = new JSZip();
    const totalFiles = selectedFiles.size;
    let completedFiles = 0;

    try {
      // Process files in parallel batches of 3 to avoid overwhelming S3
      const batchSize = 3;
      const fileKeys = Array.from(selectedFiles);
      
      for (let i = 0; i < fileKeys.length; i += batchSize) {
        const batch = fileKeys.slice(i, i + batchSize);
        
        await Promise.all(batch.map(async (fileKey) => {
          try {
            // Download individual file
            const fileBlob = await s3Service.downloadFile(fileKey);
            const fileName = fileKey.split('/').pop() || fileKey;
            
            // Add to ZIP
            zip.file(fileName, fileBlob);
            
            completedFiles++;
            const progress = Math.round((completedFiles / totalFiles) * 100);
            
            // Update progress in context
            updateDownloadProgress(fileKey, progress);
            
          } catch (error) {
            console.error(`Failed to download ${fileKey}:`, error);
            toast.error(`Failed to download ${fileKey.split('/').pop()}`);
          }
        }));
      }

      // Generate ZIP archive
      const zipBlob = await zip.generateAsync({ 
        type: 'blob',
        compression: 'DEFLATE',
        compressionOptions: {
          level: 6
        }
      });

      // Trigger browser download
      const timestamp = new Date().toISOString().split('T')[0];
      const filename = `reports-${timestamp}.zip`;
      FileSaver.saveAs(zipBlob, filename);

      toast.success(`Downloaded ${completedFiles} files as ${filename}`);

    } catch (error) {
      console.error('Bulk download failed:', error);
      toast.error('Bulk download failed');
    } finally {
      setIsDownloading(false);
      
      // Clear progress tracking
      selectedFiles.forEach(fileKey => {
        updateDownloadProgress(fileKey, 0);
      });
    }
  };

  return (
    <Card>
      <CardContent>
        <Box display="flex" alignItems="center" gap={2}>
          <Typography variant="h6">
            {selectedFiles.size} files selected
          </Typography>
          <Button
            variant="contained"
            startIcon={<Download />}
            onClick={handleBulkDownload}
            disabled={selectedFiles.size === 0 || isDownloading}
          >
            {isDownloading ? 'Downloading...' : 'Download as ZIP'}
          </Button>
        </Box>
        
        {isDownloading && (
          <Box mt={2}>
            <Typography variant="body2">Download Progress:</Typography>
            <LinearProgress 
              variant="determinate" 
              value={(Array.from(downloadProgress.values()).reduce((a, b) => a + b, 0) / selectedFiles.size)} 
            />
          </Box>
        )}
      </CardContent>
    </Card>
  );
};
```

#### S3 Error Handling and Recovery Patterns
```mermaid
graph TB
    subgraph "Error Detection"
        A[S3 Operation] --> B{Error Type?}
        B -->|AccessDenied| C[Permission Error]
        B -->|NoSuchKey| D[File Not Found]
        B -->|NetworkError| E[Connectivity Issue]
        B -->|ThrottlingException| F[Rate Limit Hit]
    end
    
    subgraph "Recovery Strategies"
        C --> G[Show auth error, suggest re-login]
        D --> H[Remove from file list, notify user]
        E --> I[Exponential backoff retry]
        F --> J[Queue operation, retry after delay]
    end
    
    subgraph "User Feedback"
        G --> K[Toast Notification]
        H --> L[File Status Update]
        I --> M[Loading Indicator]
        J --> N[Queued Status Badge]
    end
    
    K --> O[Error Boundary Fallback]
    L --> O
    M --> O
    N --> O
```

**Error Recovery Implementation**:
```typescript
// useS3ErrorHandler.ts - Error handling patterns
export const useS3ErrorHandler = () => {
  const handleS3Error = useCallback((error: any, context: ErrorContext) => {
    const errorType = classifyS3Error(error);
    
    switch (errorType) {
      case 'ACCESS_DENIED':
        return {
          message: 'Access denied. Please check your permissions and try logging in again.',
          action: 'retry_auth',
          severity: 'error' as const
        };
        
      case 'NO_SUCH_KEY':
        return {
          message: `File "${context.fileName}" not found or has been moved.`,
          action: 'remove_from_list',
          severity: 'warning' as const
        };
        
      case 'NETWORK_ERROR':
        return {
          message: 'Network connectivity issue. Retrying...',
          action: 'retry_with_backoff',
          severity: 'info' as const
        };
        
      case 'THROTTLING':
        return {
          message: 'Too many requests. Please wait a moment.',
          action: 'queue_and_retry',
          severity: 'warning' as const
        };
        
      default:
        return {
          message: 'An unexpected error occurred with S3 operation.',
          action: 'log_and_notify',
          severity: 'error' as const
        };
    }
  }, []);

  const retryWithBackoff = useCallback(async (
    operation: () => Promise<any>,
    maxRetries = 3
  ) => {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (error) {
        if (attempt === maxRetries) throw error;
        
        const delay = Math.min(1000 * Math.pow(2, attempt), 10000);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }, []);

  return { handleS3Error, retryWithBackoff };
};

// S3ErrorBoundary component for graceful error handling
class S3ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error, errorInfo: null };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('S3ErrorBoundary caught an error:', error, errorInfo);
    
    // Log to monitoring service
    this.logErrorToService(error, errorInfo);
    
    this.setState({ errorInfo });
  }

  render() {
    if (this.state.hasError) {
      return (
        <Box p={3} textAlign="center">
          <ErrorOutline color="error" sx={{ fontSize: 60, mb: 2 }} />
          <Typography variant="h6" gutterBottom>
            S3 File Browser Error
          </Typography>
          <Typography variant="body1" color="text.secondary" paragraph>
            We encountered an issue loading the file browser. This might be due to:
          </Typography>
          <Box component="ul" textAlign="left" display="inline-block">
            <li>Network connectivity issues</li>
            <li>AWS service temporarily unavailable</li>
            <li>Authentication credentials expired</li>
          </Box>
          <Box mt={3} gap={2}>
            <Button 
              variant="contained" 
              onClick={() => window.location.reload()}
              startIcon={<Refresh />}
            >
              Retry
            </Button>
            <Button 
              variant="outlined" 
              onClick={() => this.setState({ hasError: false, error: null })}
              sx={{ ml: 2 }}
            >
              Dismiss
            </Button>
          </Box>
        </Box>
      );
    }

    return this.props.children;
  }
}
```

#### Performance Optimization Data Patterns

**S3 Request Batching and Caching**:
```typescript
// S3 request optimization patterns
class S3CacheManager {
  private cache = new Map<string, CacheEntry>();
  private pendingRequests = new Map<string, Promise<any>>();
  
  // Implement request deduplication
  async getCachedOrFetch<T>(
    key: string, 
    fetcher: () => Promise<T>,
    ttl = 300000 // 5 minutes
  ): Promise<T> {
    // Check cache first
    const cached = this.cache.get(key);
    if (cached && Date.now() - cached.timestamp < ttl) {
      return cached.data as T;
    }
    
    // Check for pending request to avoid duplicates
    if (this.pendingRequests.has(key)) {
      return this.pendingRequests.get(key) as Promise<T>;
    }
    
    // Create new request
    const request = fetcher().then(data => {
      this.cache.set(key, {
        data,
        timestamp: Date.now()
      });
      this.pendingRequests.delete(key);
      return data;
    }).catch(error => {
      this.pendingRequests.delete(key);
      throw error;
    });
    
    this.pendingRequests.set(key, request);
    return request;
  }
  
  // Intelligent prefetching based on user behavior
  prefetchNextPage(currentPath: string, currentItems: S3Object[]): void {
    if (currentItems.length === 50) { // Full page, likely more items
      const nextContinuationToken = this.extractContinuationToken(currentItems);
      if (nextContinuationToken) {
        // Prefetch in background
        setTimeout(() => {
          this.getCachedOrFetch(
            `${currentPath}-page-${nextContinuationToken}`,
            () => this.listObjectsWithToken(currentPath, nextContinuationToken)
          );
        }, 1000);
      }
    }
  }
}
```

This comprehensive S3 File Browser data flow documentation demonstrates the integration patterns, state management, error handling, and performance optimization strategies for the new direct S3 frontend integration within the Distro Nation CRM application.
