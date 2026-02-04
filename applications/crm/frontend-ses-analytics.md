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

---

## Financial Metrics Aggregation

### Overview

Financial email analytics (`useFinancialLifetimeMetrics`) queries the `/financial/tracking-data` endpoint which retrieves records from the `financial-campaign-tracking` DynamoDB table. This hook aggregates event counts to display lifetime metrics (total sent, delivered, opened, clicked, etc.) and calculate rates on the Mailer Lifetime Metrics dashboard.

### Data Structure

Each financial tracking record contains:

```json
{
  "messageId": "unique-message-id",
  "sesEventType": "OPEN",
  "events": [
    { "type": "SEND", "timestamp": "..." },
    { "type": "DELIVERY", "timestamp": "..." },
    { "type": "OPEN", "timestamp": "..." }
  ]
}
```

**Key Fields**:
- `messageId`: Unique identifier for the email message (used for deduplication)
- `sesEventType`: The most recent SES event type (string)
- `events`: Array containing the complete history of all SES events for this message

### Aggregation Logic

The `fetchFinancialTrackingData` function in `src/hooks/useFinancialLifetimeMetrics.ts` performs the following aggregation:

1. **Count Unique Messages** (for "totalSent"): Iterates through all records and uses a `Set<messageId>` to count unique messages, avoiding double-counting.

2. **Count Events from events Array**: For each record, iterates through the `events` array and counts specific event types:
   - `DELIVERY` or `DELIVERED` → `totalDelivered`
   - `OPEN` → `totalOpened`
   - `CLICK` → `totalClicked`
   - `BOUNCE` → `totalBounced`
   - `COMPLAINT` → `totalComplained`
   - **Skips SEND events** in the array (already counted as unique messages)

3. **Fallback to sesEventType**: For records without a populated `events` array, uses `sesEventType` to count individual engagement events.

4. **Calculate Rates**:
   - `deliveryRate = totalDelivered / totalSent`
   - `openRate = totalOpened / totalDelivered`
   - `clickRate = totalClicked / totalDelivered`
   - `bounceRate = totalBounced / totalSent`
   - `complaintRate = totalComplained / totalDelivered`

### Historical Data Considerations

**Important**: Metrics aggregated from emails sent before the SES event processor fix will appear lower than expected because:

- **Old Records**: Historical emails had incomplete event capture due to a bug in the event processor
- **Recent Records**: Emails sent after the processor was fixed now have complete event histories in the `events` array
- **Gradual Improvement**: As the 90-day DynamoDB TTL cycles out old incomplete records, aggregate metrics will improve
- **No Action Required**: The system is working correctly; metrics reflect the actual event data available

### Query Pattern

The hook queries the last 4 months of data to capture all active records (accounting for the 90-day TTL):

```typescript
// Query months: current, current-1, current-2, current-3
for (let monthsBack = 0; monthsBack < 4; monthsBack++) {
  const response = await axios.get('/financial/tracking-data', {
    params: {
      month: 'JANUARY|FEBRUARY|...',  // Uppercase month name
      year: '2025',
      limit: 500
    }
  });
}
```

### Validation & Monitoring

To verify financial metrics aggregation is working correctly:

1. **Check Dashboard**: Navigate to Mailer Lifetime Metrics dashboard
2. **Verify Sent Count**: Compare the "Total Emails Sent" count with actual sent records in DynamoDB
3. **Monitor Rates**: Open rate, click rate, and delivery rate should increase as new emails with complete event histories accumulate
4. **Check Logs**: Review browser console for the `Financial metrics aggregation` log which shows raw counts

### Rate Calculations

The financial metrics aggregation uses unique message tracking to calculate accurate rates:

**Sent Count**: Total unique messages with at least one event record

**Engagement Rates** (Open, Click, Complain):
- Numerator: Unique messages that had that event AND have a delivery confirmation
- Denominator: Total delivered messages
- Example: 3 opened / 3 delivered = 100% open rate

**Delivery Rate**:
- Numerator: Unique messages with a DELIVERY event
- Denominator: Messages with any tracked event (delivery, open, click, bounce, or complaint)
- Formula: `totalDelivered / messagesWithAnyTrackedEvent`
- Example: 3 delivered / 5 tracked = 60% delivery rate

**Bounce Rate**:
- Numerator: Unique messages with a BOUNCE event
- Denominator: Messages with any tracked event
- Formula: `totalBounced / messagesWithAnyTrackedEvent`

**Rationale**: Using messages with any tracked event as the delivery rate denominator (instead of all sent emails) accounts for the fact that old emails may have no tracking data at all due to incomplete event processor fixes. This prevents artificially low delivery rates from being inflated by thousands of emails with zero event data.

### Troubleshooting

**Symptom**: Delivery rate and open rate seem low

**Root Cause**: Historical emails have incomplete or missing event data

**Expected Behavior**:
1. Only messages with recorded events are included in rate calculations
2. Very old emails (no event data) are excluded from denominators
3. Rates reflect actual engagement among tracked messages
4. As 90-day TTL cycles out old records, rates will stabilize

**Symptom**: Open rate shows 100%, click rate shows 33.3%, delivery rate shows 60%

**Expected**: This is correct! It means:
- 3 messages have delivery confirmation
- All 3 delivered messages were opened
- 1 of the 3 delivered messages was clicked
- 5 total messages have some form of event tracking
- Therefore: delivery rate = 3/5 = 60%

**Symptom**: Metrics not updating

**Check**:
1. Verify React Query stale time (30 seconds) and refetch interval (60 seconds)
2. Check browser console for API errors
3. Confirm `/financial/tracking-data` endpoint is responding
4. Verify DynamoDB table has recent records with proper structure
