param virtualNetworkName string
param location string = resourceGroup().location
param CustomDnsIp string = '10.10.100.4'

var AzFwName = '${Seed}-FW'
var AzFwPolicyName = '${Seed}-FWpolicy'
var publiIPAddressName = '${Seed}-IP'
var Seed = substring(uniqueString(virtualNetworkName, location),0,5)

resource VNet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: virtualNetworkName
}

resource FWsubnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = {
  name: 'AzureFirewallSubnet'
  parent: VNet
  properties: {
    addressPrefix: '10.10.2.0/24'
  }
}

resource PublicIP 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: publiIPAddressName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: []
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2021-05-01' = {
  name: AzFwPolicyName
  location: location
  properties: {
    sku: {
      tier: 'Premium'
    }
    dnsSettings: {
      servers: [
        CustomDnsIp
      ]
      enableProxy: true
    }
    threatIntelMode: 'Alert'
  }
}

resource AppRuleCollection 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-08-01' = {
  parent: firewallPolicy
  name: 'DefaultApplicationRuleCollectionGroup'
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'SpokeInternetSurf'
            protocols: [
              {
                protocolType: 'Http'
                port: 80
              }
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            fqdnTags: []
            webCategories: []
            targetFqdns: [
              '*'
            ]
            targetUrls: []
            terminateTLS: false
            sourceAddresses: [
              '10.20.0.0/16'
            ]
            destinationAddresses: []
            sourceIpGroups: []
          }
          {
            ruleType: 'ApplicationRule'
            name: 'HubInternetSurf'
            protocols: [
              {
                protocolType: 'Http'
                port: 80
              }
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            fqdnTags: []
            webCategories: []
            targetFqdns: [
              '*'
            ]
            targetUrls: []
            terminateTLS: false
            sourceAddresses: [
              '10.10.0.0/16'
            ]
            destinationAddresses: []
            sourceIpGroups: []
          }
          {
            ruleType: 'ApplicationRule'
            name: 'OnPremInternetSurf'
            protocols: [
              {
                protocolType: 'Http'
                port: 80
              }
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            fqdnTags: []
            webCategories: []
            targetFqdns: [
              '*'
            ]
            targetUrls: []
            terminateTLS: false
            sourceAddresses: [
              '192.168.0.0/16'
            ]
            destinationAddresses: []
            sourceIpGroups: []
          }
        ]
        name: 'InternetSurfing'
        priority: 100
      }
    ]
  }
}

resource AzFirewall 'Microsoft.Network/azureFirewalls@2021-08-01' = {
  dependsOn: [
    VNet
  ]
  name: AzFwName
  location: location
  zones: []
  properties: {
    sku: {
      tier: 'Premium'
    }
    ipConfigurations: [
      {
        name: PublicIP.name
        properties: {
          subnet: {
            id: FWsubnet.id
          }
          publicIPAddress: {
            id: PublicIP.id
          }
        }
      }
    ]
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
}

output AzFwName string = AzFwName
output AzFwPolicyName string = AzFwPolicyName
output publiIPAddressName string = publiIPAddressName
output FwIP string = AzFirewall.properties.ipConfigurations[0].properties.privateIPAddress
