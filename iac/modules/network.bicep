// Single VNet with three reserved subnets for future Private Endpoint, APIM
// injection, and runbook hook scenarios. No peering at the PoC stage.

param location string
param vnetName string
param workload string
param envCode string
param tags object

param vnetAddressPrefix string = '10.50.0.0/16'

var snetApim    = '${envCode}-${workload}-snet-apim-01'
var snetPe      = '${envCode}-${workload}-snet-pe-01'
var snetRunbook = '${envCode}-${workload}-snet-runbook-01'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [ vnetAddressPrefix ]
    }
    subnets: [
      {
        name: snetApim
        properties: {
          addressPrefix: '10.50.1.0/27'
        }
      }
      {
        name: snetPe
        properties: {
          addressPrefix: '10.50.2.0/27'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: snetRunbook
        properties: {
          addressPrefix: '10.50.3.0/27'
        }
      }
    ]
  }
}

output vnetId          string = vnet.id
output vnetName        string = vnet.name
output apimSubnetId    string = vnet.properties.subnets[0].id
output peSubnetId      string = vnet.properties.subnets[1].id
output runbookSubnetId string = vnet.properties.subnets[2].id
