param virtualNetworkName string
param vnetAddressPrefix string

param CustomDNSserver string
param location string

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    dhcpOptions: CustomDNSserver == '' ? {} : {dnsServers: [CustomDNSserver]}
    subnets: []
  }
}
