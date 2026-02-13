# Development Setup

## Prerequisites

### Required Software

- **Python**: 3.11 or higher
- **PostgreSQL**: 15 or higher
- **Node.js**: 18+ (for frontend tooling, if applicable)
- **Git**: Latest version
- **AWS CLI**: For S3 access (optional, for local S3 testing)

### System Dependencies

**macOS:**
```bash
brew install python@3.11 postgresql@15
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install python3.11 python3.11-venv postgresql-15
```

**Windows:**
- Install Python from python.org
- Install PostgreSQL from postgresql.org
- Use WSL2 for a Linux-like environment (recommended)

---

## Initial Setup

### 1. Clone Repository

```bash
git clone [REPOSITORY_URL]
cd VideoClaimClassifier2
```

### 2. Create Virtual Environment

```bash
python3.11 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 3. Install Python Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

**Key Dependencies:**
```
Flask==3.0.0
Flask-SQLAlchemy==3.1.1
Flask-Security-Too==5.3.0
Flask-SocketIO==5.3.5
psycopg2-binary==2.9.9
boto3==1.34.0
alembic==1.13.0
pandas==2.1.4
firebase-admin==6.3.0
argon2-cffi==23.1.0
```

---

## Database Setup

### 1. Create PostgreSQL Database

```bash
# Start PostgreSQL service
# macOS: brew services start postgresql@15
# Ubuntu: sudo systemctl start postgresql

# Create database
psql -U postgres
CREATE DATABASE catalogtool;
CREATE USER cataloguser WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE catalogtool TO cataloguser;
\q
```

### 2. Configure Database URL

Create `.env` file in project root:

```bash
# Database
SQLALCHEMY_DATABASE_URI=postgresql://cataloguser:your_secure_password@localhost:5432/catalogtool
DATABASE_URL=postgresql://cataloguser:your_secure_password@localhost:5432/catalogtool

# Flask
FLASK_APP=app.py
FLASK_ENV=dev
SECRET_KEY=[GENERATE_RANDOM_KEY]
SECURITY_PASSWORD_SALT=[GENERATE_RANDOM_SALT]

# AWS S3 (optional for local dev)
AWS_ACCESS_KEY_ID=[YOUR_AWS_KEY]
AWS_SECRET_ACCESS_KEY=[YOUR_AWS_SECRET]
CUSTOM_AWS_ACCESS_KEY=[YOUR_AWS_KEY]
CUSTOM_AWS_SECRET_KEY=[YOUR_AWS_SECRET]

# Email (for password recovery)
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=true
MAIL_USERNAME=[YOUR_EMAIL]
MAIL_PASSWORD=[YOUR_APP_PASSWORD]
MAIL_DEFAULT_SENDER=noreply@distro-nation.com

# YouTube API (for metadata sync)
YOUTUBE_CLIENT_ID=[GOOGLE_OAUTH_CLIENT_ID]
YOUTUBE_CLIENT_SECRET=[GOOGLE_OAUTH_SECRET]
YOUTUBE_REFRESH_TOKEN=[REFRESH_TOKEN]

# Processing
MAX_CONCURRENT_REPORTS=2
```

**Generate Secure Keys:**
```python
import secrets
print("SECRET_KEY:", secrets.token_urlsafe(32))
print("SECURITY_PASSWORD_SALT:", secrets.token_urlsafe(16))
```

### 3. Run Database Migrations

```bash
# Initialize Alembic (if not already initialized)
flask db init

# Generate migration
flask db migrate -m "Initial schema"

# Apply migrations
flask db upgrade head
```

### 4. Create Initial Roles

```python
# Run in Flask shell
flask shell

>>> from app import db
>>> from models import Role

>>> admin_role = Role(name='admin', description='Administrator with full access')
>>> user_role = Role(name='user', description='Regular user')

>>> db.session.add(admin_role)
>>> db.session.add(user_role)
>>> db.session.commit()
>>> exit()
```

---

## Firebase Setup (Optional)

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create new project
3. Enable Authentication → Email/Password and Google providers
4. Get Web App config (apiKey, authDomain, projectId)

### 2. Download Service Account Key

1. Project Settings → Service Accounts
2. Generate new private key
3. Save as `firebase-service-account.json` in project root
4. Add to `.gitignore`

### 3. Configure Firebase in `.env`

```bash
FIREBASE_API_KEY=[YOUR_API_KEY]
FIREBASE_AUTH_DOMAIN=[YOUR_AUTH_DOMAIN]
FIREBASE_PROJECT_ID=[YOUR_PROJECT_ID]
```

---

## Running the Application

### Development Server

```bash
# Activate virtual environment
source venv/bin/activate

# Run Flask development server
flask run --reload --debug

# Or with python directly
python app.py
```

**Expected Output:**
```
 * Serving Flask app 'app.py'
 * Debug mode: on
 * Running on http://127.0.0.1:5000
```

### Background Queue Processor

The queue processor starts automatically with the Flask app. To run separately:

```python
# In app.py, ensure:
if __name__ == '__main__':
    queue_processor.start()
    socketio.run(app, debug=True)
```

---

## Testing

### Running Tests

```bash
# Install test dependencies
pip install pytest pytest-cov pytest-flask

# Run all tests
pytest

# Run with coverage
pytest --cov=. --cov-report=html

# Run specific test file
pytest tests/unit/test_models.py

# Run with verbose output
pytest -v
```

### Test Structure

```
tests/
├── unit/
│   ├── test_models.py        # Model validation
│   ├── test_filters.py       # Filter logic
│   └── test_utils.py         # Utility functions
├── integration/
│   ├── test_api.py           # API endpoints
│   ├── test_csv_processor.py # Report processing
│   └── test_s3_integration.py # S3 operations
└── e2e/
    ├── test_report_flow.py   # Full report pipeline
    └── test_user_workflow.py  # User journeys
```

### Example Test

```python
# tests/unit/test_models.py
import pytest
from app import app, db
from models import Video, User

@pytest.fixture
def client():
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
            yield client
            db.drop_all()

def test_video_creation(client):
    video = Video(
        video_id='test123',
        title='Test Video',
        channel_display_name='Test Channel'
    )
    db.session.add(video)
    db.session.commit()
    
    assert video.id is not None
    assert Video.query.filter_by(video_id='test123').first() is not None
```

---

## Docker Deployment

### Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Environment variables
ENV FLASK_APP=app.py
ENV FLASK_ENV=prod

# Expose port
EXPOSE 5000

# Run application
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "app:app"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "5000:5000"
    environment:
      FLASK_ENV: prod
      SQLALCHEMY_DATABASE_URI: postgresql://cataloguser:password@db:5432/catalogtool
      SECRET_KEY: ${SECRET_KEY}
      SECURITY_PASSWORD_SALT: ${SECURITY_PASSWORD_SALT}
    depends_on:
      - db
    volumes:
      - ./:/app
    restart: unless-stopped

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: catalogtool
      POSTGRES_USER: cataloguser
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped

volumes:
  postgres_data:
```

### Running with Docker

```bash
# Build and start services
docker-compose up --build

# Run migrations
docker-compose exec app flask db upgrade

# View logs
docker-compose logs -f app

# Stop services
docker-compose down
```

---

## Production Deployment

### WSGI Server (Gunicorn)

```bash
# Install gunicorn
pip install gunicorn

# Run with gunicorn
gunicorn --bind 0.0.0.0:5000 --workers 4 app:app

# With Socket.IO support
gunicorn --bind 0.0.0.0:5000 --workers 4 --worker-class eventlet app:app
```

### Systemd Service

Create `/etc/systemd/system/catalogtool.service`:

```ini
[Unit]
Description=Catalog Tool Flask Application
After=network.target postgresql.service

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/catalogtool
Environment="PATH=/var/www/catalogtool/venv/bin"
EnvironmentFile=/var/www/catalogtool/.env
ExecStart=/var/www/catalogtool/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 4 app:app

[Install]
WantedBy=multi-user.target
```

**Enable and start:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable catalogtool
sudo systemctl start catalogtool
sudo systemctl status catalogtool
```

### Nginx Reverse Proxy

Create `/etc/nginx/sites-available/catalogtool`:

```nginx
server {
    listen 80;
    server_name catalogtool.example.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket support
    location /socket.io {
        proxy_pass http://127.0.0.1:5000/socket.io;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

**Enable site:**
```bash
sudo ln -s /etc/nginx/sites-available/catalogtool /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## Troubleshooting

### Common Issues

#### Database Connection Error

**Problem:**
```
sqlalchemy.exc.OperationalError: could not connect to server
```

**Solution:**
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Verify connection string
psql -U cataloguser -d catalogtool -h localhost

# Check .env file has correct DATABASE_URL
```

#### Import Errors

**Problem:**
```
ModuleNotFoundError: No module named 'flask'
```

**Solution:**
```bash
# Ensure virtual environment is activated
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

#### Migration Errors

**Problem:**
```
alembic.util.exc.CommandError: Can't locate revision identified by 'xxxx'
```

**Solution:**
```bash
# Reset migrations (CAUTION: destroys data)
rm -rf migrations/
flask db init
flask db migrate -m "Initial schema"
flask db upgrade
```

#### S3 Access Denied

**Problem:**
```
botocore.exceptions.ClientError: An error occurred (AccessDenied)
```

**Solution:**
```bash
# Verify AWS credentials
aws s3 ls s3://youtube-reporting-main/reports/

# Check .env has correct AWS keys
# Ensure IAM user has s3:ListBucket and s3:GetObject permissions
```

---

## Development Best Practices

### Code Style

```bash
# Install development tools
pip install black flake8 mypy

# Format code
black .

# Lint code
flake8 app.py models.py api/

# Type checking
mypy app.py
```

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes and commit
git add .
git commit -m "Add new feature"

# Push to remote
git push origin feature/new-feature

# Create pull request for review
```

### Environment Variables

**Never commit:**
- `.env` file
- Firebase service account keys
- AWS credentials
- Database passwords

**Always use:**
- `.env.example` as template
- Environment-specific configs
- Secret management tools (AWS Secrets Manager, HashiCorp Vault)

---

## Database Management

### Backup

```bash
# Full backup
pg_dump -U cataloguser -d catalogtool -F c -b -v -f backup_$(date +%Y%m%d).dump

# Restore
pg_restore -U cataloguser -d catalogtool -v backup_20260213.dump
```

### Maintenance

```sql
-- Vacuum and analyze (run weekly)
VACUUM ANALYZE video;
VACUUM ANALYZE metadata_sync;

-- Check database size
SELECT pg_size_pretty(pg_database_size('catalogtool'));
```

---

## Summary

The Catalog Tool development environment requires:

- **Python 3.11+** with virtual environment
- **PostgreSQL 15+** for data storage
- **Flask** with SQLAlchemy, Flask-Security, Socket.IO
- **AWS S3** credentials for report storage (optional for local dev)
- **Firebase** configuration for OAuth authentication (optional)

The application runs as a Flask development server locally and uses Gunicorn + Nginx for production deployments. Docker Compose provides a containerized development environment with automatic database setup.

For production, use systemd services, Nginx reverse proxy, and proper secret management for credentials.
