targetScope = 'resourceGroup'

@description('Name of the existing managed disk to read creationData from.')
param diskName string

// Isolated in its own deployment so the read doesn't create a self-referencing dependency
// on the sibling resource that updates this same disk's performance tier.
resource existingDisk 'Microsoft.Compute/disks@2024-03-02' existing = {
  name: diskName
}

output creationData object = existingDisk.properties.creationData
