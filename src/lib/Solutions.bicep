param workspaceExternalId string
param name string
param product string


resource VMinsights 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: name
  location: 'westeurope'
  plan: {
    name: name
    promotionCode: ''
    product: product
    publisher: 'Microsoft'
  }
  properties: {
    workspaceResourceId: workspaceExternalId
    containedResources: [
      '${workspaceExternalId}/${name}'
    ]
  }
}
