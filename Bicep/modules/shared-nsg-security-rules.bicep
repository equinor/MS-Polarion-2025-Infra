targetScope = 'resourceGroup'

@description('Name of the existing NSG that should receive security rules.')
param networkSecurityGroupName string

@description('Security rules to apply to the existing NSG.')
param securityRules array

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-11-01' existing = {
  name: networkSecurityGroupName
}

resource networkSecurityGroupRules 'Microsoft.Network/networkSecurityGroups/securityRules@2023-11-01' = [for rule in securityRules: {
  name: rule.name
  parent: networkSecurityGroup
  properties: rule.properties
}]
