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
    solution: solution
  }
  scope: resourceGroup(newRG.name)
  dependsOn: []
}

output dependencyDeploymentOutput object = dependencyDeployment.outputs
