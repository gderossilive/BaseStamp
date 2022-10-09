param VM object
param LAresourceId string
param WorkspaceId string
param daExtensionVersion string = '9.10'


var DaExtensionName = toUpper(VM.properties.storageProfile.osdisk.ostype)=='WINDOWS' ? 'DependencyAgentWindows' : 'DependencyAgentLinux'
var DaExtensionType  = toUpper(VM.properties.storageProfile.osdisk.ostype)=='WINDOWS' ? 'DependencyAgentWindows' : 'DependencyAgentLinux'
var MmaExtensionName = toUpper(VM.properties.storageProfile.osdisk.ostype)=='WINDOWS' ? 'MicrosoftMonitoringAgent' : 'OMSAgentForLinux'
var MmaExtensionType = toUpper(VM.properties.storageProfile.osdisk.ostype)=='WINDOWS' ? 'MicrosoftMonitoringAgent' : 'OMSAgentForLinux'
var mmaExtensionVersion = toUpper(VM.properties.storageProfile.osdisk.ostype)=='WINDOWS' ? '1.0' : '1.14'


resource DA 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: '${VM.properties.osProfile.computerName}/${DaExtensionName}'  
  location: VM.location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: DaExtensionType
    typeHandlerVersion: daExtensionVersion 
    autoUpgradeMinorVersion: true
    settings: {
      enableAMA: true
    }
  }
}

resource MMA 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: '${VM.properties.osProfile.computerName}/${MmaExtensionName}'
  location: VM.location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: MmaExtensionType
    typeHandlerVersion: mmaExtensionVersion  
    settings: {
      workspaceId: WorkspaceId
      azureResourceId: VM.properties.vmId
      stopOnMultipleConnections: true
    }
    protectedSettings: {
      workspaceKey: listKeys(LAresourceId, '2015-03-20').primarySharedKey
    }
  }
}


