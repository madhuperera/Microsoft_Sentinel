# Dashboards (Workbooks)

Interactive visualizations for monitoring detection rule health and investigating security trends.

## Structure

- **production/** - Deployed to production Sentinel workspaces (PROD_*)
  - conditional-access/ - CA policy effectiveness and impact
  - insider-threats/ - User activity anomalies
  - essential8/ - Essential Eight compliance monitoring
  - intune-devices/ - Intune-managed device inventory and health
  - sharepoint-access/ - SharePoint access patterns
- **development/** - Non-production workspaces for testing (DEV_*)
  - Same structure as production for parallel testing

## Naming Convention

- `PROD_*` - Production-ready workbooks deployed to live Sentinel workspace
- `DEV_*` - Development/testing workbooks not yet production-ready

## Deploying a Workbook

### Via Azure Portal (Recommended for Testing)
1. Microsoft Sentinel > Workbooks > Create new
2. Edit > (paste JSON content from production file)
3. Save with name: `PROD_<Purpose>`

### Via ARM Template Deployment
```powershell
# Deploy DEV workbook to test workspace
az deployment group create `
  --resource-group <rg-name> `
  --template-file dashboards/production/essential8/PROD_SOC-Essential-8.json `
  --parameters workspace=/subscriptions/.../workspaces/<workspace-name>
```

### Via Azure CLI
```bash
# Import existing workbook
az sentinel workbook import \
  --resource-group <rg> \
  --workspace-name <workspace> \
  --import-source dashboards/production/insider-threats/PROD_InsiderThreats.json
```

## Common Workbook Types

### 1. Detection Rule Dashboards
- Monitor alert firing frequency and trends
- Track false positives and tuning impact
- Show entity enrichment (users, IPs, hosts)
- **Example**: `dashboards/production/conditional-access/PROD_ConditionalAccessPolicyImpact.json`

### 2. Compliance Monitoring
- Track security control effectiveness (Essential Eight, CIS, etc.)
- Show audit trail and remediation actions
- Generate compliance reports
- **Example**: `dashboards/production/essential8/PROD_SOC-Essential-8.json`

### 3. Investigation Dashboards
- Multi-tab experience for incident investigation
- User timeline, anomaly scoring, related alerts
- KQL parameter inputs for drilling down
- **Example**: `dashboards/production/insider-threats/PROD_InsiderThreats.json`

## Workbook Parameters

Most workbooks include KQL parameters for customization:

| Parameter | Purpose | Example |
|-----------|---------|---------|
| Workspace | Target Log Analytics workspace | `/subscriptions/.../workspaces/...` |
| TimeRange | Analysis period | 7d, 14d, 30d |
| EntityType | Filter by user, IP, host, etc. | User email, IP address |

## Workbook Queries

Workbooks reference KQL queries from `investigations/` directory:
- Queries are embedded as JSON strings with `\r\n` line breaks
- Parameters defined at workbook top (Workspace, TimeRange, etc.)
- Visualization type specified (line chart, pie chart, grid, etc.)

### Finding Query References
Search workbook JSON for `query: "` to find embedded KQL:
```json
{
  "type": 9,
  "content": {
    "query": "SigninLogs\r\n| where TimeGenerated > ago(7d)\r\n| summarize..."
  }
}
```

## Best Practices

1. **Test in DEV first**: Always validate workbook in DEV workspace before promoting to PROD
2. **Document parameters**: Add descriptive text explaining time range and workspace settings
3. **Pin key metrics**: Use visualization pinning to highlight critical data
4. **Schedule updates**: Set workbook refresh frequency based on query complexity
5. **Version control**: Update workbook JSON and commit to git

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Workbook fails to load | Check workspace parameter matches Log Analytics resource ID |
| Queries return no data | Verify data sources exist and time range includes events |
| Parameter dropdown empty | Check _GetWatchlist() watchlist name matches exactly |
| Slow to render | Reduce time range or add `| limit 10000` to queries |

## See Also

- [Investigation Queries](../investigations/) - KQL queries embedded in workbooks
- [Detection Rules](../detection-rules/) - Rules that populate workbook data
- [Workbook Best Practices](https://learn.microsoft.com/en-us/azure/sentinel/workbooks)
- [KQL Visualization Guide](https://learn.microsoft.com/en-us/kusto/query/render-operator)
