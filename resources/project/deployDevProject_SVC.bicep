targetScope = 'resourceGroup'

// ============================================================================================

param OrganizationDefinition object
param OrganizationContext object
param ProjectDefinition object
param ProjectContext object

// ============================================================================================

var ResourcePrefix = '${ProjectDefinition.name}-SVC'
var ResourceLocation = resourceGroup().location

var GitHubCR = first(filter(OrganizationDefinition.registries, registry => endsWith(toLower(registry.server), 'ghcr.io') && (toLower(registry.username) == 'carmada-dev')))

var IPPools = map(ProjectDefinition.environments, env => {
  name: toUpper('IPPOOL_${env.name}')
  value: join(contains(env, 'ipPools') ? env.ipPools : [], ', ')
})

// ============================================================================================

resource project 'Microsoft.DevCenter/projects@2022-11-11-preview' existing = {
  name: ProjectDefinition.name
}

resource settingsStore 'Microsoft.AppConfiguration/configurationStores@2022-05-01' existing = {
  name: ProjectDefinition.name
}

resource settingsVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: ProjectDefinition.name
}

resource serviceStorage 'Microsoft.Storage/storageAccounts@2023-01-01'= {
  name: 'service${uniqueString(resourceGroup().id)}'
  location: ResourceLocation
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource serviceHost 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: ResourcePrefix
  location: ResourceLocation
  kind: 'linux'
  sku: {
    name: 'S1' 
    tier: 'Standard'
  }
  properties: {
    reserved: true
  }
}

resource serviceInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: ResourcePrefix
  location: ResourceLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: OrganizationContext.WorkspaceId
  }
}

resource serviceIPAlloc 'Microsoft.Web/sites@2022-09-01' = if (!empty(GitHubCR)) {
  name: '${ResourcePrefix}-IPAlloc'
  location: ResourceLocation
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: serviceHost.id
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    clientAffinityEnabled: false
    siteConfig: {
      linuxFxVersion: 'DOCKER|${GitHubCR.server}/carmada-dev/ipalloc:main'
      alwaysOn: true
      healthCheckPath: '/health'
      use32BitWorkerProcess: false
      ftpsState: 'FtpsOnly'
      appSettings: concat([
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${serviceStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${serviceStorage.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${GitHubCR.server}'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: GitHubCR.username
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: GitHubCR.password
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: serviceInsights.properties.ConnectionString
        }
        {
          name: 'PROJECT_RESOURCEID'
          value: project.id
        }
      ], IPPools)
    }
  }
}

module projectReaderRoleAssignment '../tools/assignRoleOnDevProject.bicep' = if (!empty(GitHubCR)) {
  name: '${take(deployment().name, 36)}_${uniqueString('projectReaderRoleAssignment')}'
  params: {
    DevProjectName: project.name
    RoleNameOrId: 'Reader'
    PrincipalIds: [ serviceIPAlloc.identity.principalId ]
  }
}

module deploySettings '../tools/deploySettings.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(deployment().name)}'
  params: {
    ConfigurationStoreName: settingsStore.name
    ConfigurationVaultName: settingsVault.name
    Settings: {
      'IPAlloc-URL': !empty(GitHubCR) ? 'https://${serviceIPAlloc.properties.defaultHostName}' : ''
    }
  }
}

// ============================================================================================

output Services array = [
  {
    name: 'IPAlloc'
    url: !empty(GitHubCR) ? 'https://${serviceIPAlloc.properties.defaultHostName}' : ''
    principalId: !empty(GitHubCR) ? serviceIPAlloc.identity.principalId : ''
  }
]
