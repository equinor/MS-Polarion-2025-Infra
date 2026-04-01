targetScope = 'subscription'

//////////////////////
// Needed Parameters 
//////////////////////

param rgName string
param rgLocation string
param subscriptionId string = subscription().subscriptionId
param subscriptionName string = subscription().displayName
param githubRepository object
param resourceGroupName string
param keyvaultName string = '${resourceGroupName}-kv-${environment}'

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
  name: '${rgName}-${environment}'
  params: {
    location: rgLocation
    name: toLower('${rgName}-${environment}')
    tags: union(deploymentTags, tags, githubRepository)
  }
  dependsOn: []
}

output rgNameLow string = toLower('${newRG.outputs.name}')
output rgName string = newRG.outputs.name

// Deploy Dependencies Below
