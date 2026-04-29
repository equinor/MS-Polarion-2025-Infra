targetScope = 'resourceGroup'

@description('Name of the existing Key Vault where secrets should be created.')
param keyVaultName string

@secure()
@description('Secret map where each property name is the Key Vault secret name and each property value is the secret value.')
param credentials object = {}

param environment string
param rgName string
param rgLocation string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

module keyVaultSecrets 'br/public:avm/res/key-vault/vault/secret:0.1.0' = [
  for credential in items(credentials): {
    name: 'kv-secret-${uniqueString(keyVault.id, credential.key)}'
    params: {
      keyVaultName: keyVault.name
      name: '${credential.key}-localadmin-password'
      value: credential.value
      enableTelemetry: false
    }
  }
]
