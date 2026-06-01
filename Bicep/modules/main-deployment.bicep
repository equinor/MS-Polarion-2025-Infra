targetScope = 'resourceGroup'

@description('Environment short name, e.g. DEV, TEST, PRD.')
param environment string

@description('Subnet configuration object from the main parameter file. compute should point to the VM subnet resource ID.')
param subnetConfig object

@description('Key Vault name containing VM admin password secrets.')
param keyVaultName string

@description('Suffix appended to each VM name to resolve the admin password secret. Secret name format: <vmName><suffix>.')
param vmAdminPasswordSecretNameSuffix string = '-localadmin-password'

@description('Fallback number of VMs to deploy when vmConfigurations is empty.')
@minValue(1)
@maxValue(99)
param vmCount int = 4

@description('Virtual machine size.')
param vmSize string = 'Standard_D4s_v5'

@description('Base name aligned with naming standard. Resulting names become <base><NN><Environment>, for example S499POLWS01Dev.')
param vmNameBase string = 'S499POLWS'

@description('Solution name used in resource naming conventions.')
param solution string

@description('Resource group containing the shared NSG that should receive VM-derived rules.')
param sharedNetworkResourceGroupName string

@description('Shared NSG name that should receive VM-derived rules.')
param sharedNetworkSecurityGroupName string

@description('Per-VM configuration array. Each object should contain: vmSize, vmImageSku, osDiskSizeGB, hasDataDisk, dataDiskSizeGB, dataDiskStorageType, privateIPAddress.')
param vmConfigurations array = []

@description('Resource tags applied to all VMs and child resources.')
param tags object = {}

@description('Controls whether the Windows Admin Center VM extension is deployed on each VM.')
param enableWindowsAdminCenterExtension bool = true

param subscriptionId string = subscription().subscriptionId
param subscriptionPrefix string

@description('Settings passed to the Windows Admin Center extension.')
param windowsAdminCenterExtensionSettings object = {
  port: '6516'
  salt: ''
}

@description('Start date/time for the monthly maintenance window in yyyy-MM-dd HH:mm format (Azure Maintenance API format).')
param maintenanceWindowStartDateTime string = utcNow('yyyy-MM-dd HH:mm')

@description('Windows time zone name used by the monthly maintenance window.')
param maintenanceWindowTimeZone string = 'W. Europe Standard Time'

@description('Secret name in S499-FkeyADJoin Key Vault containing the AD join account password.')
param domainJoinPasswordSecretName string = 'domainJoinKey'

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: 'S499-FkeyADJoin'
  scope: resourceGroup(subscriptionId, 'S499-ADKeyJoin')
}

output kvName string = kv.name

var extensionDomainJoinConfig = {
  enabled: true
  settings: {
    Name: 'statoil.net'
    OUPath: 'OU=${subscriptionPrefix},OU=Omnia Classic,OU=Cloud Servers,OU=Servers,DC=statoil,DC=net'
    // JsonADDomainExtension authentication is most reliable with DOMAIN\\user format.
    User: 'STATOIL\\f_ocdj_${subscriptionPrefix}'
    Restart: true
    Options: 3
  }
}

var environmentSuffix = '${toUpper(substring(environment, 0, 1))}${toLower(substring(environment, 1))}'
var effectiveVmCount = length(vmConfigurations) > 0 ? length(vmConfigurations) : vmCount
var vmPrivateIpAddresses = [for vm in vmInstances: vm.config.privateIPAddress]
var recoveryServicesVaultResourceGroupName = '${resourceGroup().name}-RSV'
var recoveryServicesVaultName = '${toLower(solution)}-rsv-${toLower(environment)}'
var workloadNetworkSecurityGroupName = 'ms-polarion-2025-nsg-${toLower(environment)}'

module monthlyMaintenanceConfiguration 'br/public:avm/res/maintenance/maintenance-configuration:0.4.0' = {
  name: 'monthlyMaintenanceConfiguration'
  params: {
    name: 'Monthly-${resourceGroup().name}'
    location: resourceGroup().location
    extensionProperties: {
      InGuestPatchMode: 'User'
    }
    installPatches: {
      rebootSetting: 'Never'
      windowsParameters: {
        classificationsToInclude: [
          'Critical'
          'Security'
        ]
      }
    }
    maintenanceScope: 'InGuestPatch'
    maintenanceWindow: {
      duration: '04:00'
      expirationDateTime: '9999-12-31 23:59'
      recurEvery: 'Month Second Sunday'
      startDateTime: maintenanceWindowStartDateTime
      timeZone: maintenanceWindowTimeZone
    }
    namespace: 'Microsoft.Maintenance'
    visibility: 'Custom'
    tags: tags
  }
}

var vmInstances = [
  for i in range(0, effectiveVmCount): {
    index: i + 1
    name: '${toUpper(vmNameBase)}${padLeft(string(i + 1), 2, '0')}${environmentSuffix}'
    config: union(
      {
        vmSize: vmSize
        vmImageSku: '2025-datacenter-g2'
        osDiskSizeGB: 512
        hasDataDisk: false
        dataDiskSizeGB: 256
        dataDiskStorageType: 'Premium_LRS'
        privateIPAddress: '10.83.157.${52 + i}'
      },
      length(vmConfigurations) > i ? vmConfigurations[i] : {}
    )
  }
]

module windowsVm 'br/public:avm/res/compute/virtual-machine:0.22.0' = [
  for vm in vmInstances: {
    name: 'vm-${toLower(vm.name)}'
    params: {
      provisionVMAgent: true
      maintenanceConfigurationResourceId: monthlyMaintenanceConfiguration.outputs.resourceId
      patchMode: 'AutomaticByPlatform'
      patchAssessmentMode: 'AutomaticByPlatform'
      enableHotpatching: false
      rebootSetting: 'Never'
      availabilityZone: -1
      name: vm.name
      computerName: substring(vm.name, 0, min(length(vm.name), 15))
      osType: 'Windows'
      vmSize: vm.config.vmSize
      adminUsername: 'localAdmin'
      adminPassword: keyVault.getSecret('${vmNameBase}${padLeft(string(vm.index), 2, '0')}${toUpper(environment)}${vmAdminPasswordSecretNameSuffix}')
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: vm.config.vmImageSku
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        diskSizeGB: vm.config.osDiskSizeGB
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: vm.config.hasDataDisk
        ? [
            {
              caching: 'ReadWrite'
              createOption: 'Empty'
              diskSizeGB: vm.config.dataDiskSizeGB
              lun: 0
              managedDisk: {
                storageAccountType: vm.config.dataDiskStorageType
              }
            }
          ]
        : []
      nicConfigurations: [
        {
          nicSuffix: '-nic-01'
          networkSecurityGroupResourceId: workloadNetworkSecurityGroup.outputs.resourceId
          ipConfigurations: [
            {
              name: 'ipconfig01'
              subnetResourceId: subnetConfig.compute
              privateIPAddress: vm.config.privateIPAddress
              privateIPAllocationMethod: 'Static'
            }
          ]
        }
      ]
      tags: tags
    }
  }
]

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
      priority: 1000
      direction: 'Inbound'
    }
  }
  {
    name: 'Allow-VirtualNetwork-Inbound'
    properties: {
      description: 'Allow inbound TCP from VirtualNetwork to VirtualNetwork'
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
      priority: 1001
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
          priority: 1002
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
          priority: 4049
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_Web_Outbound'
        properties: {
          description: 'Allow outbound TCP 80 and 443 traffic from VM private IPs to the internet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '80'
            '443'
          ]
          sourceAddressPrefixes: vmPrivateIpAddresses
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 1004
          direction: 'Outbound'
        }
      }
      {
        name: 'OmniaDenyAllInbound'
        properties: {
          description: 'Deny all inbound traffic from VM private IPs to the internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4050
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_Azure_LoadBalancer_Inbound'
        properties: {
          description: 'Allow inbound traffic from Azure Load Balancer'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 1005
          direction: 'Inbound'
        }
      }
      {
        name: 'Polarion2025_AD_Allow_VN'
        properties: {
          description: 'Allow AD connection from Virtual Network'
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [
            '53'
            '389'
            '88'
            '135-139'
            '445'
            '636'
          ]
          access: 'Allow'
          priority: 1006
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowEntraIdOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefixes: vmPrivateIpAddresses
          destinationAddressPrefix: 'AzureActiveDirectory'
          access: 'Allow'
          priority: 1008
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowEntraIdInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'AzureActiveDirectory'
          destinationAddressPrefixes: vmPrivateIpAddresses
          access: 'Allow'
          priority: 1009
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
        }
      }
      {
        name: 'AllowAllPortsInternalInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefixes: vmPrivateIpAddresses
          destinationAddressPrefixes: vmPrivateIpAddresses
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
        }
      }
      {
        name: 'AllowAllPortsInternalOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefixes: vmPrivateIpAddresses
          destinationAddressPrefixes: vmPrivateIpAddresses
          access: 'Allow'
          priority: 1011
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
        }
      }
    ]
  : []

var nsgSecurityRules = concat(nsgBaseSecurityRules, nsgRdpSecurityRules)

module workloadNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.4.0' = {
  name: '${solution}-nsg-${environment}'
  params: {
    location: resourceGroup().location
    name: workloadNetworkSecurityGroupName
    tags: tags
    securityRules: nsgSecurityRules
  }
}

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

resource recoveryServicesVaultRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: recoveryServicesVaultResourceGroupName
  scope: subscription()
}

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2023-06-01' existing = {
  name: recoveryServicesVaultName
  scope: resourceGroup(recoveryServicesVaultRG.name)
}

var recoveryServicesProtectedItemInputs = [
  for (vm, i) in vmInstances: {
    vmName: vm.name
    sourceResourceId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachines/${vm.name}'
  }
]

module recoveryServicesProtectedItems 'recovery-services-protected-items.bicep' = {
  name: '${solution}-rsv-protected-items-${environment}'
  params: {
    recoveryServicesVaultName: recoveryServicesVault.name
    workloadResourceGroupName: resourceGroup().name
    protectedItems: recoveryServicesProtectedItemInputs
  }
  scope: resourceGroup(recoveryServicesVaultRG.name)
  dependsOn: [
    windowsVm
  ]
}

resource windowsAdminCenterExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = [
  for (vm, i) in vmInstances: if (enableWindowsAdminCenterExtension) {
    name: '${vm.name}/AdminCenter'
    location: resourceGroup().location
    properties: {
      publisher: 'Microsoft.AdminCenter'
      type: 'AdminCenter'
      typeHandlerVersion: '0.0'
      autoUpgradeMinorVersion: true
      enableAutomaticUpgrade: true
      settings: windowsAdminCenterExtensionSettings
    }
    dependsOn: [
      windowsVm[i]
    ]
  }
]

module domainJoinExtension 'domain-join-extension.bicep' = [
  for (vm, i) in vmInstances: if (extensionDomainJoinConfig.enabled) {
    name: '${vm.name}-domainJoin'
    params: {
      vmName: vm.name
      location: resourceGroup().location
      domainJoinSettings: extensionDomainJoinConfig.settings
      domainJoinKey: kv.getSecret(domainJoinPasswordSecretName)
    }
    dependsOn: [
      windowsVm[i]
    ]
  }
]

output deployedVmNames array = [for vm in vmInstances: vm.name]
output deployedVmIds array = [for (vm, i) in vmInstances: windowsVm[i].outputs.resourceId]
output deployedVmPrivateIpAddresses array = [for vm in vmInstances: vm.config.privateIPAddress]
output maintenanceConfigurationName string = monthlyMaintenanceConfiguration.outputs.name
output maintenanceConfigurationResourceId string = monthlyMaintenanceConfiguration.outputs.resourceId
