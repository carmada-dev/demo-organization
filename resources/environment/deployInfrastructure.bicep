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

resource routes 'Microsoft.Network/routeTables@2022-07-01' = {
  name: ResourceName
  location: OrganizationDefinition.location
}

resource defaultRoute 'Microsoft.Network/routeTables/routes@2022-07-01' = {
  name: 'default'
  parent: routes
  properties: {
    nextHopType: 'VirtualAppliance'
    addressPrefix: '0.0.0.0/0'
    nextHopIpAddress: ProjectContext.GatewayIP
  }
}

module splitSubnets '../tools/splitSubnets.bicep' = if (InitialDeployment) {
  name: '${take(deployment().name, 36)}_splitSubnets'
  params: {
    IPRange: EnvironmentDefinition.ipRange
    SubnetCount: 3
  }
}

resource virtualNetworkCreate 'Microsoft.Network/virtualNetworks@2022-11-01' = if (InitialDeployment) {
  name: ResourceName
  location: OrganizationDefinition.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        EnvironmentDefinition.ipRange  
      ]
    } 
    dhcpOptions: {
      dnsServers: [
        '168.63.129.16'
        ProjectContext.GatewayIP
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
      {
        name: 'RouteServerSubnet'
        properties: {
          addressPrefix: splitSubnets.outputs.Subnets[2]
        }
      }
    ]
  }
}

module virtualNetworkPeer '../tools/peerNetworks.bicep' = if (InitialDeployment) {
  name: '${take(deployment().name, 36)}_${uniqueString(string(EnvironmentDefinition), 'virtualNetworkPeer')}'
  scope: subscription()
  params: {
    HubNetworkId: ProjectContext.NetworkId
    HubPeeringPrefix: 'project'
    HubGatewayIP: ProjectContext.GatewayIP
    SpokeNetworkIds: [ virtualNetworkCreate.id ]
    SpokePeeringPrefix: 'environment'
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: ResourceName
}
module deployInfrastructure_DNS './deployInfrastructure_DNS.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(EnvironmentDefinition), 'deployInfrastructure_DNS')}'
  dependsOn: [
    virtualNetworkCreate
  ]
  params: {
    OrganizationDefinition: OrganizationDefinition
    OrganizationContext: OrganizationContext
    ProjectDefinition: ProjectDefinition
    ProjectContext: ProjectContext
    EnvironmentDefinition: EnvironmentDefinition
    InitialDeployment: InitialDeployment
  }
}

module deployInfrastructure_NVA './deployInfrastructure_NVA.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(EnvironmentDefinition), 'deployInfrastructure_NVA')}'
  dependsOn: [
    virtualNetworkCreate
  ]
  params: {
    OrganizationDefinition: OrganizationDefinition
    OrganizationContext: OrganizationContext
    ProjectDefinition: ProjectDefinition
    ProjectContext: ProjectContext
    EnvironmentDefinition: EnvironmentDefinition
    InitialDeployment: InitialDeployment
  }
}

// ============================================================================================

output NetworkId string = InitialDeployment ? virtualNetworkCreate.id : virtualNetwork.id
