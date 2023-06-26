
targetScope = 'resourceGroup'

// ============================================================================================

param VirtualNetworkName string
param InitialDeployment bool = false

// ============================================================================================

var ResourcePrefix = '${virtualNetwork.name}-IPG'

var IPGroupSuffixes = [ 'project' ]
var IPGroupHashTag = 'IPGroupHash'

// ============================================================================================

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: VirtualNetworkName
}

module ipGroupLocalExists 'testResourceExists.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString('ipGroupLocalExists', 'LOCAL')}'
  params: {
    ResourceName: '${ResourcePrefix}-LOCAL'
    ResourceType: 'Microsoft.Network/ipGroups'
  }
}

module ipGroupLocalDeploy 'deployIPGroup.bicep' = {
  name: '${take(deployment().name, 36)}_IPG-${uniqueString('ipGroupLocalDeploy', 'LOCAL')}'
  params: {
    IPGroupName: '${ResourcePrefix}-LOCAL'
    IPGroupHash: (ipGroupLocalExists.outputs.ResourceExists && contains(ipGroupLocalExists.outputs.ResourceTags, IPGroupHashTag)) ? ipGroupLocalExists.outputs.ResourceTags[IPGroupHashTag] : ''
    IPAddresses: sort(virtualNetwork.properties.addressSpace.addressPrefixes, (ip1, ip2) => ip1 < ip2)    
  }
}

module ipGroupPeeredExists 'testResourceExists.bicep' = [for suffix in IPGroupSuffixes : {
  name: '${take(deployment().name, 36)}_${uniqueString(suffix)}'
  params: {
    ResourceName: '${ResourcePrefix}-${toUpper(suffix)}'
    ResourceType: 'Microsoft.Network/ipGroups'
  }
}]

module ipGroupPeeredDeployParallel 'deployIPGroup.bicep' = [for (suffix, index) in IPGroupSuffixes : if (InitialDeployment) {
  name: '${take(deployment().name, 36)}_IPG-${uniqueString('ipGroupPeeredDeployParallel', toUpper(suffix))}'
  dependsOn: [
    ipGroupLocalDeploy
  ]
  params: {
    IPGroupName: '${ResourcePrefix}-${toUpper(suffix)}'
    IPGroupHash: (ipGroupPeeredExists[index].outputs.ResourceExists && contains(ipGroupPeeredExists[index].outputs.ResourceTags, IPGroupHashTag)) ? ipGroupPeeredExists[index].outputs.ResourceTags[IPGroupHashTag] : ''
    IPAddresses: sort(flatten(map(filter(virtualNetwork.properties.virtualNetworkPeerings, peer => toUpper(split(peer.name, '-')[0]) == toUpper(suffix)), peer => peer.properties.remoteVirtualNetworkAddressSpace.addressPrefixes)), (ip1, ip2) => ip1 < ip2)
  }
}]

@batchSize(1)
module ipGroupPeeredDeploySequential 'deployIPGroup.bicep' = [for (suffix, index) in IPGroupSuffixes : if (!InitialDeployment) {
  name: '${take(deployment().name, 36)}_IPG-${uniqueString('ipGroupPeeredDeploySequential', toUpper(suffix))}'
  dependsOn: [
    ipGroupLocalDeploy
  ]
  params: {
    IPGroupName: '${ResourcePrefix}-${toUpper(suffix)}'
    IPGroupHash: (ipGroupPeeredExists[index].outputs.ResourceExists && contains(ipGroupPeeredExists[index].outputs.ResourceTags, IPGroupHashTag)) ? ipGroupPeeredExists[index].outputs.ResourceTags[IPGroupHashTag] : ''
    IPAddresses: sort(flatten(map(filter(virtualNetwork.properties.virtualNetworkPeerings, peer => toUpper(split(peer.name, '-')[0]) == toUpper(suffix)), peer => peer.properties.remoteVirtualNetworkAddressSpace.addressPrefixes)), (ip1, ip2) => ip1 < ip2)
  }
}]

// ============================================================================================

output IpGroupLocalId string = ipGroupLocalDeploy.outputs.IPGroupId
output IpGroupLocalName string = ipGroupLocalDeploy.outputs.IPGroupName

output IpGroupsPeered array = [ for i in range(0, length(IPGroupSuffixes)) : {
  id: InitialDeployment ? ipGroupPeeredDeployParallel[i].outputs.IPGroupId : ipGroupPeeredDeploySequential[i].outputs.IPGroupId
  name: InitialDeployment ? ipGroupPeeredDeployParallel[i].outputs.IPGroupName : ipGroupPeeredDeploySequential[i].outputs.IPGroupName
}]
