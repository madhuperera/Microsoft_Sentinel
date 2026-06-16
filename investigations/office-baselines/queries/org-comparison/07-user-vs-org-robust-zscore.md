# 07 — User vs organisation / peer group

**Companion to:** `07-user-vs-org-robust-zscore.kql`
**Model:** B (secondary — supporting context for Model A)
**Output:** one row per user + workload — user rate, group median, percentile band, modified z-score, outlier flag

> Observable telemetry only. **Not** a productivity measure. An "outlier" is *worth
> a look*, never a verdict.

## What it answers

"Is this user broadly in line with the company on this workload?" It places each
user's per-workload daily rate against the robust org distribution from `06`,
without producing a misleading leaderboard. The **headline is the percentile band**
(easy to explain); the **statistical flag is the modified z-score**.

## Parameters

| Parameter | Default | Meaning |
|---|---|---|
| `ReportPeriod` | `30d` | Window analysed. |
| `MinUserActivity` | `5` | Drop near-zero users from the comparison. |
| `OutlierZ` | `3.5` | `|modified z-score|` above this → flagged as outlier. |

## Step by step

1. **Parameters & exclusions** — as in `06`.

2. **`PerUser`.** Identical construction to `06`: per-user, per-workload
   `EventsPerDay` for the current window, guests/service/system excluded, near-zero
   users dropped, `GroupKey = "All"`.

3. **`Stats`.** Per `GroupKey, Workload`: `Median`, `P25`, `P75`, `P90`
   (percentiles of `EventsPerDay`).

4. **`MAD`.** Join `PerUser` to `Stats`, compute `AbsDev`, then `MAD =
   percentile(AbsDev, 50)` per group/workload.

5. **`UserList`.** Member sign-ins → latest `UserDisplayName` per UPN.

6. **Combine.** `PerUser` **inner join** `Stats`, then **inner join** `MAD`
   (on `GroupKey, Workload`). Now every row has the user's rate plus the group's
   median, percentiles, and MAD.

7. **Modified z-score.** `ModifiedZ = 0.6745 × (EventsPerDay − Median) / MAD`,
   guarded by `iff(MAD == 0, 0.0, ...)` to avoid divide-by-zero. (0.6745 scales MAD
   so the score is comparable to a standard z-score.)

8. **Percentile band.** A `case()` placing the user's rate in
   `Below P25 / P25–P50 / P50–P75 / P75–P90 / Above P90`.

9. **Outlier flag.** `OrgFlag = iff(abs(ModifiedZ) > OutlierZ, "Outlier - review
   only", "Typical")`.

10. **Display name & filter.** `leftouter` to `UserList`, then
    `where isnotempty(UserDisplayName)`.

11. **Project & sort** by `Workload`, then `ModifiedZ desc` (most extreme first).

## Reading the output

- Read `PercentileBand` first (intuitive), then `ModifiedZ`/`OrgFlag` for the
  statistical view. `UserEventsPerDay` vs `GroupMedian` shows the raw gap.
- **This is secondary context.** The primary question remains user-vs-own-baseline
  (`01`/`05`). Different roles legitimately produce different bands — which is why a
  peer-group `GroupKey` (Phase 2) makes this fairer.

## Related

`06` (the reference stats this depends on) · `01`/`05` (the primary model) ·
`methodology.md` §4.
