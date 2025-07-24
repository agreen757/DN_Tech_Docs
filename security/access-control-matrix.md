# Access Control Matrix

## Overview
This document provides a comprehensive overview of access controls implemented across the Distro Nation infrastructure, including role-based access control (RBAC), AWS IAM policies, Firebase authentication, and API-level permissions. This matrix serves as the authoritative source for understanding who has access to what resources and under what conditions.

## Executive Summary

### Current Access Control Status
- **Mixed Implementation**: Combination of open endpoints, AWS IAM, and Firebase Auth
- **Security Gaps**: dn-api endpoints lack authentication (high risk)
- **Complexity**: Multiple authentication mechanisms across different services
- **Coverage**: ~70% of services have proper access controls

### Immediate Security Concerns
1. **Open API Endpoints**: dn-api allows unrestricted access to administrative functions
2. **No Centralized Identity Management**: Multiple identity providers without unified control
3. **Inconsistent Authorization**: Different permission models across services
4. **Limited Audit Trail**: Some systems lack comprehensive access logging

## Role-Based Access Control (RBAC) Framework

### Defined Roles

| Role | Description | Scope | Risk Level |
|------|-------------|-------|------------|
| **System Administrator** | Full infrastructure access | AWS account, Firebase project | Critical |
| **API Developer** | API deployment and configuration | Lambda, API Gateway, AppSync | High |
| **Content Manager** | Content and artist management | Application-level data access | Medium |
| **Analytics Viewer** | Read-only access to metrics and reports | Reporting systems only | Low |
| **Artist User** | Artist-specific content management | Own content only | Low |
| **End User** | Standard application access | Limited to public endpoints | Low |

### Role Inheritance Model
```
System Administrator
└── API Developer  
    └── Content Manager
        └── Analytics Viewer
            └── Artist User
                └── End User
```

## AWS IAM Access Control

### Service Account Roles

#### Lambda Execution Roles
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds-data:BatchExecuteStatement",
        "rds-data:BeginTransaction", 
        "rds-data:CommitTransaction",
        "rds-data:ExecuteStatement",
        "rds-data:RollbackTransaction"
      ],
      "Resource": "arn:aws:rds:<REGION>:<AWS_ACCOUNT_ID>:cluster:database-2-cluster"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:<REGION>:<AWS_ACCOUNT_ID>:secret:prod/distronation/*"
    }
  ]
}
```

#### API Gateway IAM Authentication
- **Service**: distronationfmGeneralAccess
- **Authentication**: AWS Signature Version 4
- **Resource ARN**: `arn:aws:execute-api:<REGION>:<AWS_ACCOUNT_ID>:<API_GATEWAY_ID_1>/main/*/*`
- **Required Permissions**: `execute-api:Invoke`

### Human User Access

#### Administrative Access
| AWS Service | Access Method | MFA Required | Justification Required |
|-------------|---------------|--------------|----------------------|
| AWS Console | IAM User/Role | ✅ Yes | ✅ Yes |
| AWS CLI | Access Keys | ❌ No (Gap) | ❌ No (Gap) |
| CloudFormation | Console/CLI | ✅ Yes | ✅ Yes |
| Lambda Functions | Console/CLI | ✅ Yes | ❌ No (Gap) |
| RDS Management | Console only | ✅ Yes | ✅ Yes |

#### Development Team Access
| Resource | Developer Role | Read Access | Write Access | Admin Access |
|----------|----------------|-------------|--------------|--------------|
| Lambda Functions | ✅ Yes | ✅ Yes | ✅ Yes | ❌ No |
| API Gateway | ✅ Yes | ✅ Yes | ✅ Yes | ❌ No |
| S3 Buckets | ✅ Yes | ✅ Yes | 🟡 Limited | ❌ No |
| Aurora Database | ❌ No | ❌ No | ❌ No | ❌ No |
| CloudWatch Logs | ✅ Yes | ✅ Yes | ❌ No | ❌ No |

## Firebase Authentication & Authorization

### Authentication Methods
| Method | Implementation | User Base | Security Level |
|--------|----------------|-----------|----------------|
| Email/Password | Firebase Auth | Primary users | Medium |
| Google OAuth | Firebase Auth | Secondary option | High |
| Custom Tokens | Firebase Admin SDK | Service integration | High |
| Anonymous Auth | Firebase Auth | Limited features | Low |

### Firebase Security Rules

#### Realtime Database Rules
```javascript
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    },
    "artists": {
      ".read": "auth != null",
      "$artistId": {
        ".write": "auth.uid == resource.data.ownerId"
      }
    }
  }
}
```

#### Cloud Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /public/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### Custom Claims Authorization
```javascript
// Artist role with upload permissions
{
  "role": "artist",
  "permissions": ["upload", "analytics", "profile_edit"],
  "tier": "premium",
  "channels": ["UCxxxxxx"]
}

// Admin role with full access
{
  "role": "admin", 
  "permissions": ["all"],
  "tier": "admin"
}
```

## API Access Control Matrix

### REST API Endpoints (dn-api)

| Endpoint | Method | Current Auth | Required Role | Data Sensitivity | Risk Level |
|----------|--------|--------------|---------------|------------------|------------|
| `/dn_users_list` | GET | ❌ None (Gap) | Content Manager | High (PII) | 🔴 Critical |
| `/update-dnfm-user` | POST | ❌ None (Gap) | Content Manager | High (PII) | 🔴 Critical |
| `/send-mail` | POST | ❌ None (Gap) | API Developer | Medium | 🟡 High |
| `/dn_payouts_fetch` | GET | ❌ None (Gap) | System Admin | Critical (Financial) | 🔴 Critical |
| `/create-user-playlist` | POST | ❌ None (Gap) | Artist User | Low | 🟡 Medium |
| `/get-user-playlists` | GET | ❌ None (Gap) | Artist User | Low | 🟡 Medium |
| `/link-track-to-playlist` | POST | ❌ None (Gap) | Artist User | Low | 🟡 Medium |
| `/unlink-track-from-playlist` | DELETE | ❌ None (Gap) | Artist User | Low | 🟡 Medium |
| `/hollow` | GET | ❌ None | End User | None | 🟢 Low |

### REST API Endpoints (distrofm)

| Endpoint | Method | Current Auth | Required Role | Data Sensitivity | Risk Level |
|----------|--------|--------------|---------------|------------------|------------|
| `/artist-info/{id}` | GET | ✅ AWS IAM | Artist User | Medium | 🟢 Low |
| `/artist-videos/{id}` | GET | ✅ AWS IAM | Artist User | Medium | 🟢 Low |
| `/track-upload` | POST | ✅ AWS IAM | Artist User | High | 🟡 Medium |
| `/analytics-data/{id}` | GET | ✅ AWS IAM | Artist User | Medium | 🟢 Low |
| All other endpoints | Various | ✅ AWS IAM | Artist User+ | Medium | 🟢 Low |

### GraphQL API Access Control (AppSync)

#### distrofmgraphql-main (Production)
| Operation Type | Authentication | Authorization | Field-Level Security |
|----------------|----------------|---------------|---------------------|
| Queries | ✅ AWS IAM | User-based filtering | 🟡 Partial |
| Mutations | ✅ AWS IAM | Owner-based access | ✅ Yes |
| Subscriptions | ✅ AWS IAM | User-specific filtering | ✅ Yes |

**Key Resolvers:**
- `getArtist`: Owner or public data only
- `updateArtist`: Owner only
- `createSong`: Authenticated users only
- `listVideos`: Public with rate limiting

#### Video Management APIs (Development)
| API | Authentication | Data Isolation | Sync Security |
|-----|----------------|----------------|---------------|
| dnbackendfunctionnew-dev | ✅ AWS IAM | Channel-based | N/A |
| dnbackendfunctions-dev | ✅ AWS IAM | Channel-based | Version-controlled |

## Database Access Control

### Aurora PostgreSQL Cluster
- **Cluster**: database-2-cluster
- **Access Method**: RDS Data API only (no direct connections)
- **Authentication**: IAM database authentication
- **Network**: Private subnets only, no public access

#### Database User Roles
| Role | Permissions | Services | Usage |
|------|-------------|----------|--------|
| `lambda_executor` | SELECT, INSERT, UPDATE | Lambda functions | Application queries |
| `admin_user` | ALL PRIVILEGES | Management console | Administrative tasks |
| `readonly_user` | SELECT only | Analytics/Reporting | Read-only queries |

#### Table-Level Permissions
```sql
-- Users table (PII data)
GRANT SELECT, INSERT, UPDATE ON users TO lambda_executor;
GRANT SELECT ON users TO readonly_user;

-- Financial/Payout tables (sensitive)
GRANT SELECT, INSERT, UPDATE ON payouts TO lambda_executor;
REVOKE ALL ON payouts FROM readonly_user;

-- Analytics tables (aggregated data)
GRANT SELECT ON analytics TO readonly_user;
GRANT ALL ON analytics TO lambda_executor;
```

## External API Access Control

### Third-Party Service Authentication

| Service | Authentication Method | Credentials Storage | Rotation Schedule | Access Level |
|---------|----------------------|-------------------|------------------|--------------|
| YouTube Data API | OAuth 2.0 + API Key | AWS Secrets Manager | 90 days | Channel management |
| Spotify Web API | Client Credentials | AWS Secrets Manager | 30 days | Track metadata |
| TikTok API | OAuth 2.0 | AWS Secrets Manager | 60 days | Content posting |
| Instagram API | OAuth 2.0 | AWS Secrets Manager | 60 days | Content posting |
| Airtable API | API Key | AWS Secrets Manager | 90 days | Data synchronization |

### Rate Limiting & Access Controls
```javascript
// Example rate limiting configuration
const rateLimits = {
  youtube: {
    quotaPerDay: 10000,
    rateLimitPerSecond: 100,
    burstLimit: 1000
  },
  spotify: {
    rateLimitPerSecond: 10,
    burstLimit: 100,
    retryAfter: true
  }
};
```

## Administrative Access Procedures

### User Provisioning Workflow

#### New Employee Onboarding
1. **Request Submission**: Manager submits access request with role justification
2. **Approval Process**: Security team reviews and approves based on role requirements
3. **Account Creation**: 
   - AWS IAM user with appropriate role assignment
   - Firebase project access (if required)
   - Development tool access
4. **MFA Setup**: Mandatory MFA configuration for all admin accounts
5. **Access Verification**: New user confirms access and completes security training

#### Role Change Process
1. **Change Request**: Manager submits role modification request
2. **Impact Assessment**: Security team evaluates permission changes
3. **Approval**: Security lead approves role elevation/reduction
4. **Implementation**: Access changes applied with effective date
5. **Audit Log**: All changes logged for compliance review

### User Deprovisioning Workflow

#### Employee Departure
1. **Immediate Actions** (Day of departure):
   - Disable AWS IAM user account
   - Revoke Firebase project access
   - Invalidate all active sessions
   - Remove from all distribution lists
2. **Follow-up Actions** (Within 24 hours):
   - Transfer ownership of critical resources
   - Update emergency contact lists
   - Archive user data per retention policy
3. **Audit Review** (Within 7 days):
   - Verify all access has been removed
   - Review audit logs for unusual activity
   - Document closure in HR system

### Emergency Access Procedures

#### Break-Glass Access
For critical system failures requiring immediate access:

1. **Activation**: On-call engineer activates break-glass procedure
2. **Notification**: Automatic alerts sent to security team
3. **Temporary Access**: Emergency credentials provided (4-hour expiry)
4. **Activity Monitoring**: All actions logged and monitored in real-time
5. **Post-Incident Review**: Full audit and review within 24 hours

#### Emergency Contacts
| Role | Primary Contact | Backup Contact | Escalation Time |
|------|----------------|----------------|-----------------|
| System Administrator | Adrian Green | TBD | 15 minutes |
| Security Lead | Adrian Green | TBD | 30 minutes |
| AWS Account Admin | Adrian Green | TBD | 15 minutes |

## Access Monitoring & Auditing

### CloudTrail Configuration
```json
{
  "TrailName": "distronation-audit-trail",
  "S3BucketName": "distronation-cloudtrail-logs",
  "IncludeGlobalServiceEvents": true,
  "IsLogging": true,
  "EnableLogFileValidation": true,
  "EventSelectors": [
    {
      "ReadWriteType": "All",
      "IncludeManagementEvents": true,
      "DataResources": [
        {
          "Type": "AWS::S3::Object",
          "Values": ["arn:aws:s3:::distronation-*/*"]
        }
      ]
    }
  ]
}
```

### Security Monitoring Alerts

#### High-Priority Alerts
- Root account usage
- MFA device changes
- IAM policy modifications
- Failed authentication attempts (>5 in 15 minutes)
- Unusual API access patterns
- Database admin operations

#### Medium-Priority Alerts  
- New IAM user creation
- Role assumption events
- S3 bucket policy changes
- Lambda function modifications
- API Gateway configuration changes

### Access Review Schedule

| Review Type | Frequency | Scope | Responsible Party |
|-------------|-----------|-------|-------------------|
| **Quarterly Access Review** | Every 3 months | All user accounts and permissions | Security Team |
| **Annual Role Review** | Yearly | Role definitions and assignments | Management + Security |
| **Continuous Monitoring** | Real-time | Suspicious activity and violations | Automated systems |
| **Incident-Based Review** | As needed | Access involved in security incidents | Security Team |

## Recommendations for Empire Integration

### Immediate Actions (Week 1-2)
1. **Secure Open Endpoints**: Implement authentication for all dn-api endpoints
2. **Centralized Identity**: Evaluate AWS Cognito for unified identity management
3. **MFA Enforcement**: Require MFA for all administrative access
4. **Access Audit**: Complete comprehensive review of all current access

### Short-Term Improvements (Month 1-2)
1. **RBAC Implementation**: Standardize role-based access across all services
2. **Privileged Access Management**: Implement PAM solution for admin accounts
3. **Just-In-Time Access**: Temporary elevated access for administrative tasks
4. **Enhanced Monitoring**: Implement SIEM for comprehensive security monitoring

### Long-Term Strategy (Month 3-6)
1. **Zero Trust Architecture**: Implement zero trust security model
2. **Certificate-Based Authentication**: Move to certificate-based auth for critical systems
3. **Advanced Threat Detection**: ML-based anomaly detection for access patterns
4. **Compliance Automation**: Automated compliance checking and reporting

### Cost Considerations
- **AWS Cognito**: ~$0.0055 per monthly active user
- **AWS IAM Advanced**: No additional cost for basic features
- **Third-party PAM Solution**: $15-25 per user per month
- **SIEM Solution**: $100-500 per month depending on log volume
- **Total Estimated Cost**: $500-1,500 per month for enhanced security

## Compliance Mapping

### SOC 2 Type II Controls
| Control | Current Status | Gap Analysis | Remediation Required |
|---------|----------------|--------------|---------------------|
| Access Control (CC6.1) | 🟡 Partial | Open API endpoints | Authentication implementation |
| Logical Access (CC6.2) | ✅ Compliant | Good IAM structure | Enhanced monitoring |
| System Access (CC6.3) | 🟡 Partial | No PAM solution | PAM implementation |

### GDPR Requirements
| Requirement | Current Status | Implementation | Data Subject Rights |
|-------------|----------------|----------------|-------------------|
| Data Access Control | 🟡 Partial | Some systems lack auth | Right to access |
| Data Portability | ❌ Not Implemented | No export mechanism | Right to portability |
| Data Deletion | 🟡 Partial | Manual process only | Right to erasure |

## Appendices

### Appendix A: AWS IAM Policy Examples

#### Lambda Execution Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream", 
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:<REGION>:<AWS_ACCOUNT_ID>:*"
    }
  ]
}
```

#### API Gateway Access Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "execute-api:Invoke",
      "Resource": "arn:aws:execute-api:<REGION>:<AWS_ACCOUNT_ID>:*/main/*/*",
      "Condition": {
        "StringEquals": {
          "aws:userid": "${aws:userid}"
        }
      }
    }
  ]
}
```

### Appendix B: Firebase Security Rules Examples

#### Comprehensive Database Rules
```javascript
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid || root.child('admins').child(auth.uid).exists()",
        ".write": "$uid === auth.uid || root.child('admins').child(auth.uid).exists()",
        ".validate": "newData.hasChildren(['email', 'displayName'])"
      }
    }
  }
}
```

### Appendix C: Access Control Checklists

#### New User Access Checklist
- [ ] Access request form completed and approved
- [ ] Background check completed (if required)
- [ ] AWS IAM account created with appropriate role
- [ ] MFA device configured and tested
- [ ] Firebase project access granted (if needed)
- [ ] Development environment access configured
- [ ] Security training completed
- [ ] Access confirmation email sent
- [ ] Manager notified of access completion

#### User Termination Checklist
- [ ] HR notification received
- [ ] AWS IAM account disabled
- [ ] Firebase access revoked
- [ ] Active sessions terminated
- [ ] API keys rotated (if user had access)
- [ ] Shared accounts updated
- [ ] Equipment return confirmed
- [ ] Exit interview security questions completed
- [ ] Final access audit completed

---

**Document Version**: 1.0  
**Last Updated**: July 24, 2025  
**Next Review**: October 24, 2025  
**Owner**: Adrian Green, Head of Engineering  
**Approved By**: [Pending Empire Distribution Security Team Review]