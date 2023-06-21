
targetScope = 'resourceGroup'

// ============================================================================================

param IPGroupName string

param IPGroupHash string = ''

param IPAddresses array

// ============================================================================================

#disable-next-line no-loc-expr-outside-params
var ResourceLocation = resourceGroup().location

var IPGroupHashNew = uniqueString(string(sort(IPAddresses, (ip1, ip2) => ip1 < ip2)))
var IPGroupHashTag = 'IPGroupHash'

// ============================================================================================

resource ipGroup 'Microsoft.Network/ipGroups@2022-01-01' = if (IPGroupHash != IPGroupHashNew) {
  name: IPGroupName
  location: ResourceLocation
  properties: {
    ipAddresses: IPAddresses
  }
}

resource ipGroupTags 'Microsoft.Resources/tags@2022-09-01' = {
  name: 'default'
  scope: ipGroup
  properties: {
    tags: {
      '${IPGroupHashTag}': IPGroupHashNew
    }
  }
}

// ============================================================================================

output IPGroupId string = ipGroup.id
output IPGroupName string = ipGroup.name
output IPGroupUpdated bool = (IPGroupHash != IPGroupHashNew)
output IPGroupHashOld string = IPGroupHash
output IPGroupHashNew string = IPGroupHashNew
