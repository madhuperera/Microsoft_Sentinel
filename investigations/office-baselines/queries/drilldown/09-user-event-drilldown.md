# 09 — User event drill-down

**Companion to:** `09-user-event-drilldown.kql`
**Type:** Review (underlying events)
**Output:** raw meaningful `OfficeActivity` rows for one user, most recent first

> Observable telemetry only. **Not** a productivity measure. This is **event-level,
> privacy-sensitive** data — restrict access and review responsibly.

## What it answers

Shows the **actual events** behind a single user's summary numbers, so a reviewer
can understand *what* drove a baseline deviation **before** drawing any conclusion.
Use it after a user appears in `01`/`05`.

## Parameters

| Parameter | Default | Meaning |
|---|---|---|
| `TargetUser` | `jane.doe@contoso.com` | **Set this** to the UPN you're reviewing. |
| `LookbackPeriod` | `30d` | How far back to pull events. |
| `WorkloadFilter` | `""` | `""` = all workloads; or set e.g. `"SharePoint"`. |

## Step by step

1. **Parameters** — `TargetUser`, `LookbackPeriod`, optional `WorkloadFilter`, and
   the `MeaningfulOps` list.

2. **Filter `OfficeActivity`:**
   - `TimeGenerated >= ago(LookbackPeriod)`, `UserType == "Regular"`;
   - lowercase `UserId` → `UPN`, then **`where UPN == tolower(TargetUser)`** — pin to
     the one user;
   - keep only `MeaningfulOps`;
   - optional `where WorkloadFilter == "" or OfficeWorkload == WorkloadFilter`.

3. **Project the evidence columns.** `TimeGenerated, UPN, OfficeWorkload, Operation,
   RecordType, ResultStatus, ClientIP, UserAgent, OfficeObjectId, SourceFileName,
   Site_Url` — enough to see what happened, where, and from what client.

4. **Sort.** `order by TimeGenerated desc` (newest first).

## Notes

- Because you choose the user explicitly, there is **no guest `#ext#` filter and no
  empty-display-name filter** here — if you point it at a guest, you'll see the
  guest (intentional for review).
- No service-account/system exclusion either — this is a targeted lens, not an
  aggregate; you decide who to inspect.

## Related

`01`/`05` (where users get flagged) · `10` (operation-level breakdown across users).
