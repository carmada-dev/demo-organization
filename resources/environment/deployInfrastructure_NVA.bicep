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

var GatewayDefinition = contains(ProjectDefinition, 'gateway') ? ProjectDefinition.gateway : {}
var GatewayIPSegments = split(split(snet.properties.addressPrefix, '/')[0],'.')
var GatewayIP = '${join(take(GatewayIPSegments, 3),'.')}.${int(any(last(GatewayIPSegments)))+4}'

var DnsForwarderArguments = join([
  '-f \'168.63.129.16\''                                                                            // forward request to the Azure default DNS
  '-f \'${ProjectContext.GatewayIP}\''                                                              // forward request to the project DNS
], ' ')

// var NetForwarderArguments = join([
//   join(map(EnvironmentAddressPrefixes, prefix => '-f \'${prefix}\''), ' ')                          // forward traffic from environment networks
//   '-b \'${OrganizationDefinition.ipRange}\''                                                        // block forward request from organization network
// ], ' ')

var InitScriptBaseUri = 'https://raw.githubusercontent.com/carmada-dev/demo-organization/main/resources/scripts/'
var InitScriptNames = [ 'initMachine.sh', 'setupDnsForwarder.sh', 'setupNetForwarder.sh', 'setupWireGuard.sh' ]
var InitCommand = join(filter([
  './initMachine.sh'
  './setupDnsForwarder.sh ${DnsForwarderArguments}'
  // './setupNetForwarder.sh ${NetForwarderArguments}'
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
]

// ============================================================================================

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: ResourceName
}

resource snet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  name: 'gateway'
  parent: vnet
}

resource gatewayNSG 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${ResourceName}-GW'
  location: OrganizationDefinition.location
  properties: {
    securityRules: DefaultRules
  }
}

resource gatewayNIC 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: '${ResourceName}-GW'
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
  name: '${ResourceName}-GW'
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
  name: '${ResourceName}-GW'
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
