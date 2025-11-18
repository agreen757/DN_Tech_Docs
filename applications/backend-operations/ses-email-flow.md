# Email Flow with SES (Mailgun Fallback)

```mermaid
flowchart LR
    subgraph App["App (Audit/Claims)"]
        A[Build email payload]
        B[Select provider\nEMAIL_PROVIDER]
    end
    A --> B
    B -->|ses| SESClient[SESEmailService]
    B -->|mailgun| MG[Mailgun client]

    SESClient -->|SendRawEmail| SES[Amazon SES]
    SES -->|Success| Recipients
    SES -.Fail.-> Error[Error mapped\n(throttle/unverified/size)]
    Error --> Retry[Retry/backoff or surface error]
    SESClient -->|Failures| SNS[(SNS topic Optional)]

    MG --> Recipients
    MG -.Fail.-> MGError[Mailgun error]
    MGError --> SNS
```

Notes:
- SES credentials are loaded from Secrets Manager (name and region configured via environment).
- SNS topic is optional for failure notifications.
- Provider selection is controlled by `EMAIL_PROVIDER` (`ses` default, `mailgun` fallback).
