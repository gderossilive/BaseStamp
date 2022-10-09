param amplsName string
param WorkspaceName string
param LAWdeployId string


resource ampls 'microsoft.insights/privateLinkScopes@2019-10-17-preview' existing = {
  name: amplsName
}

resource PrivateLinkScope 'Microsoft.Insights/privateLinkScopes/scopedResources@2019-10-17-preview' = {
  parent: ampls
  name: 'amplslink-${WorkspaceName}'
  properties: {
    linkedResourceId: LAWdeployId
  }
}
