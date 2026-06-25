<#
.SYNOPSIS
    Shared helpers for the AI Hub PoC post-deployment configuration scripts.

.DESCRIPTION
    Dot-source this file from each Set-*.ps1 script. Provides:
      - Write-Step, Write-Ok, Write-Skip, Write-Fail for consistent logging.
      - Get-DeploymentOutputs, reads the Bicep deployment outputs from the
        subscription-scope deployment by name.
      - Invoke-AzApi, thin wrapper around Invoke-AzRestMethod with retry
        and structured error reporting.
      - Resolve-AzResource, locates a resource by name within the deployed
        resource group and returns its full resource ID.
#>

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Step([string]$msg) { Write-Host ""; Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok  ([string]$msg) { Write-Host "    OK   $msg" -ForegroundColor Green }
function Write-Skip([string]$msg) { Write-Host "    SKIP $msg" -ForegroundColor Yellow }
function Write-Fail([string]$msg) { Write-Host "    FAIL $msg" -ForegroundColor Red }

function Get-DeploymentOutputs {
    param(
        [Parameter(Mandatory)] [string] $DeploymentName,
        [Parameter(Mandatory)] [string] $SubscriptionId
    )
    Write-Step "Reading deployment outputs from '$DeploymentName' at subscription scope"
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Resources/deployments/${DeploymentName}?api-version=2024-03-01"
    $resp = Invoke-AzRestMethod -Method GET -Uri $uri
    if ($resp.StatusCode -ne 200) {
        throw "Failed to read deployment outputs. Status $($resp.StatusCode). Body: $($resp.Content)"
    }
    $j = $resp.Content | ConvertFrom-Json
    if (-not $j.properties.outputs) {
        throw "Deployment '$DeploymentName' has no outputs."
    }
    $flat = [ordered]@{}
    foreach ($p in $j.properties.outputs.PSObject.Properties) {
        $flat[$p.Name] = $p.Value.value
    }
    Write-Ok "Outputs: $($flat.Keys -join ', ')"
    return [pscustomobject]$flat
}

function Invoke-AzApi {
    param(
        [Parameter(Mandatory)] [string] $Method,
        [Parameter(Mandatory)] [string] $Uri,
        [string] $JsonBody,
        [int]    $RetryCount = 8,
        [int]    $RetryDelaySeconds = 30,
        [int[]]  $AllowedStatusCodes = @(200, 201, 202, 204)
    )
    $attempt = 0
    while ($true) {
        $attempt++
        try {
            if ($JsonBody) {
                $resp = Invoke-AzRestMethod -Method $Method -Uri $Uri -Payload $JsonBody
            } else {
                $resp = Invoke-AzRestMethod -Method $Method -Uri $Uri
            }
            if ($AllowedStatusCodes -contains $resp.StatusCode) {
                return $resp
            }
            $err = "Request failed. $Method $Uri returned $($resp.StatusCode): $($resp.Content)"
            if ($attempt -ge $RetryCount) { throw $err }
            Write-Skip "Attempt $attempt failed ($($resp.StatusCode)), retrying in $RetryDelaySeconds s..."
            Start-Sleep -Seconds $RetryDelaySeconds
        }
        catch {
            if ($attempt -ge $RetryCount) { throw }
            Write-Skip "Attempt $attempt raised an exception ($($_.Exception.Message)), retrying..."
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }
}

function ConvertTo-CompactJson {
    param([Parameter(Mandatory, ValueFromPipeline)] $InputObject)
    process { $InputObject | ConvertTo-Json -Depth 32 -Compress }
}
