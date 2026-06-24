# 00 - Config & shared privileged taxonomy

**Companion to:** `00-config-and-shared-taxonomy.kql`
**Type:** Reference (not a standalone report)

> Observable telemetry only. A highlighted action is a prompt to ask a question,
> never proof of misconduct.

## What it is

The single place that documents the **parameters** and the **privileged-activity
signals** used by every query in this folder. Each query is **self-contained** (it
repeats the parameters and the compact signal lists it needs), so it runs with no
dependencies. When you tune the model, change it **here first**, then copy the
changed list into the individual queries.

## Why classify the action, not the person

These three tables (`SigninLogs`, `OfficeActivity`, `AuditLogs`, `AzureActivity`)
do **not** carry a reliable role-membership feed, so we cannot assert "this user is
a Global Administrator". Instead we classify **each action** by whether the action
itself is administrative or high-impact, per source, and surface a
`Privileged = "Yes"/"No"` column with a `PrivilegeReason`. See
[`../docs/privileged-operations-taxonomy.md`](../docs/privileged-operations-taxonomy.md)
for the full rationale and the per-source rules.

## Parameters

| Parameter | Default | Meaning |
|---|---|---|
| `TargetUser` | `jane.doe@contoso.com` | **Set this** to the UPN you are investigating. |
| `StartTime` | `ago(30d)` | Window start. Replace with `datetime(2026-05-01)` for a fixed date. |
| `EndTime` | `now()` | Window end. Replace with `datetime(2026-06-01)` for a fixed date. |

## Signal lists

| List | Applies to | Used by |
|---|---|---|
| `PrivAuditCategories` | `AuditLogs.Category` | 01, 02, 03 |
| `PrivAuditOps` | `AuditLogs.OperationName` (substring) | 01, 02, 03 |
| `PrivOfficeOps` | `OfficeActivity.Operation` (substring) | 01, 02, 03 |
| `PrivOfficeCmdletRegex` | `OfficeActivity.Operation` (admin cmdlet shape, `(?i)`) | 01, 02, 03 |
| `PrivAzureActions` | `AzureActivity` action verb (`/write`, `/delete`, `/action`) | 01, 02, 03 |
| `PrivAzureFriendlyOps` | `AzureActivity.OperationNameValue` (friendly fallback) | 01, 02, 03 |
| `HighPrivAzure` | `AzureActivity` action prefix (RBAC / PIM / Key Vault / keys / identity) | 01, 03 |
| `MgmtSurfaceApps` | `SigninLogs.AppDisplayName` / `ResourceDisplayName` | 04 |

**Self-service downgrade (Entra).** Queries 01 / 02 / 03 do not rely on the lists
alone for `AuditLogs`: an otherwise-privileged action is downgraded to
`Privileged = No` when the actor acts on their own object
(`InitiatedBy.user.id == TargetResources[0].id`), which removes self-service noise
(own password change, own profile update) while keeping admin-on-another-user
actions.

## Notes

- Running this file returns the signal lists as a table - it is a documentation
  aid, not a report.
- The lists are a **first cut** for a typical tenant. Validate them against the
  client's real operations using the breakdown in query 02 before relying on the
  Privileged flag operationally.
