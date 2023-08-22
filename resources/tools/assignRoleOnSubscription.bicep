targetScope = 'subscription'

// ============================================================================================

param RoleNameOrId string
param PrincipalType string = 'ServicePrincipal'
param PrincipalIds array = []

// ============================================================================================

var BuiltInRoleDefinitions = loadJsonContent('../data/builtInRolesDefinitions.json')

// ============================================================================================

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: length(filter(BuiltInRoleDefinitions, rd => rd.role == RoleNameOrId)) == 1 ? filter(BuiltInRoleDefinitions, rd => rd.role == RoleNameOrId)[0].id : RoleNameOrId
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = [for principalId in PrincipalIds: {
  name: guid(subscription().id, roleDefinition.id, principalId)
  properties: {
    roleDefinitionId: roleDefinition.id
    principalId: principalId
    principalType: PrincipalType
  }
}]
