@description('Keyvault Name to be used for storing secrets')
param keyVaultName string

@description('Environment to be deployed')
@allowed([
  'DEV'
  'TEST'
  'QA'
  'PROD'
  'TST'
  'PRD'
  'dev'
  'qa'
  'prd'
  'prod'
  'tst'
  'test'
  'DEMO'
  'demo'
])
param environment string

param tags object
param rgLocation string
param resourceGroupName string
param keyVaultAccessObject array

resource newRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: '${resourceGroupName}-${environment}'
  scope: subscription()
}

output existingRGName string = newRG.name

// module keyVault 'br/public:avm/res/key-vault/vault:0.13.3' = {
//   name: '${keyVaultName}${uniqueString(keyVaultName)}'
//   params: {
//     location: rgLocation
//     name: toLower(keyVaultName)
//     enableVaultForDeployment: enabledForDeployment
//     enableVaultForDiskEncryption: enabledForDiskEncryption
//     enableVaultForTemplateDeployment: enabledForTemplateDeployment
//     tags: union(deploymentTags, tags, githubRepository)
//     enablePurgeProtection: enablePurgeProtection
//     enableSoftDelete: enableSoftDelete
//     softDeleteRetentionInDays: 7
//     networkAcls: networkAccessPolicies
//     publicNetworkAccess: publicNetworkAccess
//     // accessPolicies: keyVaultAccessObject    
//     enableRbacAuthorization: true
//     roleAssignments: keyVaultAccessObject
//     createMode: 'default'
//   }
//   scope: resourceGroup(newRG.name)
// }

// output keyVaultName string = keyVault.outputs.name
// output keyVaultUrl string = keyVault.outputs.uri
// output keyVaultId string = keyVault.outputs.resourceId
