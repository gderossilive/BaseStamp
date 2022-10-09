param VM object
param LAresourceId string
param WorkspaceId string
param HealthExtensionVersion string = '1.0'

var HealthExtensionName = toUpper(VM.properties.storageProfile.osdisk.ostype)=='WINDOWS' ? 'GuestHealthWindowsAgent' : 'GuestHealthLinuxAgent'
var HealthExtensionType  = toUpper(VM.properties.storageProfile.osdisk.ostype)=='WINDOWS' ? 'GuestHealthWindowsAgent' : 'GuestHealthLinuxAgent'

resource Health 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: '${VM.properties.osProfile.computerName}/${HealthExtensionName}'
  location: VM.location
  properties: {
    publisher: 'Microsoft.Azure.Monitor.VirtualMachines.GuestHealth'
    type: HealthExtensionType
    typeHandlerVersion: HealthExtensionVersion 
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
