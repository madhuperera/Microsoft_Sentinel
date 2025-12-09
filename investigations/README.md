# Investigations

Ad-hoc KQL queries for manual analysis and investigation of security incidents.

## Structure by Data Source

- **identity-security/** - Sign-in logs, audit events, identity risk signals
  - conditional-access/ - CA policy impact analysis
  - privileged-accounts/ - Privileged account activity patterns
  - security-groups/ - Security group change history
  - inactive-logins/ - Stale credential detection
  - sign-in-analysis/ - Sign-in anomalies and patterns
- **email-security/** - Exchange activity and email threat analysis
  - attachment-controls/ - Email attachment patterns
- **office-anomalies/** - SharePoint, Teams, OneDrive activity
- **device-security/** - Device logon and file activity
  - intune/ - Intune-managed device analysis
- **billing-analysis/** - Data ingestion costs by table/source
- **guest-access/** - Guest user activity
- **keeper-security/** - Keeper password manager activity
- **concepts/** - Reusable KQL patterns and techniques

## How to Use

### Running Queries in Sentinel

1. Open Microsoft Sentinel > Logs
2. Paste query content
3. Adjust time range and parameters (at top of each query with `let` statements)
4. Run and analyze results

### Integrating with Workbooks

Queries can be embedded in Sentinel workbooks for:
- Time-series visualization of trends
- KQL parameter dropdowns for interactive filtering
- Scheduled exports to reports

Example workbook queries reference:
- `investigations/identity-security/inactive-logins/inactive-logins.kql`
- `investigations/office-anomalies/unusual-office-activities-baseline.kql`

## Common Query Patterns

### 1. Parameterized Time Windows
```kusto
let ReportPeriod = 1d;         // Time window to analyze
let BinPeriod = 1h;            // Aggregation interval
SigninLogs
| where TimeGenerated > ago(ReportPeriod)
| summarize Count = count() by bin(TimeGenerated, BinPeriod)
```

### 2. Timezone Conversion (New Zealand)
```kusto
let ClientTimeZone = "Pacific/Auckland";
SigninLogs
| extend LocalTime = datetime_utc_to_local(TimeGenerated, ClientTimeZone)
| extend Hour = hourofday(LocalTime)
| where Hour between (0 .. 6)  // Overnight logins
```

### 3. Watchlist Lookup
```kusto
SigninLogs
| lookup kind=inner _GetWatchlist("EmergencyBreakGlassAccounts")
    on $left.UserId == $right.SearchKey
```

### 4. Baseline & Anomaly Detection
```kusto
let BaselinePeriod = 14d;
let ReportPeriod = 1d;
let HistoricData = OfficeActivity
| where TimeGenerated between (ago(BaselinePeriod) .. ago(ReportPeriod))
| summarize BaselineCount = count() by UserId, Operation;

let CurrentData = OfficeActivity
| where TimeGenerated > ago(ReportPeriod)
| summarize CurrentCount = count() by UserId, Operation;

CurrentData
| join HistoricData on UserId, Operation
| where CurrentCount > (BaselineCount * 2)  // 2x normal activity
```

## Naming Convention

Files use kebab-case describing the analysis purpose:
- `ca-policy-impact.kql` - How CA policies affect user logins
- `privileged-account-logons.kql` - When privileged accounts sign in
- `unusual-office-activities-baseline.kql` - Anomalies vs. baseline

## Data Sources Available

| Table | Purpose | Retention |
|-------|---------|-----------|
| `SigninLogs` | User authentication events | 30 days |
| `AuditLogs` | Entra ID admin actions | 30 days |
| `OfficeActivity` | Teams, SharePoint, OneDrive events | 90 days |
| `DeviceLogonEvents` | Windows device logons (via Defender) | 30 days |
| `EmailAttachmentInfo` | Email attachment metadata | 30 days |
| `AADNonInteractiveUserSignInLogs` | Service principal auth | 30 days |

## See Also

- [Detection Rules](../detection-rules/) - Scheduled alerts powered by similar queries
- [Workbooks](../dashboards/) - Visualizations using these queries
- [KQL Query Best Practices](https://learn.microsoft.com/en-us/kusto/query/best-practices)
