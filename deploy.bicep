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

// ============================================================================================


// Deploy Organization
// --------------------------------------------------------------------------------------------

resource organizationResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'ORG-${OrganizationDefinition.name}'
  location: OrganizationDefinition.location
}

resource organizationResourceGroupPrivateLink 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'ORG-${OrganizationDefinition.name}-PL'
  location: OrganizationDefinition.location
}

module testOrganizationNetworkExists 'resources/tools/testResourceExists.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'testOrganizationNetworkExists')}'
  scope: organizationResourceGroup
  params: {
    ResourceName: OrganizationDefinition.name
    ResourceType: 'Microsoft.Network/virtualNetworks'
  }
}

module organizationInfrastructure 'resources/organization/deployInfrastructure.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition))}'
  scope: organizationResourceGroup
  params: {
    OrganizationDefinition: OrganizationDefinition
    InitialDeployment: !testOrganizationNetworkExists.outputs.ResourceExists
  }
}


// Deploy Project/s
// --------------------------------------------------------------------------------------------

resource projectResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = [for ProjectDefinition in ProjectDefinitions: {
  name: 'PRJ-${ProjectDefinition.name}'
  location: OrganizationDefinition.location
}]

resource projectResourceGroupPrivateLink 'Microsoft.Resources/resourceGroups@2022-09-01' = [for ProjectDefinition in ProjectDefinitions: {
  name: 'PRJ-${ProjectDefinition.name}-PL'
  location: OrganizationDefinition.location
}]

module testProjectNetworkExists 'resources/tools/testResourceExists.bicep' = [for (ProjectDefinition, ProjectIndex) in ProjectDefinitions: {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'testProjectNetworkExists')}'
  scope: projectResourceGroup[ProjectIndex]
  params: {
    ResourceName: ProjectDefinition.name
    ResourceType: 'Microsoft.Network/virtualNetworks'
  }
}]

module projectInfrastructure 'resources/project/deployInfrastructure.bicep'= [for (ProjectDefinition, ProjectIndex) in ProjectDefinitions: {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition))}'
  scope: projectResourceGroup[ProjectIndex]
  params: {
    OrganizationDefinition: OrganizationDefinition
    ProjectDefinition: ProjectDefinition
    InitialDeployment: !testProjectNetworkExists[ProjectIndex].outputs.ResourceExists
  }
}]

