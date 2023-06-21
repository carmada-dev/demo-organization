targetScope = 'resourceGroup'

// ============================================================================================

param OrganizationDefinition object
param OrganizationWorkspaceId string
param InitialDeployment bool

// ============================================================================================

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: OrganizationDefinition.name
}

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: toLower(OrganizationDefinition.zone)
  location: 'global'
}

resource dnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'VNet-${guid(virtualNetwork.id)}'
  parent: dnsZone
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}
