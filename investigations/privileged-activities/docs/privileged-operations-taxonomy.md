# Activity classification taxonomy

How each action is given an **`ActivityClass`** and a **`Severity`**, per source.
This replaces the earlier binary "privileged yes/no" flag, which wrongly merged
three different things: confirmed administrative actions, high-risk user / data
exposure actions, and management-surface sign-in context. The canonical signal
lists live in
[`../queries/00-config-and-shared-taxonomy.kql`](../queries/00-config-and-shared-taxonomy.kql);
this document explains the reasoning so another consultant can review and tune it.

> Observable telemetry only. A classified action is a prompt to review, never proof
> of misconduct. See [`assumptions-and-limitations.md`](assumptions-and-limitations.md).

## Classification model

Each row is assigned one `ActivityClass`:

| ActivityClass | Base severity | Meaning |
|---|---|---|
| Privileged role/RBAC change | High | Directory / Exchange / Azure role or RBAC assignment changes. |
| Privileged policy/security config change | High | Conditional Access, auth-method / security-defaults / domain / federation / cross-tenant policy, Exchange security config. |
| App/consent/service principal change | High | App consent, delegated/app permission grants, SP creation, credential adds. |
| High-impact Azure control-plane change | High | RBAC/PIM, Key Vault, identity, logging/security tampering, compute execution, automation, network controls, key enumeration. |
| User/group/identity admin change | Medium | User lifecycle / credential admin performed on **another** user. |
| Azure control-plane change | Medium | Any other `Administrative` write / delete / action. |
| High-risk sharing/data exposure | Medium | Anonymous / company / secure links, sharing invites, eDiscovery / mailbox search. |
| Requires manual review | Medium | Context-dependent (e.g. group membership - privileged only if the group is). |
| Possible admin activity (review) | Low | Low-confidence: matched the admin-cmdlet shape or the secondary category net only. |
| Management-surface sign-in | Info | Sign-in to admin tooling (query 04). Context, **not** an action. |
| Normal user activity | Info | Everything else, incl. self-service. Kept in the timeline. |

**Severity = base severity of the class, then a failed attempt is downgraded one
level** (High to Medium, Medium to Low) so successful changes always rank above
failed attempts while failures stay visible. `Outcome` (Success / Failure / Other)
is derived from each source's result field.

> Severity does not yet incorporate the **target object** (which user, which group,
> which resource) or **scope**, because the three tables carry no privileged-roster
> or group-purpose feed. That is the main planned refinement (watchlist). See
> Tuning.

## Guiding principle: classify the action, not the person

These tables do not give a reliable, current list of who holds which role, so we do
not label a user "an admin". We classify each action by what it is. A future
privileged-roster / privileged-group watchlist would let us also weight *who* acted
and sharpen the `Requires manual review` and group cases.

## Source 1 - Entra ID (`AuditLogs`) - operation-name primary

**Important schema note.** Microsoft's `AuditLogs` table reference documents the
`Category` column as effectively a fixed value (`"Audit"`) in Log Analytics, and
the activity-to-category mapping is inconsistent anyway (PIM activations log under
`ApplicationManagement` / `GroupManagement`, not `RoleManagement`; credential /
MFA / token operations log under `UserManagement`). **So classification is driven
by `OperationName`** (the activity display name, which is stable and documented),
matched case-insensitively as a substring against curated lists:

- `EntraRoleOps` -> **Privileged role/RBAC change** (role assignment, eligible-role,
  role-definition changes, PIM activation, elevate access).
- `EntraAppOps` -> **App/consent/service principal change** (consent, delegated /
  app-role permission grants, SP creation, credential / secret adds, owners).
- `EntraPolicyOps` -> **Privileged policy/security config change** (Conditional
  Access, authorization / auth-method / auth-strength policy, security defaults,
  domain / federation, cross-tenant access, `Disable Strong Authentication`,
  `Update StsRefreshTokenValidFrom`, `Read BitLocker key`).
- `EntraIdentityOps` -> **User/group/identity admin change**, but only when **not
  self-service**. Self-service is `InitiatedBy.user.id == TargetResources[0].id`
  (a user acting on their own object, e.g. own password change); those drop to
  **Normal user activity**.
- `EntraReviewOps` (group lifecycle / membership) -> **Requires manual review** -
  privileged only if the group is privileged, which we cannot tell from these logs.
- A row that matches none of the lists but whose `Category` is in the secondary net
  (`RoleManagement` etc.) -> **Possible admin activity (review)** (low confidence;
  depends on `Category` being populated, which must be tenant-validated).

**Actor:** `InitiatedBy.user.userPrincipalName` (id at `InitiatedBy.user.id`).

## Source 2 - Office 365 (`OfficeActivity`)

- `OfficeRoleOps` -> **Privileged role/RBAC change** (role group / management role
  membership, site collection admin add).
- `OfficeSecurityCfgOps` -> **Privileged policy/security config change** (mailbox /
  recipient / folder permissions, inbox / transport rules, connectors, remote
  domain, journal, CAS mailbox, org config, DLP / retention policy).
- `OfficeExposureOps` -> **High-risk sharing/data exposure** (anonymous / company /
  secure links, sharing invitations, `SharingSet`, eDiscovery / compliance search,
  `Search-Mailbox`).
- Otherwise, an **admin record type** (`RecordType has "Admin"`) **or** the
  case-insensitive admin-cmdlet shape `(?i)^(add|set|new|...)-` ->
  **Possible admin activity (review)**. This is deliberately *low confidence*: the
  cmdlet shape is an indicator of possible admin activity, not a confirmed
  privileged action.
- Everything else -> **Normal user activity** (kept in the timeline).

**Actor:** `UserId`.

> **Limitation - mail forwarding.** `Set-Mailbox -ForwardingSmtpAddress` /
> `-DeliverToMailboxAndForward` is the classic exfiltration vector, but forwarding
> is a *parameter*, not a distinct `Operation`. `set-mailbox` is classed as a
> security config change, but to confirm forwarding you must inspect the `Details`
> (`Parameters`) column for `ForwardingSmtpAddress`.

## Source 3 - Azure control-plane (`AzureActivity`)

Restricted to `CategoryValue == "Administrative"`. The resolved action is
`Authorization_d.action`, falling back to `OperationNameValue` when empty.

- Action matches `HighPrivAzure`, **or** the friendly `OperationNameValue` is in
  `PrivAzureFriendlyOps` -> **High-impact Azure control-plane change**. This list
  covers RBAC / PIM-via-ARM, Key Vault, managed identity, diagnostic-settings
  changes (log tampering), security / Sentinel, Log Analytics workspaces, VM
  extensions and run-command (code execution), automation accounts, NSG / route
  table / firewall / private endpoint, management-group scope, and storage key
  enumeration / App Service publish profiles.
- Otherwise, a change verb (`/write`, `/delete`, `/action`) **or** a friendly
  sensitive op -> **Azure control-plane change**.
- Otherwise -> **Normal user activity**.

**Actor:** `Caller` (a UPN for user-initiated actions; a GUID for service
principals - a user-UPN lookup naturally excludes those).

**Control-plane only.** `AzureActivity` records configuration changes, not
data-plane access. It may show a Key Vault or storage **configuration** change but
will not show every secret read or blob read - see Known blind spots.

## Source 4 - Sign-ins (`SigninLogs`) - context only

Sign-ins are authentication events, not actions, and never carry an action
`ActivityClass`. Query 04 marks `MgmtSurface = Yes` when the sign-in targets admin
tooling (`MgmtSurfaceApps`) and sets `ActivityClass = "Management-surface sign-in"`
with `Severity = Info`. This is administrative-access context to correlate with
real actions in 01 / 03, not evidence that an action occurred.

## Known blind spots

Inherent to the four supported tables - state them when presenting results:

- **Key Vault secret reads and Storage blob access are data-plane** and are not in
  `AzureActivity` (they need resource diagnostic logs).
- **Mail forwarding** is a `Set-Mailbox` parameter, not a distinct operation.
- **PIM activations** log under `ApplicationManagement` / `GroupManagement`, not
  `RoleManagement` - caught by operation name, not category.
- **Service-principal-initiated Azure actions** carry a GUID in `Caller`, so a
  user-UPN lookup excludes them by design.
- **Group / target context** is unavailable, so group membership and generic
  identity changes are `Requires manual review` rather than confirmed-privileged.

## Tuning

- Validate the lists - especially the Entra `Category` secondary net - against the
  tenant's **real** operations using query 02 before relying on them operationally.
- The single biggest precision win is a **privileged-roster / privileged-group
  watchlist**: it would let `Requires manual review` and `User/group/identity admin
  change` be promoted to confirmed-privileged based on the target, and let severity
  reflect *who* / *what* was targeted.
- Keep the per-source `case()` expressions in queries 01 / 02 / 03 in step with any
  change here and in `00-config`.
