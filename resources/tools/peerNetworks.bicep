targetScope = 'subscription'

// ============================================================================================

param HubNetworkId string

param HubGatewayIP string = ''

param HubPeeringPrefix string = 'hub'

param SpokeNetworkIds array

param SpokePeeringPrefix string = 'spoke'

param UpdateIPGroups bool = false

param OperationId string = newGuid()

// ============================================================================================

resource hubNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: any(last(split(HubNetworkId, '/')))
  scope: resourceGroup(split(HubNetworkId, '/')[2], split(HubNetworkId, '/')[4])
}

module peerHub2Spoke 'peerNetwork.bicep' = [for i in range(0, length(SpokeNetworkIds)): {
  name: '${take(deployment().name, 36)}_${uniqueString('peerNetwork', SpokeNetworkIds[i], OperationId)}'
  scope: resourceGroup(split(HubNetworkId, '/')[2], split(HubNetworkId, '/')[4])
  params: {
    LocalVirtualNetworkName: hubNetwork.name
    RemoteVirtualNetworkId: SpokeNetworkIds[i]
    PeeringPrefix: SpokePeeringPrefix
  }
}]

resource spokeNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = [for SpokeNetworkId in SpokeNetworkIds: {
  name: any(last(split(SpokeNetworkId, '/')))
  scope: resourceGroup(split(SpokeNetworkId, '/')[2], split(SpokeNetworkId, '/')[4])
}]

module peerSpoke2Hub 'peerNetwork.bicep' = [for i in range(0, length(SpokeNetworkIds)): {
  name: '${take(deployment().name, 36)}_${uniqueString('peerNetwork', HubNetworkId, OperationId)}'
  scope: resourceGroup(split(SpokeNetworkIds[i], '/')[2], split(SpokeNetworkIds[i], '/')[4])
  params: {
    LocalVirtualNetworkName: spokeNetwork[i].name
    RemoteVirtualNetworkId: HubNetworkId
    RemoteGatewayIP: HubGatewayIP
    PeeringPrefix: HubPeeringPrefix
  }
}]

module updateIPGroups 'deployIPGroups.bicep' = if (UpdateIPGroups) {
  name: '${take(deployment().name, 36)}_${uniqueString('updateIPGroups', HubNetworkId, OperationId)}'
  scope: resourceGroup(split(HubNetworkId, '/')[2], split(HubNetworkId, '/')[4])
  dependsOn: [
    peerHub2Spoke
    peerSpoke2Hub
  ]
  params: {
    VNetName: hubNetwork.name
  }
}
