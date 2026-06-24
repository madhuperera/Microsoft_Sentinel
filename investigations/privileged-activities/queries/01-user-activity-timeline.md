# 01 - User activity timeline

**Companion to:** `01-user-activity-timeline.kql`
**Type:** Primary report
**Output:** one row per action across Office 365, Entra ID, and Azure - newest first

> Observable telemetry only. A highlighted action is a **prompt to review**, not
> proof of wrongdoing. Event-level, privacy-sensitive data - handle with care.

## What it answers

> "Show me everything this user did in this period, and highlight anything
> administrative or privileged."

It unions the three **action-bearing** sources into one chronological timeline and
flags each row `Privileged = Yes/No` with a reason. Sign-ins (authentication, not
actions) are deliberately excluded - see query 04 for that context.

## Parameters

| Parameter | Default | Meaning |
|---|---|---|
| `TargetUser` | `jane.doe@contoso.com` | **Set this** to the UPN under investigation. |
| `StartTime` | `ago(30d)` | Window start, or `datetime(2026-05-01)`. |
| `EndTime` | `now()` | Window end, or `datetime(2026-06-01)`. |

## Output columns

| Column | Meaning |
|---|---|
| `TimeGenerated` | When the action occurred (UTC). |
| `Source` | `Office365`, `EntraID`, or `Azure`. |
| `Actor` | The user's UPN (lower-cased), confirming attribution. |
| `Category` | O365 workload / Entra category / Azure resource provider. |
| `Operation` | The specific action. |
| `Privileged` | `Yes` if administrative / high-impact, else `No`. |
| `PrivilegeReason` | Why it was flagged (blank when `No`). |
| `Result` | Success / failure status as reported by the source. |
| `ClientIP` | Source IP where the source records it. |
| `Target` | Object acted on (file/site, directory target, Azure resource id). |
| `Details` | Raw parameters / target resources / properties for drill-down. |

## Step by step

1. **Parameters** - `TargetUser`, `StartTime`, `EndTime`, and the privileged
   signal lists (copied from `00-config`).

2. **Three per-source sub-queries**, each filtered to the window and to the user
   on that source's own actor field:
   - **Office 365** (`OfficeActivity`): actor = `UserId`. Privileged when the
     `RecordType` is an Admin type, the `Operation` is in `PrivOfficeOps`, or the
     `Operation` looks like an admin cmdlet (`Add-`/`Set-`/`New-`/...).
   - **Entra ID** (`AuditLogs`): actor = `InitiatedBy.user.userPrincipalName`.
     Privileged when `Category` is in `PrivAuditCategories` or `OperationName`
     matches `PrivAuditOps`, **and** the action is not self-service - self-service
     is detected as `InitiatedBy.user.id == TargetResources[0].id` (actor acting on
     their own object) and downgraded to `Privileged = No`.
   - **Azure** (`AzureActivity`): actor = `Caller`; restricted to
     `CategoryValue == "Administrative"`. Privileged when the resolved action
     (`Authorization_d.action`, else `OperationNameValue`) contains `/write`,
     `/delete`, or `/action`, **or** the friendly `OperationNameValue` is in
     `PrivAzureFriendlyOps` (e.g. "List Storage Account Keys"); high-impact when it
     touches RBAC, PIM-via-ARM, Key Vault, managed identity, key enumeration, or
     App Service publish profiles.

3. **Normalise** each sub-query to the same column shape, then `union` and
   `order by TimeGenerated desc`.

## How to read it

- Scan the `Privileged` column first. A run of `Yes` rows from `EntraID`
  (RoleManagement) or `Azure` (RBAC) is the kind of thing the client is asking
  about.
- A privileged action is **not** automatically a problem - many are expected of
  the role. Correlate the time and `ClientIP` with query 04 (sign-in context) to
  see whether it came from a normal device / location.
- Use the `Details` column, or query 03 for the privileged-only view.

## Notes

- Because you choose the user explicitly, there is **no** service-account or guest
  exclusion - this is a targeted lens, you decide who to inspect.
- The Azure sub-query intentionally keeps only `Administrative` category events;
  ServiceHealth / Recommendation / Alert noise is dropped.

## Related

`02` (summary first) - `03` (privileged only) - `04` (sign-in context).
