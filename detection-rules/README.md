# Detection Rules

Scheduled alert rules deployed to Microsoft Sentinel to automatically detect security threats.

## Structure

- **identity-security/** - Entra ID (Azure AD) and authentication-related detections
  - conditional-access/ - Conditional Access policy changes and violations
  - privileged-accounts/ - Emergency break glass and privileged account monitoring
  - unauthorized-access/ - Temporary access passes and unmanaged device registrations
  - security-groups/ - Security group membership changes
- **email-security/** - Exchange/M365 email threat detection
  - attachment-controls/ - Email attachment exfiltration patterns
- **office-anomalies/** - Anomalous Office 365 activity
- **device-security/** - Device registration and activity monitoring
- **keeper-security/** - Keeper password manager policy monitoring

## Common Patterns

All detection rules follow the Azure Resource Manager (ARM) template schema:
- `apiVersion: 2023-12-01-preview`
- `kind: Scheduled` (query-based rules run at defined intervals)
- `queryFrequency`: How often to run the query (typically PT1H or PT2H)
- `queryPeriod`: Time window to analyze (typically matches queryFrequency)
- `triggerThreshold`: Minimum events to trigger an alert
- MITRE ATT&CK `tactics` and `techniques` for categorization
- Entity mappings for User/IP/URL extraction

## Deployment

```powershell
# Deploy a single rule to Sentinel
az deployment group create `
  --resource-group <rg-name> `
  --template-file detection-rules/identity-security/conditional-access/ca-changes-afterhours.json `
  --parameters workspace=<workspace-name>
```

## Naming Convention

Files use descriptive kebab-case names matching the threat/control:
- `ca-changes-afterhours.json` - Conditional Access changes outside business hours
- `emergency-breakglass-login.json` - Emergency admin account sign-ins
- `attachment-leak-external.json` - Email attachment exfiltration to external domains

## Severity Levels

- **High**: Immediate investigation required; likely security incident
- **Medium**: Review within hours; potential policy violation
- **Low**: Monitor; requires trending analysis to determine risk

## See Also

- [Investigation Queries](../investigations/) - Ad-hoc KQL queries for the same domains
- [Watchlists](../reference-data/) - Reference data used in rule conditions
- [Dashboards](../dashboards/) - Visualizations for monitoring rule effectiveness
