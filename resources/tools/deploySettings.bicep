targetScope = 'resourceGroup'

// ============================================================================================

param ConfigurationStoreName string

param ConfigurationVaultName string

param Label string = ''

param Settings object = {}

@secure()
param Secrets object = {}

param ReaderPrincipalIds array = []

// ============================================================================================

var SettingItems = empty(Settings) ? [] : empty(Label) ? items(Settings) : map(items(Settings), item => {
  key: '${item.key}$${Label}'
  value: item.value
})

var SecretItems = empty(Secrets) ? [] : empty(Label) ? items(Secrets) : map(items(Secrets), item => {
  key: '${item.key}$${Label}'
  value: item.value
})

// ============================================================================================

resource appConfigurationStore 'Microsoft.AppConfiguration/configurationStores@2021-10-01-preview' existing = {
  name: ConfigurationStoreName
}

resource appConfigurationVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: ConfigurationVaultName
}

resource appConfigurationDataReaderRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '516239f1-63e1-4d78-a4de-a74fb236a071' // https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#app-configuration-data-reader
}

resource appConfigurationDataReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = [for ReaderPrincipalId in ReaderPrincipalIds: {
  name: guid(appConfigurationStore.id, appConfigurationDataReaderRoleDefinition.id, ReaderPrincipalId)
  scope: appConfigurationStore
  properties: {
    roleDefinitionId: appConfigurationDataReaderRoleDefinition.id
    principalType: 'ServicePrincipal'
    principalId: ReaderPrincipalId
  }
}] 

resource appConfigurationSettingItem 'Microsoft.AppConfiguration/configurationStores/keyValues@2021-10-01-preview' = [for Item in SettingItems: {
  parent: appConfigurationStore
  name: Item.key
  properties: {
    value: Item.value
  }
}] 

resource appConfigurationSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = [for Item in SecretItems: {
  parent: appConfigurationVault
  name: replace(Item.key, '$', '-')
  properties:{
    value: Item.value    
  }
}]

resource appConfigurationSecretItem 'Microsoft.AppConfiguration/configurationStores/keyValues@2021-10-01-preview' = [for (Item, Index) in SecretItems: {
  parent: appConfigurationStore
  name: Item.key
  properties: {
    value: string({ uri: appConfigurationSecret[Index].properties.secretUri })
  }
}] 

// ============================================================================================
