# What's New Modal - Configuration Guide

## Overview

This guide provides detailed information about configuring the What's New modal feature, including the JSON schema, validation rules, and step-by-step examples for updating feature lists.

## Configuration File

### Location
**File:** `src/data/features-config.json`

### Purpose
The `features-config.json` file stores all feature release information displayed in the What's New modal. It contains:
- Modal title
- Feature version (e.g., "1.0.0", "1.1.0")
- Release date
- Array of features with descriptions and icons

## JSON Schema

### Complete Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "title": "What's New Modal Configuration",
  "description": "Configuration for feature release information displayed in the What's New modal",
  "required": ["title", "version", "releaseDate", "features"],
  "properties": {
    "title": {
      "type": "string",
      "description": "Modal title displayed at the top of the dialog",
      "minLength": 1,
      "maxLength": 100,
      "example": "What's New in Payouts Mailer"
    },
    "version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+\\.\\d+$",
      "description": "Semantic version string (MAJOR.MINOR.PATCH format)",
      "example": "1.0.0"
    },
    "releaseDate": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 formatted release date and time",
      "example": "2024-01-12T00:00:00Z"
    },
    "features": {
      "type": "array",
      "description": "Array of feature objects",
      "minItems": 1,
      "maxItems": 10,
      "items": {
        "type": "object",
        "required": ["id", "title", "description", "icon"],
        "properties": {
          "id": {
            "type": "string",
            "pattern": "^[a-z0-9-]+$",
            "description": "Unique feature identifier (lowercase, alphanumeric with hyphens)",
            "minLength": 1,
            "maxLength": 50,
            "example": "enhanced-dashboard"
          },
          "title": {
            "type": "string",
            "description": "Feature name displayed as bold heading",
            "minLength": 1,
            "maxLength": 50,
            "example": "Enhanced Dashboard"
          },
          "description": {
            "type": "string",
            "description": "Feature description explaining benefits and usage",
            "minLength": 10,
            "maxLength": 200,
            "example": "Completely redesigned dashboard with real-time analytics and improved performance"
          },
          "icon": {
            "type": "string",
            "description": "Material-UI icon name (without 'Icon' suffix if using standard icons)",
            "enum": [
              "Star", "Lightbulb", "Analytics", "CheckCircle", "TrendingUp",
              "Security", "Speed", "Integration", "Cloud", "Zap",
              "BarChart", "Target", "Users", "Settings", "Bell",
              "Search", "Filter", "Download", "Upload", "Share",
              "Lock", "Unlock", "Eye", "EyeOff", "Heart",
              "ThumbsUp", "Award", "Rocket", "Smile", "Gift"
            ],
            "example": "Analytics"
          }
        },
        "additionalProperties": false
      }
    }
  },
  "additionalProperties": false
}
```

## Field Specifications

### Root Object Fields

#### title
- **Type:** String
- **Required:** Yes
- **Min Length:** 1 character
- **Max Length:** 100 characters
- **Purpose:** Displayed as the main modal heading
- **Example:** `"What's New in Payouts Mailer"`
- **Guidelines:**
  - Should be concise and descriptive
  - Typically "What's New in [App Name]"
  - Avoid using punctuation or special characters

#### version
- **Type:** String
- **Required:** Yes
- **Format:** Semantic Versioning (MAJOR.MINOR.PATCH)
- **Pattern:** `^\d+\.\d+\.\d+$`
- **Purpose:** Controls modal display and dismissal tracking
- **Examples:**
  - `"1.0.0"` - Initial release
  - `"1.1.0"` - Minor feature update
  - `"2.0.0"` - Major release
  - `"1.2.3"` - Bug fix release
- **Guidelines:**
  - Increment MAJOR for breaking changes
  - Increment MINOR for new features
  - Increment PATCH for bug fixes
  - Update this to show modal to users who have already dismissed previous version

#### releaseDate
- **Type:** String
- **Required:** Yes
- **Format:** ISO 8601 Date-Time (RFC 3339)
- **Purpose:** Displayed in modal metadata and used for sorting
- **Examples:**
  - `"2024-01-12T00:00:00Z"` - Midnight UTC
  - `"2024-01-12T10:30:00Z"` - 10:30 UTC
  - `"2024-01-12T00:00:00-05:00"` - With timezone offset
- **Guidelines:**
  - Always use UTC timezone (Z suffix)
  - Use the date your release goes live
  - Include time for accuracy (usually 00:00:00)
  - Will be formatted as "January 12, 2024" in the modal

### Feature Object Fields

#### id
- **Type:** String
- **Required:** Yes
- **Min Length:** 1 character
- **Max Length:** 50 characters
- **Pattern:** Lowercase alphanumeric with hyphens: `^[a-z0-9-]+$`
- **Purpose:** Unique identifier for the feature
- **Examples:**
  - `"enhanced-dashboard"`
  - `"real-time-analytics"`
  - `"dark-mode-support"`
  - `"csv-export-feature"`
- **Guidelines:**
  - Must be unique within the features array
  - Use lowercase letters, numbers, and hyphens only
  - Use hyphens to separate words (kebab-case)
  - Should be descriptive and meaningful
  - No spaces or special characters

#### title
- **Type:** String
- **Required:** Yes
- **Min Length:** 1 character
- **Max Length:** 50 characters
- **Purpose:** Feature name displayed in bold
- **Examples:**
  - `"Enhanced Dashboard"`
  - `"Real-Time Analytics"`
  - `"Dark Mode Support"`
- **Guidelines:**
  - Use Title Case (capitalize each word)
  - Keep concise and descriptive
  - Avoid technical jargon when possible
  - Should be readable at a glance

#### description
- **Type:** String
- **Required:** Yes
- **Min Length:** 10 characters
- **Max Length:** 200 characters
- **Purpose:** Detailed explanation of the feature
- **Examples:**
  - `"Completely redesigned dashboard with real-time analytics and improved performance"`
  - `"View live engagement metrics as they happen with our new real-time tracking system"`
  - `"Switch to dark mode for comfortable viewing in low-light environments"`
- **Guidelines:**
  - Start with what the feature does
  - Include user benefit when possible
  - Use plain language
  - Keep sentences concise
  - Avoid marketing hype
  - Focus on practical value

#### icon
- **Type:** String
- **Required:** Yes
- **Purpose:** Visual representation of the feature
- **Valid Values:** Material-UI icon names from approved list
- **Examples:**
  - `"Analytics"` - For analytics/metrics features
  - `"Lightbulb"` - For new ideas/smart features
  - `"CheckCircle"` - For completed/improved features
  - `"TrendingUp"` - For performance improvements
- **Approved Icons:**

| Icon Name | Use Case | Appearance |
|-----------|----------|-----------|
| `"Star"` | Highlight/favorite features | ⭐ Star |
| `"Lightbulb"` | Smart/intelligent features | 💡 Light bulb |
| `"Analytics"` | Analytics/metrics | 📊 Chart |
| `"CheckCircle"` | Improvements/completions | ✓ Check mark |
| `"TrendingUp"` | Performance improvements | 📈 Up trend |
| `"Security"` | Security features | 🔒 Lock |
| `"Speed"` | Speed/performance | ⚡ Lightning |
| `"Integration"` | Integrations | 🔗 Link |
| `"Cloud"` | Cloud features | ☁️ Cloud |
| `"Zap"` | Power/energy features | ⚡ Flash |
| `"BarChart"` | Data/reporting | 📊 Bar chart |
| `"Target"` | Goals/targeting | 🎯 Target |
| `"Users"` | User management | 👥 People |
| `"Settings"` | Configuration | ⚙️ Gear |
| `"Bell"` | Notifications | 🔔 Bell |
| `"Search"` | Search functionality | 🔍 Magnifying glass |
| `"Filter"` | Filtering | 🔽 Filter |
| `"Download"` | Download action | ⬇️ Down arrow |
| `"Upload"` | Upload action | ⬆️ Up arrow |
| `"Share"` | Sharing | 📤 Share |

## Validation Rules

### Required Validation
- All root-level fields (`title`, `version`, `releaseDate`, `features`) must be present
- Each feature must have all required fields (`id`, `title`, `description`, `icon`)
- `features` array must contain at least 1 and no more than 10 features

### Format Validation
- `version` must match semantic versioning pattern: `X.Y.Z` where X, Y, Z are integers
- `releaseDate` must be valid ISO 8601 format (RFC 3339)
- Feature `id` must match pattern: `^[a-z0-9-]+$` (lowercase, alphanumeric, hyphens only)
- Feature `icon` must be from the approved icons list

### Length Validation
- `title`: 1-100 characters
- `version`: Follows MAJOR.MINOR.PATCH format
- Feature `id`: 1-50 characters
- Feature `title`: 1-50 characters
- Feature `description`: 10-200 characters

### Uniqueness Validation
- Feature `id` values must be unique within the `features` array
- Duplicate IDs will cause unexpected behavior

### Semantic Validation
- `version` should be incremented from the previous version to show modal to returning users
- `releaseDate` should be the actual date the release goes live
- `features` should be sorted by importance or implementation order

## Examples

### Minimal Valid Configuration

```json
{
  "title": "What's New",
  "version": "1.0.0",
  "releaseDate": "2024-01-12T00:00:00Z",
  "features": [
    {
      "id": "feature-1",
      "title": "New Feature",
      "description": "This is a new feature that improves user experience",
      "icon": "Star"
    }
  ]
}
```

### Complete Example with Multiple Features

```json
{
  "title": "What's New in Payouts Mailer v1.2",
  "version": "1.2.0",
  "releaseDate": "2024-01-15T10:00:00Z",
  "features": [
    {
      "id": "enhanced-dashboard",
      "title": "Enhanced Dashboard",
      "description": "Completely redesigned dashboard with real-time analytics, custom widgets, and improved performance metrics visualization",
      "icon": "Analytics"
    },
    {
      "id": "batch-campaign-scheduling",
      "title": "Batch Campaign Scheduling",
      "description": "Schedule multiple campaigns at once using our new batch scheduler with timezone support and recurring campaign options",
      "icon": "CheckCircle"
    },
    {
      "id": "ai-subject-line-optimizer",
      "title": "AI Subject Line Optimizer",
      "description": "Leverage machine learning to generate optimized subject lines that increase open rates based on your audience data",
      "icon": "Lightbulb"
    },
    {
      "id": "export-analytics-reports",
      "title": "Export Analytics Reports",
      "description": "Download detailed campaign analytics and performance reports in PDF or CSV format for sharing with stakeholders",
      "icon": "Download"
    },
    {
      "id": "improved-performance",
      "title": "30% Performance Improvement",
      "description": "Optimized codebase and infrastructure upgrades deliver significantly faster load times and better responsiveness",
      "icon": "TrendingUp"
    }
  ]
}
```

### Version Update Example

When releasing a new version with additional features:

```json
{
  "title": "What's New in Payouts Mailer v1.3",
  "version": "1.3.0",  // ← Incremented from 1.2.0
  "releaseDate": "2024-02-01T00:00:00Z",  // ← New date
  "features": [
    // Keep all previous features if applicable, or show only new ones
    {
      "id": "collaboration-features",
      "title": "Team Collaboration",
      "description": "Work together on campaigns with real-time collaboration, commenting, and approval workflows",
      "icon": "Users"
    },
    {
      "id": "api-webhooks",
      "title": "Webhook API Integration",
      "description": "Integrate with external systems using our new webhook API for custom automations and real-time notifications",
      "icon": "Integration"
    }
  ]
}
```

## How to Update Features

### Step-by-Step Process

#### 1. Open features-config.json
```bash
# Navigate to the file
open src/data/features-config.json
# Or in your editor:
# VSCode: Ctrl+P (Cmd+P on Mac) → type "features-config.json"
```

#### 2. Update Version Number
Always increment the version when adding features:

```json
// BEFORE
{
  "title": "What's New in Payouts Mailer",
  "version": "1.0.0",  // ← Old version
  ...
}

// AFTER
{
  "title": "What's New in Payouts Mailer",
  "version": "1.1.0",  // ← Incremented
  ...
}
```

**Version Increment Rules:**
- New features → Increment MINOR (1.0.0 → 1.1.0)
- Breaking changes → Increment MAJOR (1.0.0 → 2.0.0)
- Bug fixes only → Increment PATCH (1.0.0 → 1.0.1)

#### 3. Update Release Date
```json
// BEFORE
{
  "releaseDate": "2024-01-12T00:00:00Z"  // ← Old date
}

// AFTER
{
  "releaseDate": "2024-02-15T00:00:00Z"  // ← Today's release date
}
```

Use the date your release goes live to production.

#### 4. Add New Feature Objects
Add new feature objects to the `features` array:

```json
{
  "features": [
    // Existing features...
    
    // New feature
    {
      "id": "new-feature-name",
      "title": "New Feature Title",
      "description": "Description of what this feature does and why users will benefit from it",
      "icon": "StarIcon"  // Choose appropriate icon
    }
  ]
}
```

**Best Practices:**
- Add most important features first
- Use descriptive IDs (lowercase, hyphens)
- Write benefit-focused descriptions
- Choose icons that match the feature

#### 5. Validate JSON
Ensure the JSON is valid:

```bash
# Using Node.js
node -e "console.log(JSON.parse(require('fs').readFileSync('src/data/features-config.json', 'utf8')))"

# If no error is printed, JSON is valid
```

#### 6. Test Locally
```bash
# Start the development server
npm start

# On first load, the modal should appear with new version
# If you're on the same version, the modal won't show
# To test: Clear localStorage and reload
# In browser console:
localStorage.clear()
location.reload()
```

#### 7. Verify Modal Displays
1. Open application
2. Modal should appear with new version and features
3. Click "Got It" to dismiss
4. Modal should not reappear on page navigation
5. Modal should not reappear on reload

### Adding a Feature (Complete Example)

**Scenario:** You've built a new "Dark Mode" feature and want to announce it.

**Process:**

1. **Current config:**
```json
{
  "title": "What's New in Payouts Mailer",
  "version": "1.0.0",
  "releaseDate": "2024-01-12T00:00:00Z",
  "features": [
    {
      "id": "enhanced-dashboard",
      "title": "Enhanced Dashboard",
      "description": "Completely redesigned dashboard with real-time analytics",
      "icon": "Analytics"
    }
  ]
}
```

2. **Add feature and increment version:**
```json
{
  "title": "What's New in Payouts Mailer",
  "version": "1.1.0",  // ← Changed from 1.0.0
  "releaseDate": "2024-02-01T00:00:00Z",  // ← Changed to today
  "features": [
    {
      "id": "enhanced-dashboard",
      "title": "Enhanced Dashboard",
      "description": "Completely redesigned dashboard with real-time analytics",
      "icon": "Analytics"
    },
    {  // ← New feature
      "id": "dark-mode-support",
      "title": "Dark Mode Support",
      "description": "Switch to dark mode for comfortable viewing in low-light environments with automatic scheduling",
      "icon": "Settings"
    }
  ]
}
```

3. **Commit and deploy:**
```bash
git add src/data/features-config.json
git commit -m "feat: add dark mode feature to What's New modal (v1.1.0)"
npm run build
# Deploy...
```

4. **Verify:**
   - Modal appears on next user session with version 1.1.0
   - Both features are displayed
   - Dark mode icon appears correctly
   - Modal can be dismissed and doesn't reappear

### Removing or Archiving Features

When you want to stop showing a feature:

**Option 1: Remove from array** (simplest)
```json
{
  "version": "1.2.0",  // Increment version
  "features": [
    // Remove the feature entirely
  ]
}
```

**Option 2: Create archive document**
Keep a separate file for historical reference:

```json
// src/data/features-archive.json
{
  "archived_features": {
    "1.0.0": [
      { "id": "feature-1", ... }
    ],
    "1.1.0": [
      { "id": "feature-2", ... }
    ]
  }
}
```

## Common Issues and Solutions

### JSON Syntax Error
**Problem:** Browser console shows "Unexpected token"
**Solution:**
1. Validate JSON at https://jsonlint.com/
2. Check for missing commas between array items
3. Ensure all strings use double quotes
4. Check for trailing commas

### Modal Not Appearing After Update
**Problem:** Updated config but modal doesn't show
**Solution:**
1. Verify version number was incremented
2. Clear browser cache: `Ctrl+Shift+Del`
3. Clear localStorage: Open DevTools → Application → Storage → Clear All
4. Hard refresh: `Ctrl+Shift+R` (Cmd+Shift+R on Mac)
5. Check browser console for errors

### Icon Not Displaying
**Problem:** Feature shows but icon appears as placeholder
**Solution:**
1. Verify icon name is in the approved list
2. Check for typos in icon name
3. Icon names are case-sensitive
4. Some icons may not be available in your version of Material-UI

### Features Display But Modal Looks Wrong
**Problem:** Text truncated or layout broken
**Solution:**
1. Check description length (max 200 characters)
2. Check title length (max 50 characters)
3. Ensure no HTML or special characters in text
4. Validate JSON format

## localStorage Key Format

When users dismiss the modal, the dismissal state is stored in localStorage:

```javascript
// Key format: whats_new_modal_dismissed_v{VERSION}
localStorage['whats_new_modal_dismissed_v1.0.0'] = 'true'
localStorage['whats_new_modal_dismissed_v1.1.0'] = 'true'
localStorage['whats_new_modal_dismissed_v1.2.0'] = 'true'
```

**Important:** 
- Version in localStorage key must match exactly the `version` in features-config.json
- When you increment the version, a new localStorage key is created
- The modal will show again for the new version (keys don't match)
- This is how users see the updated features

## Configuration Checklist

When updating features-config.json, verify:

- [ ] All required fields are present (title, version, releaseDate, features)
- [ ] Version matches semantic versioning pattern (X.Y.Z)
- [ ] Version is incremented from the previous version
- [ ] Release date is today or the deployment date (ISO 8601 format)
- [ ] Each feature has all required fields (id, title, description, icon)
- [ ] Feature IDs are unique and lowercase with hyphens
- [ ] Feature titles are concise (1-50 characters)
- [ ] Feature descriptions are benefit-focused (10-200 characters)
- [ ] Feature icons are from the approved list
- [ ] JSON is valid (no syntax errors)
- [ ] Array has 1-10 features
- [ ] No trailing commas
- [ ] Strings use double quotes
- [ ] Configuration file is at correct location: src/data/features-config.json

## Summary

The What's New modal configuration system provides:
- ✅ Simple JSON format for feature descriptions
- ✅ Semantic versioning for version management
- ✅ Automatic localStorage tracking per version
- ✅ Easy developer updates without code changes
- ✅ Validation of all configuration fields
- ✅ Clear guidelines for each field
- ✅ Step-by-step update instructions
- ✅ Common troubleshooting solutions
