# Privileged Activities - user activity review

User-scoped review of Microsoft 365, Entra ID, and Azure activity. Each action is
given an **`ActivityClass`** and a **`Severity`** so administrative, high-risk, and
normal activity are distinguished (not collapsed into one flag). Give a username and
a date range, run a query, and see what that account did.

> ⚠️ **Read this first.** These results are *observable telemetry only*. A
> classified action is a **signal to review**, never evidence of wrongdoing -
> privileged work is normal and expected for privileged staff. This is event-level,
> privacy-sensitive monitoring of named individuals; confirm it is lawful,
> proportionate, approved, and transparent to staff before operational use.
> See [`docs/assumptions-and-limitations.md`](docs/assumptions-and-limitations.md).

> **Coverage limitation.** Detections are based **only** on the logs the client
> currently has: Entra **sign-in logs** (`SigninLogs`), Office 365 **activity**
> (`OfficeActivity`), and Azure **audit logs** (`AuditLogs` + `AzureActivity`).
> `AzureActivity` is **control-plane only** - it shows configuration changes, not
> data-plane access (Key Vault secret reads, Storage blob reads, mailbox / file
> content). This is **not** full coverage of Microsoft 365 / Azure / endpoint
> activity, and does not claim to capture all privileged activity.

## What this is

A set of plain Sentinel / Log Analytics **KQL queries** plus a documented
**privileged-operations taxonomy** and **methodology**. The use case: a client is
concerned that staff with privileged access may be performing privileged activities
the business is not aware of, and wants to look up any user over any period and see
their activity with the high-impact actions called out.

This is a **review / investigation** tool, not an alerting rule. It surfaces a named
user's actions for a human to assess.

## Data sources

`SigninLogs`, `OfficeActivity`, `AuditLogs` (Entra ID), and `AzureActivity` (Azure
control-plane). No Advanced Hunting. No other tables. "Azure Audit logs" is taken
to mean **both** `AuditLogs` and `AzureActivity`.

## How to use

All queries are plain KQL - paste into **Sentinel -> Logs**. Set the parameters at
the top of each file:

```kusto
let TargetUser = "jane.doe@contoso.com";   // the UPN to investigate
let StartTime  = ago(30d);                  // or datetime(2026-05-01)
let EndTime    = now();                      // or datetime(2026-06-01)
```

> Every `NN-*.kql` has a companion **`NN-*.md`** next to it explaining the logic,
> parameters, and how to read the output.

### Run order

| Step | File | Purpose |
|---|---|---|
| 1 | `queries/02-user-activity-summary.kql` | Overview: counts per source / `ActivityClass` / `Severity`. Run this first. |
| 2 | `queries/01-user-activity-timeline.kql` | The full chronological account of everything the user did, each row classified (normal activity kept). |
| 3 | `queries/03-user-privileged-activity.kql` | Everything except `Normal user activity`, highest severity first. |
| 4 | `queries/04-user-signin-context.kql` | Sign-in / location / MFA context to explain how those actions were reached. |

`queries/00-config-and-shared-taxonomy.kql` is a **reference** (parameters + the
classification signal lists + the class-to-severity map), not a report.

## Documentation

- [`docs/methodology.md`](docs/methodology.md) - how activity is gathered, why
  sign-ins are separated, how the date range works, run order, output shape.
- [`docs/privileged-operations-taxonomy.md`](docs/privileged-operations-taxonomy.md)
  - the per-source rules that drive the `Privileged` flag, with rationale.
- [`docs/assumptions-and-limitations.md`](docs/assumptions-and-limitations.md) -
  guardrails, assumptions, limitations, and the validation checklist.
- [`PROJECT-BRIEF.md`](PROJECT-BRIEF.md) - the living project brief.

## Status

Phase 1 (KQL + docs). Queries are drafts pending validation against real tenant
data - work through the checklist in `docs/assumptions-and-limitations.md` before
relying on them or building a workbook.
