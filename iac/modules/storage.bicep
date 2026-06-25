// Storage account, StorageV2, Standard LRS, Hot. Used as the BYO connection
// for the Foundry project artifacts. Hardened defaults: no public blob
// access, TLS 1.2 minimum, shared key access enabled only because Foundry
// requires it for its BYO connection path.

param location string
param storageName string
param tags object

resource storage 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource blobSvc 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' = {
  parent: storage
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

output storageAccountName string = storage.name
output storageAccountId   string = storage.id
