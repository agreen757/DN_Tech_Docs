# Amazon SES Engagement Tracking Configuration

**Document Version:** 1.0  
**Last Updated:** December 3, 2025  
**Status:** Production Ready

## Overview

This document describes the configuration and implementation of click and open tracking for emails sent through Amazon SES in the CRM Tool. Engagement tracking enables the system to monitor recipient interactions with email campaigns for analytics and optimization.

## Architecture

### Components

```yaml
SES Configuration Sets:
  financial-reports:
    Purpose: Financial report email delivery tracking
    Region: AWS_REGION
    Event Destinations: financial-ses-events-dest
    
  outreach-tracking:
    Purpose: Outreach campaign email delivery tracking  
    Region: AWS_REGION
    Event Destinations: outreach-ses-events-dest

Event Destinations:
  Enabled Events:
    - SEND: Email dispatch confirmation
    - DELIVERY: Successful recipient delivery
    - BOUNCE: Delivery failures
    - COMPLAINT: Spam complaints
    - OPEN: Email open events (tracking pixel loaded)
    - CLICK: Link click events (tracked URL accessed)
    - REJECT: Pre-send rejections
    - RENDERING_FAILURE: Template rendering errors
    
  Destination: Amazon SNS Topics
    - financial-ses-events (for financial-reports config set)
    - ses-email-events (for outreach-tracking config set)
```

### How Engagement Tracking Works

1. **Email Composition**: Lambda functions prepare HTML emails with links
2. **Link Wrapping**: SES automatically wraps ``<a>`` tags with tracking URLs
3. **Tracking Domain**: Default AWS domain (e.g., r.AWS_REGION.awstrack.me)
4. **Event Flow**:

   ```text
   User clicks link → AWS tracking server → Event logged → SNS notification → Lambda processor → DynamoDB
   ```

## Configuration Requirements

### 1. Configuration Set Setup

Both configuration sets must have:

* ✅ **Event Destinations** configured with CLICK and OPEN event types enabled  
* ✅ **SNS Topic** specified for event delivery  
* ✅ **Enabled** status for the event destination  

.. note::
   No custom tracking domain or manual "engagement tracking" toggle is needed. Having CLICK/OPEN in event destinations automatically enables link wrapping with AWS default tracking domains.

### 2. Secrets Manager Configuration

**Secret Name**: ``distronation/ses``

.. code-block:: json

   {
     "region": "AWS_REGION",
     "fromEmail": "sender@domain.com",
     "replyToEmail": "reply@domain.com",
     "configurationSet": "outreach-tracking",
     "financialConfigurationSet": "financial-reports",
     "outreachConfigurationSet": "outreach-tracking"
   }

**Key Fields**:

* ``financialConfigurationSet``: Used by financial Lambda functions
* ``outreachConfigurationSet``: Used by outreach Lambda functions
* ``configurationSet``: Legacy field, defaults to outreach

### 3. Lambda Function Integration

**Financial Lambda** (``lambda/finance/src/utils/secrets.ts``):

.. code-block:: typescript

   configurationSet: secrets.financialConfigurationSet || 
                    secrets.configurationSet || 
                    'financial-reports'

**Outreach Lambda** (``lambda/outreach/src/utils/secrets.ts``):

.. code-block:: typescript

   configurationSet: secrets.outreachConfigurationSet || 
                    secrets.configurationSet || 
                    'outreach-tracking'

### 4. Frontend URL Handling

**Challenge**: SES only wraps HTML anchor tags (``<a href="...">``) - plain text URLs are not tracked.

**Solution**: Auto-conversion utility in React application

**Implementation** (``src/utils/linkUtils.ts``):

.. code-block:: typescript

   export function convertPlainUrlsToLinks(html: string): string {
     const urlPattern = /(?<!href=["'])(https?:\/\/[^\s<>"]+?)(?=[\s<]|$)/gi;
     return html.replace(urlPattern, (url) => `<a href="${url}">${url}</a>`);
   }

**Integration** (``src/pages/outreach/CampaignDetailsPage.tsx``):

.. code-block:: typescript

   // Convert plain URLs to anchor tags before sending
   const processedBody = convertPlainUrlsToLinks(messageBody);

   await sendMailgunEmail({
     recipients,
     subject: messageSubject,
     body: processedBody,  // URLs now wrapped in <a> tags
     // ...
   });

**Result**: All URLs in outreach emails are automatically converted to clickable links that SES can track.

## Validation Steps

### Verify Configuration Set Event Destinations

.. code-block:: bash

   aws ses describe-configuration-set \
     --configuration-set-name outreach-tracking \
     --region AWS_REGION \
     --configuration-set-attribute-names eventDestinations

**Expected Output**:

.. code-block:: json

   {
     "EventDestinations": [{
       "Name": "outreach-ses-events-dest",
       "Enabled": true,
       "MatchingEventTypes": [
         "bounce", "click", "complaint", "delivery",
         "open", "reject", "renderingFailure", "send"
       ],
       "SNSDestination": {
         "TopicARN": "arn:aws:sns:AWS_REGION:ACCOUNT_ID:ses-email-events"
       }
     }]
   }

### Verify Email Link Wrapping

1. **Send a test email** through the CRM interface
2. **View email source** (right-click → View Page Source)
3. **Verify link format**:

   .. code-block:: html

      <!-- Tracked link (correct) -->
      <a href="https://r.AWS_REGION.awstrack.me/L0/https:%2F%2Fexample.com/1/...">
        https://example.com
      </a>
      
      <!-- Plain URL (will NOT be tracked) -->
      <p>Visit https://example.com</p>

### Verify Event Tracking

1. **Click a link** in a test email
2. **Check DynamoDB** tracking table for click events
3. **Verify SNS** topic received the event

.. code-block:: bash

   # Check CloudWatch Logs for SNS-triggered Lambda
   aws logs tail /aws/lambda/outreach-tracking-processor \
     --since 10m --region AWS_REGION

## Troubleshooting

### Links Not Being Wrapped

**Symptom**: Links in emails appear as plain text  
**Cause**: URLs not formatted as HTML anchor tags  
**Solution**: Ensure frontend conversion utility is being called before email send

**Check**:

1. Verify ``convertPlainUrlsToLinks()`` is imported
2. Confirm it's called before ``sendMailgunEmail()``
3. Test the utility function independently

### Click Events Not Recorded

**Symptom**: Link clicks don't appear in analytics  
**Cause**: Event destination missing CLICK event type or SNS processor not running

**Check**:

1. Verify CLICK is in ``MatchingEventTypes`` array
2. Confirm SNS topic subscription is active
3. Check Lambda processor CloudWatch logs for errors

### Wrong Configuration Set Used

**Symptom**: Financial emails using outreach config set (or vice versa)  
**Cause**: Secrets Manager missing specific config set field

**Solution**: Update Secrets Manager secret with both fields:

.. code-block:: bash

   aws secretsmanager update-secret \
     --secret-id distronation/ses \
     --secret-string '{
       "financialConfigurationSet": "financial-reports",
       "outreachConfigurationSet": "outreach-tracking"
     }'

## Cost Considerations

**SES Engagement Tracking Pricing** (as of December 2025):

* **Email Sending**: $0.10 per 1,000 emails
* **Event Publishing**: Included at no additional cost
* **SNS Notifications**: $0.50 per 1 million notifications
* **DynamoDB Storage**: Pay-per-request pricing

**Projected Monthly Cost** (at 20,000 emails/month):

* Email sending: $2.00
* SNS events (8 types × 20k): $0.08
* DynamoDB writes: ~$0.25
* **Total**: ~$2.33/month

**Cost Savings vs. Mailgun**: 87.5% reduction in per-email costs

## Security Considerations

### Data Privacy

* **Tracking URLs**: Do not include sensitive data in query parameters
* **IP Address Logging**: Click events include recipient IP addresses
* **Retention**: Configure TTL in DynamoDB for GDPR compliance

### Link Security

* **HTTPS**: All tracking redirects use HTTPS by default
* **Validation**: AWS validates destination URLs before redirection
* **Phishing Protection**: Tracking domains are AWS-owned and trusted

## Best Practices

### Email Composition

**DO**:

* Use HTML anchor tags for all links
* Include descriptive link text
* Test emails in multiple clients
* Monitor click-through rates

**DON'T**:

* Paste plain URLs expecting them to be tracked
* Use JavaScript redirects (not trackable)
* Embed links in images only
* Exceed 250 links per email (SES limit)

### Testing

1. **Staging Environment**: Test link wrapping before production deployment
2. **Multiple Clients**: Verify rendering in Gmail, Outlook, Apple Mail
3. **Mobile Testing**: Confirm tracking works on mobile devices
4. **Analytics Validation**: Cross-reference with user reports

### Monitoring

* **Daily Metrics**: Track open rates, click rates, bounce rates
* **Anomaly Detection**: Alert on sudden drops in engagement
* **A/B Testing**: Compare tracked vs. untracked campaigns
* **User Feedback**: Monitor for link redirect issues

## References

### Internal Documentation

* `SES Email Flow <../../backend-operations/ses-email-flow.html>`_
* `Frontend SES Analytics <./frontend-ses-analytics.html>`_
* `SES Analytics Reference <./ses-analytics-reference.html>`_

### AWS Documentation

* `SES Configuration Sets <https://docs.aws.amazon.com/ses/latest/dg/using-configuration-sets.html>`_
* `Event Publishing <https://docs.aws.amazon.com/ses/latest/dg/monitor-using-event-publishing.html>`_
* `Custom Tracking Domains <https://docs.aws.amazon.com/ses/latest/dg/configure-custom-open-click-domains.html>`_

### Technical Roadmap

* See `Technical Roadmap <../../technical-roadmap.html>`_ for SES migration timeline
* Email Service Integration section (lines 153-163)

---

**Document Classification**: Internal Technical Documentation  
**Sensitivity**: Non-Sensitive (no credentials or proprietary data)  
**Owner**: Platform Engineering Team  
**Review Cycle**: Quarterly or upon significant changes
