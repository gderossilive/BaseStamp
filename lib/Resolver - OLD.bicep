param ResName string
param InSubnetName string = 'dns-inbound-${Seed}'
param OutSubnetName string = 'dns-outbound-${Seed}'
param InEndName string = 'dns-inbound-${Seed}'
param OutEndName string = 'dns-outbound-${Seed}'
param RulesetName string = 'RS-${Seed}'
param NetworkLinkName string = '${VnetName}-link'
param VnetName string
param location string = resourceGroup().location
param Seed string =substring(uniqueString(resourceGroup().name,VnetName),0,5)


resource Vnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: VnetName
}

resource Resolver 'Microsoft.Network/dnsResolvers@2020-04-01-preview' = {
  dependsOn: [
    InboundSubnet
    OutboundSubnet
  ]
  name: ResName
  location: location
  properties: {
    virtualNetwork: {
      id: Vnet.id
    } 
  }
}

resource InboundSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = {
  parent: Vnet
  name: InSubnetName
  properties: {
    addressPrefix: '10.10.0.0/28'
    networkSecurityGroup: {
      id: Vnet.properties.subnets[0].properties.networkSecurityGroup.id
    }
  }
}

resource OutboundSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = {
  dependsOn: [
    InboundSubnet
  ]
  parent: Vnet
  name: OutSubnetName
  properties: {
    addressPrefix: '10.10.0.16/28'
    networkSecurityGroup: {
      id: Vnet.properties.subnets[0].properties.networkSecurityGroup.id
    }
  }
}

resource InboundEndpoint 'Microsoft.Network/dnsResolvers/inboundEndpoints@2020-04-01-preview' = {
  dependsOn: [
    Resolver
  ]
  name: '${ResName}/${InEndName}'
  location: location
  properties: {
    ipConfigurations: [
      {
        subnet: {
          id: InboundSubnet.id
        }
      }
    ]
  }
}

resource OutboundEndpoint 'Microsoft.Network/dnsResolvers/outboundEndpoints@2020-04-01-preview' = {
  dependsOn: [
    Resolver
    InboundEndpoint
  ]
  name: '${ResName}/${OutEndName}'
  location: location
  properties: {
    subnet: {
      id: OutboundSubnet.id
    }
  }
}

resource Ruleset 'Microsoft.Network/dnsForwardingRulesets@2020-04-01-preview' = {
  dependsOn: [
    InboundEndpoint
  ]
  name: RulesetName
  location: location
  properties: {
    dnsResolverOutboundEndpoints: [
      {
        id: OutboundEndpoint.id
      }
    ]
  }
}

resource VnetLink 'Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2020-04-01-preview' = {
  dependsOn: [
    Ruleset
  ]
  name: '${RulesetName}/${NetworkLinkName}'
  properties: {
    virtualNetwork: {
      id: Vnet.id
    }
  }
}

output RulesetName string = RulesetName
