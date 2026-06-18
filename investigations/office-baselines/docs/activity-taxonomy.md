# Activity Taxonomy — `OfficeActivity`

`OfficeActivity` (the Microsoft 365 Unified Audit Log) contains hundreds of
operation types. Counting all of them is misleading: many are background, system,
sync, read-only, or administrative events that don't reflect a person doing
knowledge work. This taxonomy separates **meaningful** operations from **noise** so
the metrics in `docs/methodology.md` are built on a defensible subset.

> This is a **starting point, designed to be reviewed and adjusted.** Operation
> names and volumes vary by tenant licensing, audit configuration, and workload
> usage. Validate against your tenant with
> `queries/drilldown/10-workload-operation-breakdown.kql` and tune.

## How it is used

- Metric queries count **only** operations marked `EngagementSignal = Yes`.
- The canonical machine-readable copy lives in two places that must stay in sync:
  - inline `datatable` in `queries/00-config-and-shared-taxonomy.kql` (and a
    compact `MeaningfulOps` list embedded in each metric query), and
  - the future watchlist CSV in
    `reference-data/office-activity-taxonomy/office-activity-taxonomy.csv`.
- `EngagementSignal = No` rows are documented on purpose, so reviewers can see what
  was *deliberately excluded* and why — not just what was kept.

## Categories

| Category | Counts as engagement? | Description |
|---|---|---|
| `Email-Communication` | ✅ Yes | A person sending mail. |
| `Content-Authoring` | ✅ Yes | Creating/editing/checking-in files. |
| `Content-Collaboration` | ✅ Yes | Interactive viewing, sharing, downloading by a person. |
| `Teams-Communication` | ✅ Yes | Chat/channel messages by a person. |
| `Meetings` | ✅ Yes | Joining/participating in meetings. |
| `Sharing-Collaboration` | ❌ No¹ | Deliberate sharing actions — creating/updating sharing, company and secure links and grants. Currently excluded; **promotion candidate**. |
| `Content-Management` | ❌ No | Folder/list structure changes and file housekeeping (create/rename/move folders, list & column edits, thumbnails, copies, checkouts). |
| `Content-Lifecycle` | ❌ No | Delete / recycle / restore of files, list items and mail (move-to-deleted, soft/hard delete). Ambiguous cleanup, not authored work. |
| `Mailbox-Activity` | ❌ No | Background-heavy mailbox modifications (Exchange `Update`: flagging, moving, property changes). |
| `Read-Access` | ❌ No | Passive access/preview, link & token use, read receipts; heavily background and easily inflated. |
| `Background-Sync` | ❌ No | OneDrive/SharePoint sync client and system-generated uploads (`*Extended`, partial, recording uploads). |
| `Administrative` | ❌ No | Admin/config, permissions, membership, site & app management — not staff engagement. |
| `Search` | ❌ No | Search queries — noisy, weak signal. |
| `Security-Signal` | ❌ No | Sessions, sign-ins and security-posture events — tracked elsewhere, not engagement. |

¹ Some categories carry `EngagementSignal = No` rows that *could* reflect human work
(`Sharing-Collaboration`, comments under `Content-Collaboration`, the
`Teams-Communication` message variants, call/meeting records under `Meetings`). These
are deliberately left **excluded by default** but called out as **promotion candidates**
during tuning — see the expanded map in
`queries/drilldown/10-workload-operation-breakdown.kql`.

## Meaningful operations (`EngagementSignal = Yes`)

| Workload | Operation | Category | Rationale / caveat |
|---|---|---|---|
| Exchange | `Send` | Email-Communication | User sent a message. Strong human signal. |
| Exchange | `SendAs` | Email-Communication | Sent as another mailbox (delegate). |
| Exchange | `SendOnBehalf` | Email-Communication | Sent on behalf of another mailbox. |
| SharePoint | `FileUploaded` | Content-Authoring | New content added. |
| SharePoint | `FileModified` | Content-Authoring | Edit. *Caveat:* can also be sync-driven — keep under review. |
| SharePoint | `FileCheckedIn` | Content-Authoring | Deliberate save of a versioned doc. |
| SharePoint | `FileRenamed` | Content-Authoring | Deliberate file management. |
| SharePoint | `FileMoved` | Content-Authoring | Deliberate file management. |
| SharePoint | `FileDownloaded` | Content-Collaboration | Person retrieving content. *Caveat:* also a security signal; can be sync-driven. |
| SharePoint | `ClientViewSignaled` | Content-Collaboration | Interactive page/doc view (client-confirmed). |
| SharePoint | `PageViewed` | Content-Collaboration | Interactive page view. |
| MicrosoftTeams | `MessageSent` | Teams-Communication | Chat/channel message sent. |
| MicrosoftTeams | `MessageEdited` | Teams-Communication | Edited an existing message. |
| MicrosoftTeams | `ChatCreated` | Teams-Communication | Started a chat. |
| MicrosoftTeams | `TeamCreated` | Teams-Communication | Created a team (collaboration setup). |
| MicrosoftTeams | `ChannelAdded` | Teams-Communication | Added a channel. |
| MicrosoftTeams | `MeetingParticipantDetail` | Meetings | Participated in a meeting. |

## Deliberately excluded operations (`EngagementSignal = No`)

These are documented so the exclusions are reviewable; they are **not** counted.

| Workload | Operation | Category | Why excluded |
|---|---|---|---|
| SharePoint | `FileAccessed` | Read-Access | Extremely high volume; triggered by preview/sync, not just people. |
| SharePoint | `FilePreviewed` | Read-Access | Often automatic thumbnail/preview generation. |
| SharePoint | `FileSyncDownloadedFull` | Background-Sync | OneDrive sync client, not a person. |
| SharePoint | `FileSyncUploadedFull` | Background-Sync | OneDrive sync client, not a person. |
| SharePoint | `FileSyncDownloadedPartial` | Background-Sync | OneDrive sync client, not a person. |
| Exchange | `MailItemsAccessed` | Read-Access | Background/sync heavy; poor engagement signal and privacy-sensitive. |
| Exchange | `Create` | Read-Access | Ambiguous (drafts/calendar internals); excluded pending validation. |
| MicrosoftTeams | `MessagesListed` | Read-Access | Reading message lists, background. |
| AzureActiveDirectory | `UserLoggedIn` | Security-Signal | Sign-ins are measured from `SigninLogs`; avoids double counting. |
| Exchange | `New-InboxRule` / `Set-*` / `Add-*` | Administrative | Admin/config or security signal, not engagement. |
| (any) | `SearchQueryPerformed` | Search | Noisy, weak engagement signal. |

The table above is the **curated** short-list — the highest-volume / most important
exclusions. The **exhaustive observed map** (every operation seen in the tenant, each
assigned one of the categories above) is maintained inline in
`queries/drilldown/10-workload-operation-breakdown.kql`. That query exists precisely to
keep nothing `UNMAPPED`; it is the working surface for tuning, while this file remains
the definition of the **categories** and the canonical `Yes` set. Representative
additions classified there:

| Category | Example operations (all `EngagementSignal = No`) |
|---|---|
| `Mailbox-Activity` | `Update` |
| `Background-Sync` | `FileModifiedExtended`, `FileUploadedPartial`, `TeamsMeetingRecordingUploaded` |
| `Read-Access` | `FileAccessedExtended`, `AttachmentAccess`, `ListViewed`, `PagePrefetched`, `SharingLinkUsed`, `CompanyLinkUsed`, `SecureLinkUsed`, `MessageReadReceiptReceived` |
| `Content-Lifecycle` | `MoveToDeletedItems`, `SoftDelete`, `HardDelete`, `FileRecycled`, `ListItemDeleted`, `ListItemRestored` |
| `Content-Management` | `FolderCreated`/`Renamed`/`Moved`, `FileCopied`, `FileCheckedOut`, `List*` create/update/column changes |
| `Sharing-Collaboration` *(candidate)* | `SharingSet`, `SharingLinkCreated`, `CompanyLinkCreated`, `SecureLinkCreated`, `AddedToSharingLink` |
| `Content-Collaboration` *(candidate)* | `CommentCreated`, `CommentEdit` |
| `Teams-Communication` *(candidate)* | `MessageCreatedHasLink`, `MessageEditedHasLink`, `MessageUpdated`, `ReactedToMessage` |
| `Meetings` *(candidate)* | `CallParticipantDetail`, `MeetingDetail` |
| `Security-Signal` | `TeamsSessionStarted`, `SignInEvent`, `BaselineSecurityModeThirdPartyAppHPA` |
| `Administrative` | group/permission/membership changes, `Tab*`/`App*`, `SiteCollection*`, `Sharing(Inheritance)Broken`/`Revoked` |

## Tuning workflow

1. Run `queries/drilldown/10-workload-operation-breakdown.kql` for your tenant.
2. Look at the highest-volume operations **not** currently marked meaningful — decide
   if any genuinely reflect human work.
3. Look at meaningful operations with suspiciously high volume (possible sync/system
   contamination) and consider demoting them.
4. Update the inline taxonomy in `00-config-and-shared-taxonomy.kql`, the
   `MeaningfulOps` lists in the metric queries, the watchlist CSV, and this file
   **together**.
