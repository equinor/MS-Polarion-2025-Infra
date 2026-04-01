targetScope = 'resourceGroup'

param dataCollectionEndpointId string
param dataCollectionRuleName string
param location string
param logAnalyticsWorkspaceId string
param logAnalyticsWorkspaceName string
param counterSpecifiers array

param streams array

param kind string

param samplingFrequency int

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: dataCollectionRuleName
  location: location
  properties: {
    dataCollectionEndpointId: dataCollectionEndpointId
    dataFlows: [
      {
        streams: streams
        destinations: [
          logAnalyticsWorkspaceName
        ]
      }
    ]
    dataSources: {
      performanceCounters: [
        {
          streams: streams
          counterSpecifiers: counterSpecifiers
          samplingFrequencyInSeconds: samplingFrequency
          name: dataCollectionRuleName
        }
      ]
    }
    description: 'Collection rule'
    destinations: {
      logAnalytics: [
        {
          name: logAnalyticsWorkspaceName
          workspaceResourceId: logAnalyticsWorkspaceId
        }
      ]
    }
  }
  kind: kind
}

output dataCollectionRuleId string = dataCollectionRule.id
output dataCollectionRuleName string = dataCollectionRule.name
