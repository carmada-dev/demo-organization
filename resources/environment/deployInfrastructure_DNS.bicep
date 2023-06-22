targetScope = 'resourceGroup'

// ============================================================================================

param OrganizationDefinition object
param OrganizationContext object
param ProjectDefinition object
param ProjectContext object
param EnvironmentDefinition object
param InitialDeployment bool

// ============================================================================================

var ResourceName = '${ProjectDefinition.name}-${EnvironmentDefinition.name}'

// ============================================================================================

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: ResourceName
}

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: toLower('${EnvironmentDefinition.name}.${ProjectDefinition.name}.${OrganizationDefinition.zone}')
  location: 'global'
}

resource dnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${ResourceName}-${guid(virtualNetwork.id)}'
  parent: dnsZone
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

resource dnsZoneLinkProject 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${ResourceName}-${guid(ProjectContext.NetworkId)}'
  parent: dnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: ProjectContext.NetworkId
    }
  }
}

