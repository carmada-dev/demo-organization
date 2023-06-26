targetScope = 'subscription'

// ============================================================================================

param OrganizationDefinition object
param DeploymentContext object

// ============================================================================================


resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'ORG-${OrganizationDefinition.name}'
  location: OrganizationDefinition.location
}

resource resourceGroupPrivateLink 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'ORG-${OrganizationDefinition.name}-PL'
  location: OrganizationDefinition.location
}

module testOrganizationNetworkExists 'tools/testResourceExists.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'testOrganizationNetworkExists')}'
  scope: resourceGroup
  params: {
    ResourceName: OrganizationDefinition.name
    ResourceType: 'Microsoft.Network/virtualNetworks'
  }
}

module organizationInfrastructure 'organization/deployInfrastructure.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition))}'
  scope: resourceGroup
  params: {
    OrganizationDefinition: OrganizationDefinition
    InitialDeployment: !testOrganizationNetworkExists.outputs.ResourceExists
  }
}

// ============================================================================================

output OrganizationContext object = {
  ResourceGroupId: resourceGroup.id
  WorkspaceId: organizationInfrastructure.outputs.WorkspaceId
  NetworkId: organizationInfrastructure.outputs.NetworkId
  GatewayIP: organizationInfrastructure.outputs.GatewayIP
}
