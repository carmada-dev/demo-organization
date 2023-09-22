targetScope = 'resourceGroup'

// ============================================================================================

param OrganizationDefinition object
param OrganizationContext object
param ProjectDefinition object
param InitialDeployment bool

// ============================================================================================

var dnsZoneNames = concat(
  [ toLower('${ProjectDefinition.name}.${OrganizationDefinition.zone}') ], 
  map(ProjectDefinition.environments, env => toLower('${env.name}.${ProjectDefinition.name}.${OrganizationDefinition.zone}')))

// ============================================================================================

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: ProjectDefinition.name
}

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = [for dnsZoneName in dnsZoneNames: {
  name: dnsZoneName
  location: 'global'
}]

resource dnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for i in range(0, length(dnsZoneNames)): {
  name: '${virtualNetwork.name}-${guid(virtualNetwork.id)}'
  parent: dnsZone[i]
  location: 'global'
  properties: {
    registrationEnabled: (i == 0)
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}]
