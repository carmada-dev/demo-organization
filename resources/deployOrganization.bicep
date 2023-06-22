targetScope = 'subscription'

// ============================================================================================

param OrganizationDefinition object
param DeploymentContext object

// ============================================================================================


resource organizationResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'ORG-${OrganizationDefinition.name}'
  location: OrganizationDefinition.location
}

resource organizationResourceGroupPrivateLink 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'ORG-${OrganizationDefinition.name}-PL'
  location: OrganizationDefinition.location
}

module testOrganizationNetworkExists 'tools/testResourceExists.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition), 'testOrganizationNetworkExists')}'
  scope: organizationResourceGroup
  params: {
    ResourceName: OrganizationDefinition.name
    ResourceType: 'Microsoft.Network/virtualNetworks'
  }
}

module organizationInfrastructure 'organization/deployInfrastructure.bicep' = {
  name: '${take(deployment().name, 36)}_${uniqueString(string(OrganizationDefinition))}'
  scope: organizationResourceGroup
  params: {
    OrganizationDefinition: OrganizationDefinition
    InitialDeployment: !testOrganizationNetworkExists.outputs.ResourceExists
  }
}

// ============================================================================================

output OrganizationContext object = {}
