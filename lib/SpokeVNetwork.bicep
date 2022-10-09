param virtualNetworkName string
param vnetSddressPrefix string 

param PEsubnetName string 

param PEsubnetAddressPrefix string 
param GatewaySubnetAddressPrefix string 

param CustomDNSserver string 
param NSGname string
param RouteTableId string
param DeployGw bool 
param location string = resourceGroup().location

resource NSG 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: NSGname
  location: location
  properties: {
    securityRules: []
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetSddressPrefix
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
