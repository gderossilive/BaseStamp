param VM object
param KVname string
param CertificateName string
param KvExtensionVersion string = '1.0'
param certificateStoreName string = 'MY'
param certificateStoreLocation string = toUpper(VM.properties.storageProfile.osdisk.ostype)=='WINDOWS' ? 'LocalMachine' : '/var/lib/waagent/Microsoft.Azure.KeyVault'

var KvExtensionName = toUpper(VM.properties.storageProfile.osdisk.ostype)=='WINDOWS' ? 'KeyVaultForWindows' : 'KeyVaultForLinux'
var KvExtensionType  = toUpper(VM.properties.storageProfile.osdisk.ostype)=='WINDOWS' ? 'KeyVaultForWindows' : 'KeyVaultForLinux'


resource KvExt 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: '${VM.properties.osProfile.computerName}/${KvExtensionName}'
  location: VM.location
  properties: {
    publisher: 'Microsoft.Azure.KeyVault'
    type: KvExtensionType
    typeHandlerVersion: KvExtensionVersion
    autoUpgradeMinorVersion: true 
    settings: {
      secretsManagementSettings: {
        pollingIntervalInS: '3600'
        certificateStoreName: certificateStoreName
        certificateStoreLocation: certificateStoreLocation
        observedCertificates: 'https://${KVname}.vault.azure.net/secrets/${CertificateName}'
      }
      authenticationSettings: {}
    }
  }
}


