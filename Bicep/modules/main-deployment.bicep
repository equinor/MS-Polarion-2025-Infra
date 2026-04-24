targetScope = 'resourceGroup'

@description('Environment short name, e.g. DEV, TEST, PRD.')
param environment string

@description('Subnet configuration object from the main parameter file. compute should point to the VM subnet resource ID.')
param subnetConfig object

@description('Key Vault name containing VM admin password secrets.')
param keyVaultName string

@description('Suffix appended to each VM name to resolve the admin password secret. Secret name format: <vmName><suffix>.')
param vmAdminPasswordSecretNameSuffix string = '-localadmin-password'

@description('Number of VMs to deploy.')
param vmCount int = 4

@description('Virtual machine size.')
param vmSize string = 'Standard_D4s_v5'

@description('Base name aligned with legacy naming standard. Resulting names become <base><NN>-<environment>.')
param vmNameBase string = 'S499PLWS25'

@description('Marketplace SKU for Windows Server 2025 Datacenter x64 Gen2. Validate availability in your target region.')
param vmImageSku string = '2025-datacenter-g2'

@description('Resource tags applied to all VMs and child resources.')
param tags object = {}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

var vmInstances = [
  for i in range(0, vmCount): {
    index: i + 1
    name: '${toUpper(vmNameBase)}${padLeft(string(i + 1), 2, '0')}-${toUpper(environment)}'
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
      vmSize: vmSize
      adminUsername: 'localAdmin'
      adminPassword: keyVault.getSecret('${toLower(vm.name)}${vmAdminPasswordSecretNameSuffix}')
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: vmImageSku
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        diskSizeGB: 512
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      nicConfigurations: [
        {
          nicSuffix: '-nic-01'
          ipConfigurations: [
            {
              name: 'ipconfig01'
              subnetResourceId: subnetConfig.compute
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
