param VM object
param LAresourceId string
param WorkspaceId string
param daExtensionVersion string = '9.10'



var DaExtensionName = toUpper(VM.properties.osname)=='WINDOWS' ? 'DependencyAgentWindows' : 'DependencyAgentLinux'
var DaExtensionType  = toUpper(VM.properties.osname)=='WINDOWS' ? 'DependencyAgentWindows' : 'DependencyAgentLinux'
var MmaExtensionName = toUpper(VM.properties.osname)=='WINDOWS' ? 'MicrosoftMonitoringAgent' : 'OMSAgentForLinux'
var MmaExtensionType = toUpper(VM.properties.osname)=='WINDOWS' ? 'MicrosoftMonitoringAgent' : 'OMSAgentForLinux'
var mmaExtensionVersion = toUpper(VM.properties.osname)=='WINDOWS' ? '1.0' : '1.14'


resource DA 'Microsoft.HybridCompute/machines/extensions@2021-06-10-preview' = {
  name: '${VM.properties.displayName}/${DaExtensionName}'  
  location: VM.location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: DaExtensionType
/*    typeHandlerVersion: daExtensionVersion */ 
    autoUpgradeMinorVersion: true
    settings: {
      enableAMA: true
    }
  }
}

resource MMA 'Microsoft.HybridCompute/machines/extensions@2021-06-10-preview' = {
  name: '${VM.properties.displayName}/${MmaExtensionName}'
  location: VM.location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: MmaExtensionType
/*    typeHandlerVersion: mmaExtensionVersion */
    settings: {
      workspaceId: WorkspaceId
      azureResourceId: VM.properties.vmId
      stopOnMultipleConnections: true
      proxyUri: 'http://10.10.1.5:3128'
    }
    protectedSettings: {
      workspaceKey: listKeys(LAresourceId, '2015-03-20').primarySharedKey
    }
  }
}


