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
param enablePurgeProtection bool = false
param enableSoftDelete bool = true
param softDeleteRetentionInDays int = 7
param networkAccessPolicies object
param publicNetworkAccess string = 'Enabled'
param publicNetworkAccessLogAnalytics string
param solution string
param skuName string
param storageAccountName string

param deploymentTags object = {
  Environment: environment
  SubscriptionId: subscription().subscriptionId
  SubscriptionName: subscription().displayName
}

resource newRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroupName
  scope: subscription()
}

param recoveryServicesVaultRGName string

resource recoveryServicesVaultRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: recoveryServicesVaultRGName
  scope: subscription()
}

param runner string

output existingRGName string = newRG.name
output keyvaultNameOutput string = keyVaultName

var networkAccessPoliciesWithRunner = union(networkAccessPolicies, {
  ipRules: concat(networkAccessPolicies.?ipRules ?? [], [
    {
      value: runner
      action: 'Allow'
    }
  ])
})

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
    networkAcls: networkAccessPoliciesWithRunner
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
    publicNetworkAccessForIngestion: publicNetworkAccessLogAnalytics
    publicNetworkAccessForQuery: publicNetworkAccessLogAnalytics
  }
  scope: resourceGroup(newRG.name)
}

output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.outputs.name
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.outputs.resourceId

module storageAccount 'br/public:avm/res/storage/storage-account:0.32.0' = {
  name: 'st${solution}${environment}'
  params: {
    location: rgLocation
    name: toLower('${storageAccountName}${environment}')
    skuName: skuName
    publicNetworkAccess: publicNetworkAccess
    tags: union(deploymentTags, tags)
    networkAcls: networkAccessPolicies
  }
  dependsOn: []
  scope: resourceGroup(newRG.name)
}

// param enableSoftDelete bool = false
// param softDeleteRetentionInDays int = 7

module recoveryServicesVault 'br/public:avm/res/recovery-services/vault:0.11.1' = {
  name: '${solution}-rsv-${environment}'
  params: {
    location: rgLocation
    name: '${toLower(solution)}-rsv-${toLower(environment)}'
    tags: union(deploymentTags, tags)
    publicNetworkAccess: publicNetworkAccess
    immutabilitySettingState: 'Unlocked'
    softDeleteSettings: {
      softDeleteRetentionPeriodInDays: softDeleteRetentionInDays
      softDeleteState: 'Disabled'
      enhancedSecurityState: 'Disabled'
    }
  }
  // networkAcls: networkAccessPolicies
  dependsOn: []
  scope: resourceGroup(recoveryServicesVaultRG.name)
}
