# Privileged operations taxonomy

How we decide whether a single action is **administrative / privileged**, per
source. This is the source of truth behind the `Privileged` column and the
`PrivilegeReason` text in the queries. The canonical signal lists live in
[`../queries/00-config-and-shared-taxonomy.kql`](../queries/00-config-and-shared-taxonomy.kql);
this document explains the reasoning so another consultant can review and tune it.

> Observable telemetry only. A privileged action is a prompt to review, never proof
> of misconduct. See [`assumptions-and-limitations.md`](assumptions-and-limitations.md).

## Guiding principle: classify the action, not the person

These three tables do not give us a reliable, current list of who holds which
directory or Azure role. So we do **not** try to label a user as "an admin".
Instead we ask, for each event: *is this action itself administrative or
high-impact?* That keeps the model honest with the data we actually have, and it
catches the case the client cares about - a user **performing** privileged
activity - regardless of how their access was granted.

A future refinement (see assumptions doc) is to layer in a privileged-roster
watchlist so we can also weight *who* did it.

## Source 1 - Entra ID directory (`AuditLogs`)

Almost everything in `AuditLogs` is a directory change, but some entries are
self-service (a user registering their own MFA, changing their own password). We
flag **privileged** when **either**:

- **Category** is in a high-impact set:
  `RoleManagement`, `ApplicationManagement`, `Policy`, `AuthorizationPolicy`,
  `DirectoryManagement`; **or**
- **`OperationName`** matches a curated list (`PrivAuditOps`), e.g. role
  assignment, app consent / delegated permission grant / credential add, service
  principal creation, user create / delete / restore / disable, password reset by
  admin, token-validity / strong-auth / BitLocker-key tampering, Conditional Access
  policy changes, federation / domain changes, privileged group membership changes.

**Self-service downgrade.** Several of these operations fire for both admin actions
*and* benign self-service (a user updating their own profile or changing their own
password). To avoid that noise, an action is **not** treated as privileged when the
actor and the target are the same identity, i.e.
`InitiatedBy.user.id == TargetResources[0].id`. This keeps admin-on-another-user
events while dropping self-service. Group-membership operations are an exception:
the target is a group, so the actor-vs-target test does not apply - they remain
flagged and are best gated on a privileged-group watchlist (see Tuning).

**Actor field:** `InitiatedBy.user.userPrincipalName` (id at `InitiatedBy.user.id`).
**Highest-impact examples:** "Add member to role", "Add app role assignment to
service principal", "Consent to application", "Add delegated permission grant",
"Update conditional access policy", "Update StsRefreshTokenValidFrom Timestamp",
"Disable Strong Authentication", "Read BitLocker key".

## Source 2 - Office 365 (`OfficeActivity`)

Privileged when **any** of:

- **`RecordType` contains `Admin`** (e.g. `ExchangeAdmin`) - these are admin
  surfaces by definition; **or**
- **`Operation`** is in a curated list (`PrivOfficeOps`), e.g. mailbox permission
  grants, inbox-rule creation (incl. the OWA/Graph `UpdateInboxRules` op, not just
  the cmdlets), transport / journal / remote-domain config, role-group and
  management-role changes, organisation config, eDiscovery / compliance search,
  anonymous / company sharing link creation, site collection admin additions; **or**
- **`Operation` matches an admin-cmdlet shape** -
  `(?i)^(add|set|new|remove|enable|disable|update|grant|reset)-` - which catches
  Exchange / SharePoint administrative cmdlets generically. The `(?i)` flag makes it
  case-insensitive so it does not depend on the source emitting PascalCase; `Get-`
  (read / recon) is deliberately excluded.

**Actor field:** `UserId`.
**Watch items of note:** `New-InboxRule` / `Set-InboxRule` / `UpdateInboxRules`
(auto-forwarding is a classic exfiltration / BEC signal), `Add-MailboxPermission`
(delegate access), `New-ComplianceSearch` / `Search-Mailbox` (insider data access),
sharing-link creation.

> **Limitation - mail forwarding.** `Set-Mailbox -ForwardingSmtpAddress` /
> `-DeliverToMailboxAndForward` is the classic exfiltration vector, but forwarding
> is a *parameter*, not a distinct `Operation`. `set-mailbox` flags the cmdlet, but
> to confirm forwarding you must inspect the `Details` (`Parameters`) column for
> `ForwardingSmtpAddress`.

## Source 3 - Azure control-plane (`AzureActivity`)

We keep only `CategoryValue == "Administrative"` (user / service-principal
control-plane changes; reads and platform noise are excluded). Within that:

- **Privileged** when the resolved action (`Authorization_d.action`, falling back
  to `OperationNameValue`) contains `/write`, `/delete`, or `/action` - i.e. it
  changes something rather than reading it; **or**
- the friendly `OperationNameValue` is on a small allowlist (`PrivAzureFriendlyOps`)
  of sensitive operations that do **not** contain a change verb in their friendly
  form (e.g. "List Storage Account Keys", "Initiate JIT Network Access Policy").
  This is the load-bearing fallback for when `Authorization_d.action` is empty.
- **High-impact** subset (`HighPrivAzure`) when the action touches
  `Microsoft.Authorization/roleAssignments` / `roleDefinitions` (RBAC),
  `roleEligibilityScheduleRequests` / `roleAssignmentScheduleRequests` (PIM via
  ARM), `elevateAccess`, `Microsoft.KeyVault`, `Microsoft.ManagedIdentity`, storage
  key enumeration (`/listKeys/action`), or App Service publish-profile theft
  (`Microsoft.Web/sites/publishxml`).

**Actor field:** `Caller` (a UPN for user-initiated actions; a GUID for service
principals - filter `Caller has "@"` if you want users only).

## Source 4 - Sign-ins (`SigninLogs`) - context only

Sign-ins are **authentication events, not actions**, so they are never flagged as
privileged activity and are not in the timeline. Query 04 instead marks
`MgmtSurface = Yes` when the sign-in targets admin tooling (`MgmtSurfaceApps`:
Azure Portal, Azure Resource Manager, Microsoft Graph / Graph PowerShell, Azure AD
PowerShell, Azure CLI, Exchange Online PowerShell, Intune, etc.). This is used to
explain *how* a privileged action was reached, not to assert that one happened.

## Known blind spots

These are inherent to the four supported tables, not bugs - state them when
presenting results:

- **Key Vault secret reads and Storage blob access are data-plane** and are **not**
  in `AzureActivity`. They require diagnostic logs (e.g. `AzureDiagnostics` /
  Key Vault audit, Storage diagnostic settings), which are out of scope here.
- **Mail forwarding** is a `Set-Mailbox` parameter, not a distinct operation - see
  the Office 365 limitation above.
- **PIM activations** log under the `ApplicationManagement` / `GroupManagement`
  categories, not `RoleManagement`; they are caught by the operation-name list
  (`add member to role`, `add eligible member to role`), not by category.
- **Service-principal-initiated Azure actions** carry a GUID in `Caller`, so a
  user-UPN lookup excludes them by design. Match the object id if you need SPN
  activity.

## Tuning

- Validate the lists against the tenant's **real** operations using query 02
  (counts per source + category) before relying on the flag operationally.
- Lists are intentionally broad first cuts. Tightening `PrivOfficeOps` /
  `PrivAuditOps` reduces false highlights; broadening them reduces misses.
- Keep query 01 (`IsPriv` expressions) and query 03 (`where` filters) in step with
  any change here and in `00-config`.
