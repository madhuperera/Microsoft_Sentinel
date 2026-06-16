# 08 — Organisation workload trend over time

**Companion to:** `08-org-workload-trend.kql`
**Model:** B (graph-ready)
**Output:** `Day` (daily bin) × `Workload` × `AvgEventsPerActiveUser` — ready for `render timechart`

> Observable telemetry only. **Not** a productivity measure.

## What it answers

The **organisation-level** activity trend per workload, expressed as an average
**per active user** so it isn't distorted by headcount changes or a few heavy
users. It's the company backdrop you read an individual's trend (`03`) against.

## Parameters

| Parameter | Default | Meaning |
|---|---|---|
| `LookbackPeriod` | `60d` | Total window to chart. |
| `BinSize` | `1d` | Time-bucket size. |

## Step by step

1. **Parameters & exclusions** — `ServiceAccountUPNs` (`isfuzzy`), `ExcludedUPNs`,
   `MeaningfulOps`.

2. **Filter `OfficeActivity`** over `LookbackPeriod`: `UserType == "Regular"`, keep
   `MeaningfulOps`, lowercase to `UPN`, **drop guests** (`#ext#`) and
   service/system accounts.

3. **Bucket & aggregate.** `summarize Events = count(), ActiveUsers = dcount(UPN)
   by Day = bin(TimeGenerated, BinSize), Workload` — per day per workload, the total
   events and how many distinct users were active.

4. **Normalise.** `AvgEventsPerActiveUser = Events / ActiveUsers` — the key metric
   that makes the trend independent of how many people were active that day.

5. **Project & render.** Output `Day, Workload, AvgEventsPerActiveUser`
   (+ `ActiveUsers`, `Events` for context), `order by Day asc`, then
   `render timechart with (series = Workload, ycolumns = AvgEventsPerActiveUser)` —
   one line per workload.

## Reading the output

- Each line is the **average activity of an active user** in that workload, per day.
  A company-wide dip (e.g. a public holiday) shows here, helping you tell
  organisation-level effects apart from an individual change in `03`.
- No `UserDisplayName` column — aggregate, so the empty-display-name filter doesn't
  apply.

## Related

`03` (per-user trend to overlay) · `06` (snapshot org stats) · `02` (per-user,
per-workload baseline).
