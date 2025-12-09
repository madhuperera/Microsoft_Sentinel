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

## 🔄 Recent Restructuring

December 2025: Repository reorganized from artifact-type (Analytics/, KQL/, Workbooks/) to domain-based organization.
See `MIGRATION_COMPLETE.md` for details.

## 📝 License

See `LICENSE` file
