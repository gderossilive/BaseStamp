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
param OnPremDMZvnetSubnetAddressPrefix string
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
var DMZsubnetName = 'DMZ-Subnet'
var KVname = 'KV-${Seed}'


resource HubRG 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: HubRGname
}
resource OnPremRG 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: OnPremRGname
  location: location
}

module OnPremNSG 'src/NSG.bicep' = {
  scope: OnPremRG
  name: OnPremRGname
  params: {
    NSGname: networkSecurityGroupName
    location: location
  }
}

module OnPremRT 'src/RouteTable.bicep' = {
  scope: OnPremRG
  name: 'OnPremRT'
  params: {
    RTname: 'OnPremRT'
    location: OnPremRG.location
  }
}

module OnPremVNet 'src/VirtualNetwork.bicep' = {
  scope: OnPremRG
  name: OnPremVnetName
  params: {
    virtualNetworkName: OnPremVnetName
    vnetAddressPrefix: OnPremVnetAddressPrefix
    CustomDNSserver: ''
    location: location
  }
}

module DMZsubnet 'src/VirtualNetwork-Subnet.bicep' = if (DeployProxy) {
  dependsOn: [
    OnPremVNet
  ]
  scope: OnPremRG
  name: DMZsubnetName
  params: {
    NsgId: ''
    RtId:  ''
    SubnetName: DMZsubnetName
    SubnetAddressPrefix: OnPremDMZvnetSubnetAddressPrefix
    VNetName: OnPremVnetName
  }
}

module GWsubnet 'src/VirtualNetwork-Subnet.bicep' = {
  dependsOn: [
    DMZsubnet
  ]
  scope: OnPremRG
  name: 'GatewaySubnet'
  params: {
    NsgId: ''
    RtId:  ''
    SubnetName: 'GatewaySubnet'
    VNetName: OnPremVnetName
    SubnetAddressPrefix: OnPremGWvnetSubnetAddressPrefix
  }
}

module PEsubnet 'src/VirtualNetwork-Subnet.bicep' = {
  dependsOn: [
    GWsubnet
  ]
  scope: OnPremRG
  name: 'PEsubnet'
  params: {
    NsgId: OnPremNSG.outputs.NsgId
    RtId:  OnPremRT.outputs.RTid
    SubnetName: 'PEsubnet'
    VNetName: OnPremVnetName
    SubnetAddressPrefix: OnPremPEvnetSubnetAddressPrefix
  }
}

module OnPremVNetGW 'src/VirtualNetworkGateway.bicep' = {
  dependsOn: [
    GWsubnet
  ]
  scope: OnPremRG
  name:  OnPremVirtualNetworkGWName
  params: {
    VirtualNetGwName: OnPremVirtualNetworkGWName
    VnetName: OnPremVnetName
    location: location
  }
}
 
module HubVNetGW 'src/VirtualNetworkGateway.bicep' = {
  scope: HubRG
  name:  HubVirtualNetworkGWName
  params: {
    VirtualNetGwName: HubVirtualNetworkGWName
    VnetName: HubVnetName
    location: location
  }
}

module Hub2OnPremConnection 'src/NetGwConnection.bicep' = {
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

module OnPrem2HubConnection 'src/NetGwConnection.bicep' = {
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

module KV './src/KV.bicep' = {
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

module adminPasswd './src/Secret.bicep' = {
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

module Proxy './src/UbuntuVM.bicep' = if (DeployProxy) {
  dependsOn: [
    DMZsubnet
  ]
  name: Proxyname
  scope: OnPremRG
  params: {
    vmName: Proxyname
    virtualNetworkName: OnPremVnetName
    subnetName: DMZsubnetName
    adminPassword: adminPassword
    location: OnPremRG.location
    Command: 'sudo apt-get update && sudo apt-get install -y squid apache2-utils && sudo wget https://gdrcontent.z16.web.core.windows.net/whitelist.txt -O /etc/squid/whitelist.txt && sudo wget https://gdrcontent.z16.web.core.windows.net/squid.conf -O /etc/squid/squid.conf && sudo systemctl restart squid'
  }
}

module NoInternetOnPrem 'src/AddNsgRule.bicep' = if (DeployProxy) {
  dependsOn: [
    Proxy
  ]
  scope: OnPremRG
  name: 'NoInternetOnPrem'
  params: {
    sourceAddressPrefixes: []
    access: 'Deny'
    NsgName: networkSecurityGroupName
    RuleName: 'NoInternet'
    protocol: 'Tcp'
    sourcePortRange: '*'
    priority: 1000
    sourceAddressPrefix: '*'
    destinationAddressPrefix: 'Internet'
    destinationPortRanges: [443,80]
    sourcePortRanges: []
    direction: 'Outbound'
    destinationAddressPrefixes: []
  }
}

output OnPremVnetName string = OnPremVnetName
output NSGname string = networkSecurityGroupName
output PEsubnetName string = PEsubnetName
output ProxyName string = (DeployProxy) ? Proxyname : ''
