targetScope = 'subscription'

param tenantId string
param subscriptionId string
param AZAPPL_S499_OWNER string = ''
param iac_objectid string = ''
param iac_clientid string = ''
param Deploy_iac_objectID string = ''
param S499_MS_Classic_Omnia_Contributor string = ''
param S499_MS_CLASSIC_OMNIA_OWNER string = ''

@description('Azure ClientID and ObjectID')
param IAC_OBJECT_ID string = ''

@description('Set basetime to UTC')
param baseTime string = utcNow('u')

@description('set basetime to Norway(UTC+1) in string format')
param NorwayBaseTimeString string = dateTimeAdd(baseTime, 'PT1H')

@description('Converts timeformat baseTime from string to int and adds 1 hour to set NorwayBaseTime ')
param NorwayBaseTime int = dateTimeToEpoch(dateTimeAdd(baseTime, 'PT1H'))

@description('Adds 29 days to NorwayBaseTimeAdd1Year')
param NorwayBaseTimeAdd29Days int = dateTimeToEpoch(dateTimeAdd(NorwayBaseTimeString, 'P29D'))

@allowed([
  'DEV'
  'PROD'
  'QA'
])
param environmentType string

@allowed([
  'dev'
  'prod'
  'qa'
])
param environmentTypeLowerCase string

@description('Optional. Tags to be set on the resources')
param tags object = {}

@description('Optional. Default deployment location')
param location string = deployment().location

@description('Required. Name of the ResourceGroup')
param resourceGroupName string

module newRg '../../../templates/resources/resource-group/main.bicep' = {
  name: '${uniqueString(deployment().name, resourceGroupName)}-rg-${resourceGroupName}'
  params: {
    location: location
    name: resourceGroupName
    tags: tags
  }
}

@description('Optional. Name of the Key Vault. If missing, will default to subscription prefix, location and add -keyvault string to the resource name.')
param kvName string
param enableSoftDelete bool = true

@description('Optional. [Omnia Classic Policy]. softDelete data retention days. It accepts >=7 and <=90.')
param softDeleteRetentionInDays int = 90

@description('Optional. Property that controls how data actions are authorized. When true, the key vault will use Role Based Access Control (RBAC) for authorization of data actions, and the access policies specified in vault properties will be ignored (warning: this is a preview feature). When false, the key vault will use the access policies specified in vault properties, and any policy stored on Azure Resource Manager will be ignored. If null or not specified, the vault is created with the default value of false. Note that management actions are always authorized with RBAC.')
@allowed([
  false
  true
])
param enableRbacAuthorization bool = false

@description('Optional. Specifies if the vault is enabled for deployment by script or compute')
@allowed([
  false
  true
])
param enableVaultForDeployment bool = true

@description('Optional. Specifies if the vault is enabled for a template deployment')
@allowed([
  false
  true
])
param enableVaultForTemplateDeployment bool = true

@description('Optional. Specifies if the azure platform has access to the vault for enabling disk encryption scenarios.')
@allowed([
  false
  true
])
param enableVaultForDiskEncryption bool = false

@description('Optional. [Omnia Classic Policy]. Provide \'true\' to enable Key Vault\'s purge protection feature.')
param enableKvPurgeProtection bool = true

@description('Optional. Specifies the SKU for the vault')
param keyVaultSku string = 'standard'

@description('Optional. Name of the Virtual Network. Name will be set by subscription and location + -vnet')
param vnetName string = '${subscriptionPrefix}-${locationShortName['${location}']}-vnet'

@description('Optional. Name of the Virtual Network ResourceGroup.  Name will be set by subscription and location + -network')
param vnetResourcegroup string = '${subscriptionPrefix}-${locationShortName['${location}']}-network'

@description('Optional. Name of the Subnet. Name will be set by subscription, location and subnetsuffix from param file')
param subNetName string = '${subscriptionPrefix}-${locationShortName['${deployment().location}']}-${subnetSuffix}'
param NewsubNetName string = '${subscriptionPrefix}-${locationShortName['${deployment().location}']}-${NewsubnetSuffix}'

@description('Optional. Suffix of the subnet.')
param subnetSuffix string = 'subnet'
param NewsubnetSuffix string = 'polarion-${environmentTypeLowerCase}-subnet'
param subnetId string = '/subscriptions/${subscriptionId}/resourceGroups/${vnetResourcegroup}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${subNetName}'
param NewsubnetId string = '/subscriptions/${subscriptionId}/resourceGroups/${vnetResourcegroup}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${NewsubNetName}'
param subscriptionPrefix string = '${first(split(subscription().displayName, '-'))}'
param locationShortName object = {
  brazilsouth: 'BS'
  northcentralus: 'NCUS'
  northeurope: 'NE'
  norwayeast: 'NOE'
  norwaywest: 'NOW'
  southcentralus: 'SCUS'
  westeurope: 'WE'
}

@description('Ip address of Github action runner')
param runner string

var networkAcls = {
  bypass: 'AzureServices'
  defaultAction: 'Deny'
  virtualNetworkRules: [
    {
      Id: subnetId
      ignoreMissingVnetServiceEndpoint: true
    }
  ]
}

module keyVault '../../../templates/key-vault/vault/main.bicep' = {
  name: '${uniqueString(deployment().name, '${kvName}-${environmentType}')}-kv-${kvName}-${environmentType}'
  scope: resourceGroup(resourceGroupName)
  params: {
    enablePurgeProtection: enableKvPurgeProtection
    enableRbacAuthorization: enableRbacAuthorization
    enableSoftDelete: enableSoftDelete
    enableVaultForDeployment: enableVaultForDeployment
    enableVaultForDiskEncryption: enableVaultForDiskEncryption
    enableVaultForTemplateDeployment: enableVaultForTemplateDeployment
    location: location
    name: '${kvName}-${environmentType}'
    networkAcls: networkAcls
    publicNetworkAccess: 'Enabled'
    secrets: {}
    softDeleteRetentionInDays: softDeleteRetentionInDays
    tags: tags
    vaultSku: keyVaultSku
    accessPolicies: [
      {
        objectId: S499_MS_CLASSIC_OMNIA_OWNER
        tenantId: tenantId
        permissions: {
          certificates: [
            'Backup'
            'Create'
            'Delete'
            'DeleteIssuers'
            'Get'
            'GetIssuers'
            'Import'
            'List'
            'ListIssuers'
            'ManageContacts'
            'ManageIssuers'
            'Purge'
            'Recover'
            'Restore'
            'SetIssuers'
            'Update'
          ]
          keys: [
            'Backup'
            'Create'
            'Decrypt'
            'Delete'
            'Encrypt'
            'Get'
            'GetRotationPolicy'
            'Import'
            'List'
            'Purge'
            'Recover'
            'Release'
            'Restore'
            'Rotate'
            'SetRotationPolicy'
            'Sign'
            'UnwrapKey'
            'Update'
            'Verify'
            'WrapKey'
          ]
          secrets: ['Get', 'List', 'Set', 'Delete', 'Recover', 'Backup', 'Restore', 'Purge']
        }
      }
      {
        objectId: IAC_OBJECT_ID
        tenantId: tenantId
        permissions: {
          certificates: [
            'Backup'
            'Create'
            'Delete'
            'DeleteIssuers'
            'Get'
            'GetIssuers'
            'Import'
            'List'
            'ListIssuers'
            'ManageContacts'
            'ManageIssuers'
            'Purge'
            'Recover'
            'Restore'
            'SetIssuers'
            'Update'
          ]
          keys: [
            'Backup'
            'Create'
            'Decrypt'
            'Delete'
            'Encrypt'
            'Get'
            'GetRotationPolicy'
            'Import'
            'List'
            'Purge'
            'Recover'
            'Release'
            'Restore'
            'Rotate'
            'SetRotationPolicy'
            'Sign'
            'UnwrapKey'
            'Update'
            'Verify'
            'WrapKey'
          ]
          secrets: ['Get', 'List', 'Set', 'Delete', 'Recover', 'Backup', 'Restore', 'Purge']
        }
      }
      {
        objectId: S499_MS_Classic_Omnia_Contributor
        tenantId: tenantId
        permissions: {
          certificates: ['Get', 'List']
          keys: ['Get', 'List']
          secrets: ['Get', 'List']
        }
      }
    ]
  }
  dependsOn: [
    newRg
  ]
}

module keyvaultPE '../../../templates/network/private-endpoint/main.bicep' = {
  name: '${uniqueString(deployment().name, kvName)}-kv-PE-${kvName}-${environmentType}'
  scope: resourceGroup(resourceGroupName)
  params: {
    customNetworkInterfaceName: '${kvName}-${environmentType}-PE.nic'
    groupIds: ['vault']
    location: location
    name: '${kvName}-${environmentType}-PE.nic'
    serviceResourceId: keyVault.outputs.resourceId
    subnetResourceId: subnetId
    tags: tags
  }
  dependsOn: [
    keyVault
  ]
}

param UserAssignedManagedIdentity string

module managedIdentity '../../../templates/managed-identity/user-assigned-identity/main.bicep' = {
  name: '${UserAssignedManagedIdentity}-${environmentType}'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    name: '${UserAssignedManagedIdentity}-${environmentType}'
    tags: tags
  }
  dependsOn: [
    newRg
  ]
}
