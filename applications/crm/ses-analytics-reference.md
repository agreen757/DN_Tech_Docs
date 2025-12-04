# SES Analytics Integration Reference

## Overview

This document mirrors the latest SES tracking updates implemented in `/Users/adriangreen/Work/mailer_frontend/payouts-mailer-app`. Keep this file aligned with `docs/ses-analytics-pipeline.md` in the source repository.

## Pipeline Summary

1. **Send Handlers**
   - Outreach: `lambda/outreach/src/handlers/sendTemplateEmailSES.ts`
   - Finance: `lambda/finance/src/handlers/sendFinancialReportSES.ts`
   - Both attach configuration sets (`outreach-tracking`, `finance-tracking`) from `getSESSecrets()`, enforce sanitized `campaign_*` tags via `formatCampaignTag()`, and include List-Unsubscribe / ListManagementOptions metadata for VDM/Inbox controls.

2. **SES → SNS**
   - Configuration sets publish SEND/DELIVERY/BOUNCE/COMPLAINT/OPEN/CLICK events to `ses-email-events`.

3. **SNS → Lambda Processors**
   - Outreach: `lambda/outreach/src/handlers/sesEventProcessor.ts`
   - Finance: `lambda/finance/src/handlers/sesFinancialEventProcessor.ts`
   - Processors normalize payloads, log missing campaign tags, record per-event metrics (`SES_EVENT_PROCESSED`), and update/create DynamoDB tracking entries while maintaining suppression lists.

4. **Storage (DynamoDB)**
   - Outreach table: `outreach-campaign-tracking`
   - Finance table: `financial-campaign-tracking`
   - TTL = ~90 days via `expirationTime`. GSIs: `EmailIndex`, `email-event-index`, plus `MonthYearIndex` for finance.

5. **API + Frontend**
   - Outreach API: `/outreach/tracking-data-ses` → `src/services/outreach/api/outreachApiClient.ts`
   - Finance API: `/financial/tracking-data`
   - Hooks: `useTrackingData`, `useCampaignStats`, `getSESLogs` etc. React Query caches SES data for 15–30s windows with fallback/offline messaging.

## Monitoring & Validation

- **CloudWatch Logs**: query for `SES_EVENT_PROCESSED` to aggregate outcomes (created/updated/duplicate) and alert on missing campaign tags.
- **SES VDM Dashboard**: confirm configuration set health and correlate bounce/complaint spikes.
- **Suppression Tables**: `outreach-suppression-list`, `financial-suppression-list` auto-maintained; use `aws dynamodb scan` for spot checks.

## Deployment Notes

- Build + package Lambdas from `lambda/outreach` using `./build-terraform-simple.sh` (and `build-custom-layer.sh` when layer deps change) before running Terraform in `terraform/outreach`.
- Finance stack follows analogous scripts within `lambda/finance`.

## Frontend Consumption Tips

- TTL-driven retention means older campaigns (>90 days) disappear; UI should surface “no data” gracefully.
- HTTP 207 from send endpoints indicates partial send success—use returned `results` array for debugging.
- React hooks automatically detect provider type (SES vs legacy). Cached provider stored in `sessionStorage`.

## Change Management

- Update both this document and `docs/ses-analytics-pipeline.md` whenever configuration sets, Dynamo schemas, or monitoring procedures change.
- Reference Task Master task 2 subtasks for historical context on SES hardening work.
