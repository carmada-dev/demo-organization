targetScope = 'resourceGroup'

// ============================================================================================

param IPRange string

param SubnetCount int

param OperationId string = newGuid()

// ============================================================================================

#disable-next-line no-loc-expr-outside-params
var ResourceLocation = resourceGroup().location

// ============================================================================================

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (SubnetCount > 1) {
  #disable-next-line use-stable-resource-identifiers
  name: 'SplitSubnets-${guid(IPRange, string(SubnetCount), OperationId)}'
  location: ResourceLocation
  kind: 'AzureCLI'
  properties: {
    forceUpdateTag: OperationId
    azCliVersion: '2.40.0'
    timeout: 'PT30M'
    environmentVariables: [
      {
        name: 'SUBNET'
        value: IPRange
      }
      {
        name: 'REQUIRED_SUBNETS'
        value: string(max(SubnetCount, 2))
      }
    ]
    scriptContent: loadTextContent('splitSubnets.sh')
    cleanupPreference: 'Always'
    retentionInterval: 'PT1H'
  }
}

// ============================================================================================

output Subnets array = SubnetCount > 1 ? deploymentScript.properties.outputs.subnets : [ IPRange ]
