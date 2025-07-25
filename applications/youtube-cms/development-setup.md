# YouTube CMS Metadata Management Tool - Development Setup

## Overview

This document provides comprehensive instructions for setting up the YouTube CMS Metadata Management Tool development environment, including all dependencies, configuration requirements, and deployment procedures.

## Prerequisites

### System Requirements

**Operating System Support**
- macOS 10.15+ (Catalina or later)
- Ubuntu 18.04+ / Debian 10+
- Windows 10+ with WSL2
- Docker environment (any platform)

**Required Software Versions**
- Python 3.8+ (3.9+ recommended)
- PostgreSQL 13+ (14+ recommended)
- Node.js 14+ (for frontend tooling)
- Git 2.20+

### Development Tools

**Recommended IDE/Editors**
- Visual Studio Code with Python extension
- PyCharm Professional
- Vim/Neovim with Python LSP
- Any editor with Python language server support

**Essential Command Line Tools**
```bash
# macOS installation via Homebrew
brew install python@3.9 postgresql node git

# Ubuntu/Debian installation
sudo apt update
sudo apt install python3.9 python3.9-pip postgresql postgresql-contrib nodejs npm git

# Windows WSL2 (Ubuntu)
# Follow Ubuntu installation steps above
```

## Environment Setup

### 1. Repository Setup

**Clone Repository**
```bash
# Clone the repository
git clone https://github.com/agreen757/yt_cms_metadata_tool.git
cd yt_cms_metadata_tool

# Verify repository structure
ls -la
# Expected files: app.py, models.py, routes.py, requirements.txt, etc.
```

**Virtual Environment Creation**
```bash
# Create Python virtual environment
python3 -m venv venv

# Activate virtual environment
# macOS/Linux
source venv/bin/activate

# Windows
venv\Scripts\activate

# Verify activation (should show project directory)
which python
```

### 2. Python Dependencies

**Install Core Dependencies**
```bash
# Upgrade pip to latest version
pip install --upgrade pip

# Install project dependencies
pip install -r requirements.txt

# Install development dependencies (if requirements-dev.txt exists)
pip install -r requirements-dev.txt
```

**Core Dependencies Overview**
```txt
# Core framework dependencies
Flask==2.3.3
Flask-SQLAlchemy==3.0.5
Flask-Migrate==4.0.5
Flask-SocketIO==5.3.6

# Database dependencies
psycopg2-binary==2.9.7
alembic==1.12.0

# AWS integration
boto3==1.28.57
botocore==1.31.57

# HTTP and API dependencies
requests==2.31.0
urllib3==1.26.16

# Development and testing
pytest==7.4.2
pytest-flask==1.2.0
python-dotenv==1.0.0

# Security and authentication
cryptography==41.0.4
PyJWT==2.8.0

# Utility libraries
python-dateutil==2.8.2
pytz==2023.3
```

### 3. PostgreSQL Database Setup

**Database Installation and Configuration**

*macOS Setup*
```bash
# Install PostgreSQL via Homebrew
brew install postgresql
brew services start postgresql

# Create database user
createuser --interactive ytcms_user
# Choose: superuser? No, create databases? Yes, create roles? No

# Set password for user
psql postgres
ALTER USER ytcms_user PASSWORD 'your_secure_password';
\q
```

*Ubuntu/Debian Setup*
```bash
# Install PostgreSQL
sudo apt install postgresql postgresql-contrib

# Switch to postgres user and create application user
sudo -u postgres createuser --interactive ytcms_user
sudo -u postgres psql
ALTER USER ytcms_user PASSWORD 'your_secure_password';
\q
```

**Database Creation**
```bash
# Create development database
createdb -O ytcms_user youtube_cms_dev

# Create test database
createdb -O ytcms_user youtube_cms_test

# Verify database creation
psql -U ytcms_user -d youtube_cms_dev -c "SELECT version();"
```

**Advanced PostgreSQL Configuration**
```sql
-- Connect to your database
psql -U ytcms_user -d youtube_cms_dev

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For full-text search
CREATE EXTENSION IF NOT EXISTS "btree_gin"; -- For advanced indexing

-- Verify extensions
\dx
```

### 4. Environment Configuration

**Environment Variables Setup**
```bash
# Create .env file in project root
touch .env

# Add the following configuration
cat > .env << 'EOF'
# Flask Configuration
FLASK_APP=app.py
FLASK_ENV=development
FLASK_DEBUG=True
FLASK_SECRET_KEY=your-super-secret-development-key

# Database Configuration
DATABASE_URL=postgresql://ytcms_user:your_secure_password@localhost:5432/youtube_cms_dev
TEST_DATABASE_URL=postgresql://ytcms_user:your_secure_password@localhost:5432/youtube_cms_test

# YouTube API Configuration
YOUTUBE_API_KEY=your_youtube_api_key_here
YOUTUBE_CLIENT_ID=your_youtube_client_id
YOUTUBE_CLIENT_SECRET=your_youtube_client_secret

# AWS Configuration
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
S3_BUCKET_NAME=yt-cms-reports-dev
AWS_REGION=us-east-1

# Security Configuration
ENCRYPTION_KEY=generate_this_with_cryptography_fernet
JWT_SECRET_KEY=another-secret-key-for-jwt

# Logging Configuration
LOG_LEVEL=DEBUG
LOG_FILE=logs/youtube_cms.log

# Development Specific
RELOADER_TYPE=stat
RELOADER_EXTRA_FILES=templates,static
EOF
```

**Environment Variable Generation**
```python
# Generate secure keys (run in Python REPL)
from cryptography.fernet import Fernet
import secrets

# Generate Fernet encryption key
encryption_key = Fernet.generate_key()
print(f"ENCRYPTION_KEY={encryption_key.decode()}")

# Generate secure Flask secret key
flask_secret = secrets.token_urlsafe(32)
print(f"FLASK_SECRET_KEY={flask_secret}")

# Generate JWT secret key
jwt_secret = secrets.token_urlsafe(32)
print(f"JWT_SECRET_KEY={jwt_secret}")
```

### 5. External Service Configuration

**YouTube API Setup**
1. Visit [Google Cloud Console](https://console.cloud.google.com/)
2. Create new project or select existing project
3. Enable YouTube Data API v3
4. Create credentials (API Key and OAuth 2.0)
5. Add authorized redirect URIs for development:
   - `http://localhost:5000/auth/callback`
   - `http://127.0.0.1:5000/auth/callback`

**AWS S3 Setup**
```bash
# Install AWS CLI for configuration
pip install awscli

# Configure AWS credentials
aws configure
# Enter your Access Key ID, Secret Access Key, Region, and output format

# Create S3 bucket for development
aws s3 mb s3://yt-cms-reports-dev --region us-east-1

# Set bucket policy for development access
aws s3api put-bucket-policy --bucket yt-cms-reports-dev --policy file://dev-bucket-policy.json
```

*dev-bucket-policy.json*
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DevelopmentAccess",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::YOUR_ACCOUNT_ID:user/YOUR_IAM_USER"
            },
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::yt-cms-reports-dev",
                "arn:aws:s3:::yt-cms-reports-dev/*"
            ]
        }
    ]
}
```

## Database Initialization

### 1. Database Migration Setup

**Initialize Migration Repository**
```bash
# Initialize Flask-Migrate (only needed once)
flask db init

# Create initial migration
flask db migrate -m "Initial database setup"

# Apply migration to database
flask db upgrade

# Verify tables were created
psql -U ytcms_user -d youtube_cms_dev -c "\dt"
```

**Manual Database Initialization** (if migrations fail)
```sql
-- Connect to database
psql -U ytcms_user -d youtube_cms_dev

-- Create tables manually (from models.py)
CREATE TABLE video (
    id SERIAL PRIMARY KEY,
    video_id VARCHAR(20) UNIQUE NOT NULL,
    asset_id VARCHAR(50),
    title VARCHAR(200),
    custom_id VARCHAR(100),
    artist VARCHAR(200)[],
    genre VARCHAR(100)[],
    label VARCHAR(200),
    upc VARCHAR(20),
    isrc VARCHAR(12),
    privacy_status VARCHAR(20),
    claimed_status VARCHAR(10),
    other_owners_claiming TEXT,
    claimed_by_another_owner VARCHAR(10),
    embedding_allowed VARCHAR(10),
    ratings_allowed VARCHAR(10),
    comments_allowed VARCHAR(10),
    effective_policy TEXT DEFAULT '',
    time_published TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_short BOOLEAN DEFAULT FALSE,
    is_live_stream BOOLEAN DEFAULT FALSE,
    channel_display_name VARCHAR(100),
    hidden BOOLEAN DEFAULT FALSE,
    category VARCHAR(50),
    video_length INTEGER,
    third_party_ads_enabled VARCHAR(10),
    display_ads_enabled VARCHAR(10),
    sponsored_cards_enabled VARCHAR(10),
    overlay_ads_enabled VARCHAR(10),
    notes VARCHAR(500),
    administered BOOLEAN DEFAULT FALSE,
    administered_at TIMESTAMP
);

-- Create additional tables (channel, report, etc.)
-- See models.py for complete schema definitions

-- Create indexes for performance
CREATE INDEX idx_video_video_id ON video(video_id);
CREATE INDEX idx_video_category ON video(category);
CREATE INDEX idx_video_updated_at ON video(updated_at);
CREATE INDEX idx_video_administered ON video(administered);
```

### 2. Sample Data Loading

**Development Data Setup**
```python
# Create sample data script (dev_data.py)
from app import app
from database import db
from models import Video, Channel
from datetime import datetime

def create_sample_data():
    with app.app_context():
        # Sample videos
        sample_videos = [
            {
                'video_id': 'dQw4w9WgXcQ',
                'title': 'Sample Music Video 1',
                'artist': ['Artist Name'],
                'genre': ['Pop', 'Rock'],
                'label': 'Sample Records',
                'privacy_status': 'public',
                'category': 'Music'
            },
            {
                'video_id': 'jNQXAC9IVRw',
                'title': 'Sample Music Video 2',
                'artist': ['Another Artist'],
                'genre': ['Electronic'],
                'label': 'Digital Music Label',
                'privacy_status': 'public',
                'category': 'Music'
            }
        ]
        
        for video_data in sample_videos:
            video = Video(**video_data)
            db.session.add(video)
        
        # Sample channels
        sample_channels = [
            {
                'channel_id': 'UCuAXFkgsw1L7xaCfnd5JJOw',
                'name': 'Sample Music Channel',
                'subscriber_count': 1000000,
                'video_count': 150,
                'is_monetized': True
            }
        ]
        
        for channel_data in sample_channels:
            channel = Channel(**channel_data)
            db.session.add(channel)
        
        db.session.commit()
        print("Sample data created successfully!")

if __name__ == '__main__':
    create_sample_data()
```

```bash
# Run sample data creation
python dev_data.py
```

## Development Workflow

### 1. Running the Application

**Development Server**
```bash
# Ensure virtual environment is activated
source venv/bin/activate

# Set environment variables
export FLASK_APP=app.py
export FLASK_ENV=development
export FLASK_DEBUG=True

# Run development server
flask run

# Alternative: Run with custom host/port
flask run --host=0.0.0.0 --port=5000

# Or run directly with Python
python app.py
```

**Development Server with Hot Reload**
```bash
# Install watchdog for better file watching
pip install watchdog

# Run with file watching
flask run --reload

# Or use Python with debug mode
python -c "
from app import app
app.run(debug=True, host='0.0.0.0', port=5000)
"
```

### 2. Testing Setup

**Test Configuration**
```python
# Create conftest.py for pytest configuration
import pytest
import tempfile
import os
from app import app
from database import db
from models import Video, Channel

@pytest.fixture
def client():
    # Create temporary database
    db_fd, app.config['DATABASE'] = tempfile.mkstemp()
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('TEST_DATABASE_URL')
    
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
        yield client
    
    os.close(db_fd)
    os.unlink(app.config['DATABASE'])

@pytest.fixture
def auth_headers():
    # Mock authentication headers for testing
    return {'Authorization': 'Bearer test-token'}
```

**Run Tests**
```bash
# Install test dependencies
pip install pytest pytest-flask pytest-cov

# Run all tests
pytest

# Run tests with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest test_routes.py

# Run tests with verbose output
pytest -v

# Run tests and stop on first failure
pytest -x
```

### 3. Database Operations

**Common Database Commands**
```bash
# Create new migration
flask db migrate -m "Description of changes"

# Apply migrations
flask db upgrade

# Downgrade to previous migration
flask db downgrade

# View migration history
flask db history

# View current migration version
flask db current

# Reset database (WARNING: destroys all data)
flask db downgrade base
flask db upgrade
```

**Database Maintenance**
```bash
# Create database backup
pg_dump -U ytcms_user youtube_cms_dev > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore from backup
psql -U ytcms_user youtube_cms_dev < backup_20241201_120000.sql

# Reset database with sample data
dropdb -U ytcms_user youtube_cms_dev
createdb -O ytcms_user youtube_cms_dev
flask db upgrade
python dev_data.py
```

## Code Quality & Development Tools

### 1. Code Formatting and Linting

**Install Development Tools**
```bash
# Install code quality tools
pip install black flake8 isort mypy

# Install pre-commit hooks
pip install pre-commit
pre-commit install
```

**Configuration Files**

*.flake8*
```ini
[flake8]
max-line-length = 88
extend-ignore = E203, W503
exclude = 
    .git,
    __pycache__,
    venv,
    migrations
```

*pyproject.toml*
```toml
[tool.black]
line-length = 88
target-version = ['py38']
include = '\.pyi?$'
exclude = '''
/(
    \.eggs
  | \.git
  | \.hg
  | \.mypy_cache
  | \.venv
  | _build
  | buck-out
  | build
  | dist
  | migrations
)/
'''

[tool.isort]
profile = "black"
line_length = 88
```

**Code Quality Commands**
```bash
# Format code with Black
black app.py models.py routes.py

# Sort imports with isort
isort app.py models.py routes.py

# Check code with flake8
flake8 app.py models.py routes.py

# Type checking with mypy
mypy app.py models.py routes.py
```

### 2. Git Workflow

**Recommended Git Hooks**

*.pre-commit-config.yaml*
```yaml
repos:
  - repo: https://github.com/psf/black
    rev: 23.9.1
    hooks:
      - id: black
        language_version: python3.9

  - repo: https://github.com/pycqa/isort
    rev: 5.12.0
    hooks:
      - id: isort

  - repo: https://github.com/pycqa/flake8
    rev: 6.1.0
    hooks:
      - id: flake8

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
```

**Git Workflow Commands**
```bash
# Create feature branch
git checkout -b feature/new-video-filters

# Stage and commit changes
git add .
git commit -m "Add advanced video filtering capabilities"

# Push feature branch
git push origin feature/new-video-filters

# Create pull request (via GitHub CLI)
gh pr create --title "Add advanced video filtering" --body "Implements new filtering options for video management"
```

## Deployment Preparation

### 1. Production Environment Setup

**Environment Variables for Production**
```bash
# Production .env file
FLASK_ENV=production
FLASK_DEBUG=False
DATABASE_URL=postgresql://ytcms_user:prod_password@prod-db:5432/youtube_cms_prod
SECRET_KEY=your-production-secret-key

# Production AWS configuration
AWS_ACCESS_KEY_ID=prod_access_key
AWS_SECRET_ACCESS_KEY=prod_secret_key
S3_BUCKET_NAME=yt-cms-reports-prod

# Production YouTube API
YOUTUBE_API_KEY=prod_youtube_api_key
```

**Production Dependencies**
```bash
# Install production WSGI server
pip install gunicorn

# Create production requirements
pip freeze > requirements-prod.txt
```

### 2. Docker Configuration

**Dockerfile**
```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "app:app"]
```

**docker-compose.yml**
```yaml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "5000:5000"
    environment:
      - DATABASE_URL=postgresql://ytcms_user:password@db:5432/youtube_cms
    depends_on:
      - db

  db:
    image: postgres:14
    environment:
      POSTGRES_DB: youtube_cms
      POSTGRES_USER: ytcms_user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

**Run with Docker**
```bash
# Build and run with docker-compose
docker-compose up --build

# Run in detached mode
docker-compose up -d

# View logs
docker-compose logs -f web
```

## Troubleshooting

### Common Issues and Solutions

**Database Connection Issues**
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Restart PostgreSQL
sudo systemctl restart postgresql

# Check connection
psql -U ytcms_user -d youtube_cms_dev -c "SELECT 1;"
```

**Python Environment Issues**
```bash
# Recreate virtual environment
deactivate
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**Permission Issues**
```bash
# Fix file permissions
chmod +x app.py
chmod -R 755 static/
chmod -R 755 templates/

# Database permissions
sudo -u postgres psql
GRANT ALL PRIVILEGES ON DATABASE youtube_cms_dev TO ytcms_user;
```

This comprehensive development setup guide provides all necessary information to establish a fully functional development environment for the YouTube CMS Metadata Management Tool.