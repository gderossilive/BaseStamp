param VirtualNetGwName string
param GW_pip_name string = 'Onprem-GW-pip'
param VnetName string
param location string

var subnetName = 'GatewaySubnet'

resource VNGWiP 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: GW_pip_name
  location: location
}

resource VNet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: VnetName
}

resource Subnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  parent: VNet
  name: subnetName
}

resource VirtualNetworkGW 'Microsoft.Network/virtualNetworkGateways@2022-01-01' = {
  name: VirtualNetGwName
  location: location
  properties: {
    enablePrivateIpAddress: false
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: VNGWiP.id
          }
          subnet: {
            id: Subnet.id
          }
        }
      }
    ]
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: true
    activeActive: false
    vpnGatewayGeneration: 'Generation1'
  }
}

output VNetGwId string = VirtualNetworkGW.id
