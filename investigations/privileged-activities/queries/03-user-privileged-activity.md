# 03 - User flagged activity

**Companion to:** `03-user-privileged-activity.kql`
**Type:** Highlights (everything except normal)
**Output:** one row per non-normal action - highest severity first

> Observable telemetry only. A classified action is a **prompt to review**, not
> proof of misconduct. Many such actions are legitimate and expected of the role.

## What it answers

> "Did this user do anything administrative or high-risk, and what exactly was it?"

Same engine as query 01, but it drops `Normal user activity` and sorts by severity
(highest first), so you see the confirmed privileged changes, high-risk sharing /
data exposure, Azure control-plane changes, and items needing manual review without
scrolling the full timeline.

## Parameters

Same as query 01: `TargetUser`, `StartTime`, `EndTime`.

## Output columns

Same shape as query 01: `TimeGenerated, Source, Actor, ActivityClass, Severity,
Outcome, Category, Operation, Result, ClientIP, Target, Details, SeverityRank`.

## Step by step

1. **Parameters** and the signal lists (as in query 01).
2. The same three per-source sub-queries produce `ActivityClass`.
3. `union`, then `where ActivityClass != "Normal user activity"`.
4. Derive `Severity` (class base + failed-attempt downgrade) and
   `order by SeverityRank desc, TimeGenerated desc`.

## How to read it

- An **empty result** means no administrative or high-risk action by this user in
  the window (per the current signals) - a useful negative answer.
- Work top-down by `Severity`. For each row check `Outcome` (did it succeed?),
  `Target` (what was changed?), and correlate `TimeGenerated` / `ClientIP` with
  query 04.
- `Requires manual review` rows (e.g. group membership) need the group's purpose to
  judge - that context is not in these logs (a watchlist is the planned fix).

## Notes

- This query and query 01 share the same classification expressions - keep them in
  step (and with `00-config`) when tuning.

## Related

`02` (summary first) - `01` (full timeline incl. normal) - `04` (sign-in context).
