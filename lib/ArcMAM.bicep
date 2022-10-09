param VM object
param WorkspaceName string
param WorkspaceId string
param location string = resourceGroup().location

var MaMExtensionName = toUpper(VM.properties.osname)=='WINDOWS' ? 'AzureMonitorWindowsAgent' : 'AzureMonitorLinuxAgent'
var MaMExtensionType  = toUpper(VM.properties.osname)=='WINDOWS' ? 'AzureMonitorWindowsAgent' : 'AzureMonitorLinuxAgent'
var IsWindows= toUpper(VM.properties.osname)=='WINDOWS' ? true : false


resource MAMdeploy 'Microsoft.HybridCompute/machines/extensions@2021-06-10-preview' = {
  location: location
  name: '${VM.properties.displayName}/${MaMExtensionName}'
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: MaMExtensionType
    autoUpgradeMinorVersion: true
    settings: {
      proxy: {
        mode: 'application'
        address: '10.10.1.5:3128'
        auth: false
      }
    }
  }
}

resource DRCwin 'Microsoft.Insights/dataCollectionRules@2021-04-01' = if(IsWindows) {
  name: 'DcrWindows'
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
          workspaceResourceId: WorkspaceId
          name: WorkspaceName
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Event'
        ]
        destinations: [
          WorkspaceName
        ]
      }
    ]
  }
}

resource DRClin 'Microsoft.Insights/dataCollectionRules@2021-04-01' = if(!IsWindows) {
  name: 'DcrLinux'
  location: location
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
          workspaceResourceId: WorkspaceId
          name: WorkspaceName
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Syslog'
        ]
        destinations: [
          WorkspaceName
        ]
      }
    ]
  }
}
