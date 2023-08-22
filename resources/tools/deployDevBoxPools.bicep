targetScope = 'resourceGroup'

// ============================================================================================

param ProjectName string

param ProjectLocation string = resourceGroup().location

param NetworkConnectionName string

param DevBoxDefinitionName string

param Pools array

// ============================================================================================

resource project 'Microsoft.DevCenter/projects@2022-11-11-preview' existing = {
  name: ProjectName
}

resource devBoxPool 'Microsoft.DevCenter/projects/pools@2022-11-11-preview' = [for Pool in Pools: {
  name: Pool.name
  location: ProjectLocation
  parent: project
  properties: {    
    devBoxDefinitionName: DevBoxDefinitionName
    networkConnectionName: NetworkConnectionName
    licenseType: 'Windows_Client'
    localAdministrator: Pool.localAdministrator ? 'Enabled' : 'Disabled'
  }
}]
