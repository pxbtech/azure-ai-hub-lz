// Subscription-scope Cost Management budget. Notifications wired to the
// platform Action Group at the 100 percent threshold, and to email at 50
// and 80 percent.

targetScope = 'subscription'

param budgetName string
param amount int
param startDate string
param alertEmail string
param actionGroupId string

resource budget 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: budgetName
  properties: {
    amount: amount
    category: 'Cost'
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
    }
    notifications: {
      Actual_50_Percent: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 50
        thresholdType: 'Actual'
        contactEmails: [ alertEmail ]
        locale: 'en-us'
      }
      Actual_80_Percent: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: [ alertEmail ]
        locale: 'en-us'
      }
      Actual_100_Percent_HardStop: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        thresholdType: 'Actual'
        contactEmails: [ alertEmail ]
        contactGroups: [ actionGroupId ]
        locale: 'en-us'
      }
    }
  }
}

output budgetName string = budget.name
