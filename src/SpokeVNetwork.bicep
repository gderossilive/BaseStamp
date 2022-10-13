param virtualNetworkName string
param vnetAddressPrefix string 

param PEsubnetName string 

param PEsubnetAddressPrefix string 
param GatewaySubnetAddressPrefix string 

param CustomDNSserver string 
param NSGname string
param RouteTableId string
param DeployGw bool 
param DeployFirewall bool
param location string = resourceGroup().location

resource NSG 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: NSGname
  location: location
  properties: {
    securityRules: []
  }
}

module NoInternetSpoke 'AddNsgRule.bicep' = if (DeployFirewall) {
  dependsOn: [
    NSG
  ]
  name: 'NoInternet-${virtualNetworkName}'
  params: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: 'Internet'
    access: 'Deny'
    priority: 1000
    direction: 'Outbound'
    sourcePortRanges: []
    destinationPortRanges: [443,80]
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
    NsgName: NSGname
    RuleName: 'NoInternet'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    dhcpOptions: {
      dnsServers: [
        CustomDNSserver
      ]
    }
    subnets: [
      {
        name: PEsubnetName
        properties: {
          addressPrefix: PEsubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: NSG.id
          }
          routeTable: {
            id: RouteTableId
          }
        }
      }
    ]
  }
}

resource GwSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = if (DeployGw) {
  name: 'GatewaySubnet'
  parent: vnet
  properties: {
    addressPrefix: GatewaySubnetAddressPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}


output virtualNetworkRg string = resourceGroup().name
output virtualNetworkName string = virtualNetworkName
