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
@description('Subnet configuration passed from the environment parameter file.')
param subnetConfig object
param publicNetworkAccess string = 'Enabled'
param publicNetworkAccessLogAnalytics string
param solution string
param skuName string
param storageAccountName string
@description('Resource group containing a shared NSG that should receive Polarion security rules.')
param sharedNetworkResourceGroupName string = 'S499-NOE-Network'
@description('Shared NSG name that should receive Polarion security rules.')
param sharedNetworkSecurityGroupName string = 'S499-NOE-snet-compute-polarion-dev-nsg'
@description('Private IP addresses for VMs that should receive inbound deny rules on port 3389. Leave empty to deploy an NSG without custom rules.')
param vmPrivateIpAddresses array = []
@description('VM backup targets used to associate virtual machines to the VMPolicyEnhanced backup policy.')
param vmBackupItems array = []
@description('Controls whether the GitHub runner IP is appended to Key Vault IP rules.')
param includeRunnerAccess bool = true

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
output subnetConfigOutput object = subnetConfig

var runnerIpRules = includeRunnerAccess
  ? [
      {
        value: runner
        action: 'Allow'
      }
    ]
  : []

var networkAccessPoliciesWithRunner = union(networkAccessPolicies, {
  ipRules: concat(networkAccessPolicies.?ipRules ?? [], runnerIpRules)
  virtualNetworkRules: [
    {
      id: subnetConfig.compute
      action: 'Allow'
      ignoreMissingVnetServiceEndpoint: true
    }
  ]
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
    privateEndpoints: [
      {
        subnetResourceId: subnetConfig.privateEndpoints
        service: 'vault'
      }
    ]
    createMode: 'default'
  }
  scope: resourceGroup(newRG.name)
}

output keyVaultName string = keyVault.outputs.name
output keyVaultUrl string = keyVault.outputs.uri
output keyVaultId string = keyVault.outputs.resourceId
output keyVaultPrivateEndpoints array = keyVault.outputs.privateEndpoints

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

var nsgBaseSecurityRules = [
  {
    name: 'Allow-LDAP-Kerberos-Any-Any'
    properties: {
      description: 'Allow inbound TCP 88 (Kerberos) and 389 (LDAP) from Any to Any'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRanges: [
        '88'
        '389'
      ]
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 2890
      direction: 'Inbound'
    }
  }
  {
    name: 'Allow-443-6516-5433-VirtualNetwork'
    properties: {
      description: 'Allow inbound TCP 443, 6516, and 5433 from VirtualNetwork to VirtualNetwork'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRanges: [
        '443'
        '6516'
        '5433'
      ]
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 2891
      direction: 'Inbound'
    }
  }
]

var nsgRdpSecurityRules = length(vmPrivateIpAddresses) > 0
  ? [
      {
        name: 'Allow-RDP-3389-VirtualNetwork-All-VMs'
        properties: {
          description: 'Allow inbound TCP 3389 traffic from VirtualNetwork to all configured VM private IPs'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefixes: vmPrivateIpAddresses
          access: 'Allow'
          priority: 2990
          direction: 'Inbound'
        }
      }
      {
        name: 'Deny-RDP-3389-All-VMs'
        properties: {
          description: 'Deny inbound TCP 3389 traffic to all configured VM private IPs'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefixes: vmPrivateIpAddresses
          access: 'Deny'
          priority: 3000
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_Web_Outbound'
        properties: {
          description: 'Allow outbound TCP 80 and 443 traffic to the internet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '80'
            '443'
          ]
          sourceAddressPrefix: '*'
          destinationAddressPrefixes: vmPrivateIpAddresses
          access: 'Allow'
          priority: 3000
          direction: 'Outbound'
        }
      }
    ]
  : []

var nsgSecurityRules = concat(nsgBaseSecurityRules, nsgRdpSecurityRules)

resource sharedNetworkRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: sharedNetworkResourceGroupName
  scope: subscription()
}

module sharedNetworkSecurityGroupRules 'shared-nsg-security-rules.bicep' = {
  name: '${solution}-shared-nsg-rules-${environment}'
  params: {
    networkSecurityGroupName: sharedNetworkSecurityGroupName
    securityRules: nsgSecurityRules
  }
  scope: resourceGroup(sharedNetworkRG.name)
}

module networkSecurityGroup 'br/public:avm/res/network/network-security-group:0.4.0' = {
  name: '${solution}-nsg-${environment}'
  params: {
    location: rgLocation
    name: '${toLower(solution)}-nsg-${toLower(environment)}'
    tags: union(deploymentTags, tags)
    securityRules: nsgSecurityRules
  }
  scope: resourceGroup(newRG.name)
}

output networkSecurityGroupName string = networkSecurityGroup.outputs.name
output networkSecurityGroupId string = networkSecurityGroup.outputs.resourceId

// param enableSoftDelete bool = false
// param softDeleteRetentionInDays int = 7

var backupPoliciesRaw = loadJsonContent('../CommonFiles/backupPolicies.json')
var backupPolicies = [
  for policy in backupPoliciesRaw: {
    name: policy.name
    properties: policy.properties
  }
]

var recoveryServicesProtectedItems = [
  for vm in vmBackupItems: {
    name: 'VM;iaasvmcontainerv2;${resourceGroupName};${vm.vmName}'
    policyName: 'VMPolicyEnhanced'
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    protectionContainerName: 'IaasVMContainer;iaasvmcontainerv2;${resourceGroupName};${vm.vmName}'
    sourceResourceId: vm.sourceResourceId
  }
]

module recoveryServicesVault 'br/public:avm/res/recovery-services/vault:0.11.1' = {
  name: '${solution}-rsv-${environment}'
  params: {
    location: rgLocation
    name: '${toLower(solution)}-rsv-${toLower(environment)}'
    tags: union(deploymentTags, tags)
    publicNetworkAccess: publicNetworkAccess
    privateEndpoints: [
      {
        subnetResourceId: subnetConfig.recoveryServicesVault
      }
    ]
    immutabilitySettingState: 'Disabled'
    backupPolicies: backupPolicies
    protectedItems: recoveryServicesProtectedItems
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

module recoveryServicesVaultNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.4.0' = {
  name: '${solution}-rsv-nsg-${environment}'
  params: {
    location: rgLocation
    name: '${toLower(solution)}-rsv-nsg-${toLower(environment)}'
    tags: union(deploymentTags, tags)
  }
  scope: resourceGroup(recoveryServicesVaultRG.name)
}

output recoveryServicesVaultNetworkSecurityGroupName string = recoveryServicesVaultNetworkSecurityGroup.outputs.name
output recoveryServicesVaultNetworkSecurityGroupId string = recoveryServicesVaultNetworkSecurityGroup.outputs.resourceId
