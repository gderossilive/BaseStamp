targetScope='subscription'

// General parameters
param Seed string
param MyIP string
param Location string

// Hub parameters
param HubRgPostfix string
param HubVnetPrefix string
param InSubnetPrefix string
param OutSubnetPrefix string
param PEsubnetName string
param HubVnetAddressPrefix string
param CustomDNSserver string
param DNSInboundSubnetAddressPrefix string
param DNSOutboundSubnetAddressPrefix string
param BastionSubnetAddressPrefix string
param PEsubnetAddressPrefix string
param FirewallSubnetAddressPrefix string
param GatewaySubnetAddressPrefix string
param DeployFirewall bool

// Spoke parameter
param SpokeRgPostfix string
param SpokesNumber int = 1

// OnPrem parameters
param DeployOnPrem bool
param DeployProxy bool
param OnPremRgPostfix string
param MyObjectId string 
param OnPremVnetPrefix string 
param OnPremVnetAddressPrefix string 
param OnPremGWvnetSubnetAddressPrefix string 
param OnPremPEvnetSubnetAddressPrefix string
@secure()
param adminPassword string

var HubRgName = '${Seed}-${HubRgPostfix}'
var SpokeRgName = '${Seed}-${SpokeRgPostfix}'
var OnPremRGname = '${Seed}-${OnPremRgPostfix}'
var HubVnetName = '${HubVnetPrefix}-${Seed}'
var InSubnetName = '${InSubnetPrefix}-${Seed}'
var OutSubnetName = '${OutSubnetPrefix}-${Seed}'
var OnPremVnetName = '${OnPremVnetPrefix}-${Seed}'

module HubDeploy 'HubDeploy.bicep' = {
  name: 'HubDeploy-${Seed}'
  params: {
    BastionSubnetAddressPrefix: BastionSubnetAddressPrefix
    CustomDNSserver: CustomDNSserver
    DeployFirewall: DeployFirewall
    DNSInboundSubnetAddressPrefix: DNSInboundSubnetAddressPrefix
    DNSOutboundSubnetAddressPrefix: DNSOutboundSubnetAddressPrefix
    FirewallSubnetAddressPrefix: FirewallSubnetAddressPrefix
    GatewaySubnetAddressPrefix: GatewaySubnetAddressPrefix
    HubRGname: HubRgName
    HubVnetAddressPrefix: HubVnetAddressPrefix
    HubVnetName: HubVnetName
    InSubnetName: InSubnetName
    location: Location
    MyIPaddress: MyIP
    OutSubnetName: OutSubnetName
    PEsubnetAddressPrefix: PEsubnetAddressPrefix
    PEsubnetName: PEsubnetName
    Seed: Seed
  }
}

module SpokesDeploy 'SpokesDeploy.bicep' = {
  name: 'SpokesDeploy-${Seed}'
  params: {
    CustomDNSserverAddress: HubDeploy.outputs.DNSIp
    DeployFirewall: DeployFirewall
    FwIP: HubDeploy.outputs.FwIp
    HubRGname: HubRgName
    HubVnetName: HubVnetName
    location: Location
    Seed: Seed
    SpokeRGname: SpokeRgName
    Spokes: SpokesNumber
  }
}

module OnPremDeploy 'OnPremDeploy.bicep' = if (DeployOnPrem) {
  name: 'OnPremDeploy-${Seed}'
  params: {
    adminPassword: adminPassword
    CustomDNSserverAddress: HubDeploy.outputs.DNSIp
    DeployProxy: DeployProxy
    HubRGname: HubRgName
    HubVnetName: HubVnetName
    location: Location
    MyIPaddress: MyIP
    MyObjectId: MyObjectId
    OnPremGWvnetSubnetAddressPrefix: OnPremGWvnetSubnetAddressPrefix
    OnPremPEvnetSubnetAddressPrefix: OnPremPEvnetSubnetAddressPrefix
    OnPremRGname: OnPremRGname
    OnPremVnetAddressPrefix: OnPremVnetAddressPrefix
    OnPremVnetName: OnPremVnetName
    RulesetName: HubDeploy.outputs.RulesetName
    Seed: Seed
  }
}
