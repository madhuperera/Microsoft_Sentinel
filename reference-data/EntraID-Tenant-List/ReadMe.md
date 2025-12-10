# EntraID Tenant List

Location: `Microsoft_Sentinel/reference-data/EntraID-Tenant-List`

This folder contains a CSV watchlist (`EntraIDTenantList.csv`) that maps Azure/Entra tenant GUIDs to friendly organization names and domains. Use this watchlist to enrich Sentinel analytics and investigation queries by joining events that include a TenantId with the company/organization name.

Current CSV schema (header row in `EntraIDTenantList.csv`):

DefaultDomainName,OrganizationName,TenantID,TenantRegionScope,TenantRegionSubScope

- `DefaultDomainName`: Primary domain for the tenant (example: `example.com`).
- `OrganizationName`: Friendly company/organization name.
- `TenantID`: Tenant GUID (required for joins/enrichment).
- `TenantRegionScope` / `TenantRegionSubScope`: Optional region metadata.

Sample rows (non-production examples):

| DefaultDomainName | OrganizationName | TenantID | TenantRegionScope | TenantRegionSubScope |
|---|---|---|---|---|
| example.com | Example Corp | 12345678-1234-1234-1234-123456789012 | Public | Global |
| contoso.onmicrosoft.com | Contoso Ltd | 87654321-4321-4321-4321-210987654321 | Public | Global |
| tailwind-traders.com | Tailwind Traders | abcdef12-abcd-abcd-abcd-abcdefabcdef | Public | Global |

Note: The CSV in this repo currently only has the header row. Add rows following the schema above.

How to generate or update this list

1. Manual lookup (single domain)
   - Use https://tenantidlookup.com/ and enter the domain to obtain the tenant GUID.
   - Record the `DefaultDomainName`, `OrganizationName`, and `TenantID` into the CSV.

2. Bulk collection (recommended for large lists)
   - Export domains or observed tenant identifiers from your inventory or logs (emails, domains in sign-in logs, partner lists).
   - Use the Microsoft workbook(s) or community tools that accept lists of domains and resolve tenant IDs in bulk. Microsoft-provided or community workbooks may allow you to paste domains and return tenant GUIDs for export.
   - Alternatively, build a small automation that queries an API or service to resolve domains to tenant GUIDs (respect API terms and rate limits).

Quick lookup note:
- `tenantidlookup.com` is a public lookup website; it does not provide a documented API for bulk resolution. Use the site for manual, single lookups only.
- For bulk resolution prefer Microsoft workbooks, community tools that explicitly support bulk input/output, or an authoritative internal source (CMDB/customer list).


Importing the CSV into Microsoft Sentinel (Watchlist)

Portal (UI):
- In the Azure portal, open your Microsoft Sentinel workspace.
- Settings -> Watchlist (or Configuration -> Watchlists depending on UI).
- Click "Add new" and upload `EntraIDTenantList.csv`.
- Choose comma delimiter and ensure header row is present.
- Select `TenantID` (or `DefaultDomainName`) as the key column depending on how you'll join.

Automation / REST API:
- You can use the Log Analytics Watchlist REST APIs to create or update a watchlist from a CSV programmatically. See: https://learn.microsoft.com/azure/sentinel/data-connectors-watchlist

Example KQL to enrich Signin logs with watchlist data (assumes watchlist named `EntraIDTenantList`):

```kql
let tenantWL = view () { Watchlist('EntraIDTenantList') };
SigninLogs
| extend TenantId = tostring(TenantId)
| lookup kind=leftouter tenantWL on $left.TenantId == $right.TenantID
| project TimeGenerated, UserPrincipalName, TenantId, OrganizationName, Result
```

Best practices
- Maintain a source-of-truth: if you have a CMDB or authoritative customer list, prefer that over public lookups.
- Document the source and date: add a `Notes` column or append a comment in the CSV when adding entries.
- Rate-limit and cache public lookups when doing bulk resolution.
- Keep the watchlist updated on a schedule (runbook/Logic App) if you expect domain-to-tenant mappings to change.

Next actions I can do for you
- Add a sample `EntraIDTenantList.csv` with a few example rows (non-production values).
- Add a PowerShell script to perform bulk lookups (requires deciding on a lookup service and handling rate-limits/credentials).
- Create an automation (Azure Automation/Logic App) to refresh the watchlist from a stored CSV in a storage account on a schedule.

Tell me which of these you'd like me to implement next.