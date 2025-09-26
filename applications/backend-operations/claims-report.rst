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
4. **Notification**: Generates difference reports and emails them to stakeholders

Components
----------

- **app.py**: Main entry point that orchestrates the process
- **claims_report_download.py**: Handles YouTube API authentication and data retrieval
- **claims_report_process.py**: Processes data and updates the database

Configuration
------------

The application requires the following environment variables:

.. code-block:: yaml

   # Required for AWS Secrets Manager access
   AWS_REGION: us-east-1
   AWS_ACCESS_KEY_ID: [your-access-key]  # For local development only
   AWS_SECRET_ACCESS_KEY: [your-secret-key]  # For local development only
   
   # Application configuration
   DATABASE_URL: [postgres-connection-string]
   FLASK_SECRET_KEY: [secret-key]

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

The application requires specific IAM permissions to access secrets under the `distronation/*` prefix in AWS Secrets Manager:

.. code-block:: json

   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "secretsmanager:GetSecretValue",
           "secretsmanager:DescribeSecret"
         ],
         "Resource": [
           "arn:aws:secretsmanager:us-east-1:<AWS_ACCOUNT_ID>:secret:distronation/*"
         ]
       }
     ]
   }

For complete setup instructions, troubleshooting, and security best practices, see the documentation files in the project root.