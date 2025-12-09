# Email Security Investigations

Ad-hoc queries for analyzing email threats and attachment patterns.

## Included Queries

### Attachment Controls
- `attachment-leak-external.kql` - External email recipients receiving attachments
- `attachment-leak-personal-domains.kql` - Personal domain attachment sharing patterns
- `monitoring-attachments.kql` - Comprehensive attachment activity analysis
- `email-attachment-count-per-day.kql` - Daily email attachment volume trends
- `email-attachments-count-per-domain.kql` - Attachment sharing by external domain

## Common Patterns

### 1. Detecting Attachment Exfiltration
```kusto
let InternalDomains = dynamic(["contoso.com","contoso.onmicrosoft.com"]);
let FileTypesToIgnore = dynamic(["png","jpeg","gif"]);
let ReportPeriod = 7d;
let ThresholdCount = 30;  // emails per day

EmailAttachmentInfo
| where TimeGenerated > ago(ReportPeriod)
| extend SenderDomain = tostring(split(SenderFromAddress, "@")[1])
| extend RecipientDomain = tostring(split(RecipientEmailAddress, "@")[1])
| where SenderDomain in (InternalDomains)
| where RecipientDomain !in (InternalDomains)
| where FileType !in (FileTypesToIgnore)
| summarize Count = count() by bin(TimeGenerated, 1d), RecipientDomain, FileType
| where Count > ThresholdCount
```

### 2. Bulk Sharing Detection
```kusto
EmailAttachmentInfo
| where TimeGenerated > ago(1d)
| summarize
    AttachmentCount = dcount(FileName),
    UniqueRecipients = dcount(RecipientEmailAddress),
    TotalSize = sum(FileSize)
    by SenderFromAddress
| where UniqueRecipients > 20  // Bulk sharing indicator
```

### 3. Sensitive File Types
```kusto
let SensitiveTypes = dynamic(["xlsx","docx","pptx","pdf","zip","rar"]);
EmailAttachmentInfo
| where FileType in (SensitiveTypes)
| where TimeGenerated > ago(7d)
| summarize Count = count() by SenderFromAddress, FileType, RecipientEmailAddress
```

## Data Source

- **Table**: `EmailAttachmentInfo` (available with defender for office 365)
- **Retention**: 30 days
- **Fields**:
  - `SenderFromAddress` - Email sender
  - `RecipientEmailAddress` - Recipient email
  - `FileName` - Attachment name
  - `FileType` - Extension (xlsx, pdf, exe, etc.)
  - `FileSize` - Size in bytes
  - `TimeGenerated` - Event timestamp

## See Also

- [Detection Rules](../../detection-rules/email-security/) - Automated email threat alerts
- [Office 365 Defender Documentation](https://learn.microsoft.com/en-us/defender-office-365/)
