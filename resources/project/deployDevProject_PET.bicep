targetScope = 'resourceGroup'

// ============================================================================================

param ProjectName string

param ProjectUsers array

param EnvironmentName string

param EnvironmentSubscription string

param EnvironmentResourceGroupId string

param EnvironmentNetworkId string

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

var creatorRoleAssignment = {
  roles: {
    '${RoleDefinitionId.Contributor}': {}
  }
}

var userRoleAssignments = map(ProjectUsers, usr => {
  '${usr}': {
    roles: {
      '${RoleDefinitionId.Reader}': {}
    }
  }
})

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
    creatorRoleAssignment: creatorRoleAssignment
    userRoleAssignments: reduce(userRoleAssignments, {}, (cur, next) => union(cur, next))
  }
}

module deploySettings '../tools/deploySettings.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString('deploySettings', EnvironmentName)}'
  scope: resourceGroup()
  params: {
    ConfigurationStoreName: ConfigurationStoreName
    ConfigurationVaultName: ConfigurationVaultName
    Label: EnvironmentName
    ReaderPrincipalIds: [
      environmentType.identity.principalId
    ]
    Settings: {
      EnvironmentNetworkId: EnvironmentNetworkId
      EnvironmentResourceGroupId: EnvironmentResourceGroupId
    }
    Secrets: {

    }
  }
}

module assignRoleOnResourceGroup_PrivateLink '../tools/assignRoleOnResourceGroup.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString('assignRoleOnResourceGroup_PrivateLink', environmentType.id)}'
  scope: resourceGroup('${resourceGroup().name}-PL')
  params: {
    RoleNameOrId: 'Contributor'
    PrincipalIds: [
      environmentType.identity.principalId
    ]
  }
}

module assignRoleOnResourceGroup_Environment '../tools/assignRoleOnResourceGroup.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString('assignRoleOnResourceGroup_Environment', environmentType.id)}'
  scope: resourceGroup(split(EnvironmentResourceGroupId, '/')[2], split(EnvironmentResourceGroupId, '/')[4])
  params: {
    RoleNameOrId: 'Contributor'
    PrincipalIds: [
      environmentType.identity.principalId
    ]
  }
}

module assignRoleOnVirtualNetwork '../tools/assignRoleOnVirtualNetwork.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString('assignRoleOnVirtualNetwork', environmentType.id)}'
  params: {
    VirtualNetworkName: ProjectName
    RoleNameOrId: 'Contributor'
    PrincipalIds: [
      environmentType.identity.principalId
    ]
  }
}

// ============================================================================================

output EnvironmentTypePrincipalId string = environmentType.identity.principalId
