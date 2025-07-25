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
**Purpose**: Email campaign creation and management
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

**Key Features**:
- Rich text email content editing
- User list loading from dn-api
- Recipient selection (individual or bulk)
- Email preview functionality
- Campaign scheduling options
- Template management (financial/newsletter)

**API Integration**:
- `GET /dn_users_list`: Fetch recipient list
- `POST /send-mail`: Send email campaign

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
- Settings

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