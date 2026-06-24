# 03 - User privileged activity only

**Companion to:** `03-user-privileged-activity.kql`
**Type:** Privileged highlight
**Output:** one row per privileged action across all three sources - newest first

> Observable telemetry only. A privileged action is a **prompt to review**, not
> proof of misconduct. Many privileged actions are legitimate and expected of the
> role.

## What it answers

> "Did this user perform any privileged activity, and what exactly was it?"

Same engine as query 01, but each sub-query **filters to** the privileged
condition instead of flagging it, so the result is only the highlights.

## Parameters

Same as query 01: `TargetUser`, `StartTime`, `EndTime`.

## Output columns

Same shape as query 01 minus the `Privileged` flag (every row is privileged), with
`PrivilegeReason` retained: `TimeGenerated, Source, Actor, Category, Operation,
PrivilegeReason, Result, ClientIP, Target, Details`.

## Step by step

1. **Parameters** and the privileged signal lists (as in query 01).
2. Each per-source sub-query applies the privileged test in a `where` clause:
   - **Office 365**: `RecordType has "Admin"`, or `Operation` in `PrivOfficeOps`,
     or the case-insensitive admin-cmdlet regex.
   - **Entra ID**: (`Category` in `PrivAuditCategories` or `OperationName` in
     `PrivAuditOps`) **and not self-service** (`InitiatedBy.user.id !=
     TargetResources[0].id`).
   - **Azure**: `Administrative` category **and** (action in `PrivAzureActions`
     **or** friendly `OperationNameValue` in `PrivAzureFriendlyOps`);
     `PrivilegeReason` marks the RBAC / PIM / Key Vault / key-enumeration / identity
     subset as high-impact.
3. `union` and `order by TimeGenerated desc`.

## How to read it

- An **empty result** means no privileged action by this user in the window (per
  the current signals) - a useful negative answer in itself.
- For each row, check the `Result` (did it succeed?), the `Target` (what was
  changed?), and correlate `TimeGenerated` / `ClientIP` with query 04.
- Group mentally by `PrivilegeReason`: RBAC / Key Vault changes and directory role
  changes are the highest-impact categories.

## Notes

- This query and query 01 must stay in step: the `where` conditions here are the
  same as the `IsPriv` expressions in 01. If you tune one, tune both (and
  `00-config`).

## Related

`02` (summary first) - `01` (full timeline incl. non-privileged) - `04` (sign-in
context).
