# Office Activity Baselines

Observable Microsoft 365 activity-pattern reporting, built around **per-user
baseline comparison** with a **secondary organisation comparison**.

> ⚠️ **Read this first.** The activity counts here are *observable telemetry only*.
> They are **not** a measure of productivity, work quality, effort, or hours worked.
> A higher event count does not mean more work was done. Deviations are **signals
> to review**, never evidence of underperformance or misconduct. See
> [`docs/assumptions-and-limitations.md`](docs/assumptions-and-limitations.md).

## What this is

Phase 1 of a reporting project: a validated set of **KQL queries**, a documented
**activity taxonomy**, and a **comparison methodology**. The workbook/dashboard is a
*later* phase and is intentionally not built yet.

Two comparison models:

- **Model A (primary) — user vs own baseline.** Each user's activity in a selected
  reporting period is compared with that same user's previous period of equal length
  (e.g. last 30 days vs the 30 days before). Changes outside a configurable ±20% band
  are flagged for review.
- **Model B (secondary) — user vs organisation / peer group.** Robust statistics
  (median, MAD, percentiles, modified z-score) show whether a user's per-workload
  activity is broadly in line with the wider organisation, without being skewed by
  outliers, service accounts, or differing roles.

Full context is in [`PROJECT-BRIEF.md`](PROJECT-BRIEF.md).

## Data sources

`SigninLogs`, `AADNonInteractiveUserSignInLogs` (if ingested), and `OfficeActivity`.
No Advanced Hunting. No other tables.

## How to use

All queries are plain Sentinel / Log Analytics KQL — paste into **Sentinel → Logs**.
Tunable values are `let` parameters at the top of each file.

> Every `NN-*.kql` has a companion **`NN-*.md`** next to it with a step-by-step
> explanation of how that query's logic works, its parameters, and how to read the
> output. Open the `.md` alongside the `.kql`.

1. Open [`queries/00-config-and-shared-taxonomy.kql`](queries/00-config-and-shared-taxonomy.kql)
   to see every parameter and the canonical activity taxonomy in one place.
2. Run the **baseline** queries (Model A):

   | File | Purpose |
   |---|---|
   | `baseline/01-user-vs-own-baseline-summary.kql` | Per-user current vs own baseline (headline metrics). |
   | `baseline/02-user-baseline-by-workload.kql` | Same comparison split by M365 workload. |
   | `baseline/03-user-activity-trend.kql` | Daily activity trend (one user or all) — graph-ready. |
   | `baseline/04-signin-active-days-baseline.kql` | Sign-in "active days" comparison from `SigninLogs`. |
   | `baseline/05-flagged-for-review.kql` | Only users outside the normal band (review list). |

3. Run the **org-comparison** queries (Model B):

   | File | Purpose |
   |---|---|
   | `org-comparison/06-org-workload-robust-stats.kql` | Org/peer robust stats per workload (median, MAD, percentiles). |
   | `org-comparison/07-user-vs-org-robust-zscore.kql` | Each user vs org: percentile band + modified z-score. |
   | `org-comparison/08-org-workload-trend.kql` | Org-level workload trend over time — graph-ready. |
   | `org-comparison/11-user-vs-org-activity-trend.kql` | One user's trend overlaid on the org average, one chart — graph-ready. |

4. Use the **drill-down** queries to review underlying events:

   | File | Purpose |
   |---|---|
   | `drilldown/09-user-event-drilldown.kql` | Raw meaningful events for one user. |
   | `drilldown/10-workload-operation-breakdown.kql` | Operation-level breakdown + taxonomy mapping (validates the taxonomy). |

## Documentation

- [`docs/methodology.md`](docs/methodology.md) — the comparison maths, normalisation,
  thresholds, and why robust statistics are used for the org model.
- [`docs/activity-taxonomy.md`](docs/activity-taxonomy.md) — which `OfficeActivity`
  operations are meaningful vs noise, grouped by category, with rationale.
- [`docs/assumptions-and-limitations.md`](docs/assumptions-and-limitations.md) —
  ethical guardrails, assumptions, and the pre-workbook validation checklist.

## Dependencies

- `service-accounts` watchlist (`reference-data/service-accounts/`) — used to exclude
  service accounts, expected to have a `UPN` column. Referenced via
  `union isfuzzy=true`, so the queries still run if it's missing (they just skip
  the service-account exclusion).
- *(Optional, future)* `office-activity-taxonomy` watchlist
  (`reference-data/office-activity-taxonomy/`) — lets you maintain the taxonomy
  centrally instead of inline. Queries ship self-contained (inline) so they run
  without it.

## Status

Phase 1. Queries and docs are drafts pending validation against real tenant data —
see the checklist in `docs/assumptions-and-limitations.md` before promoting anything
or starting the workbook.
