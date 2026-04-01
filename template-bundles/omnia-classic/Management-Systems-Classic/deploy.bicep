targetScope = 'subscription'

@description('Required. Name of the TenantId')
param tenantId string
param subscriptionId string

@description('Required. Name of the ResourceGroup')
param resourceGroupName string
param AZAPPL_S499_OWNER string
param iac_clientid string = ''
param S499_MS_Classic_Omnia_Contributor string

@description('Set basetime to UTC')
param baseTime string = utcNow('u')
param vmTags object

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
param UserAssignedManagedIdentity string
param UserAssignedIdentitiesClient_ID string
param userAssignedManagedIdentityID string = '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${UserAssignedManagedIdentity}'
param ApplicationSecGroupName string = '${subscriptionPrefix}-MS-POLARION-ASG-${environmentType}'
param AplicationSecurityGroupID string = '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Network/applicationSecurityGroups/${ApplicationSecGroupName}'
param resourceGroupNamePolarion string = '${subscriptionPrefix}-MS-POLARION-${environmentType}'
param PolarionApplicationSecGroupName string = '${subscriptionPrefix}-MS-POLARION-ASG-${environmentType}'
param PolarionAplicationSecurityGroupID string = '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupNamePolarion}/providers/Microsoft.Network/applicationSecurityGroups/${PolarionApplicationSecGroupName}'

@description('Remote Gateway servers for Equinor RDP')
param sourceAddressPrefixesRDGW array = [
  '10.73.200.75'
  '10.74.143.75'
  '10.80.0.159'
  '10.80.128.150'
]

@description('Bastion Subnet S035-NOEB1-vnet')
param AzureBastionSubnet string = '10.73.207.0/25'
param PolarionNSGs array = [
  {
    name: 'AllowLDAP'
    properties: {
      access: 'Allow'
      destinationAddressPrefix: '*'
      destinationPortRange: '389'
      direction: 'Inbound'
      priority: 101
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
    }
  }
  {
    name: 'AllowKerberos'
    properties: {
      access: 'Allow'
      destinationAddressPrefix: '*'
      destinationPortRange: '88'
      direction: 'Inbound'
      priority: 102
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
    }
  }
  {
    name: 'AllowVnetInbound'
    properties: {
      access: 'Allow'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationPortRanges: [
        '443'
        '6516'
      ]
      direction: 'Inbound'
      priority: 103
      protocol: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
    }
  }
  {
    name: 'AllowHttpsInbound'
    properties: {
      access: 'Allow'
      destinationAddressPrefix: '*'
      destinationAddressPrefixes: []
      destinationPortRange: '443'
      destinationPortRanges: []
      direction: 'Inbound'
      priority: 104
      protocol: 'Tcp'
      sourceAddressPrefix: 'Internet'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'AllowInboundRDPGateway'
    properties: {
      access: 'Allow'
      destinationAddressPrefix: '*'
      destinationAddressPrefixes: []
      destinationPortRange: '3389'
      destinationPortRanges: []
      direction: 'Inbound'
      priority: 105
      protocol: 'Tcp'
      sourceAddressPrefixes: ['10.80.128.150', '10.80.0.159']
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'AllowGatewayManagerInbound'
    properties: {
      access: 'Allow'
      destinationAddressPrefix: '*'
      destinationAddressPrefixes: []
      destinationPortRange: '443'
      destinationPortRanges: []
      direction: 'Inbound'
      priority: 106
      protocol: 'Tcp'
      sourceAddressPrefix: 'GatewayManager'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'AllowAzureLoadBalancerInbound'
    properties: {
      access: 'Allow'
      destinationAddressPrefix: '*'
      destinationAddressPrefixes: []
      destinationPortRange: '443'
      destinationPortRanges: []
      direction: 'Inbound'
      priority: 107
      protocol: 'Tcp'
      sourceAddressPrefix: 'AzureLoadBalancer'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'AllowBastionHostCommunication'
    properties: {
      access: 'Allow'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefixes: []
      destinationPortRanges: ['8080', '5701']
      direction: 'Inbound'
      priority: 108
      protocol: 'Tcp'
      sourceAddressPrefix: 'VirtualNetwork'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'Allow-Bastion-Inbound-for-AZVMs'
    properties: {
      access: 'Allow'
      DestinationApplicationSecurityGroups: [{ ID: AplicationSecurityGroupID }]
      destinationPortRanges: ['3389', '22']
      direction: 'Inbound'
      priority: 109
      protocol: 'Tcp'
      sourceAddressPrefix: AzureBastionSubnet
      sourcePortRange: '*'
    }
  }
  {
    name: 'AllowInboundWinRM'
    properties: {
      access: 'Allow'
      description: 'Inbound rules for WinRM'
      DestinationApplicationSecurityGroups: [{ ID: AplicationSecurityGroupID }]
      destinationPortRange: ''
      destinationPortRanges: ['5985', '5986']
      direction: 'Inbound'
      priority: 110
      protocol: 'Tcp'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'PolarionInboundRules'
    properties: {
      access: 'Allow'
      description: 'Inbound rules for PolarionCluster Environment'
      destinationAddressPrefix: '*'
      destinationPortRange: ''
      destinationPortRanges: ['8889', '2181', '8887', '3690', '139', '445', '443', '80', '40608', '5433']
      direction: 'Inbound'
      priority: 111
      protocol: 'Tcp'
      sourceApplicationSecurityGroups: [{ ID: AplicationSecurityGroupID }]
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'PolarionInboundWebRules'
    properties: {
      access: 'Allow'
      description: 'Inbound rules for PolarionCluster Environment'
      destinationApplicationSecurityGroups: [{ ID: AplicationSecurityGroupID }]
      destinationPortRanges: ['443', '80']
      direction: 'Inbound'
      priority: 112
      protocol: 'Tcp'
      sourceAddressPrefix: 'Internet'
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'Allow-Bastion-Outbound-for-AZVMs'
    properties: {
      access: 'Allow'
      destinationAddressPrefix: 'Internet'
      destinationPortRange: '443'
      direction: 'Outbound'
      priority: 101
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
    }
  }
  {
    name: 'PolarionOutboundRules'
    properties: {
      access: 'Allow'
      description: 'Outbound rules for PolarionCluster Environment'
      destinationApplicationSecurityGroups: [{ ID: AplicationSecurityGroupID }]
      destinationPortRanges: ['8889', '2181', '8887', '3690', '139', '445', '443', '80', '40608', '5433']
      direction: 'Outbound'
      priority: 102
      protocol: 'Tcp'
      sourceApplicationSecurityGroups: [{ ID: AplicationSecurityGroupID }]
      sourcePortRange: '*'
    }
  }
  {
    name: 'AllowSshRdpOutbound'
    properties: {
      access: 'Allow'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefixes: []
      destinationPortRanges: ['22', '3389']
      direction: 'Outbound'
      priority: 112
      protocol: '*'
      sourceAddressPrefix: '*'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'AllowAzureCloudOutpbound'
    properties: {
      access: 'Allow'
      destinationAddressPrefix: 'AzureCloud'
      destinationAddressPrefixes: []
      destinationPortRange: '443'
      destinationPortRanges: []
      direction: 'Outbound'
      priority: 113
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'AllowBastionCommunication'
    properties: {
      access: 'Allow'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefixes: []
      destinationPortRanges: ['8080', '5701']
      direction: 'Outbound'
      priority: 120
      protocol: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'AllowDNS'
    properties: {
      access: 'Allow'
      destinationAddressPrefix: '*'
      destinationPortRange: '53'
      direction: 'Outbound'
      priority: 125
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
    }
  }
  {
    name: 'AllowSMB'
    properties: {
      access: 'Allow'
      destinationAddressPrefix: '*'
      destinationPortRange: '445'
      direction: 'Outbound'
      priority: 135
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
    }
  }
  {
    name: 'AllowGetSessionInformation'
    properties: {
      access: 'Allow'
      destinationAddressPrefix: 'Internet'
      destinationAddressPrefixes: []
      destinationPortRange: '80'
      destinationPortRanges: []
      direction: 'Outbound'
      priority: 130
      protocol: '*'
      sourceAddressPrefix: '*'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'AllowVnetOutbound'
    properties: {
      access: 'Allow'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationPortRange: '*'
      direction: 'Outbound'
      priority: 200
      protocol: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
    }
  }
  {
    name: 'AllowInternetOutbound'
    properties: {
      access: 'Allow'
      destinationAddressPrefix: 'Internet'
      destinationPortRange: '*'
      direction: 'Outbound'
      priority: 300
      protocol: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
    }
  }
]

@description('Required. Determines the spesifications of virtual machines')
param vms array

@description('Required. Name of the local windows server administrator')
@secure()
param defaultAdminUsername string
param AADLogin object = { enabled: false }
param enableReferencedModulesTelemetry bool = true

@description('Optional(if specified in vms). The type of Operating System that will be deployed to Vms where different OS has not been specified')
param defaultOsType string = 'Windows'

@description('Optional(if specified in vms). OS image reference. In case of marketplace images, it\'s the combination of the publisher, offer, sku, version attributes. In case of custom images it\'s the resource ID of the custom image.')
param windowsImageReference object = {
  offer: 'WindowsServer'
  publisher: 'MicrosoftWindowsServer'
  sku: '2022-Datacenter'
  version: 'latest'
}

@description('Optional(if specified in vms). OS image reference. In case of marketplace images, it\'s the combination of the publisher, offer, sku, version attributes. In case of custom images it\'s the resource ID of the custom image.')
param linuxImageReference object = {
  offer: 'RHEL'
  publisher: 'RedHat'
  sku: '7-LVM'
  version: 'latest'
}

@description('Optional(if specified in vms). OS image reference. In case of marketplace images, it\'s the combination of the publisher, offer, sku, version attributes. In case of custom images it\'s the resource ID of the custom image.')
param imageReferences object = {
  linuxImageReference: linuxImageReference
  windowsImageReference: windowsImageReference
}

@description('Optional(if specified in vms). Specifies the size for the VMs')
param defaultVmSize string = 'Standard_D2s_v3'

@description('Optional(if specified in vms). Specifies the OS disk.')
param defaultOsDisk object = {
  createOption: 'fromImage'
  deleteOption: 'Delete'
  diskSizeGB: 128
  managedDisk: { storageAccountType: 'Premium_LRS' }
}

@description('Optional. Specifies settings related to VM Guest Patching. OS Updates can be initiated manually by the OS itself or by the platform.')
param defaultPatchSettings string = 'AutomaticByPlatform'
param patchAssessmentMode string = 'AutomaticByPlatform'

@description('Optional(if specified in vms). Enables system assigned managed identity on the resource.')
param defaultSystemAssignedIdentity bool = false

@description('Optional. Determines default Azure AD Authentication behaviour, for vms where AADLogin parameterer is not specified.')
param defaultAADLogin bool = false

@description('Optional. Determines default domain join behaviour, for vms where domainJoin parameterer is not specified.')
param defaultDomainJoin bool = false

@description('Optional. Default deployment location')
param location string = deployment().location

@description('Optional. Tags to be set on the resources')
param tags object = {}

@description('Optional. Name of the Key Vault. If missing, will default to subscription prefix, location and add -keyvault string to the resource name.')
@maxLength(34)
param kvName string = 'MS-POLARION-KV-${environmentType}'

@description('Optional. [Omnia Classic Policy]. Switch to enable/disable Key Vault\'s soft delete feature.')
@allowed([
  false
  true
])
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
param enableVaultForDeployment bool = false

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

@description('Optional. Name of the Virtual Network ResourceGroup.  Name will be set by subscription and location + -network')
param vnetResourcegroup string = '${subscriptionPrefix}-${locationShortName['${deployment().location}']}-network'

@description('Optional. Name of the Virtual Network. Name will be set by subscription and location + -vnet')
param vnetName string = '${subscriptionPrefix}-${locationShortName['${deployment().location}']}-vnet'

@description('Optional. Name of the Subnet. Name will be set by subscription, location and subnetsuffix from param file')
param subNetName string = '${subscriptionPrefix}-${locationShortName['${deployment().location}']}-${subnetSuffix}'
param NewsubNetName string = '${subscriptionPrefix}-${locationShortName['${deployment().location}']}-${NewsubnetSuffix}'

@description('Optional. Suffix of the subnet.')
param subnetSuffix string = 'subnet'
param NewsubnetSuffix string = 'polarion-${environmentTypeLowerCase}-subnet'
param subnetId string = '/subscriptions/${subscriptionId}/resourceGroups/${vnetResourcegroup}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${subNetName}'
param NewsubnetId string = '/subscriptions/${subscriptionId}/resourceGroups/${vnetResourcegroup}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${NewsubNetName}'

@description('Optional. Will deploy Recovery Services Vault in seperate rg if set to true')
@allowed([
  false
  true
])
param deployRecoveryServicesVault bool = false

@description('Optional. Resource group for Recovery Services Vault be used if "deployRecoveryServicesVault" is set to true')
param recoveryServicesVaultResourceGroup string = '${resourceGroupName}-backup'

@description('Optional. Name of the Recovery Services vault. Will be used as reference to existing vault if "deployRecoveryServicesVault" is set to false')
param recoveryServicesVaultName string = deployRecoveryServicesVault ? '${resourceGroupName}-backup' : ''
param subscriptionPrefix string = split(subscription().displayName, '-')[0]
param locationShortName object = {
  brazilsouth: 'BS'
  northcentralus: 'NCUS'
  northeurope: 'NE'
  norwayeast: 'NOE'
  norwaywest: 'NOW'
  southcentralus: 'SCUS'
  westeurope: 'WE'
}
var vNetId = '/subscriptions/${subscriptionId}/resourceGroups/${vnetResourcegroup}/providers/Microsoft.Network/virtualNetworks/${vnetName}'
var nsgNames = [for vm in vms: vm.?nsgName ?? '${subscriptionPrefix}${vm.name}-${environmentType}-nsg']
var NewNsgNames = [for vm in vms: vm.?nsgName ?? '${subscriptionPrefix}${vm.name}-${environmentType}-nsg']
param NewsubnetPolarionNsgName string = '${subscriptionPrefix}-NOE-polarion-${environmentTypeLowerCase}-nsg'

module NewPolarionSubnetNSG '../../../templates/network/network-security-group/main.bicep' = {
  name: '${uniqueString(deployment().name, NewsubnetPolarionNsgName)}'
  scope: resourceGroup(vnetResourcegroup)
  params: {
    name: NewsubnetPolarionNsgName
    securityRules: PolarionNSGs
  }
}

param subnets array = []

var subnetconfigs = [
  for (subnet, i) in subnets: union(
    {
      addressPrefix: subnet.addressPrefix
      name: '${subnet.name}-${environmentTypeLowerCase}-subnet'
      networkSecurityGroupId: '/subscriptions/${subscriptionId}/resourceGroups/${vnetResourcegroup}/providers/Microsoft.Network/networkSecurityGroups/${subnet.?networkSecurityGroupName ?? '${subnet.name}-nsg'}'
      networkSecurityGroupName: subnet.?networkSecurityGroupName ?? '${subscriptionPrefix}-${locationShortName}${subnet.name}-${environmentType}-subnet-nsg'
      privateEndpointNetworkPolicies: subnet.privateEndpointNetworkPolicies
      routetableId: '/subscriptions/5a0bb1d0-a00b-40d4-9fc4-4f0e3fd71c4e/resourceGroups/S499-NOE-network/providers/Microsoft.Network/routeTables/${subnet.routetable}'
      virtualNetworkName: 'S499-NOE-vnet'
    },
    subnet
  )
]

@description('Optional. This property can be used by the user in the request to enable or disable the Host Encryption for the virtual machine. This will enable the encryption for all the disks including Resource/Temp disk at host itself. For security reasons, it is recommended to set encryptionAtHost to True. Restrictions: Cannot be enabled if Azure Disk Encryption (guest-VM encryption using bitlocker/DM-Crypt) is enabled on your VMs.')
@allowed([
  false
  true
])
param encryptionAtHost bool = false

@description('Optional. Specifies the SecurityType of the virtual machine. It is set as TrustedLaunch to enable UefiSettings.')
param securityType string = ''

@description('Optional. Specifies whether secure boot should be enabled on the virtual machine. This parameter is part of the UefiSettings. SecurityType should be set to TrustedLaunch to enable UefiSettings.')
param secureBootEnabled bool = false

@description('Optional. Specifies whether vTPM should be enabled on the virtual machine. This parameter is part of the UefiSettings.  SecurityType should be set to TrustedLaunch to enable UefiSettings.')
param vTpmEnabled bool = false

var vmConfigs = [
  for (vm, i) in vms: union(
    {
      AADLogin: defaultAADLogin
      adminUsername: defaultAdminUsername
      domainJoin: defaultDomainJoin
      encryptionAtHost: false
      imageReferenceObject: (contains(vm, 'imageReference')) ? imageReferences[vm.imageReference] : {}
      location: location
      name: '${subscriptionPrefix}${vm.name}-${environmentType}'
      nsgRules: PolarionNSGs
      osDisk: defaultOsDisk
      osType: defaultOsType
      patchAssessmentMode: patchAssessmentMode
      patchSettings: defaultPatchSettings
      securityProfile: {
        encryptionAtHost: encryptionAtHost ? encryptionAtHost : null
        securityType: securityType
        uefiSettings: securityType == 'TrustedLaunch'
          ? {
              secureBootEnabled: secureBootEnabled
              vTpmEnabled: vTpmEnabled
            }
          : null
      }
      systemAssignedIdentity: defaultSystemAssignedIdentity
      vmSize: defaultVmSize
    },
    vm
  )
]

param adminPasswordsarray array = []
var adminPasswords = [
  for (vm, i) in vmConfigs: {
    attributesExp: NorwayBaseTimeAdd29Days
    attributesNbf: NorwayBaseTime
    contentType: ''
    name: '${subscriptionPrefix}${vm.name}-${environmentType}'
    value: adminPasswordsarray[i]
  }
]

resource existingkeyvaults 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: '${kvName}-${environmentType}'
  scope: resourceGroup(resourceGroupName)
  resource kvsecret 'secrets@2023-07-01' existing = [
    for (adminPassword, i) in adminPasswords: {
      name: adminPassword.name
    }
  ]
}

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: 'S499-FkeyADJoin'
  scope: resourceGroup(subscriptionId, 'S499-ADKeyJoin')
}

var networkAcls = {
  bypass: 'AzureServices'
  defaultAction: 'Deny'
  ipRules: []
  virtualNetworkRules: [
    {
      Id: subnetId
      ignoreMissingVnetServiceEndpoint: true
    }
  ]
}

var stgnetworkAcls = [
  for (storageaccount, i) in storageAccounts: {
    bypass: 'AzureServices'
    defaultAction: 'Deny'
    virtualNetworkRules: []
  }
]

var nicConfigurations = [
  for (vm, i) in vms: [
    {
      ipConfigurations: [
        {
          applicationSecurityGroups: [
            {
              id: '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Network/applicationSecurityGroups/${ApplicationSecGroupName}'
            }
          ]
          name: 'ipconfig01'
          subnetResourceId: subnetId
        }
      ]
      networkSecurityGroupResourceId: '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Network/networkSecurityGroups/${nsgNames[i]}'
      nicSuffix: '-nic-01'
      vnetEncryptionSupported: false
    }
  ]
]

resource DeployedVMS 'Microsoft.Compute/virtualMachines@2023-03-01' existing = [
  for (vm, i) in vms: {
    name: '${subscriptionPrefix}${vm.name}-${environmentType}'
    scope: resourceGroup(resourceGroupName)
  }
]
var vmnames = [for (vm, i) in vmConfigs: DeployedVMS[i].name == vm.name ? true : false]

module nicsupdated '../../../templates/network/network-interface/main.bicep' = [
  for vm in vms: if (vmnames == true) {
    name: '${subscriptionPrefix}${vm.name}-${environmentType}-nic-01'
    scope: resourceGroup(resourceGroupName)
    params: {
      name: '${subscriptionPrefix}${vm.name}-${environmentType}-nic-01'
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            privateIPAllocationMethod: 'Static'
          }
        }
      ]
      location: location
    }
    dependsOn: [
      virtualMachine
    ]
  }
]

var AADLoginForWindows = [
  for vm in vmConfigs: {
    enabled: vm.AADLogin
  }
]

var extensionDomainJoinConfigs = [
  for (vm, i) in vms: union(
    {
      enabled: vm.osType == 'Windows' ? vm.domainJoin : false
      settings: {
        Name: 'statoil.net'
        Options: 3
        OUPath: 'OU=${subscriptionPrefix},OU=Omnia Classic,OU=Cloud Servers,OU=Servers,DC=statoil,DC=net'
        Restart: true
        User: 'f_ocdj_${subscriptionPrefix}@statoil.net'
      }
    },
    vm
  )
]

var extensionAntiMalwareConfig = [
  for vm in vmConfigs: {
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: false
    enabled: true
    typeHandlerVersion: '1.3'
    protectedSettings: null
    settings: {
      AntimalwareEnabled: true
      RealtimeProtectionEnabled: true
      ScheduledScanSettings: {
        day: 7
        isEnabled: true
        scanType: 'Quick'
        time: 120
      }
    }
  }
]

var vmMonitorAgentExtensionConfig = [
  for vm in vmConfigs: {
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      authentication: {
        managedIdentity: {
          'identifier-name': userAssignedManagedIdentityID
          'identifier-value': UserAssignedIdentitiesClient_ID
        }
      }
    }
    typeHandlerVersion: '1.0'
  }
]

var vmCustomScriptExtensionConfig = [
  for vm in vmConfigs: {
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: false
    enabled: true
    settings: {
      commandToExecute: 'powershell.exe -Command "Enable-PSRemoting -Force"'
    }
    typeHandlerVersion: '1.10'
  }
]

module AppSecGroups '../../../templates/network/application-security-group/main.bicep' = {
  name: ApplicationSecGroupName
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    name: ApplicationSecGroupName
  }
  dependsOn: [
    newRg
  ]
}

module newRg '../../../templates/resources/resource-group/main.bicep' = {
  name: '${uniqueString(deployment().name, resourceGroupName)}-rg-${resourceGroupName}'
  scope: subscription()
  params: {
    location: location
    name: resourceGroupName
    tags: tags
  }
}

module managedIdentityDeployment '../../../templates/managed-identity/user-assigned-identity/main.bicep' = {
  name: '${uniqueString(deployment().name, resourceGroupName)}-mi-${resourceGroupName}'
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

module backupRg '../../../templates/resources/resource-group/main.bicep' = if (deployRecoveryServicesVault) {
  name: '${uniqueString(deployment().name, recoveryServicesVaultResourceGroup)}-rg-${recoveryServicesVaultResourceGroup}'
  scope: subscription()
  params: {
    location: location
    name: recoveryServicesVaultResourceGroup
    tags: tags
  }
  dependsOn: [
    newRg
  ]
}

param iac_objectid string = ''

module managedIdentity '../../../templates/managed-identity/user-assigned-identity/main.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: '${UserAssignedManagedIdentity}-${environmentType}'
  params: {
    location: location
    name: '${UserAssignedManagedIdentity}-${environmentType}'
    tags: tags
  }
  dependsOn: [
    newRg
  ]
}

module newNSG '../../../templates/network/network-security-group/main.bicep' = [
  for (vm, i) in vmConfigs: {
    name: '${uniqueString(deployment().name, nsgNames[i])}-nsg-${nsgNames[i]}'
    scope: resourceGroup(resourceGroupName)
    params: {
      location: location
      name: nsgNames[i]
      securityRules: vm.nsgRules
    }
    dependsOn: [
      newRg
    ]
  }
]

module recoveryServicesVault '../../../templates/recovery-services/vault/main.bicep' = if (deployRecoveryServicesVault) {
  name: '${uniqueString(deployment().name, recoveryServicesVaultName)}-rsv-${recoveryServicesVaultName}'
  scope: resourceGroup(recoveryServicesVaultResourceGroup)
  params: {
    location: location
    name: recoveryServicesVaultName
    securitySettings: {
      softDeleteSettings: {
        softDeleteRetentionPeriodInDays: 14
        softDeleteState: 'Enabled'
        enhancedSecurityState: 'Enabled'
      }
      monitoringSettings: {
        azureMonitorAlertSettings: {
          alertsForAllJobFailures: 'Enabled'
          alertsForAllReplicationIssues: 'Enabled'
          alertsForAllFailoverIssues: 'Enabled'
        }
        classicAlertSettings: {
          alertsForCriticalOperations: 'Disabled'
          emailNotificationsForSiteRecovery: 'Disabled'
        }
      }
      immutabilitySettings: {
        state: 'Locked'
      }
    }
  }
  dependsOn: [
    backupRg
  ]
}

resource DeployedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: '${UserAssignedManagedIdentity}-${environmentType}'
  scope: resourceGroup(resourceGroupName)
}

output ManagedIdentityId string = DeployedManagedIdentity.id
output ManagedIdentityClientId string = DeployedManagedIdentity.properties.clientId
output ManagedIdentityOjbectId string = DeployedManagedIdentity.properties.principalId

module virtualMachine '../../../templates/compute/virtual-machine/main.bicep' = [
  for (vm, i) in vmConfigs: {
    name: '${uniqueString(deployment().name, vm.name)}-vm-${vm.name}'
    scope: resourceGroup(resourceGroupName)
    params: {
      adminPassword: existingkeyvaults.getSecret('${subscriptionPrefix}${vm.name}-${environmentType}')
      adminUsername: vm.adminUsername
      backupVaultName: recoveryServicesVaultName
      backupVaultResourceGroup: recoveryServicesVaultResourceGroup
      extensionAadJoinConfig: AADLoginForWindows[i]
      extensionDomainJoinConfig: extensionDomainJoinConfigs[i]
      extensionDomainJoinPassword: kv.getSecret('domainJoinKey')
      imageReference: !empty(vm.imageReferenceObject)
        ? vm.imageReferenceObject
        : (vm.osType == 'Linux' ? linuxImageReference : windowsImageReference)
      location: vm.location
      managedIdentities: {
        systemAssigned: vm.systemAssignedIdentity
        userAssignedResourceIds: [DeployedManagedIdentity.id]
      }
      monitoringWorkspaceId: logAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
      name: '${subscriptionPrefix}${vm.name}-${environmentType}'
      nicConfigurations: nicConfigurations[i]
      osDisk: vm.osDisk
      osType: vm.osType
      patchAssessmentMode: vm.patchAssessmentMode
      patchMode: vm.patchSettings
      securityProfile: vm.securityProfile
      tags: union(tags, vmTags)
      timeZone: 'W. Europe Standard Time'
      vmSize: vm.vmSize
    }
    dependsOn: [
      AppSecGroups
      newNSG
      newRg
      recoveryServicesVault
    ]
  }
]

@description('Please enter workspace name to be registered for current solution')
param workspaceName string = 'PL-logAnalytics-${environmentType}'

module logAnalyticsWorkspace '../../../Bicep/logAnalyticsWorkspace.bicep' = {
  name: workspaceName
  scope: resourceGroup(resourceGroupName)
  params: {
    tags: tags
    workspaceName: workspaceName
    rgLocation: location
    retentionInDays: 35
  }
}

output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.outputs.logAnalyticsWorkspaceName
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId

module dataCollectionEndpoint '../../../Bicep/modules/insights/data-collection-endpoint/main.bicep' = {
  name: '${subscriptionPrefix}-PL-DataCollectionEndpoint-${environmentType}'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: '${subscriptionPrefix}-PL-DataCollectionEndpoint-${environmentType}'
    enableDefaultTelemetry: true
    kind: 'Windows'
    location: location
    publicNetworkAccess: 'Disabled'
    tags: tags
  }
}

output dataCollectionEndpointOutputId string = dataCollectionEndpoint.outputs.resourceId
output dataCollectionEndpointOutputName string = dataCollectionEndpoint.outputs.name

var dataCollectionRules = [
  {
    name: '${subscriptionPrefix}-PL-DCR-${environmentType}'
    counterSpecifiers: [
      '\\Processor Information(_Total)\\% Processor Time'
      '\\Processor Information(_Total)\\% Privileged Time'
      '\\Processor Information(_Total)\\% User Time'
      '\\Processor Information(_Total)\\Processor Frequency'
      '\\System\\Processes'
      '\\Process(_Total)\\Thread Count'
      '\\Process(_Total)\\Handle Count'
      '\\System\\Processor Queue Length'
      '\\Process(_Total)\\Working Set'
      '\\Process(_Total)\\Working Set - Private'
      '\\LogicalDisk(_Total)\\% Free Space'
      '\\LogicalDisk(_Total)\\Free Megabytes'
      '\\LogicalDisk(*)\\Free Megabytes'
      '\\LogicalDisk(*)\\% Free Space'
      '\\Storage Spaces Virtual Disk(*)\\Virtual Disk Total'
      '\\LogicalDisk(*)\\Size'
    ]
    streams: [
      'Microsoft-Perf'
    ]
    samplingFrequency: 60
    kind: 'Windows'
  }
]

module dataCollectionRule '../../../Bicep/dataCollectionRule.bicep' = [
  for r in dataCollectionRules: {
    name: r.name
    params: {
      dataCollectionEndpointId: dataCollectionEndpoint.outputs.resourceId
      dataCollectionRuleName: r.name
      location: location
      logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.logAnalyticsWorkspaceName
      logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
      counterSpecifiers: r.counterSpecifiers
      streams: r.streams
      samplingFrequency: r.samplingFrequency
      kind: r.kind
    }
    scope: resourceGroup(resourceGroupName)
    dependsOn: [
      logAnalyticsWorkspace
    ]
  }
]

// https://microsoft.github.io/WhatTheHack/007-AzureMonitoring/Student/Challenge-02.html
module dataCollectionVmRuleAssociationVM '../../../Bicep/dataCollectionRuleAssociation.bicep' = [
  for vm in vms: {
    name: 'vmDataCollectionEndpointAssociationVM-${vm.name}'
    params: {
      dataCollectionRuleId: dataCollectionRule[0].outputs.dataCollectionRuleId
      vmId: '${subscriptionPrefix}${vm.name}-${environmentType}'
    }
    scope: resourceGroup(resourceGroupName)
  }
]

module vmCustomScriptExtension '../../../templates/compute/virtual-machine/extension/main.bicep' = [
  for (vm, i) in vmConfigs: if (vmCustomScriptExtensionConfig[i].enabled) {
    name: '${uniqueString(deployment().name, location)}-${subscriptionPrefix}${vm.name}-${environmentType}-vmCustomScriptExtension'
    scope: resourceGroup(resourceGroupName)
    params: {
      autoUpgradeMinorVersion: contains(vmCustomScriptExtensionConfig, 'autoUpgradeMinorVersion')
        ? vmCustomScriptExtensionConfig[i].autoUpgradeMinorVersion
        : true
      enableAutomaticUpgrade: contains(vmCustomScriptExtensionConfig, 'enableAutomaticUpgrade')
        ? vmCustomScriptExtensionConfig[i].enableAutomaticUpgrade
        : false
      location: location
      name: 'CustomScriptExtension'
      publisher: 'Microsoft.Compute'
      settings: vmCustomScriptExtensionConfig[i].settings
      type: 'CustomScriptExtension'
      typeHandlerVersion: contains(vmCustomScriptExtensionConfig, 'typeHandlerVersion')
        ? vmCustomScriptExtensionConfig[i].typeHandlerVersion
        : '1.10'
      virtualMachineName: '${subscriptionPrefix}${vm.name}-${environmentType}'
    }
    dependsOn: [
      virtualMachine[i]
    ]
  }
]

module vm_admincenter '../../../templates/compute/virtual-machine/extension/admincenter.bicep' = [
  for (vm, i) in vmConfigs: {
    name: '${uniqueString(deployment().name, location)}-${vm.name}-VM-admincenter'
    scope: resourceGroup(resourceGroupName)
    params: {
      location: location
      tags: tags
      vmName: '${subscriptionPrefix}${vm.name}-${environmentType}'
    }
    dependsOn: [
      virtualMachine[i]
    ]
  }
]

module vm_microsoftAADLoginForWindowsExtension '../../../templates/compute/virtual-machine/extension/main.bicep' = [
  for (vm, i) in vmConfigs: if (AADLogin.enabled) {
    name: '${uniqueString(deployment().name, location)}-${subscriptionPrefix}${vm.name}-${environmentType}-AADLoginForWindows'
    scope: resourceGroup(resourceGroupName)
    params: {
      autoUpgradeMinorVersion: contains(AADLoginForWindows, 'autoUpgradeMinorVersion')
        ? AADLogin.autoUpgradeMinorVersion
        : true
      enableAutomaticUpgrade: contains(AADLoginForWindows, 'enableAutomaticUpgrade')
        ? AADLogin.enableAutomaticUpgrade
        : false
      location: location
      name: 'AADLoginForWindows'
      publisher: 'Microsoft.Azure.ActiveDirectory'
      type: 'AADLoginForWindows'
      typeHandlerVersion: contains(AADLoginForWindows, 'typeHandlerVersion') ? AADLogin.typeHandlerVersion : '1.0'
      virtualMachineName: '${subscriptionPrefix}${vm.name}-${environmentType}'
    }
    dependsOn: [
      virtualMachine[i]
    ]
  }
]

module vm_microsoftAntiMalwareExtension '../../../templates/compute/virtual-machine/extension/main.bicep' = [
  for (vm, i) in vmConfigs: {
    name: '${uniqueString(deployment().name, location)}-${vm.name}-VM-MicrosoftAntiMalware'
    scope: resourceGroup(resourceGroupName)
    params: {
      autoUpgradeMinorVersion: contains(extensionAntiMalwareConfig, 'autoUpgradeMinorVersion')
        ? extensionAntiMalwareConfig[i].autoUpgradeMinorVersion
        : true
      enableAutomaticUpgrade: contains(extensionAntiMalwareConfig, 'enableAutomaticUpgrade')
        ? extensionAntiMalwareConfig[i].enableAutomaticUpgrade
        : false
      enableDefaultTelemetry: enableReferencedModulesTelemetry
      location: location
      name: 'MicrosoftAntiMalware'
      publisher: 'Microsoft.Azure.Security'
      settings: extensionAntiMalwareConfig[i].settings
      type: 'IaaSAntimalware'
      typeHandlerVersion: contains(extensionAntiMalwareConfig, 'typeHandlerVersion')
        ? extensionAntiMalwareConfig[i].typeHandlerVersion
        : '1.3'
      virtualMachineName: '${subscriptionPrefix}${vm.name}-${environmentType}'
    }
    dependsOn: [
      virtualMachine[i]
    ]
  }
]

module vmMonitorAgentExtension '../../../templates/compute/virtual-machine/extension/main.bicep' = [
  for (vm, i) in vmConfigs: if (vm.osType == 'Windows') {
    name: '${uniqueString(deployment().name, location)}-${subscriptionPrefix}${vm.name}-${environmentType}'
    scope: resourceGroup(resourceGroupName)
    params: {
      autoUpgradeMinorVersion: vmMonitorAgentExtensionConfig[i].?autoUpgradeMinorVersion ?? true
      enableAutomaticUpgrade: vmMonitorAgentExtensionConfig[i].?enableAutomaticUpgrade ?? true
      location: location
      name: 'AzureMonitorWindowsAgent'
      publisher: 'Microsoft.Azure.Monitor'
      type: 'AzureMonitorWindowsAgent'
      typeHandlerVersion: vmMonitorAgentExtensionConfig[i].?typeHandlerVersion ?? '1.0'
      virtualMachineName: '${subscriptionPrefix}${vm.name}-${environmentType}'
    }
    dependsOn: [
      virtualMachine[i]
    ]
  }
]

module secret '../../../templates/key-vault/vault/secret/main.bicep' = [
  for (vm, i) in vmConfigs: {
    name: '${uniqueString(deployment().name, vm.name)}-${vm.name}-secret'
    scope: resourceGroup(resourceGroupName)
    params: {
      attributesEnabled: true
      attributesExp: adminPasswords[i].attributesExp
      attributesNbf: adminPasswords[i].attributesNbf
      contentType: 'VM'
      keyVaultName: '${kvName}-${environmentType}'
      name: adminPasswords[i].name
      value: adminPasswords[i].value
    }
  }
]

@description('Required. Determines the spesifications of storageAccounts')
param storageAccounts array

var storageAccountConfigs = [
  for (storageAccount, i) in storageAccounts: union(
    {
      allowBlobPublicAccess: true
      allowedCopyScope: storageAccount.properties.allowedCopyScope
      blobServices: {
        blobContainers: [
          {
            name: 'polarionblob${environmentTypeLowerCase}'
            properties: {
              enableDefaultTelemetry: true
              immutabilityPolicyProperties: false
              publicAccess: false
              roleAssignments: []
            }
          }
          {
            name: 'vulnerability-assessment'
            properties: {
              enableDefaultTelemetry: true
              immutabilityPolicyProperties: false
              publicAccess: false
              roleAssignments: []
            }
          }
        ]
        changeFeedEnabled: true
        containerDeleteRetentionPolicyDays: 7
        containerDeleteRetentionPolicyEnabled: true
        deleteRetentionPolicyDays: 35
        deleteRetentionPolicyEnabled: true
        enabled: storageAccount.properties.blobServices.enabled
        enableDefaultTelemetry: true
        isVersioningEnabled: true
        keyType: storageAccount.properties.blobServices.keyType
        restorePolicy: {
          enabled: true
          days: 7
        }
        restorePolicyDays: 30
        restorePolicyEnabled: true
      }
      fileServices: {
        enabled: storageAccount.properties.fileServices.enabled
        keyType: storageAccount.properties.fileServices.keyType
        shareDeleteRetentionPolicy: {
          allowPermanentDelete: storageAccount.properties.fileServices.shareDeleteRetentionPolicy.allowPermanentDelete
          days: storageAccount.properties.fileServices.shareDeleteRetentionPolicy.days
          enabled: storageAccount.properties.fileServices.shareDeleteRetentionPolicy.enabled
        }
      }
      name: '${storageAccount.name}${environmentTypeLowerCase}'
      requireInfrastructureEncryption: storageAccount.requireInfrastructureEncryption
      storageAccountKind: storageAccount.storageAccountKind
      storageAccountSku: storageAccount.storageAccountSku
    },
    storageAccount
  )
]

module storageAccount '../../../templates/storage/storage-account/main.bicep' = [
  for (storageAccount, i) in storageAccountConfigs: /* if  (storageAccountnames == true) */ {
    name: '${uniqueString(deployment().name, storageAccount.name)}-${storageAccount.name}-storageaccount'
    scope: resourceGroup(resourceGroupName)
    params: {
      allowBlobPublicAccess: false
      allowCrossTenantReplication: false
      allowedCopyScope: storageAccount.allowedCopyScope
      blobServices: storageAccount.blobServices
      fileServices: storageAccount.fileServices
      kind: storageAccount.storageAccountKind
      largeFileSharesState: 'Enabled'
      location: location
      name: '${storageAccounts[i].name}${environmentTypeLowerCase}'
      networkAcls: stgnetworkAcls[i]
      publicNetworkAccess: 'Disabled'
      requireInfrastructureEncryption: storageAccount.requireInfrastructureEncryption
      skuName: storageAccount.storageAccountSku
      supportsHttpsTrafficOnly: true
    }
    dependsOn: [
      newRg
    ]
  }
]

@description('Required. Determines the spesifications of shares')
param shares array

var sharesconfigs = [
  for (share, i) in shares: union(
    {
      name: '${share.name}${environmentTypeLowerCase}'
      StorageAccountName: share.StorageAccountName
      properties: {
        accessTier: share.properties.accessTier
        enabledProtocols: share.properties.enabledProtocols
        rootSquash: share.properties.rootSquash
        shareQuota: share.properties.shareQuota
      }
    },
    share
  )
]

module fileServices_shares '../../../templates/storage/storage-account/file-service/share/main.bicep' = [
  for (share, i) in sharesconfigs: {
    name: '${uniqueString(deployment().name, share.name)}-${share.name}-SharefileServices'
    scope: resourceGroup(resourceGroupName)
    params: {
      enabledProtocols: share.properties.enabledProtocols
      name: '${share.name}${environmentTypeLowerCase}'
      rootSquash: share.properties.rootSquash
      shareQuota: share.properties.shareQuota
      storageAccountName: '${share.StorageAccountName}${environmentTypeLowerCase}'
    }
    dependsOn: [
      storageAccount
    ]
  }
]

param blobs array

var blobsconfigs = [
  for (blob, i) in blobs: union(
    {
      name: '${blob.name}${environmentTypeLowerCase}'
      properties: {
        enableDefaultTelemetry: blob.properties.enableDefaultTelemetry
        immutabilityPolicyProperties: blob.properties.immutabilityPolicyProperties
        publicAccess: blob.properties.publicAccess
        roleAssignments: blob.properties.roleAssignments
      }
      StorageAccountName: blob.StorageAccountName
    },
    blob
  )
]

module blobServices_container '../../../templates/storage/storage-account/blob-service/container/main.bicep' = [
  for (blob, index) in blobsconfigs: {
    name: '${uniqueString(deployment().name, blob.name)}-${blob.name}-BlobServices'
    scope: resourceGroup(resourceGroupName)
    params: {
      enableDefaultTelemetry: blob.properties.enableDefaultTelemetry
      immutabilityPolicyProperties: contains(blob, 'blob.properties.immutabilityPolicyProperties')
        ? blob.properties.immutabilityPolicyProperties
        : {}
      name: '${blob.name}${environmentTypeLowerCase}'
      publicAccess: contains(blob, 'blob.properties.publicAccess') ? blob.properties.publicAccess : 'None'
      roleAssignments: contains(blob, 'blob.properties.roleAssignments') ? blob.properties.roleAssignments : []
      storageAccountName: '${blob.StorageAccountName}${environmentTypeLowerCase}'
    }
    dependsOn: [
      newRg
      storageAccount
    ]
  }
]

module storageaccblobprivateEndpoint '../../../templates/network/private-endpoint/main.bicep' = [
  for (blob, i) in blobsconfigs: {
    name: '${uniqueString(deployment().name, blob.name)}-${blob.name}-blobPE'
    scope: resourceGroup(resourceGroupName)
    params: {
      customNetworkInterfaceName: '${resourceGroupName}-blob-PE.nic'
      groupIds: ['blob']
      location: location
      name: '${resourceGroupName}-blob-PE'
      serviceResourceId: '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Storage/storageAccounts/${blob.storageAccountName}${environmentTypeLowerCase}'
      subnetResourceId: subnetId
    }
    dependsOn: [
      blobServices_container
      fileServices_shares
      newRg
    ]
  }
]

module storageaccfileprivateEndpoint '../../../templates/network/private-endpoint/main.bicep' = [
  for (storageAccount, i) in storageAccountConfigs: {
    name: '${uniqueString(deployment().name, storageAccount.name)}-${storageAccount.name}-filePE'
    scope: resourceGroup(resourceGroupName)
    params: {
      customNetworkInterfaceName: '${resourceGroupName}-file-PE.nic'
      groupIds: ['file']
      location: location
      name: '${resourceGroupName}-file-PE'
      serviceResourceId: '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Storage/storageAccounts/${storageAccount.name}${environmentTypeLowerCase}'
      subnetResourceId: subnetId
    }
    dependsOn: [
      blobServices_container
      fileServices_shares
      newRg
    ]
  }
]
