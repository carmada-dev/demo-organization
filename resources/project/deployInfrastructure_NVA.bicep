targetScope = 'resourceGroup'

// ============================================================================================

param OrganizationDefinition object
param OrganizationContext object
param ProjectDefinition object
param InitialDeployment bool

// ============================================================================================

var ResourceName = '${ProjectDefinition.name}-GW'

var GatewayDefinition = contains(ProjectDefinition, 'gateway') ? ProjectDefinition.gateway : {}
var GatewayIPSegments = split(split(snet.properties.addressPrefix, '/')[0],'.')
var GatewayIP = '${join(take(GatewayIPSegments, 3),'.')}.${int(any(last(GatewayIPSegments)))+4}'

var WireguardDefinition = contains(ProjectDefinition, 'wireguard') ? ProjectDefinition.wireguard : {}
var WireguardPort = 51820

var EnvironmentPeerings = filter(vnet.properties.virtualNetworkPeerings, peer => startsWith(peer.name, 'environment-'))
var EnvironmentAddressPrefixes = flatten(map(EnvironmentPeerings, peer => peer.properties.remoteAddressSpace.addressPrefixes))

var DnsForwarderArguments = join([
  join(map(EnvironmentAddressPrefixes, prefix => '-c \'${prefix}\''), ' ')                          // mark environment networks as valid clients
  '-f \'168.63.129.16\''                                                                            // forward request to the Azure default DNS
  '-f \'${OrganizationContext.GatewayIP}\''                                                         // forward request to the organization DNS
], ' ')

var NetForwarderArguments = join([
  join(map(EnvironmentAddressPrefixes, prefix => '-f \'${prefix}\''), ' ')                          // forward traffic from environment networks
  '-b \'${OrganizationDefinition.ipRange}\''                                                        // block forward request from organization network
], ' ')

var WireguardArguments = join([
  '-e \'${gatewayPIP.properties.ipAddress}:${WireguardPort}\''                                      // Endpoint (the Wireguard public endpoint)
  '-h \'${ProjectDefinition.ipRange}\''                                                             // Home Range (the Project's IPRange)
  '-v \'${WireguardDefinition.ipRange}\''                                                           // Virtual Range (internal Wireguard IPRange)
  join(map(WireguardDefinition.islands, island => '-i \'${island}\''), ' ')                         // Island Ranges (list of Island IPRanges)
  join(map(WireguardDefinition.devices, device => '-d \'${first(split(device, '/'))}\''), ' ')      // Device Address (list of Device IPAddress)
], ' ')

var InitScriptBaseUri = 'https://raw.githubusercontent.com/carmada-dev/demo-organization/main/resources/project/scripts/'
var InitScriptNames = [ 'initMachine.sh', 'setupDnsForwarder.sh', 'setupNetForwarder.sh', 'setupWireGuard.sh' ]
var InitCommand = join(filter([
  './initMachine.sh'
  './setupDnsForwarder.sh ${DnsForwarderArguments}'
  './setupNetForwarder.sh ${NetForwarderArguments}'
  './setupWireGuard.sh ${WireguardArguments}'
  'sudo shutdown -r 1'
], item => !empty(item)), ' && ')

var DefaultRules = [
  {
    name: 'SSH'
    properties: {
      priority: 1000
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: OrganizationDefinition.ipRange
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '22'
    }
  }
  {
    name: 'Wireguard-Tunnel'
    properties: {
      priority: 2000
      protocol: 'Udp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: 'Internet'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '${WireguardPort}'
    }
  }
]

var IslandRules = [for i in range(1, length(WireguardDefinition.islands)): {
  name: 'Wireguard-Island${i}'
  properties: {
    priority: (2000 + i)
    protocol: '*'
    access: 'Allow'
    direction: 'Inbound'
    sourceAddressPrefix: 'VirtualNetwork'
    sourcePortRange: '*'
    destinationAddressPrefix: WireguardDefinition.islands[i-1]
    destinationPortRange: '*'
  }
}]

// ============================================================================================

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: ProjectDefinition.name
}

resource snet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  name: 'gateway'
  parent: vnet
}

resource defaultRoutes 'Microsoft.Network/routeTables@2022-07-01' existing = {
  name: vnet.name
}

resource defaultRoute 'Microsoft.Network/routeTables/routes@2022-07-01' = [for (island, islandIndex) in WireguardDefinition.islands : {
  name: 'Island${islandIndex + 1}'
  parent: defaultRoutes
  properties: {
    addressPrefix: island
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: gatewayNIC.properties.ipConfigurations[0].properties.privateIPAddress
  }
}]

resource gatewayPIP 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: ResourceName
  location: OrganizationDefinition.location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource gatewayNSG 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: ResourceName
  location: OrganizationDefinition.location
  properties: {
    securityRules: concat(DefaultRules, IslandRules)
  }
}

resource gatewayNIC 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: ResourceName
  location: OrganizationDefinition.location
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          subnet: {
            id: snet.id
          }
          privateIPAddress: GatewayIP
          privateIPAllocationMethod: 'Static'
          publicIPAddress: {
            id: gatewayPIP.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: gatewayNSG.id
    }
    enableIPForwarding: true
  }
}

resource availabilitySet 'Microsoft.Compute/availabilitySets@2022-08-01' = {
  name: ResourceName
  location: OrganizationDefinition.location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 2
  }
}

resource gateway 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: ResourceName
  location: OrganizationDefinition.location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    availabilitySet: {
      id: availabilitySet.id
    }
    storageProfile: {
      osDisk: {
        name: ResourceName
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-minimal-jammy'
        sku: 'minimal-22_04-lts'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: gatewayNIC.id
        }
      ]
    }
    osProfile: {
      computerName: 'gateway'
      adminUsername: GatewayDefinition.username
      adminPassword: GatewayDefinition.password
    }
  }
}

resource gatewayInit 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = {
  name: 'Init'
  location: OrganizationDefinition.location
  parent: gateway
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    forceUpdateTag: guid(deployment().name)
    autoUpgradeMinorVersion: true
    settings: {      
      fileUris: map(InitScriptNames, name => uri(InitScriptBaseUri, name))
      commandToExecute: InitCommand
    }
  }
}

// ============================================================================================

output GatewayIP string = gatewayNIC.properties.ipConfigurations[0].properties.privateIPAddress
