# 05 — Users flagged for review

**Companion to:** `05-flagged-for-review.kql`
**Model:** A (review shortlist)
**Output:** one row per **flagged** user — direction, magnitude, and the numbers behind it

> "Flagged" = **worth asking a question about**, never a finding of wrongdoing or
> underperformance. Always pair with context (leave, role change, projects).

## What it answers

The actionable shortlist: only the users whose **active-day ratio** moved *outside*
the normal band vs their own baseline, with low-confidence baselines already
removed. It is the same logic as `01`, pre-filtered to the rows a human should look
at.

## Parameters

| Parameter | Default | Meaning |
|---|---|---|
| `ReportPeriod` / `BaselinePeriod` | `30d` / `30d` | Current / baseline window lengths. |
| `NormalBandPct` | `20.0` | Anything beyond ±this is flagged. |
| `MinBaselineEvents` | `20` | Baseline confidence floor; quieter baselines are excluded entirely. |

## Step by step

1. **Windows, exclusions, `MeaningfulOps`** — identical scaffold to `01`.

2. **`OfficeMetrics(...)`** — a trimmed version of `01`'s builder: per window it
   produces `Events`, `ActiveDays`, and `ActiveDayRatio` per `UPN` (guests via
   `#ext#`, service and system accounts excluded).

3. **Run for both windows**, build `UserList` from member sign-ins.

4. **Join** `kind=fullouter` on `UPN`; `coalesce` builds `B_ActiveDayRatio`,
   `C_ActiveDayRatio`, `B_Events`, `C_Events`.

5. **Confidence gate (the first filter).**
   `where B_Events >= MinBaselineEvents and B_ActiveDayRatio > 0` keeps only users
   with a trustworthy baseline (this is why low-confidence rows never appear here).

6. **Compute change.** `ChangePct = (C − B) / B × 100` on the active-day ratio.

7. **Band gate (the second filter).** `where abs(ChangePct) > NormalBandPct` — keep
   only movements outside the normal band.

8. **Direction.** `Direction = iff(ChangePct > 0, "Increase - review only",
   "Decrease - review only")`.

9. **Display name & filter.** `leftouter` to `UserList`, then
   `where isnotempty(UserDisplayName)`.

10. **Project & sort** by `abs(ChangePct) desc` — biggest movers (either direction)
    at the top.

## Reading the output

- Every row here is, by construction, **outside ±`NormalBandPct`** *and* has a
  confident baseline. The absence of a user means "within normal range" or "low
  confidence", not "no data".
- `B_`/`C_` = Baseline/Current. Use `09`/`10` to understand *why* before drawing any
  conclusion.

## Related

`01` (the full per-user table this shortlist is drawn from) · `09`/`10` (drill-down)
· `assumptions-and-limitations.md` (the guardrails on interpreting flags).
