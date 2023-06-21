targetScope = 'resourceGroup'

// ============================================================================================

param FirewallName string
param FirewallLocation string = resourceGroup().location
param FirewallSubnetId string
param FirewallManagementSubnetId string = ''
param FirewallRuleCollections array = []

param WorkspaceId string = ''

// ============================================================================================

resource firewallPIP 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: FirewallName
  location: FirewallLocation
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2022-07-01' = {
  name: FirewallName
  location: FirewallLocation
  properties: {
    threatIntelMode: 'Alert'
    dnsSettings: {
      enableProxy: true
      servers: [
        '168.63.129.16'
      ]
    }
  }

  resource defaultRuleCollectionGroup 'ruleCollectionGroups@2022-01-01' = if (!empty(FirewallRuleCollections)){
    name: 'default'
    properties: {
      priority: 100
      ruleCollections: FirewallRuleCollections
    }
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2022-07-01' = {
  name: FirewallName
  location: FirewallLocation
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          subnet:{
            id: FirewallSubnetId
          }
          publicIPAddress: !empty(FirewallManagementSubnetId) ? null : {
            id: firewallPIP.id
          }
        }
      }
    ]
    managementIpConfiguration: empty(FirewallManagementSubnetId) ? null : {
      name: firewallPIP.name
      properties: {
        subnet: {
          id: FirewallManagementSubnetId
        }
        publicIPAddress: {
          id: firewallPIP.id
        }
      }
    }
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
}

resource firewallDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(!empty(WorkspaceId)) {
  name: firewall.name
  scope: firewall
  properties: {
    workspaceId: WorkspaceId
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

// ============================================================================================

output FirewallId string = firewall.id
output FirewallPrivateIP string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output FirewallPublicIP string = firewallPIP.properties.ipAddress
