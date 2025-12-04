# SES Analytics Integration (Frontend Reference)

This mirrors `docs/frontend-ses-analytics.md` inside the CRM repo so stakeholders without repo access can reference the same integration contract.

## Data Sources

| Source | Description |
| --- | --- |
| `/outreach/tracking-data-ses` | Authenticated API returning SES tracking records for a campaign (`lambda/outreach/src/handlers/trackingDataSes.ts`). |
| `outreachApiClient.getTrackingData` | Client-side wrapper that fetches the endpoint and normalizes SES events into `EnhancedMessageTrackingData`. |
| `useTrackingData` | React Query hook that caches SES/Mailgun providers, exposes loading/error states, and triggers fallback banners. |
| `useCampaignStats` | Hook for campaign-level aggregates (hero metrics, success rates). |
| `ses-email-events` SNS topic | SES configuration set publishes delivery/open/click events to this SNS topic in `us-east-1`, which now has an explicit Terraform-managed subscription to the `sesEventProcessor` Lambda. |

## How to Consume the Data

1. Fetch via `outreachApiClient.getTrackingData(campaignId, options)` when hooks are not available (scripts, tests).
2. Prefer `useTrackingData` in React components:
   ```tsx
   const { data, isLoading } = useTrackingData(campaignId, {
     statusFilter: 'delivered',
     providerOverride: 'ses',
   });
   ```
3. Hooks automatically:
   - Persist detected provider in `sessionStorage`.
   - Use SES-specific cache settings (`staleTime = refetchInterval = 15s`, max cache age 60s).
   - Render cached/fallback states inside `MessageTrackingLog.tsx`.

## Status & Timeline Mapping

| SES Event | UI Status |
| --- | --- |
| SEND/SENT/SUCCESS | `sent` |
| DELIVERY/DELIVERED | `delivered` |
| OPEN | `opened` |
| CLICK | `clicked` |
| BOUNCE/COMPLAINT/FAILURE/REJECT | `failed` |

- `EnhancedMessageTrackingData` also exposes derived timestamps (`deliveredAt`, `openedAt`, etc.) and `events` for timeline components.
- Components in Tasks 3–10 should rely on these normalized fields rather than parsing raw payloads.

## Best Practices

1. Always provide a `campaignId`; optional filters include `status`, `event`, `messageId`, `limit`, and `skip`.
2. Reuse `trackingKeys` from `useTrackingData` when creating new hooks/components to keep caches consistent.
3. Respect the 90-day DynamoDB TTL: show “no recent data” states when older campaigns fall outside the window.
4. Align refetch intervals with SES event cadence (≥ 15 seconds) to avoid unnecessary load.
5. For live dashboards, leverage `useCampaignStats` for hero metrics and `useTrackingData` for detailed tables/cards.

## Validation & Monitoring

- When data stalls, check the new CloudWatch metrics:
  - `SesProcessorErrors` (alarm `outreach-ses-processor-errors`)
  - `SesMissingCampaignTag` (alarm `outreach-ses-missing-campaign-tag`)
- Review SES VDM dashboards (Deliverability, Engagement, Compliance) to corroborate metrics.
- Ensure Storybook/preview environments call `useTrackingData` with valid tokens to prevent CORS/auth surprises before shipping UI changes.

### SES Event Delivery Path

- SES configuration sets for CRM mail flows emit delivery, open, click, bounce, and complaint notifications to the SNS topic **`ses-email-events`** (region `us-east-1`).
- Terraform (`terraform/outreach/main.tf`) now looks up this topic and creates:
  - An `aws_lambda_permission` allowing SNS to invoke `outreach-sesEventProcessor`.
  - An `aws_sns_topic_subscription` that wires the topic directly to the `sesEventProcessor` Lambda module output.
- Result: each SNS notification triggers the processor, which persists events to `outreach-campaign-tracking` and maintains the suppression table. If tracking data seems stale, verify the SNS subscription status and Lambda invocation metrics first.

Keep this document synchronized with the repository copy whenever the integration contract evolves.
