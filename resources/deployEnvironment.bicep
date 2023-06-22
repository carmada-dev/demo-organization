targetScope = 'subscription'

// ============================================================================================

param OrganizationDefinition object
param OrganizationContext object
param ProjectDefinition object
param ProjectContext object
param EnvironmentDefinition object

// ============================================================================================

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'ENV-${OrganizationDefinition.name}-${ProjectDefinition.name}-${EnvironmentDefinition.name}'
  location: OrganizationDefinition.location
}

module testEnvironmentNetworkExists 'tools/testResourceExists.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(ProjectDefinition), 'testEnvironmentNetworkExists')}'
  scope: resourceGroup
  params: {
    ResourceName: EnvironmentDefinition.name
    ResourceType: 'Microsoft.Network/virtualNetworks'
  }
}

module deployEnvironmentInfrastructure 'environment/deployInfrastructure.bicep' = {
  name: '${take(deployment().name, 36)}_deployNetwork'
  scope: resourceGroup
  params: {
    OrganizationDefinition: OrganizationDefinition
    OrganizationContext: OrganizationContext
    ProjectDefinition: ProjectDefinition
    ProjectContext: ProjectContext
    EnvironmentDefinition: EnvironmentDefinition
    InitialDeployment: !testEnvironmentNetworkExists.outputs.ResourceExists
  }
}

