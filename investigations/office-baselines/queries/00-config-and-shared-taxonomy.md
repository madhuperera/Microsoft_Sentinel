# 00 — Config & shared taxonomy

**Companion to:** `00-config-and-shared-taxonomy.kql`
**Type:** Reference / documentation (not a report)
**Model:** N/A (shared building blocks)

## What this file is for

This is the **canonical reference** for every tunable parameter and the activity
taxonomy used across the office-baselines queries. The individual queries are
deliberately **self-contained** (each repeats the parameters and the operation list
it needs) so they run with no dependencies. This file is where you read the full
picture, and the place to change the model first before propagating edits.

When you run it, it simply returns the taxonomy as a table (so you can eyeball the
meaningful/noise split). Nothing is queried from `OfficeActivity`/`SigninLogs`.

## Step by step

1. **Reporting window parameters** (`ReportPeriod`, `BaselinePeriod`, `EndTime`).
   `EndTime = now()` is the anchor; `CurrentStart = EndTime - ReportPeriod` and
   `BaselineStart = CurrentStart - BaselinePeriod` define the two adjacent windows
   used everywhere:
   - **Current window** = `[CurrentStart, EndTime)`
   - **Baseline window** = `[BaselineStart, CurrentStart)`
   Set `EndTime` to a fixed datetime to "freeze" a report for a fixed period.

2. **Model A thresholds.** `NormalBandPct = 20.0` (the ± band treated as normal) and
   `MinBaselineEvents = 20` (the confidence floor that suppresses tiny baselines).

3. **Model B thresholds.** `OutlierZ = 3.5` (modified-z cutoff for "outlier") and
   `MinUserActivity = 5` (drop near-zero users from org statistics).

4. **Noise controls.**
   - `ServiceAccountUPNs` is built from the `service-accounts` watchlist using
     `union isfuzzy=true` with an empty `datatable` fallback, so a **missing
     watchlist degrades to no exclusions** instead of failing the query.
   - `ExcludedUPNs` is a static list of system principals (`SHAREPOINT\system`, …).

5. **`MeaningfulOps`.** The compact `dynamic([...])` array of operations counted as
   engagement — i.e. every operation flagged `EngagementSignal = Yes` in the
   taxonomy. This is the list embedded in the metric queries.

6. **`Taxonomy` datatable.** The full operation → category → `EngagementSignal`
   map (both Yes and No rows), mirroring `docs/activity-taxonomy.md` and the
   `reference-data/office-activity-taxonomy` watchlist.

7. **Final line.** `Taxonomy | order by ...` just displays the map.

## How to use it

- Copy the `let` parameter block into a query, or read it as documentation.
- When tuning, change values here **and** in the individual queries (they each
  carry their own copy by design). The breakdown query `10` helps you decide what
  belongs in the taxonomy.

## Keep in sync

`docs/activity-taxonomy.md` (narrative source of truth) ·
`reference-data/office-activity-taxonomy/office-activity-taxonomy.csv` ·
the inline `MeaningfulOps` / `Taxonomy` blocks in each query.
