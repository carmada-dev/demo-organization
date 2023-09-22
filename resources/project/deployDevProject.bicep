targetScope = 'resourceGroup'

// ============================================================================================

param OrganizationDefinition object
param OrganizationContext object
param ProjectDefinition object
param ProjectContext object
param DeploymentContext object

// ============================================================================================

var DevBoxes = contains(OrganizationDefinition, 'devboxes') ? OrganizationDefinition.devboxes : []

var ProjectAdmins = contains(ProjectDefinition, 'admins') ? ProjectDefinition.admins : []
var ProjectUsers = contains(ProjectDefinition, 'users') ? ProjectDefinition.users : []

// ============================================================================================

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: ProjectDefinition.name
}

resource defaultSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  name: 'default'
  parent: virtualNetwork
}

resource settingsStore 'Microsoft.AppConfiguration/configurationStores@2022-05-01' existing = {
  name: ProjectDefinition.name
}

resource settingsVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: ProjectDefinition.name
}

resource project 'Microsoft.DevCenter/projects@2022-11-11-preview' = {
  name: ProjectDefinition.name
  location: OrganizationDefinition.location
  properties: {
    devCenterId: OrganizationContext.DevCenterId
  }
}

module deployDevProject_SVC 'deployDevProject_SVC.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(ProjectDefinition), 'deployDevProject_SVC')}'
  dependsOn: [
    project
  ]
  params: {
    OrganizationContext: OrganizationContext
    OrganizationDefinition: OrganizationDefinition
    ProjectDefinition: ProjectDefinition
    ProjectContext: ProjectContext
  }
}

module projectAdminRoleAssignment '../tools/assignRoleOnDevProject.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString('projectAdminRoleAssignment')}'
  params: {
    DevProjectName: project.name
    RoleNameOrId: 'DevCenter Project Admin'
    PrincipalIds: ProjectAdmins
    PrincipalType: 'User'
  }
}

module devBoxUserRoleAssignment '../tools/assignRoleOnDevProject.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString('devBoxUserRoleAssignment')}'
  params: {
    DevProjectName: project.name
    RoleNameOrId: 'DevCenter Dev Box User'
    PrincipalIds: ProjectUsers
    PrincipalType: 'User'
  }
}

module deploymentEnvironmentUserRoleAssignment '../tools/assignRoleOnDevProject.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString('deploymentEnvironmentUserRoleAssignment')}'
  params: {
    DevProjectName: project.name
    RoleNameOrId: 'Deployment Environments User'
    PrincipalIds: ProjectUsers
    PrincipalType: 'User'
  }
}

resource networkConnection 'Microsoft.DevCenter/networkConnections@2022-11-11-preview' = {
  name: ProjectDefinition.name
  location: OrganizationDefinition.location
  properties: {
    domainJoinType: 'AzureADJoin'
    subnetId: defaultSubnet.id
    networkingResourceGroupName: '${resourceGroup().name}-NI'
  }
}

module deployAzureNetworkConnection 'deployDevProject_ANC.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(networkConnection.id)}'
  scope: resourceGroup(split(OrganizationContext.DevCenterId, '/')[2], split(OrganizationContext.DevCenterId, '/')[4])
  params: {
    DevCenterName: last(split(OrganizationContext.DevCenterId, '/'))
    NetworkConnectionId: networkConnection.id
  }
}

module deployDevBoxPools '../tools/deployDevBoxPools.bicep' = [for DevBox in DevBoxes: {
  name: '${take(deployment().name, 36)}_${uniqueString(string(DevBox), 'deployDevBoxPools')}'
  dependsOn: [
    deployAzureNetworkConnection
  ]
  params: {
    ProjectName: project.name 
    ProjectLocation: project.location
    NetworkConnectionName: networkConnection.name
    DevBoxDefinitionName: DevBox.name 
    Pools: contains(DevBox, 'pools') ? DevBox.pools : []
  }
}]

module deployProjectEnvironmentType 'deployDevProject_PET.bicep' = [for (EnvironmentDefinition, EnvironmentDefinitionIndex) in ProjectDefinition.environments: {
  name: '${take(deployment().name, 36)}_${uniqueString('attachEnvironmentType', string(EnvironmentDefinition))}'
  params: {
    ProjectName: project.name
    ProjectUsers: ProjectDefinition.users
    EnvironmentName: EnvironmentDefinition.name
    EnvironmentSubscription: EnvironmentDefinition.subscription
    ConfigurationStoreName: settingsStore.name
    ConfigurationVaultName: settingsVault.name
  }  
}]

resource gallery 'Microsoft.Compute/galleries@2021-10-01' = {
  name: ProjectDefinition.name
  location: OrganizationDefinition.location
}

module galleryContributorRoleAssignment '../tools/assignRoleOnComputeGallery.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'galleryContributorRoleAssignment')}'
  params: {
    ComputeGalleryName: gallery.name
    RoleNameOrId: 'Contributor'
    PrincipalIds: [ OrganizationContext.PrincipalId ]
  }
}

module galleryReaderRoleAssignment '../tools/assignRoleOnComputeGallery.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'galleryReaderRoleAssignment')}'
  params: {
    ComputeGalleryName: gallery.name
    RoleNameOrId: 'Reader'
    PrincipalIds: [ DeploymentContext.Windows365PrinicalId ]
  }
}

module attachGallery '../tools/deployGalleryRegistration.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(gallery.id, 'galleryReaderRoleAssignment')}'
  scope: resourceGroup(split(OrganizationContext.DevCenterId, '/')[2], split(OrganizationContext.DevCenterId, '/')[4])
  dependsOn: [
    galleryContributorRoleAssignment
    galleryReaderRoleAssignment
  ]
  params: {
    DevCenterName: last(split(OrganizationContext.DevCenterId, '/'))
    GalleryId: gallery.id
  }
}

// ============================================================================================

output NetworkConnectionId string = networkConnection.id
output ProjectId string = project.id

output Environments array = [for i in range(0, length(ProjectDefinition.environments)): {
  Name: ProjectDefinition.environments[i].name
  TypeId: deployProjectEnvironmentType[i].outputs.TypeId
  PrincipalId: deployProjectEnvironmentType[i].outputs.PrincipalId
}]
