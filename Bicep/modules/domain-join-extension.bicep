targetScope = 'resourceGroup'

param vmName string
param location string
param domainJoinSettings object

@secure()
param domainJoinKey string

resource domainJoinExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  name: '${vmName}/domainJoin'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: false
    settings: domainJoinSettings
    protectedSettings: {
      Password: domainJoinKey
    }
  }
}
