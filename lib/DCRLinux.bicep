param WorkspaceName string

resource LAW 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: WorkspaceName
}

resource DRClin 'Microsoft.Insights/dataCollectionRules@2021-04-01' = {
  name: 'ArcLinux'
  location: 'westeurope'
  kind: 'Linux'
  properties: {
    dataSources: {
      syslog: [
       {
         streams: [
           'Microsoft-Syslog'
         ]
         facilityNames: [
           'auth'
           'authpriv'
           'cron'
           'daemon'
           'mark'
           'kern'
           'syslog'
           'user'
           'uucp'
         ]
         logLevels: [
           'Debug'
           'Info'
           'Notice'
           'Warning'
           'Error'
           'Critical'
           'Alert'
           'Emergency'
         ]
         name: 'sysLogsDataSource-1688419672'
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
          'Microsoft-Syslog'
        ]
        destinations: [
          LAW.name
        ]
      }
    ]
  }
}
