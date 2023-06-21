targetScope = 'resourceGroup'

// ============================================================================================

param OrganizationDefinition object
param OrganizationWorkspaceId string
param InitialDeployment bool

// ============================================================================================

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: OrganizationDefinition.name
}

resource bastionSubNet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  name: 'AzureBastionSubnet'
  parent: virtualNetwork
}

resource bastionPIP 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: '${OrganizationDefinition.name}-BH'
  location: OrganizationDefinition.location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2022-07-01' = {
  name: '${OrganizationDefinition.name}-BH'
  location: OrganizationDefinition.location
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: bastionPIP.id
          }
          subnet: {
            id: bastionSubNet.id
          }
        }
      }
    ]
  }
}

resource bastionDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: bastion.name
  scope: bastion
  properties: {
    workspaceId: OrganizationWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
  }
}
