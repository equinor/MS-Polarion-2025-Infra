@description('Please enter workspace name to be registered for current solution')
param workspaceName string

@description('Please enter location for resource to be deployed')
param rgLocation string = resourceGroup().location

@description('Please enter tags to identify your resources, cost allocation unit, contact person, solution etc as shown below.')
param tags object

@description('Please enter the length of your rentention in days - Int')
param retentionInDays int

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: rgLocation
  tags: tags
  properties: {
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
      immediatePurgeDataOn30Days: true
    }
    forceCmkForQuery: false
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    retentionInDays: retentionInDays
    sku: {
      name: 'standalone'
    }
  }
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
