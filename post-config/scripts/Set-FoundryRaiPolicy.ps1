<#
.SYNOPSIS
    Applies the custom Responsible AI policy to the Foundry chat deployment.

.DESCRIPTION
    Loads /post-config/policies/foundry/rai-policy.json, PUTs it to the
    Foundry control plane to create (or update) the RAI policy, then
    updates the chat deployment to reference the custom policy by name.

    Idempotent. The RAI policy name is derived from the deployment name.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $SubscriptionId,
    [Parameter(Mandatory)] [pscustomobject] $Outputs
)

. $PSScriptRoot/Common-Functions.ps1

Write-Step "Foundry RAI policy"

$rg         = $Outputs.resourceGroupName
$foundry    = $Outputs.foundryName
$deployment = $Outputs.chatDeploymentName

$policyPath = Join-Path $PSScriptRoot '..\policies\foundry\rai-policy.json'
$policyBody = Get-Content -Path $policyPath -Raw
$policyName = 'aihub-poc-strict'

$uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$rg/providers/Microsoft.CognitiveServices/accounts/$foundry/raiPolicies/${policyName}?api-version=2025-12-01"
$null = Invoke-AzApi -Method PUT -Uri $uri -JsonBody $policyBody -AllowedStatusCodes @(200, 201)
Write-Ok "RAI policy '${policyName}' created or updated on $foundry"

Write-Step "Bind chat deployment to RAI policy"

$deployUri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$rg/providers/Microsoft.CognitiveServices/accounts/$foundry/deployments/${deployment}?api-version=2025-12-01"

$current = (Invoke-AzApi -Method GET -Uri $deployUri).Content | ConvertFrom-Json
$patch = @{
    sku        = $current.sku
    properties = $current.properties
}
$patch.properties.raiPolicyName = $policyName

$null = Invoke-AzApi -Method PUT -Uri $deployUri -JsonBody ($patch | ConvertTo-Json -Depth 12) -AllowedStatusCodes @(200, 201)
Write-Ok "Deployment '$deployment' bound to RAI policy '$policyName'"
