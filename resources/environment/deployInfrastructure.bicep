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

resource virtualNetworkCreate 'Microsoft.Network/virtualNetworks@2022-07-01' = if (InitialDeployment) {
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
          addressPrefix: EnvironmentDefinition.ipRange
          routeTable: {
              id: routes.id
          }
        }
      }      
    ]
  }
}

module deployEnvironmentInfrastructure_DNS './deployInfrastructure_DNS.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(EnvironmentDefinition), 'deployEnvironmentInfrastructure_DNS')}'
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

