# 04 - User sign-in context

**Companion to:** `04-user-signin-context.kql`
**Type:** Context (authentication, not actions)
**Output:** one row per interactive sign-in - newest first

> Observable telemetry only. `MgmtSurface = Yes` means the user signed in to admin
> tooling - it does **not** by itself mean they changed anything. Correlate with
> 01/03 for actual actions.

## What it answers

> "When and from where did this user authenticate, on what client, with what
> MFA / Conditional Access - and were they signing in to admin tooling?"

Sign-ins are kept out of the activity timeline (01/03) because they are
authentication events, not actions. This query is the supporting context: it lets
you confirm whether a privileged action seen in 01/03 came from a normal device,
location, and client - or from somewhere unexpected.

## Parameters

| Parameter | Default | Meaning |
|---|---|---|
| `TargetUser` | `jane.doe@contoso.com` | **Set this** to the UPN under investigation. |
| `StartTime` | `ago(30d)` | Window start, or `datetime(2026-05-01)`. |
| `EndTime` | `now()` | Window end, or `datetime(2026-06-01)`. |

## Output columns

| Column | Meaning |
|---|---|
| `TimeGenerated` | When the sign-in occurred (UTC). |
| `App` / `Resource` | The application and resource the sign-in targeted. |
| `MgmtSurface` | `Yes` if `App`/`Resource` is admin tooling (`MgmtSurfaceApps`). |
| `Status` | `Success`, or `Failure (<ResultType>)`. |
| `IPAddress`, `Country`, `City` | Where the sign-in came from. |
| `ClientApp` | Browser / mobile / legacy client used. |
| `OS`, `Browser` | Device detail. |
| `MFA` | `AuthenticationRequirement` (single-factor vs MFA). |
| `ConditionalAccess` | CA evaluation result for the sign-in. |
| `Risk` | `RiskLevelDuringSignIn`. |

## Step by step

1. **Parameters** and `MgmtSurfaceApps` (copied from `00-config`).
2. Filter `SigninLogs` to the window and `UserPrincipalName == TargetUser`.
3. Derive `MgmtSurface` with `has_any` against `MgmtSurfaceApps` on both the app
   and resource names.
4. Project the readable context columns; `ResultType == "0"` is success.
5. `order by TimeGenerated desc`.

## How to read it

- Filter `MgmtSurface == "Yes"` to see sign-ins to admin tooling, then line those
  timestamps up against privileged actions in query 03.
- Watch for privileged actions whose nearest sign-in was from an unusual
  `Country` / `IPAddress`, a legacy `ClientApp`, single-factor `MFA`, or a
  non-success `ConditionalAccess`.

## Notes

- This query uses interactive `SigninLogs` only. Non-interactive / token sign-ins
  (`AADNonInteractiveUserSignInLogs`) are out of scope by design - confirm with the
  client whether that table is even ingested.
- A sign-in to a management surface with **no** matching action in 01/03 usually
  means the user opened a console but changed nothing.

## Related

`01` / `03` (the actions this context explains) - `02` (summary).
