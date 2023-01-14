# Security Group Change Monitoring

This Microsoft Sentinel Analytic rule monitors changes to security groups. It uses several dynamic lists to define which categories, group names, group name prefixes, and operations to monitor. 

## Variables
- `MonitoredCategories`: A list of categories to monitor. The default value is ["GroupManagement"].
- `MonitoredADGroupNames`: A list of group names to monitor. The default value is ["AdminAgents","HelpdeskAgents","SalesAgents"].
- `MonitoredADGroupNamePrefix`: A prefix for group names to monitor. The default value is "M365 GDAP".
- `MonitoredOperations`: A list of operations to monitor. The default value is ["Add member to group","Add owner to group","Update group","Remove member from group","Hard Delete group","Delete group","Remove owner from group"].
- `NumOfDays`: Number of days to check the logs for. The default value is 1 day.

## Output
The rule will output a table with the following columns:
- `TimeGenerated`: The time the event was generated.
- `OperationName`: The name of the operation performed.
- `TargetedGroupName`: The name of the targeted group.
- `ActivityDisplayName`: The display name of the activity.

The rule will sort the output by `TimeGenerated` in descending order.

## Note
This script is intended to be used with Microsoft Sentinel.