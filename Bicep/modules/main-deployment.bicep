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

@description('Per-VM configuration array. Each object should contain: vmSize, vmImageSku, osDiskSizeGB, hasDataDisk, dataDiskSizeGB, dataDiskStorageType, privateIPAddress.')
param vmConfigurations array = []

@description('Resource tags applied to all VMs and child resources.')
param tags object = {}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

var environmentSuffix = '${toUpper(substring(environment, 0, 1))}${toLower(substring(environment, 1))}'
var effectiveVmCount = length(vmConfigurations) > 0 ? length(vmConfigurations) : vmCount

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

output deployedVmNames array = [for vm in vmInstances: vm.name]
output deployedVmIds array = [for (vm, i) in vmInstances: windowsVm[i].outputs.resourceId]
