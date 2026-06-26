# Panel descriptions (source of truth)

Each `NN.md` file is the text shown for the matching panel of the combined workbook
(`DEV_OfficeBaselines-AllQueries_vN.json`). These files are the source of truth: edit
them here, then ask for the workbook to be rebuilt and the new version will contain this
text verbatim.

> **From v8, each file is split into two workbook items:**
> - **line 1** (the `### NN. ...` heading) becomes the panel's **always-visible title**
>   (`title-NN`) - it is never hidden by the Show/Hide toggle;
> - **the rest** becomes the **collapsible description** (`desc-NN`), controlled by the
>   panel's Description pill.
>
> So keep the heading on line 1, then a blank line, then the body. Do not add a second
> top-level heading.

## Mapping

| File | Workbook panel | Query | Section |
|---|---|---|---|
| `01.md` | `desc-01` | `query-01` user vs own baseline (summary) | 1 |
| `02.md` | `desc-02` | `query-02` baseline by workload | 1 |
| `03.md` | `desc-03` | `query-03` activity trend | 1 |
| `04.md` | `desc-04` | `query-04` sign-in active days | 1 |
| `05.md` | `desc-05` | `query-05` flagged for review | 1 |
| `06.md` | `desc-06` | `query-06` org baseline per workload | 2 |
| `07.md` | `desc-07` | `query-07` user vs org | 2 |
| `08.md` | `desc-08` | `query-08` org trend | 2 |
| `11.md` | `desc-11` | `query-11` user vs org trend | 2 |
| `09.md` | `desc-09` | `query-09` user event drill-down | 3 |
| `10.md` | `desc-10` | `query-10` operation / taxonomy breakdown | 3 |

## How to edit

- Write normal **Markdown**. The workbook renders it (bold, italics, lists, emoji).
- You can use workbook **parameter tokens**, for example `{W_TimeRange:label}`,
  `{W_NormalBandPct}`, `{W_OutlierZ}`. They are substituted live when the workbook runs.
- Keep it **plain-English for a non-technical audience**. Avoid statistics jargon in the
  visible text.
- Do not use em or en dashes; use a normal hyphen or rephrase.

## How a sync happens

When you ask to update the workbook to match these files, a new workbook version is
produced (`..._vN+1.json`) by reading every `NN.md` and writing it into the matching
`desc-NN` panel. The build script lives in the git-ignored `dev-scratch/` folder
(`build-workbook-vN.ps1`). The workbook is never hand-edited for description text; these
files drive it.
