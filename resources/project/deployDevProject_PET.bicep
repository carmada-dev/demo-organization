targetScope = 'resourceGroup'

// ============================================================================================

param ProjectName string

param ProjectUsers array

param EnvironmentName string

param EnvironmentSubscription string

param EnvironmentTags object = {}

param ConfigurationStoreName string

param ConfigurationVaultName string

// ============================================================================================

#disable-next-line no-loc-expr-outside-params
var ResourceLocation = resourceGroup().location

var RoleDefinitionId = {
  Contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  Reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

var EnvironmentTypeCreatorRoleAssignment = {
  roles: {
    '${RoleDefinitionId.Contributor}': {}
  }
}

var EnvironmentTypeUserRoleAssignments = map(ProjectUsers, usr => {
  '${usr}': {
    roles: {
      '${RoleDefinitionId.Reader}': {}
    }
  }
})

var EnvironmentTypeRolesOnConfigurationStore = [
  'Reader'
  'App Configuration Data Reader'
]

var EnvironmentTypeRolesOnConfigurationVault = [
  'Reader'
  'Key Vault Secrets User'
]

// ============================================================================================

resource project 'Microsoft.DevCenter/projects@2022-11-11-preview' existing = {
  name: ProjectName
}

resource configurationStore 'Microsoft.AppConfiguration/configurationStores@2022-05-01' existing = {
  name: ConfigurationStoreName
}

resource configurationVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: ConfigurationVaultName
}

resource environmentType 'Microsoft.DevCenter/projects/environmentTypes@2022-11-11-preview' = {
  name: EnvironmentName
  parent: project
  identity: {
    type: 'SystemAssigned'
  }
  tags: union(EnvironmentTags, {
    'hidden-ConfigurationLabel': EnvironmentName
    'hidden-ConfigurationStoreId': configurationStore.id
    'hidden-ConfigurationVaultId': configurationVault.id
  })
  properties: {
    deploymentTargetId: startsWith(EnvironmentSubscription, '/') ? EnvironmentSubscription : '/subscriptions/${EnvironmentSubscription}'
    status: 'Enabled'
    creatorRoleAssignment: EnvironmentTypeCreatorRoleAssignment
    userRoleAssignments: reduce(EnvironmentTypeUserRoleAssignments, {}, (cur, next) => union(cur, next))
  }
}

module deploySettings '../tools/deploySettings.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString('deploySettings', EnvironmentName)}'
  scope: resourceGroup()
  params: {
    ConfigurationStoreName: configurationStore.name
    ConfigurationVaultName: configurationVault.name
    Label: EnvironmentName
    ReaderPrincipalIds: [
      environmentType.identity.principalId
    ]
    Settings: {
    }
    Secrets: {
    }
  }
}

// Grant EnvironmentType identity permissions on the project's PrivateLink resource group
// to support private DNS zone creation as part of environment deployments.
module assignRoleOnResourceGroup_PrivateLink_Contributor '../tools/assignRoleOnResourceGroup.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString('assignRoleOnResourceGroup_PrivateLink_Contributor', environmentType.id)}'
  scope: resourceGroup('${resourceGroup().name}-PL')
  params: {
    RoleNameOrId: 'Contributor'
    PrincipalIds: [
      environmentType.identity.principalId
    ]
  }
}

// Grant EnvironmentType identity permissions on the project's PrivateLink resource group
// to support private DNS zone linking as part of environment deployments.
module assignRoleOnResourceGroup_PrivateLink_PrivateDNSZoneContributor '../tools/assignRoleOnResourceGroup.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString('assignRoleOnResourceGroup_PrivateLink_PrivateDNSZoneContributor', environmentType.id)}'
  scope: resourceGroup('${resourceGroup().name}-PL')
  params: {
    RoleNameOrId: 'Private DNS Zone Contributor'
    PrincipalIds: [
      environmentType.identity.principalId
    ]
  }
}


// Grant EnvironmentType identity permissions on the project's network to enable PrivateLink
// registrations if they are created during an environment deployment.
module assignRoleOnVirtualNetwork_PrivateLink '../tools/assignRoleOnVirtualNetwork.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString('assignRoleOnVirtualNetwork_PrivateLink', environmentType.id)}'
  params: {
    VirtualNetworkName: ProjectName
    RoleNameOrId: 'Contributor'
    PrincipalIds: [
      environmentType.identity.principalId
    ]
  }
}

// Grant EnvironmentType identity permissions on the projects configuration store to
// read project specific configuration values during environment deployments.
module assingRoleOnAppConfiguration_ConfigurationStore '../tools/assignRoleOnAppConfiguration.bicep' = [for role in EnvironmentTypeRolesOnConfigurationStore: {
  name: '${take(deployment().name, 36)}_${uniqueString('assingRoleOnAppConfiguration_ConfigurationStore', environmentType.id, role)}'
  params: {
    AppConfigurationName: configurationStore.name
    RoleNameOrId: role
    PrincipalIds: [ 
      environmentType.identity.principalId 
    ]
  }
}]

// Grant EnvironmentType identity permissions on the projects configuration vault to
// read project specific configuration secrets during environment deployments.
module assignRoleOnKeyVault_ConfigurationVault '../tools/assignRoleOnKeyVault.bicep' = [for role in EnvironmentTypeRolesOnConfigurationVault: {
  name: '${take(deployment().name, 36)}_${uniqueString('assignRoleOnKeyVault_ConfigurationVault', environmentType.id, role)}'
  params: {
    KeyVaultName: configurationVault.name
    RoleNameOrId: role
    PrincipalIds: [ 
      environmentType.identity.principalId 
    ]
  }
}]

// ============================================================================================

output TypeId string = environmentType.id
output PrincipalId string = environmentType.identity.principalId
