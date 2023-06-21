targetScope = 'resourceGroup'

// ============================================================================================

param ResourceType string

param ResourceName string

param OperationId string = newGuid()

// ============================================================================================

#disable-next-line no-loc-expr-outside-params
var ResourceLocation = resourceGroup().location
var ResourceId = resourceId(ResourceType, ResourceName)

// ============================================================================================

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: 'ResourceExists'
  location: ResourceLocation
}

resource readerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

resource readerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, readerRoleDefinition.id, identity.id)
  properties: {
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: readerRoleDefinition.id
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  #disable-next-line use-stable-resource-identifiers
  name: 'ResourceExists-${guid(ResourceId, OperationId)}'
  location: ResourceLocation
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  dependsOn: [
    readerRoleAssignment
  ]
  kind: 'AzureCLI'
  properties: {
    forceUpdateTag: OperationId
    azCliVersion: '2.40.0'
    timeout: 'PT30M'
    environmentVariables: [
      {
        name: 'ResourceId'
        value: ResourceId
      }
    ]
    scriptContent: loadTextContent('testResourceExists.sh')
    cleanupPreference: 'Always'
    retentionInterval: 'PT1H'
    // retentionInterval: 'P1D'
  }
}

// ============================================================================================

output ResourceId string = ResourceId
output ResourceExists bool = deploymentScript.properties.outputs.resourceExists
output ResourceProperties object = deploymentScript.properties.outputs.resourceProperties
output ResourceTags object = deploymentScript.properties.outputs.resourceTags


