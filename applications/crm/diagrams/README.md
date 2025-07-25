# CRM Application Architecture Diagrams

This directory contains visual architecture diagrams for the Distro Nation CRM application, created using AWS Diagrams to illustrate system components, data flows, and deployment patterns.

## Available Diagrams

### 1. CRM Application Architecture (`crm-architecture.png`)
**Purpose**: High-level overview of the CRM application architecture and its integration with Distro Nation infrastructure

**Components Illustrated**:
- **Frontend Layer**: React CRM application with CloudFront CDN
- **Authentication**: Firebase Auth and AWS Cognito integration
- **API Gateway**: dn-api endpoint management
- **Backend Services**: Lambda functions for user, email, and analytics services
- **Data Layer**: Aurora PostgreSQL, Firestore, and S3 storage
- **Monitoring**: CloudWatch integration

**Use Cases**: Understanding overall system architecture, onboarding new developers, system planning discussions

### 2. Email Campaign Flow (`email-campaign-flow.png`)
**Purpose**: Detailed workflow showing how email campaigns are created, processed, and tracked

**Flow Illustrated**:
1. CRM Admin creates campaign via MailerTemplate component
2. System fetches recipient list from dn_users_list API
3. Campaign data processed by Email Campaign Lambda
4. Email delivery handled through Mailgun API integration
5. Real-time analytics updated and displayed in dashboard

**Use Cases**: Understanding email campaign lifecycle, troubleshooting campaign issues, process optimization

### 3. Authentication & Security Flow (`authentication-security-flow.png`)
**Purpose**: Multi-provider authentication architecture and security patterns

**Security Components**:
- **Primary Authentication**: Firebase Auth for user identity
- **Enhanced Security**: AWS Cognito with MFA for admin access
- **API Security**: Custom Lambda authorizer and JWT token management
- **Session Management**: Secure token storage and validation

**Use Cases**: Security audits, authentication troubleshooting, access control planning

### 4. Data Flow & Integrations (`data-flow-integrations.png`)
**Purpose**: Data movement between external APIs, processing services, and storage systems

**Integration Points**:
- **External APIs**: OpenAI, YouTube, Spotify, SimilarWeb, Mailgun
- **Processing Services**: Content generation, analytics aggregation, email services
- **Storage Systems**: Aurora PostgreSQL, real-time databases, S3 file storage
- **Caching Strategy**: Local cache and session storage optimization

**Use Cases**: API integration planning, performance optimization, data architecture reviews

### 5. Deployment Architecture (`deployment-architecture.png`)
**Purpose**: CI/CD pipeline and infrastructure deployment patterns

**Deployment Pipeline**:
- **Development**: GitHub repository management
- **CI/CD**: GitHub Actions with automated build processes
- **Frontend Deployment**: Firebase Hosting with CloudFront CDN
- **Backend Infrastructure**: API Gateway, Lambda functions, Aurora database
- **Monitoring**: CloudWatch logs and application monitoring

**Use Cases**: DevOps planning, deployment troubleshooting, infrastructure scaling decisions

## Diagram Creation Details

### Technology Stack
- **Generation Tool**: AWS Diagrams Python package via MCP
- **Format**: PNG images with transparent backgrounds
- **Layout**: Mixed top-bottom (TB) and left-right (LR) orientations
- **Components**: AWS, Firebase, and Generic icons for comprehensive representation

### Design Principles
- **Logical Clustering**: Related components grouped for clarity
- **Clear Data Flow**: Directional arrows showing information movement
- **Consistent Styling**: Standardized icons and color schemes
- **Scalable Layout**: Readable at different zoom levels

### Usage Guidelines

#### For Developers
- Reference these diagrams when implementing new features
- Use for understanding system dependencies and integration points
- Include in technical design documents and code reviews

#### For System Administrators
- Use for troubleshooting system issues and performance optimization
- Reference during security audits and access control reviews
- Include in disaster recovery and operational procedures

#### For Stakeholders
- Use for high-level system understanding and project planning
- Include in presentations and business requirement discussions
- Reference for budget planning and resource allocation decisions

## Maintenance

### Updates Required When:
- New services or APIs are integrated
- Authentication methods are modified
- Database schema or infrastructure changes occur
- Deployment processes are updated
- Security policies are revised

### Regeneration Process
1. Update diagram code with new components or relationships
2. Regenerate using AWS Diagrams MCP tool
3. Update this README with any new diagram descriptions
4. Commit changes to documentation repository

## Integration with Documentation

These diagrams complement the written CRM documentation:
- **Architecture Overview**: References `crm-architecture.png`
- **API Integrations**: References `data-flow-integrations.png`
- **Authentication Flows**: References `authentication-security-flow.png`
- **Development Setup**: References `deployment-architecture.png`
- **Data Flow Patterns**: References `email-campaign-flow.png`

## File Locations
All diagrams are stored in this directory (`/Users/adriangreen/Documents/Empire/applications/crm/diagrams/`) and are version-controlled as part of the Empire technical documentation repository.

For questions about these diagrams or requests for additional visualizations, please refer to the main CRM documentation or contact the development team.