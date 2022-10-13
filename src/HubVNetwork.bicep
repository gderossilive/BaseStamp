param virtualNetworkName string
param vnetSddressPrefix string = '10.10.0.0/16'

param InSubnetName string = 'dns-inbound-${Seed}'
param OutSubnetName string = 'dns-outbound-${Seed}'
param PEsubnetName string = 'PE-${Seed}'

param DNSInboundSubnetAddressPrefix string = '10.10.0.0/28'
param DNSOutboundSubnetAddressPrefix string = '10.10.0.16/28'
param BastionSubnetAddressPrefix string = '10.10.0.64/26'
param PEsubnetAddressPrefix string = '10.10.1.0/24'
param FirewallSubnetAddressPrefix string = '10.10.2.0/24'
param GatewaySubnetAddressPrefix string = '10.10.3.0/26'

param CustomDNSserver string = '10.10.0.4'
param NSGname string
param RouteTableId string
param MyIPaddress string 
param location string = resourceGroup().location
param Seed string

resource NSG 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: NSGname
  location: location
  properties: {
    securityRules: []
  }
}

resource BastinoNSG 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'Bastion-${NSGname}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAzureCloudOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 200
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes:[]
        }
      }
      {
        name: 'AllowHttpsInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: MyIPaddress
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes:[]
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes:[]
        }
      }
      {
        name: 'AllowSshRdpOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '22'
            '3389'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes:[]
        }
      }
    ]
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
        name: InSubnetName
        properties: {
          addressPrefix: DNSInboundSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: NSG.id
          }
          delegations: [
            {
              name: 'Microsoft.Network.dnsResolvers'
              properties: {
                serviceName: 'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
      {
        name: OutSubnetName
        properties: {
          addressPrefix: DNSOutboundSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: NSG.id
          }
          delegations: [
            {
              name: 'Microsoft.Network.dnsResolvers'
              properties: {
                serviceName: 'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: BastionSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: BastinoNSG.id
          }
        }
      }
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
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: FirewallSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: GatewaySubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}


output virtualNetworkRg string = resourceGroup().name
output virtualNetworkName string = virtualNetworkName
