// Action Group used by every alert rule created in post-config and by the
// Cost Management budget at subscription scope. Single email receiver for the
// PoC. Production would add SMS, webhook, and ITSM connectors.

param actionGroupName string
param alertEmail string
param tags object

resource ag 'Microsoft.Insights/actionGroups@2024-10-01-preview' = {
  name: actionGroupName
  location: 'Global'
  tags: tags
  properties: {
    groupShortName: 'aihubag'
    enabled: true
    emailReceivers: [
      {
        name: 'primary-email'
        emailAddress: alertEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

output actionGroupId   string = ag.id
output actionGroupName string = ag.name
