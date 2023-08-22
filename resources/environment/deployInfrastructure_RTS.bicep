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

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: ResourceName
}

resource snet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  name: 'RouteServerSubnet'
  parent: vnet
}

resource routeServerPIP 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: '${ResourceName}-RS'
  location: OrganizationDefinition.location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource routeServer 'Microsoft.Network/virtualHubs@2023-04-01' = {
  name: '${ResourceName}-RS'
  location: OrganizationDefinition.location
  properties: {
    sku: 'Standard'
  }
}

resource routeServerIPC 'Microsoft.Network/virtualHubs/ipConfigurations@2023-04-01' = {
  name: 'default'
  parent: routeServer
  properties: {
    subnet: {
      id: snet.id
    }
    publicIPAddress: {
      id: routeServerPIP.id
    }
  }
}
