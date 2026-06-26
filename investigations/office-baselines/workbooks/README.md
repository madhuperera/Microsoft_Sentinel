# Workbooks (Phase 2, draft)

Sentinel workbooks built from the office-baselines queries. **Drafts pending live
validation:** import to a non-production view, check rendering and numbers, then
iterate. Naming follows the repo convention (`DEV_` = development/unvalidated).

**Versioning:** every change to a workbook is written to a NEW file with the next
`_vN` suffix (`..._v1.json`, `..._v2.json`, ...). Older versions are kept, never
overwritten, so a working import can always be rolled back to. The highest `_vN` is
the current one.

> ⚠️ Activity here is observable telemetry only, **not** a measure of productivity,
> work quality, effort, or hours worked. See
> `../docs/assumptions-and-limitations.md`.

## Workbooks

| File | Built from | What it shows |
|---|---|---|
| `DEV_OfficeBaselines-AllQueries_v9.json` | **all** queries `01`-`11` | **Current.** Classifies four previously-`UNMAPPED` operations in panel `10` (`FileVersionsAllDeleted`, `SharingInvitationCreated`, `SharingPolicyChanged`, `SPOTenantCmdlets`). All `EngagementSignal = No`, so the engagement metrics are unchanged. |
| `DEV_OfficeBaselines-AllQueries_v8.json` | **all** queries `01`-`11` | Superseded by v9. Customer feedback: (1) panel titles are now always visible (split out of the description so the Show/Hide toggle hides only the body); (2) panel `07` shows every workload per active person, including zeros. |
| `DEV_OfficeBaselines-AllQueries_v7.json` | **all** queries `01`-`11` | Superseded by v8. Adds status icons to the grids (trend up/down/neutral on the review columns), driven by the `Status` text so the +/- normal band is respected. |
| `DEV_OfficeBaselines-AllQueries_v6.json` | **all** queries `01`-`11` | Superseded by v7. Full business-friendly panel descriptions synced from `panel-descriptions/NN.md`. Kept for rollback. |
| `DEV_OfficeBaselines-AllQueries_v5.json` | **all** queries `01`-`11` | Superseded. Relative 7-day date default and the "About the controls" help block. Kept for rollback. |
| `DEV_OfficeBaselines-AllQueries_v4.json` | **all** queries `01`-`11` | Superseded. Working Show/Hide toggles on every panel (`type: 10` pill parameter). Kept for rollback. |
| `DEV_OfficeBaselines-AllQueries_v3.json` | **all** queries `01`-`11` | Superseded. Business-friendly notes and styled section banners, but the links/tabs toggles did not survive a portal save. Kept for rollback. |
| `DEV_OfficeBaselines-AllQueries_v2.json` | **all** queries `01`-`11` | Superseded. Custom date range + tab toggles, terse/technical descriptions. Kept for rollback. |
| `DEV_OfficeBaselines-AllQueries_v1.json` | **all** queries `01`-`11` | Superseded (preset durations, dropdown toggles, per-card time range bug). Kept for rollback. |
| `DEV_OfficeBaselines-UserVsOrg.json` | queries `06` + `07` (Model B) | Org robust baseline per workload, then each user vs the org (percentile band + modified z-score), with outliers flagged for review. |

## DEV_OfficeBaselines-AllQueries (the combined workbook)

Every query and graph in the project, in the same three groups as `queries/`:

- **Baseline, Model A** (`01` summary, `02` by workload, `03` trend, `04` sign-in days, `05` flagged).
- **Organisation comparison, Model B** (`06` org stats, `07` user vs org, `08` org trend, `11` user-vs-org trend overlay).
- **Drill-down** (`09` user events, `10` operation/taxonomy breakdown).

### Parameters

| Parameter | Maps to | Default | Notes |
|---|---|---|---|
| `W_TimeRange` | the query window | **last 7 days** (relative) | **Date range**, custom. Defaults to today going back 7 days; pick a custom start/end any time. Drives every panel. |
| `W_TargetUser` | `TargetUser` | *(empty)* | **User UPN** for the drill-down panels (`03`, `09`, `11`; also filters `01`/`02`/`04`/`05`/`07` when set). Empty = whole org; `09` shows nothing until a UPN is entered. |
| `W_NormalBandPct` | `NormalBandPct` | `20` | **Normal band.** How big a change counts as "normal" in Section 1 before a person is flagged (at 20%, plus or minus 20% vs their own previous period). Wider = fewer flags. |
| `W_MinUserActivity` | `MinUserActivity` | `5` | **Min activity.** When computing the company's typical levels (Section 2), accounts below this many events are ignored so barely-used accounts do not distort the averages. |
| `W_OutlierZ` | `OutlierZ` | `3.5` | **Outlier threshold.** In Section 2, how far from typical (on a robust \|modified z\| scale) a person must be before being marked unusual. Higher = only the most extreme cases. |

A plain-English **"About the controls"** help block is shown in the workbook itself,
just under the parameters, so business users do not need this table.
| `W_Desc01` ... `W_Desc11` | panel visibility | `Show` | **Per-panel description toggle.** Each graph/table has its own Show/Hide pill above it, implemented as a small parameters step with a `type: 10` parameter (not a links/tabs control, which the portal blanks on save). Defaults to Show. |

### Panel titles vs descriptions (v8)

Each panel has two text items:

- an **always-visible title** (`title-NN`) - the `### NN. ...` heading. It is never
  hidden, so the report stays navigable even when descriptions are collapsed.
- a **collapsible description** (`desc-NN`) - the body, toggled by the panel's
  **Description** Show/Hide pill (`W_DescNN`).

Both come from the **same** `panel-descriptions/NN.md` file: the build splits the
**first line** (the heading) into the title item and uses the **rest** as the
description body. So you still edit one file per panel; keep the heading on line 1.

### Panel descriptions live in `panel-descriptions/` (source of truth)

From v5 on, the text in each description panel is sourced from
[`panel-descriptions/NN.md`](panel-descriptions/) (one file per query, see that folder's
README for the mapping). **Edit the `.md` files**, then ask for the workbook to be rebuilt;
a new version is produced with those files copied verbatim into the matching panels. The
workbook description text is never hand-edited.

Style: non-technical business audience, a short bold heading with an icon, then
**What it shows** in plain language, plus **Tip** / **Keep in mind** / **Action needed**
where useful. No jargon, no em dashes. The three section banners use the `info` style.

### How the date range maps to each query

Each card's own **Time Range** control is **"Set in query"** (the query items carry no
`timeContext`), so the global `W_TimeRange` picker governs the window through the
`{W_TimeRange:start}` / `{W_TimeRange:end}` tokens. **Do not** set a per-card time range
in the editor; that clips the card and overrides the global picker (this was the v1
defect that returned no data).

- **Single-window panels** (`03`, `06`, `07`, `08`, `09`, `10`, `11`) read only the
  selected range, via the `{W_TimeRange:start}` / `{W_TimeRange:end}` tokens.
- **Model A own-baseline panels** (`01`, `02`, `04`, `05`) treat the selected range as
  the *current* period and compare it against the **immediately preceding equal-length**
  period. ⚠️ A long range therefore reads data proportionally further back (a 90-day
  range looks ~180 days back); confirm Log Analytics retention covers it, or the
  baseline looks artificially low.

> The KQL is the same logic as the `.kql` files, with `let` values replaced by `{W_*}`
> tokens. As in the other DEV workbook, the `sharepoint\system` exclusion entry is
> dropped (backslash escaping); `app@sharepoint` / `system@sharepoint`, guests, and the
> service-account watchlist are still excluded.
>
> **Divergence (v8):** `query-07` in the workbook now **zero-fills workloads** - every
> active person gets a row for every app (real figure or `0`), while the org stats
> (median/percentiles/MAD) still come only from users at/above `{W_MinUserActivity}`.
> The source `queries/org-comparison/07-user-vs-org-robust-zscore.kql` has **not** been
> changed; it still returns only workloads where a user was active. Port it across if you
> want them identical.

### Regenerating

Each version is produced by `dev-scratch/generate-workbook-vN.ps1` (local, git-ignored
build scripts) which assemble the JSON from the query set via `ConvertTo-Json`. To make
the next version, copy the latest script to `..._vN+1.ps1`, change the output filename
and the title version label, apply your edits, run it, then update this README. Do not
hand-edit the generated JSON.

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

1. Sentinel > **Workbooks** > **Add workbook**.
2. Open the new workbook > **Edit** > **</> Advanced Editor**.
3. Replace the contents with the chosen version's JSON > **Apply** > **Done editing**.
4. **Save** with a clear name (for example *Office Baselines, All Queries (DEV v2)*).

> `fallbackResourceIds` points at the existing workspace used by the other
> dashboards in this repo. On import, confirm the workbook is bound to the correct
> Log Analytics / Sentinel workspace.

## Validate before promoting (DEV to PROD)

- Every panel renders and returns rows for a known-active period and date range.
- Description Show/Hide tabs flip each panel's note on and off.
- `OrgFlag` colours correctly (amber = outlier-review, green = typical).
- Spot-check a couple of users against query `07` run directly in Logs; numbers match.
- Confirm the framing and caveats are acceptable to the client before wider sharing.

## Notes / next iterations

- v6 supersedes v5: every panel description rewritten for non-technical business users,
  explaining the exact output columns, status values, parameters, data scope and sorting.
  Synced from `panel-descriptions/NN.md` with `dev-scratch/build-workbook-v6.ps1`. The
  description-writing standard is recorded in the assistant's memory.
- v7 supersedes v6: grid status icons via `dev-scratch/build-workbook-v7.ps1`. Icons are
  driven by the status text, not the percentage change, so a small dip inside the normal
  band stays neutral and rows with no baseline are not mislabelled.
- v8 supersedes v7 (customer feedback), via `dev-scratch/build-workbook-v8.ps1`:
  - **Titles always visible.** Each panel's `### NN. ...` heading is split into its own
    `title-NN` item above the Description toggle; the toggle now hides only the body.
  - **Workload completeness in `07`.** Every active person shows a row for every app
    (zeros included, usually `Below P25`); org typical levels still exclude sub-threshold
    users so the median is not dragged down. See the divergence note above.
- v9 supersedes v8 (customer feedback), via `dev-scratch/build-workbook-v9.ps1`:
  - **Four operations classified.** `FileVersionsAllDeleted` (Content-Lifecycle),
    `SharingInvitationCreated` (Sharing-Collaboration, candidate), `SharingPolicyChanged`
    and `SPOTenantCmdlets` (Administrative) were appearing as `UNMAPPED` in panel `10`;
    they are now labelled. All are `EngagementSignal = No`, so `MeaningfulOps` and every
    metric panel are unchanged. The same rows were added to `queries/drilldown/10-*.kql`,
    `queries/00-*.kql`, `docs/activity-taxonomy.md` and the watchlist CSV so all taxonomy
    copies stay in sync.

### Grid status icons (v7)

| Column (queries) | Value | Icon |
|---|---|---|
| `Status` (`01`, `02`, `04`) | `Increase - review only` | trend up |
| | `Decrease - review only` | trend down |
| | `Within normal range` | success (green) |
| | `Insufficient baseline (low confidence)` / `No baseline activity` | unknown (grey) |
| `Direction` (`05`) | `Increase - review only` / `Decrease - review only` | trend up / trend down |
| `OrgFlag` (`07`) | `Outlier - review only` / `Typical` | warning / success |
| `EngagementSignal` (`10`) | `Yes` / `UNMAPPED` / `No` | success / warning / disabled |

Icons use documented workbook icon names only. To match the **Normal band** parameter,
trend up appears for `Increase - review only` (change above `+{W_NormalBandPct}%`) and
trend down for `Decrease - review only` (change below `-{W_NormalBandPct}%`); anything
inside the band stays neutral.
