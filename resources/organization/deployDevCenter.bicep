targetScope = 'resourceGroup'

// ============================================================================================

param OrganizationDefinition object
param OrganizationContext object
param DeploymentContext object

// ============================================================================================

var DevBoxes = contains(OrganizationDefinition, 'devboxes') ? OrganizationDefinition.devboxes : []
var EnvTypes = contains(OrganizationDefinition, 'environments') ? OrganizationDefinition.environments : []
var Catalogs = contains(OrganizationDefinition, 'catalogs') ? OrganizationDefinition.catalogs : []
var CatalogsGitHub = filter(Catalogs, Catalog => Catalog.type == 'gitHub')
var CatalogsAdoGit = filter(Catalogs, Catalog => Catalog.type == 'adoGit')

// ============================================================================================

resource devCenter 'Microsoft.DevCenter/devcenters@2022-11-11-preview' = {
  name: OrganizationDefinition.name
  location: OrganizationDefinition.location
  identity: {
    type:'SystemAssigned'
  }
}

resource devCenterDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: devCenter.name
  scope: devCenter
  properties: {
    workspaceId: OrganizationContext.WorkspaceId
    logs: [
      {
        categoryGroup: 'audit'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
    metrics: []
  }
}

resource devBox 'Microsoft.DevCenter/devcenters/devboxdefinitions@2022-11-11-preview' = [for DevBox in DevBoxes: {
  name: DevBox.name
  location: OrganizationDefinition.location
  parent: devCenter
  properties: {
    imageReference: {
      id: resourceId('Microsoft.DevCenter/devcenters/galleries/images', devCenter.name, 'default', DevBox.image)
    }
    sku: {
      name: DevBox.sku
    }
    osStorageType: DevBox.storage
  }
}]

resource envType 'Microsoft.DevCenter/devcenters/environmentTypes@2022-09-01-preview' = [for EnvType in EnvTypes: {
  name: EnvType
  parent: devCenter
}]

resource gallery 'Microsoft.Compute/galleries@2021-10-01' = {
  name: OrganizationDefinition.name
  location: OrganizationDefinition.location
}

module galleryContributorRoleAssignment '../tools/assignRoleOnComputeGallery.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'galleryContributorRoleAssignment')}'
  params: {
    ComputeGalleryName: gallery.name
    RoleNameOrId: 'Contributor'
    PrincipalIds: [ devCenter.identity.principalId ]
  }
}

module galleryReaderRoleAssignment '../tools/assignRoleOnComputeGallery.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'galleryReaderRoleAssignment')}'
  params: {
    ComputeGalleryName: gallery.name
    RoleNameOrId: 'Reader'
    PrincipalIds: [ DeploymentContext.Windows365PrinicalId ]
  }
}

resource attachGallery 'Microsoft.DevCenter/devcenters/galleries@2022-11-11-preview' = {
  name: gallery.name
  parent: devCenter
  dependsOn: [
    galleryContributorRoleAssignment
    galleryReaderRoleAssignment
  ]
  properties: {
    #disable-next-line use-resource-id-functions
    galleryResourceId: gallery.id
  }
}

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: any(OrganizationDefinition.name)
  location: OrganizationDefinition.location
  properties: {
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    sku: {
      name: 'standard'
      family: 'A'
    }
    createMode: 'default'
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
  }
}

module vaultSecretUserRoleAssignment '../tools/assignRoleOnKeyVault.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'vaultSecretUserRoleAssignment')}'
  params: {
    KeyVaultName: vault.name
    RoleNameOrId: 'Key Vault Secrets User'
    PrincipalIds: [ devCenter.identity.principalId ]
  }
}

resource vaultSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = [for (Catalog, CatalogIndex) in Catalogs : {
  name: Catalog.name
  parent: vault
  properties: {
    value: Catalog.secret
  }
}]

resource catalogGitHub 'Microsoft.DevCenter/devcenters/catalogs@2022-11-11-preview' = [for (Catalog, CatalogIndex) in CatalogsGitHub : {
  name: '${Catalog.name}'
  parent: devCenter
  properties: {
    gitHub: {
      uri: Catalog.uri
      branch: Catalog.branch
      secretIdentifier: vaultSecret[CatalogIndex].properties.secretUri
      path: Catalog.path
    }
  }
}]

resource catalogAdoGit 'Microsoft.DevCenter/devcenters/catalogs@2022-11-11-preview' = [for (Catalog, CatalogIndex) in CatalogsAdoGit : {
  name: '${Catalog.name}'
  parent: devCenter
  properties: {
    adoGit: {
      uri: Catalog.uri
      branch: Catalog.branch
      secretIdentifier: vaultSecret[CatalogIndex].properties.secretUri
      path: Catalog.path
    }
  }
}]

// ============================================================================================

output DevCenterId string = devCenter.id
output GalleryId string = gallery.id
output VaultId string = vault.id
output PrincipalId string = devCenter.identity.principalId
