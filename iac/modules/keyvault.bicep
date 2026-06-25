// Key Vault Standard tier with RBAC authorization. Holds: language data plane
// key (populated by post-config), runbook SPN secret (optional), APIM named
// value references. Soft delete is enabled. Purge protection is intentionally
// not enabled for the PoC to allow clean teardown.

param location string
param kvName string
param tags object

resource kv 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: kvName
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: null
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

output keyVaultName string = kv.name
output keyVaultId   string = kv.id
output keyVaultUri  string = kv.properties.vaultUri
