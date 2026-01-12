# Distro Nation CRM Component Catalog

## Overview
This document provides a comprehensive catalog of all React components within the Distro Nation CRM application, including their purpose, props, dependencies, and integration points.

## Root Application Components

### App.tsx
**Purpose**: Root application component with routing and theme configuration
**Location**: `src/App.tsx`
**Dependencies**: 
- Material-UI ThemeProvider
- React Router DOM
- AuthContext Provider

**Key Features**:
- Global theme application via MUI ThemeProvider
- Route configuration with protected/public route separation
- Authentication state management integration
- Fallback and redirect route handling

**Routes Configuration**:
```typescript
// Public Routes
/login -> Login Component
/register -> Register Component  
/forgot-password -> ForgotPassword Component

// Protected Routes (within Layout)
/dashboard -> Dashboard Component
/mailer/* -> Mailer Module
/outreach -> OutreachPage Component
/profile -> Profile Component
/admin -> AdminPanel Component
```

## Authentication Module (`/components/auth/`)

### Login.tsx
**Purpose**: Primary authentication interface
**Location**: `src/components/auth/Login.tsx`
**Props**: None (uses AuthContext)
**Dependencies**:
- Firebase Authentication
- AuthContext for state management
- Material-UI form components

**Functionality**:
- Email/password authentication via Firebase
- Form validation and error handling
- Automatic redirect to dashboard on success
- Integration with forgot password flow

### Register.tsx  
**Purpose**: User registration with role assignment
**Location**: `src/components/auth/Register.tsx`
**Props**: None
**Dependencies**:
- Firebase Authentication
- User role management utilities
- Form validation libraries

**Features**:
- New user account creation
- Role-based access control setup
- Email verification integration
- Welcome email triggering

### ProtectedRoute.tsx
**Purpose**: Route guard for authenticated access
**Location**: `src/components/auth/ProtectedRoute.tsx`
**Props**: 
- `children`: React components to protect
**Dependencies**:
- AuthContext for authentication state
- React Router for navigation

**Logic Flow**:
1. Check authentication status from AuthContext
2. If authenticated, render children components
3. If not authenticated, redirect to login page
4. Handle loading states during auth verification

### AdminPanel.tsx
**Purpose**: Administrative interface for user management
**Location**: `src/components/auth/AdminPanel.tsx`
**Props**: None
**Dependencies**:
- Material-UI Data Grid
- Firebase Admin SDK
- User role management utilities

**Capabilities**:
- User list management and editing
- Role assignment and permissions
- Account activation/deactivation
- Administrative action logging

### Profile.tsx
**Purpose**: User profile management interface
**Location**: `src/components/auth/Profile.tsx`
**Props**: None
**Dependencies**:
- AuthContext for current user data
- Firebase Authentication for updates
- Form validation components

**Features**:
- Profile information editing
- Password change functionality
- Account settings management
- Profile picture upload

### ForgotPassword.tsx
**Purpose**: Password reset functionality
**Location**: `src/components/auth/ForgotPassword.tsx`
**Props**: None
**Dependencies**:
- Firebase Authentication
- Email validation utilities

**Workflow**:
- Email address collection and validation
- Password reset email triggering
- Success/error message display
- Return to login navigation

### AdminSetup.tsx
**Purpose**: Initial administrative account setup
**Location**: `src/components/auth/AdminSetup.tsx`
**Props**: None
**Dependencies**:
- Firebase Admin SDK
- Setup validation utilities

**Purpose**: First-time admin account configuration and initial system setup

## Layout Module (`/components/layout/`)

### Layout.tsx
**Purpose**: Main application layout wrapper
**Location**: `src/components/layout/Layout.tsx`
**Props**: 
- `children`: Child components to render within layout
**Dependencies**:
- Sidebar component
- Header component
- Material-UI layout containers

**Structure**:
```typescript
<Layout>
  <Header />
  <Sidebar />
  <MainContent>
    {children}
  </MainContent>
</Layout>
```

### Sidebar.tsx
**Purpose**: Navigation sidebar with menu items
**Location**: `src/components/layout/Sidebar.tsx`
**Props**: None
**Dependencies**:
- SidebarItem components
- React Router navigation
- AuthContext for role-based menu items

**Navigation Items**:
- Dashboard (default landing)
- Mailer (email campaigns)
- Outreach (campaign management)
- Profile (user settings)
- Admin Panel (admin only)

### SidebarItem.tsx
**Purpose**: Individual sidebar navigation item
**Location**: `src/components/layout/SidebarItem.tsx`
**Props**:
- `icon`: Material-UI icon component
- `text`: Display text for menu item
- `path`: Navigation route path
- `onClick`: Optional click handler

**Features**:
- Active state highlighting
- Icon and text display
- Navigation integration
- Accessibility support

## Mailer Module (`/components/mailer/`)

### MailerTemplate.tsx
**Purpose**: Tabbed interface for email campaign creation and financial report downloads
**Location**: `src/components/mailer/MailerTemplate.tsx`
**Props**: None
**State Management**:
```typescript
interface NewsletterFormData {
  email: string;
  user: EmailUser | null;
  content: string;
  subject: string;
  greeting: string;
  emailList: EmailUser[];
  sendAll: boolean;
  testing: boolean;
  month: string;
  year: string;
  emailType: "financial" | "newsletter";
}
```

**Dependencies**:
- React Quill for rich text editing
- axios for API communication
- dn-api configuration
- Material-UI form components
- Material-UI Tabs for tabbed interface
- S3FileBrowser component for Reports tab

**Key Features**:
- **Email Template Tab**: Rich text email content editing
- **Reports Download Tab**: S3 file browser for financial report access
- User list loading from dn-api
- Recipient selection (individual or bulk)
- Email preview functionality
- Campaign scheduling options
- Template management (financial/newsletter)
- File browsing and bulk download capabilities

**API Integration**:
- `GET /dn_users_list`: Fetch recipient list
- `POST /send-mail`: Send email campaign
- AWS S3 SDK for file operations

### MailerLogs.tsx
**Purpose**: Email campaign tracking and analytics
**Location**: `src/components/mailer/MailerLogs.tsx`
**Props**: None
**Dependencies**:
- Material-UI Data Grid
- Date formatting utilities
- Mailgun API integration

**Features**:
- Campaign performance metrics
- Delivery status tracking
- Open/click rate analytics
- Failed delivery management
- Export capabilities for reporting

### MailerLayout.tsx
**Purpose**: Mailer module layout container
**Location**: `src/components/mailer/MailerLayout.tsx`
**Props**:
- `children`: Mailer module components
**Dependencies**:
- MailerSidebar for module navigation
- Module-specific header

**Structure**:
- Module-specific navigation
- Content area for mailer components
- Breadcrumb navigation

### MailerSidebar.tsx
**Purpose**: Mailer module navigation sidebar
**Location**: `src/components/mailer/MailerSidebar.tsx`
**Props**: None
**Dependencies**:
- React Router for navigation
- Module-specific menu items

**Navigation Options**:
- Template Creation
- Campaign Logs
- Template Library
- Reports Download
- Settings

## S3 File Browser Module (`/components/s3/`)

### S3FileBrowser.tsx
**Purpose**: Main S3 file browser interface with hierarchical navigation
**Location**: `src/components/s3/S3FileBrowser.tsx`
**Props**: None
**Dependencies**:
- S3BrowserContext for state management
- S3FileTable component
- S3BreadcrumbNav component
- S3DownloadManager component
- S3Service for AWS operations

**Key Features**:
- Hierarchical folder navigation
- File selection and bulk operations
- Integration with S3BrowserContext for state management
- Error handling through S3ErrorBoundary
- Loading states with skeleton placeholders

**State Management**:
```typescript
interface S3BrowserState {
  currentPath: string;
  files: S3Object[];
  selectedFiles: Set<string>;
  loading: boolean;
  error: string | null;
  downloadProgress: Map<string, number>;
}
```

### S3FileTable.tsx
**Purpose**: Material-UI DataGrid for file listing and selection
**Location**: `src/components/s3/S3FileTable.tsx`
**Props**:
- `files`: Array of S3 file objects
- `onFileSelect`: File selection handler
- `onFolderNavigate`: Folder navigation handler
**Dependencies**:
- Material-UI X DataGrid
- File type icon mapping
- Custom cell renderers

**Features**:
- Sortable columns (Name, Size, Last Modified, Type)
- Checkbox-based multi-selection
- File type icons and folder indicators
- Custom actions column with download buttons
- Responsive design for mobile devices
- Pagination support for large directories

**Column Configuration**:
```typescript
interface S3FileColumns {
  selection: CheckboxColumn;
  name: FileNameColumn;
  size: FileSizeColumn;
  lastModified: DateColumn;
  type: FileTypeColumn;
  actions: ActionsColumn;
}
```

### S3BreadcrumbNav.tsx
**Purpose**: Hierarchical navigation breadcrumb component
**Location**: `src/components/s3/S3BreadcrumbNav.tsx`
**Props**:
- `currentPath`: Current S3 path
- `onNavigate`: Path navigation handler
**Dependencies**:
- Material-UI Breadcrumbs
- Path parsing utilities

**Features**:
- Interactive path segments
- Home/root navigation
- Path validation and sanitization
- Responsive breadcrumb display
- Keyboard navigation support

### S3DownloadManager.tsx
**Purpose**: Download progress tracking and bulk ZIP creation
**Location**: `src/components/s3/S3DownloadManager.tsx`
**Props**:
- `selectedFiles`: Set of selected file keys
- `onDownloadComplete`: Completion handler
**Dependencies**:
- JSZip for bulk archive creation
- FileSaver.js for browser downloads
- Progress tracking utilities

**Features**:
- Individual file download with signed URLs
- Bulk ZIP download for multiple files
- Real-time download progress indicators
- Error handling and retry mechanisms
- Download cancellation support
- Progress notifications via toast system

**Download Types**:
```typescript
interface DownloadOptions {
  individual: SignedUrlDownload;
  bulk: ZipArchiveDownload;
  progress: ProgressTracking;
  retry: RetryMechanism;
}
```

### S3ErrorBoundary.tsx
**Purpose**: Error handling specific to S3 operations
**Location**: `src/components/s3/S3ErrorBoundary.tsx`
**Props**:
- `children`: Components to protect
- `fallback`: Error display component
**Dependencies**:
- React Error Boundary API
- S3-specific error handling

**Error Handling**:
- S3 access permission errors
- Network connectivity issues
- File not found errors
- Download failure recovery
- User-friendly error messages
- Automatic retry suggestions

## Outreach Module (`/components/outreach/`)

### OutreachPage.tsx
**Purpose**: Main outreach campaign management interface
**Location**: `src/components/outreach/OutreachPage.tsx`
**Props**: None
**Dependencies**:
- OutreachTabs for tabbed interface
- OutreachDataGrid for data display
- Campaign management utilities

**Features**:
- Campaign overview dashboard
- Multi-tab interface for different views
- Campaign creation and editing
- Performance analytics integration

### CampaignsTab.tsx
**Purpose**: Campaign list and management interface
**Location**: `src/components/outreach/CampaignsTab.tsx`
**Props**:
- `campaigns`: Array of campaign objects
- `onCampaignSelect`: Campaign selection handler
**Dependencies**:
- Material-UI Data Grid
- Campaign filtering utilities

**Functionality**:
- Campaign list display with sorting/filtering
- Status indicators (draft, active, completed)
- Campaign performance metrics
- Quick action buttons (edit, duplicate, delete)

### OutreachDataGrid.tsx
**Purpose**: Data grid component for outreach data display
**Location**: `src/components/outreach/OutreachDataGrid.tsx`
**Props**:
- `data`: Data array for grid display
- `columns`: Column configuration
- `onRowSelect`: Row selection handler
**Dependencies**:
- Material-UI X Data Grid
- Custom cell renderers

**Features**:
- Sortable and filterable data display
- Custom cell rendering for specific data types
- Row selection and bulk actions
- Export functionality

### MessageTrackingLog.tsx
**Purpose**: Detailed message tracking and analytics
**Location**: `src/components/outreach/MessageTrackingLog.tsx`
**Props**:
- `messageId`: Message identifier for tracking
**Dependencies**:
- Analytics service integration
- Chart components for visualization

**Analytics Displayed**:
- Message delivery status
- Open rates and timestamps
- Click tracking data
- Recipient engagement metrics
- Geographic distribution data

### OutreachFormDialog.tsx
**Purpose**: Campaign creation and editing modal
**Location**: `src/components/outreach/OutreachFormDialog.tsx`
**Props**:
- `open`: Dialog open state
- `onClose`: Close handler
- `campaign`: Campaign data for editing (optional)
- `onSave`: Save handler
**Dependencies**:
- Material-UI Dialog components
- Form validation utilities
- RichTextEditor component

**Form Fields**:
- Campaign name and description
- Target audience selection
- Message content (rich text)
- Scheduling options
- Campaign settings and preferences

### RichTextEditor.tsx
**Purpose**: Rich text editing component for campaign content
**Location**: `src/components/outreach/RichTextEditor.tsx`
**Props**:
- `value`: Current text content
- `onChange`: Content change handler
- `placeholder`: Input placeholder text
**Dependencies**:
- React Quill editor
- Custom toolbar configuration

**Features**:
- WYSIWYG text editing
- HTML content generation
- Custom toolbar with relevant options
- Image insertion capabilities
- Link management

### ImportButton.tsx & ImportButtons.tsx
**Purpose**: Data import functionality for campaigns
**Location**: `src/components/outreach/ImportButton.tsx`
**Props**:
- `onImport`: Import completion handler
- `acceptedTypes`: File types accepted
**Dependencies**:
- CSV parsing utilities
- Google Sheets integration

**Import Sources**:
- CSV file upload
- Google Sheets integration
- Manual data entry
- API data synchronization

### DeleteConfirmationModal.tsx
**Purpose**: Confirmation dialog for delete operations
**Location**: `src/components/outreach/DeleteConfirmationModal.tsx`
**Props**:
- `open`: Modal open state
- `onClose`: Close handler
- `onConfirm`: Confirmation handler
- `itemName`: Name of item being deleted
**Dependencies**:
- Material-UI Dialog components

**Safety Features**:
- Clear confirmation messaging
- Item identification display
- Action confirmation buttons
- Cancel/escape options

### OutreachSettingsDrawer.tsx
**Purpose**: Settings panel for outreach configuration
**Location**: `src/components/outreach/OutreachSettingsDrawer.tsx`
**Props**:
- `open`: Drawer open state
- `onClose`: Close handler
**Dependencies**:
- Material-UI Drawer component
- Settings management utilities

**Configuration Options**:
- Default campaign settings
- Integration configurations
- Notification preferences
- Data retention settings

## Dashboard Module (`/pages/dashboard/`)

### Dashboard.tsx
**Purpose**: Main dashboard landing page
**Location**: `src/pages/dashboard/Dashboard.tsx`
**Props**: None
**Dependencies**:
- AnalyticsSummary component
- RecentActivity component
- QuickAccessCard components

**Layout**:
- Key metrics overview
- Recent activity feed
- Quick access to main functions
- Performance charts and graphs

### AnalyticsSummary.tsx
**Purpose**: Key performance indicators display
**Location**: `src/pages/dashboard/AnalyticsSummary.tsx`
**Props**: None
**Dependencies**:
- Analytics services
- Chart visualization libraries
- Data formatting utilities

**Metrics Displayed**:
- Total campaigns sent
- Email delivery rates
- Open and click rates
- User engagement trends
- Revenue attribution data

### RecentActivity.tsx
**Purpose**: Activity feed and action log
**Location**: `src/pages/dashboard/RecentActivity.tsx`
**Props**: None
**Dependencies**:
- Activity logging service
- Date formatting utilities

**Activity Types**:
- Campaign creation and launches
- User management actions
- System configuration changes
- Performance milestones
- Error and warning events

### QuickAccessCard.tsx
**Purpose**: Quick action cards for common tasks
**Location**: `src/pages/dashboard/QuickAccessCard.tsx`
**Props**:
- `title`: Card title
- `description`: Card description
- `icon`: Display icon
- `onClick`: Action handler
**Dependencies**:
- Material-UI Card components
- Navigation utilities

**Common Quick Actions**:
- Create new email campaign
- View campaign analytics
- Manage user lists
- Access recent campaigns
- System health check

## Service Components (`/services/`)

### emailService.ts
**Purpose**: Email sending and management service
**Location**: `src/services/emailService.ts`
**Dependencies**:
- dn-api configuration
- Mailgun integration
- Error handling utilities

**Functions**:
- `sendViaAPI()`: Send email via dn-api
- `validateEmailContent()`: Content validation
- `formatEmailData()`: Data formatting for API

### loggingService.ts
**Purpose**: Application logging and analytics
**Location**: `src/services/loggingService.ts`
**Dependencies**:
- Analytics providers
- Error tracking services

**Logging Capabilities**:
- User action tracking
- Error logging and reporting
- Performance metrics collection
- Campaign analytics data

### openaiService.ts
**Purpose**: OpenAI API integration for content generation
**Location**: `src/services/openaiService.ts`
**Dependencies**:
- OpenAI API client
- Content formatting utilities

**AI Features**:
- Email content generation
- Subject line optimization
- Content improvement suggestions
- Template creation assistance

### outreachService.ts
**Purpose**: Outreach campaign management service
**Location**: `src/services/outreachService.ts`
**Dependencies**:
- Campaign data models
- API integration utilities

**Service Functions**:
- Campaign CRUD operations
- Analytics data collection
- Campaign scheduling management
- Performance tracking

### templateService.ts
**Purpose**: Email template management service
**Location**: `src/services/templateService.ts`
**Dependencies**:
- Template storage utilities
- Content validation services

**Template Management**:
- Template creation and editing
- Template library management
- Version control for templates
- Template sharing and collaboration

### S3Service.ts
**Purpose**: AWS S3 integration service for file operations
**Location**: `src/services/S3Service.ts`
**Dependencies**:
- @aws-sdk/client-s3
- AWS Amplify for credentials
- Signed URL generation utilities
- File validation and security utilities

**Core Functions**:
```typescript
interface S3ServiceMethods {
  listFiles(prefix?: string): Promise<S3Object[]>;
  downloadFile(key: string): Promise<Blob>;
  generateSignedUrl(key: string): Promise<string>;
  validatePath(path: string): boolean;
  getFileMetadata(key: string): Promise<S3Metadata>;
}
```

**Key Features**:
- Hierarchical file listing with `listObjectsV2`
- Secure signed URL generation for downloads
- File path validation and sanitization
- Pagination support for large directories
- Error handling and retry logic
- Credentials management via Amplify-Firebase bridge
- Security validation for all file operations

**Security Implementation**:
- Path traversal prevention
- File access validation
- Time-limited signed URLs
- Credential security with AWS Cognito
- Error message sanitization

## What's New Modal Module (`/components/` & `/contexts/`)

### WhatsNewModal.tsx
**Purpose**: Main modal component for displaying feature release information
**Location**: `src/components/WhatsNewModal.tsx`
**Props**: 
```typescript
interface WhatsNewModalProps {
  open: boolean;              // Whether the modal is visible
  onClose: () => void;        // Callback when modal is closed
  featureConfig: FeatureConfig; // Feature configuration with release info
}
```
**Dependencies**:
- Material-UI Dialog, Button, Typography, Stack, Grow
- FeatureItem component
- modalStyles utilities

**Key Features**:
- Responsive Material-UI Dialog with adaptive sizing
- Smooth Grow transition animation (300ms enter, 200ms exit)
- Full keyboard navigation support (Escape to close, Tab navigation)
- Screen reader announcements via live region
- Semantic HTML with proper ARIA attributes
- Focus trap within dialog (native MUI behavior)
- Mobile-friendly sheet appearance on small screens
- Staggered animations for feature items
- Color contrast and accessibility compliance
- Respects prefers-reduced-motion media query

**Dialog Structure**:
- **Title Section**: Feature title, version, and release date with close button
- **Content Section**: Scrollable stack of FeatureItem components
- **Actions Section**: "Got It" button to dismiss modal

### FeatureItem.tsx
**Purpose**: Individual feature item component with icon, title, and description
**Location**: `src/components/FeatureItem.tsx`
**Props**:
```typescript
interface FeatureItemProps {
  feature: Feature;    // Feature object with id, title, description, icon
  index: number;       // Index for staggered animation timing
}
```
**Dependencies**:
- Material-UI Box, Stack, Typography, Avatar
- Dynamic Material-UI icon imports

**Features**:
- Icon rendering using Material-UI icon library
- Responsive layout with mobile-optimized spacing
- Staggered entrance animation based on index position
- Text truncation and wrapping for long descriptions
- Avatar container for feature icon display

### WhatsNewProvider.tsx
**Purpose**: React Context provider managing What's New modal state and lifecycle
**Location**: `src/contexts/WhatsNewProvider.tsx`
**Props**:
- `children`: React components to wrap

**Provides via Context**:
```typescript
interface WhatsNewContextValue {
  open: boolean;                  // Modal visibility state
  setOpen: (open: boolean) => void; // Control modal visibility
  featureConfig: FeatureConfig;   // Current feature configuration
  dismissModal: () => void;       // Dismiss modal and persist state
}
```

**Dependencies**:
- React Context API
- whatsNewService for localStorage operations
- featureConfigLoader for loading feature configuration
- React Router for route change detection
- Theme utilities

**Key Features**:
- Initializes modal visibility based on feature version and dismissal history
- Loads feature configuration from features-config.json
- Tracks route changes and auto-closes modal on navigation
- Handles dismissal state persistence via whatsNewService
- Manages context lifecycle with useEffect cleanup
- Provides uniform context values to all child components

**Initialization Flow**:
1. Load features-config.json
2. Check current feature version
3. Determine if modal should be shown (using whatsNewService.shouldShowModal())
4. Set initial visibility state
5. Provide context to children

### whatsNewService.ts
**Purpose**: localStorage persistence layer for modal dismissal tracking
**Location**: `src/services/whatsNewService.ts`
**Functions**:
- `shouldShowModal(): boolean` - Determine if modal should be shown
- `markModalAsDismissed(version: string): void` - Persist dismissal state
- `hasUserDismissedModal(version: string): boolean` - Check dismissal state
- `getCurrentFeatureVersion(): string` - Get current feature version
- `getModalDismissedKey(version: string): string` - Generate localStorage key
- `isNewVersionAvailable(current: string, lastSeen: string | null): boolean` - Check for version update
- `getLastSeenVersion(): string | null` - Get highest previously seen version
- `clearVersionCache(): void` - Clear version cache (testing)

**localStorage Keys Pattern**:
- Format: `whats_new_modal_dismissed_v{VERSION}`
- Example: `whats_new_modal_dismissed_v1.0.0`

**Error Handling**:
- Private browsing mode: Logs warning, continues without persistence
- Quota exceeded: Logs warning, continues without persistence
- Security errors: Logs warning, continues without persistence
- All errors logged to console but application continues

**Features**:
- Version caching to optimize repeated lookups
- Semantic version comparison (MAJOR.MINOR.PATCH)
- Graceful fallback to safe defaults on errors
- localStorage availability checks before operations
- Comprehensive error logging without throwing exceptions

### featureConfig.ts (Types)
**Purpose**: TypeScript type definitions for feature configuration
**Location**: `src/types/featureConfig.ts`

**Exported Types**:
```typescript
interface Feature {
  id: string;           // Unique feature identifier
  title: string;        // Feature name/title
  description: string;  // Feature description
  icon: string;         // Material-UI icon name
}

interface FeatureConfig {
  title: string;        // Modal title (e.g., "What's New")
  version: string;      // Feature version (e.g., "1.0.0")
  releaseDate: string;  // ISO 8601 date string
  features: Feature[];  // Array of Feature objects
}
```

### features-config.json
**Purpose**: Feature release configuration data
**Location**: `src/data/features-config.json`
**Format**: JSON with structured feature information

**Structure**:
```json
{
  "title": "What's New in Payouts Mailer",
  "version": "1.0.0",
  "releaseDate": "2024-01-12T00:00:00Z",
  "features": [
    {
      "id": "feature-1",
      "title": "Feature Title",
      "description": "Description of feature",
      "icon": "StarIcon"
    }
  ]
}
```

### modalStyles.ts
**Purpose**: Centralized styling configuration for modal components
**Location**: `src/utils/modalStyles.ts`
**Exports**: Style objects for:
- `dialog` - Dialog container styles
- `mobileSheet` - Mobile-optimized sheet styles
- `dialogTitle` - Title section styles
- `dialogContent` - Content section styles
- `dialogActions` - Actions section styles

**Features**:
- Responsive spacing and sizing
- Theme-aware color usage
- Mobile-first design approach
- Consistent animation and transitions

### featureConfigLoader.ts
**Purpose**: Utility for loading and parsing feature configuration files
**Location**: `src/utils/featureConfigLoader.ts`
**Functions**:
- `loadFeatureConfig(): Promise<FeatureConfig>` - Load features-config.json
- Error handling for missing or invalid configuration files

**Dependencies**:
- Fetch API for loading JSON files
- TypeScript types for configuration objects

**Error Handling**:
- Network errors: Logs and returns empty configuration
- Parse errors: Logs and returns empty configuration
- Missing file: Logs and returns empty configuration

## Utility Components

### Context Providers

#### AuthContext.tsx
**Purpose**: Global authentication state management
**Location**: `src/contexts/AuthContext.tsx`
**Provides**:
- Current user state
- Authentication methods
- Role-based permissions
- Session management

#### S3BrowserContext.tsx
**Purpose**: S3 file browser state management
**Location**: `src/contexts/S3BrowserContext.tsx`
**Provides**:
- Current path state
- File listing data
- Selected files state
- Download progress tracking
- Error state management

**Context State**:
```typescript
interface S3BrowserContextValue {
  currentPath: string;
  setCurrentPath: (path: string) => void;
  files: S3Object[];
  loading: boolean;
  error: string | null;
  selectedFiles: Set<string>;
  toggleFileSelection: (key: string) => void;
  selectAllFiles: () => void;
  clearSelection: () => void;
  downloadProgress: Map<string, number>;
  updateDownloadProgress: (key: string, progress: number) => void;
}
```

### Custom Hooks

#### useLocalStorageState.ts
**Purpose**: Local storage state management hook
**Location**: `src/hooks/useLocalStorageState.ts`
**Parameters**: 
- `key`: Storage key
- `defaultValue`: Default value if not found

#### useMailgunLogs.ts
**Purpose**: Mailgun API integration for email logs
**Location**: `src/hooks/useMailgunLogs.ts`
**Returns**: Email delivery logs and analytics data

#### useOutreachAnalytics.ts
**Purpose**: Outreach campaign analytics hook
**Location**: `src/hooks/useOutreachAnalytics.ts`
**Returns**: Campaign performance metrics and trends

#### useOutreachData.ts
**Purpose**: Outreach data management hook
**Location**: `src/hooks/useOutreachData.ts`
**Returns**: Campaign data and CRUD operations

#### useOutreachForm.ts
**Purpose**: Outreach form state management
**Location**: `src/hooks/useOutreachForm.ts`
**Returns**: Form state and validation utilities

#### useS3Service.ts
**Purpose**: S3 service integration hook
**Location**: `src/hooks/useS3Service.ts`
**Returns**: S3 service methods and state management
**Features**:
- S3Service instance with error handling
- File listing and navigation utilities
- Download management and progress tracking
- Path validation and security checks

#### useS3ErrorHandler.ts
**Purpose**: S3-specific error handling hook
**Location**: `src/hooks/useS3ErrorHandler.ts`
**Parameters**:
- `error`: S3 error object
- `context`: Error context information
**Returns**: 
- Formatted error messages
- User-friendly error descriptions
- Retry suggestions and actions
- Error reporting utilities

**Error Types Handled**:
```typescript
interface S3ErrorTypes {
  AccessDenied: PermissionError;
  NoSuchKey: FileNotFoundError;
  NetworkError: ConnectivityError;
  InvalidRequest: ValidationError;
  ThrottlingException: RateLimitError;
}
```

## Component Integration Patterns

### Data Flow Pattern
1. **Service Layer**: API calls and data transformation
2. **Custom Hooks**: State management and business logic
3. **Components**: UI rendering and user interaction
4. **Context Providers**: Global state distribution

### Error Handling Pattern
- Component-level error boundaries
- Service-level error catching and transformation
- User-friendly error message display
- Automatic retry mechanisms where appropriate

### Loading State Pattern
- Loading indicators for async operations
- Skeleton loading for content areas
- Progressive data loading for large datasets
- Optimistic UI updates where possible

This component catalog provides a comprehensive reference for understanding the structure, dependencies, and functionality of all components within the Distro Nation CRM application.