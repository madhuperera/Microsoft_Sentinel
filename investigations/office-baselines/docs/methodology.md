# Methodology — Baseline & Organisation Comparison

This document explains *how* activity is measured and compared, and *why* the
methods were chosen. It is meant to be reviewed and adjusted by another Microsoft
365 consultant. Nothing here treats activity as a measure of productivity — see
[`assumptions-and-limitations.md`](assumptions-and-limitations.md).

---

## 1. What we measure (metrics)

We deliberately avoid using raw `OfficeActivity` event counts as the headline,
because:

- one human action can emit several audit records;
- sync clients and background services emit large volumes that aren't "work";
- different roles/devices/apps emit very different volumes.

So we use a small set of **normalised, noise-resistant** metrics built only from
operations the taxonomy marks as meaningful (`EngagementSignal = Yes`):

| Metric | Definition | Why |
|---|---|---|
| **Active days** | Distinct calendar days (UTC) with ≥1 meaningful action. | Primary engagement metric — resists per-event inflation. A noisy day and a quiet day both count once. |
| **Active-day ratio** | Active days ÷ days in period. | Normalises across periods of different length. |
| **Meaningful events / day** | Count of meaningful operations ÷ days in period. | Secondary context, not the headline. |
| **Active workloads** | Distinct M365 workloads touched (Exchange, SharePoint, OneDrive, Teams…). | Breadth of engagement; resists volume skew. |
| **Sign-in active days** | Distinct days with a successful interactive sign-in (`SigninLogs`). | Independent engagement proxy from a different source. |

**Primary classification metric = active-day ratio.** Event rate is reported
alongside as context only.

> `AADNonInteractiveUserSignInLogs` is **not** an engagement metric — it is
> background/token traffic. If used at all, it is only to show how much of a user's
> sign-in volume is background vs interactive.

## 2. Normalisation

All metrics are converted to **per-day rates** before any comparison:

```
rate = metric / (period_length / 1d)
```

This keeps the selected reporting period and the baseline period comparable even
if their lengths differ, and keeps the model honest if you change the window.

> **Known simplification:** we normalise by *calendar* days, not *working* days.
> A period containing more weekends/holidays will show a lower rate. This is
> acceptable for trend/baseline purposes (both periods are treated the same way) but
> is called out as a limitation. A working-day calendar could be layered in later.

## 3. Model A — User vs own baseline (primary)

For each user, compute each metric for two adjacent windows of equal length:

```
Baseline window:  [ now - ReportPeriod - BaselinePeriod , now - ReportPeriod )
Current  window:  [ now - ReportPeriod                  , now                 )
```

Both `ReportPeriod` and `BaselinePeriod` are `let` parameters (default `30d` each;
set `BaselinePeriod` larger for a steadier baseline if desired).

**Change** is the percentage difference of the *rate* vs the baseline *rate*:

```
ChangePct = (current_rate - baseline_rate) / baseline_rate * 100
```

### Classification bands

| Condition | Status |
|---|---|
| baseline below confidence floor (`MinBaselineEvents`) | `Insufficient baseline (low confidence)` |
| no baseline activity at all | `No baseline activity` |
| `|ChangePct| ≤ NormalBandPct` | `Within normal range` |
| `ChangePct > NormalBandPct` | `Increase - review only` |
| `ChangePct < -NormalBandPct` | `Decrease - review only` |

- `NormalBandPct` default **20** (i.e. ±20%). Configurable.
- `MinBaselineEvents` is a **floor** so that tiny baselines (e.g. 2 events → 6
  events = +200%) don't generate noise. Small absolute numbers produce huge
  percentages; the floor suppresses those low-confidence cases.
- Both **increase and decrease** are *review only*. Neither is good or bad on its
  own. A drop might be annual leave, a project handover, or a role change; a spike
  might be a migration, a sync re-index, or a busy period.

## 4. Model B — User vs organisation / peer group (secondary)

The goal: is a user's per-workload activity *broadly in line* with the
organisation? The main comparison stays Model A; this adds context.

### Why robust statistics (not mean / standard deviation)

M365 activity per user is **heavily right-skewed** and contains outliers
(power users, service-like accounts, automation). Mean and standard deviation are
dragged around by those outliers, so a "normal" range built from them is
misleading. We therefore use **robust** measures that ignore the tails:

| Measure | Use |
|---|---|
| **Median (P50)** | Central tendency that ignores outliers. |
| **Percentiles (P25 / P50 / P75 / P90)** | Explainable "where does this user sit" bands. No distribution assumption. |
| **MAD** (median absolute deviation) | Robust spread: `median(|x − median|)`. |
| **Modified z-score** | `0.6745 × (x − median) / MAD`. Robust analogue of a z-score. |

### Outlier flag

A user is flagged as an outlier for a workload when:

```
|modified z-score| > OutlierZ        (default OutlierZ = 3.5)
```

3.5 is the conventional Iglewicz–Hoaglin threshold. Configurable. As with Model A,
"outlier" means **worth a look**, not "wrong".

### Reducing misleading conclusions

- **Service accounts excluded** via the `service-accounts` watchlist.
- **System principals excluded** (`SHAREPOINT\system`, `app@sharepoint`, …).
- **Activity floor:** users below a minimum activity level are excluded from the
  stats so near-zero users don't distort the median/MAD or get over-flagged.
- **Peer grouping:** the stats can be computed per **peer group** rather than the
  whole org, so people in different roles are compared with similar people. The
  default is whole-org (no reliable role attribute is available from these three
  tables); the query exposes a `GroupKey` you can repoint at a department/role
  column sourced from a watchlist when one exists. **This is the recommended Phase-2
  refinement.**
- **Percentile band is the headline** (easy to explain to non-statisticians); the
  modified z-score is the statistical flag.

## 5. Identity resolution across sources

- `OfficeActivity.UserId` and `SigninLogs.UserPrincipalName` both generally hold the
  UPN. We join on `tolower(UPN)` to be case-safe.
- Display names are sourced from `SigninLogs` (most reliable of the three tables).

## 6. Parameters (single source of truth in `00-config-and-shared-taxonomy.kql`)

| Parameter | Default | Meaning |
|---|---|---|
| `ReportPeriod` | `30d` | Selected/current reporting window length. |
| `BaselinePeriod` | `30d` | Length of the prior baseline window. |
| `NormalBandPct` | `20.0` | ± band treated as normal variation (Model A). |
| `MinBaselineEvents` | `20` | Baseline confidence floor (Model A). |
| `OutlierZ` | `3.5` | Modified-z outlier threshold (Model B). |
| `MinUserActivity` | `5` | Activity floor for inclusion in org stats (Model B). |
| `ServiceAccountWatchlist` | `"service-accounts"` | Watchlist used to exclude service accounts. |

## 7. Output shape (for later graphing)

Queries are shaped so a future workbook can chart them directly:

- **Trends over time** — daily bins (`03`, `08`), ready for `render timechart`.
- **Baseline vs current** — paired columns per user/workload (`01`, `02`).
- **Workload-level** — grouped by `OfficeWorkload` (`02`, `06`, `08`).
- **Org-level** — robust aggregates (`06`).
- **User vs org** — per-user percentile band + modified z (`07`).
- **Drill-down** — raw events behind any summary (`09`, `10`).
