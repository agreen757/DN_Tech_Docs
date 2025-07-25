# Distro Nation CRM Development Setup & Deployment Guide

## Prerequisites

### System Requirements
- **Node.js**: Version 18.x or higher
- **npm**: Version 8.x or higher
- **Git**: Latest version for version control
- **VS Code**: Recommended IDE with extensions
- **Browser**: Chrome/Firefox with developer tools

### Required VS Code Extensions
```json
{
  "recommendations": [
    "esbenp.prettier-vscode",
    "bradlc.vscode-tailwindcss",
    "ms-vscode.vscode-typescript-next",
    "bradlc.vscode-tailwindcss",
    "formulahendry.auto-rename-tag",
    "christian-kohler.path-intellisense",
    "ms-vscode.vscode-json"
  ]
}
```

## Local Development Setup

### 1. Repository Setup
```bash
# Clone the repository
git clone [repository-url]
cd payouts-mailer-app

# Install dependencies
npm install

# Verify installation
npm list --depth=0
```

### 2. Environment Configuration

#### Required Environment Variables
Create `.env` file in project root:

```bash
# Firebase Configuration
REACT_APP_FIREBASE_API_KEY=your_firebase_api_key
REACT_APP_FIREBASE_AUTH_DOMAIN=distro-nation-crm.firebaseapp.com
REACT_APP_FIREBASE_PROJECT_ID=distro-nation-crm
REACT_APP_FIREBASE_STORAGE_BUCKET=distro-nation-crm.appspot.com
REACT_APP_FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
REACT_APP_FIREBASE_APP_ID=your_firebase_app_id

# AWS Amplify Configuration
REACT_APP_USER_POOL_ID=us-east-1_xxxxxxxxx
REACT_APP_USER_POOL_CLIENT_ID=your_user_pool_client_id

# API Keys
REACT_APP_DN_API_KEY=your-dn-api-key-here
REACT_APP_MAILGUN_API_KEY=your_mailgun_api_key
REACT_APP_MAILGUN_DOMAIN=mg.distro-nation.com
REACT_APP_OPENAI_API_KEY=your_openai_api_key
REACT_APP_YOUTUBE_API_KEY=your_youtube_api_key
REACT_APP_SPOTIFY_CLIENT_ID=your_spotify_client_id
REACT_APP_SPOTIFY_CLIENT_SECRET=your_spotify_client_secret
REACT_APP_SIMILARWEB_API_KEY=your_similarweb_api_key

# Development Settings
REACT_APP_ENV=development
REACT_APP_DEBUG=true
```

#### Environment Variable Security
- **Never commit `.env` files** to version control
- Use `.env.example` as template for required variables
- Store production keys in secure environment variable systems
- Rotate API keys regularly following security best practices

### 3. Firebase Setup

#### Firebase Project Configuration
1. **Create Firebase Project**: Visit [Firebase Console](https://console.firebase.google.com)
2. **Enable Authentication**: Configure email/password and Google OAuth
3. **Setup Firestore**: Initialize database with security rules
4. **Configure Hosting**: Setup hosting for deployment (optional)

#### Firebase Admin SDK Setup
```bash
# Download service account key
# Place in project root as: distro-nation-crm-firebase-adminsdk-fbsvc-[key].json

# Install Firebase Tools
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase project (if not already done)
firebase init
```

#### Firestore Security Rules
Update `firestore.rules`:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own campaigns
    match /campaigns/{campaignId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Allow authenticated users to read/write their preferences
    match /userPreferences/{userId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }
    
    // Admin-only access to analytics
    match /campaignAnalytics/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.token.admin == true;
    }
  }
}
```

### 4. AWS Configuration

#### AWS Amplify Setup
```bash
# Install Amplify CLI
npm install -g @aws-amplify/cli

# Configure Amplify
amplify configure

# Initialize Amplify project
amplify init

# Add authentication
amplify add auth

# Deploy authentication
amplify push
```

#### Cognito User Pool Configuration
```json
{
  "userPoolId": "us-east-1_xxxxxxxxx",
  "userPoolClientId": "your_client_id",
  "region": "us-east-1",
  "authenticationFlowType": "USER_SRP_AUTH",
  "passwordPolicy": {
    "minimumLength": 8,
    "requireUppercase": true,
    "requireLowercase": true,
    "requireNumbers": true,
    "requireSymbols": true
  }
}
```

### 5. Development Server Setup

#### Start Development Server
```bash
# Start the development server
npm start

# Server will start on http://localhost:3000
# Hot reload enabled for development changes
```

#### Development Scripts
```json
{
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject",
    "lint": "eslint src --ext .ts,.tsx",
    "lint:fix": "eslint src --ext .ts,.tsx --fix",
    "format": "prettier --write src/**/*.{ts,tsx,css,md}",
    "type-check": "tsc --noEmit",
    "analyze": "npm run build && npx bundle-analyzer build/static/js/*.js"
  }
}
```

### 6. Development Workflow

#### Code Quality Tools
**ESLint Configuration** (`.eslintrc.js`):
```javascript
module.exports = {
  extends: [
    'react-app',
    'react-app/jest',
    '@typescript-eslint/recommended'
  ],
  rules: {
    '@typescript-eslint/no-unused-vars': 'error',
    '@typescript-eslint/explicit-function-return-type': 'warn',
    'react-hooks/exhaustive-deps': 'warn'
  }
};
```

**Prettier Configuration** (`.prettierrc`):
```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": false,
  "printWidth": 80,
  "tabWidth": 2,
  "useTabs": false
}
```

#### Git Workflow
```bash
# Feature branch workflow
git checkout -b feature/your-feature-name
git add .
git commit -m "feat: add new feature description"
git push origin feature/your-feature-name

# Create pull request for code review
```

#### Pre-commit Hooks
Install Husky for pre-commit hooks:
```bash
npm install --save-dev husky lint-staged

# Setup pre-commit hook
npx husky add .husky/pre-commit "lint-staged"
```

**lint-staged configuration** (`package.json`):
```json
{
  "lint-staged": {
    "src/**/*.{ts,tsx}": [
      "eslint --fix",
      "prettier --write",
      "git add"
    ],
    "src/**/*.{css,md}": [
      "prettier --write",
      "git add"
    ]
  }
}
```

## Testing Setup

### Unit Testing Configuration
```bash
# Install additional testing dependencies
npm install --save-dev @testing-library/jest-dom @testing-library/user-event

# Run tests
npm test

# Run tests with coverage
npm test -- --coverage
```

### Testing Utilities Setup
**Test setup file** (`src/setupTests.ts`):
```typescript
import '@testing-library/jest-dom';
import { configure } from '@testing-library/react';

// Configure testing library
configure({ testIdAttribute: 'data-testid' });

// Mock Firebase
jest.mock('./utils/firebase', () => ({
  auth: {
    currentUser: null,
    signInWithEmailAndPassword: jest.fn(),
    signOut: jest.fn(),
  },
  db: {},
}));

// Mock environment variables
process.env.REACT_APP_DN_API_KEY = 'test-api-key';
```

### Example Component Test
```typescript
// src/components/auth/Login.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { AuthProvider } from '../../contexts/AuthContext';
import Login from './Login';

const renderWithProviders = (component: React.ReactElement) => {
  return render(
    <BrowserRouter>
      <AuthProvider>
        {component}
      </AuthProvider>
    </BrowserRouter>
  );
};

describe('Login Component', () => {
  test('renders login form', () => {
    renderWithProviders(<Login />);
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /sign in/i })).toBeInTheDocument();
  });

  test('validates required fields', async () => {
    renderWithProviders(<Login />);
    const submitButton = screen.getByRole('button', { name: /sign in/i });
    
    fireEvent.click(submitButton);
    
    expect(screen.getByText(/email is required/i)).toBeInTheDocument();
    expect(screen.getByText(/password is required/i)).toBeInTheDocument();
  });
});
```

## Build and Deployment

### Development Build
```bash
# Create development build
npm run build

# Serve build locally for testing
npx serve -s build -l 3000
```

### Production Build Process
```bash
# Clean previous builds
rm -rf build/

# Create optimized production build
NODE_ENV=production npm run build

# Analyze bundle size
npm run analyze

# Build output structure:
# build/
# ├── static/
# │   ├── css/
# │   ├── js/
# │   └── media/
# ├── index.html
# └── asset-manifest.json
```

### Environment-Specific Builds
```bash
# Development build
REACT_APP_ENV=development npm run build

# Staging build
REACT_APP_ENV=staging npm run build

# Production build
REACT_APP_ENV=production npm run build
```

## Deployment Strategies

### Firebase Hosting Deployment
```bash
# Initialize Firebase hosting
firebase init hosting

# Deploy to Firebase
firebase deploy --only hosting

# Deploy to specific project
firebase use your-project-id
firebase deploy --only hosting
```

**Firebase hosting configuration** (`firebase.json`):
```json
{
  "hosting": {
    "public": "build",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "/static/**",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000"
          }
        ]
      }
    ]
  }
}
```

### AWS S3 + CloudFront Deployment
```bash
# Build for production
npm run build

# Sync to S3 bucket
aws s3 sync build/ s3://your-bucket-name --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
```

### Vercel Deployment
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy to Vercel
vercel --prod

# Environment variables configured in Vercel dashboard
```

**Vercel configuration** (`vercel.json`):
```json
{
  "builds": [
    {
      "src": "package.json",
      "use": "@vercel/static-build",
      "config": {
        "distDir": "build"
      }
    }
  ],
  "routes": [
    {
      "src": "/static/(.*)",
      "headers": {
        "cache-control": "public, max-age=31536000"
      }
    },
    {
      "src": "/(.*)",
      "dest": "/index.html"
    }
  ]
}
```

## CI/CD Pipeline

### GitHub Actions Workflow
**Workflow file** (`.github/workflows/deploy.yml`):
```yaml
name: Build and Deploy CRM Application

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run linting
        run: npm run lint
      
      - name: Run type checking
        run: npm run type-check
      
      - name: Run tests
        run: npm test -- --coverage --watchAll=false
      
      - name: Upload coverage reports
        uses: codecov/codecov-action@v3

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build application
        run: npm run build
        env:
          REACT_APP_DN_API_KEY: ${{ secrets.REACT_APP_DN_API_KEY }}
          REACT_APP_FIREBASE_API_KEY: ${{ secrets.REACT_APP_FIREBASE_API_KEY }}
          # ... other environment variables
      
      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          projectId: distro-nation-crm
```

### Deployment Environments

#### Development Environment
- **URL**: `https://dev-crm.distro-nation.com`
- **Auto-deploy**: On push to `develop` branch
- **Features**: Debug logging, development API keys, hot reload

#### Staging Environment
- **URL**: `https://staging-crm.distro-nation.com`
- **Deploy**: Manual trigger from approved PRs
- **Features**: Production-like environment, staging API keys, performance testing

#### Production Environment
- **URL**: `https://crm.distro-nation.com`
- **Deploy**: Manual trigger from `main` branch
- **Features**: Production API keys, performance monitoring, error tracking

## Environment Management

### Configuration Management
**Environment-specific configuration** (`src/config/environments.ts`):
```typescript
interface EnvironmentConfig {
  apiBaseUrl: string;
  firebaseConfig: object;
  features: {
    debugMode: boolean;
    analyticsEnabled: boolean;
    aiFeatures: boolean;
  };
}

const environments: Record<string, EnvironmentConfig> = {
  development: {
    apiBaseUrl: 'https://dev-api.distro-nation.com',
    firebaseConfig: devFirebaseConfig,
    features: {
      debugMode: true,
      analyticsEnabled: false,
      aiFeatures: true,
    },
  },
  staging: {
    apiBaseUrl: 'https://staging-api.distro-nation.com',
    firebaseConfig: stagingFirebaseConfig,
    features: {
      debugMode: false,
      analyticsEnabled: true,
      aiFeatures: true,
    },
  },
  production: {
    apiBaseUrl: 'https://api.distro-nation.com',
    firebaseConfig: prodFirebaseConfig,
    features: {
      debugMode: false,
      analyticsEnabled: true,
      aiFeatures: true,
    },
  },
};

export const getEnvironmentConfig = (): EnvironmentConfig => {
  const env = process.env.REACT_APP_ENV || 'development';
  return environments[env];
};
```

### Feature Flags
```typescript
// src/utils/featureFlags.ts
export const featureFlags = {
  aiContentGeneration: process.env.REACT_APP_FEATURE_AI_CONTENT === 'true',
  advancedAnalytics: process.env.REACT_APP_FEATURE_ANALYTICS === 'true',
  betaFeatures: process.env.REACT_APP_FEATURE_BETA === 'true',
};

// Usage in components
const MyComponent = () => {
  if (featureFlags.aiContentGeneration) {
    return <AIContentGenerator />;
  }
  return <StandardContentEditor />;
};
```

## Performance Optimization

### Build Optimization
```json
{
  "scripts": {
    "build:analyze": "npm run build && npx webpack-bundle-analyzer build/static/js/*.js",
    "build:prod": "NODE_ENV=production npm run build"
  }
}
```

### Code Splitting Implementation
```typescript
// Lazy load components for better performance
const Dashboard = lazy(() => import('./pages/dashboard/Dashboard'));
const OutreachPage = lazy(() => import('./pages/outreach/OutreachPage'));

// Wrap in Suspense
<Suspense fallback={<CircularProgress />}>
  <Routes>
    <Route path="/dashboard" element={<Dashboard />} />
    <Route path="/outreach" element={<OutreachPage />} />
  </Routes>
</Suspense>
```

### Bundle Size Optimization
- **Tree shaking**: Enabled by default in Create React App
- **Chunk splitting**: Automatic vendor/app chunk separation
- **Asset optimization**: Image compression and lazy loading
- **CSS optimization**: Unused CSS removal

## Troubleshooting

### Common Development Issues

#### 1. Environment Variable Issues
```bash
# Check environment variables are loaded
console.log(process.env.REACT_APP_DN_API_KEY);

# Restart development server after .env changes
npm start
```

#### 2. Firebase Authentication Issues
```typescript
// Debug Firebase auth state
import { onAuthStateChanged } from 'firebase/auth';

onAuthStateChanged(auth, (user) => {
  console.log('Auth state changed:', user);
});
```

#### 3. API Integration Issues
```typescript
// Debug API calls
axios.interceptors.request.use(request => {
  console.log('Starting Request:', request);
  return request;
});

axios.interceptors.response.use(
  response => {
    console.log('Response:', response);
    return response;
  },
  error => {
    console.log('API Error:', error.response);
    return Promise.reject(error);
  }
);
```

#### 4. Build Issues
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# Clear build cache
rm -rf build/
npm run build
```

### Performance Debugging
```bash
# Analyze bundle size
npm run build
npx webpack-bundle-analyzer build/static/js/*.js

# Check for memory leaks
npm install --save-dev @welldone-software/why-did-you-render
```

This comprehensive development setup guide ensures developers can efficiently work on the Distro Nation CRM application with proper tooling, testing, and deployment procedures.