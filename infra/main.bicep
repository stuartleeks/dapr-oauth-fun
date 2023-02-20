targetScope = 'subscription'

@description('Specifies the supported Azure location (region) where the resources will be deployed')
@minLength(1)
param location string

@description('This value will explain who is the author of specific resources and will be reflected in every deployed tool')
@minLength(1)
param uniqueUserName string

var abbrs = loadJsonContent('abbreviations.json')

var toolName = 'bicep'
var resourceGroupName = '${abbrs.resourcesResourceGroups}${toolName}-${uniqueUserName}'
var acrName = '${abbrs.containerRegistryRegistries}${toolName}${uniqueUserName}'
var aksName = '${abbrs.containerServiceManagedClusters}${toolName}-${uniqueUserName}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}



module cluster 'cluster.bicep' = {
  name: 'cluster'
  scope: resourceGroup
  params: {
    location: location
    acrName: acrName
    aksName: aksName
  }
}


output acr_name string = cluster.outputs.acrName
output acr_login_server string = cluster.outputs.acrLoginServer
output aks_name string = cluster.outputs.clusterName
output rg_name string = resourceGroup.name

