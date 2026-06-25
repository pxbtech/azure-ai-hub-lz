<#
.SYNOPSIS
    Enables diagnostic settings on every PoC resource, routing all logs and
    metrics to the central Log Analytics workspace.

.DESCRIPTION
    Idempotent. Each setting is named "send-to-law-${instance}" so a re-run
    overwrites the same setting in place.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $SubscriptionId,
    [Parameter(Mandatory)] [pscustomobject] $Outputs
)

. $PSScriptRoot/Common-Functions.ps1

Write-Step "Diagnostic settings, send to Log Analytics"

$rg    = $Outputs.resourceGroupName
$lawId = $Outputs.logAnalyticsId

function Set-Diag {
    param(
        [string] $TargetResourceId,
        [string] $TargetLabel,
        [object[]] $Logs,
        [bool]   $AllMetrics
    )
    $name = 'send-to-law-01'
    $uri  = "https://management.azure.com$TargetResourceId/providers/Microsoft.Insights/diagnosticSettings/${name}?api-version=2021-05-01-preview"
    $metrics = @()
    if ($AllMetrics) {
        $metrics = @( @{ category = 'AllMetrics'; enabled = $true } )
    }
    $body = @{
        properties = @{
            workspaceId = $lawId
            logs        = $Logs
            metrics     = $metrics
        }
    } | ConvertTo-Json -Depth 8
    $resp = Invoke-AzApi -Method PUT -Uri $uri -JsonBody $body -AllowedStatusCodes @(200, 201)
    Write-Ok "${TargetLabel}: diagnostic settings applied"
}

$allLogs = @( @{ categoryGroup = 'allLogs'; enabled = $true } )
$auditOnly = @(
    @{ category = 'AuditEvent'; enabled = $true }
    @{ category = 'AzurePolicyEvaluationDetails'; enabled = $true }
)

# Foundry
Set-Diag -TargetResourceId "/subscriptions/$SubscriptionId/resourceGroups/$rg/providers/Microsoft.CognitiveServices/accounts/$($Outputs.foundryName)" `
         -TargetLabel "Foundry"        -Logs $allLogs -AllMetrics $true

# Content Safety
Set-Diag -TargetResourceId "/subscriptions/$SubscriptionId/resourceGroups/$rg/providers/Microsoft.CognitiveServices/accounts/$($Outputs.contentSafetyName)" `
         -TargetLabel "Content Safety" -Logs $allLogs -AllMetrics $true

# Language
Set-Diag -TargetResourceId "/subscriptions/$SubscriptionId/resourceGroups/$rg/providers/Microsoft.CognitiveServices/accounts/$($Outputs.languageName)" `
         -TargetLabel "Language"       -Logs $allLogs -AllMetrics $true

# APIM
Set-Diag -TargetResourceId "/subscriptions/$SubscriptionId/resourceGroups/$rg/providers/Microsoft.ApiManagement/service/$($Outputs.apimName)" `
         -TargetLabel "APIM"           -Logs $allLogs -AllMetrics $true

# Key Vault, audit only
Set-Diag -TargetResourceId "/subscriptions/$SubscriptionId/resourceGroups/$rg/providers/Microsoft.KeyVault/vaults/$($Outputs.keyVaultName)" `
         -TargetLabel "Key Vault"      -Logs $auditOnly -AllMetrics $true

# Storage, metrics only at the account level
Set-Diag -TargetResourceId "/subscriptions/$SubscriptionId/resourceGroups/$rg/providers/Microsoft.Storage/storageAccounts/$($Outputs.storageAccountName)" `
         -TargetLabel "Storage"        -Logs @() -AllMetrics $true
