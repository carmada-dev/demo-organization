targetScope = 'subscription'

// ============================================================================================

param OrganizationDefinition object
param OrganizationContext object
param ProjectDefinition object
param DeploymentContext object

// ============================================================================================

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'PRJ-${ProjectDefinition.name}'
  location: OrganizationDefinition.location
}

resource resourceGroupPrivateLink 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'PRJ-${ProjectDefinition.name}-PL'
  location: OrganizationDefinition.location
}

module testProjectNetworkExists 'tools/testResourceExists.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'testProjectNetworkExists')}'
  scope: resourceGroup
  params: {
    ResourceName: ProjectDefinition.name
    ResourceType: 'Microsoft.Network/virtualNetworks'
  }
}

module projectInfrastructure 'project/deployInfrastructure.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition))}'
  scope: resourceGroup
  params: {
    OrganizationDefinition: OrganizationDefinition
    OrganizationContext: OrganizationContext
    ProjectDefinition: ProjectDefinition
    InitialDeployment: !testProjectNetworkExists.outputs.ResourceExists
  }
}

// ============================================================================================

output ProjectContext object = {
  ResourceGroupId: resourceGroup.id
  NetworkId: projectInfrastructure.outputs.NetworkId
  GatewayIP: projectInfrastructure.outputs.GatewayIP
}
