targetScope = 'resourceGroup'

// ============================================================================================

param DevCenterName string

param NetworkConnectionId string

// ============================================================================================

resource devCenter 'Microsoft.DevCenter/devcenters@2022-11-11-preview' existing = {
  name: DevCenterName
}

resource attachNetworkConnection 'Microsoft.DevCenter/devcenters/attachednetworks@2022-11-11-preview' = {
  name: any(last(split(NetworkConnectionId, '/')))
  parent: devCenter
  properties: {
    networkConnectionId: NetworkConnectionId
  }
}
