targetScope = 'resourceGroup'

@description('Name of the existing Recovery Services Vault where VM protected items are registered.')
param recoveryServicesVaultName string

@description('Name of the workload resource group that contains the protected VMs.')
param workloadResourceGroupName string

@description('Protected item inputs. Each object must contain vmName and sourceResourceId.')
param protectedItems array

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2023-06-01' existing = {
  name: recoveryServicesVaultName
}

resource recoveryServicesProtectedItems 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2023-06-01' = [
  for item in protectedItems: {
    name: '${recoveryServicesVault.name}/Azure/IaasVMContainer;iaasvmcontainerv2;${workloadResourceGroupName};${item.vmName}/VM;iaasvmcontainerv2;${workloadResourceGroupName};${item.vmName}'
    properties: {
      protectedItemType: 'Microsoft.Compute/virtualMachines'
      policyId: '${recoveryServicesVault.id}/backupPolicies/VMPolicyEnhanced'
      sourceResourceId: item.sourceResourceId
    }
  }
]
