targetScope = 'resourceGroup'

// ============================================================================================

param OrganizationDefinition object
param OrganizationContext object
param ProjectDefinition object
param ProjectContext object

// ============================================================================================

var DevBoxes = contains(OrganizationDefinition, 'devboxes') ? OrganizationDefinition.devboxes : []

var ProjectAdmins = contains(ProjectDefinition, 'admins') ? ProjectDefinition.admins : []
var ProjectUsers = contains(ProjectDefinition, 'users') ? ProjectDefinition.users : []

var ProjectSettings = contains(ProjectDefinition, 'settings') ? ProjectDefinition.settings : {}
var ProjectSecrets = contains(ProjectDefinition, 'secrets') ? ProjectDefinition.secrets : {}

// ============================================================================================

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: ProjectDefinition.name
}

resource defaultSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  name: 'default'
  parent: virtualNetwork
}

resource project 'Microsoft.DevCenter/projects@2022-11-11-preview' = {
  name: ProjectDefinition.name
  location: OrganizationDefinition.location
  properties: {
    devCenterId: OrganizationContext.DevCenterId
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
    EnvironmentResourceGroupId: ProjectContext.Environments[EnvironmentDefinitionIndex].ResourceGroupId
    EnvironmentNetworkId: ProjectContext.Environments[EnvironmentDefinitionIndex].NetworkId
    ConfigurationStoreName: settings.name
    ConfigurationVaultName: vault.name
  }  
}]

resource settings 'Microsoft.AppConfiguration/configurationStores@2022-05-01' = {
  name: ProjectDefinition.name
  location: OrganizationDefinition.location
  sku: {
    name: 'standard'
  }
  identity: {
    type: 'SystemAssigned'   
  }
  properties: {
    // disableLocalAuth: true
    publicNetworkAccess: 'Enabled'
  }
}

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: ProjectDefinition.name
  location: OrganizationDefinition.location
  properties: {
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

module vault_KeyVaultSecretsUser '../tools/assignRoleOnKeyVault.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(vault.id, 'vault_KeyVaultSecretsUser')}'
  params: {
    KeyVaultName: vault.name
    RoleNameOrId: 'Key Vault Secrets User'
    PrincipalIds: [ settings.identity.principalId ]
  }
}

module deploySettings '../tools/deploySettings.bicep' = {
  name: '${take(deployment().name, 36)}_deploySettings'
  scope: resourceGroup()
  params: {
    ConfigurationStoreName: settings.name
    ConfigurationVaultName: vault.name
    Settings: union(ProjectSettings, {
      ProjectNetworkName: virtualNetwork.name
      ProjectNetworkId: virtualNetwork.id
      PrivateLinkDnsZoneRG: '${resourceGroup().id}-PL'
    })
    Secrets: union(ProjectSecrets, {

    })
  }
}

// ============================================================================================

output NetworkConnectionId string = networkConnection.id
output ProjectId string = project.id

output Environments array = [for i in range(0, length(ProjectDefinition.environments)): union(ProjectContext.Environments[i], {
  Name: ProjectDefinition.environments[i].name
  TypeId: deployProjectEnvironmentType[i].outputs.TypeId
  PrincipalId: deployProjectEnvironmentType[i].outputs.PrincipalId
})]
