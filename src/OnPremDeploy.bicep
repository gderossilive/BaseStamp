targetScope='subscription'

// Resource Groups
param OnPremRGname string
param HubRGname string
param location string 

// Virtual Networks
param OnPremVnetName string 
param OnPremVnetAddressPrefix string 
param OnPremGWvnetSubnetAddressPrefix string 
param OnPremPEvnetSubnetAddressPrefix string
param HubVnetName string
param CustomDNSserverAddress string

param DeployProxy bool
@secure()
param adminPassword string
param Seed string
param MyObjectId string 
param MyIPaddress string
param RulesetName string



var networkSecurityGroupName = 'NSG-${Seed}'
var HubToOnPremConnectionName = 'Hub2OnPrem-${Seed}'
var OnPremToHubConnectionName = 'OnPrem2Hub-${Seed}'
var OnPremVirtualNetworkGWName = 'OnPremVNGW-${Seed}'
var HubVirtualNetworkGWName = 'HubVNGW-${Seed}'
var Proxyname = 'Proxy-${Seed}'
var PEsubnetName = 'PE-Subnet'
var KVname = 'KV-${Seed}'



resource OnPremRG 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: OnPremRGname
  location: location
}

resource HubRG 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: HubRGname
}

module OnPremRT 'lib/RouteTable.bicep' = {
  scope: OnPremRG
  name: 'OnPremRT'
  params: {
    RTname: 'OnPremRT'
    location: OnPremRG.location
  }
}

module OnPremVnet './lib/SpokeVNetwork.bicep' = {
  name: OnPremVnetName
  scope: OnPremRG
  params: {
    virtualNetworkName: OnPremVnetName
    vnetSddressPrefix: OnPremVnetAddressPrefix
    PEsubnetName:  PEsubnetName
    PEsubnetAddressPrefix: OnPremPEvnetSubnetAddressPrefix
    GatewaySubnetAddressPrefix: OnPremGWvnetSubnetAddressPrefix
    DeployGw: true
    NSGname: networkSecurityGroupName
    RouteTableId: OnPremRT.outputs.RTid
    location: location
    CustomDNSserver: CustomDNSserverAddress
  }
}

module OnPremVNetGW 'lib/VirtualNetworkGateway.bicep' = {
  dependsOn: [
    OnPremVnet
  ]
  scope: OnPremRG
  name:  OnPremVirtualNetworkGWName
  params: {
    VirtualNetGwName: OnPremVirtualNetworkGWName
    VnetName: OnPremVnetName
    location: location
  }
}
 
module HubVNetGW 'lib/VirtualNetworkGateway.bicep' = {
  scope: HubRG
  name:  HubVirtualNetworkGWName
  params: {
    VirtualNetGwName: HubVirtualNetworkGWName
    VnetName: HubVnetName
    location: location
  }
}

module Hub2OnPremConnection 'lib/NetGwConnection.bicep' = {
  dependsOn: [
    OnPremVNetGW
    HubVNetGW
  ]
  scope: HubRG
  name: HubToOnPremConnectionName
  params: {
    connection_name: HubToOnPremConnectionName
    LocalGWId: HubVNetGW.outputs.VNetGwId
    RemoteGWId: OnPremVNetGW.outputs.VNetGwId
    location: location
  }
}

module OnPrem2HubConnection 'lib/NetGwConnection.bicep' = {
  dependsOn: [
    OnPremVNetGW
    HubVNetGW
  ]
  scope: OnPremRG
  name: OnPremToHubConnectionName
  params: {
    connection_name: OnPremToHubConnectionName
    LocalGWId: OnPremVNetGW.outputs.VNetGwId
    RemoteGWId: HubVNetGW.outputs.VNetGwId
    location: location
  }
}

module KV './lib/KV.bicep' = {
  name: KVname
  scope: HubRG
  params: {
    keyVaultName: KVname
    objectId: MyObjectId
    VnetName: HubVnetName
    SubnetName: PEsubnetName
    MyIPaddress: MyIPaddress
    RulesetName: RulesetName
    location: HubRG.location
  }
}

module adminPasswd './lib/Secret.bicep' = {
  dependsOn: [
    KV
  ]
  name: 'adminPassword'
  scope: HubRG
  params: {
    KVname: KVname
    secretName: 'adminPassword'
    secret: adminPassword
  }
}

module Proxy './lib/UbuntuVM.bicep' = if (DeployProxy) {
  dependsOn: [
    OnPremVnet
  ]
  name: Proxyname
  scope: OnPremRG
  params: {
    vmName: Proxyname
    virtualNetworkName: OnPremVnetName
    subnetName: PEsubnetName
    adminPassword: adminPassword
    location: OnPremRG.location
  }
}

/*
module NoInternetOnPrem 'lib/AddNsgRule.bicep' = if (DeployProxy) {
  dependsOn: [
    Proxy
  ]
  scope: OnPremRG
  name: 'NoInternetOnPrem'
  params: {
    destinationPortRange: '*'
    sourceAddressPrefixes: []
    access: 'Deny'
    NsgName: networkSecurityGroupName
    protocol: 'Tcp'
    sourcePortRange: '*'
    priority: 1000
    sourceAddressPrefix: '*'
    destinationAddressPrefix: 'Internet'
    destinationPortRanges: [
      443
      80
    ]
    sourcePortRanges: []
    direction: 'Outbound'
    destinationAddressPrefixes: []
  }
}*/



output OnPremVnetName string = OnPremVnetName
//output DnsName string = DNSname
output NSGname string = networkSecurityGroupName
output PEsubnetName string = PEsubnetName
output ProxyName string = (DeployProxy) ? Proxyname : ''
