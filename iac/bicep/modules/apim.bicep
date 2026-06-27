// API Management, Developer tier, 1 unit, no SLA, no VNet integration. APIs,
// products, named values, backends, and the GenAI policy chain are applied
// post-deployment by /post-config/scripts/Set-ApimGateway.ps1. The instance
// itself ships with a system-assigned managed identity so the post-config
// step can grant it Cognitive Services User on the AI accounts.

param location string
param apimName string
param publisherEmail string
param publisherName string
param tags object

resource apim 'Microsoft.ApiManagement/service@2024-05-01' = {
  name: apimName
  location: location
  tags: tags
  sku: {
    name: 'Developer'
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkType: 'None'
    publicNetworkAccess: 'Enabled'
  }
}

output apimName        string = apim.name
output apimId          string = apim.id
output apimPrincipalId string = apim.identity.principalId
output apimGatewayUrl  string = apim.properties.gatewayUrl
