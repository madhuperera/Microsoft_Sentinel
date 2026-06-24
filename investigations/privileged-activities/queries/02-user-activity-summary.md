# 02 - User activity summary

**Companion to:** `02-user-activity-summary.kql`
**Type:** Overview
**Output:** one row per Source + ActivityClass + Severity, with counts and span

> Observable telemetry only. Class / severity are review signals, not a verdict.

## What it answers

> "Before I read every line - what did this user touch, how was it classified, and
> how severe?"

Run this **first**. It shows the shape of the activity so you know which classes
and severities are worth drilling into with query 01 (full timeline) or query 03
(flagged only).

## Parameters

Same as query 01: `TargetUser`, `StartTime`, `EndTime`.

## Output columns

| Column | Meaning |
|---|---|
| `Source` | `Office365`, `EntraID`, or `Azure`. |
| `ActivityClass` | The classification bucket. |
| `Severity` | Derived severity (after failed-attempt downgrade). |
| `Events` | Count of actions in that Source + class + severity. |
| `FirstSeen` / `LastSeen` | Time span of that bucket (UTC). |
| `SeverityRank` | 3/2/1/0 for ordering. |

## Step by step

1. **Parameters** and the signal lists (as in query 01).
2. The same three per-source sub-queries, projecting only `TimeGenerated, Source,
   ActivityClass, Result`.
3. `union`, derive `Severity` (class base + failure downgrade), then `summarize`
   counts and the time span **by `Source, ActivityClass, Severity`**, and
   `order by SeverityRank desc, Events desc`.

## How to read it

- The top rows are the highest-severity buckets - open query 03 for those.
- `High` rows in `Privileged role/RBAC change`, `App/consent/service principal
  change`, `Privileged policy/security config change`, or `High-impact Azure
  control-plane change` are the buckets the client most cares about.
- A user whose rows are all `Normal user activity` / `Info` did nothing
  administrative or high-risk in the window (per the current signals).

## Related

`01` (full timeline) - `03` (flagged only) - `04` (sign-in context).
