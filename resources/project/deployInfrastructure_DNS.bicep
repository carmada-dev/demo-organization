targetScope = 'resourceGroup'

// ============================================================================================

param OrganizationDefinition object
param OrganizationContext object
param ProjectDefinition object
param InitialDeployment bool

// ============================================================================================

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: ProjectDefinition.name
}

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: toLower('${ProjectDefinition.name}.${OrganizationDefinition.zone}')
  location: 'global'
}

resource dnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${virtualNetwork.name}-${guid(virtualNetwork.id)}'
  parent: dnsZone
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

