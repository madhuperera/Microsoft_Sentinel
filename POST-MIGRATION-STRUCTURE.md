# Post-Migration Directory Structure

This document shows the final repository structure after the domain-based reorganization.

## Complete Directory Tree

```
Microsoft_Sentinel/
│
├── .github/
│   └── copilot-instructions.md          ← Updated for new structure
│
├── detection-rules/                     ✨ NEW: Scheduled alert rules
│   ├── README.md                        ← Main guide for detection rules
│   └── identity-security/               
│       ├── README.md                    ← Identity threat context & dependencies
│       ├── conditional-access/
│       │   ├── ca-changes-afterhours.json
│       │   └── ca-exclusion-updates.json
│       ├── privileged-accounts/
│       │   ├── emergency-breakglass-login.json
│       │   └── protected-user-tampering.json
│       ├── unauthorized-access/
│       │   ├── temp-access-pass-monitoring.json
│       │   └── unmanaged-device-registration.json
│       └── security-groups/
│
├── investigations/                      ✨ NEW: Ad-hoc investigation queries
│   ├── README.md                        ← Main guide for queries
│   ├── identity-security/
│   │   ├── conditional-access/
│   │   │   └── ca-policy-impact.kql
│   │   ├── privileged-accounts/
│   │   │   └── privileged-account-logons.kql
│   │   ├── security-groups/
│   │   │   ├── README.md                ← Moved from Analytics/Monitor Security Groups/
│   │   │   └── monitor-security-group-changes.kql
│   │   ├── sign-in-analysis/
│   │   │   └── untrusted-ips-user-counts.kql
│   │   ├── inactive-logins/
│   │   │   ├── inactive-logins.kql
│   │   │   ├── inactive-logins-ubea.kql
│   │   │   └── inactive-logins-extended.kql
│   │   ├── password-cracking-attempts.kql
│   │   ├── phishing-resistance-logins.kql
│   │   └── security-registration-changes.kql
│   │
│   ├── email-security/
│   │   ├── README.md                    ← Email threat analysis guide
│   │   ├── attachment-controls/
│   │   │   ├── attachment-leak-external.kql
│   │   │   ├── attachment-leak-personal-domains.kql
│   │   │   └── monitoring-attachments.kql
│   │   ├── email-attachment-count-per-day.kql
│   │   └── email-attachments-count-per-domain.kql
│   │
│   ├── office-anomalies/
│   │   ├── unusual-office-activities-baseline.kql
│   │   ├── unusual-office-activities-extended.kql
│   │   ├── unusual-office-activities-graph.kql
│   │   ├── password-cracking-attempts-chart.kql
│   │   ├── anonymous-access-by-staff.kql
│   │   ├── guest-sharing-by-staff.kql
│   │   └── old-file-formats.kql
│   │
│   ├── device-security/
│   │   ├── device-registrations.kql
│   │   ├── device-logon-report.kql
│   │   ├── file-activity-report.kql
│   │   └── intune/
│   │       └── android-devices.kql
│   │
│   ├── billing-analysis/
│   │   ├── billed-data-over-time.kql
│   │   ├── billed-data-by-computer.kql
│   │   └── billed-data-by-table.kql
│   │
│   ├── guest-access/
│   │   └── guest-report.kql
│   │
│   ├── keeper-security/
│   │   └── policy-changes.kql
│   │
│   └── concepts/                        ← Reusable KQL patterns
│       └── timezone-conversions.kql
│
├── reference-data/                      ✨ NEW: Watchlists & lookup tables
│   ├── README.md                        ← Watchlist guide & examples
│   └── emergency-breakglass-accounts/
│       ├── README.md                    ← Maintenance & usage instructions
│       └── emergency-breakglass-accounts.csv
│
├── dashboards/                          ✨ NEW: Workbooks & visualizations
│   ├── README.md                        ← Workbook deployment guide
│   │
│   ├── production/                      ← Production-ready dashboards
│   │   ├── conditional-access/
│   │   │   └── DEV_ConditionalAccessPolicyImpact.json
│   │   ├── insider-threats/
│   │   │   └── PROD_InsiderThreats.json
│   │   ├── essential8/
│   │   │   └── PROD_SOC-Essential-8.json
│   │   ├── intune-devices/
│   │   │   └── PROD_SOC-IntuneDevices.kql
│   │   └── sharepoint-access/
│   │       └── PROD_SharePointAccess.json
│   │
│   └── development/                     ← Non-production test dashboards
│       ├── conditional-access/
│       │   └── DEV_ConditionalAccessPolicyImpact.json
│       ├── insider-threats/
│       │   └── DEV_InsiderThreats.json
│       ├── essential8/
│       │   └── DEV_SOC-Essential-8.json
│       └── sharepoint-access/
│           └── DEV_SharePointAccess.json
│
├── RESTRUCTURING_PROPOSAL.md            ← Original proposal document
├── MIGRATION_COMPLETE.md                ← This migration's completion summary
├── migrate-to-domain-structure.ps1      ← Migration script (one-time use)
├── LICENSE
├── README.md                            ← Project overview
└── .gitignore
```

## Migration Statistics

| Category | Count | Notes |
|----------|-------|-------|
| **Detection Rules** | 6 files | ARM templates for scheduled alerts |
| **Investigation Queries** | 32 files | KQL ad-hoc analysis queries |
| **Reference Data** | 1 file | Emergency accounts watchlist |
| **Dashboards** | 8 files | Workbook visualizations |
| **README Files** | 7 created | Domain documentation |
| **Total Files Moved** | 45 | Using `git mv` to preserve history |
| **Directories Created** | 28 | Organized by domain + environment |
| **Git Commits** | ~45 file moves | Staged, awaiting commit |

## How to Find Things Now

### Scenario 1: "I need to update the Conditional Access detection rule"
```
detection-rules/identity-security/conditional-access/
├── ca-changes-afterhours.json
├── ca-exclusion-updates.json
└── (related investigation queries in investigations/identity-security/conditional-access/)
```

### Scenario 2: "I'm investigating an email exfiltration incident"
```
investigations/email-security/
├── README.md (explains email security threats)
├── attachment-controls/
│   ├── attachment-leak-external.kql
│   ├── attachment-leak-personal-domains.kql
│   └── monitoring-attachments.kql
└── (detection rules in detection-rules/email-security/ - but email-security domain not yet created)
```

### Scenario 3: "I need to add a new detection rule for broken cloud"
```
1. Create folder: detection-rules/cloud-security/broken-auth/ (new domain + threat)
2. Create: detection-rules/cloud-security/broken-auth/README.md
3. Add rule: detection-rules/cloud-security/broken-auth/oauth-abuse.json
4. Add query: investigations/identity-security/auth-anomalies/oauth-abuse.kql
5. Link in README: reference dependencies & deployment order
```

## Next Actions

### Required (Before Commit)
- [ ] Review changes: `git status`
- [ ] Verify git history: `git log --follow detection-rules/identity-security/conditional-access/ca-changes-afterhours.json`
- [ ] Commit changes: `git commit -m "refactor: reorganize repository structure by security domain"`

### Optional (After Commit)
- [ ] Archive old directories: `rm -r Analytics KQL Workbooks Watchlists`
- [ ] Create additional domain READMEs (concepts, device-security, etc.)
- [ ] Update external documentation/runbooks referencing old paths
- [ ] Record video walkthrough of new structure for team

### Future Maintenance
- When adding new detection rule → put in `detection-rules/{domain}/{threat}/`
- When adding new query → put in `investigations/{domain}/`
- When updating watchlist → update `.csv` file + check dependencies
- When creating new domain → create README with threat context & dependencies

---

**Repository successfully restructured!** 🎉
