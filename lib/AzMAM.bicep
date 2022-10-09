param VM object
param WorkspaceName string
param MaMExtensionVersion string = '1.0'
param location string = resourceGroup().location

var MaMExtensionName = toUpper(VM.properties.storageProfile.osdisk.ostype)=='WINDOWS' ? 'AzureMonitorWindowsAgent' : 'AzureMonitorLinuxAgent'
var MaMExtensionType  = toUpper(VM.properties.storageProfile.osdisk.ostype)=='WINDOWS' ? 'AzureMonitorWindowsAgent' : 'AzureMonitorLinuxAgent'
var IsWindows= toUpper(VM.properties.storageProfile.osdisk.ostype)=='WINDOWS' ? true : false

resource LAW 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: WorkspaceName
}

resource MAMdeploy 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  location: location
  name: '${VM.properties.osProfile.computerName}/${MaMExtensionName}'
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: MaMExtensionType
    typeHandlerVersion: MaMExtensionVersion
    autoUpgradeMinorVersion: true
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
