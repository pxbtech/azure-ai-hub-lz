<#
.SYNOPSIS
    Configures the APIM gateway for the chat use case: backends, named
    values (with Key Vault references), an API imported from OpenAPI, a
    product, and the full GenAI policy chain attached to the API.

.DESCRIPTION
    Idempotent. PUT operations against named ARM URIs overwrite in place.
    Policy XML is loaded from
    /post-config/policies/apim/chat-api-policy.xml. OpenAPI definition is
    loaded from /post-config/policies/apim/openapi-chat.json.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $SubscriptionId,
    [Parameter(Mandatory)] [pscustomobject] $Outputs
)

. $PSScriptRoot/Common-Functions.ps1

Write-Step "APIM gateway configuration"

$rg          = $Outputs.resourceGroupName
$apim        = $Outputs.apimName

# APIM Developer SKU has no SLA. The management endpoint can be unavailable
# during platform upgrades (typically 5 to 15 minutes). Wait for the
# service to report Online before sending control-plane writes.
Write-Step "APIM readiness probe"
$apimUri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$rg/providers/Microsoft.ApiManagement/service/${apim}?api-version=2024-05-01"
$probeAttempts = 30
for ($i = 1; $i -le $probeAttempts; $i++) {
    $resp = Invoke-AzRestMethod -Method GET -Uri $apimUri
    if ($resp.StatusCode -eq 200) {
        $state = ($resp.Content | ConvertFrom-Json).properties.provisioningState
        if ($state -eq 'Succeeded') {
            Write-Ok "APIM provisioningState=$state (attempt $i)"
            break
        }
        Write-Skip "APIM provisioningState=$state, waiting 30s (attempt $i / $probeAttempts)"
    } else {
        Write-Skip "APIM probe HTTP $($resp.StatusCode), waiting 30s (attempt $i / $probeAttempts)"
    }
    if ($i -eq $probeAttempts) { throw "APIM never reached provisioningState=Succeeded after $probeAttempts attempts." }
    Start-Sleep -Seconds 30
}
$kvUri       = $Outputs.keyVaultUri
$foundryUri  = $Outputs.foundryEndpoint
$csUri       = $Outputs.contentSafetyEndpoint
$languageUri = $Outputs.languageEndpoint
$chatDeploy  = $Outputs.chatDeploymentName

$apimBase = "/subscriptions/$SubscriptionId/resourceGroups/$rg/providers/Microsoft.ApiManagement/service/$apim"
$apiVer   = '2024-05-01'

function Put($SubPath, $Body) {
    $uri = "https://management.azure.com$apimBase/$SubPath`?api-version=$apiVer"
    return Invoke-AzApi -Method PUT -Uri $uri -JsonBody $Body -AllowedStatusCodes @(200, 201, 202)
}

# ---- Named values (plain) ------------------------------------------------
Write-Step "APIM named values, plain"

$plainNvs = @{
    'foundry-endpoint'        = $foundryUri
    'content-safety-endpoint' = $csUri
    'language-endpoint'       = $languageUri
    'chat-deployment'         = $chatDeploy
    'language-api-version'    = '2024-11-15-preview'
    'openai-api-version'      = '2024-10-21'
}
foreach ($n in $plainNvs.GetEnumerator()) {
    $body = @{
        properties = @{
            displayName = $n.Key
            value       = $n.Value
            secret      = $false
        }
    } | ConvertTo-Json -Depth 5
    Put "namedValues/$($n.Key)" $body | Out-Null
    Write-Ok "named value: $($n.Key)"
}

# ---- Named values (Key Vault references) --------------------------------
Write-Step "APIM named values, Key Vault references"

$kvNvs = @(
    @{ name = 'language-key';        secretUri = "${kvUri}secrets/language-key"        }
    @{ name = 'content-safety-key';  secretUri = "${kvUri}secrets/content-safety-key"  }
)
foreach ($n in $kvNvs) {
    $body = @{
        properties = @{
            displayName = $n.name
            secret      = $true
            keyVault    = @{
                secretIdentifier = $n.secretUri
            }
        }
    } | ConvertTo-Json -Depth 5
    Put "namedValues/$($n.name)" $body | Out-Null
    Write-Ok "named value (KV ref): $($n.name)"
}

# ---- Backends -----------------------------------------------------------
Write-Step "APIM backends"

$backends = @(
    @{ name = 'foundry-backend'        ; url = "${foundryUri}openai" ; desc = 'Microsoft Foundry data plane' }
    @{ name = 'content-safety-backend' ; url = $csUri                ; desc = 'Azure AI Content Safety'      }
    @{ name = 'language-backend'       ; url = $languageUri          ; desc = 'Azure AI Language'            }
)
foreach ($b in $backends) {
    $body = @{
        properties = @{
            url         = $b.url
            protocol    = 'http'
            description = $b.desc
            tls         = @{
                validateCertificateChain = $true
                validateCertificateName  = $true
            }
        }
    } | ConvertTo-Json -Depth 6
    Put "backends/$($b.name)" $body | Out-Null
    Write-Ok "backend: $($b.name)"
}

# ---- Product ------------------------------------------------------------
Write-Step "APIM product"

$productBody = @{
    properties = @{
        displayName        = 'Chat Internal'
        description        = 'Internal chat use case. One subscription key per consumer. Token quota enforced per key.'
        subscriptionRequired = $true
        approvalRequired   = $false
        subscriptionsLimit = 50
        state              = 'published'
        terms              = 'For internal PoC use only. Subject to enterprise content safety, PII redaction, rate limit, and monthly token quota.'
    }
} | ConvertTo-Json -Depth 5
Put 'products/chat-internal' $productBody | Out-Null
Write-Ok "product: chat-internal"

# ---- API (OpenAPI import) -----------------------------------------------
Write-Step "APIM API import"

$openapiPath = Join-Path $PSScriptRoot '..\policies\apim\openapi-chat.json'
$openapiRaw  = Get-Content -Path $openapiPath -Raw

$apiBody = @{
    properties = @{
        displayName          = 'OpenAI Chat (via Foundry)'
        description          = 'Governed chat endpoint backed by gpt-5.4-nano on Microsoft Foundry. All inbound traffic passes the GenAI policy chain.'
        path                 = 'openai'
        protocols            = @( 'https' )
        subscriptionRequired = $true
        apiType              = 'http'
        serviceUrl           = "${foundryUri}openai"
        format               = 'openapi+json'
        value                = $openapiRaw
    }
} | ConvertTo-Json -Depth 6
Put 'apis/openai-chat' $apiBody | Out-Null
Write-Ok "api: openai-chat"

# ---- Link API to product ------------------------------------------------
Put 'products/chat-internal/apis/openai-chat' '{}' | Out-Null
Write-Ok "product link: chat-internal -> openai-chat"

# ---- Policy XML ---------------------------------------------------------
Write-Step "APIM policy attach"

$policyPath = Join-Path $PSScriptRoot '..\policies\apim\chat-api-policy.xml'
$policyXml  = Get-Content -Path $policyPath -Raw

$policyBody = @{
    properties = @{
        format = 'rawxml'
        value  = $policyXml
    }
} | ConvertTo-Json -Depth 5
Put 'apis/openai-chat/policies/policy' $policyBody | Out-Null
Write-Ok "policy attached to openai-chat"
