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

module deployProjectEnvironment './deployProjectEnvironment.bicep' = [for EnvironmentDefinition in ProjectDefinition.environments: {
  name: '${take(deployment().name, 36)}_${uniqueString(string(EnvironmentDefinition))}'
  scope: subscription(EnvironmentDefinition.subscription)
  params: {
    OrganizationDefinition: OrganizationDefinition
    OrganizationContext: OrganizationContext
    ProjectDefinition: ProjectDefinition
    ProjectContext: {
      // CAUTION !!! This is a temporary project context
      // and not necessarily the context we return as
      // an output value of this template !!!
      NetworkId: projectInfrastructure.outputs.NetworkId
      GatewayIP: projectInfrastructure.outputs.GatewayIP      
    }
    EnvironmentDefinition: EnvironmentDefinition
  }
}]

// ============================================================================================

output ProjectContext object = {
  ResourceGroupId: resourceGroup.id
  NetworkId: projectInfrastructure.outputs.NetworkId
  GatewayIP: projectInfrastructure.outputs.GatewayIP
}

output Environments array = [for i in range(0, length(ProjectDefinition.environments)): deployProjectEnvironment[i].outputs.EnvironmentContext]
