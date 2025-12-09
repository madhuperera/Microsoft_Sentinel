#!/usr/bin/env pwsh
<#
.SYNOPSIS
Reorganize Microsoft Sentinel repository from artifact-type structure to domain-based structure.

.DESCRIPTION
Migrates files from:
  - Analytics/ → detection-rules/{domain}/{threat}/
  - KQL/ → investigations/{domain}/
  - Watchlists/ → reference-data/{watchlist-name}/
  - Workbooks/ → dashboards/{prod|dev}/{domain}/

Uses 'git mv' to preserve git history. Run from repository root.

.EXAMPLE
./migrate-to-domain-structure.ps1 -DryRun
./migrate-to-domain-structure.ps1 -Verbose

.NOTES
- Requires git to be available in PATH
- Run from Microsoft_Sentinel repository root
- DryRun shows what would move without executing
#>

param(
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = 'Stop'

# Mapping: source path -> (destination path, new name)
$migrations = @(
    # ============ DETECTION RULES (Analytics/Templates) ============
    @{ src = "Analytics/Templates/SOC-High-ConditionalAccessChanges-AfterHours.json"; dest = "detection-rules/identity-security/conditional-access/"; name = "ca-changes-afterhours.json" }
    @{ src = "Analytics/Templates/SOC-High-ConditionalAccessExclusionGroupUpdates.json"; dest = "detection-rules/identity-security/conditional-access/"; name = "ca-exclusion-updates.json" }
    @{ src = "Analytics/Templates/SOC-High-PrivilegedAccess-EmergencyBreakGlassAccounts.json"; dest = "detection-rules/identity-security/privileged-accounts/"; name = "emergency-breakglass-login.json" }
    @{ src = "Analytics/Templates/SOC-Medium-PrivilegedAccess-ProtectedUserTampering.json"; dest = "detection-rules/identity-security/privileged-accounts/"; name = "protected-user-tampering.json" }
    @{ src = "Analytics/Templates/SOC-Low-UnauthorizedAccess-TemporaryAccessPassMonitoingByAdmin.json"; dest = "detection-rules/identity-security/unauthorized-access/"; name = "temp-access-pass-monitoring.json" }
    @{ src = "Analytics/Templates/SOC-Medium-UnmanagedDeviceRegistrationByStaffAccount.json"; dest = "detection-rules/identity-security/unauthorized-access/"; name = "unmanaged-device-registration.json" }

    # ============ INVESTIGATIONS (KQL queries) ============
    # Email-related queries
    @{ src = "Analytics/MonitorEmailAttachmentLeaks.kql"; dest = "investigations/email-security/attachment-controls/"; name = "attachment-leak-external.kql" }
    @{ src = "Analytics/MonitorEmailAttachmentLeaksToPersonalDomains.kql"; dest = "investigations/email-security/attachment-controls/"; name = "attachment-leak-personal-domains.kql" }
    @{ src = "Analytics/MonitoringAttachments.kql"; dest = "investigations/email-security/attachment-controls/"; name = "monitoring-attachments.kql" }
    @{ src = "KQL/EmailActivities/EmailAttachmentCountPerDay.kql"; dest = "investigations/email-security/"; name = "email-attachment-count-per-day.kql" }
    @{ src = "KQL/EmailActivities/EmailAttachmentsCountPerDomain.kql"; dest = "investigations/email-security/"; name = "email-attachments-count-per-domain.kql" }

    # Identity-related queries
    @{ src = "Analytics/MonitorPrivilegedAccountLogons.kql"; dest = "investigations/identity-security/privileged-accounts/"; name = "privileged-account-logons.kql" }
    @{ src = "Analytics/MonitorChangesToUsersSecurityRegistrationDetails.kql"; dest = "investigations/identity-security/"; name = "security-registration-changes.kql" }
    @{ src = "Analytics/MonitorPasswordCrackingAttempts.kql"; dest = "investigations/identity-security/"; name = "password-cracking-attempts.kql" }
    @{ src = "KQL/SignInLogs/CAPolicyImpact.kql"; dest = "investigations/identity-security/conditional-access/"; name = "ca-policy-impact.kql" }
    @{ src = "KQL/SignInLogs/PhishingResistanceLogins.kql"; dest = "investigations/identity-security/"; name = "phishing-resistance-logins.kql" }
    @{ src = "KQL/SignInLogs/UntrustedIPsWithUserCounts.kql"; dest = "investigations/identity-security/sign-in-analysis/"; name = "untrusted-ips-user-counts.kql" }

    # Device-related queries
    @{ src = "Analytics/MonitoringDeviceRegistrations.kql"; dest = "investigations/device-security/"; name = "device-registrations.kql" }
    @{ src = "KQL/DeviceActivities/DeviceLogonReport.kql"; dest = "investigations/device-security/"; name = "device-logon-report.kql" }
    @{ src = "KQL/DeviceActivities/FileActivityReport.kql"; dest = "investigations/device-security/"; name = "file-activity-report.kql" }

    # Office/Intune-related queries
    @{ src = "Analytics/Anomalies/UnusualOfficeActivities.kql"; dest = "investigations/office-anomalies/"; name = "unusual-office-activities-baseline.kql" }
    @{ src = "Analytics/Anomalies/UnusualOfficeActivitiesExtended.kql"; dest = "investigations/office-anomalies/"; name = "unusual-office-activities-extended.kql" }
    @{ src = "Analytics/Anomalies/UnusualOfficeActivities_Graph.kql"; dest = "investigations/office-anomalies/"; name = "unusual-office-activities-graph.kql" }
    @{ src = "KQL/Office_Activities/AreachartByPossiblePasswordCrackingAttempts.kql"; dest = "investigations/office-anomalies/"; name = "password-cracking-attempts-chart.kql" }
    @{ src = "KQL/Office_Activities/PieChartByAnonymousAccessPerStaffMember.kql"; dest = "investigations/office-anomalies/"; name = "anonymous-access-by-staff.kql" }
    @{ src = "KQL/Office_Activities/PieChartByGuestSharingAccessPerStaffMember.kql"; dest = "investigations/office-anomalies/"; name = "guest-sharing-by-staff.kql" }
    @{ src = "KQL/Intune/AndroidDevices.kql"; dest = "investigations/device-security/intune/"; name = "android-devices.kql" }

    # Security group-related queries
    @{ src = "Analytics/Monitor Security Groups/MonitorChangesToSecurityGroup.kql"; dest = "investigations/identity-security/security-groups/"; name = "monitor-security-group-changes.kql" }
    @{ src = "Analytics/KeeperSecurity/PolicyChanges.kql"; dest = "investigations/keeper-security/"; name = "policy-changes.kql" }

    # Billing/Guest/other queries
    @{ src = "KQL/Billing/AreaChartForBilledDataOverTime.kql"; dest = "investigations/billing-analysis/"; name = "billed-data-over-time.kql" }
    @{ src = "KQL/Billing/BilledDataByComputer.kql"; dest = "investigations/billing-analysis/"; name = "billed-data-by-computer.kql" }
    @{ src = "KQL/Billing/BilledDataByTable.kql"; dest = "investigations/billing-analysis/"; name = "billed-data-by-table.kql" }
    @{ src = "KQL/Guests/GuestReport.kql"; dest = "investigations/guest-access/"; name = "guest-report.kql" }

    # Concepts folder
    @{ src = "KQL/Concepts/MonitorPrivilegedAccountsUsingTimeZones.kql"; dest = "investigations/concepts/"; name = "timezone-conversions.kql" }

    # ============ REFERENCE DATA (Watchlists) ============
    @{ src = "Watchlists/EmergencyBreakGlassAccounts.csv"; dest = "reference-data/emergency-breakglass-accounts/"; name = "emergency-breakglass-accounts.csv" }

    # ============ DASHBOARDS (Workbooks) ============
    # Development dashboards
    @{ src = "Workbooks/DEV_ConditionalAccessPolicyImpact.json"; dest = "dashboards/development/conditional-access/"; name = "DEV_ConditionalAccessPolicyImpact.json" }
    @{ src = "Workbooks/DEV_InsiderThreats.json"; dest = "dashboards/development/insider-threats/"; name = "DEV_InsiderThreats.json" }
    @{ src = "Workbooks/Essential8/DEV_SOC-Essential-8.json"; dest = "dashboards/development/essential8/"; name = "DEV_SOC-Essential-8.json" }
    @{ src = "Workbooks/SOC-SharePointAccess/SOC-SharePointAccess-DEV.json"; dest = "dashboards/development/sharepoint-access/"; name = "DEV_SharePointAccess.json" }

    # Production dashboards
    @{ src = "Workbooks/PROD_InsiderThreats.json"; dest = "dashboards/production/insider-threats/"; name = "PROD_InsiderThreats.json" }
    @{ src = "Workbooks/Essential8/PROD_SOC-Essential-8.json"; dest = "dashboards/production/essential8/"; name = "PROD_SOC-Essential-8.json" }
    @{ src = "Workbooks/SOC-SharePointAccess/SOC-SharePointAccess-PRO.json"; dest = "dashboards/production/sharepoint-access/"; name = "PROD_SharePointAccess.json" }
    @{ src = "Workbooks/SOC-IntuneDevices/PROD_SOC-IntuneDevices.kql"; dest = "dashboards/production/intune-devices/"; name = "PROD_SOC-IntuneDevices.kql" }

    # Supporting queries for Essential8
    @{ src = "Workbooks/Essential8/Queries/InactiveLogins.kql"; dest = "investigations/identity-security/inactive-logins/"; name = "inactive-logins.kql" }
    @{ src = "Workbooks/Essential8/Queries/InactiveLogins_UBEA.kql"; dest = "investigations/identity-security/inactive-logins/"; name = "inactive-logins-ubea.kql" }
    @{ src = "Workbooks/Essential8/Queries/InactiveLogins_Extended.kql"; dest = "investigations/identity-security/inactive-logins/"; name = "inactive-logins-extended.kql" }
    @{ src = "Workbooks/Essential8/Queries/OldFileFormats.kql"; dest = "investigations/office-anomalies/"; name = "old-file-formats.kql" }

    # Documentation files
    @{ src = "Analytics/Monitor Security Groups/README.md"; dest = "investigations/identity-security/security-groups/"; name = "README.md" }
)

function Test-GitRepo {
    if (-not (Test-Path ".git")) {
        Write-Error "Not in a git repository root. Please run from Microsoft_Sentinel directory."
        exit 1
    }
}

function Ensure-Directory {
    param([string]$path)
    
    $fullPath = Join-Path (Get-Location) $path
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        if ($Verbose) { Write-Host "Created directory: $path" -ForegroundColor Green }
    }
}

function Invoke-GitMove {
    param(
        [string]$source,
        [string]$dest,
        [string]$newName
    )
    
    $destPath = Join-Path $dest $newName
    
    if ($DryRun) {
        Write-Host "WOULD MOVE: $source → $destPath" -ForegroundColor Cyan
    } else {
        git mv $source $destPath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Moved: $source → $destPath" -ForegroundColor Green
        } else {
            Write-Error "Failed to move $source"
            exit 1
        }
    }
}

# Main execution
Write-Host "Microsoft Sentinel Repository Migration" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
}

Test-GitRepo

# Create all destination directories
Write-Host "`nCreating destination directories..." -ForegroundColor Cyan
$uniqueDirs = $migrations | ForEach-Object { $_.dest } | Select-Object -Unique
foreach ($dir in $uniqueDirs) {
    Ensure-Directory $dir
}

# Create docs directory
Ensure-Directory "docs"

# Move files
Write-Host "`nMigrating files..." -ForegroundColor Cyan
$migrations | ForEach-Object {
    Invoke-GitMove -source $_.src -dest $_.dest -newName $_.name
}

Write-Host "`nMigration complete!" -ForegroundColor Green

if ($DryRun) {
    Write-Host "`nTo execute the migration, run:" -ForegroundColor Yellow
    Write-Host "  ./migrate-to-domain-structure.ps1 -Verbose" -ForegroundColor White
} else {
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "  1. Review changes: git status" -ForegroundColor White
    Write-Host "  2. Verify structure: tree -d detection-rules investigations reference-data dashboards" -ForegroundColor White
    Write-Host "  3. Commit changes: git commit -m 'refactor: reorganize repository structure by security domain'" -ForegroundColor White
    Write-Host "  4. Add domain README files" -ForegroundColor White
}
