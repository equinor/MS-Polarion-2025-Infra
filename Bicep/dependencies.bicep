// targetScope = 'resourceGroup'
param rgName string
param rgLocation string
param subscriptionId string = subscription().subscriptionId
param subscriptionName string = subscription().displayName
param githubRepository object
param solution string
param publicNetworkAccess string
param enableSoftDelete bool
param enablePurgeProtection bool
param networkAccessPolicies object
param keyVaultAccessObject array

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

@description('Please enter tags to identify your resources, cost allocation unit, contact person, solution etc as shown below.')
param deploymentTags object = {
  Environment: environment
  SubscriptionId: subscriptionId
  SubscriptionName: subscriptionName
}

resource newRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: '${rgName}-${environment}'
  scope: subscription()
}

// Deploy Keyvault and Credentials to be used in the solution
@description('Specifies the name of the key vault.')
param keyVaultName string // = '${solution}-kv-${environment}'

@description('Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.')
param enabledForDeployment bool

@description('Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.')
param enabledForDiskEncryption bool

@description('Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
param enabledForTemplateDeployment bool

// @description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
// param tenantId string = subscription().tenantId

module keyVault 'br/public:avm/res/key-vault/vault:0.13.3' = {
  name: '${keyVaultName}${uniqueString(keyVaultName)}'
  params: {
    location: rgLocation
    name: toLower(keyVaultName)
    enableVaultForDeployment: enabledForDeployment
    enableVaultForDiskEncryption: enabledForDiskEncryption
    enableVaultForTemplateDeployment: enabledForTemplateDeployment
    tags: union(deploymentTags, tags, githubRepository)
    enablePurgeProtection: enablePurgeProtection
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: 7
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
