param AAname string
param WorkspaceName string

var LinkedService = '${WorkspaceName}/Automation'

resource AA 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  name: AAname
  location: 'westeurope'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: true
    disableLocalAuth: false
    sku: {
      name: 'Basic'
    }
    encryption: {
      keySource: 'Microsoft.Automation'
      identity: {}
    }
  }
}

resource Link 'Microsoft.OperationalInsights/workspaces/linkedServices@2020-08-01' = {
  dependsOn: [
    AA
  ]
  name: LinkedService
  properties: {
    resourceId: AA.id
  }
}
