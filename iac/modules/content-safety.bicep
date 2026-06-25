// Azure AI Content Safety, F0 tier. Provides Hate / Sexual / SelfHarm /
// Violence severity grading and Prompt Shield for jailbreak and indirect
// prompt injection. Called by the APIM llm-content-safety policy attached
// during post-config.

param location string
param accountName string
param tags object

resource contentSafety 'Microsoft.CognitiveServices/accounts@2025-12-01' = {
  name: accountName
  location: location
  tags: tags
  kind: 'ContentSafety'
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

output accountName string = contentSafety.name
output accountId   string = contentSafety.id
output endpoint    string = contentSafety.properties.endpoint
