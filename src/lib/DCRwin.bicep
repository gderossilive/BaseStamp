param WorkspaceName string
param location string = resourceGroup().location

resource LAW 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: WorkspaceName
}

resource DRCwin 'Microsoft.Insights/dataCollectionRules@2021-04-01' = {
  name: 'ArcWindows'
  location: location
  kind: 'Windows'
  properties: {
    dataSources: {
      windowsEventLogs: [
        {
          streams: [
            'Microsoft-Event'
          ]
          xPathQueries: [
            'Security!*[System[(band(Keywords,13510798882111488))]]'
          ]
          name: 'eventLogsDataSource'
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: LAW.id
          name: LAW.name
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Event'
        ]
        destinations: [
          LAW.name
        ]
      }
    ]
  }
}
