targetScope = 'resourceGroup'

// ============================================================================================

param OrganizationDefinition object
param OrganizationWorkspaceId string
param InitialDeployment bool

// ============================================================================================

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: OrganizationDefinition.name
}

resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  name: 'GatewaySubnet'
  parent: virtualNetwork
}

resource gatewayPIP 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: '${OrganizationDefinition.name}-GW'
  location: OrganizationDefinition.location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource gatewayCreate 'Microsoft.Network/virtualNetworkGateways@2022-11-01' = if (InitialDeployment) {
  name: '${OrganizationDefinition.name}-GW'
  location: OrganizationDefinition.location
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnet.id
          }
          publicIPAddress: {
            id: gatewayPIP.id
          }
        }
      }
    ]
    sku: {
       name: 'VpnGw2'
       tier: 'VpnGw2'
    }
    vpnGatewayGeneration: 'Generation2'
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    activeActive: false
  }
}

resource gateway 'Microsoft.Network/virtualNetworkGateways@2022-11-01' existing = {
  name: '${OrganizationDefinition.name}-GW'
}

// ============================================================================================

output VpnGatewayId string = InitialDeployment ? gatewayCreate.id : gateway.id
