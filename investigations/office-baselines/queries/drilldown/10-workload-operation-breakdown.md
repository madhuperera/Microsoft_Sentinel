# 10 — Workload / operation breakdown + taxonomy validation

**Companion to:** `10-workload-operation-breakdown.kql`
**Type:** Review + taxonomy tuning
**Output:** per workload + operation — total events, distinct users, and the taxonomy classification

> Observable telemetry only. **Not** a productivity measure.

## What it answers

Two jobs in one:
1. **Drill-down** — which operations actually make up activity in a period, per
   workload.
2. **Taxonomy tuning** — every operation is tagged against the taxonomy
   (`EngagementSignal` Yes/No, or **`UNMAPPED`**), so you can check whether the
   meaningful/noise split still fits *this* tenant. This is the query you run to
   maintain `docs/activity-taxonomy.md` and the `MeaningfulOps` lists.

## Parameters

| Parameter | Default | Meaning |
|---|---|---|
| `LookbackPeriod` | `30d` | Window to summarise. |

## Step by step

1. **Parameters & exclusions** — `ServiceAccountUPNs` (`isfuzzy`), `ExcludedUPNs`.

2. **Inline `Taxonomy` datatable.** The **expanded (tuning) map** — operation →
   category → `EngagementSignal`, keyed on `Operation` only. Unlike the metric
   queries (which carry only the compact `MeaningfulOps` list), this query classifies
   *every* operation observed in the tenant so nothing lands in `UNMAPPED`.
   - The `EngagementSignal = Yes` rows are **exactly** the canonical meaningful set
     and must stay identical to `MeaningfulOps` / `00-config-and-shared-taxonomy.kql`.
   - Every other operation is given a category but `EngagementSignal = No` (currently
     excluded). Operations flagged `(candidate)` in the `.kql` comments
     (`Sharing-Collaboration`, comments, Teams message variants, call/meeting records)
     are plausible engagement signals a reviewer may choose to promote.
   - Category names are defined in `docs/activity-taxonomy.md` (source of truth).

3. **Filter & aggregate.** From `OfficeActivity` over `LookbackPeriod`:
   `UserType == "Regular"`, lowercase to `UPN`, **drop guests** (`#ext#`) and
   service/system accounts, then
   `summarize Events = count(), Users = dcount(UPN) by Workload, Operation`.
   - Note: this **does not** pre-filter to `MeaningfulOps` — the point is to see
     *all* operations, including ones not yet classified.

4. **Tag against the taxonomy.** `leftouter join Taxonomy on Operation`, then
   `coalesce(..., "UNMAPPED")` so any operation missing from the map is clearly
   labelled.

5. **Project & sort.** `order by toint(EngagementSignal == "UNMAPPED") desc, Events
   desc` — any **still-unmapped** operation floats to the top. With the expanded map
   this should now be rare; an `UNMAPPED` row means a genuinely new operation type has
   appeared in the tenant and needs classifying.

## How to use it for tuning

1. **New operations.** Any `UNMAPPED` rows at the top are operation types not yet in
   the map — classify each (pick the best-fit category, default `EngagementSignal =
   No`) and add it to the datatable.
2. **Promotion candidates.** Review the `No` rows whose category implies genuine human
   activity — `Sharing-Collaboration` (deliberate sharing), `Content-Collaboration`
   comments, the `Teams-Communication` message variants, and `Meetings`
   call/meeting records. Decide whether any volume justifies promoting to
   `EngagementSignal = Yes`.
3. **Demotion check.** Look at operations currently marked `Yes` with suspiciously high
   volume — possible sync/system contamination to demote.
4. Apply any `Yes`/`No` change **together** to: `docs/activity-taxonomy.md` (source of
   truth), this inline datatable, the `00-config-and-shared-taxonomy.kql` block, the
   `MeaningfulOps` lists in the metric queries, and the
   `reference-data/office-activity-taxonomy` CSV — so the canonical engagement set
   stays identical everywhere.

## Related

`activity-taxonomy.md` (the narrative + full table) · `00` (canonical taxonomy block)
· `09` (per-user raw events).
