targetScope = 'subscription'

// ============================================================================================

param DeploymentContext object
param OrganizationDefinition object
param OrganizationContext object

// ============================================================================================

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: last(split(OrganizationContext.ResourceGroupId, '/'))  
}

module deployIPGroups 'tools/deployIPGroups.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'deployIPGroups')}'
  scope: resourceGroup
  params: {
    VNetName: last(split(OrganizationContext.NetworkId, '/'))
  }
}

module deployDevCenter 'organization/deployDevCenter.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'deployDevCenter')}'
  scope: resourceGroup
  params: {
    OrganizationDefinition: OrganizationDefinition
    OrganizationContext: OrganizationContext
    DeploymentContext: DeploymentContext
  }
}

// ============================================================================================

output OrganizationContext object = union(OrganizationContext, {
  DevCenterId: deployDevCenter.outputs.DevCenterId
  GallerId: deployDevCenter.outputs.GalleryId
  VaultId: deployDevCenter.outputs.VaultId
})
