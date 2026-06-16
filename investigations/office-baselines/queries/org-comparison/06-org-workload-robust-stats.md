# 06 — Organisation / peer-group robust stats by workload

**Companion to:** `06-org-workload-robust-stats.kql`
**Model:** B (secondary — the reference distribution)
**Output:** one row per workload — user count, median, P25/P75/P90, and MAD of the per-user daily event rate

> Observable telemetry only. **Not** a productivity measure.

## What it answers

Establishes what "normal" looks like **across the organisation (or a peer group)**
for each workload. These statistics are the reference distribution that `07`
compares individual users against. It is intentionally **robust** — built from
median / percentiles / MAD, not mean / standard deviation — because per-user M365
activity is heavily right-skewed and would otherwise be distorted by power users,
automation, and service-like accounts.

## Parameters

| Parameter | Default | Meaning |
|---|---|---|
| `ReportPeriod` | `30d` | Window analysed (current period only — no baseline here). |
| `MinUserActivity` | `5` | Users with fewer events than this are dropped, so near-zero users don't skew the stats. |

## Key concepts

- **Median (P50):** middle value; ignores outliers.
- **Percentiles (P25/P75/P90):** explainable "where does a user sit" bands.
- **MAD (median absolute deviation):** robust spread = `median(|x − median|)`.

## Step by step

1. **Parameters & exclusions** — current window only; `ServiceAccountUPNs`
   (`isfuzzy`), `ExcludedUPNs`, `MeaningfulOps`.

2. **`PerUser` (the base set).** From `OfficeActivity` in the current window:
   `UserType == "Regular"`, keep `MeaningfulOps`, drop guests (`#ext#`) and
   service/system accounts, then `summarize Events = count() by UPN, Workload`.
   - `where Events >= MinUserActivity` removes near-zero users.
   - `GroupKey = "All"` is the **peer-cohort key** (whole org by default — repoint
     it at a department/role column from a watchlist in Phase 2).
   - `EventsPerDay = Events / ReportDays` normalises to a daily rate.

3. **`Medians`.** `summarize Median = percentile(EventsPerDay, 50) by GroupKey,
   Workload` — the per-workload median (needed before MAD).

4. **`MAD`.** Join `PerUser` to `Medians`, compute `AbsDev = abs(EventsPerDay −
   Median)`, then `MAD = percentile(AbsDev, 50)` per workload. (Two-step because MAD
   is "the median of the absolute deviations from the median".)

5. **Final aggregate.** From `PerUser`, `summarize` `Users` (count), `Median`,
   `P25`, `P75`, `P90` per `GroupKey, Workload`; **inner join** to `MAD`.

6. **Project & sort** by `Workload`.

## Reading the output

- One row per workload (per peer group, if you repoint `GroupKey`).
- `Median` is the typical per-day rate; `P25`–`P90` describe the spread; `MAD`
  feeds the modified z-score in `07`. `Users` tells you how many people the stats
  rest on (small N → treat with caution).
- No `UserDisplayName` column — this is an aggregate, so the empty-display-name
  filter doesn't apply.

## Related

`07` (places each user against these stats) · `08` (org trend over time) ·
`methodology.md` §4 (why robust statistics).
