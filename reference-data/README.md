# Reference Data (Watchlists)

Lookup tables and reference data used in detection rules and investigation queries.

## Included Watchlists

### Emergency Break Glass Accounts
- **File**: `emergency-breakglass-accounts/emergency-breakglass-accounts.csv`
- **Purpose**: Identify emergency admin accounts that should have restricted/monitored access
- **Used By**: 
  - `detection-rules/identity-security/privileged-accounts/emergency-breakglass-login.json`
  - `investigations/identity-security/privileged-accounts/privileged-account-logons.kql`

**Format**:
```csv
SearchKey,UserId,AccountName,CreatedDate
user@domain.com,xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx,Emergency Admin 1,2024-01-01
```

**Updating**:
1. Edit the `.csv` file in git
2. Upload to Sentinel Watchlist via Portal (Sentinel > Watchlists > Import)
3. Commit changes to git
4. Document the change reason in commit message

**Maintenance Schedule**: Quarterly after account reviews; immediately upon new account creation

---

## Using Watchlists in KQL

### Basic Lookup
```kusto
SigninLogs
| lookup kind=inner _GetWatchlist("EmergencyBreakGlassAccounts")
    on $left.UserId == $right.SearchKey
```

### With Filtering
```kusto
let EmergencyAccounts = _GetWatchlist("EmergencyBreakGlassAccounts")
| project SearchKey, AccountName;

SigninLogs
| where UserId in (EmergencyAccounts)
| summarize Count = count() by UserPrincipalName, AccountName
```

### Left Outer Join (Includes non-matches)
```kusto
SigninLogs
| lookup kind=leftouter _GetWatchlist("EmergencyBreakGlassAccounts")
    on $left.UserId == $right.SearchKey
| where isnotempty(AccountName)  // Only emergency accounts
```

---

## Planning Additional Watchlists

Based on your detection requirements, consider adding:

### 1. Office Locations (Recommended)
**Purpose**: Timezone-aware after-hours detection, trusted IP ranges
**Fields**: `LocationName`, `IPRanges`, `Timezone`, `BusinessHours`
**Used By**: Conditional Access rules, Sign-in anomaly rules

**Example**:
```csv
LocationName,IPRangeStart,IPRangeEnd,Timezone,OfficeOpenHour,OfficeCloseHour
Auckland HQ,192.0.2.0,192.0.2.255,Pacific/Auckland,7,18
Sydney Office,198.51.100.0,198.51.100.255,Australia/Sydney,7,18
```

### 2. Disabled Accounts (Optional)
**Purpose**: Exclude inactive accounts from alerting
**Fields**: `UserId`, `UserPrincipalName`, `DisableDate`

```csv
UserId,UserPrincipalName,DisableDate
xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx,user@domain.com,2024-06-01
```

### 3. Service Principals (Optional)
**Purpose**: Exclude app accounts from alerting
**Fields**: `AppId`, `AppName`, `Owner`, `Purpose`

```csv
AppId,AppName,Owner,Purpose
xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx,PowerAutomate-Integration,CloudOps,Business Process Automation
```

---

## Creating a New Watchlist

### Step 1: Prepare CSV File
- Headers: Column names (no spaces; use camelCase or snake_case)
- Rows: Data entries
- Encoding: UTF-8
- Max Size: 3.5 MB

### Step 2: Add to Git
```bash
mkdir -p reference-data/my-watchlist/
echo "SearchKey,Name,Value" > reference-data/my-watchlist/my-watchlist.csv
echo "key1,Name1,Value1" >> reference-data/my-watchlist/my-watchlist.csv
git add reference-data/my-watchlist/
git commit -m "feat: add my-watchlist reference data"
```

### Step 3: Create README
```bash
cat > reference-data/my-watchlist/README.md << 'EOF'
# My Watchlist

## Purpose
Brief description of what this watchlist is used for.

## Format
| SearchKey | Name | Value |
| --- | --- | --- |
| ... | ... | ... |

## Usage
- Detection rule: `detection-rules/.../rule.json`
- Investigation query: `investigations/.../query.kql`

## Maintenance
- Update frequency: Quarterly
- Owner: [Team Name]
EOF
```

### Step 4: Upload to Sentinel
1. Azure Portal > Microsoft Sentinel > Watchlists > Create new
2. Upload CSV file
3. Set "SearchKey" as lookup column
4. Save

### Step 5: Reference in Rules/Queries
```kusto
| lookup kind=inner _GetWatchlist("my-watchlist")
    on $left.UserId == $right.SearchKey
```

---

## Troubleshooting Watchlist Lookups

| Issue | Solution |
|-------|----------|
| Lookup returns no results | Verify SearchKey column name matches in lookup join condition |
| Watchlist name not found | Check exact spelling and capitalization in `_GetWatchlist("name")` |
| Missing rows | Verify CSV encoding is UTF-8; check for special characters |
| Size exceeds 3.5 MB | Split into multiple watchlists or archive old entries |

---

## See Also

- [Detection Rules](../detection-rules/) - Rules that use these watchlists
- [Investigation Queries](../investigations/) - Queries that use these watchlists
- [Watchlist Best Practices](https://learn.microsoft.com/en-us/azure/sentinel/watchlists)
- [CSV Format Specification](https://tools.ietf.org/html/rfc4180)
