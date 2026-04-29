targetScope = 'subscription'

//////////////////////
// Needed Parameters 
//////////////////////

param rgLocation string
param subscriptionId string = subscription().subscriptionId
param subscriptionName string = subscription().displayName
param githubRepository object
param resourceGroupName string
param keyVaultName string
param solution string
param keyVaultAccessObject array
param subscriptionPrefix string
param networkAccessPolicies object
@description('Subnet configuration for workload placement.')
param subnetConfig object
param skuName string
param storageAccountName string
param runner string
@description('Controls whether the GitHub runner IP is temporarily allowed in Key Vault network ACLs during bootstrap.')
param includeRunnerAccess bool = true
@description('Controls whether Key Vault purge protection is enabled.')
param enablePurgeProtection bool = false
param publicNetworkAccessLogAnalytics string = 'Disabled'
param vmAdminPasswordSecretNameSuffix string = '-localadmin-password'

@secure()
@description('Initial Key Vault secrets to seed on first deployment. Object format: { "secret-name": "secret-value" }.')
param initialKeyVaultSecrets object = {}

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
  'demo'
  'DEMO'
])
param environment string
param tags object

@description('Please enter tags to identify your resources, cost allocation unit, contact person, solution etc as shown below.')
param deploymentTags object = {
  Environment: environment
  SubscriptionId: subscriptionId
  SubscriptionName: subscriptionName
}

module newRG 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: '${subscriptionPrefix}-${resourceGroupName}-${environment}'
  params: {
    location: rgLocation
    name: toUpper('${subscriptionPrefix}-${resourceGroupName}-${environment}')
    tags: union(deploymentTags, tags, githubRepository)
  }
  dependsOn: []
}

output newRGName string = newRG.outputs.name

// Recovery Services Vault RG
module recoveryServicesVaultRG 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: '${subscriptionPrefix}-${resourceGroupName}-${environment}-rsv'
  params: {
    location: rgLocation
    name: toUpper('${subscriptionPrefix}-${resourceGroupName}-${environment}-rsv')
    tags: union(deploymentTags, tags, githubRepository)
  }
  dependsOn: []
}

output recoveryServicesVaultRGName string = recoveryServicesVaultRG.outputs.name

// Deploy Dependencies Below

module dependencyDeployment './modules/dependencies.bicep' = {
  name: 'dependencyDeployment'
  params: {
    resourceGroupName: newRG.outputs.name
    rgLocation: rgLocation
    environment: environment
    keyVaultAccessObject: keyVaultAccessObject
    keyVaultName: keyVaultName
    tags: tags
    networkAccessPolicies: networkAccessPolicies
    subnetConfig: subnetConfig
    solution: solution
    skuName: skuName
    storageAccountName: storageAccountName
    runner: runner
    includeRunnerAccess: includeRunnerAccess
    enablePurgeProtection: enablePurgeProtection
    publicNetworkAccessLogAnalytics: publicNetworkAccessLogAnalytics
    recoveryServicesVaultRGName: recoveryServicesVaultRG.outputs.name
  }
  scope: resourceGroup(newRG.name)
  dependsOn: []
}

output dependencyDeploymentOutput object = dependencyDeployment.outputs

// module keyVaultResources './modules/keyvault-resources.bicep' = {
//   name: 'keyVaultResources'
//   params: {
//     keyVaultName: dependencyDeployment.outputs.keyVaultName
//     credentials: initialKeyVaultSecrets
//   }
//   scope: resourceGroup(newRG.name)
// }

// module mainDeployment './modules/main-deployment.bicep' = {
//   name: 'mainDeployment'
//   params: {
//     environment: environment
//     subnetConfig: subnetConfig
//     keyVaultName: dependencyDeployment.outputs.keyVaultName
//     vmAdminPasswordSecretNameSuffix: vmAdminPasswordSecretNameSuffix
//     tags: tags
//   }
//   scope: resourceGroup(newRG.name)
// }

// output mainDeploymentOutput object = {
//   deployedVmNames: mainDeployment.outputs.deployedVmNames
//   deployedVmIds: mainDeployment.outputs.deployedVmIds
// }
