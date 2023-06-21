targetScope = 'resourceGroup'

// ============================================================================================

param OrganizationDefinition object
param OrganizationContext object
param ProjectDefinition object
param InitialDeployment bool

// ============================================================================================

resource routes 'Microsoft.Network/routeTables@2022-07-01' = {
  name: ProjectDefinition.name
  location: OrganizationDefinition.location
}

module splitSubnets '../tools/splitSubnets.bicep' = {
  name: '${take(deployment().name, 36)}_splitSubnets'
  params: {
    IPRange: ProjectDefinition.ipRange
    SubnetCount: 2
  }
}

resource virtualNetworkCreate 'Microsoft.Network/virtualNetworks@2022-07-01' = if (InitialDeployment) {
  name: ProjectDefinition.name
  location: OrganizationDefinition.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        ProjectDefinition.ipRange
      ]
    }
    dhcpOptions: {
      dnsServers: [
        '168.63.129.16'
        OrganizationContext.GatewayIP
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
    ]
  }
}

module deployInfrastructure_DNS 'deployInfrastructure_DNS.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'deployInfrastructure_DNS')}'
  params: {
    InitialDeployment: InitialDeployment
    OrganizationContext: OrganizationContext
    OrganizationDefinition: OrganizationDefinition
    ProjectDefinition: ProjectDefinition
  }
}

module deployInfrastructure_NVA 'deployInfrastructure_NVA.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'deployInfrastructure_NVA')}'
  params: {
    InitialDeployment: InitialDeployment
    OrganizationContext: OrganizationContext
    OrganizationDefinition: OrganizationDefinition
    ProjectDefinition: ProjectDefinition
  }
}
