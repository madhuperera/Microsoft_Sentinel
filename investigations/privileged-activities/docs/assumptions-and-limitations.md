# Assumptions, limitations & guardrails

## 1. Ethical and legal guardrails (apply to every output)

1. **Observable telemetry only.** These rows reflect what the platform logged, not
   a complete account of what a person did.
2. **Review only.** A classified (non-normal) action is a *prompt to ask a
   question*, never evidence of wrongdoing. Many privileged actions are legitimate
   and expected of the role.
3. **Privileged work is normal for privileged staff.** This tool is for confirming
   that privileged activity is **known and expected**, not for assuming it is not.
4. **Context before conclusions.** Correlate an action (01 / 03) with the sign-in
   context (04) and the business reason before drawing any inference.
5. **Privacy.** This is workforce-adjacent monitoring of named individuals. Confirm
   it is lawful, proportionate, transparent to staff, and approved before
   operational use. Restrict access to these event-level queries.
6. **Attribution is not identity-proofing.** A row attributed to a UPN means the
   logs recorded that account performing the action; it does not by itself prove
   who was at the keyboard (shared credentials, delegated access, token replay).

## 2. Assumptions made in the queries

- `OfficeActivity.UserId`, `SigninLogs.UserPrincipalName`, and
  `AzureActivity.Caller` hold the user's UPN; `AuditLogs` holds it at
  `InitiatedBy.user.userPrincipalName`. All matches are case-insensitive.
- "Azure Audit logs" means **both** `AuditLogs` (Entra) and `AzureActivity`
  (Azure control-plane). The queries reference both; whichever is not ingested
  simply returns no rows for that source (the `union` still succeeds).
- The classification signal lists in `00-config` are a **reasonable first cut** for
  a typical tenant, not a tenant-validated list. They were docs-verified against
  Microsoft's published operation names but not yet against live tenant data.
- **Entra classification is operation-name primary.** The `AuditLogs.Category`
  column is documented by Microsoft as effectively fixed (`"Audit"`) in Log
  Analytics, and the activity-to-category mapping is inconsistent, so `Category` is
  used only as a low-confidence secondary net (the "Possible admin activity
  (review)" fallback) and must be validated per tenant.
- The Entra **self-service downgrade** assumes `InitiatedBy.user.id` and
  `TargetResources[0].id` are populated and comparable. When either is empty the
  action is treated as not-self-service (i.e. it stays flagged) - a deliberately
  conservative default.
- `AzureActivity` reads are not logged to that table, so restricting to
  `Administrative` write / delete / action events captures the meaningful changes.
- Times are UTC; the investigator supplies the window.

## 3. Known limitations

- **No role-membership feed.** These tables do not tell us who currently holds
  which privileged role, so we classify the **action**, not the person. A
  privileged-roster watchlist would let us also weight *who* acted (recommended
  refinement).
- **Tenant-specific operations.** Operation names and volumes vary between tenants;
  the signal lists must be validated per tenant (use query 02).
- **`Caller` can be a GUID.** For service-principal-initiated Azure actions
  `Caller` is a GUID, not a UPN; a user-UPN lookup naturally excludes those. If you
  need SPN activity, match the object id instead.
- **Audit latency & retention.** `OfficeActivity` and `AuditLogs` can lag, and all
  four tables are bounded by workspace retention - ensure the requested window sits
  within retention.
- **Coverage gaps / data-plane blind spots.** Anything not surfaced by these four
  tables is invisible here. Notably: Key Vault **secret reads** and Storage **blob
  access** are data-plane and not in `AzureActivity`; mail **forwarding** is a
  `Set-Mailbox` parameter, not a distinct operation (inspect `Details`); PIM
  activations log under `ApplicationManagement` / `GroupManagement`, not
  `RoleManagement`. See `privileged-operations-taxonomy.md` for the full list.
- **Heuristic classification.** The admin-cmdlet regex and substring matches can
  both over-flag and under-flag; low-confidence matches are deliberately set to the
  `Possible admin activity (review)` class rather than a confirmed-privileged class.
- **Severity ignores target / scope.** Severity is derived from the action class
  and the success / failure outcome only. It does not yet reflect the **target**
  (which user, group, or resource) or **administrative scope**, because no
  privileged-roster / group-purpose feed exists in these tables. Group membership
  and generic identity changes are therefore `Requires manual review`.
- **Shared / delegated access.** Delegated mailbox access, "act on behalf of", and
  shared accounts can attribute activity in ways that do not map cleanly to one
  person.

## 4. Pre-operational validation checklist

Run and review before relying on this for an investigation:

- [ ] Confirm `SigninLogs`, `OfficeActivity`, `AuditLogs`, and `AzureActivity` are
      ingested, with retention covering the windows you will query.
- [ ] Run query 02 against a few known privileged users; confirm the
      `Source` / `ActivityClass` / `Severity` split looks sane.
- [ ] Validate / tune the signal lists in `00-config` against the tenant's real
      operations (and propagate changes to queries 01 / 02 / 03).
- [ ] **Validate the Entra `Category` secondary net** - confirm whether
      `AuditLogs.Category` carries activity categories in this tenant; if not, the
      "Possible admin activity (review)" fallback will be empty (operation-name
      classes are unaffected).
- [ ] Spot-check query 03 against a user with known recent admin work - are their
      actions captured and correctly classed?
- [ ] Spot-check that a non-privileged user returns only low-severity / empty
      results in query 03.
- [ ] Confirm with the client that the framing, access controls, and staff
      transparency around this monitoring are agreed.
- [ ] Agree that outputs will be labelled "review only / not proof of misconduct"
      wherever they are surfaced.
- [ ] Decide whether a privileged-roster watchlist will be added to weight *who*
      acted, not just *what* was done.
