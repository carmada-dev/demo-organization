targetScope = 'subscription'

// ============================================================================================

param DeploymentContext object
param OrganizationDefinition object
param OrganizationContext object
param ProjectDefinition object
param ProjectContext object

// ============================================================================================

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: last(split(ProjectContext.ResourceGroupId, '/'))  
}

module deployDevProject 'project/deployDevProject.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(ProjectDefinition), 'deployDevProject')}'
  scope: resourceGroup
  params: {
    OrganizationDefinition: OrganizationDefinition
    OrganizationContext: OrganizationContext
    ProjectDefinition: ProjectDefinition
    ProjectContext: ProjectContext
  }
}

module assignRoleOnSubscription './tools/assignRoleOnSubscription.bicep' = [for EnvironmentDefinition in ProjectDefinition.environments: {
  name: '${take(deployment().name, 36)}_${uniqueString('assignRoleOnSubscription', EnvironmentDefinition.subscription)}'
  scope: subscription(EnvironmentDefinition.subscription)
  params: {
    RoleNameOrId: 'Owner'
    PrincipalIds: [
      OrganizationContext.PrincipalId
    ]
  }
}]

// ============================================================================================

output ProjectContext object = union(ProjectContext, {
  NetworkConnectionId: deployDevProject.outputs.NetworkConnectionId
  ProjectId: deployDevProject.outputs.ProjectId
  Environments : deployDevProject.outputs.Environments
})
