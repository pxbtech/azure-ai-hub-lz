// Microsoft Foundry account (Microsoft.CognitiveServices kind AIServices,
// new resource model with allowProjectManagement=true), plus one project and
// one chat model deployment.

param location string
param accountName string
param projectName string
param chatDeploymentName string
param chatModelName string
param chatModelVersion string
param chatModelCapacity int
param tags object

resource foundry 'Microsoft.CognitiveServices/accounts@2025-12-01' = {
  name: accountName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    allowProjectManagement: true
    customSubDomainName: accountName
    disableLocalAuth: false
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource project 'Microsoft.CognitiveServices/accounts/projects@2025-12-01' = {
  parent: foundry
  name: projectName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'AI Hub PoC chat project'
    description: 'Foundry project that hosts the chat model deployment for the AI Hub PoC.'
  }
}

resource chat 'Microsoft.CognitiveServices/accounts/deployments@2025-12-01' = {
  parent: foundry
  name: chatDeploymentName
  sku: {
    name: 'GlobalStandard'
    capacity: chatModelCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: chatModelName
      version: chatModelVersion
    }
    raiPolicyName: 'Microsoft.DefaultV2'
    versionUpgradeOption: 'OnceCurrentVersionExpired'
  }
}

output accountName        string = foundry.name
output accountId          string = foundry.id
output endpoint           string = foundry.properties.endpoint
output projectName        string = project.name
output chatDeploymentName string = chat.name
