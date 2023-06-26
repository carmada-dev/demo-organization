targetScope = 'resourceGroup'

// ============================================================================================

param OrganizationDefinition object
param InitialDeployment bool

// ============================================================================================


resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${OrganizationDefinition.name}-LA'
  location: OrganizationDefinition.location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource routes 'Microsoft.Network/routeTables@2022-07-01' = {
  name: OrganizationDefinition.name
  location: OrganizationDefinition.location
}

module splitSubnets '../tools/splitSubnets.bicep' = {
  name: '${take(deployment().name, 36)}_splitSubnets'
  params: {
    IPRange: OrganizationDefinition.ipRange
    SubnetCount: 3
  }
}

resource virtualNetworkCreate 'Microsoft.Network/virtualNetworks@2022-07-01' = if (InitialDeployment) {
  name: OrganizationDefinition.name
  location: OrganizationDefinition.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        OrganizationDefinition.ipRange  
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
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled' 
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: splitSubnets.outputs.Subnets[1]
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: splitSubnets.outputs.Subnets[2]
        }
      }
    ]
  }  
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: OrganizationDefinition.name
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: OrganizationDefinition.name
}

module deployInfrastructure_Bastion 'deployInfrastructure_Bastion.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'deployInfrastructure_Bastion')}'
  dependsOn: [
    virtualNetworkCreate
  ]
  params: {
    InitialDeployment: InitialDeployment
    OrganizationDefinition: OrganizationDefinition
    OrganizationWorkspaceId: workspace.id
  }  
}

module deployInfrastructure_DNS 'deployInfrastructure_DNS.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'deployInfrastructure_DNS')}'
  dependsOn: [
    virtualNetworkCreate
  ]
  params: {
    InitialDeployment: InitialDeployment
    OrganizationDefinition: OrganizationDefinition
    OrganizationWorkspaceId: workspace.id
  }  
}

module deployInfrastructure_Firewall 'deployInfrastructure_Firewall.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'deployInfrastructure_Firewall')}'
  dependsOn: [
    virtualNetworkCreate
  ]
  params: {
    InitialDeployment: InitialDeployment
    OrganizationDefinition: OrganizationDefinition
    OrganizationWorkspaceId: workspace.id
  }  
}

// ============================================================================================

output WorkspaceId string = workspace.id
output NetworkId string = InitialDeployment ? virtualNetworkCreate.id : virtualNetwork.id
output GatewayIP string = deployInfrastructure_Firewall.outputs.GatewayIP

