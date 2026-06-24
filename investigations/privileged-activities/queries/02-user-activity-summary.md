# 02 - User activity summary

**Companion to:** `02-user-activity-summary.kql`
**Type:** Overview
**Output:** one row per Source + Category, with event and privileged counts

> Observable telemetry only. Privileged counts are review signals, not a verdict.

## What it answers

> "Before I read every line - roughly what did this user touch, where, and how
> much of it was privileged?"

Run this **first**. It gives the shape of the activity so you know which sources
and categories are worth drilling into with query 01 (full timeline) or query 03
(privileged only).

## Parameters

Same as query 01: `TargetUser`, `StartTime`, `EndTime`.

## Output columns

| Column | Meaning |
|---|---|
| `Source` | `Office365`, `EntraID`, or `Azure`. |
| `Category` | O365 workload / Entra category / Azure resource provider. |
| `Events` | Total in-scope actions for that source + category. |
| `PrivilegedEvents` | How many of those were flagged privileged. |
| `FirstSeen` / `LastSeen` | Time span of activity in that bucket (UTC). |
| `PrivilegedPct` | `PrivilegedEvents / Events` as a percentage. |

## Step by step

1. **Parameters** and the privileged signal lists (as in query 01).
2. The same three per-source sub-queries as query 01, but each projects only
   `TimeGenerated, Source, Category, IsPriv` (no detail columns).
3. `union`, then `summarize` to counts and the time span **by `Source,
   Category`**, add `PrivilegedPct`, and `order by PrivilegedEvents desc`.

## How to read it

- Rows with a high `PrivilegedEvents` (or `PrivilegedPct`) are where to look
  first; open query 03 for those.
- `EntraID` / `RoleManagement`, `Azure` / `Microsoft.Authorization`, and O365
  admin categories are the usual high-signal buckets.
- A user with **only** `Privileged = 0` rows across all sources did no
  administrative action in the window (per these signals).

## Related

`01` (full timeline) - `03` (privileged only) - `04` (sign-in context).
