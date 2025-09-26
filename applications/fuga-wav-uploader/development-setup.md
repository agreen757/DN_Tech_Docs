# FUGA WAV Uploader Development Setup

## Prerequisites

### Required Software

- **Docker & Docker Compose** - For containerized development environment
- **Python 3.9+** - For backend development and testing
- **Node.js 16+** - For frontend development
- **Git** - For version control and repository management

### Required Accounts & Services

- **FUGA API Account** with valid distribution credentials
- **AWS Account** with ECS and ECR access for deployment
- **Domain Name** for production deployment (currently uses distro-nation.com)

### Development Tools (Recommended)

- **VS Code** with Python and TypeScript extensions
- **Docker Desktop** for container management
- **Postman** or similar for API testing
- **AWS CLI** for deployment and infrastructure management

## Environment Setup

### Repository Structure
```
FUGA Wav Uploader/
├── app.py                          # Main Flask application
├── config.py                       # Configuration management
├── requirements.txt                # Python dependencies
├── Dockerfile                      # Backend container configuration
├── docker-compose.yml              # Production setup
├── docker-compose.dev.yml          # Development setup
├── gunicorn.conf.py               # Gunicorn server configuration
├── test_fuga_api.py               # FUGA API test suite
├── dev.sh                         # Development startup script
├── CLAUDE.md                      # Development guidance
│
├── blueprints/                    # Flask blueprints (modular routes)
├── utils/                         # Shared utility modules
├── modules/fuga/                  # FUGA API Python client
├── frontend/                      # React frontend application
├── terraform/                     # Infrastructure as Code
└── utils/                         # Utility scripts
```

## Local Development Setup

### Method 1: Docker Compose Development Mode (Recommended)

#### 1. Repository Setup
```bash
# Clone the repository
git clone <repository-url>
cd "FUGA Wav Uploader"
```

#### 2. Environment Configuration
```bash
# Copy environment template files
cp .env.example .env
cp frontend/.env.example frontend/.env
```

#### 3. Backend Environment Variables (.env)
```bash
# FUGA API Configuration
FUGA_USERNAME=your_fuga_username
FUGA_PASSWORD=your_fuga_password
FUGA_API_URL=https://api.fuga.com

# Data Sync Configuration
FUGA_DATA_REFRESH_HOURS=24.0
FUGA_DATA_STARTUP_SYNC=true
FUGA_DATA_DIRECTORY=.

# Flask Configuration
FLASK_ENV=development
FLASK_DEBUG=True

# AWS Configuration (for deployment)
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_REGION=us-east-1
```

#### 4. Frontend Environment Variables (frontend/.env)
```bash
# Development API endpoint
REACT_APP_API_URL=http://localhost:5000
```

#### 5. Development Startup
```bash
# Start the optimized development environment
./dev.sh
```

The development script provides:
- **Hot Reload**: Automatic reloading for both frontend and backend changes
- **BuildKit Cache Mounts**: Faster dependency installation on rebuilds
- **Named Volumes**: Dependency caching for improved performance
- **Development Optimized Dockerfiles**: Faster build times
- **Live Code Editing**: No rebuilds required for code changes

#### 6. Access Points
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:5000
- **Health Check**: http://localhost:5000/health

### Method 2: Manual Development Setup

#### Backend Setup
```bash
# Create Python virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install Python dependencies
pip install -r requirements.txt

# Install FUGA module in development mode
cd modules/fuga
pip install -e .
cd ../..

# Set environment variables
export FLASK_ENV=development
export FLASK_DEBUG=True
export FUGA_USERNAME=your_fuga_username
export FUGA_PASSWORD=your_fuga_password

# Run the Flask application
python app.py
```

#### Frontend Setup
```bash
cd frontend

# Install Node.js dependencies
npm install

# Set environment variables
export REACT_APP_API_URL=http://localhost:5000

# Start development server
npm start
```

## Development Workflow

### Code Organization

#### Backend Development
- **Modular Architecture**: Use Flask blueprints for new features
- **Utility Functions**: Place shared code in `utils/` modules
- **Testing**: Write tests in `test_fuga_api.py` or create new test files
- **Configuration**: Manage settings through `config.py` and environment variables

#### Frontend Development
- **Component Structure**: Follow existing component organization patterns
- **TypeScript**: Use TypeScript for all new React components
- **Material-UI**: Follow established UI component patterns
- **State Management**: Use React hooks and context for state management

### Development Best Practices

#### Code Style
- **Python**: Follow PEP 8 coding standards
- **TypeScript/React**: Use ESLint and Prettier configurations
- **Import Organization**: Group imports logically (standard library, third-party, local)
- **Documentation**: Include docstrings for Python functions and JSDoc for TypeScript

#### Version Control
```bash
# Create feature branches for development
git checkout -b feature/new-feature-name

# Commit changes with descriptive messages
git add .
git commit -m "Add new feature: description of changes"

# Push to remote repository
git push origin feature/new-feature-name
```

#### Environment Management
- **Never commit sensitive data**: Use `.env` files that are git-ignored
- **Environment Templates**: Update `.env.example` files when adding new variables
- **Local Configuration**: Use `.env.local` for personal development settings

## Testing and Validation

### Backend Testing

#### API Test Suite
```bash
# Run comprehensive FUGA API tests
python test_fuga_api.py

# Run specific test functions
python -c "from test_fuga_api import test_fuga_login; test_fuga_login()"
python -c "from test_fuga_api import test_create_fuga_product; test_create_fuga_product()"
```

#### Manual API Testing
```bash
# Test health endpoint
curl http://localhost:5000/health

# Test FUGA authentication
curl -X POST http://localhost:5000/api/fuga/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test"}'

# Test file upload
curl -X POST http://localhost:5000/upload \
  -F "files=@test-audio.wav" \
  -F 'albumMetadata={"title":"Test Album"}'
```

#### Test Coverage Areas
- FUGA API authentication and session management
- Product (album) creation and metadata management
- Asset (track) creation and audio file upload
- Audio format validation and error handling
- Data synchronization (artists, labels, people)
- Error handling and user feedback

### Frontend Testing
```bash
cd frontend

# Run React test suite
npm test

# Run tests in watch mode for development
npm test -- --watch

# Generate test coverage report
npm test -- --coverage --watchAll=false
```

### Integration Testing

#### Docker Environment Testing
```bash
# Build and test complete environment
docker-compose -f docker-compose.dev.yml up --build

# Test container health
docker-compose exec backend curl http://localhost:5000/health
docker-compose exec frontend curl http://localhost:3000
```

#### End-to-End Testing Workflow
1. Start services with `./dev.sh` or `docker-compose up`
2. Authenticate with FUGA API credentials
3. Upload test WAV files through the frontend interface
4. Verify album and track creation in FUGA system
5. Test error handling with invalid files
6. Validate data synchronization functionality

## Debugging and Development Tools

### Backend Debugging
```bash
# Enable Flask debug mode
export FLASK_DEBUG=True

# Run with verbose logging
export FLASK_ENV=development
python app.py

# Python debugger integration
import pdb; pdb.set_trace()  # Add to code for breakpoints
```

### Frontend Debugging
```bash
# React Developer Tools (browser extension recommended)
# Chrome/Firefox: React Developer Tools

# Enable source maps for debugging
export GENERATE_SOURCEMAP=true
npm start

# Debug API calls
# Use browser Network tab or add console.log statements
```

### Docker Debugging
```bash
# View container logs
docker-compose logs backend
docker-compose logs frontend

# Execute commands in running containers
docker-compose exec backend bash
docker-compose exec frontend sh

# Debug container build issues
docker-compose build --no-cache backend
```

## Development Database and Data Management

### FUGA Reference Data Management
```bash
# Manual data synchronization
curl -X POST http://localhost:5000/api/fuga/refresh-data

# Check synchronization status
curl http://localhost:5000/api/fuga/data-status

# View cached data files
ls -la fuga_*.json
```

### Data Files Location
- `fuga_artists.json` - Cached artists data
- `fuga_labels.json` - Cached labels data  
- `fuga_people.json` - Cached people/contributors data
- `fuga_genres.json` - Cached genres data
- `*.backup` files - Backup copies of data files

## Common Development Issues and Solutions

### Port Conflicts
```bash
# Check if ports are in use
lsof -i :3000  # Frontend port
lsof -i :5000  # Backend port

# Kill processes using ports
kill -9 <PID>
```

### Docker Issues
```bash
# Clean Docker system
docker system prune -a

# Rebuild containers without cache
docker-compose build --no-cache

# Remove all containers and volumes
docker-compose down -v
```

### Environment Variable Issues
```bash
# Verify environment variables are loaded
printenv | grep FUGA
printenv | grep REACT_APP

# Source environment files manually
source .env
```

### FUGA API Connection Issues
- Verify credentials in `.env` file
- Check FUGA API status and availability
- Review network connectivity and firewall settings
- Validate API endpoint URLs and authentication

## Production Deployment Preparation

### Environment Variables for Production
```bash
# Production Flask settings
FLASK_ENV=production
FLASK_DEBUG=False

# Production frontend API URL
REACT_APP_API_URL=https://your-production-domain

# AWS deployment configuration
AWS_ACCOUNT_ID=your_aws_account_id
ECR_REGISTRY=your_ecr_registry_url
ECS_CLUSTER=wav-uploader-cluster
```

### Build and Deployment Scripts
```bash
# Backend deployment
./build-and-push.sh

# Frontend deployment  
cd frontend && ./build-and-push.sh

# Infrastructure deployment
./update_with_terraform.sh
```

### Pre-Deployment Checklist
- [ ] All environment variables configured for production
- [ ] FUGA API credentials validated
- [ ] AWS infrastructure provisioned via Terraform
- [ ] Docker images built and pushed to ECR
- [ ] SSL certificates configured
- [ ] Domain DNS settings configured
- [ ] Monitoring and logging configured
- [ ] Backup and rollback procedures tested

This comprehensive development setup ensures a smooth development experience with proper environment isolation, testing capabilities, and clear deployment pathways.