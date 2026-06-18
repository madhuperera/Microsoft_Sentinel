# 03 — User activity trend over time

**Companion to:** `03-user-activity-trend.kql`
**Model:** A (graph-ready)
**Output:** `TimeGenerated` (daily bin) × `Workload` × `Events` — ready for `render timechart`

> Observable telemetry only. **Not** a productivity measure.

## What it answers

Shows the **shape** of activity over time for one user (or everyone), split by
workload — so you can see whether a change flagged in `01`/`05` was gradual or
sudden, and whether it's one workload or across the board.

## Parameters

| Parameter | Default | Meaning |
|---|---|---|
| `LookbackPeriod` | `60d` | Total window to chart (covers a 30d current + 30d baseline). |
| `BinSize` | `1d` | Time-bucket size for the trend. |
| `TargetUser` | `""` | A single UPN to chart; `""` = aggregate across all users. |

## Step by step

1. **Parameters** including `TargetUser` (the per-user toggle).

2. **Exclusions & `MeaningfulOps`** — `ServiceAccountUPNs` (watchlist, `isfuzzy`),
   `ExcludedUPNs`, and the engagement operation list.

3. **Filter `OfficeActivity`:**
   - `TimeGenerated >= ago(LookbackPeriod)`;
   - `UserType == "Regular"`, keep only `MeaningfulOps`;
   - lowercase `UserId` → `UPN`; **drop guests** (`#ext#`) and service/system
     accounts;
   - **user toggle:** `where TargetUser == "" or UPN == tolower(TargetUser)` — with
     the default empty string this passes everyone; set a UPN to focus on one user.

4. **Bucket & count.** `summarize Events = count() by bin(TimeGenerated, BinSize),
   Workload` produces a daily count per workload.

5. **Sort & render.** `order by TimeGenerated asc` then `render timechart` — the
   datetime column becomes the x-axis, `Workload` splits the series, `Events` is
   plotted.

## Reading the output

- As a chart: one line per workload over time. With `TargetUser` set you see that
  person; left blank you see the organisation total.
- This query has **no `UserDisplayName` column** (it's a time/workload aggregate),
  so the "empty display name" exclusion does not apply here — guests and
  service/system accounts are still removed at source.

## Related

`01`/`02` (the summary the trend explains) · `08` (org-level trend to compare a user
against) · `11` (this user's trend and the org average overlaid on one chart) ·
`09` (raw events for a user).
