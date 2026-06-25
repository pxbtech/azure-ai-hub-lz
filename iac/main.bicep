// =============================================================================
// AI Hub Reference, main.bicep, subscription scope orchestrator.
//
// Provisions the bare resources only. Post-deployment configuration (APIM
// policy chain, Foundry RAI policy, diagnostic settings, alert rules, Key
// Vault secret population) is handled by the PowerShell scripts under
// /post-config and executed by the GitHub Actions workflow .github/workflows/
// deploy.yml.
//
// Naming convention is documented in /README.md section 3. Workload code
// "aihub". Environment code "poc". Region canadacentral. All resource names
// here are derived from these three values and the type abbreviation.
// =============================================================================

targetScope = 'subscription'

@description('Canadian region for all resources. Canada Central required because gpt-5.4-nano is available there on Global Standard.')
@allowed([
  'canadacentral'
  'canadaeast'
])
param location string = 'canadacentral'

@description('Environment code segment. Lowercase, 2 to 4 chars.')
@minLength(2)
@maxLength(4)
param envCode string = 'poc'

@description('Workload code segment. Lowercase, 3 to 6 chars.')
@minLength(3)
@maxLength(6)
param workload string = 'aihub'

@description('Org code segment used in the resource group name. Lowercase.')
@minLength(2)
@maxLength(4)
param orgCode string = 'it'

@description('Subscription billing currency budget cap. Applied per billing cycle. The subscription billing cycle is 27 -> 26.')
param budgetAmountCad int = 1500

@description('Budget start date. Must be the first of a calendar month, UTC.')
param budgetStartDate string = '2026-07-01T00:00:00Z'

@description('Email address that receives FinOps and security alerts.')
param alertEmail string = 'alerts@example.com'

@description('Email address shown on the APIM developer portal as the publisher.')
param apimPublisherEmail string = 'alerts@example.com'

@description('Publisher name shown on the APIM developer portal.')
param apimPublisherName string = 'AI Hub Reference Implementation'

@description('Chat model deployment capacity in thousands of tokens per minute.')
@minValue(1)
@maxValue(50)
param chatModelCapacity int = 10

@description('Chat model name. gpt-5.4-nano is the cheapest current-generation chat model available in Canadian regions with the longest retirement runway.')
param chatModelName string = 'gpt-5.4-nano'

@description('Chat model version. Pin to a date string returned by the models API; leave blank to take Azure default.')
param chatModelVersion string = '2026-03-17'

@description('Instance number, zero-padded. Used as the suffix on every resource name.')
@minLength(2)
@maxLength(2)
param instance string = '01'

@description('Common tag set applied to every resource.')
param tags object = {
  workload: 'aihub'
  environment: 'poc'
  costCenter: 'your-cost-center'
  managedBy: 'bicep'
  owner: 'platform-team'
  application: 'ai-hub-reference'
}

// -----------------------------------------------------------------------------
// Derived names. Follow {env}-{workload}-{type}-{NN} for hyphenated resources
// and {env}{workload}{type}{NN} for storage and other no-hyphen types.
// -----------------------------------------------------------------------------

var rgName            = '${envCode}-${orgCode}-rg-${workload}'
var lawName           = '${envCode}-${workload}-law-${instance}'
var appiName          = '${envCode}-${workload}-appi-${instance}'
var vnetName          = '${envCode}-${workload}-vnet-${instance}'
var kvName            = '${envCode}-${workload}-kv-${instance}'
var storageName       = '${envCode}${workload}st${instance}'
var contentSafetyName = '${envCode}-${workload}-cs-${instance}'
var languageName      = '${envCode}-${workload}-lang-${instance}'
var foundryName       = '${envCode}-${workload}-aif-${instance}'
var apimName          = '${envCode}-${workload}-apim-${instance}'
var actionGroupName   = '${envCode}-${workload}-ag-${instance}'
var budgetName        = '${envCode}-${workload}-budget-${instance}'

// -----------------------------------------------------------------------------
// Resource Group.
// -----------------------------------------------------------------------------

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: tags
}

// -----------------------------------------------------------------------------
// Foundation modules. Order matters: observability is referenced by everything
// else that emits diagnostic settings during post-config.
// -----------------------------------------------------------------------------

module observability 'modules/observability.bicep' = {
  name: 'mod-observability'
  scope: rg
  params: {
    location: location
    lawName: lawName
    appiName: appiName
    tags: tags
  }
}

module network 'modules/network.bicep' = {
  name: 'mod-network'
  scope: rg
  params: {
    location: location
    vnetName: vnetName
    workload: workload
    envCode: envCode
    tags: tags
  }
}

module keyvault 'modules/keyvault.bicep' = {
  name: 'mod-keyvault'
  scope: rg
  params: {
    location: location
    kvName: kvName
    tags: tags
  }
}

module storage 'modules/storage.bicep' = {
  name: 'mod-storage'
  scope: rg
  params: {
    location: location
    storageName: storageName
    tags: tags
  }
}

// -----------------------------------------------------------------------------
// AI service modules.
// -----------------------------------------------------------------------------

module contentSafety 'modules/content-safety.bicep' = {
  name: 'mod-content-safety'
  scope: rg
  params: {
    location: location
    accountName: contentSafetyName
    tags: tags
  }
}

module language 'modules/language.bicep' = {
  name: 'mod-language'
  scope: rg
  params: {
    location: location
    accountName: languageName
    tags: tags
  }
}

module foundry 'modules/foundry.bicep' = {
  name: 'mod-foundry'
  scope: rg
  params: {
    location: location
    accountName: foundryName
    projectName: 'proj-chat'
    chatDeploymentName: 'chat'
    chatModelName: chatModelName
    chatModelVersion: chatModelVersion
    chatModelCapacity: chatModelCapacity
    tags: tags
  }
}

// -----------------------------------------------------------------------------
// Gateway.
// -----------------------------------------------------------------------------

module apim 'modules/apim.bicep' = {
  name: 'mod-apim'
  scope: rg
  params: {
    location: location
    apimName: apimName
    publisherEmail: apimPublisherEmail
    publisherName: apimPublisherName
    tags: tags
  }
}

// -----------------------------------------------------------------------------
// FinOps.
// -----------------------------------------------------------------------------

module actionGroup 'modules/action-group.bicep' = {
  name: 'mod-action-group'
  scope: rg
  params: {
    actionGroupName: actionGroupName
    alertEmail: alertEmail
    tags: tags
  }
}

module budget 'modules/budget.bicep' = {
  name: 'mod-budget'
  params: {
    budgetName: budgetName
    amount: budgetAmountCad
    startDate: budgetStartDate
    alertEmail: alertEmail
    actionGroupId: actionGroup.outputs.actionGroupId
  }
}

// -----------------------------------------------------------------------------
// Outputs consumed by the post-config script.
// -----------------------------------------------------------------------------

output resourceGroupName        string = rg.name
output location                 string = location
output logAnalyticsName          string = observability.outputs.logAnalyticsName
output logAnalyticsId            string = observability.outputs.logAnalyticsId
output applicationInsightsName   string = observability.outputs.applicationInsightsName
output applicationInsightsId     string = observability.outputs.applicationInsightsId
output keyVaultName              string = keyvault.outputs.keyVaultName
output keyVaultUri               string = keyvault.outputs.keyVaultUri
output storageAccountName        string = storage.outputs.storageAccountName
output contentSafetyName         string = contentSafety.outputs.accountName
output contentSafetyEndpoint     string = contentSafety.outputs.endpoint
output languageName              string = language.outputs.accountName
output languageEndpoint          string = language.outputs.endpoint
output foundryName               string = foundry.outputs.accountName
output foundryEndpoint           string = foundry.outputs.endpoint
output foundryProjectName        string = foundry.outputs.projectName
output chatDeploymentName        string = foundry.outputs.chatDeploymentName
output apimName                  string = apim.outputs.apimName
output apimGatewayUrl            string = apim.outputs.apimGatewayUrl
output apimPrincipalId           string = apim.outputs.apimPrincipalId
output actionGroupId             string = actionGroup.outputs.actionGroupId
output budgetName                string = budget.outputs.budgetName
