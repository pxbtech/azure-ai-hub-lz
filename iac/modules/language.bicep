// Azure AI Language, F0 tier. Used by APIM to perform PII detection and
// entity-mask redaction on inbound prompts before they reach Foundry.

param location string
param accountName string
param tags object

resource language 'Microsoft.CognitiveServices/accounts@2025-12-01' = {
  name: accountName
  location: location
  tags: tags
  kind: 'TextAnalytics'
  sku: {
    name: 'F0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: accountName
    disableLocalAuth: false
    publicNetworkAccess: 'Enabled'
  }
}

output accountName string = language.name
output accountId   string = language.id
output endpoint    string = language.properties.endpoint
