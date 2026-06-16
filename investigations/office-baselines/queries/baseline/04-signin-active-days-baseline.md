# 04 — Sign-in active days vs own baseline

**Companion to:** `04-signin-active-days-baseline.kql`
**Model:** A (independent proxy)
**Output:** one row per user — baseline vs current sign-in active-day ratio, % change, distinct apps, status

> Observable telemetry only. **Not** a productivity measure. Review signals only.

## What it answers

An engagement proxy built from a **different source** than `01`/`02`: distinct days
with a *successful interactive sign-in*. Useful to corroborate (or question) the
OfficeActivity picture — e.g. if OfficeActivity dropped but sign-in days held
steady, the cause may be workload/telemetry, not the person.

> `AADNonInteractiveUserSignInLogs` is deliberately **not** used as a metric — it is
> background/token traffic. A commented optional block at the bottom shows how to
> split interactive vs non-interactive *for context only*.

## Parameters

| Parameter | Default | Meaning |
|---|---|---|
| `ReportPeriod` / `BaselinePeriod` | `30d` / `30d` | Current / baseline window lengths. |
| `NormalBandPct` | `20.0` | ± band (%) treated as normal. |
| `MinBaselineDays` | `3` | Baseline confidence floor in *active sign-in days*. |

## Step by step

1. **Windows & days** — same scaffold as `01`.

2. **`ServiceAccountUPNs`** from the watchlist (`isfuzzy`). No `#ext#` filter is
   needed here because the `SigninLogs` member filter already excludes guests.

3. **`SigninMetrics(winStart, winEnd, days)`** — per window:
   - filters `SigninLogs` to the window, `UserType =~ "Member"` (case-insensitive),
     and `ResultType == 0` (**successful** sign-ins only);
   - lowercases `UserPrincipalName` → `UPN`, drops service accounts;
   - `summarize` per UPN: **`SignInDays`** (distinct day-bins), **`DistinctApps`**
     (distinct `AppDisplayName`), and `arg_max(TimeGenerated, UserDisplayName)` to
     carry the latest display name;
   - derives **`SignInDayRatio`** = SignInDays ÷ days.

4. **Run for both windows** → `Baseline`, `Current`.

5. **Join** `kind=fullouter` on `UPN`; `coalesce` rebuilds `UPN`, `UserDisplayName`
   (preferring the current side) and the `B_`/`C_` pairs for sign-in days, ratio,
   and app count.

6. **Change & status.** `ChangePct = (C_Ratio − B_Ratio) / B_Ratio × 100`; the same
   five-way `case()` banding, but the confidence floor is `MinBaselineDays`.

7. **Filter & project.** `where isnotempty(UserDisplayName)` drops unresolved
   accounts; output the `B_`/`C_` pairs, change %, app counts, and status; sort by
   `ChangePct asc` (largest decreases first).

8. **Optional block (commented).** A `union` of `SigninLogs` + 
   `AADNonInteractiveUserSignInLogs` pivoted by `Kind` — context only; do not
   classify on non-interactive volume.

## Reading the output

- `B_` = Baseline, `C_` = Current. `SignInDayRatio` is the headline (normalised);
  `DistinctApps` is supporting context (breadth of apps used).
- Compare against `01`: agreement strengthens a signal; divergence suggests the
  OfficeActivity change is workload/telemetry-driven rather than engagement-driven.

## Related

`01` (OfficeActivity-based baseline) · `assumptions-and-limitations.md` (why
non-interactive sign-ins are excluded).
