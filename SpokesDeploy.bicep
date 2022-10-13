targetScope='subscription'

// Virtual Network
param HubVnetName string 

// Resource Group
param HubRGname string
param SpokeRGname string
param location string 

param Seed string
param Spokes int = 1
param DeployFirewall bool
param FwIP string
param CustomDNSserverAddress string

resource HubRG 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: HubRGname
}

resource SpokeRG 'Microsoft.Resources/resourceGroups@2021-01-01' = if (Spokes>0) {
  name: SpokeRGname
  location: location
}

module SpokeRT 'src/RouteTable.bicep' = if (Spokes>0) {
  scope: SpokeRG
  name: 'SpokeRT'
  params: {
    RTname: 'SpokeRT'
    location: SpokeRG.location
  }
}

module Route2FwHub 'src/RouteToFW.bicep' = if (DeployFirewall && Spokes>0) {
  scope: SpokeRG
  name: 'Route2FwHub'
  params: {
    RTname: SpokeRT.name
    addressPrefix: '0.0.0.0/0'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: DeployFirewall ? FwIP : ''
  }
}

module SpokesVnet './src/SpokeVNetwork.bicep' = [for i in range(0,Spokes): {
  name: 'Spoke-VNet-${i}'
  scope: SpokeRG
  params: {
    virtualNetworkName: 'Spoke-VNet-${i}'
    vnetAddressPrefix: '10.20.${i}.0/24'
    PEsubnetName:  'PEsubnet-${i}-${Seed}'
    PEsubnetAddressPrefix: '10.20.${i}.0/24'
    GatewaySubnetAddressPrefix: ''
    NSGname: 'NSG-${i}-${Seed}'
    RouteTableId: SpokeRT.outputs.RTid
    location: location
    CustomDNSserver: CustomDNSserverAddress
    DeployGw: false
    DeployFirewall: DeployFirewall
  }
}]

module Hub2Spoke './src/NetworkPeering.bicep' = [for i in range(0,Spokes): {
  dependsOn: [
    SpokesVnet
  ]
  name: 'Hub2Spoke-${i}'
  scope: HubRG
  params: {
    virtualNetworkName: HubVnetName
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: false 
    remoteResourceGroup: SpokeRGname
    remoteVirtualNetworkName: 'Spoke-VNet-${i}'
  }
}]

module Spoke2Hub './src/NetworkPeering.bicep' = [for i in range(0,Spokes): {
  dependsOn: [
    SpokesVnet
  ]
  name: 'Spoke2Hub-${i}'
  scope: SpokeRG
  params: {
    virtualNetworkName: 'Spoke-VNet-${i}'
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: false 
    remoteResourceGroup: HubRGname
    remoteVirtualNetworkName: HubVnetName
  }
}]


output SpokesVnetName array = [for i in range(0,Spokes): {
  name: SpokesVnet[i].outputs.virtualNetworkName
}]
