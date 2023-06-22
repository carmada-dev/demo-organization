targetScope = 'subscription'

// ============================================================================================

param OrganizationDefinition object
param ProjectDefinitions array
param Windows365PrinicalId string

// ============================================================================================

var DeploymentContext = {
  Windows365PrinicalId: Windows365PrinicalId
  Features: {
    TestHost: false
    TestSQL: false
  } 
}

var EnvironmentMaps = flatten(map(range(0, length(ProjectDefinitions)), pdi => map(range(0, length(ProjectDefinitions[pdi].environments)), evi => {
  ProjectDefinitionIndex: pdi
  ProjectDefinition: ProjectDefinitions[pdi]
  EnvironmentDefinitionIndex: evi
  EnvironmentDefinition: ProjectDefinitions[pdi].environments[evi]
})))

// ============================================================================================

module deployOrganization 'resources/deployOrganization.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'deployOrganization')}'
  params: {
    DeploymentContext: DeploymentContext
    OrganizationDefinition: OrganizationDefinition
  }
}

module deployProject 'resources/deployProject.bicep' = [for ProjectDefinition in ProjectDefinitions: {
  name: '${take(deployment().name, 36)}_${uniqueString(string(ProjectDefinition), 'deployProject')}'
  params: {
    DeploymentContext: DeploymentContext
    OrganizationDefinition: OrganizationDefinition
    OrganizationContext: deployOrganization.outputs.OrganizationContext
    ProjectDefinition: ProjectDefinition
  }
}]


module deployEnvironment 'resources/deployEnvironment.bicep' = [for EnvironmentMap in EnvironmentMaps: {
  name: '${take(deployment().name, 36)}_${uniqueString(string(EnvironmentMap))}'
  scope: subscription(EnvironmentMap.EnvironmentDefinition.subscription)
  params: {
    OrganizationDefinition: OrganizationDefinition
    OrganizationContext: deployOrganization.outputs.OrganizationContext
    ProjectDefinition: EnvironmentMap.ProjectDefinition
    ProjectContext: deployProject[EnvironmentMap.ProjectDefinitionIndex].outputs.ProjectContext
    EnvironmentDefinition: EnvironmentMap.EnvironmentDefinition
  }
}]
