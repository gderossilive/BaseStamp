targetScope='subscription'

// Resource Group
param HubRGname string
param location string 

// Virtual Network
param HubVnetName string 
param InSubnetName string 
param OutSubnetName string 
param PEsubnetName string 
param HubVnetAddressPrefix string 
param CustomDNSserver string
param DNSInboundSubnetAddressPrefix string 
param DNSOutboundSubnetAddressPrefix string 
param BastionSubnetAddressPrefix string 
param PEsubnetAddressPrefix string 
param FirewallSubnetAddressPrefix string 
param GatewaySubnetAddressPrefix string 


//@secure()
//param adminPassword string
param Seed string 
//param MyObjectId string 
param MyIPaddress string

param DeployFirewall bool
param DeployBastion bool

var networkSecurityGroupName = 'NSG-${Seed}'
//var KVname = 'KV-${Seed}'
var ResolverName = 'DNS-${Seed}'
var FwName = 'FW-${Seed}'
var BastionName = 'Bastion-${Seed}'


resource HubRG 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: HubRGname
  location: location
}

module HubRT 'lib/RouteTable.bicep' = {
  scope: HubRG
  name: 'HubRT'
  params: {
    RTname: 'HubRT'
    location: HubRG.location
  }
}

module Route2FwGwHub 'lib/RouteToFW.bicep' = if (DeployFirewall) {
  dependsOn: [
    AzFW
  ]
  scope: HubRG
  name: 'Route2FwHub'
  params: {
    RTname: HubRT.name
    addressPrefix: '0.0.0.0/0'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: DeployFirewall ? AzFW.outputs.FwIP : ''
  }
}

module HubVnet './lib/HubVNetwork.bicep' = {
  name: HubVnetName
  scope: HubRG
  params: {
    virtualNetworkName: HubVnetName
    vnetSddressPrefix: HubVnetAddressPrefix
    InSubnetName: InSubnetName
    OutSubnetName: OutSubnetName
    PEsubnetName: PEsubnetName
    DNSInboundSubnetAddressPrefix: DNSInboundSubnetAddressPrefix
    DNSOutboundSubnetAddressPrefix: DNSOutboundSubnetAddressPrefix
    BastionSubnetAddressPrefix: BastionSubnetAddressPrefix
    PEsubnetAddressPrefix: PEsubnetAddressPrefix
    FirewallSubnetAddressPrefix: FirewallSubnetAddressPrefix
    GatewaySubnetAddressPrefix: GatewaySubnetAddressPrefix
    CustomDNSserver: CustomDNSserver
    NSGname: networkSecurityGroupName
    RouteTableId: HubRT.outputs.RTid
    location: location
    Seed: Seed
    MyIPaddress: MyIPaddress
  }
}

module NoInternetHub 'lib/AddNsgRule.bicep' = if (DeployFirewall) {
  dependsOn: [
    HubVnet
  ]
  scope: HubRG
  name: 'NoInternetHub'
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
    NsgName: networkSecurityGroupName
    RuleName: 'NoInternet'
  }
}


module Resolver 'lib/Resolver.bicep' = {
  dependsOn: [
    HubVnet
  ]
  name: ResolverName
  scope: HubRG
  params: {
    ResName: ResolverName
    VnetName: HubVnet.name
    location: HubRG.location
    InSubnetName: InSubnetName
    OutSubnetName: OutSubnetName
    InEndName: InSubnetName
    OutEndName: OutSubnetName
  }
}

module AzFW 'lib/AzFW.bicep' = if (DeployFirewall) {
  dependsOn: [
    Resolver
  ]
  scope: HubRG
  name: FwName
  params: {
    virtualNetworkName: HubVnet.name
    location: HubRG.location
    CustomDnsIp: CustomDNSserver
  }
}

module Bastion 'lib/AzBastion.bicep' = if (DeployBastion) {
  dependsOn: [
    Resolver
  ]
  scope: HubRG
  name: BastionName
  params: {
    virtualNetworkName: HubVnet.name
    location: HubRG.location
  }
}

output HubVnetName string = HubVnetName
output ResolverName string = ResolverName
output DNSIp string = Resolver.outputs.DNSIp
output NSGname string = networkSecurityGroupName
output PEsubnetName string = PEsubnetName
//output KvName string = KVname
output RulesetName string = Resolver.outputs.RulesetName
output FwIp string = (DeployFirewall) ? AzFW.outputs.FwIP : ''
output FwName string = (DeployFirewall) ? FwName : ''
