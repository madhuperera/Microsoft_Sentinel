# Microsoft Sentinel Repository

Security detection and investigation assets for Microsoft Sentinel, organized by security domain.

## 📂 Repository Structure

The repository is organized by **security threat domain** for better discoverability and maintainability:

- **`detection-rules/`** - Scheduled alert rules (ARM templates deployed to Sentinel)
  - `identity-security/` - Azure AD authentication and privilege monitoring
  - Other security domains for email, office, devices

- **`investigations/`** - Ad-hoc KQL queries for incident analysis
  - Organized by **threat domain** AND **data source**
  - Covers identity, email, office, devices, billing, and more

- **`reference-data/`** - Watchlists and lookup tables
  - `emergency-breakglass-accounts/` - Emergency admin monitoring

- **`dashboards/`** - Sentinel workbooks and visualizations
  - `production/` - Live workbooks (PROD_*)
  - `development/` - Testing workbooks (DEV_*)

## 🚀 Quick Start

### Find a Detection Rule
Browse `detection-rules/{domain}/{threat}/` for scheduled alert rules ready to deploy to Sentinel.

### Run an Investigation Query
Browse `investigations/{domain}/` for KQL queries to run during incident investigation.

### View a Dashboard
See `dashboards/production/{domain}/` for interactive workbook visualizations.

## 📚 Documentation

- **`.github/copilot-instructions.md`** - AI agent guidance + codebase patterns
- **`detection-rules/README.md`** - Detection rule guide
- **`investigations/README.md`** - Investigation query guide
- **`dashboards/README.md`** - Workbook deployment
- **`reference-data/README.md`** - Watchlist management
- **`POST-MIGRATION-STRUCTURE.md`** - Complete directory structure

## 📊 Repository Contents

- **6 Detection Rules** - Scheduled alerts for threats
- **32 Investigation Queries** - KQL for analysis
- **1 Watchlist** - Emergency accounts reference data
- **8 Dashboards** - Production + development workbooks
- **7+ README Files** - Domain-specific documentation

## 💡 Key Concepts

**Detection Rules**: ARM templates with embedded KQL that run on a schedule and create incidents.

**Investigation Queries**: Reusable KQL for ad-hoc analysis during incidents.

**Watchlists**: CSV reference data used in rule/query conditions.

**Dashboards**: Sentinel workbooks with parameterized KQL visualizations.

# Microsoft Sentinel

Security detection and investigation assets for Microsoft Sentinel — organized by security domain for clarity and maintenance.

## Table of contents

- Repository structure
- Quick start
- Prerequisites & deploy examples
- Maintainers & support
- Notes on generated content
- Documentation and links
- License

## Repository structure

Top-level directories (high level):

- `detection-rules/` — Scheduled alert rules (ARM templates) organized by domain (e.g. `identity-security/`).
- `investigations/` — Reusable KQL queries for ad-hoc analysis, organized by domain and data source.
- `reference-data/` — Watchlists and lookup tables (each watchlist has its own folder and README).
- `dashboards/` — Sentinel workbooks, separated into `production/` and `development/`.

For the full, current tree and a snapshot of contents see `POST-MIGRATION-STRUCTURE.md`.

## Quick start

- Find detection rules: `detection-rules/{domain}/{threat}/`
- Run an investigation query: `investigations/{domain}/` (paste `.kql` into Sentinel Logs)
- View a dashboard: `dashboards/production/{domain}/`

## Prerequisites & deploy example

Minimum requirements for deploying templates and workbooks:

- Azure CLI (latest)
- Logged in: `az login`
- Permissions: Contributor on target resource group + appropriate Sentinel workspace permissions

Example: deploy an ARM template for a detection rule (PowerShell example):

```powershell
az deployment group create \
  --resource-group <rg-name> \
  --template-file detection-rules/identity-security/conditional-access/ca-changes-afterhours.json \
  --parameters workspace=/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<workspace-name>
```

Notes:

- Importing workbooks is easiest via the Azure portal (Sentinel → Workbooks → Add). CLI import support varies by extension/version.
- If you plan automation, standardize parameter values and use CI to validate templates before deployment.

## Maintainers & support

- Repo owner: GitHub user `madhuperera` (see repository settings for team/contacts).
- For questions or to request changes: open a GitHub Issue in this repository.
- To propose edits: create a branch and open a pull request; include test/deployment notes in the PR description.

If you want specific team contact details added here, tell me what to include.

## Notes on generated content

Some files in this repository were generated or assisted by language models. Treat these as drafts — review and test queries and templates before promoting to production. Examples of files to review first:

- `investigations/*` (many KQL files)
- `detection-rules/*` (ARM templates exported from workbooks)

See domain README files for more context and a note when a file was flagged as generated.

## Documentation and direct links

Key README files:

- `detection-rules/README.md` — detection rule guidance
- `detection-rules/identity-security/README.md` — identity security context
- `investigations/README.md` — using and authoring KQL queries
- `reference-data/README.md` — watchlist lifecycle and format
- `reference-data/emergency-breakglass-accounts/README.md` — emergency accounts watchlist
- `.github/copilot-instructions.md` — AI agent guidance and conventions

For a complete snapshot of directories and files, see `POST-MIGRATION-STRUCTURE.md`.

## License

See the `LICENSE` file in the repository root for licensing terms.

----

If you want, I can also:

- add a short table of contents with anchors, or
- include example automation scripts for CI-based deployment.
