# Workbooks (Phase 2 — draft)

Sentinel workbooks built from the office-baselines queries. **Drafts pending live
validation** — import to a non-production view, check rendering and numbers, then
iterate. Naming follows the repo convention (`DEV_` = development/unvalidated).

> ⚠️ Activity here is observable telemetry only — **not** a measure of productivity,
> work quality, effort, or hours worked. See
> `../docs/assumptions-and-limitations.md`.

## Workbooks

| File | Built from | What it shows |
|---|---|---|
| `DEV_OfficeBaselines-UserVsOrg.json` | queries `06` + `07` (Model B) | Org robust baseline per workload, then each user vs the org (percentile band + modified z-score), with outliers flagged for review. |

## Parameters (DEV_OfficeBaselines-UserVsOrg)

| Parameter | Maps to KQL `let` | Default |
|---|---|---|
| `W_ReportPeriod` | `ReportPeriod` | `30d` |
| `W_MinUserActivity` | `MinUserActivity` | `5` |
| `W_OutlierZ` | `OutlierZ` | `3.5` |

The KQL inside the workbook is the same logic as the `.kql` files, with the `let`
values replaced by `{W_*}` parameter tokens. Service accounts, system principals,
and B2B guests are excluded exactly as in the source queries.

## How to import

1. Sentinel → **Workbooks** → **Add workbook**.
2. Open the new workbook → **Edit** → **</> Advanced Editor**.
3. Replace the contents with this file's JSON → **Apply** → **Done editing**.
4. **Save** with a clear name (e.g. *Office Baselines – User vs Organisation (DEV)*).

> `fallbackResourceIds` points at the existing workspace used by the other
> dashboards in this repo. On import, confirm the workbook is bound to the correct
> Log Analytics / Sentinel workspace.

## Validate before promoting (DEV → PROD)

- Both grids render and return rows for a known-active period.
- `OrgFlag` colours correctly (amber = outlier-review, green = typical).
- Spot-check a couple of users against query `07` run directly in Logs — numbers match.
- Confirm the framing/caveats are acceptable to the client before wider sharing.

## Notes / next iterations

- Currently two grids (org stats + user-vs-org). Candidate additions: a per-band
  bar chart, a `TargetUser` drill-through to the `03`/`09` detail, and a global time
  parameter.
- This is the **secondary** model (Model B). A Model A workbook (user vs own
  baseline, from `01`/`05`) is the natural next build.
