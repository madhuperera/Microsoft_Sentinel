# 11 — User vs organisation activity trend

**Companion to:** `11-user-vs-org-activity-trend.kql`
**Model:** A vs B (graph-ready)
**Output:** `Day` (daily bin) × `Series` (`User` / `Org avg / active user`) × `Value` — ready for `render timechart`

> Observable telemetry only. **Not** a productivity measure.

## What it answers

Draws **one user's daily trend and the organisation backdrop on the same chart**, so
you can see *when* a person sits above or below the typical active user over time —
the combined picture that `03` (user) and `08` (org) only show on separate charts.

The two lines are comparable because both are on a **per-person-per-day** scale:

- **`User`** — the target user's meaningful events that day.
- **`Org avg / active user`** — the org's meaningful events that day ÷ the number of
  active users that day (so it's not distorted by headcount or a few heavy users).

## Parameters

| Parameter | Default | Meaning |
|---|---|---|
| `LookbackPeriod` | `60d` | Total window to chart (covers a 30d current + 30d baseline). |
| `BinSize` | `1d` | Time-bucket size for the trend. |
| `TargetUser` | `"jane.doe@contoso.com"` | **Required.** The UPN to compare against the org. |
| `WorkloadFilter` | `""` | `""` = all workloads combined; else one workload, e.g. `"SharePoint"`. |

## Step by step

1. **Parameters** including `TargetUser` (required) and the optional `WorkloadFilter`.

2. **Exclusions & `MeaningfulOps`** — `ServiceAccountUPNs` (watchlist, `isfuzzy`),
   `ExcludedUPNs`, and the engagement operation list.

3. **Shared base (`materialize`d).** Filter `OfficeActivity` over `LookbackPeriod`:
   `UserType == "Regular"`, keep `MeaningfulOps`, lowercase to `UPN`, **drop guests**
   (`#ext#`) and service/system accounts, apply the optional `WorkloadFilter`, then
   `summarize Events = count() by Day, UPN`. It's wrapped in `materialize()` because
   the base feeds both series — the scan runs once and is reused.

4. **User line.** From the base, keep the target user, `todouble(sum(Events)) by Day`,
   label `Series = "User"`. The `todouble` matters: `union` splits a same-named column
   when the two sides differ in type, so the user count is cast to `real` to match the
   org average and merge into one `Value` column.

5. **Org line.** From the same base, `sum(Events) / dcount(UPN) by Day` → the average
   active user's events that day, label `Series = "Org avg / active user"`.

6. **Combine & render.** `union` the two series, `order by Day asc`, then
   `render timechart with (series = Series, ycolumns = Value)` — two lines on one
   chart sharing the x-axis.

## Reading the output

- The **gap between the lines** is the story: the user tracking near the org line is
  "typical"; sustained separation above or below is the review signal. A *parallel*
  dip in both lines (e.g. a public holiday) is an organisation effect, not a personal
  one.
- Set `WorkloadFilter` to compare a single workload (e.g. only Teams) when one channel
  is the question; leave it blank for total meaningful activity.
- The org line uses the **mean per active user** (matching `08`). If you prefer the
  robust centre, the **median** per-user rate is in `06`; swap `dcount`/`sum` for a
  `percentile(..., 50)` over per-user daily rates to plot that instead.
- No `UserDisplayName` column — this is a time aggregate, so the empty-display-name
  filter doesn't apply; guests and service/system accounts are still removed at source.

## Related

`03` (per-user trend, split by workload) · `08` (org trend, split by workload) ·
`07` (point-in-time user-vs-org percentile + z-score) · `01`/`02` (the summaries a
deviation in this chart explains).
