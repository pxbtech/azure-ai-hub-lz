<#
.SYNOPSIS
    Grants the APIM system-assigned Managed Identity the Cognitive Services
    User role on the Foundry, Content Safety, and Language accounts.

.DESCRIPTION
    Idempotent. Uses a deterministic GUID for each role assignment name so
    re-runs do not duplicate assignments.

.PARAMETER SubscriptionId
    The subscription that owns the resources.

.PARAMETER Outputs
    The Bicep deployment outputs object produced by Get-DeploymentOutputs.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $SubscriptionId,
    [Parameter(Mandatory)] [pscustomobject] $Outputs
)

. $PSScriptRoot/Common-Functions.ps1

$cognitiveServicesUserRoleId = 'a97b65f3-24c7-4388-baec-2e87135dc908'
$keyVaultSecretsUserRoleId   = '4633458b-17de-408a-b874-0445c86b69e6'
$rg = $Outputs.resourceGroupName
$apimPrincipalId = $Outputs.apimPrincipalId

function Grant-Role {
    param(
        [string] $Scope,
        [string] $PrincipalId,
        [string] $RoleDefinitionId,
        [string] $Description
    )
    $seed = "$Scope|$PrincipalId|$RoleDefinitionId"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($seed)
    $md5   = [System.Security.Cryptography.MD5]::Create().ComputeHash($bytes)
    $assignmentName = ([guid]::new($md5)).ToString()
    $uri = "https://management.azure.com${Scope}/providers/Microsoft.Authorization/roleAssignments/${assignmentName}?api-version=2022-04-01"
    $body = @{
        properties = @{
            roleDefinitionId = "/subscriptions/$SubscriptionId/providers/Microsoft.Authorization/roleDefinitions/$RoleDefinitionId"
            principalId      = $PrincipalId
            principalType    = 'ServicePrincipal'
            description      = $Description
        }
    } | ConvertTo-Json -Depth 5
    try {
        $resp = Invoke-AzApi -Method PUT -Uri $uri -JsonBody $body -AllowedStatusCodes @(200, 201)
        return $resp.StatusCode
    }
    catch {
        if ($_.Exception.Message -match 'RoleAssignmentExists') {
            return 'exists'
        } else {
            throw
        }
    }
}

Write-Step "RBAC: APIM MI -> Cognitive Services User on AI accounts"

$targets = @(
    @{ name = $Outputs.foundryName;       label = 'Foundry'        }
    @{ name = $Outputs.contentSafetyName; label = 'Content Safety' }
    @{ name = $Outputs.languageName;      label = 'Language'       }
)
foreach ($t in $targets) {
    $scope = "/subscriptions/$SubscriptionId/resourceGroups/$rg/providers/Microsoft.CognitiveServices/accounts/$($t.name)"
    $r = Grant-Role -Scope $scope -PrincipalId $apimPrincipalId -RoleDefinitionId $cognitiveServicesUserRoleId -Description "APIM MI, Cognitive Services User on $($t.label)"
    Write-Ok "$($t.label): $r"
}

Write-Step "RBAC: APIM MI -> Key Vault Secrets User on Key Vault"
$kvScope = "/subscriptions/$SubscriptionId/resourceGroups/$rg/providers/Microsoft.KeyVault/vaults/$($Outputs.keyVaultName)"
$r = Grant-Role -Scope $kvScope -PrincipalId $apimPrincipalId -RoleDefinitionId $keyVaultSecretsUserRoleId -Description "APIM MI, Key Vault Secrets User on $($Outputs.keyVaultName)"
Write-Ok "Key Vault: $r"
Write-Ok "Sleeping 30s for AAD role propagation before downstream KV reference use..."
Start-Sleep -Seconds 30
