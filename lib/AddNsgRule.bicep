param NsgName string
param protocol string
param sourcePortRange string
param destinationPortRange string
param sourceAddressPrefix string
param destinationAddressPrefix string
param access string
param priority int
param direction string
param sourcePortRanges array
param destinationPortRanges array
param sourceAddressPrefixes array
param destinationAddressPrefixes array


resource NSG 'Microsoft.Network/networkSecurityGroups@2021-08-01' existing = {
  name: NsgName
}

resource AllowAzureCloudOutbound 'Microsoft.Network/networkSecurityGroups/securityRules@2021-08-01' = {
  parent: NSG
  name: 'AllowAzureCloudOutbound'
  properties: {
    protocol: protocol
    sourcePortRange: sourcePortRange
    destinationPortRange: destinationPortRange
    sourceAddressPrefix: sourceAddressPrefix
    destinationAddressPrefix: destinationAddressPrefix
    access: access
    priority: priority
    direction: direction
    sourcePortRanges: sourcePortRanges
    destinationPortRanges: destinationPortRanges
    sourceAddressPrefixes: sourceAddressPrefixes
    destinationAddressPrefixes: destinationAddressPrefixes
  }
}
