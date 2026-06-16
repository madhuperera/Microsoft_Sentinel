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

2. **Inline `Taxonomy` datatable.** A local copy of the operation → category →
   `EngagementSignal` map (keyed on `Operation` only). *Keep this in sync with
   `docs/activity-taxonomy.md` and `00-config-and-shared-taxonomy.kql`.*

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
   desc` — **unmapped, high-volume operations float to the top**, because those are
   the tuning candidates.

## How to use it for tuning

1. Look at the top rows: high-volume `UNMAPPED` operations — decide if any genuinely
   reflect human work and should become `EngagementSignal = Yes`.
2. Look at operations currently marked `Yes` with suspiciously high volume — possible
   sync/system contamination to demote.
3. Apply changes **together** to: `docs/activity-taxonomy.md` (source of truth), this
   inline datatable, the `MeaningfulOps` lists in the metric queries, and the
   `reference-data/office-activity-taxonomy` CSV.

## Related

`activity-taxonomy.md` (the narrative + full table) · `00` (canonical taxonomy block)
· `09` (per-user raw events).
