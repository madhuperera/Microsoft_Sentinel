# 01 — User vs own baseline (summary)

**Companion to:** `01-user-vs-own-baseline-summary.kql`
**Model:** A (primary — each user against their *own* prior period)
**Output:** one row per user — baseline vs current rates, % change, review status

> Observable telemetry only. **Not** a productivity measure. The `Status` is a
> review signal, never proof of underperformance.

## What it answers

"Is this user's observable M365 activity in the current period broadly in line with
their own recent baseline?" The headline metric is the **active-day ratio**
(fraction of days with at least one meaningful action), which resists the
event-count inflation caused by sync clients and multi-event actions.

## Parameters

| Parameter | Default | Meaning |
|---|---|---|
| `ReportPeriod` | `30d` | Length of the current window. |
| `BaselinePeriod` | `30d` | Length of the prior baseline window. |
| `NormalBandPct` | `20.0` | ± band (%) treated as normal variation. |
| `MinBaselineEvents` | `20` | Baseline confidence floor; below it → low-confidence status. |

## Step by step

1. **Define windows & days.** `CurrentStart`/`BaselineStart` mark the two adjacent
   windows; `ReportDays`/`BaselineDays` (`ReportPeriod / 1d`) convert the timespans
   to a number of days for per-day normalisation.

2. **Build the exclusion set & operation list.** `ServiceAccountUPNs` (from the
   watchlist, `isfuzzy` so a missing watchlist won't fail), `ExcludedUPNs` (system
   principals), and `MeaningfulOps` (engagement operations).

3. **`OfficeMetrics(winStart, winEnd, days)` — the reusable metric builder.** For a
   window it:
   - filters `OfficeActivity` to the window and `UserType == "Regular"`;
   - keeps only `MeaningfulOps`;
   - lowercases `UserId` → `UPN`;
   - **drops guests** (`UPN !contains "#ext#"`) — note `"Regular"` does *not*
     exclude guests — and drops service/system accounts;
   - `summarize` per `UPN`: `Events` (count), `ActiveDays` (distinct day-bins),
     `Workloads` (distinct workloads);
   - derives **`EventsPerDay`** = Events ÷ days and **`ActiveDayRatio`** =
     ActiveDays ÷ days.

4. **Run it for both windows.** `Baseline = OfficeMetrics(baseline window)` and
   `Current = OfficeMetrics(current window)`.

5. **Build `UserList`** from `SigninLogs` (members only, `UserType =~ "Member"`),
   taking the latest `UserDisplayName` per UPN — used to attach a friendly name.

6. **Join baseline ⋈ current** with `kind=fullouter` on `UPN`, so users present in
   only one window still appear. Right-hand columns get a `1` suffix
   (`ActiveDayRatio1`, `Events1`, …); `coalesce(..., 0)` turns missing sides into
   zero and produces the `B_` (baseline) and `C_` (current) columns.

7. **Compute change.** `ActiveDayChangePct = (C − B) / B × 100` (only when the
   baseline is > 0, else null). `EventRateChangePct` is the same for the event rate
   (secondary context).

8. **Classify `Status`** with a `case()` in priority order:
   - baseline events < `MinBaselineEvents` → *Insufficient baseline (low confidence)*
   - no baseline at all (null change) → *No baseline activity*
   - `|change| ≤ NormalBandPct` → *Within normal range*
   - change > band → *Increase - review only*
   - else → *Decrease - review only*

9. **Attach display name & filter.** `leftouter` join to `UserList`, then
   `where isnotempty(UserDisplayName)` drops accounts that can't be resolved to a
   member sign-in (service-like/stale/non-member).

10. **Project & sort.** Output the `B_`/`C_` metric pairs, change %, and status;
    `order by ActiveDayChangePct asc nulls last` puts the largest decreases first.

## Reading the output

- `B_` = **Baseline** period value; `C_` = **Current** period value.
- Focus on `Status` first; treat `ActiveDayRatio` as the headline and
  `EventsPerDay` as secondary context. Large `%` swings on tiny baselines are
  suppressed by `MinBaselineEvents`.

## Related

`05` (filtered review shortlist of this same logic) · `02` (same, per workload) ·
`03` (trend) · `09`/`10` (drill into the underlying events).
