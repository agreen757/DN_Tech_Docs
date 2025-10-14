CMS Custom ID Cleanup
=====================

Overview
--------

The CMS Custom ID Cleanup Lambda runs daily to keep our managed channels in sync with YouTube Content ID. Each execution downloads the latest finance video report from our YouTube reporting S3 bucket, reconciles the ``customId`` values for partner-owned assets, and updates YouTube so every asset is tagged with the correct partner channel identifier. The function records results for auditability and exposes structured error information when updates fail.

The function lives at ``amplify/backend/function/cmsCustomidCleanup`` and is written in TypeScript. Build artifacts are emitted to ``src/`` for Lambda packaging.

Architecture
-----------

The solution is event-driven and relies on managed AWS services:

1. **EventBridge** rule schedules the Lambda on a daily cadence.
2. **AWS Lambda** coordinates report processing and writes diagnostic output to ``/tmp/output.json``.
3. **AWS AppSync** provides the partner channel catalog; API keys are automatically created and rotated through the Lambda if needed.
4. **AWS SSM Parameter Store** holds both the AppSync API key (``<Token_Key_Name>``) and the API key required to request OAuth tokens (``<Token_Key_Name>``).
5. **Amazon S3** hosts the YouTube reporting CSV (``<S3 Bucket>/reports/video_report_Indmusic_V_v1-3.csv``).
6. **API Gateway + Token Service** exchanges the API key for a short-lived access token used to call YouTube.
7. **YouTube Content ID API** receives PATCH requests that update the asset ``customId``.

Workflow
--------

1. Validate the scheduled EventBridge invocation and ensure basic guardrails (environment, payload shape) are satisfied.
2. Instantiate the GraphQL client to prime the AppSync connection, auto-provision or rotate API keys when necessary, and cache the partner channel list.
3. Use ``APIToken.getToken()`` to fetch an OAuth token via the token service API Gateway endpoint.
4. Download the latest video report from the YouTube financial reporting bucket and parse it with ``VideoReport_.processCsv``, keeping only partner-owned rows.
5. Filter the report again so that only videos whose ``channel_id`` exists in AppSync remain.
6. For each candidate, ensure the YouTube ``video_id`` matches the CSV ``custom_id``. When they match, invoke ``APIRequest.updateCMS`` with retry protection (``withRetry``) to patch the corresponding asset in YouTube.
7. Append successful updates to ``/tmp/output.json`` via ``ExportToLocalFile`` for ad-hoc inspection, and count successes/failures for the Lambda response.
8. On error, wrap details with ``createProblemDetails`` so CloudWatch logs and callers receive RFC-9457 structured diagnostics.

Components
----------

- **lib/index.ts**: Lambda handler that wires the entire cleanup flow together.
- **lib/classes.ts**:
  - ``APIToken``: Retrieves the token service API key from SSM and fetches OAuth tokens.
  - ``APIRequest``: Issues PATCH calls to the YouTube Content ID API.
  - ``GraphQL``: Manages AppSync access, including API key creation, validation, storage in SSM, and channel lookups.
  - ``VideoReport_``: Streams the S3 CSV into memory and normalizes rows.
  - ``FilterChannel``: Restricts the report to known partner channel IDs.
  - ``ExportToLocalFile``: Persists processed rows to ``/tmp`` during execution.
  - ``Logger``: Structured logging helper with masking and audit support.
- **lib/errorHandling.ts**: Provides retry helpers and RFC-9457 problem documents.
- **lib/types.ts**: Shared type definitions used throughout the cleanup process.

Configuration
------------

The Lambda expects the following environment variables (Amplify injects them during deployment):

.. code-block:: yaml

   # Core identifiers
   ENV: <stage>
   REGION: <REGION>
   API_ID: <appsync-api-id>

   # GraphQL endpoints
   API_DNBACKENDFUNCTIONNEW_GRAPHQLAPIENDPOINTOUTPUT: https://<appsync-endpoint>
   API_DISTROFMGRAPHQL_GRAPHQLAPIENDPOINTOUTPUT: https://<legacy-endpoint>

   # Optional key fallback
   API_DISTROFMGRAPHQL_GRAPHQLAPIKEYOUTPUT: <fallback-key>
   API_DNBACKENDFUNCTIONS_GRAPHQLAPIKEYOUTPUT: <fallback-key>

   # Downstream integrations
   S3_ACCESS_KEY: <only required for local runs>
   S3_SECRET_KEY: <only required for local runs>


The Lambda role must allow ``ssm:GetParameter``, ``ssm:PutParameter``, ``appsync:ListApiKeys``, ``appsync:CreateApiKey``, ``appsync:DeleteApiKey``, ``s3:GetObject`` on the report bucket, plus outbound HTTPS access to the token service and YouTube.

Deployment
---------

- Managed as part of the Amplify project under ``amplify/backend/function/cmsCustomidCleanup``.
- Built with ``npm run build`` (see ``package.json``) which compiles ``lib`` TypeScript sources into the ``src`` directory consumed by Lambda.
- The EventBridge rule is defined in the function's CloudFormation template (``cmsCustomidCleanup-cloudformation-template.json``) and points at the channel backfill completion events.

For local testing you can invoke the handler with Amplify:

.. code-block:: bash

   amplify function invoke cmsCustomidCleanup --event src/event.json

Ensure you provide valid environment variables and mocked SSM/S3 responses when running offline.

Security
-------

- API keys and tokens never persist in code or logs; the ``Logger`` masks sensitive fields automatically.
- API key rotation is built in through ``GraphQL.rotateApiKey``, ensuring stale AppSync keys are replaced and stored back into SSM.
- OAuth access tokens are fetched on-demand and not cached outside the Lambda invocation.
- The YouTube updates run under the ``<YT_Owner_ID>`` content owner using the scoped token from the token service.

Monitoring & Failure Handling
-----------------------------

- All major actions emit structured JSON logs (info, warn, error, audit) to CloudWatch for traceability.
- Transient errors when calling AppSync or YouTube use exponential backoff (``withRetry``), and failures are surfaced via RFC-9457 problem responses.
- The Lambda response includes counts for processed videos and errors; consider using these metrics to raise alerts if ``errorCount`` spikes or ``processedCount`` is zero.

Troubleshooting
---------------

- **API key errors**: Confirm the Lambda role can read/write the SSM parameters and manage AppSync API keys. Missing permissions surface as ``API_KEY_*`` log entries.
- **Token retrieval failures**: Verify the token service API Gateway (``<Secure_APIGateway_Endpoint>/ikey``) is reachable and the SSM token API key is populated.
- **S3 access denied**: Ensure the role grants ``s3:GetObject`` on ``<S3 Bucket>/reports/video_report_Indmusic_V_v1-3.csv``.
- **No channels processed**: Check that the channel backfill actually produced partner channels and that the CSV contains matching ``channel_id``/``custom_id`` pairs.
- **YouTube PATCH errors**: Review CloudWatch logs for the ``APIRequest.updateCMS`` responses; invalid tokens or content owner mappings typically return 401/403 errors.
