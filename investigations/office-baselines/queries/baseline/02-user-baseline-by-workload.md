# 02 — User vs own baseline, by workload

**Companion to:** `02-user-baseline-by-workload.kql`
**Model:** A (primary)
**Output:** one row per user **+ workload** — baseline vs current event rate, % change, status

> Observable telemetry only. **Not** a productivity measure. Review signals only.

## What it answers

The same per-user baseline comparison as `01`, but broken out **per M365 workload**
(Exchange / SharePoint / OneDrive / Teams …). It shows *where* a shift happened —
e.g. Teams up while SharePoint is down — which a single whole-user number hides.

## Parameters

| Parameter | Default | Meaning |
|---|---|---|
| `ReportPeriod` / `BaselinePeriod` | `30d` / `30d` | Current / baseline window lengths. |
| `NormalBandPct` | `20.0` | ± band (%) treated as normal. |
| `MinBaselineEvents` | `10` | Per-workload confidence floor (lower than `01`'s whole-user floor, because a single workload has fewer events). |

## Step by step

1. **Windows & days** — identical setup to `01`.

2. **Exclusions & `MeaningfulOps`** — identical (watchlist `isfuzzy`, system
   principals, engagement operations).

3. **`WorkloadMetrics(winStart, winEnd, days)`** — like `01`'s builder but the
   `summarize` groups **by `UPN` *and* `Workload`** (`tostring(OfficeWorkload)`),
   producing `Events`, `ActiveDays`, and `EventsPerDay` *per workload*. (Guests and
   service/system accounts are excluded the same way.)

4. **Run for both windows** → `Baseline`, `Current`.

5. **`UserList`** from `SigninLogs` members for display names.

6. **Join** `kind=fullouter` on **two keys** (`UPN, Workload`), so a workload that
   appears in only one window still shows. `coalesce` builds `B_`/`C_` columns and
   reconstructs `UPN`/`Workload` from the suffixed (`UPN1`/`Workload1`) sides.

7. **Change & status.** `ChangePct = (C_EventsPerDay − B_EventsPerDay) / B × 100`,
   then the same five-way `case()` banding as `01` (using `MinBaselineEvents = 10`).

8. **Display name & filter.** `leftouter` to `UserList`, then
   `where isnotempty(UserDisplayName)`.

9. **Project & sort** by `UPN`, then `Workload`.

## Reading the output

- One user spans several rows (one per workload they used).
- `B_` = Baseline, `C_` = Current. Use the per-workload `Status` to see which
  workload drove a change flagged at the whole-user level in `01`.
- Because this is workload-level, the metric is the **event rate** (not active-day
  ratio); interpret with the same "review only" caution.

## Related

`01` (whole-user headline) · `03` (per-workload trend over time) · `08` (org-level
per-workload backdrop) · `09`/`10` (event drill-down).
