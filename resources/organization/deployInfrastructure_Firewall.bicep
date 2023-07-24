targetScope = 'resourceGroup'

// ============================================================================================

param OrganizationDefinition object
param OrganizationWorkspaceId string
param InitialDeployment bool

// ============================================================================================

var FirewallRuleCollections = [
  {
    ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
    name: 'org-services-applications'
    priority: 1000
    action: {
      type: 'Allow'
    }
    rules: [
      {
        ruleType: 'ApplicationRule'
        name: 'WindowsUpdate'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        fqdnTags: [
          'WindowsUpdate'
        ]
        terminateTLS: false
        sourceIpGroups: concat([deployIPGroups.outputs.IpGroupLocalId], map(deployIPGroups.outputs.IpGroupsPeered, ipg => ipg.id))
      }
      {
        ruleType: 'ApplicationRule'
        name: 'WindowsVirtualDesktop'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
        ]
        fqdnTags: [
          'WindowsVirtualDesktop'
          'WindowsDiagnostics'
          'MicrosoftActiveProtectionService'
        ]
        destinationAddresses: [
          '*.events.data.microsoft.com'
          '*.sfx.ms'
          '*.digicert.com'
          '*.azure-dns.com'
          '*.azure-dns.net'
        ]
        terminateTLS: false
        sourceIpGroups: map(deployIPGroups.outputs.IpGroupsPeered, ipg => ipg.id)
      }
    ]
  }
  {
    name: 'org-virtualdesktop'
    ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
    priority: 1100
    action: {
      type: 'Allow'
    }
    rules: [
      {
        ruleType: 'NetworkRule'
        name: 'avd-common'
        ipProtocols: [ 'TCP' ]
        sourceIpGroups: map(deployIPGroups.outputs.IpGroupsPeered, ipg => ipg.id)
        destinationFqdns: [
          'oneocsp.microsoft.com'
          'www.microsoft.com'
        ]
        destinationPorts: [ '80' ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'avd-storage'
        ipProtocols: [ 'TCP' ]
        sourceIpGroups: map(deployIPGroups.outputs.IpGroupsPeered, ipg => ipg.id)
        destinationFqdns: [
          'mrsglobalsteus2prod.blob.${environment().suffixes.storage}'
          'wvdportalstorageblob.blob.${environment().suffixes.storage}'
        ]
        destinationPorts: [ '443' ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'avd-services'
        ipProtocols: [ 'TCP' ]
        sourceIpGroups: map(deployIPGroups.outputs.IpGroupsPeered, ipg => ipg.id)
        destinationAddresses: [
          'WindowsVirtualDesktop'
          'AzureFrontDoor.Frontend'
          'AzureMonitor'
        ]
        destinationPorts: [ '443' ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'avd-kms'
        ipProtocols: [ 'TCP' ]
        sourceIpGroups: map(deployIPGroups.outputs.IpGroupsPeered, ipg => ipg.id)
        destinationFqdns: [
          'azkms.${environment().suffixes.storage}'
          'kms.${environment().suffixes.storage}'
        ]
        destinationPorts: [ '1688' ]
      }      
      {
        ruleType: 'NetworkRule'
        name: 'avd-devices'
        ipProtocols: [ 'TCP' ]
        sourceIpGroups: map(deployIPGroups.outputs.IpGroupsPeered, ipg => ipg.id)
        destinationFqdns: [
          'global.azure-devices-provisioning.net'
        ]
        destinationPorts: [ '5671' ]
      }   
      {
        ruleType: 'NetworkRule'
        name: 'avd-fastpath-ip'
        ipProtocols: [ 'UDP' ]
        sourceIpGroups: map(deployIPGroups.outputs.IpGroupsPeered, ipg => ipg.id)
        destinationAddresses: [ '13.107.17.41' ]
        destinationPorts: [ '3478' ]
      }  
      {
        ruleType: 'NetworkRule'
        name: 'avd-fastpath-fqdn'
        ipProtocols: [ 'UDP' ]
        sourceIpGroups: map(deployIPGroups.outputs.IpGroupsPeered, ipg => ipg.id)
        destinationFqdns: [ 'stun.azure.com' ]
        destinationPorts: [ '3478' ]
      }  
    ]
  }
  {
    ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
    name: 'org-services-endpoints'
    priority: 2000
    action: {
      type: 'Allow'
    }
    rules: [
        {
        ruleType: 'NetworkRule'
        name: 'time-windows-address'
        ipProtocols: [ 'UDP' ]
        sourceIpGroups: concat([deployIPGroups.outputs.IpGroupLocalId], map(deployIPGroups.outputs.IpGroupsPeered, ipg => ipg.id))
        destinationAddresses: [ '13.86.101.172' ]
        destinationPorts: [ '123' ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'time-windows-fqdn'
        ipProtocols: [ 'UDP' ]
        sourceIpGroups: concat([deployIPGroups.outputs.IpGroupLocalId], map(deployIPGroups.outputs.IpGroupsPeered, ipg => ipg.id))
        destinationFqdns: [ 'time.windows.com' ]
        destinationPorts: [ '123' ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'microsoft-login'
        ipProtocols: [ 'TCP' ]
        sourceIpGroups: concat([deployIPGroups.outputs.IpGroupLocalId], map(deployIPGroups.outputs.IpGroupsPeered, ipg => ipg.id))
        destinationFqdns: [ 
          split(environment().authentication.loginEndpoint, '/')[2] 
          'login.windows.net'
        ]
        destinationPorts: [ '443' ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'microsoft-connect'
        ipProtocols: [ 'TCP' ]
        sourceIpGroups: concat([deployIPGroups.outputs.IpGroupLocalId], map(deployIPGroups.outputs.IpGroupsPeered, ipg => ipg.id))
        destinationFqdns: [ 'www.msftconnecttest.com' ]
        destinationPorts: [ '443' ]
      }
    ]
  }
  {
    ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
    name: 'org-browse'
    priority: 2100
    action: {
      type: 'Allow'
    }
    rules: [
      {
        ruleType: 'ApplicationRule'
        name: 'general'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        webCategories: [
          'ComputersAndTechnology'
          'InformationSecurity'
          'WebRepositoryAndStorage'
          'SearchEnginesAndPortals'
        ]
        terminateTLS: false
        sourceIpGroups: concat([deployIPGroups.outputs.IpGroupLocalId], map(deployIPGroups.outputs.IpGroupsPeered, ipg => ipg.id))
      }
    ]
  }
]

// ============================================================================================

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: OrganizationDefinition.name
}

resource routes 'Microsoft.Network/routeTables@2022-07-01' existing = {
  name: virtualNetwork.name
}

resource firewallSnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  name: 'AzureFirewallSubnet'
  parent: virtualNetwork
}

module deployIPGroups '../tools/deployIPGroups.bicep' = {
  name: '${take(deployment().name, 36)}_deployIPGroups'
  params: {
    VirtualNetworkName: virtualNetwork.name
    InitialDeployment: InitialDeployment
  }
}

module deployFirewall '../tools/deployFirewall.bicep' = if (InitialDeployment) {
  name: '${take(deployment().name, 36)}_deployFirewall'
  params: {
    FirewallName: '${OrganizationDefinition.name}-FW'
    FirewallLocation: OrganizationDefinition.location
    FirewallSubnetId: firewallSnet.id
    FirewallRuleCollections: FirewallRuleCollections
    WorkspaceId: OrganizationWorkspaceId
  }
}

resource defaultSubNetRouteGateway 'Microsoft.Network/routeTables/routes@2022-07-01' = if (InitialDeployment) {
  name: '${OrganizationDefinition.name}-FW'
  parent: routes
  properties: {
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: InitialDeployment ? deployFirewall.outputs.FirewallPrivateIP : null
    addressPrefix: '0.0.0.0/0'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2022-07-01' existing = {
  name: '${OrganizationDefinition.name}-FW'
}

// ============================================================================================

output GatewayIP string = InitialDeployment ? deployFirewall.outputs.FirewallPrivateIP : firewall.properties.ipConfigurations[0].properties.privateIPAddress

