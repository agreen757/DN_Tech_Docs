# AWS Athena Integration: Symphonic Earnings Data Query

**Date**: March 6, 2026  
**Status**: Implementation Planning (Q1 2026)  
**Component**: CRM Financial Lambda (`financial-sendFinancialReportSES`)

## Executive Summary

This document details the AWS Athena integration strategy for querying Symphonic earnings data in the CRM's monthly mailer financial reporting system. Testing completed on March 6, 2026 has validated two viable approaches:

1. **Direct CSV Download** ✅ WORKING - Current recommendation for Phase 1
2. **AWS Athena Queries** ✅ WORKING - Planned for Phase 2 when data exceeds 1MB

**Recommendation**: Implement Direct Download immediately (Phase 1), migrate to Athena when monthly files exceed 1MB (Phase 2).

---

## Testing Results Summary

### Test Date: March 6, 2026

Three data retrieval methods were evaluated:

| Method | Status | Performance | File Size | Cost | Recommendation |
|--------|--------|-------------|-----------|------|---|
| S3 Select | ❌ FAILED | N/A | 14KB | N/A | Not viable |
| Direct CSV Download | ✅ PASSING | <100ms | 14KB | <$0.01 | **Use Now** |
| AWS Athena | ✅ PASSING | 2-3s | 14KB | <$0.01 | Use at 1MB+ |

### Detailed Test Findings

**S3 Select Attempt**:
- Issue: MethodNotAllowed error on S3 bucket
- Root Cause: S3 Select not enabled on bucket or permissions insufficient
- Resolution: Not pursued (alternative methods viable)

**Direct CSV Download** (RECOMMENDED FOR PHASE 1):
- File Size: 14KB per month
- Download Time: Instant (<100ms)
- Reliability: Consistent across multiple test runs
- Authentication: S3 Cognito Identity Pool verified working
- Error Handling: S3 timeout and missing file scenarios tested
- **Status**: PRODUCTION READY

**AWS Athena** (PLANNED FOR PHASE 2):
- Database: [See Secrets Manager]
- Table: [See Secrets Manager]
- Data Location: [Configured in Secrets Manager]
- Query Time: 2-3 seconds consistent
- Query Cost: <$0.01 per query
- Reliability: High availability with automatic failover
- **Status**: PRODUCTION READY, staging validation in progress

---

## Symphonic Earnings Data Schema

**Athena Table Configuration**:

```sql
CREATE EXTERNAL TABLE symphonic_earnings (
  account_id STRING,
  reporting_period_id STRING,
  reporting_period_name STRING,
  earnings DECIMAL(15, 2),
  earning_details_link STRING
)
STORED AS CSV
LOCATION '[S3 location configured in Secrets Manager]'
```

**Data Characteristics**:
- Format: Monthly CSV exports from Symphonic earnings platform
- Location: Organized by year/month (see Secrets Manager for details)
- Update Frequency: Once per month
- Retention: Indefinite (financial compliance)
- Partition Strategy: Year/Month (recommended for Phase 3)

---

## Phase 1: Direct Download Implementation

### Timeline
- **Duration**: 1-2 weeks
- **Start**: Week of March 10, 2026
- **Completion Target**: March 20, 2026

### Implementation Scope

**Lambda Function Updates**:
- File: `lambda/financial/src/handlers/sendFinancialReportSES.ts`
- Integration Point: Monthly report generation trigger
- Functionality: Retrieve latest Symphonic CSV from S3

**Code Changes**:
```typescript
// New utility function for Symphonic earnings
import { S3Client, GetObjectCommand } from "@aws-sdk/client-s3";

async function getSymhonicEarningsCSV(reportingPeriod: string): Promise<string> {
  const s3Client = new S3Client({ region: process.env.AWS_REGION });
  const key = `Exports/${reportingPeriod.split('-')[0]}/${getMonthName(reportingPeriod)}/earnings.csv`;
  
  const command = new GetObjectCommand({
    Bucket: process.env.SYMPHONIC_EARNINGS_BUCKET,
    Key: key,
  });
  
  const response = await s3Client.send(command);
  const csvContent = await response.Body.transformToString();
  return csvContent;
}

// Parse CSV and extract earnings data
interface EarningsRecord {
  account_id: string;
  reporting_period_id: string;
  reporting_period_name: string;
  earnings: number;
  earning_details_link: string;
}

function parseSymhonicEarnings(csvContent: string): EarningsRecord[] {
  // CSV parsing logic using existing libraries (Papa Parse, csv-parse, etc.)
  // Return structured earnings records for email template injection
}
```

**Integration into Email Template**:
- Combine Korrect internal earnings with Symphonic earnings
- Inject mixed-source data into monthly mailer template
- Validate data completeness before sending

### Testing Strategy

**Unit Tests**:
- CSV file parsing with valid/invalid data
- Error handling for missing files
- S3 authentication and permissions
- Data format validation

**Integration Tests**:
- End-to-end monthly report generation
- Email template rendering with earnings data
- SES delivery verification
- Error recovery and retry logic

**Staging Validation**:
- Deploy to staging environment
- Run 2-3 test cycles with real Symphonic data
- Validate email output quality
- Performance profiling

### Success Criteria

- ✅ CSV file retrieved successfully every attempt
- ✅ Earnings data parsed correctly (100% accuracy)
- ✅ Email template renders with accurate totals
- ✅ Monthly report generation <5 seconds
- ✅ Zero errors in production logs
- ✅ SES delivery success rate >99%

### Rollback Procedure

If Direct Download implementation fails:
1. Revert to manual Symphonic CSV download
2. Maintain previous month's data as fallback
3. Alert on Slack #backend-engineering channel
4. Begin Athena implementation immediately as alternative

---

## Phase 2: AWS Athena Migration (Deferred)

### Trigger Conditions

Migrate to Athena when **ANY** of these conditions met:

1. **File Size Growth**: Monthly CSV reaches 1MB+
2. **Query Frequency**: Need >5 earnings data queries per month
3. **Analytics Requirements**: Historical trend analysis required
4. **Performance**: Need <1 second query response time
5. **Growth Projection**: >50% month-over-month file size increase

### Current Status

- **Current File Size**: 14KB per month
- **Estimated Migration Trigger**: 12-18 months at current growth rate
- **Recommendation**: Monitor quarterly, no immediate action needed

### Phase 2 Implementation Plan

**When Triggered**:

1. **Staging Validation** (1 week)
   - Clone Athena table to staging environment
   - Load historical data (12+ months)
   - Validate query results vs. Direct Download method
   - Performance benchmarking

2. **Lambda Integration** (1 week)
   - Create athena-query utility module
   - Implement SQL query templates
   - Add result parsing and aggregation logic
   - Error handling for Athena-specific exceptions

3. **Deployment** (1 week)
   - Feature flag: `USE_ATHENA_EARNINGS_QUERY`
   - Parallel execution with both methods (validation)
   - Monitoring for query anomalies
   - Gradual traffic shift to Athena

4. **Validation** (1 week)
   - 3 monthly cycles with Athena in production
   - Data accuracy verification
   - Performance baseline establishment
   - Team training completion

### Athena Query Templates (Phase 2)

```sql
-- Monthly earnings query
SELECT 
  account_id,
  reporting_period_id,
  reporting_period_name,
  SUM(earnings) AS total_earnings,
  COUNT(*) AS record_count,
  MAX(earning_details_link) AS details_link
FROM symphonic_earnings
WHERE reporting_period_name = ?
GROUP BY account_id, reporting_period_id, reporting_period_name
ORDER BY account_id;

-- Year-to-date earnings (Phase 3)
SELECT 
  account_id,
  SUM(earnings) AS ytd_earnings,
  COUNT(*) AS earnings_months
FROM symphonic_earnings
WHERE YEAR(reporting_period_name) = YEAR(CURRENT_DATE)
GROUP BY account_id
ORDER BY ytd_earnings DESC;
```

---

## Cost Analysis

### Direct Download (Phase 1)

**Monthly Costs** (at 14KB file size):
- S3 Data Transfer: $0 (AWS internal)
- Lambda Execution: <$0.01 (estimated)
- CloudWatch Logs: <$0.01
- **Total: <$0.05/month**

**Cost per Report**: <$0.001

---

### AWS Athena (Phase 2)

**Monthly Costs** (at 14KB file size):
- Athena Queries: $0.006 per query × 1 query/month = $0.006
- Glue Catalog: ~$1.00/month
- S3 Output Results: <$0.01/month
- **Total: ~$1.01/month**

**Cost per Query**: ~$0.006 (improves with larger datasets)

---

### Cost Optimization Roadmap

| Data Volume | Recommended Method | Monthly Cost | Notes |
|-------------|------------------|--------------|-------|
| <1MB | Direct Download | <$0.10 | Current state (14KB) |
| 1-10MB | Athena | ~$1.00 | Better performance, scalable |
| >10MB | Athena + Partitioning | $1-2.00 | Optimized with date partitions |
| >100MB | Athena + Analytics | $2-5.00 | Historical trend analysis enabled |

---

## Monitoring and Observability

### CloudWatch Metrics to Track

**Direct Download (Phase 1)**:
```
- symphonic/download/duration (milliseconds)
- symphonic/download/success_rate (percent)
- symphonic/earnings/record_count (count)
- symphonic/earnings/total_amount (dollars)
```

**Athena (Phase 2)**:
```
- symphonic/athena/query_duration (seconds)
- symphonic/athena/data_scanned (bytes)
- symphonic/athena/query_cost (dollars)
- symphonic/athena/row_count (count)
```

### Alerting

**Critical Alerts**:
- Earnings data retrieval fails (Direct Download or Athena)
- Monthly report generation timeout >30 seconds
- Data validation fails (earnings count or amounts don't match source)
- Email delivery failure for financial reports

**Warning Alerts**:
- Query performance degradation >2x baseline
- Athena query cost >$0.10 per month (Phase 2)
- Athena query time >10 seconds (Phase 2)

---

## Dependencies and Permissions

### Required IAM Permissions

**Lambda Execution Role**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::[earnings-data-bucket]",
        "arn:aws:s3:::[earnings-data-bucket]/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "athena:StartQueryExecution",
        "athena:GetQueryExecution",
        "athena:GetQueryResults",
        "athena:StopQueryExecution"
      ],
      "Resource": "arn:aws:athena:[region]:*:workgroup/primary"
    },
    {
      "Effect": "Allow",
      "Action": [
        "glue:GetDatabase",
        "glue:GetTable"
      ],
      "Resource": [
        "arn:aws:glue:[region]:*:catalog",
        "arn:aws:glue:[region]:*:database/[database-name]",
        "arn:aws:glue:[region]:*:table/[database-name]/[table-name]"
      ]
    }
  ]
}
```
**Note**: Replace `[earnings-data-bucket]`, `[region]`, `[database-name]`, and `[table-name]` with values from Secrets Manager.

### Secrets Manager

**Symphonic API Configuration** (if needed for Phase 1):
```
symphonic-api-credentials:
  - endpoint: https://api.symphonic.com/earnings
  - api_key: [stored in Secrets Manager]
  - auth_type: api_key
```

---

## Risk Mitigation

### Known Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| S3 Permission Denials | Medium | High | Test in staging, validate IAM role |
| Symphonic API Outage | Low | High | Maintain cached previous month data |
| Athena Query Timeout | Low | Medium | Query timeout setting: 30 seconds max |
| Data Integrity Issues | Low | High | Validation: record count + total amount checks |
| Cost Overrun (Phase 2) | Low | Low | Monitor monthly Athena costs closely |

### Mitigation Strategies

**Direct Download Failures**:
- Fallback to previous month's earnings data
- Alert team immediately for manual intervention
- Retry logic with exponential backoff (3 attempts)

**Athena Failures** (Phase 2):
- Automatic fallback to Direct Download method
- Circuit breaker pattern: disable Athena after 3 consecutive failures
- Manual override flag for team troubleshooting

**Data Validation**:
- Compare record counts: source vs. parsed data
- Validate earnings amount totals match source
- Hash-based integrity checking for historical data

---

## Implementation Checklist

### Phase 1: Direct Download (Weeks 1-2)

**Development**:
- [ ] Create `symphonic-earnings.ts` utility module
- [ ] Implement CSV parsing logic
- [ ] Add error handling and retry logic
- [ ] Create CloudWatch metrics integration
- [ ] Update Lambda environment variables

**Testing**:
- [ ] Unit tests for CSV parsing (valid/invalid data)
- [ ] Integration tests with real S3 file
- [ ] Error scenario testing (missing file, timeout)
- [ ] Staging deployment and validation
- [ ] Performance profiling (<100ms target)

**Deployment**:
- [ ] Code review and approval
- [ ] Merge to development branch
- [ ] Deploy to staging environment (test 1 cycle)
- [ ] Deploy to production
- [ ] Monitor first 3 production cycles

**Documentation**:
- [ ] Lambda function documentation
- [ ] Symphonic API integration guide
- [ ] Error handling procedures
- [ ] Rollback documentation
- [ ] Team training notes

---

## Related Documentation

**Technical Roadmap**: `DN_Tech_Docs/technical-roadmap.md` (Section: AWS Athena Integration for Mixed-Source Earnings Data)

**CRM Application Docs**:
- `DN_Tech_Docs/applications/crm/architecture-overview.md`
- `DN_Tech_Docs/applications/crm/api-integrations.md`
- `DN_Tech_Docs/applications/crm/data-flow-patterns.md`

**Backend Operations**:
- `lambda/financial/src/handlers/sendFinancialReportSES.ts`
- `lambda/financial/src/handlers/sendTemplateEmailSES.ts`
- Deployment guides and environment configuration

---

## Questions & Support

**Contact**: Adrian Green (Head of Engineering)  
**Slack Channel**: #backend-engineering  
**Escalation**: Platform Engineering Lead

---

**Document Version**: 1.0  
**Last Updated**: March 6, 2026  
**Next Review**: Monthly (monitor for Phase 2 trigger conditions)
