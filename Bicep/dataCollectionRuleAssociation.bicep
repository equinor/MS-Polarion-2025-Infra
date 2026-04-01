targetScope = 'resourceGroup'

param dataCollectionRuleId string

param vmId string

resource vmToAssociate 'Microsoft.Compute/virtualMachines@2024-03-01' existing = {
  name: vmId
}

resource dataCollectionRuleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = {
  name: 'DataCollectionRuleAssociation'
  properties: {
    dataCollectionRuleId: dataCollectionRuleId
    description: 'DataCollectionAssociation'
  }
  scope: vmToAssociate
  dependsOn: [
    vmToAssociate
  ]
}
