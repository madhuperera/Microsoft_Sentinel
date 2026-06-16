# Watchlist — `office-activity-taxonomy`

Optional reference data for the **office-baselines** reporting project
(`investigations/office-baselines/`). It maps `OfficeActivity` operations to a
category and an `EngagementSignal` (Yes/No) flag, so activity metrics count only
meaningful, human-driven operations and exclude background/system/admin noise.

> ⚠ This supports activity-pattern reporting that is **observable telemetry only**
> — not a measure of productivity, work quality, effort, or hours worked. See
> `investigations/office-baselines/docs/assumptions-and-limitations.md`.

## Status: optional

The office-baselines queries ship **self-contained** — each embeds the meaningful
operations inline, so they run without this watchlist. Deploy this watchlist only
when you want to maintain the taxonomy **centrally** (one place) instead of editing
each query. The narrative source of truth is
`investigations/office-baselines/docs/activity-taxonomy.md`; this CSV is its
machine-readable twin.

## File

| File | Purpose |
|---|---|
| `office-activity-taxonomy.csv` | Watchlist source rows. |

### Columns

| Column | Type | Description |
|---|---|---|
| `Workload` | string | M365 workload (Exchange, SharePoint, MicrosoftTeams, …). |
| `Operation` | string | `OfficeActivity.Operation` value. |
| `Category` | string | Taxonomy category (see activity-taxonomy.md). |
| `EngagementSignal` | string | `Yes` = counted as engagement; `No` = excluded as noise. |
| `Notes` | string | Rationale / caveat. |

**Suggested SearchKey:** `Operation`.

## Using it in KQL (alternative to the inline list)

Replace the inline `let MeaningfulOps = dynamic([...]);` in a query with:

```kql
let MeaningfulOps = toscalar(
    _GetWatchlist("office-activity-taxonomy")
    | where EngagementSignal == "Yes"
    | summarize make_set(Operation));
```

## Maintenance

When tuning the taxonomy (after reviewing
`investigations/office-baselines/queries/drilldown/10-workload-operation-breakdown.kql`),
update **all** of these together so they stay in sync:

1. `investigations/office-baselines/docs/activity-taxonomy.md` (source of truth)
2. this CSV
3. the inline `MeaningfulOps` / `Taxonomy` blocks in the office-baselines queries
