# CRM IAM Security Configuration

## Overview

This document outlines the Identity and Access Management (IAM) security configuration for the CRM application's outreach functionality. The implementation follows AWS security best practices with a least-privilege approach, using role-based access control with function-specific permissions.

## Architecture Summary

The CRM outreach system uses a **three-tier IAM role architecture** that segregates permissions based on Lambda function responsibilities:

1. **Email Sender Role** - For email sending functions
2. **Data Reader Role** - For analytics and tracking data retrieval
3. **Webhook Processor Role** - For webhook event processing

## IAM Roles Configuration

### 1. Email Sender Role (`outreach-email-sender-role`)

**Purpose**: Handles email sending operations through external email service providers.

**Functions Using This Role**:
- `outreach-sendEmail`
- `outreach-sendTemplateEmail`

**Attached Policies**:
- `AWSLambdaBasicExecutionRole` (AWS Managed) - CloudWatch logging
- `outreach-mailgun-secrets-policy` (Custom) - Email service credentials access
- `outreach-firebase-secrets-policy` (Custom) - Authentication service credentials

**Trust Policy**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### 2. Data Reader Role (`outreach-data-reader-role`)

**Purpose**: Retrieves campaign statistics and tracking data from external APIs.

**Functions Using This Role**:
- `outreach-campaignStats`
- `outreach-trackingData`

**Attached Policies**:
- `AWSLambdaBasicExecutionRole` (AWS Managed) - CloudWatch logging
- `outreach-mailgun-secrets-policy` (Custom) - Email service API access
- `outreach-firebase-secrets-policy` (Custom) - Authentication service credentials

**Key Security Feature**: No database write permissions - read-only access to external APIs.

### 3. Webhook Processor Role (`outreach-webhook-processor-role`)

**Purpose**: Processes incoming webhook events and stores tracking data.

**Functions Using This Role**:
- `outreach-webhookHandler`

**Attached Policies**:
- `AWSLambdaBasicExecutionRole` (AWS Managed) - CloudWatch logging
- `outreach-webhook-dynamodb-policy` (Custom) - Database write access

**Key Security Feature**: No external API access - isolated to webhook processing and database operations.

## Custom IAM Policies

### Email Service Secrets Policy (`outreach-mailgun-secrets-policy`)

**Purpose**: Provides access to email service provider credentials.

**Permissions**:
- `secretsmanager:GetSecretValue` on specific email service secret

**Resource Scope**: Limited to specific secret ARN only.

### Authentication Service Secrets Policy (`outreach-firebase-secrets-policy`)

**Purpose**: Provides access to authentication service credentials for user verification.

**Permissions**:
- `secretsmanager:GetSecretValue` on authentication service account secret

**Resource Scope**: Limited to authentication service secret pattern.

### Webhook Database Policy (`outreach-webhook-dynamodb-policy`)

**Purpose**: Enables webhook event storage in campaign tracking database.

**Permissions**:
- `dynamodb:PutItem` - Create new tracking records
- `dynamodb:UpdateItem` - Update existing tracking records

**Resource Scope**: Limited to specific campaign tracking table ARN.

**Security Note**: Write-only access - no read, delete, or scan permissions.

## AWS Managed Policies Used

### AWSLambdaBasicExecutionRole

**Applied To**: All three IAM roles

**Purpose**: Standard AWS managed policy for Lambda CloudWatch logging.

**Permissions**:
- `logs:CreateLogGroup`
- `logs:CreateLogStream`
- `logs:PutLogEvents`

**Rationale**: Using AWS managed policy ensures automatic updates and follows AWS best practices for Lambda logging.

## Security Implementation Details

### Least Privilege Principles Applied

1. **Function-Specific Roles**: Each Lambda function type has its own role with only required permissions.

2. **Resource-Scoped Policies**: All custom policies specify exact resource ARNs rather than wildcards.

3. **Action-Specific Permissions**: Only necessary actions are granted (e.g., webhook processor has write-only database access).

4. **No Cross-Function Access**: Email functions cannot access database, webhook processor cannot access external APIs.

### Security Boundaries

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Email Sender   │    │  Data Reader    │    │ Webhook Processor│
│     Role        │    │     Role        │    │     Role        │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • Email API     │    │ • Email API     │    │ • Database      │
│ • Auth Service  │    │ • Auth Service  │    │   Write Only    │
│ • CloudWatch    │    │ • CloudWatch    │    │ • CloudWatch    │
│                 │    │ (Read Only)     │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Access Control Matrix

| Resource Type | Email Sender | Data Reader | Webhook Processor |
|---------------|--------------|-------------|-------------------|
| Email Service API | ✅ Read | ✅ Read | ❌ No Access |
| Auth Service | ✅ Read | ✅ Read | ❌ No Access |
| Campaign Database | ❌ No Access | ❌ No Access | ✅ Write Only |
| CloudWatch Logs | ✅ Write | ✅ Write | ✅ Write |

## IAM Access Analyzer Compliance

### Analysis Results

- **External Access Findings**: None - no resources are accessible outside the AWS account
- **Unused Access**: Minimal - all policies are actively used by their respective functions
- **Overprivileged Access**: None detected - each role has only necessary permissions

### Compliance Status

✅ **Least Privilege**: Each role has minimum required permissions
✅ **Resource Scoping**: All policies use specific resource ARNs
✅ **Function Isolation**: No cross-function access capabilities
✅ **External Access Control**: No unintended external access
✅ **AWS Best Practices**: Uses managed policies where appropriate

## Monitoring and Auditing

### CloudWatch Integration

All Lambda functions log to CloudWatch with role-specific log groups:
- `/aws/lambda/outreach-sendEmail`
- `/aws/lambda/outreach-sendTemplateEmail`
- `/aws/lambda/outreach-campaignStats`
- `/aws/lambda/outreach-trackingData`
- `/aws/lambda/outreach-webhookHandler`

### Security Monitoring

- **IAM Access Analyzer**: Continuous monitoring for policy changes and access patterns
- **CloudWatch Logs**: All function executions and errors are logged
- **AWS CloudTrail**: API calls and policy changes are tracked (when enabled)

## Maintenance and Updates

### Policy Review Schedule

- **Quarterly**: Review IAM Access Analyzer findings
- **After Function Updates**: Verify permissions are still appropriate
- **Security Incidents**: Immediate review and adjustment if needed

### Update Procedures

1. **Policy Changes**: Use Terraform to manage all IAM resources
2. **Testing**: Validate function operation after policy updates
3. **Documentation**: Update this document with any changes
4. **Approval**: Security team review for significant changes

## Terraform Implementation

All IAM resources are managed through Infrastructure as Code using Terraform:

- **Roles**: Defined with appropriate trust policies
- **Policies**: Custom policies with specific resource ARNs
- **Attachments**: Managed policy attachments to roles
- **Data Sources**: References to AWS managed policies

### Key Terraform Resources

- `aws_iam_role` - IAM role definitions
- `aws_iam_policy` - Custom policy definitions
- `aws_iam_role_policy_attachment` - Policy-to-role associations
- `data.aws_iam_policy` - AWS managed policy references

## Security Recommendations

### Current Implementation Strengths

1. **Role Segregation**: Clear separation of concerns between function types
2. **Minimal Permissions**: Each role has only necessary permissions
3. **Resource Scoping**: Policies target specific resources, not wildcards
4. **Standard Practices**: Uses AWS managed policies where appropriate

### Future Enhancements

1. **Condition-Based Policies**: Consider adding time-based or IP-based conditions
2. **Cross-Account Access**: Implement if multi-account architecture is adopted
3. **Service Control Policies**: Add organizational-level controls if using AWS Organizations
4. **Permission Boundaries**: Consider implementing for additional security layers

## Troubleshooting

### Common Issues

1. **Access Denied Errors**: Check if function is using correct role and policy attachments
2. **Secret Access Issues**: Verify secret ARN matches policy resource specification
3. **Database Access Issues**: Confirm DynamoDB table ARN in policy matches actual table

### Validation Commands

```bash
# List role policies
aws iam list-attached-role-policies --role-name [role-name]

# Check policy document
aws iam get-policy-version --policy-arn [policy-arn] --version-id v1

# Verify function role assignment
aws lambda get-function --function-name [function-name]
```

## Conclusion

The CRM IAM security configuration implements a robust, least-privilege access control system that:

- Segregates permissions by function responsibility
- Uses specific resource ARNs to limit access scope
- Follows AWS security best practices
- Maintains operational efficiency while maximizing security

This configuration provides strong security boundaries while enabling the CRM outreach functionality to operate effectively.