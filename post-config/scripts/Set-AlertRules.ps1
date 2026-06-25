<#
.SYNOPSIS
    Creates Log Analytics scheduled-query alert rules that route to the
    central Action Group.

.DESCRIPTION
    Loads alert definitions from /post-config/alerts/*.json. Each file is
    a parameter object describing a single scheduledQueryRule. Variables
    in the queries (workspace ID, subscription ID) are substituted before
    submission.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $SubscriptionId,
    [Parameter(Mandatory)] [pscustomobject] $Outputs
)

. $PSScriptRoot/Common-Functions.ps1

Write-Step "Log Analytics alert rules"

$rg            = $Outputs.resourceGroupName
$location      = $Outputs.location
$lawId         = $Outputs.logAnalyticsId
$actionGroupId = $Outputs.actionGroupId

$alertsDir = Join-Path $PSScriptRoot '..\alerts'

foreach ($f in Get-ChildItem -Path $alertsDir -Filter '*.json') {
    $raw = Get-Content -Path $f.FullName -Raw
    $def = $raw `
        -replace '\$\{LOG_ANALYTICS_ID\}',  $lawId `
        -replace '\$\{ACTION_GROUP_ID\}',   $actionGroupId `
        -replace '\$\{SUBSCRIPTION_ID\}',   $SubscriptionId `
        -replace '\$\{LOCATION\}',          $location `
        | ConvertFrom-Json

    $ruleName = $def.name
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$rg/providers/Microsoft.Insights/scheduledQueryRules/${ruleName}?api-version=2023-03-15-preview"

    $body = $def.body | ConvertTo-Json -Depth 12
    $null = Invoke-AzApi -Method PUT -Uri $uri -JsonBody $body -AllowedStatusCodes @(200, 201)
    Write-Ok "alert rule: $ruleName"
}
