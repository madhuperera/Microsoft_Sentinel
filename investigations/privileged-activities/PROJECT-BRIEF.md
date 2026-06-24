# Project Brief - Privileged Activity Review (user-scoped)

> **Project code:** `sentinel-privileged-activities-01`
> **Status:** Phase 1 in progress - initial structure, docs, and the first four
> queries drafted. Unvalidated until run against live tenant data.
> **Branding:** none / generic (confirmed).
>
> This file is the reusable, living brief for the project. It is meant to be
> portable: drop it into another Claude project, Claude Code session, or repo and
> it should carry enough context to continue the work without re-explaining. It is
> updated whenever new guidance is provided.

---

## 1. Purpose

The client is concerned that **staff with privileged access may be performing
privileged activities the business is not aware of**, for example in Microsoft
Azure and Office 365. The deliverable is a **user-scoped review tool**:

> Give a username and a date range, run a query, and see **what that account did**
> in the period - with **administrative / privileged actions highlighted**.

The core question:

> "What did this user do during this period, and was any of it privileged /
> administrative?"

## 2. Framing (read before anything else)

- This is a **review / investigation** tool, not an alerting rule and not a
  verdict. It surfaces a named user's actions for a human to assess.
- A highlighted (privileged) action is a **prompt to ask a question**, never proof
  of misconduct. **Privileged work is normal and expected for privileged staff**;
  the goal is to confirm activity is *known and expected*.
- This is **event-level, privacy-sensitive monitoring of named individuals**. It
  must be lawful, proportionate, approved, and transparent to staff before
  operational use. Access to the queries should be restricted.
- Every output and document carries these caveats.

## 3. Scope and constraints

| Item | Decision |
|---|---|
| Phase | KQL + docs only. No workbook yet. |
| Data sources | `SigninLogs`, `OfficeActivity`, `AuditLogs` (Entra), `AzureActivity` (Azure). Nothing else. |
| "Azure Audit logs" means | **Both** `AuditLogs` and `AzureActivity` (confirmed). |
| Advanced Hunting | **Not used.** Sentinel / Log Analytics KQL only. |
| Input | A single `TargetUser` (UPN) + a `StartTime` / `EndTime` window. |
| Primary output | All of a user's activity, each row given an `ActivityClass` + `Severity`. |
| Classification basis | The **action**, not the person (no role-membership feed in these tables). Entra is operation-name primary; `Category` is a low-confidence secondary net. |
| Sign-ins | Treated as **authentication context**, not actions; kept in a separate query. |
| Configurability | User, window, and the privileged signal lists are all editable at the top of each file. |
| Branding | None / generic. |

## 4. Approach

- **Activity timeline** unions the three action-bearing sources (`OfficeActivity`,
  `AuditLogs`, `AzureActivity`) into one chronological view, each row classified
  privileged or not with a visible `PrivilegeReason`.
- **Privileged classification** tests each action against per-source signals
  (categories / curated operations / admin-cmdlet shapes / control-plane write
  verbs). See `docs/privileged-operations-taxonomy.md`.
- **Sign-in context** is a separate lens on `SigninLogs` (where / when / how the
  user authenticated, and whether they hit a management surface), used to explain
  how a privileged action was reached.

## 5. Repository layout for this project

```
investigations/privileged-activities/
|-- README.md                          - index + run order
|-- PROJECT-BRIEF.md                   - this file (living brief)
|-- docs/
|   |-- methodology.md                 - sources, actions vs auth, run order, output shape
|   |-- privileged-operations-taxonomy.md - per-source rules behind the Privileged flag
|   \-- assumptions-and-limitations.md - guardrails, caveats, validation checklist
\-- queries/   (each NN-*.kql has a companion NN-*.md walkthrough)
    |-- 00-config-and-shared-taxonomy.kql  - canonical params + privileged signal lists (reference)
    |-- 01-user-activity-timeline.kql      - PRIMARY: all activity, privileged highlighted
    |-- 02-user-activity-summary.kql       - OVERVIEW: counts per source/category
    |-- 03-user-privileged-activity.kql    - PRIVILEGED: highlights only
    \-- 04-user-signin-context.kql         - CONTEXT: sign-in / location / MFA
```

## 6. Guidance log (append-only, newest first)

- **2026-06-24** (update) - Second external code review (run against the original).
  Acted on it with a **full restructure** from the binary `Privileged = Yes/No`
  flag to an explicit **`ActivityClass` + `Severity`** model (client chose: go fully
  to classes, no binary flag). Key changes: (1) separated confirmed privileged
  admin from high-risk sharing / data exposure and from management-surface sign-in
  context (distinct classes); (2) made Entra **operation-name primary** after
  confirming via docs that `AuditLogs.Category` is documented as effectively fixed
  (`"Audit"`) in Log Analytics and that activity-to-category mapping is inconsistent
  (PIM under App/Group management; credential/MFA/token ops under UserManagement) -
  `Category` is now a low-confidence secondary net only; (3) demoted the Office
  admin-cmdlet shape and the category net to a `Possible admin activity (review)`
  class; (4) expanded Azure high-impact coverage (diagnostic settings, policy
  assignments, security/Sentinel, Log Analytics, VM extensions / run-command,
  automation, NSG/route/firewall/private-endpoint, mgmt-group scope, key
  enumeration); (5) expanded Office coverage (connectors, DLP/retention, eDiscovery
  / compliance search, management roles); (6) added cross-tenant / auth-method /
  security-defaults Entra ops; (7) severity now factors success vs failure (failed
  attempts downgraded one level, kept visible); (8) added explicit control-plane-
  only and "not full coverage" limitation statements to README and every query
  header. Output schema for 01/03 is now `TimeGenerated, Source, Actor,
  ActivityClass, Severity, Outcome, Category, Operation, Result, ClientIP, Target,
  Details, SeverityRank`.
- **2026-06-24** (update) - Ran a docs-verified subagent review of the privileged
  classification logic and applied the findings. Fixed strings that never matched
  (`add oauth2permissiongrant` -> added `add delegated permission grant`;
  `add unverified domain` -> `add domain`); added missing high-impact Entra ops
  (token / strong-auth / BitLocker-key tamper, `restore user`, `set force change
  user password`, `add app role assignment to group`), O365 ops (`updateinboxrules`,
  `set-casmailbox`, management-role and compliance-search ops, `sharingset`), and
  Azure high-impact entries (storage `listKeys`, PIM-via-ARM, App Service
  `publishxml`). Made the O365 admin-cmdlet regex case-insensitive (`(?i)`). Added
  an Entra **self-service downgrade** (actor == target) to cut false positives on
  `update user` / own password change. Added an `AzureActivity` friendly-name
  fallback (`PrivAzureFriendlyOps`) so sensitive ops with no change verb in their
  friendly name are still caught. Documented known blind spots (data-plane Key
  Vault / Storage, mail-forwarding parameter, PIM category placement).
- **2026-06-24** - Project initiated under code `sentinel-privileged-activities-01`.
  Phase 1 = KQL + docs only, no workbook. Data sources limited to `SigninLogs`,
  `OfficeActivity`, `AuditLogs`, `AzureActivity`; no Advanced Hunting. "Azure Audit
  logs" confirmed to mean both `AuditLogs` and `AzureActivity`. Branding: none /
  generic. Approach: show all activity for a named user over a date range, classify
  each action privileged/not (classify the action, not the person, since no
  role-membership feed exists in these tables), keep sign-ins as separate auth
  context. Delivered: structure, README, brief, methodology, taxonomy,
  assumptions-and-limitations, and queries 00-04 with per-query companion docs.

## 7. Open items to validate before Phase 2 (workbook)

See `docs/assumptions-and-limitations.md` for the full checklist. Headlines:

- Confirm all four tables are ingested with adequate retention.
- Validate / tune the privileged signal lists against the tenant's real operations
  (run query 02), then propagate to 01 / 02 / 03.
- Spot-check query 03 against a known privileged user and a known non-privileged
  user.
- Decide whether to add a **privileged-roster watchlist** so we can also weight
  *who* acted, not just *what* was done.
- Confirm framing, access controls, and staff transparency with the client.
