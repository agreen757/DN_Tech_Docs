# SES Analytics Integration Reference

## Overview

This document mirrors the latest SES tracking updates implemented in the CRM application. Keep this file aligned with source repository documentation.

**Last Updated:** January 13, 2026  
**Status:** Analysis Complete - Analytics Separation Implemented with Known Backend Issue

## Pipeline Summary

### 1. Send Handlers

- **Outreach**: `lambda/outreach/src/handlers/sendTemplateEmailSES.ts`
- **Finance**: `lambda/finance/src/handlers/sendFinancialReportSES.ts`
- Both attach configuration sets and enforce campaign tags
- Include List-Unsubscribe metadata for engagement controls

### 2. SES to SNS Publishing

- Configuration sets publish event types: SEND, DELIVERY, BOUNCE, COMPLAINT, OPEN, CLICK
- Outreach: publishes to `ses-email-events` topic
- Finance: publishes to `financial-ses-events` topic

### 3. SNS to Lambda Processors

- **Outreach**: `lambda/outreach/src/handlers/sesEventProcessor.ts` - **WORKING**
- **Finance**: `lambda/finance/src/handlers/sesFinancialEventProcessor.ts` - **BLOCKED**
- Processors normalize payloads and update DynamoDB tracking entries
- Finance processor currently fails on invocation (infrastructure issue)

### 4. Storage (DynamoDB)

- **Outreach table**: `outreach-campaign-tracking` - Receiving engagement events
- **Finance table**: `financial-campaign-tracking` - Send records only, no engagement events
- TTL: ~90 days via `expirationTime`
- Global Secondary Indexes: EmailIndex, MonthYearIndex

### 5. API and Frontend

- **Outreach API**: `/outreach/tracking-data-ses` - Fully functional
- **Finance API**: `/financial/tracking-data` - Functional but incomplete data
- Frontend hooks:
  - `useOutreachLifetimeMetrics()` - Queries Outreach API
  - `useFinancialLifetimeMetrics()` - Queries Finance API (new - January 13, 2026)

## Analytics Data Separation

### System Architecture Comparison

| Aspect | Outreach | Mailer (Finance) |
|--------|----------|------------------|
| Purpose | Marketing campaigns | Financial reports |
| Send Lambda | sendTemplateEmailSES | sendFinancialReportSES |
| Config Set | outreach-tracking | finance-tracking |
| SNS Topic | ses-email-events | financial-ses-events |
| Event Processor | sesEventProcessor | sesFinancialEventProcessor |
| DynamoDB Table | outreach-campaign-tracking | financial-campaign-tracking |
| API Endpoint | /outreach/tracking-data-ses | /financial/tracking-data |
| Frontend Hook | useOutreachLifetimeMetrics | useFinancialLifetimeMetrics |
| Status | WORKING | BLOCKED |

### Frontend Implementation Changes (January 13, 2026)

**New File**: `src/hooks/useFinancialLifetimeMetrics.ts`
- Queries dedicated `/financial/tracking-data` endpoint
- Month-year based querying (API requirement)
- 4-month lookback for 90-day TTL coverage
- Message deduplication by ID
- SES event type aggregation
- React Query caching (5-minute TTL)

**Updated File**: `src/pages/dashboard/MailerLifetimeMetrics.tsx`
- Now uses `useFinancialLifetimeMetrics()` hook
- Maintains same UI rendering logic
- Data source separation complete

## Analytics Status by System

### Outreach System (WORKING)

- Send records: Yes
- Engagement events (DELIVERY, OPEN, CLICK, BOUNCE): Yes
- Metrics available: Open rate, click rate, delivery rate, bounce rate
- Dashboard display: Full metrics visible
- Data freshness: Real-time with 5-minute caching

### Financial System (PARTIAL)

- Send records: Yes (564+ records from Oct-Nov 2025)
- Engagement events: None (processor blocked)
- Metrics available: Send count only
- Dashboard display: All rates show 0%
- Root cause: Event processor Lambda crashes on invocation

## Known Issues and Troubleshooting

### Issue: Financial Metrics Display as 0%

**Symptoms**:
- MailerLifetimeMetrics component shows 0% for all engagement rates
- Only send count displays correctly
- Component renders successfully but shows incomplete data

**Technical Details**:
- Send stage: Working correctly (emails sent to SES)
- SNS publishing: Configured correctly
- Lambda event processor: Failing on invocation
- DynamoDB: Receiving send records but not engagement events

**Data Inventory** (as of January 13, 2026):
- Total financial send records: 564 (October-November 2025)
- Engagement event records: 0
- Data retention: 90 days TTL

**Resolution Authority**: Backend Infrastructure/DevOps team

**For Infrastructure Team**:
1. Review CloudWatch logs for event processor crashes
2. Verify Lambda has required dependencies
3. Redeploy event processor with complete bundle
4. Test SNS-to-Lambda invocation chain
5. Monitor DynamoDB for engagement event records
6. Alert when engagement events appear

## Monitoring and Validation

### Outreach System Checks

- CloudWatch Logs: Monitor for SES_EVENT_PROCESSED metrics
- SES Dashboard: Verify configuration set health for outreach-tracking
- DynamoDB: Scan outreach-campaign-tracking for sesEventType records
- Frontend: Verify metrics display percentages (not 0%)

### Financial System Checks

- Send records: Query financial-campaign-tracking for recent sends
- Engagement events: Query for records with sesEventType field (should show events)
- Event processor logs: Check for error messages and stack traces
- SNS topic: Verify messages published to financial-ses-events
- Lambda invocations: Monitor for failed invocation attempts

## Frontend Consumption

### API Query Parameters

**Financial API** (`/financial/tracking-data`):
- Required: `month` (uppercase month name: JANUARY, FEBRUARY, etc.)
- Required: `year` (numeric: 2025, 2026)
- Optional: `limit` (default 500, max 500)

**Outreach API** (`/outreach/tracking-data-ses`):
- Flexible query parameters (supports date ranges)

### Data Limitations

- TTL retention: Older campaigns (>90 days) have no data
- Month-based querying: API requires month-year parameters (not arbitrary ranges)
- Record limit: Maximum 500 records per request
- Cache behavior: React Query 5-minute TTL means up to 5-minute data lag

### Graceful Degradation

- Components handle "no data" states gracefully
- Show placeholders when engagement metrics unavailable
- Display only available data (e.g., send count without engagement rates)

## Change Management

- Update this document when configuration sets change
- Update when DynamoDB schema modifications occur
- Update when API contracts change (query parameters, response structure)
- Document any new SES event types added to processors
- Coordinate changes across both Outreach and Financial systems
- Reference technical roadmap for infrastructure status

---

**Critical Note**: Financial engagement tracking awaiting backend infrastructure resolution. Frontend implementation and API integration complete. Backend event processing Lambda requires redeployment with required dependencies.
