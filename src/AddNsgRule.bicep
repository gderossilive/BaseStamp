param NsgName string
param RuleName string
param protocol string
param sourcePortRange string
param sourceAddressPrefix string
param destinationAddressPrefix string
param access string
param priority int
param direction string
param sourcePortRanges array
param destinationPortRanges array
param sourceAddressPrefixes array
param destinationAddressPrefixes array


resource DisableAzureCloudOutbound 'Microsoft.Network/networkSecurityGroups/securityRules@2021-08-01' = {
  name: '${NsgName}/${RuleName}'
  properties: {
    protocol: protocol
    sourcePortRange: sourcePortRange
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
