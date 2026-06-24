# Methodology - user activity review with privileged highlighting

How the queries identify and present a single user's activity, and why they are
built the way they are. Meant to be reviewed and adjusted by another Microsoft
security consultant. Nothing here treats activity as a measure of productivity -
see [`assumptions-and-limitations.md`](assumptions-and-limitations.md).

---

## 1. The question this answers

The client is concerned that staff with privileged access may be performing
privileged activities the business is not aware of. The deliverable is a
**user-scoped lookup**: give a UPN and a date range, run a query, and see
**everything that user did**, with administrative / privileged actions
**highlighted**.

This is deliberately a *review / investigation* tool, not an alerting rule. It does
not decide that anything is wrong; it puts a named user's actions in front of a
human with the high-impact ones marked.

## 2. Sources and what each one contributes

| Source | Table | Contributes | Actor field |
|---|---|---|---|
| Entra sign-in logs | `SigninLogs` | Authentication context: when / where / how the user signed in (query 04). | `UserPrincipalName` |
| Office 365 activity | `OfficeActivity` | Actions in Exchange, SharePoint, OneDrive, Teams, incl. admin cmdlets. | `UserId` |
| Entra ID audit | `AuditLogs` | Directory actions: roles, apps, users, policies, Conditional Access. | `InitiatedBy.user.userPrincipalName` |
| Azure activity | `AzureActivity` | Azure control-plane changes: RBAC, Key Vault, resource writes / deletes. | `Caller` |

No Advanced Hunting, and no tables beyond these four. ("Azure Audit logs" was
confirmed to mean *both* the Entra `AuditLogs` table and the Azure `AzureActivity`
table; both are built for, and the queries degrade to whichever is populated.)

## 3. Actions vs authentication

`SigninLogs` records **authentications**, not actions, and is high-volume. Mixing
it into the activity timeline would bury the actual actions. So:

- The **activity timeline** (queries 01 / 02 / 03) unions only the three
  **action-bearing** sources: `OfficeActivity`, `AuditLogs`, `AzureActivity`.
- **Sign-in context** (query 04) is a separate lens on `SigninLogs`, used to
  explain *how* a privileged action was reached (device, location, client, MFA,
  Conditional Access, management surface).

## 4. Activity classification (`ActivityClass` + `Severity`)

Each action row is given an **`ActivityClass`** and a **`Severity`** rather than a
single privileged yes/no flag. This keeps three things separate that must not be
confused: confirmed administrative actions, high-risk user / data-exposure actions,
and management-surface sign-in context. We classify the **action, not the person**
(no role-membership feed exists in these tables). The full class list, per-source
rules, and rationale are in
[`privileged-operations-taxonomy.md`](privileged-operations-taxonomy.md). In short:

- **Entra ID** classification is **operation-name primary**. Microsoft documents
  the `AuditLogs` `Category` column as effectively fixed in Log Analytics, and the
  activity-to-category mapping is inconsistent (PIM under ApplicationManagement /
  GroupManagement; credential / MFA / token ops under UserManagement). So
  `OperationName` drives the class; `Category` is a low-confidence secondary net
  that must be tenant-validated. Self-service (actor == target) drops to normal.
- **Office 365**: curated lists map to role / security-config / data-exposure
  classes; an admin `RecordType` or admin-cmdlet shape is only **"Possible admin
  activity (review)"** (an indicator, not a confirmed privileged action).
- **Azure**: `Administrative` write / delete / action; an expanded high-impact list
  (RBAC/PIM, Key Vault, logging/security tampering, compute execution, automation,
  networking, key enumeration, management-group scope) gets the high-impact class.

**Severity** is the class's base level, then **failed attempts are downgraded one
level** (High to Medium, Medium to Low) so successful changes rank above failed
ones while failures remain visible (`Outcome` = Success / Failure / Other).

## 5. Identity resolution

Each source carries the actor in a different field (see the table in section 2).
Every query matches the user case-insensitively (`tolower(...) == tolower(TargetUser)`)
on that source's own field. Because the investigator names the user explicitly,
there is no service-account / guest exclusion - the lens is intentionally pointed
at one identity the investigator chose.

`AzureActivity.Caller` holds a UPN for user-initiated actions and a GUID for
service principals; matching on the UPN naturally selects the user's own actions.

## 6. Date range

All queries expose `StartTime` / `EndTime`. The defaults (`ago(30d)` / `now()`)
give a rolling 30-day window; replace either with a fixed `datetime(...)` to pin an
exact range, e.g. `let StartTime = datetime(2026-05-01); let EndTime =
datetime(2026-06-01);`. `between (StartTime .. EndTime)` is inclusive. All times
are UTC.

## 7. Run order

1. **02 - summary** - shape of the activity: counts by `Source` / `ActivityClass` /
   `Severity`.
2. **01 - timeline** - the full chronological account, every row classified
   (normal activity included).
3. **03 - flagged only** - everything except `Normal user activity`, highest
   severity first.
4. **04 - sign-in context** - correlate the flagged actions with how the user
   authenticated.

## 8. Output shape (for later workbook use)

The columns are deliberately uniform across 01 / 03 (`TimeGenerated, Source,
Actor, ActivityClass, Severity, Outcome, Category, Operation, Result, ClientIP,
Target, Details, SeverityRank`) so a future Sentinel workbook can bind a single
grid with conditional formatting on `Severity` / `ActivityClass`, sort on
`SeverityRank`, drive `TargetUser` / time range from parameters, and drill into
`Details`. Query 02 is shaped for a summary tile / bar chart by class and severity.
