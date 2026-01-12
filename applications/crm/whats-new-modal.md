# What's New Modal Feature - Technical Documentation

## Overview

The What's New modal is a feature release information system that displays new features to users upon application updates. It provides a smooth, accessible way to introduce new functionality while respecting user dismissal preferences through localStorage persistence.

## Architecture

### Component Hierarchy

```
App (Root Component)
└── WhatsNewProvider (Context Provider)
    ├── WhatsNewModal (Main Modal Component)
    │   ├── DialogTitle (Feature Release Info)
    │   ├── DialogContent
    │   │   └── FeatureItem[] (Individual Features)
    │   └── DialogActions (Got It Button)
    └── {App Content}
```

### Component Responsibilities

#### WhatsNewProvider.tsx
**Location:** `src/contexts/WhatsNewProvider.tsx`
**Purpose:** React Context provider that manages What's New modal state and lifecycle
**Props:** 
- `children`: React components to wrap

**Provides via Context:**
- `open`: boolean - Whether the modal is currently visible
- `setOpen`: (open: boolean) => void - Function to control modal visibility
- `featureConfig`: FeatureConfig - Current feature configuration data
- `dismissModal`: () => void - Function to dismiss modal and persist state

**Key Features:**
- Initializes modal visibility based on feature version and dismissal history
- Automatically hides modal on route changes or re-render
- Handles dismissal state persistence via whatsNewService
- Provides context values to all child components

#### WhatsNewModal.tsx
**Location:** `src/components/WhatsNewModal.tsx`
**Purpose:** Main modal component for displaying feature information
**Props:**
```typescript
interface WhatsNewModalProps {
  open: boolean;
  onClose: () => void;
  featureConfig: FeatureConfig;
}
```

**Features:**
- Material-UI Dialog component with responsive design
- Smooth animations (Grow transition with 300ms enter, 200ms exit)
- Full keyboard navigation support (Escape to close, Tab for focus)
- Screen reader support with proper ARIA attributes
- Accessibility features:
  - Semantic dialog with `aria-labelledby` and `aria-describedby`
  - Live region announcements for modal state changes
  - Focus trap within dialog (native MUI behavior)
  - Proper button labeling and semantic HTML
  - Color contrast compliance
  - Respects `prefers-reduced-motion` media query
- Responsive design for mobile and desktop
- Staggered entrance animations for feature items

**Dialog Structure:**
```
DialogTitle
├── Title (Feature Release Name)
└── Metadata (Version & Release Date)
└── Close Button (X Icon)

DialogContent
└── Stack of FeatureItem components

DialogActions
└── "Got It" Button
```

#### FeatureItem.tsx
**Location:** `src/components/FeatureItem.tsx`
**Purpose:** Individual feature item component with icon and description
**Props:**
```typescript
interface FeatureItemProps {
  feature: Feature;
  index: number;
}
```

**Features:**
- Displays feature icon, title, and description
- Staggered entrance animation based on index
- Responsive text sizing and padding
- Icon rendering for visual feature representation

### Data Flow

```
1. App Initialization
   ├── Check APP_FEATURE_VERSION environment variable/window property
   ├── Load features-config.json via featureConfigLoader
   └── Pass feature configuration to WhatsNewProvider

2. WhatsNewProvider Initialization
   ├── Call whatsNewService.shouldShowModal()
   │   ├── Get current feature version
   │   ├── Check if user has dismissed this version
   │   └── Return boolean for modal visibility
   ├── Set initial modal visibility state
   └── Provide context to child components

3. User Interaction
   ├── User views features in modal
   ├── User clicks "Got It" or closes modal
   ├── Call dismissModal() callback
   ├── WhatsNewProvider calls whatsNewService.markModalAsDismissed(version)
   ├── localStorage is updated with dismissal state
   └── Modal visibility state is updated to false

4. Next Session
   ├── App initializes with new feature version
   ├── WhatsNewProvider checks shouldShowModal()
   ├── If version incremented: hasUserDismissedModal() returns false
   ├── Modal displays again for new version
   └── If same version: hasUserDismissedModal() returns true, modal hidden
```

### localStorage Key Format

```typescript
// Pattern: whats_new_modal_dismissed_v{VERSION}
// Examples:
localStorage['whats_new_modal_dismissed_v1.0.0'] = 'true'
localStorage['whats_new_modal_dismissed_v1.1.0'] = 'true'
localStorage['whats_new_modal_dismissed_v2.0.0'] = 'true'
```

## Service Layer

### whatsNewService.ts
**Location:** `src/services/whatsNewService.ts`
**Purpose:** localStorage persistence layer for modal dismissal tracking

#### Core Functions

##### `shouldShowModal(): boolean`
Determines whether the modal should be displayed to the user.

**Logic:**
1. Get current feature version via `getCurrentFeatureVersion()`
2. Validate version is not null/empty
3. Check if user has dismissed this version via `hasUserDismissedModal()`
4. Return `!userDismissed` (show if NOT dismissed)

**Returns:** `true` if modal should be shown, `false` otherwise

**Example:**
```typescript
if (whatsNewService.shouldShowModal()) {
  setOpen(true);
}
```

##### `markModalAsDismissed(version: string): void`
Persists modal dismissal state to localStorage for a specific version.

**Process:**
1. Check if localStorage is available
2. Generate key: `whats_new_modal_dismissed_v{version}`
3. Set value: `localStorage.setItem(key, 'true')`
4. Handle errors gracefully (private browsing, quota exceeded)

**Error Handling:**
- Private browsing mode: Logs warning, continues without persistence
- Quota exceeded: Logs warning, continues without persistence
- Security errors: Logs warning, continues without persistence

**Example:**
```typescript
whatsNewService.markModalAsDismissed('1.0.0');
// localStorage['whats_new_modal_dismissed_v1.0.0'] = 'true'
```

##### `getCurrentFeatureVersion(): string`
Retrieves the current feature version from multiple sources.

**Version Source Priority (in order):**
1. `window.APP_FEATURE_VERSION` - Runtime configuration
2. `process.env.REACT_APP_FEATURE_VERSION` - Build-time environment variable
3. `'1.0.0'` - Default fallback

**Caching:** Version is cached after first call to avoid repeated lookups

**Example:**
```typescript
const version = whatsNewService.getCurrentFeatureVersion();
// Returns: '1.2.0'
```

##### `hasUserDismissedModal(version: string): boolean`
Checks if user has previously dismissed the modal for a specific version.

**Process:**
1. Check localStorage availability
2. Generate dismissal key: `whats_new_modal_dismissed_v{version}`
3. Return true if `localStorage.getItem(key) === 'true'`
4. Return false if storage unavailable or any error occurs

**Example:**
```typescript
const dismissed = whatsNewService.hasUserDismissedModal('1.0.0');
// Returns: true if previously dismissed, false otherwise
```

##### `getModalDismissedKey(version: string): string`
Generates the localStorage key for a specific version's dismissal state.

**Format:** `whats_new_modal_dismissed_v{version}`

**Example:**
```typescript
const key = whatsNewService.getModalDismissedKey('1.0.0');
// Returns: 'whats_new_modal_dismissed_v1.0.0'
```

##### `isNewVersionAvailable(currentVersion: string, lastSeenVersion: string | null): boolean`
Determines if a new version is available compared to last seen version.

**Returns `true` if:**
- No last seen version exists (first time or cleared)
- Current version is numerically greater than last seen version

**Returns `false` if:**
- Versions are identical
- Last seen version is greater than current version

**Comparison Method:** Semantic versioning (MAJOR.MINOR.PATCH)

**Example:**
```typescript
const isNew = whatsNewService.isNewVersionAvailable('1.1.0', '1.0.0');
// Returns: true (1.1.0 > 1.0.0)
```

##### `getLastSeenVersion(): string | null`
Retrieves the most recent feature version that user has seen.

**Process:**
1. Check localStorage availability
2. Scan all localStorage keys for pattern: `whats_new_modal_dismissed_v*`
3. Extract version strings from matching keys
4. Sort using semantic version comparison
5. Return the highest version

**Example:**
```typescript
const lastVersion = whatsNewService.getLastSeenVersion();
// Returns: '1.1.0' if user has seen versions 1.0.0 and 1.1.0
// Returns: null if no versions found
```

##### `clearVersionCache(): void`
Clears the cached feature version (primarily for testing).

**Use Cases:**
- Testing version detection
- Simulating version changes in tests
- Resetting version cache in development

**Example:**
```typescript
whatsNewService.clearVersionCache();
// Next call to getCurrentFeatureVersion() will re-evaluate
```

## Configuration

### Feature Configuration File
**Location:** `src/data/features-config.json`
**Format:** JSON with feature release information

```json
{
  "title": "What's New in Payouts Mailer",
  "version": "1.0.0",
  "releaseDate": "2024-01-12T00:00:00Z",
  "features": [
    {
      "id": "feature-1",
      "title": "Feature Title",
      "description": "Feature description explaining the new capability.",
      "icon": "StarIcon"
    },
    {
      "id": "feature-2",
      "title": "Another Feature",
      "description": "Another feature description.",
      "icon": "LightbulbIcon"
    }
  ]
}
```

### Feature Object Structure
**Type:** `Feature` (from `src/types/featureConfig.ts`)

```typescript
interface Feature {
  id: string;           // Unique feature identifier
  title: string;        // Feature name/title
  description: string;  // Feature description
  icon: string;         // Material-UI icon name (e.g., 'StarIcon', 'LightbulbIcon')
}
```

### Root Configuration Object
**Type:** `FeatureConfig` (from `src/types/featureConfig.ts`)

```typescript
interface FeatureConfig {
  title: string;        // Modal title (e.g., "What's New")
  version: string;      // Feature version (e.g., "1.0.0")
  releaseDate: string;  // ISO 8601 date string (e.g., "2024-01-12T00:00:00Z")
  features: Feature[];  // Array of Feature objects
}
```

## Integration Instructions

### 1. Wrap Application with WhatsNewProvider

In `src/App.tsx`, wrap your application content:

```typescript
import WhatsNewProvider from './contexts/WhatsNewProvider';

function App() {
  return (
    <WhatsNewProvider>
      <ThemeProvider>
        <Router>
          {/* Your app routes and content */}
        </Router>
      </ThemeProvider>
    </WhatsNewProvider>
  );
}
```

### 2. Place Features Configuration File

Create `src/data/features-config.json`:

```json
{
  "title": "What's New in Payouts Mailer",
  "version": "1.0.0",
  "releaseDate": "2024-01-12T00:00:00Z",
  "features": [
    {
      "id": "feature-1",
      "title": "New Dashboard",
      "description": "Completely redesigned dashboard with improved analytics.",
      "icon": "AnalyticsIcon"
    },
    {
      "id": "feature-2",
      "title": "Enhanced Search",
      "description": "Faster, more powerful search across all campaigns.",
      "icon": "SearchIcon"
    }
  ]
}
```

### 3. Set Feature Version

Choose one of these methods (in order of priority):

**Option A: Runtime Configuration (Recommended)**
```typescript
// In your main application bootstrap code
(window as any).APP_FEATURE_VERSION = '1.0.0';
```

**Option B: Environment Variable**
```bash
# In .env file
REACT_APP_FEATURE_VERSION=1.0.0
```

**Option C: Use Default**
Default version `1.0.0` will be used if neither above is set.

### 4. (Optional) Access WhatsNewContext

To manually control the modal in components:

```typescript
import { useContext } from 'react';
import { WhatsNewContext } from '../contexts/WhatsNewProvider';

function MyComponent() {
  const { open, setOpen, dismissModal } = useContext(WhatsNewContext);
  
  return (
    <button onClick={dismissModal}>
      Dismiss What's New
    </button>
  );
}
```

## How to Update Feature Lists

### Adding New Features

When adding new features to your application:

1. **Open** `src/data/features-config.json`

2. **Update the version** - Increment the version number:
   ```json
   {
     "version": "1.1.0"  // Changed from 1.0.0
   }
   ```

3. **Update the release date**:
   ```json
   {
     "releaseDate": "2024-01-15T00:00:00Z"  // Today's date
   }
   ```

4. **Add new feature objects** to the `features` array:
   ```json
   {
     "features": [
       {
         "id": "feature-3",
         "title": "New Feature Name",
         "description": "Description of what this feature does and how users benefit from it.",
         "icon": "CheckCircleIcon"
       }
     ]
   }
   ```

5. **Choose an appropriate icon** from Material-UI icons. Common ones:
   - `StarIcon` - For highlight/favorite features
   - `LightbulbIcon` - For smart/intelligent features
   - `AnalyticsIcon` - For analytics/reporting features
   - `CheckCircleIcon` - For improvements/completions
   - `TrendingUpIcon` - For performance improvements
   - `SecurityIcon` - For security features
   - `SpeedIcon` - For performance/speed
   - `IntegrationIcon` - For integrations

### Updating Existing Features

To modify an already-displayed feature:

1. **Open** `src/data/features-config.json`
2. **Locate** the feature by its `id`
3. **Update** the `title` or `description`
4. **Do NOT change the version** (users will see the same modal)

### Feature Lifecycle

```
Development
├── Add feature to codebase
├── Update features-config.json with feature details
└── Increment version number

Release
├── Deploy application with new features
├── Modal appears to all users (old version context)
├── Users click "Got It" to dismiss
└── dismissal state saved to localStorage

Next Session (Same Version)
├── App loads with same version
├── Modal is NOT shown (user already dismissed)
└── Users continue with modal hidden

Next Session (New Version)
├── App loads with incremented version
├── Modal is shown again (new version not dismissed)
├── Users see updated features
└── Cycle repeats

```

## Technical Details

### Responsive Behavior

The modal adapts to different screen sizes:

**Desktop (sm breakpoint and above)**
- Max width: 600px (md)
- Centered on screen
- Full animation
- Horizontal spacing

**Mobile (below sm breakpoint)**
- Full width with 8px margin
- Bottom sheet appearance
- Smooth scaling animation
- Touch-friendly button sizing

### Animation Details

**Dialog Entry:**
- Transition: Grow (scale from small to full size)
- Duration: 300ms enter, 200ms exit
- Easing: cubic-bezier(0.4, 0, 0.2, 1)
- Respects prefers-reduced-motion

**Paper Animation:**
- Scale: 0.95 → 1.0
- Opacity: 0 → 1
- Duration: 300ms

**Backdrop Animation:**
- Opacity: 0 → 1
- Duration: 300ms

**Feature Items:**
- Staggered entrance based on index
- Fade and slide animation

### Accessibility Features

**Keyboard Navigation:**
- Tab: Navigate through interactive elements
- Escape: Close modal
- Enter/Space: Activate buttons

**Screen Reader Support:**
- Live region announcements for modal state
- Semantic dialog with proper heading hierarchy
- ARIA labels for icon buttons
- Button purpose clearly stated

**Visual Accessibility:**
- Color contrast meets WCAG AA standards
- Focus indicators visible and high contrast
- Sufficient padding for touch targets
- Text is readable and properly sized

**Motion Preferences:**
- Respects `prefers-reduced-motion` media query
- Animations disabled for users who prefer reduced motion

### Error Handling

**localStorage Unavailable:**
- Private browsing mode
- Browser restrictions
- Quota exceeded

**Fallback Behavior:**
- Modal shows (fails open for user visibility)
- Dismissal state not persisted
- Warning logged to console
- Application continues normally

## Performance Considerations

### Optimization Techniques

1. **Version Caching:** Feature version cached after first retrieval
2. **Lazy Loading:** Modal content only rendered when open
3. **Memoization:** Component props optimized with React.memo
4. **Context Optimization:** Context provider optimized to prevent unnecessary re-renders

### Bundle Impact

- Component: ~8KB (minified + gzipped)
- Service: ~4KB (minified + gzipped)
- Configuration file: ~2KB (depends on features)
- **Total:** ~14KB additional overhead

### localStorage Impact

- Per version: ~45 bytes per dismissal state
- Typical impact: <500 bytes for 10+ versions
- No performance impact on application startup

## Testing Considerations

For comprehensive testing details, see the separate Testing Plan document.

### Key Test Scenarios

1. **Initial Load:** Modal appears on first load
2. **Dismissal:** Modal persists dismissal across sessions
3. **Version Update:** Modal reappears when version incremented
4. **localStorage Unavailable:** Graceful fallback behavior
5. **Accessibility:** Full keyboard and screen reader support
6. **Responsive Design:** Proper layout on all screen sizes
7. **Performance:** No impact on app load time

## Troubleshooting

### Modal Not Appearing

**Check:**
1. Ensure WhatsNewProvider wraps your app
2. Verify features-config.json exists and is valid JSON
3. Check browser console for errors
4. Verify `APP_FEATURE_VERSION` or env var is set
5. Clear browser localStorage and reload

**Debug:**
```typescript
console.log(whatsNewService.shouldShowModal());           // Should be true
console.log(whatsNewService.getCurrentFeatureVersion());  // Should show version
console.log(whatsNewService.hasUserDismissedModal('1.0.0')); // Should be false on first load
```

### Modal Appearing Multiple Times

**Check:**
1. Verify localStorage is persisting (not in private mode)
2. Ensure dismissal key is correct: `whats_new_modal_dismissed_v{version}`
3. Check browser console for localStorage errors

**Debug:**
```typescript
// Check localStorage directly
Object.keys(localStorage).filter(k => k.startsWith('whats_new_modal_dismissed'))
// Should show: ['whats_new_modal_dismissed_v1.0.0']
```

### Version Not Updating

**Check:**
1. Verify `APP_FEATURE_VERSION` is updated to new version
2. Confirm environment variable is changed
3. Check that build is using updated configuration
4. Clear browser cache and localStorage

### localStorage Not Working

**Check:**
1. Private browsing mode enabled?
2. Browser storage disabled?
3. localStorage quota exceeded?

**Fallback:** 
- Modal will still show but dismissal won't persist
- Warning will be logged to console
- No errors thrown (graceful degradation)

## Summary

The What's New modal provides:
- ✅ Clean, accessible UI for feature announcements
- ✅ Persistent dismissal tracking per version
- ✅ Automatic re-display on version updates
- ✅ Full keyboard and screen reader support
- ✅ Responsive design for all devices
- ✅ Zero impact on app performance
- ✅ Graceful error handling
- ✅ Easy feature list updates

For testing plan and validation criteria, see the dedicated Testing Plan document.
