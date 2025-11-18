Claims Report System
==================

Overview
--------

The Claims Report System is a Docker-based Python application that downloads claims reports from YouTube API, processes the data, updates a PostgreSQL database, and generates difference reports that are emailed to stakeholders.

Architecture
-----------

The system follows a sequential processing architecture:

1. **Data Collection**: Downloads claims reports from YouTube API using OAuth tokens
2. **Data Processing**: Processes the data and updates PostgreSQL database
3. **Difference Analysis**: Compares new data with existing records to identify changes
4. **Notification**: Generates difference reports and emails them to stakeholders (see project ``docs/ses-email-flow.md`` for the SES/Mailgun flow)

Components
----------

- **app.py**: Main entry point that orchestrates the process
- **claims_report_download.py**: Handles YouTube API authentication and data retrieval
- **claims_report_process.py**: Processes data and updates the database
- **ses_email_service.py**: SES wrapper around boto3 with retry/backoff and structured error handling
- **ses_errors.py**: Error mapping for throttling, unverified recipients, and attachment limits

Configuration
------------

The application requires the following environment variables:

.. code-block:: yaml

   # Required for AWS Secrets Manager access
   AWS_REGION: [aws-region]
   AWS_ACCESS_KEY_ID: [your-access-key]  # For local development only
   AWS_SECRET_ACCESS_KEY: [your-secret-key]  # For local development only
   
   # Application configuration
   DATABASE_URL: [postgres-connection-string]
   FLASK_SECRET_KEY: [secret-key]
   EMAIL_PROVIDER: ses  # ses (default) or mailgun for fallback during migration
   SES_SECRET_NAME: [ses-secret-name]  # Secret containing aws_access_key_id, aws_secret_access_key, region
   AWS_SES_REGION: [ses-region]  # Region for SES operations
   MAILGUN_DOMAIN: [mailgun-domain]  # Only if EMAIL_PROVIDER=mailgun
   MAILGUN_API_KEY: [mailgun-api-key]  # Only if EMAIL_PROVIDER=mailgun
   SNS_TOPIC_ARN: [optional sns topic arn]  # Publishes send failures for alerting

Deployment
---------

Docker Deployment
~~~~~~~~~~~~~~~~

The application is containerized using Docker:

.. code-block:: bash

   # Build the container
   docker build -t agreen757dn/claims-report:latest .
   
   # Run with Docker Compose
   docker-compose up
   
   # Build and deploy to production
   sh deploy.sh

Development
----------

Local Setup
~~~~~~~~~~

.. code-block:: bash

   # Install dependencies
   make install  # or pip3 install -r requirements.txt
   
   # Run complete application
   make run  # or python3 app.py
   
   # Run individual components
   make download  # python3 claims_report_download.py 2022-10-01T00:00:00Z
   make process   # python3 claims_report_process.py

Security
-------

All sensitive credentials (database authentication, API keys, etc.) are retrieved at runtime from AWS Secrets Manager. For local development, AWS credentials can be provided via environment variables, but in production, IAM roles should be used to provide these credentials automatically.

Email Delivery (SES with Mailgun fallback)
------------------------------------------

- **Primary provider**: SES is enabled by setting ``EMAIL_PROVIDER=ses``. Credentials are loaded from Secrets Manager (``SES_SECRET_NAME``) which must contain ``aws_access_key_id``, ``aws_secret_access_key``, and ``region``.
- **Fallback provider**: Setting ``EMAIL_PROVIDER=mailgun`` keeps backward compatibility with existing Mailgun credentials. Mailgun keys remain in Secrets Manager but are only read when explicitly selected.
- **SES requirements**:

  - Verify sender and recipient identities in the configured region; SES sandbox mode requires all recipients to be verified.
  - IAM permissions must include ``ses:SendEmail`` and ``ses:SendRawEmail`` plus Secrets Manager access scoped to this application’s secrets.
  - Optional: ``SNS_TOPIC_ARN`` captures failures from both providers for alerting.

The ``SESEmailService`` module centralizes retries, timeout configuration, and error mapping (throttling, unverified address, attachment size). Errors are logged with provider context so rollbacks to Mailgun can be traced.

For complete setup instructions, troubleshooting, and security best practices, see the documentation files in the project root.
