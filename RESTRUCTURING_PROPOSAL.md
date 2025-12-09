# Microsoft Sentinel Repository Restructuring Proposal

## Executive Summary
The current structure organizes content by **artifact type** (Analytics, KQL, Watchlists, Workbooks), which scatters related detection logic across multiple directories. This proposal reorganizes by **security domain** to improve discoverability, maintainability, and reduce duplicate queries.

---

## Current Pain Points

1. **Poor Discoverability**: Hard to find all assets related to a specific threat (e.g., "Conditional Access monitoring")
2. **Query Duplication**: Same monitoring logic may exist in Analytics, KQL, and Workbooks separately
3. **Unclear Dependencies**: Watchlist usage isn't well-documented; hard to know which queries rely on which watchlists
4. **Dev/Prod Mixing**: DEV and PROD workbooks in same directory with no clear naming convention
5. **Scattered Documentation**: README files in one folder, KQL concepts in another; hard to understand intent
6. **Naming Ambiguity**: Some files AI-generated without clear warning; template vs. standalone query distinction unclear

---

## Proposed Structure

### Tier 1: Domain-Based Organization
```
sentinel/
├── detection-rules/           # Scheduled alert rules (deployed to Sentinel)
├── investigations/            # Ad-hoc KQL queries for investigations
├── reference-data/            # Watchlists and lookup tables
├── dashboards/                # Workbooks and visualizations
├── .github/                   # GitHub config and docs
├── docs/                      # Architecture and patterns
└── README.md                  # Root documentation
```

### Tier 2: Domain Subdivision (within each tier)
```
detection-rules/
├── identity-security/
│   ├── README.md                    # Domain overview
│   ├── conditional-access/
│   │   ├── ca-changes-afterhours.json
│   │   ├── ca-exclusion-updates.json
│   │   └── README.md
│   ├── privileged-accounts/
│   │   ├── emergency-breakglass-login.json
│   │   ├── protected-user-tampering.json
│   │   └── README.md
│   └── unauthorized-access/
│       ├── temp-access-pass-monitoring.json
│       ├── unmanaged-device-registration.json
│       └── README.md
├── email-security/
│   ├── README.md
│   ├── attachment-controls/
│   │   ├── attachment-leak-external.json
│   │   ├── attachment-leak-personal-domains.json
│   │   └── README.md
│   └── ...
├── office-anomalies/
│   ├── README.md
│   ├── unusual-office-activities/
│   │   ├── office-anomaly-baseline.json
│   │   ├── office-anomaly-graph.json
│   │   └── README.md
│   └── ...
└── keeper-security/
    ├── README.md
    └── ...

investigations/
├── identity-security/
│   ├── README.md
│   ├── conditional-access/
│   │   ├── ca-policy-impact.kql
│   │   ├── README.md
│   └── ...
├── email-security/
│   ├── monitoring-attachments.kql
│   ├── email-exfiltration-patterns.kql
│   └── README.md
├── billing-analysis/
│   ├── README.md
│   ├── billing-queries.kql
│   └── ...
├── device-activities/
│   └── ...
├── sign-in-logs/
│   ├── trusted-ips-user-counts.kql
│   ├── ca-policy-impact.kql
│   └── README.md
├── concepts/
│   ├── timezone-conversions.kql
│   ├── baseline-anomaly-detection.kql
│   ├── watchlist-lookups.kql
│   └── README.md
└── ...

reference-data/
├── README.md
├── emergency-breakglass-accounts/
│   ├── emergency-breakglass-accounts.csv
│   └── README.md          # Maintenance instructions, format spec
├── disabled-accounts/
│   ├── disabled-accounts.csv
│   └── README.md
├── office-locations/
│   ├── office-locations.csv
│   └── README.md
└── ...

dashboards/
├── README.md
├── production/
│   ├── insider-threats/
│   │   ├── PROD_InsiderThreats.json
│   │   └── README.md
│   ├── conditional-access/
│   │   ├── PROD_ConditionalAccessPolicyImpact.json
│   │   └── README.md
│   └── ...
├── development/
│   ├── insider-threats/
│   │   ├── DEV_InsiderThreats.json
│   │   └── README.md
│   ├── conditional-access/
│   │   ├── DEV_ConditionalAccessPolicyImpact.json
│   │   └── README.md
│   ├── intune-devices/
│   ├── sharepoint-access/
│   └── ...
├── essential8/
│   ├── essential8-compliance.json
│   └── README.md
└── ...

docs/
├── ARCHITECTURE.md              # High-level design decisions
├── PATTERNS.md                  # KQL patterns, naming conventions
├── MIGRATION-GUIDE.md           # How to deploy and manage alerts
├── ADDING-NEW-DETECTION.md      # Step-by-step guide
└── DOMAIN-GLOSSARY.md           # Threat categories, terminology
```

---

## Key Design Decisions

### 1. **Domain-Based Organization (Top Level)**
**Why**: Security operations team think in threat domains (identity, email, network, etc.), not artifact types. This mirrors how SOC analysts investigate incidents.

**Example**: A Conditional Access incident requires:
- ✅ Detection rule (single file: `detection-rules/identity-security/conditional-access/ca-changes-afterhours.json`)
- ✅ Ad-hoc investigation queries (folder: `investigations/identity-security/conditional-access/`)
- ✅ Watchlist reference (folder: `reference-data/office-locations/`)
- ✅ Dashboards (folder: `dashboards/production/conditional-access/`)

All in logical, discoverable locations.

### 2. **Three-Level Hierarchy for Artifacts**
- **Tier 1**: Artifact type (detection-rules, investigations, reference-data, dashboards)
- **Tier 2**: Security domain (identity-security, email-security, office-anomalies)
- **Tier 3**: Specific threat/control (conditional-access, privileged-accounts, etc.)

**Benefit**: Scales as repo grows; easy to add new threats within existing domains.

### 3. **Separate Dev/Prod Dashboards**
- **Current**: Mixed naming (`DEV_` vs `PROD_` prefix on same-level files)
- **Proposed**: Separate `production/` and `development/` subdirectories with clear intent

**Benefit**: Prevents accidental deployment of development dashboards; clarifies lifecycle.

### 4. **README in Every Domain Folder**
**Purpose**: Document:
- What threat/control this domain addresses
- Which external dependencies (watchlists, data sources) each alert requires
- Deployment sequence (e.g., Conditional Access rules must be deployed before impact dashboards)
- Known limitations or false positive tuning needed

**Example** (`detection-rules/identity-security/conditional-access/README.md`):
```markdown
# Conditional Access Monitoring

## Threat Context
Detects unauthorized or anomalous modifications to Entra ID Conditional Access policies, 
which control access to critical resources. Unauthorized changes could indicate:
- Compromised admin account
- Insider threat attempting privilege escalation
- Policy bypass attempts

## Included Detections
- `ca-changes-afterhours.json` - Changes outside business hours (High severity)
- `ca-exclusion-updates.json` - Group exclusions added to policies (Medium severity)

## Dependencies
- Watchlist: `office-locations` (required for timezone accuracy)
- Data source: `AuditLogs` table (Microsoft Entra ID)
- Client timezone: Pacific/Auckland (verify before multi-region deployment)

## Deployment Order
1. Deploy detection rules to Sentinel
2. Configure `office-locations` watchlist with your office IP ranges
3. Deploy dashboards from `dashboards/production/conditional-access/`
```

### 5. **Investigation Queries by Data Source**
Keep ad-hoc queries organized by **data source** (SignInLogs, AuditLogs, OfficeActivity, etc.) within each domain, with a `concepts/` folder for reusable patterns.

**Rationale**: Investigators often explore a single data source across multiple domains (e.g., "show me all SignIn anomalies").

### 6. **Reference Data with Maintenance Docs**
Each watchlist gets its own folder with:
- `.csv` file (the actual data)
- `README.md` (format spec, how to update, frequency)

Example (`reference-data/emergency-breakglass-accounts/README.md`):
```markdown
# Emergency Break Glass Accounts Watchlist

## Purpose
Identifies emergency admin accounts that should have restricted/monitored access.

## Format
| SearchKey | UserId | AccountName | CreatedDate |
| --- | --- | --- | --- |
| user@domain.com | xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx | Emergency Admin 1 | 2024-01-01 |

## Maintenance
- Update quarterly after account reviews
- Add new emergency accounts immediately upon creation
- Document reason for addition in commit message
- Remove accounts when no longer needed

## Usage
Referenced in: `detection-rules/identity-security/privileged-accounts/emergency-breakglass-login.json`
```

---

## Migration Strategy

### Phase 1: Setup (1 day)
1. Create new folder structure locally
2. Update `.github/copilot-instructions.md` with new structure
3. Create README templates for each domain

### Phase 2: Move Files (2-3 days)
1. Move detection rules to `detection-rules/{domain}/{threat}/`
2. Move KQL queries to `investigations/{domain}/` preserving data-source structure
3. Move watchlists to `reference-data/{watchlist-name}/`
4. Move workbooks to `dashboards/{prod|dev}/{domain}/`
5. Update all import/reference paths in JSON/KQL files

### Phase 3: Documentation (2 days)
1. Write domain README files explaining threat context
2. Document watchlist dependencies in `MIGRATION-GUIDE.md`
3. Add deployment order guide

### Phase 4: Validation (1 day)
1. Verify all JSON files are valid ARM templates
2. Test KQL query paths and watchlist references
3. Create git commit with all changes

### Phase 5: Deployment (Optional, with stakeholder approval)
1. Merge to main branch
2. Announce restructure to SOC team
3. Update runbooks/deployment procedures

---

## Comparison: Current vs. Proposed

### Finding a Conditional Access Detection Rule

**Current**:
```
Analytics/
├── Templates/
│   ├── SOC-High-ConditionalAccessChanges-AfterHours.json ← buried here
│   ├── SOC-High-ConditionalAccessExclusionGroupUpdates.json
│   └── ...other 20+ files in templates/
├── Monitor Security Groups/
│   ├── README.md
```

**Proposed**:
```
detection-rules/identity-security/conditional-access/
├── README.md ← domain context first
├── ca-changes-afterhours.json ← clear naming
├── ca-exclusion-updates.json
└── (easy to add more CA rules here)
```

### Finding Investigation Queries for a Domain

**Current**:
```
KQL/
├── Billing/
├── Concepts/
├── DeviceActivities/
├── EmailActivities/
├── Guests/
├── Intune/
├── Office_Activities/
└── SignInLogs/
    ├── UntrustedIPsWithUserCounts.kql
    ├── CAPolicyImpact.kql ← buried, hard to relate to CA detection
```

**Proposed**:
```
investigations/identity-security/conditional-access/
├── ca-policy-impact.kql ← clearly related to detection rules above
└── README.md

investigations/sign-in-logs/  (for cross-domain sign-in analysis)
├── trusted-ips-user-counts.kql
└── README.md
```

---

## Naming Conventions (Applies to New Files)

### Detection Rules (JSON)
- Pattern: `{control|threat}-{variant}.json`
- Examples:
  - `ca-changes-afterhours.json` (Conditional Access detection rule)
  - `emergency-breakglass-login.json` (Privileged account detection)
  - `attachment-leak-external.json` (Email exfiltration)
- Avoid: `SOC-High-ConditionalAccessChanges-AfterHours.json` (too long; severity is in JSON metadata)

### Investigation Queries (KQL)
- Pattern: `{data-source}-{query-purpose}.kql` or `{threat}-{analysis}.kql`
- Examples:
  - `signin-log-anomalies.kql`
  - `office-activity-baseline.kql`
  - `ca-policy-impact.kql` (relates to conditional access domain)

### Watchlists (CSV)
- Pattern: `{watchlist-name}.csv` (kebab-case)
- Examples:
  - `emergency-breakglass-accounts.csv`
  - `office-locations.csv`
  - `disabled-accounts.csv`

### Dashboards (JSON)
- Pattern: `{ENV}_{purpose}.json` (keep current convention)
- Examples:
  - `PROD_InsiderThreats.json`
  - `DEV_ConditionalAccessPolicyImpact.json`
- Organized in `dashboards/{production|development}/{domain}/`

### Concept Queries (KQL in `investigations/concepts/`)
- Pattern: `{concept-name}.kql`
- Examples:
  - `timezone-conversions.kql`
  - `watchlist-lookups.kql`
  - `baseline-anomaly-detection.kql`

---

## Backward Compatibility & Git History

This restructure is **not backward compatible** with existing file paths, but **preserves git history**:
1. Use `git mv` (not copy/delete) to move files so git preserves blame/history
2. Old Analytics/Templates/ folder becomes detection-rules/
3. Old KQL/ folder becomes investigations/
4. Scripts that reference old paths need 1-time update

---

## Benefits Summary

| Aspect | Current | Proposed |
|--------|---------|----------|
| **Discoverability** | Threat scattered across folders | All assets for threat in one place |
| **Query Reuse** | Hard to find similar queries | Grouped by domain/data-source |
| **Dependency Tracking** | Watchlist deps unclear | README documents all deps |
| **Onboarding** | New SOC analyst must learn all 4 folder types | Read domain README, understand context |
| **Scalability** | Adding 50 more rules clutters top level | New `detection-rules/{domain}/{threat}/` folder |
| **Dev/Prod Clarity** | Naming prefix only | Separate directory trees |
| **Documentation** | Scattered READMEs | Docs at each level of hierarchy |

---

## Questions to Consider Before Implementation

1. **Should we include a `data-model/` folder** for schema documentation of custom tables created by Sentinel?
2. **Should we add a `scripts/` folder** for deployment automation (e.g., PowerShell to bulk-upload rules)?
3. **What's the deployment frequency?** If frequent (daily), we might add a `changelog/` folder tracking what changed each week.
4. **Multi-tenant?** If supporting multiple Sentinel workspaces, should we add a `tenants/` tier or keep repo generic?
5. **Content source attribution?** Should we add a `CONTRIBUTORS.md` noting which queries are AI-generated vs. hand-crafted (for quality tracking)?

---

## Next Steps

1. Review this proposal with SOC team for feedback
2. Validate domain categories (are they correct for your threat landscape?)
3. Decide on optional folders (scripts/, data-model/, etc.)
4. Create a **test branch** and reorganize a single domain (e.g., identity-security) as proof-of-concept
5. Run through migration checklist before merging to main
