param virtualNetworkName string
param vnetSddressPrefix string = '10.10.0.0/16'
param PEsubnetName string = 'PE'
param PEsubnetAddressPrefix string = '10.10.1.0/24'
param GWsubnetName string = 'GatewaySubnet'
param GWsubnetAddressPrefix string = '10.10.2.0/24'
param CustomDNSserver string = '10.10.0.4'
param networkSecurityGroupName string
param RouteTableId string
//param MyIPaddress string 
param location string = resourceGroup().location

resource securityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: []
  }
}

resource GwVnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
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
            id: securityGroup.id
          }
          routeTable: {
            id: RouteTableId
          }
        }
      }
      {
        name: GWsubnetName
        properties: {
          addressPrefix: GWsubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          routeTable: {
            id: RouteTableId
          }
        }
      }
    ]
  }
}

output virtualNetworkRg string = resourceGroup().name
output virtualNetworkName string = virtualNetworkName
