<#
.SYNOPSIS
    Retrieves the data plane keys for Language and Content Safety from the
    Cognitive Services control plane and writes them as Key Vault secrets.

.DESCRIPTION
    APIM references these secrets via Key Vault named-value references in
    /post-config/scripts/Set-ApimGateway.ps1. The SPN running this script
    must have:
      - Cognitive Services Contributor on each AI account (to call listKeys)
      - Key Vault Secrets Officer on the Key Vault (to write secrets)

    Secrets written:
      language-key, the primary key for the Language F0 account
      content-safety-key, the primary key for the Content Safety F0 account

    The script grants its own SPN Key Vault Secrets Officer first if the
    role assignment is missing.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $SubscriptionId,
    [Parameter(Mandatory)] [pscustomobject] $Outputs
)

. $PSScriptRoot/Common-Functions.ps1

Write-Step "Key Vault secrets: language-key, content-safety-key"

$rg     = $Outputs.resourceGroupName
$kvName = $Outputs.keyVaultName
$kvUri  = $Outputs.keyVaultUri

function Get-CognitiveServicesKey {
    param([string] $AccountName)
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$rg/providers/Microsoft.CognitiveServices/accounts/$AccountName/listKeys?api-version=2025-12-01"
    $resp = Invoke-AzApi -Method POST -Uri $uri
    $j = $resp.Content | ConvertFrom-Json
    return $j.key1
}

function Set-KvSecret {
    param([string] $Name, [string] $Value)
    $uri = "$($kvUri)secrets/${Name}?api-version=7.4"
    $body = @{ value = $Value } | ConvertTo-Json -Compress
    $resp = Invoke-AzApi -Method PUT -Uri $uri -JsonBody $body -AllowedStatusCodes @(200)
    Write-Ok "Key Vault secret written: $Name"
}

# Self-grant Key Vault Secrets Officer if missing. The role GUID is
# b86a8fe4-44ce-4948-aee5-eccb2c155cd7.
$kvSecretsOfficer = 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
$currentSpn = (Get-AzContext).Account.Id
$spnObjectId = (Get-AzADServicePrincipal -ApplicationId $currentSpn -ErrorAction SilentlyContinue).Id
if (-not $spnObjectId) {
    # Fallback for managed identity or user accounts where ApplicationId is not a GUID.
    Write-Skip "Could not resolve SPN object id from context. Assuming caller already has KV access."
} else {
    $scope = "/subscriptions/$SubscriptionId/resourceGroups/$rg/providers/Microsoft.KeyVault/vaults/$kvName"
    $seed  = "$scope|$spnObjectId|$kvSecretsOfficer"
    $md5   = [System.Security.Cryptography.MD5]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($seed))
    $assignmentName = ([guid]::new($md5)).ToString()
    $uri = "https://management.azure.com${scope}/providers/Microsoft.Authorization/roleAssignments/${assignmentName}?api-version=2022-04-01"
    $body = @{
        properties = @{
            roleDefinitionId = "/subscriptions/$SubscriptionId/providers/Microsoft.Authorization/roleDefinitions/$kvSecretsOfficer"
            principalId      = $spnObjectId
            principalType    = 'ServicePrincipal'
        }
    } | ConvertTo-Json -Depth 5
    try {
        $null = Invoke-AzApi -Method PUT -Uri $uri -JsonBody $body -AllowedStatusCodes @(200, 201)
        Write-Ok "SPN granted Key Vault Secrets Officer on $kvName (or already present)"
        Start-Sleep -Seconds 15
    } catch {
        if ($_.Exception.Message -match 'RoleAssignmentExists') {
            Write-Ok "SPN role already present on $kvName"
        } else {
            Write-Skip "Could not self-grant KV role: $($_.Exception.Message). Continuing in case it is already granted."
        }
    }
}

$languageKey = Get-CognitiveServicesKey -AccountName $Outputs.languageName
Set-KvSecret -Name 'language-key' -Value $languageKey

$contentSafetyKey = Get-CognitiveServicesKey -AccountName $Outputs.contentSafetyName
Set-KvSecret -Name 'content-safety-key' -Value $contentSafetyKey
