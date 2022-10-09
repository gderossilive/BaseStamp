param VMname string
param ExName string = 'DependencyAgentWindows'
param publisher string ='Microsoft.Azure.Monitoring.DependencyAgent'
param type string = 'DependencyAgentWindows'
param typeHandlerVersion string = '9.10'
param autoUpgradeMinorVersion bool = true

var name = '${VMname}/${ExName}'

resource Extension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: name
  location: resourceGroup().location
  properties: {
    publisher: publisher
    type: type
    typeHandlerVersion: typeHandlerVersion
    autoUpgradeMinorVersion: autoUpgradeMinorVersion
  }
}
