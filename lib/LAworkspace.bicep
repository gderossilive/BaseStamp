param WorkspaceName string
param publicNetworkAccess string

resource workSpace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: WorkspaceName  
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    publicNetworkAccessForIngestion: publicNetworkAccess
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output Id string = workSpace.id
