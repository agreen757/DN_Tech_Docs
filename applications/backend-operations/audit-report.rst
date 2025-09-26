Audit Report System
==================

Overview
--------

The Audit Report System is a Docker-based Python application that processes payout audit data from Korrect API and YouTube, comparing channel payouts against custom ID mappings to identify discrepancies.

Architecture
-----------

The system follows a simple batch processing architecture:

1. **Data Collection**: Retrieves data from Korrect API and YouTube
2. **Data Processing**: Compares payouts and identifies discrepancies
3. **Reporting**: Generates CSV reports and sends email notifications

Components
----------

- **app.py**: Main entry point that runs the audit process
- **process_payout_audit.py**: Core processing logic
- **process_payout_audit_send_email.py**: Email notification functionality

Configuration
------------

The application accepts the following environment variables:

.. code-block:: yaml

   # Required for AWS Secrets Manager access
   AWS_REGION: <REGION>
   AWS_ACCESS_KEY_ID: [your-access-key]  # For local development only
   AWS_SECRET_ACCESS_KEY: [your-secret-key]  # For local development only
   
   # Processing parameters
   MONTH: 1  # Default if not specified
   YEAR: 2025  # Default if not specified

Deployment
---------

Docker Deployment
~~~~~~~~~~~~~~~~

The application is containerized using Docker:

.. code-block:: bash

   # Build the container
   docker build -t audit-report .
   
   # Run with Docker Compose
   docker compose up
   
   # Run with specific month/year
   MONTH=2 YEAR=2025 docker compose up

Security
-------

All sensitive credentials (database authentication, API keys, etc.) are retrieved at runtime from AWS Secrets Manager. For local development, AWS credentials can be provided via environment variables, but in production, IAM roles should be used to provide these credentials automatically.

Future Development
----------------

A comprehensive roadmap exists to transform this batch processing system into a scalable AWS-hosted web application with:

- React/Vue.js frontend hosted on S3 + CloudFront
- Backend API using Lambda functions and API Gateway
- DynamoDB for audit results storage
- AWS Cognito for authentication
- Comprehensive monitoring via CloudWatch

The full roadmap includes:

1. Backend API Development
2. External API Integration
3. Frontend Development
4. Authentication & Security
5. File Storage & Email Integration
6. Monitoring & Logging
7. Infrastructure as Code
8. Testing & Quality Assurance
9. Performance Optimization
10. Documentation & Deployment

See the TODO.md file in the repository for detailed implementation plans.