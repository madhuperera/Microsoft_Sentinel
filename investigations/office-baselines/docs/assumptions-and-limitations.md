# Assumptions, Limitations & Guardrails

## 1. Ethical guardrails (apply to every output)

1. **Observable telemetry only.** These metrics reflect what M365 logged, not what a
   person did or how well they did it.
2. **Not a productivity measure.** Activity is **not** a proxy for productivity, work
   quality, effort, or hours worked. Do not present it as one.
3. **More events ≠ more work.** Volume is driven by device type, apps, sync clients,
   auth patterns, and background activity.
4. **Review only.** Every deviation (Model A) and outlier (Model B) is a *prompt to
   ask a question*, never evidence of underperformance or misconduct.
5. **Both directions are neutral.** A decrease is not "bad" and an increase is not
   "good". Leave, role change, project phase, or migration can all move the numbers.
6. **Context before conclusions.** Always look at the user-vs-own-baseline (Model A)
   first; org comparison (Model B) is supporting context, not a verdict.
7. **Privacy.** This is workforce-adjacent monitoring. Confirm it is lawful,
   proportionate, transparent to staff, and approved before operational use. Prefer
   aggregated/summary views; restrict access to drill-down (event-level) queries.

## 2. Assumptions made in the queries

- The `service-accounts` watchlist exists, is current, and exposes a `UPN` column
  (matching `reference-data/service-accounts/`). Queries reference it via
  `union isfuzzy=true`, so a **missing** watchlist no longer fails the query — it
  degrades gracefully to *no service-account exclusions* (the `UserType` filter and
  the static `ExcludedUPNs` list still apply). A watchlist that exists but lacks a
  `UPN` column will still error; an empty watchlist applies no exclusions.
- `OfficeActivity.UserId` and `SigninLogs.UserPrincipalName` hold the UPN and can be
  joined on `tolower(...)`.
- `UserType == "Regular"` (OfficeActivity) isolates normal users from
  Admin/System/Application/ServicePrincipal — **but it does NOT exclude guests**
  (B2B guests are also "Regular"). Guests are therefore excluded separately by
  dropping UPNs containing the `#EXT#` marker (`where UPN !contains "#ext#"`).
  `UserType =~ "Member"` (SigninLogs) excludes guests natively there.
- B2B guest accounts are assumed to carry the standard `#EXT#` marker in their UPN.
- The taxonomy in `docs/activity-taxonomy.md` is a reasonable first cut of meaningful
  operations for a typical tenant.
- Calendar-day normalisation is acceptable (working-day calendar not yet applied).
- All times are UTC.

## 3. Known limitations

- **Calendar vs working days** — periods with more weekends/holidays show lower
  rates. Both windows are treated the same, so trends remain valid, but absolute
  rates are not working-time-adjusted.
- **No role/department dimension** — these three tables don't carry a reliable peer
  attribute, so Model B defaults to whole-org. A peer-group watchlist would improve
  fairness and is the recommended Phase-2 refinement.
- **Tenant-specific operations** — operation names/volumes vary; the taxonomy must be
  validated per tenant.
- **`AADNonInteractiveUserSignInLogs`** — high-volume background/token traffic; not an
  engagement metric. Used only to separate background from interactive sign-ins.
- **Audit latency & retention** — `OfficeActivity` can lag; ensure the baseline and
  reporting windows sit within the workspace retention period.
- **Event inflation** — partially mitigated by using active-days as the primary
  metric, but raw event rates remain sensitive to app/sync behaviour.
- **Shared/delegated mailboxes & multi-user devices** can attribute activity in ways
  that don't map cleanly to one person.

## 4. Pre-workbook validation checklist

Run and review before building any dashboard:

- [ ] Confirm `AADNonInteractiveUserSignInLogs` is ingested (else drop its query).
- [ ] Confirm `OfficeActivity`, `SigninLogs` are ingested with adequate retention to
      cover `ReportPeriod + BaselinePeriod`.
- [ ] Confirm the `service-accounts` watchlist is populated and the `UPN` column name
      is correct; adjust queries if not.
- [ ] Run `10-workload-operation-breakdown.kql`; validate/tune the taxonomy against
      real operations and volumes.
- [ ] Spot-check `01` against a few known users — do the baseline vs current numbers
      look sane?
- [ ] Review the ±20% `NormalBandPct`: does it flag a sensible *proportion* of users
      (not everyone, not no one)?
- [ ] Review `OutlierZ` (3.5) and `MinUserActivity` against `06`/`07` output.
- [ ] Decide the peer-group dimension for Model B (whole-org vs department/role).
- [ ] Confirm with the client that the framing, access controls, and staff
      transparency around this reporting are agreed.
- [ ] Sign-off that outputs will be labelled "review only / not a productivity
      measure" wherever they are surfaced.
