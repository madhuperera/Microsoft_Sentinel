# Assumptions, limitations & guardrails

## 1. Ethical and legal guardrails (apply to every output)

1. **Observable telemetry only.** These rows reflect what the platform logged, not
   a complete account of what a person did.
2. **Review only.** A highlighted (privileged) action is a *prompt to ask a
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
- The privileged signal lists in `00-config` are a **reasonable first cut** for a
  typical tenant, not a tenant-validated list. They were docs-verified against
  Microsoft's published operation names but not yet against live tenant data.
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
  both over-flag (a benign `Set-` cmdlet) and under-flag (a privileged operation
  not yet in the list). Treat the flag as a starting point.
- **Shared / delegated access.** Delegated mailbox access, "act on behalf of", and
  shared accounts can attribute activity in ways that do not map cleanly to one
  person.

## 4. Pre-operational validation checklist

Run and review before relying on this for an investigation:

- [ ] Confirm `SigninLogs`, `OfficeActivity`, `AuditLogs`, and `AzureActivity` are
      ingested, with retention covering the windows you will query.
- [ ] Run query 02 against a few known privileged users; confirm the
      `Source` / `Category` split and `PrivilegedEvents` look sane.
- [ ] Validate / tune the signal lists in `00-config` against the tenant's real
      operations (and propagate changes to queries 01 / 02 / 03).
- [ ] Spot-check query 03 against a user with known recent admin work - are their
      actions captured and correctly reasoned?
- [ ] Spot-check that a non-privileged user returns an empty query 03.
- [ ] Confirm with the client that the framing, access controls, and staff
      transparency around this monitoring are agreed.
- [ ] Agree that outputs will be labelled "review only / not proof of misconduct"
      wherever they are surfaced.
- [ ] Decide whether a privileged-roster watchlist will be added to weight *who*
      acted, not just *what* was done.
