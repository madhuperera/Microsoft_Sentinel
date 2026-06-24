# 00 - Config & shared activity taxonomy

**Companion to:** `00-config-and-shared-taxonomy.kql`
**Type:** Reference (not a standalone report)

> Observable telemetry only. A classified action is a prompt to ask a question,
> never proof of misconduct.

## What it is

The single place that documents the **parameters** and the **classification
signals** used by every query in this folder. Each query is **self-contained** (it
repeats the parameters and the signal lists it needs), so it runs with no
dependencies. When you tune the model, change it **here first**, then copy the
changed list into the individual queries.

## Classification model

Every action gets an `ActivityClass` and a `Severity` instead of a binary
privileged flag. This separates three things that must not be confused: confirmed
administrative actions, high-risk user / data-exposure actions, and (for sign-ins)
management-surface access context. Running this file returns the **class-to-base-
severity map** as a table. Full per-source rules and rationale are in
[`../docs/privileged-operations-taxonomy.md`](../docs/privileged-operations-taxonomy.md).

`ActivityClass` values: `Privileged role/RBAC change`, `Privileged policy/security
config change`, `App/consent/service principal change`, `High-impact Azure
control-plane change`, `User/group/identity admin change`, `Azure control-plane
change`, `High-risk sharing/data exposure`, `Requires manual review`, `Possible
admin activity (review)`, `Management-surface sign-in`, `Normal user activity`.

`Severity` = the class base level, then **failed attempts are downgraded one level**
(High to Medium, Medium to Low) so successful changes rank above failed ones.

## Why classify the action, not the person

These tables carry no reliable role-membership feed, so we classify each action by
what it is, not by whether the actor is "an admin". A privileged-roster / group
watchlist (planned) would let us also weight *who* / *what* was targeted.

## Parameters

| Parameter | Default | Meaning |
|---|---|---|
| `TargetUser` | `jane.doe@contoso.com` | **Set this** to the UPN you are investigating. |
| `StartTime` | `ago(30d)` | Window start. Replace with `datetime(2026-05-01)` for a fixed date. |
| `EndTime` | `now()` | Window end. Replace with `datetime(2026-06-01)` for a fixed date. |

## Signal lists

| List | Maps to class | Applies to | Used by |
|---|---|---|---|
| `EntraRoleOps` | Privileged role/RBAC change | `AuditLogs.OperationName` | 01, 02, 03 |
| `EntraAppOps` | App/consent/service principal change | `AuditLogs.OperationName` | 01, 02, 03 |
| `EntraPolicyOps` | Privileged policy/security config change | `AuditLogs.OperationName` | 01, 02, 03 |
| `EntraIdentityOps` | User/group/identity admin change (non-self-service) | `AuditLogs.OperationName` | 01, 02, 03 |
| `EntraReviewOps` | Requires manual review | `AuditLogs.OperationName` | 01, 02, 03 |
| `PrivAuditCategoriesSecondary` | Possible admin activity (review) | `AuditLogs.Category` (low confidence) | 01, 02, 03 |
| `OfficeRoleOps` | Privileged role/RBAC change | `OfficeActivity.Operation` | 01, 02, 03 |
| `OfficeSecurityCfgOps` | Privileged policy/security config change | `OfficeActivity.Operation` | 01, 02, 03 |
| `OfficeExposureOps` | High-risk sharing/data exposure | `OfficeActivity.Operation` | 01, 02, 03 |
| `PrivOfficeCmdletRegex` | Possible admin activity (review) | `OfficeActivity.Operation` shape | 01, 02, 03 |
| `PrivAzureActions` | Azure control-plane change | `AzureActivity` action verb | 01, 02, 03 |
| `PrivAzureFriendlyOps` | High-impact Azure control-plane change | `AzureActivity.OperationNameValue` | 01, 02, 03 |
| `HighPrivAzure` | High-impact Azure control-plane change | `AzureActivity` action prefix | 01, 02, 03 |
| `MgmtSurfaceApps` | Management-surface sign-in | `SigninLogs` app / resource | 04 |

## Key design points

- **Entra is operation-name primary.** `AuditLogs.Category` is documented by
  Microsoft as effectively fixed (`"Audit"`) in Log Analytics and the activity-to-
  category mapping is inconsistent, so `Category` is only a low-confidence secondary
  net (`PrivAuditCategoriesSecondary`) and must be validated per tenant.
- **Self-service downgrade (Entra).** An identity-admin operation where the actor
  acts on their own object (`InitiatedBy.user.id == TargetResources[0].id`) is
  classed `Normal user activity`, not an admin change.
- **Low-confidence is explicit.** The Office admin-cmdlet shape and the Entra
  category net map to `Possible admin activity (review)`, never to a confirmed
  class.
