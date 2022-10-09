param VM object
param location string = resourceGroup().location
param fileUris array = [] 
param commandToExecute string

resource Script 'Microsoft.HybridCompute/machines/extensions@2021-12-10-preview' = {
  name: '${VM.properties.displayName}/CustomScript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {}
    protectedSettings: {
      commandToExecute: commandToExecute
/*      fileUris: fileUris   */
    }
  }
}
