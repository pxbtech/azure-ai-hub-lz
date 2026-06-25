<#
.SYNOPSIS
    Orchestrates post-deployment configuration of the AI Hub PoC.

.DESCRIPTION
    Run after the Bicep stack has succeeded. Reads deployment outputs from the
    subscription-scope deployment named by -DeploymentName and calls each
    Set-*.ps1 script in the correct order:

      1. Set-RbacAssignments      Grants APIM Managed Identity the
                                  Cognitive Services User role on Foundry,
                                  Content Safety, and Language.
      2. Set-KeyVaultSecrets      Retrieves the Language data plane key and
                                  writes it to Key Vault so APIM named
                                  values can reference it.
      3. Set-DiagnosticSettings   Wires diagnostic settings on Foundry,
                                  Content Safety, Language, APIM, Key Vault,
                                  Storage, and the Action Group, all to the
                                  Log Analytics workspace.
      4. Set-ApimGateway          Creates APIM backends, named values, the
                                  chat API, the chat product, and attaches
                                  the full GenAI policy chain.
      5. Set-FoundryRaiPolicy     Applies the custom Foundry RAI
                                  policy to the chat deployment.
      6. Set-AlertRules           Creates Log Analytics scheduled query
                                  alerts for Prompt Shield bursts, Content
                                  Safety high severity, and subscription
                                  Disabled state, all routed to the
                                  Action Group.

    The script is idempotent. Safe to re-run.

.PARAMETER SubscriptionId
    The subscription that owns the AI Hub PoC resources.

.PARAMETER DeploymentName
    Name of the subscription-scope deployment. Defaults to "aihub-poc-main".
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $SubscriptionId,
    [Parameter()]          [string] $DeploymentName = 'aihub-poc-main'
)

. $PSScriptRoot/Common-Functions.ps1

Write-Host ""
Write-Host "AI Hub PoC, post-deployment configuration" -ForegroundColor White
Write-Host "Subscription: $SubscriptionId"
Write-Host "Deployment:   $DeploymentName"
Write-Host ""

# Make sure subsequent Az calls target the right subscription.
$null = Set-AzContext -SubscriptionId $SubscriptionId

# Pull names and IDs from the Bicep deployment outputs.
$out = Get-DeploymentOutputs -DeploymentName $DeploymentName -SubscriptionId $SubscriptionId

# Step-by-step invocation. Each script writes its own status to stdout.
& $PSScriptRoot/Set-RbacAssignments.ps1     -SubscriptionId $SubscriptionId -Outputs $out
& $PSScriptRoot/Set-KeyVaultSecrets.ps1     -SubscriptionId $SubscriptionId -Outputs $out
& $PSScriptRoot/Set-DiagnosticSettings.ps1  -SubscriptionId $SubscriptionId -Outputs $out
& $PSScriptRoot/Set-ApimGateway.ps1         -SubscriptionId $SubscriptionId -Outputs $out
& $PSScriptRoot/Set-FoundryRaiPolicy.ps1    -SubscriptionId $SubscriptionId -Outputs $out
& $PSScriptRoot/Set-AlertRules.ps1          -SubscriptionId $SubscriptionId -Outputs $out

Write-Host ""
Write-Host "Post-configuration complete." -ForegroundColor Green
