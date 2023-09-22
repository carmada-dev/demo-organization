targetScope = 'resourceGroup'

// ============================================================================================

param OrganizationDefinition object
param OrganizationContext object
param ProjectDefinition object
param InitialDeployment bool

// ============================================================================================

var ProjectSettings = contains(ProjectDefinition, 'settings') ? ProjectDefinition.settings : {}
var ProjectSecrets = contains(ProjectDefinition, 'secrets') ? ProjectDefinition.secrets : {}

// ============================================================================================

resource routes 'Microsoft.Network/routeTables@2022-07-01' = {
  name: ProjectDefinition.name
  location: OrganizationDefinition.location
}

module splitSubnets '../tools/splitSubnets.bicep' = {
  name: '${take(deployment().name, 36)}_splitSubnets'
  params: {
    IPRange: ProjectDefinition.ipRange
    SubnetCount: 2
  }
}

resource virtualNetworkCreate 'Microsoft.Network/virtualNetworks@2022-07-01' = if (InitialDeployment) {
  name: ProjectDefinition.name
  location: OrganizationDefinition.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        ProjectDefinition.ipRange
      ]
    }
    dhcpOptions: {
      dnsServers: [
        '168.63.129.16'
        OrganizationContext.GatewayIP
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: splitSubnets.outputs.Subnets[0]
          routeTable: {
            id: routes.id
          }
        }
      }
      {
        name: 'gateway'
        properties: {
          addressPrefix: splitSubnets.outputs.Subnets[1]
        }
      }
    ]
  }
}

module virtualNetworkPeer '../tools/peerNetworks.bicep' = if (InitialDeployment) {
  name: '${take(deployment().name, 36)}_${uniqueString(string(ProjectDefinition), 'virtualNetworkPeer')}'
  scope: subscription()
  params: {
    HubNetworkId: OrganizationContext.NetworkId
    HubPeeringPrefix: 'organization'
    HubGatewayIP: OrganizationContext.GatewayIP
    SpokeNetworkIds: [ virtualNetworkCreate.id ]        
    SpokePeeringPrefix: 'project'
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: ProjectDefinition.name
}

resource settingsStore 'Microsoft.AppConfiguration/configurationStores@2022-05-01' = if (InitialDeployment) {
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

resource settingsVault 'Microsoft.KeyVault/vaults@2022-07-01' = if (InitialDeployment) {
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

module vault_KeyVaultSecretsUser '../tools/assignRoleOnKeyVault.bicep' = if (InitialDeployment) {
  name: '${take(deployment().name, 36)}_${uniqueString(settingsVault.id, 'vault_KeyVaultSecretsUser')}'
  params: {
    KeyVaultName: settingsVault.name
    RoleNameOrId: 'Key Vault Secrets User'
    PrincipalIds: [ settingsStore.identity.principalId ]
  }
}

module deploySettings '../tools/deploySettings.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(deployment().name)}'
  scope: resourceGroup()
  params: {
    ConfigurationStoreName: settingsStore.name
    ConfigurationVaultName: settingsVault.name
    Settings: union(ProjectSettings, {
      ProjectNetworkName: virtualNetwork.name
      ProjectNetworkId: virtualNetwork.id
      PrivateLinkDnsZoneRG: '${resourceGroup().id}-PL'
    })
    Secrets: union(ProjectSecrets, {

    })
  }
}

module deployInfrastructure_DNS 'deployInfrastructure_DNS.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(ProjectDefinition), 'deployInfrastructure_DNS')}'
  dependsOn: [
    virtualNetworkCreate
    settingsStore
    settingsVault
  ]
  params: {
    InitialDeployment: InitialDeployment
    OrganizationContext: OrganizationContext
    OrganizationDefinition: OrganizationDefinition
    ProjectDefinition: ProjectDefinition
  }
}

module deployInfrastructure_NVA 'deployInfrastructure_NVA.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(ProjectDefinition), 'deployInfrastructure_NVA')}'
  dependsOn: [
    virtualNetworkCreate
    settingsStore
    settingsVault
 ]
  params: {
    InitialDeployment: InitialDeployment
    OrganizationContext: OrganizationContext
    OrganizationDefinition: OrganizationDefinition
    ProjectDefinition: ProjectDefinition
  }
}

// ============================================================================================

output NetworkId string = InitialDeployment ? virtualNetworkCreate.id : virtualNetwork.id
output GatewayIP string = deployInfrastructure_NVA.outputs.GatewayIP
