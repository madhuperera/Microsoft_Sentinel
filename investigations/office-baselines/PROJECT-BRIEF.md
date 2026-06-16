# Project Brief — Microsoft 365 Activity Baseline Reporting

> **Status:** Phase 1 — KQL foundation, documentation, and taxonomy.
> **Workbook/dashboard:** *Not in scope yet.* Deferred until queries, assumptions,
> taxonomy, and comparison methods are validated.
>
> This file is the reusable, living brief for the project. It is intended to be
> portable: drop it into another Claude project, Claude Code session, or repo and
> it should carry enough context to continue the work without re-explaining. It is
> **updated automatically whenever new guidance is provided.**

---

## 1. Purpose

The client wants visibility of **observable Microsoft 365 activity patterns** for
users, primarily to understand activity **trends** when staff are working remotely.

The core question the solution answers is:

> "Is this user's observable M365 activity in the selected period broadly in line
> with *their own* recent baseline, and broadly in line with the wider
> organisation — or has it changed enough to be worth a human looking at?"

## 2. Non-negotiable framing (read before anything else)

Microsoft 365 activity data **must not** be presented as a direct measure of:

- productivity
- work quality
- effort
- hours worked

Telemetry counts vary heavily based on device type, application behaviour,
authentication patterns, sync clients, workload usage, and background activity.
**A user with more events is not necessarily doing more work.**

Therefore:

- Deviations are **flagged for review only**. They are *signals to ask a question*,
  never *evidence of underperformance or misconduct*.
- The primary comparison is **a user against their own baseline**, not against
  other people.
- Every output and document carries this caveat.

## 3. Scope and constraints

| Item | Decision |
|---|---|
| Phase | KQL + docs only. No workbook yet. |
| Data sources | `SigninLogs`, `AADNonInteractiveUserSignInLogs` (if available), `OfficeActivity`. Nothing else. |
| Advanced Hunting | **Not used.** Sentinel/Log Analytics KQL only. |
| Ranking model | **No** simple highest-to-lowest "who did the most" leaderboard. |
| Primary model | Each user vs **their own previous baseline period**. |
| Secondary model | Each user vs **organisation / peer group**, using robust statistics. |
| Configurability | Reporting period, baseline period, and review thresholds are all `let` parameters. |
| Normal band | Activity within **±20%** of the user's own baseline = normal (configurable). |
| Outputs | Support both **summary** analysis and **drill-down** to underlying events. |
| Future-proofing | Outputs shaped so they can later feed workbook graphs (trends, baseline vs current, per-workload, org-level, user-vs-org). |

## 4. The two comparison models

### Model A — User vs own baseline (primary)
For a selected reporting period (e.g. 30 days), compare each user's observable
activity against the **immediately preceding** period of the same length (the prior
30 days) **for the same user**. Classify the change against a configurable
normal band (default ±20%). See `docs/methodology.md`.

### Model B — User vs organisation / peer group (secondary)
Help understand whether a user's activity in workloads such as SharePoint,
OneDrive, Teams, or Exchange is broadly in line with company activity patterns.
Uses **robust statistics** (median, MAD, percentiles, modified z-score) rather than
mean/standard-deviation, because M365 activity is heavily right-skewed and
sensitive to outliers, service accounts, and role differences. See
`docs/methodology.md`.

## 5. Metric philosophy (why we don't just `count()`)

Raw audit-event counts are misleading: one human action can emit several audit
records, and sync clients / background processes generate large volumes. So:

- We count **only curated, meaningful operations** (see `docs/activity-taxonomy.md`),
  not every `OfficeActivity` row.
- The **primary engagement metric is "active days"** (distinct days with at least
  one meaningful action), which resists per-event inflation.
- Event counts are kept as **secondary context**, normalised to a per-day rate.
- Metrics are normalised to **per-day rates** so periods of different lengths stay
  comparable.

## 6. Noise / exclusion rules

- Exclude service accounts via the `service-accounts` watchlist
  (`reference-data/service-accounts/`).
- Exclude system principals (`SHAREPOINT\system`, `app@sharepoint`, etc.).
- Restrict `OfficeActivity` to `UserType == "Regular"` and `SigninLogs` to
  `UserType == "Member"`.
- Count only operations flagged `EngagementSignal = Yes` in the taxonomy.
- `AADNonInteractiveUserSignInLogs` is **background/token traffic** — it is *not*
  an engagement metric and must not be counted as one. It is included only to help
  separate background from interactive activity.

## 7. Repository layout for this project

```
investigations/office-baselines/
├── README.md                         · index + run order
├── PROJECT-BRIEF.md                  · this file (living brief)
├── docs/
│   ├── methodology.md                · comparison maths, thresholds, statistics
│   ├── activity-taxonomy.md          · meaningful vs noisy operations + rationale
│   └── assumptions-and-limitations.md· guardrails, caveats, validation checklist
├── queries/
│   ├── 00-config-and-shared-taxonomy.kql      · canonical params + taxonomy block
│   ├── baseline/                     · Model A (user vs own baseline)
│   │   ├── 01-user-vs-own-baseline-summary.kql
│   │   ├── 02-user-baseline-by-workload.kql
│   │   ├── 03-user-activity-trend.kql
│   │   ├── 04-signin-active-days-baseline.kql
│   │   └── 05-flagged-for-review.kql
│   ├── org-comparison/               · Model B (user vs org / peer group)
│   │   ├── 06-org-workload-robust-stats.kql
│   │   ├── 07-user-vs-org-robust-zscore.kql
│   │   └── 08-org-workload-trend.kql
│   └── drilldown/                    · underlying-event review
│       ├── 09-user-event-drilldown.kql
│       └── 10-workload-operation-breakdown.kql
└── (taxonomy watchlist source lives in reference-data/office-activity-taxonomy/)
```

## 8. Guidance log (append-only)

Newest first. Each entry records guidance that shaped the project so the direction,
assumptions, constraints, and principles stay current.

- **2026-06-16** — Project initiated. Phase 1 = KQL + docs only, no workbook.
  Data sources limited to `SigninLogs`, `AADNonInteractiveUserSignInLogs` (if
  available), `OfficeActivity`. No Advanced Hunting. Primary = user vs own
  baseline; secondary = user vs org using a method chosen to avoid misleading
  conclusions (decided: robust statistics — median/MAD/percentiles/modified
  z-score). Normal band ±20% (configurable). Deviations = review only, never proof
  of misconduct. Build an activity taxonomy separating meaningful from noisy
  events. Outputs to support summary + drill-down and future graphing. Branding:
  **generic / unbranded** for now.

## 9. Open items to validate before Phase 2 (workbook)

See `docs/assumptions-and-limitations.md` for the full checklist. Headlines:

- Confirm `AADNonInteractiveUserSignInLogs` is ingested in the target workspace.
- Validate the taxonomy against the tenant's real `OfficeActivity` operations.
- Confirm the `service-accounts` watchlist is populated and current.
- Sanity-check the ±20% band and the modified-z outlier threshold against real data.
- Decide the peer-group dimension for Model B (whole-org vs department vs role).
