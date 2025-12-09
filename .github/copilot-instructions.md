# Microsoft Sentinel Codebase Guide

## Repository Overview
This repository contains security detection and investigation assets for Microsoft Sentinel, Microsoft's cloud-native SIEM. It's organized into **Analytics** (scheduled detection rules), **KQL** (reusable queries), **Watchlists** (reference data), and **Workbooks** (visualization dashboards).

> **📋 Restructuring in Progress**: A new domain-based organization is planned to improve discoverability and maintainability. See [`RESTRUCTURING_PROPOSAL.md`](../RESTRUCTURING_PROPOSAL.md) for the proposed folder hierarchy and benefits.

## Core Architecture & File Organization

The repository is organized by **security domain** with related detection rules, investigation queries, watchlists, and dashboards grouped together for discoverability.

### 1. **Detection Rules** - Scheduled Alert Rules
- **Location**: `detection-rules/{domain}/{threat}/` (e.g., `detection-rules/identity-security/conditional-access/`)
- **Format**: `.json` files - ARM deployment templates for Sentinel scheduled alert rules
- **Naming**: `{control|threat}-{variant}.json` (e.g., `ca-changes-afterhours.json`)
- **Key Properties**: 
  - `apiVersion: 2023-12-01-preview`
  - `queryFrequency`, `queryPeriod` (time intervals)
  - `severity` (High/Medium/Low)
  - `tactics`, `techniques` (MITRE ATT&CK mapping)
  - `entityMappings` (User/IP/Url extraction)

**Domains**: `identity-security/`, `email-security/`, `office-anomalies/`, `device-security/`, `keeper-security/`

### 2. **Investigation Queries** - Ad-hoc Analysis
- **Location**: `investigations/{domain}/{threat}/` or `investigations/{data-source}/`
- **Format**: `.kql` files - Kusto Query Language
- **Naming**: `{purpose}.kql` (e.g., `ca-policy-impact.kql`, `unusual-office-activities-baseline.kql`)
- **Pattern**: Heavy parameterization with `let` statements at top:
  ```kusto
  let ReportPeriod = 1d;
  let ClientTimeZone = "Pacific/Auckland";
  let MonitoredOperations = dynamic([...]);
  let Threshold = value;
  ```

**Domains**: `identity-security/`, `email-security/`, `office-anomalies/`, `device-security/`, `billing-analysis/`, `guest-access/`, `keeper-security/`, `concepts/`

### 3. **Reference Data** - Watchlists
- **Location**: `reference-data/{watchlist-name}/` (e.g., `reference-data/emergency-breakglass-accounts/`)
- **Format**: `.csv` files + `README.md` (format spec, maintenance instructions)
- **Usage**: Referenced in rules/queries via `_GetWatchlist("watchlist-name")` function
- **Pattern**: Lookup joins using `lookup kind=inner _GetWatchlist(...)`
- **Example**: `emergency-breakglass-accounts.csv` - emergency admin accounts to monitor

### 4. **Dashboards** - Interactive Workbooks
- **Location**: `dashboards/{environment}/{domain}/` (e.g., `dashboards/production/conditional-access/`)
- **Naming**: `{ENV}_{Purpose}.json` (e.g., `PROD_InsiderThreats.json`, `DEV_ConditionalAccessPolicyImpact.json`)
- **Format**: JSON with `version: "Notebook/1.0"` - KQL parameter panels + visualization queries
- **Environments**: `production/` (PROD_*) and `development/` (DEV_*) separate directories for lifecycle management

## Common Patterns & Conventions

### KQL Query Structure (All Queries)
1. **Parameterization** - All configurable values at top as `let` statements
2. **Timezone Handling** - Convert to client timezone: `datetime_utc_to_local(TimeGenerated, ClientTimeZone)`
3. **Entity Extraction** - Use `extend` to create queryable fields for MITRE ATT&CK mapping
4. **Data Filtering** - Apply domain/user/category filters via dynamic lists
5. **Time Windows** - Queries typically look back 1-2 hours (via `queryFrequency`/`queryPeriod`)

### Alert Rule JSON Template Structure (Detection Rules)
- **Required Properties**: `displayName`, `description`, `severity`, `query`, `queryFrequency`, `queryPeriod`
- **MITRE Mapping**: `tactics` and `techniques` arrays (e.g., `["Persistence"]`, `["T1078"]`)
- **Incident Settings**: `createIncident: true`, grouping configuration, suppression duration
- **Entity Mappings**: Map query columns to SIEM entities (`Account`, `IP`, `Url`, etc.)
- **API Version**: `2023-12-01-preview` (latest at time of writing)

### Specific Sentinel Patterns
- **Lookup Watchlists**: `lookup kind=inner _GetWatchlist("ListName") on $left.UserId == $right.SearchKey`
- **Time Zone Conversion**: New Zealand default (`"Pacific/Auckland"`) - check client timezone per rule
- **Bin Operations**: `bin(TimeGenerated, BinPeriod)` for time-series analysis and thresholds
- **Conditional Access Parsing**: CA policies stored as JSON in `TargetResources[0].displayName` - extract with `tostring()`
- **User Identity Extraction**: Audit logs use `parse_json(tostring(InitiatedBy.user)).userPrincipalName`

## Development Workflows

### Creating a New Alert Rule
1. Write/test KQL query in `investigations/` (`.kql` file) or KQL workspace
2. Validate with real data for 24+ hours
3. Generate ARM template in `detection-rules/{domain}/{threat}/{control-name}.json` using VS Code snippets or Azure Sentinel UI export
4. Set `queryFrequency` and `queryPeriod` (typically `PT1H` or `PT2H`)
5. Map entities and MITRE tactics/techniques
6. Configure incident creation and suppression rules

### Adding KQL Investigations
- Place in `investigations/{domain}/` as descriptive `.kql` files
- Example: `investigations/identity-security/conditional-access/ca-policy-impact.kql`
- Include detailed comments on query purpose and configurable parameters at top

### Adding New Domain
If covering a new security threat domain:
1. Create folder: `detection-rules/{new-domain}/`
2. Create folder: `investigations/{new-domain}/`
3. Create `README.md` in both with:
   - Threat context and why it matters
   - List of included detections/queries
   - Dependencies (data sources, watchlists)
   - Deployment order if rules have dependencies
4. Add rules and queries following naming conventions

### Modifying Existing Rules/Queries
- Update `let` parameters at query/rule top - these are the "configuration" layer
- Preserve query logic/structure - avoid refactoring without testing
- Test timezone edge cases (DST transitions, multi-region scenarios)
- Verify watchlist dependencies still exist before deploying
- Update domain README if changing dependencies

### Organizing by Domain vs. Data Source
- **Detection rules**: Organized by threat domain (what you're protecting against)
- **Investigation queries**: Often organized by both domain AND data source (since analysts explore by data source)
- Example: `investigations/identity-security/conditional-access/` has queries specific to CA investigation
- But: `investigations/identity-security/sign-in-analysis/` groups sign-in queries across domains

## Key Files to Reference

| Purpose | Location |
|---------|----------|
| Email exfiltration detection | `detection-rules/email-security/` and `investigations/email-security/` |
| Timezone patterns | `investigations/concepts/timezone-conversions.kql` |
| Conditional Access monitoring | `detection-rules/identity-security/conditional-access/` and investigations |
| Anomaly detection baseline | `investigations/office-anomalies/unusual-office-activities-baseline.kql` |
| Privilege misuse monitoring | `detection-rules/identity-security/privileged-accounts/` |
| Emergency admin account monitoring | Reference data + `detection-rules/identity-security/privileged-accounts/` |

## Repository Navigation Tips

1. **Looking for a specific threat detection?**
   - Search by domain: `detection-rules/{domain}/*`
   - Read domain README for threat context

2. **Want to analyze a security incident?**
   - Browse `investigations/{domain}/` for ad-hoc queries
   - Or search by data source within domain folders

3. **Need to deploy rules?**
   - See `detection-rules/{domain}/README.md` for deployment order
   - Check dependencies on watchlists in `reference-data/`

4. **Setting up dashboards?**
   - Use `dashboards/development/` for testing
   - Deploy tested versions from `dashboards/production/` to live workspace

5. **Understanding a domain's full story?**
   - Read domain README at: `detection-rules/{domain}/README.md` or `investigations/{domain}/README.md`
   - See what detection rules, queries, and data dependencies exist

## Important Notes

- **All KQL is currently scoped to New Zealand timezone** - verify this assumption before cross-region deployment
- **Generated AI Content**: Some files (e.g., `Monitor Security Groups/`) were generated by language models - verify logic before production use
- **No automated build/test pipeline**: Changes require manual validation in Sentinel UI or local KQL validation
- **Watchlist Dependencies**: Always verify watchlist names exist in target workspace before deploying alert rules
- **Query Frequency**: Set based on detection urgency; most rules use 1-2 hour intervals
