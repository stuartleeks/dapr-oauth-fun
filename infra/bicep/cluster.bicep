@description('Default value obtained from resource group, it can be overwritten')
@minLength(1)
param location string = resourceGroup().location

@description('Name for the ACR')
@minLength(1)
param acrName string

@description('Expected ACR sku')
@allowed([
  'Basic'
  'Classic'
  'Premium'
  'Standard'
])
param acrSku string = 'Standard'

@description('The name of the AKS resource')
@minLength(1)
param aksName string

@description('Disk size (in GB) to provision for each of the agent pool nodes. Specifying 0 will apply the default disk size for that agentVMSize')
@minValue(0)
@maxValue(1023)
param aksDiskSizeGB int = 30

@description('The number of nodes for the AKS cluster')
@minValue(1)
@maxValue(50)
param aksNodeCount int = 3

@description('The size of the Virtual Machine nodes in the AKS cluster')
param aksVMSize string = 'Standard_D2s_v3'

// Azure Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
}

var roleAcrPullName = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: roleAcrPullName

}
resource assignAcrPullToAks 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, acrName, aksName, 'AssignAcrPullToAks')
  scope: containerRegistry
  properties: {
    description: 'Assign AcrPull role to AKS'
    principalId: aks.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: contributorRoleDefinition.id
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2020-09-01' = {
  name: aksName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: 'aks'
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: aksDiskSizeGB
        count: aksNodeCount
        minCount: 1
        maxCount: aksNodeCount
        vmSize: aksVMSize
        osType: 'Linux'
        mode: 'System'
        enableAutoScaling: true
      }
    ]
    // addonProfiles: {
    //   omsAgent: {
    //     enabled: true
    //     config: {
    //       logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
    //     }
    //   }
    //   azureKeyvaultSecretsProvider: {
    //     enabled: true
    //     config: {
    //       enableSecretRotation: 'true'
    //       rotationPollInterval: '2m'
    //     }
    //   }
    // }
  }
}

output acrName string = containerRegistry.name
output acrLoginServer string = containerRegistry.properties.loginServer
output clusterName string = aks.name
output clusterId string = aks.id
