Claims Report Processor
======================

Overview
--------

The Claims Report Processor is a Docker-based Python application that downloads daily asset reports from the YouTube Reporting API, compares active_claims counts with the Aurora PostgreSQL database, generates difference reports, and emails stakeholders. The system runs weekly via AWS EventBridge (rate: 7 days).

Architecture
-----------

The system follows a sequential processing architecture:

1. **Data Collection**: Downloads daily asset full reports from YouTube Reporting API
2. **Data Processing**: Processes CSV data (~72-190MB, 79,000+ asset records) and updates Aurora PostgreSQL database
3. **Difference Analysis**: Compares active_claims counts with existing records to identify changes
4. **Notification**: Generates difference reports and emails them to stakeholders (see project ``docs/ses-email-flow.md`` for the SES/Mailgun flow)
5. **Scheduling**: Executes weekly via AWS EventBridge with ECS Fargate tasks

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

AWS Secrets Manager Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The application retrieves YouTube API credentials and configuration from AWS Secrets Manager:

- **distronation/lambda-auth-key**: Authorization token for API Gateway
- **distronation/apigateway-key**: API Gateway URL and x-api-key
- **distronation/youtube-api**: YouTube content owner ID
- **distronation/youtube-reporting-job**: YouTube Reporting API job ID

YouTube Reporting Job Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The system uses the YouTube Reporting API to download asset claims data. The job configuration is stored in AWS Secrets Manager under ``distronation/youtube-reporting-job``.

**Current Job Details (Updated Feb 15, 2026):**

- **Report Type**: ``content_owner_asset_a3`` (Daily Asset Full Report - system-managed)
- **Previous Report Type**: ``content_owner_asset_basic_a3`` (Incorrect report type, did not contain active_claims)
- **Job Created**: February 2026
- **Data Format**: CSV with required columns: active_claims, asset_type, artist, asset_title
- **File Size**: ~72-190MB compressed (gzip), ~79,000+ asset records
- **Job Management**: Auto-created and managed by YouTube (system-managed job)

**Important Notes:**

- The ``content_owner_asset_a3`` report is the Daily Asset Full Report and is system-managed by YouTube
- This report includes the critical ``active_claims`` column required for difference analysis
- Reports are generated daily by YouTube, typically available within 24-48 hours after job creation
- The job ID must be updated in Secrets Manager if a new job is created
- If no reports are available for the requested date range, the API returns an empty response ``{}``
- The download script now handles both gzipped and plain CSV formats automatically

**Troubleshooting Report Download Issues:**

If the download script fails with ``KeyError: 'reports'``:

1. Verify the job ID in Secrets Manager matches an active YouTube Reporting job
2. Check that reports exist for the job using the YouTube Reporting API
3. Ensure the date parameter is recent enough to have available reports
4. For new jobs, allow 24-48 hours for the first report to be generated

**Creating a New YouTube Reporting Job:**

If the current job becomes inactive or needs to be recreated:

.. code-block:: python

   # List available report types
   GET https://youtubereporting.googleapis.com/v1/reportTypes?onBehalfOfContentOwner={content_owner_id}
   
   # Create new job with CORRECT report type (content_owner_asset_a3)
   POST https://youtubereporting.googleapis.com/v1/jobs
   {
     "reportTypeId": "content_owner_asset_a3",
     "name": "Claims Report - Daily Asset Full Report"
   }
   
   # Update Secrets Manager with new job ID
   aws secretsmanager update-secret \
     --secret-id distronation/youtube-reporting-job \
     --secret-string '{"job_id":"<new-job-id>"}' \
     --region <aws-region>

**IMPORTANT:** Use ``content_owner_asset_a3`` (Daily Asset Full Report), NOT ``content_owner_asset_basic_a3``. The latter does not include the ``active_claims`` column required for difference analysis.

Deployment
---------

ECS Fargate Deployment (Production)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The application runs on AWS ECS Fargate with the following configuration:

**Task Definition (Revision 9 - Feb 15, 2026):**

- **Launch Type**: FARGATE
- **CPU**: 512 (0.5 vCPU)
- **Memory**: 2048MB (2GB)
- **Network Mode**: awsvpc
- **Container Image**: agreen757dn/claims-report:latest

**Memory Increase (Feb 15, 2026):**

The memory was increased from 512MB to 2GB to prevent OOM (out of memory) kills during CSV processing. The large dataset size (~72-190MB compressed, 79,000+ records) requires substantial memory for decompression and processing.

**EventBridge Scheduling:**

- **Schedule**: rate(7 days) - runs weekly
- **Target**: ECS Task via EventBridge rule
- **IAM Role**: EventBridge requires ``ecs:RunTask`` permissions and ``iam:PassRole`` for task execution role

**Docker Optimization:**

The ``.dockerignore`` file excludes CSV data files from the container image, reducing the image size by approximately 190MB. This speeds up deployment and reduces storage costs.

Docker Deployment (Local/Testing)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

**AWS Secrets Manager Secrets:**

- ``distronation/lambda-auth-key``: Authorization token for API Gateway
- ``distronation/apigateway-key``: API Gateway URL and x-api-key
- ``distronation/youtube-api``: YouTube content owner ID
- ``distronation/youtube-reporting-job``: YouTube Reporting API job ID

Troubleshooting
--------------

Common Issues and Solutions (Updated Feb 15, 2026)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Issue: Missing active_claims Column**

*Symptom:* Processing script fails with KeyError or missing column error for ``active_claims``.

*Root Cause:* Incorrect YouTube Reporting job type was configured (``content_owner_asset_basic_a3`` instead of ``content_owner_asset_a3``).

*Solution:* Ensure the job ID in Secrets Manager (``distronation/youtube-reporting-job``) points to a ``content_owner_asset_a3`` job (Daily Asset Full Report). This report type includes the required ``active_claims`` column.

**Issue: ECS Task OOM Killed**

*Symptom:* ECS task exits with code 137 (SIGKILL) or "OutOfMemory" error in CloudWatch logs.

*Root Cause:* Large CSV file processing (~72-190MB, 79,000+ records) exceeded the 512MB memory limit.

*Solution:* Task definition revision 9 increased memory to 2GB. Ensure you're using the latest task definition revision. To verify:

.. code-block:: bash

   aws ecs describe-task-definition --task-definition claims-report-processor --region <aws-region>

**Issue: Gzip Decompression Error**

*Symptom:* CSV download fails with gzip format error or "not a gzipped file" error.

*Root Cause:* YouTube sometimes returns plain CSV instead of gzipped CSV.

*Solution:* The download script (as of Feb 15, 2026) now auto-detects both gzipped and plain CSV formats. Ensure you're using the latest version of ``claims_report_download.py``.

**Issue: Container Image Too Large**

*Symptom:* Docker image size is unexpectedly large (>300MB) or includes old CSV data files.

*Root Cause:* CSV data files were being included in the Docker image.

*Solution:* Verify ``.dockerignore`` exists and includes:

.. code-block:: text

   *.csv
   *.csv.gz
   data/
   reports/

This reduces the image by ~190MB and prevents stale data from being baked into the image.

**Issue: EventBridge Not Triggering Task**

*Symptom:* Weekly scheduled task doesn't execute.

*Troubleshooting Steps:*

1. Check EventBridge rule is enabled in AWS Console
2. Verify the rule has ``ecs:RunTask`` permissions for the target ECS task
3. Check CloudWatch Logs for EventBridge invocation errors
4. Ensure the ECS cluster and task definition are in the same region as the EventBridge rule
5. Verify the IAM role has ``iam:PassRole`` for the task execution role

**Issue: KeyError: 'reports' in Download Script**

*Symptom:* Download script fails with ``KeyError: 'reports'`` when fetching YouTube data.

*Root Cause:* No reports available for the specified date range or incorrect job ID.

*Solution:*

1. Verify the job ID in Secrets Manager matches an active YouTube Reporting job
2. Ensure the job has generated reports (allow 24-48 hours for first report after job creation)
3. Check that the date parameter is within the range of available reports
4. Use the YouTube Reporting API to list available reports:

.. code-block:: bash

   # List reports for a job
   GET https://youtubereporting.googleapis.com/v1/jobs/{jobId}/reports?onBehalfOfContentOwner={contentOwnerId}

Performance Optimization
~~~~~~~~~~~~~~~~~~~~~~~

**Memory Usage:**

- Minimum recommended memory: 2GB (2048MB)
- Peak memory usage occurs during CSV decompression and pandas DataFrame operations
- Monitor CloudWatch Container Insights for memory utilization trends

**Processing Time:**

- Expected runtime: 5-15 minutes depending on dataset size
- Large datasets (190MB+) may take longer; adjust EventBridge timeout accordingly

**Network Bandwidth:**

- Download phase requires sufficient bandwidth for 72-190MB file transfer
- ECS tasks in private subnets require NAT Gateway for YouTube API access

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
