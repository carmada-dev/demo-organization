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

var EnvironmentMaps = [ for (em, emIndex) in flatten(map(range(0, length(ProjectDefinitions)), pdi => map(range(0, length(ProjectDefinitions[pdi].environments)), evi => {
  ProjectDefinitionIndex: pdi
  ProjectDefinition: ProjectDefinitions[pdi]
  EnvironmentDefinitionIndex: evi
  EnvironmentDefinition: ProjectDefinitions[pdi].environments[evi]
}))) : union(em, { Index: emIndex }) ]

// ============================================================================================

module deployOrganization './deployOrganization.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'deployOrganization')}'
  params: {
    DeploymentContext: DeploymentContext
    OrganizationDefinition: OrganizationDefinition
  }
}

module deployProject './deployProject.bicep' = [for ProjectDefinition in ProjectDefinitions: {
  name: '${take(deployment().name, 36)}_${uniqueString(string(ProjectDefinition), 'deployProject')}'
  params: {
    DeploymentContext: DeploymentContext
    OrganizationDefinition: OrganizationDefinition
    OrganizationContext: deployOrganization.outputs.OrganizationContext
    ProjectDefinition: ProjectDefinition
  }
}]

// the core infrastructure for the passed in organization and projects definitions passed in
// should now be ready now and we can start deploying platform engineering related resources
// like the DevCenter and related DevProjects.
 
module deployDevCenter './deployDevCenter.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'deployDevCenter')}'
  params: {
    DeploymentContext: DeploymentContext
    OrganizationDefinition: OrganizationDefinition
    OrganizationContext: deployOrganization.outputs.OrganizationContext
  }
}

module deployDevProject './deployDevProject.bicep' = [for (ProjectDefinition, ProjectDefinitionIndex) in ProjectDefinitions: {
  name: '${take(deployment().name, 36)}_${uniqueString(string(ProjectDefinition), 'deployDevProject')}'
  params: {
    DeploymentContext: DeploymentContext
    OrganizationDefinition: OrganizationDefinition
    OrganizationContext: deployDevCenter.outputs.OrganizationContext
    ProjectDefinition: ProjectDefinition
    ProjectContext: union(deployProject[ProjectDefinitionIndex].outputs.ProjectContext, {
      // we merge the environment contexts provided by the deploy project operation into
      // the project context to simplify context access. unfortunately this can't be done
      // using the deployProject template as part of the output generation (bicep limitations)
      EnvironmentContexts: deployProject[ProjectDefinitionIndex].outputs.EnvironmentContexts
    })
  }
}]
