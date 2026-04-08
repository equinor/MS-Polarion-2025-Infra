@description('Keyvault Name to be used')
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
param enabledForDeployment bool = true
param enabledForDiskEncryption bool = true
param enabledForTemplateDeployment bool = true
param enablePurgeProtection bool = true
param enableSoftDelete bool = true
param softDeleteRetentionInDays int = 7
param networkAccessPolicies object
param publicNetworkAccess string = 'Enabled'
param solution string
param deploymentTags object = {
  Environment: environment
  SubscriptionId: subscription().subscriptionId
  SubscriptionName: subscription().displayName
}

resource newRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroupName
  scope: subscription()
}

output existingRGName string = newRG.name
output keyvaultNameOutput string = keyVaultName

module keyVault 'br/public:avm/res/key-vault/vault:0.13.3' = {
  name: '${keyVaultName}${uniqueString(keyVaultName)}'
  params: {
    location: rgLocation
    name: '${toLower(keyVaultName)}-${toLower(environment)}'
    enableVaultForDeployment: enabledForDeployment
    enableVaultForDiskEncryption: enabledForDiskEncryption
    enableVaultForTemplateDeployment: enabledForTemplateDeployment
    tags: union(deploymentTags, tags)
    enablePurgeProtection: enablePurgeProtection
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    networkAcls: networkAccessPolicies
    publicNetworkAccess: publicNetworkAccess
    // accessPolicies: keyVaultAccessObject    
    enableRbacAuthorization: true
    roleAssignments: keyVaultAccessObject
    createMode: 'default'
  }
  scope: resourceGroup(newRG.name)
}

output keyVaultName string = keyVault.outputs.name
output keyVaultUrl string = keyVault.outputs.uri
output keyVaultId string = keyVault.outputs.resourceId

module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.15.0' = {
  name: '${solution}-law-${environment}'
  params: {
    location: rgLocation
    name: '${toLower(solution)}-law-${toLower(environment)}'
    tags: union(deploymentTags, tags)
  }
  scope: resourceGroup(newRG.name)
}

output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.outputs.name
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.outputs.resourceId
