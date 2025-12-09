# Reference Data: Emergency Break Glass Accounts

Watchlist of emergency admin accounts that should be monitored for unauthorized access.

## Purpose

Emergency break glass accounts are privileged credentials held in secure storage for disaster recovery scenarios. They should be used extremely rarely. This watchlist enables:

1. **Alert on any sign-in** - Any usage triggers immediate investigation
2. **Activity baseline** - Distinguish legitimate emergency access from misuse
3. **Access control** - Restrict to emergency procedures only

## File Format

**File**: `emergency-breakglass-accounts.csv`

**Columns**:
| Column | Type | Required | Example |
|--------|------|----------|---------|
| SearchKey | string | Yes | user@contoso.com |
| UserId | GUID | Yes | 12345678-1234-1234-1234-123456789012 |
| AccountName | string | Yes | Emergency Admin 1 |
| CreatedDate | date | No | 2024-01-01 |

**Example**:
```csv
SearchKey,UserId,AccountName,CreatedDate
breakglass1@contoso.com,12345678-1234-1234-1234-123456789012,Emergency Admin 1,2024-01-01
breakglass2@contoso.com,87654321-4321-4321-4321-210987654321,Emergency Admin 2,2024-01-01
```

## Maintenance

### Adding an Emergency Account
1. Generate new account in Entra ID with strong password
2. Store credentials in secure secret vault (e.g., Azure Key Vault)
3. Add row to CSV with account details
4. Git commit: `git commit -m "ops: add emergency account {AccountName}"`
5. Upload to Sentinel Watchlist via Portal

### Removing an Account
1. Deactivate account in Entra ID
2. Delete row from CSV
3. Git commit: `git commit -m "ops: remove emergency account {AccountName}"`
4. Update watchlist in Sentinel

### Quarterly Review
- Verify all accounts are still needed
- Check sign-in logs for unexpected usage
- Update CreatedDate for recently rotated accounts
- Document business justification

## Usage in Rules & Queries

### Detection Rule Example
```kusto
let ReportPeriod = 1h;
let ClientTimeZone = "Pacific/Auckland";

SigninLogs
| where TimeGenerated > ago(ReportPeriod)
| lookup kind=inner _GetWatchlist("EmergencyBreakGlassAccounts")
    on $left.UserId == $right.SearchKey
| extend NZTime = datetime_utc_to_local(TimeGenerated, ClientTimeZone)
| project TimeGenerated, NZTime, UserPrincipalName, IPAddress, ConditionalAccessStatus
```

### Investigation Query Example
```kusto
let BreakGlassAccounts = _GetWatchlist("EmergencyBreakGlassAccounts")
| project SearchKey, AccountName;

SigninLogs
| where TimeGenerated > ago(7d)
| where UserId in (BreakGlassAccounts)
| summarize 
    SignInCount = count(),
    UniqueIPs = dcount(IPAddress),
    FailureCount = countif(ResultType != "0")
    by UserPrincipalName, AccountName
| sort by SignInCount desc
```

## References

- **Detection Rule**: `detection-rules/identity-security/privileged-accounts/emergency-breakglass-login.json`
- **Investigation Query**: `investigations/identity-security/privileged-accounts/privileged-account-logons.kql`
- **Microsoft Docs**: [Manage emergency access accounts](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/security-emergency-access)
