// Log Analytics workspace plus workspace-based Application Insights. The
// workspace has a 1 GB per day cap to bound ingestion cost during PoC. Both
// resources surface IDs as outputs so the post-config script can wire
// diagnostic settings on every other resource.

param location string
param lawName string
param appiName string
param tags object

@description('Daily ingestion cap in GB for the Log Analytics workspace.')
param dailyQuotaGb int = 1

@description('Retention in days.')
@minValue(30)
@maxValue(730)
param retentionInDays int = 31

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: lawName
  location: location
  tags: tags
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: retentionInDays
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource appi 'Microsoft.Insights/components@2020-02-02' = {
  name: appiName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: law.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    DisableLocalAuth: false
  }
}

output logAnalyticsName        string = law.name
output logAnalyticsId          string = law.id
output logAnalyticsCustomerId  string = law.properties.customerId
output applicationInsightsName string = appi.name
output applicationInsightsId   string = appi.id
@secure()
output appInsightsInstrumentationKey string = appi.properties.InstrumentationKey
output appInsightsConnectionString string = appi.properties.ConnectionString
