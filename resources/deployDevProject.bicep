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

// ============================================================================================

output ProjectContext object = union(ProjectContext, {

})
