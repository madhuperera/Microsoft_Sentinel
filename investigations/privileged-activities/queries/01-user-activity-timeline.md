# 01 - User activity timeline

**Companion to:** `01-user-activity-timeline.kql`
**Type:** Primary report
**Output:** one row per action across Office 365, Entra ID, and Azure - newest first

> Observable telemetry only. A classified action is a **prompt to review**, not
> proof of wrongdoing. Event-level, privacy-sensitive data - handle with care.

## What it answers

> "Show me everything this user did in this period, and classify it so admin and
> high-risk actions stand out."

It unions the three **action-bearing** sources into one chronological timeline and
gives every row an `ActivityClass` and a `Severity`. **Normal activity is kept** -
classification enriches the timeline, it does not filter it. Sign-ins
(authentication, not actions) are excluded - see query 04.

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
| `Actor` | The user's UPN (lower-cased). |
| `ActivityClass` | The classification (see `../docs/privileged-operations-taxonomy.md`). |
| `Severity` | `High` / `Medium` / `Low` / `Info`, after the failed-attempt downgrade. |
| `Outcome` | `Success` / `Failure` / `Other`, derived from the source result. |
| `Category` | O365 workload / Entra category / Azure resource provider. |
| `Operation` | The specific action. |
| `Result` | Raw status from the source. |
| `ClientIP` | Source IP where recorded. |
| `Target` | Object acted on (file/site, directory target, Azure resource id). |
| `Details` | Raw parameters / target resources / properties for drill-down. |
| `SeverityRank` | 3/2/1/0 for High/Medium/Low/Info (for workbook sorting). |

## Step by step

1. **Parameters** and the per-source signal lists (copied from `00-config`).
2. **Three per-source sub-queries**, each filtered to the window and the user on
   that source's own actor field, each producing an `ActivityClass`:
   - **Office 365** (`OfficeActivity`, actor `UserId`): curated role / security-
     config / data-exposure lists; otherwise admin `RecordType` or admin-cmdlet
     shape -> "Possible admin activity (review)"; else "Normal user activity".
   - **Entra ID** (`AuditLogs`, actor `InitiatedBy.user.userPrincipalName`):
     **operation-name primary** mapping to role / app / policy / identity classes;
     self-service (`InitiatedBy.user.id == TargetResources[0].id`) drops to normal;
     group ops -> "Requires manual review"; `Category` is a low-confidence
     secondary net only.
   - **Azure** (`AzureActivity`, actor `Caller`, `Administrative` only): expanded
     high-impact list -> "High-impact Azure control-plane change"; other changes ->
     "Azure control-plane change".
3. **`union`**, then derive `BaseSeverity` from the class, `Outcome` from `Result`,
   and `Severity` (downgrade one level on failure).
4. **Sort** `order by TimeGenerated desc` (newest first).

## How to read it

- Filter or sort on `Severity` / `ActivityClass`. `High` rows in
  `Privileged role/RBAC change`, `App/consent/service principal change`, or
  `High-impact Azure control-plane change` are the headline items.
- A classified action is not automatically a problem - correlate the time and
  `ClientIP` with query 04 (sign-in context).
- `Outcome == "Failure"` rows are kept but ranked lower - useful for spotting
  attempted-but-blocked privileged actions.

## Notes

- Because you choose the user explicitly, there is **no** service-account or guest
  exclusion - this is a targeted lens.
- Scope is control-plane / audit only; see the limitation header in the query and
  `../docs/assumptions-and-limitations.md`.

## Related

`02` (summary first) - `03` (flagged only) - `04` (sign-in context).
