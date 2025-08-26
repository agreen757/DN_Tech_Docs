# Infrastructure Documentation

This repository contains technical documentation of the Distro Nation Environment

**System Architecture & Infrastructure:**

- AWS and Firebase architecture diagrams with data flows
- Resource inventory and configurations
- API documentation and service interfaces
- Database schemas and integration points
- Environment specifications (dev/staging/prod)

**Security & Compliance:**

- Security policies and access controls
- Compliance certifications and audit results
- Data protection measures and privacy policies
- Vulnerability assessments and remediation status
- Incident response procedures

**Operations & Monitoring:**

- Deployment procedures and CI/CD pipelines
- Monitoring, alerting, and performance metrics
- Troubleshooting guides and operational runbooks
- Change management and on-call procedures

**Cost & Risk Analysis:**

- AWS/Firebase cost breakdowns and optimization opportunities
- Technical debt inventory and risk assessment
- Dependency analysis and single points of failure
- Scalability limitations and performance bottlenecks

### Technical Roadmap

**Integration Planning:**

- System consolidation timeline and migration strategies
- Data migration plans and testing phases
- User access management integration

**Modernization Opportunities:**

- Technology stack upgrades and optimizations
- Performance improvements and cost reductions
- Security enhancements and scalability plans

**Team & Knowledge Transfer:**

- Team structure, key personnel, and expertise mapping
- Knowledge transfer plans and training requirements
- Process integration (development, QA, release management)

## Repository Structure

- `architecture/` - System architecture and design documents
- `applications/` - Application-specific documentation (CRM, YouTube CMS)
- `api/` - API specifications and integration documentation
- `deployment/` - Deployment guides and configurations
- `monitoring/` - Monitoring and alerting documentation
- `security/` - Security policies and procedures
- `networking/` - Network topology and configuration
- `runbooks/` - Operational procedures and troubleshooting guides
- `docs/` - Sphinx documentation configuration for Read the Docs

## Applications

### Distro Nation CRM Application

**Email Campaign Management & Financial Report Access**

The Distro Nation CRM serves as the primary administrative interface for managing customer communications and accessing financial reports. Built with React TypeScript and Material-UI, the application provides:

**Core Features:**
- **Email Campaign Creation**: Rich text editor with template management for financial and newsletter campaigns
- **User List Management**: Dynamic recipient targeting and segmentation
- **Campaign Analytics**: Performance tracking with delivery rates, open rates, and engagement metrics
- **S3 Reports Download**: Direct access to financial reports stored in AWS S3 with:
  - Hierarchical folder navigation with breadcrumb interface
  - Individual and bulk file downloads with ZIP creation
  - Secure authenticated access via AWS Cognito Identity Pool
  - Real-time download progress tracking and error handling

**Technical Stack:**
- Frontend: React 18.2.0 with TypeScript and Material-UI
- Authentication: Firebase Auth + AWS Amplify with Cognito integration
- File Operations: AWS S3 SDK v3 for direct S3 integration
- APIs: dn-api integration for user management and email delivery

### YouTube CMS Metadata Management Tool

**Centralized Content Management for YouTube Platform**

A Flask-based Python application that provides comprehensive metadata management for YouTube Content Management System operations, enabling bulk processing and synchronization of video content data.

**Core Features:**
- **Bulk Metadata Processing**: CSV import with validation and YouTube API synchronization
- **Advanced Search & Filtering**: Multi-criteria content discovery with real-time results
- **Report Processing**: Automated S3 report ingestion and analysis
- **Real-time Sync**: WebSocket-based notifications and live updates

**Technical Stack:**
- Backend: Python 3.8+ with Flask and SQLAlchemy ORM
- Database: PostgreSQL with advanced features (arrays, JSON columns)
- Real-time: Flask-SocketIO for WebSocket communication
- APIs: YouTube Data API v3 and YouTube CMS API integration

## Documentation

This repository is configured for [Read the Docs](https://readthedocs.org/) hosting with the following features:

- **Sphinx Documentation**: Professional documentation rendering with search and navigation
- **Markdown Support**: Full MyST parser support for existing Markdown files
- **Multiple Formats**: HTML, PDF, and HTMLZip outputs available
- **Interactive Features**: Copy buttons, responsive design, and enhanced styling

### Building Documentation Locally

To build the documentation locally:

```bash
cd docs/
pip install -r requirements.txt
sphinx-build -b html . _build/html
```

### Read the Docs Setup

1. Connect your GitHub repository to Read the Docs
2. The `.readthedocs.yaml` configuration will automatically build documentation
3. All existing Markdown files are preserved and rendered through MyST parser
