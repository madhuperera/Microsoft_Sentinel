# Identity Security Detections

Monitors Entra ID (Azure AD) authentication, authorization, and privileged account activity.

## Included Threats

### Conditional Access (`conditional-access/`)
- **Purpose**: Detects unauthorized or anomalous modifications to Entra ID Conditional Access policies
- **Context**: CA policies control access to critical resources; unauthorized changes indicate:
  - Compromised admin account
  - Insider threat attempting privilege escalation
  - Policy bypass attempts (removing MFA requirement, IP restrictions, etc.)
- **Rules**:
  - `ca-changes-afterhours.json` - Changes outside business hours (High severity)
  - `ca-exclusion-updates.json` - Group exclusions added to policies (Medium severity)

### Privileged Accounts (`privileged-accounts/`)
- **Purpose**: Monitors emergency/break-glass admin accounts and protected users
- **Context**: These accounts should rarely be used; activity indicates:
  - Legitimate incident response (expect activity)
  - Unauthorized privilege escalation
  - Compromised standard account attempting admin access
- **Rules**:
  - `emergency-breakglass-login.json` - Sign-in from emergency admin account (High severity)
  - `protected-user-tampering.json` - Changes to protected users (Medium severity)
- **Dependencies**: Requires `emergency-breakglass-accounts` watchlist

### Unauthorized Access (`unauthorized-access/`)
- **Purpose**: Detects suspicious device registration and temporary access patterns
- **Context**: Unusual authentication methods may indicate:
  - Compromised account attempting new device registration
  - Weak authentication policy exploitation
  - Lateral movement within the organization
- **Rules**:
  - `temp-access-pass-monitoring.json` - Temporary Access Pass usage by admin (Low severity)
  - `unmanaged-device-registration.json` - Device registration by staff account (Medium severity)

### Security Groups (`security-groups/`)
- **Purpose**: Detects modifications to security groups
- **Associated Queries**: See `investigations/identity-security/security-groups/`

## Deployment Order

1. **Create watchlists** (reference-data/):
   - `emergency-breakglass-accounts.csv` (required for privileged-accounts rules)
   - Configure with your emergency admin accounts and refresh frequency

2. **Deploy detection rules** (this directory):
   - Start with Conditional Access rules (highest priority)
   - Deploy privileged-accounts rules
   - Deploy unauthorized-access rules

3. **Deploy investigation queries** (investigations/identity-security/):
   - Import reusable queries for ad-hoc analysis
   - Train SOC team on query patterns

4. **Deploy dashboards** (dashboards/production/conditional-access/):
   - Setup PROD_ConditionalAccessPolicyImpact workbook
   - Configure parameters (workspace, time range)

## Dependencies

### Data Sources
- `SigninLogs` table (all sign-in events)
- `AuditLogs` table (policy changes, user modifications)
- `AADRiskyUsers` table (risky user detection)
- `EnrichedMicrosoft365AuditLogs` table (additional event enrichment)

### Watchlists
- `emergency-breakglass-accounts` - List of emergency admin accounts
- `office-locations` - (referenced in some rules for timezone-aware after-hours detection)
- `disabled-accounts` - (for excluding disabled accounts from alerts)

### Client Timezone
- **Current**: Pacific/Auckland (New Zealand)
- **Update Required**: If deploying multi-region, modify `ClientTimeZone` variable in each rule
- **Impact**: "After hours" and business-hours-based rules depend on this

## Known Issues & Tuning

### False Positives
1. **After-hours changes by legitimate admins**: Adjust `OfficeOpenHour`, `OfficeCloseHour`, `OfficeCloseDays`
2. **Service principal changes to CA policies**: Add service principal accounts to exclusion list
3. **Temporary exclusions during testing**: Use `suppressionDuration` to temporarily silence rules

### Query Frequency Tuning
- **Every 1 hour (PT1H)**: For high-severity threats (CA changes, emergency account usage)
- **Every 2 hours (PT2H)**: For medium-severity threats (group modifications, device registration)
- **Adjust based on**: SOC staffing, incident response SLA, alert fatigue

## Testing

Before deploying to production:

```kusto
// Test Conditional Access query manually
let ReportPeriod = 7d;
let ClientTimeZone = "Pacific/Auckland";
AuditLogs
| where TimeGenerated > ago(ReportPeriod)
| where OperationName has "conditional access"
| count
// Should return recent CA policy changes if your environment has them
```

## Related Documentation

- [Conditional Access Architecture](https://learn.microsoft.com/en-us/entra/identity/conditional-access/overview)
- [Privileged Account Management Best Practices](https://learn.microsoft.com/en-us/security/privileged-access-workstations/privileged-access-deployment)
- [Investigation Queries](../../../investigations/identity-security/) for deeper analysis
