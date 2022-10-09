param virtualNetworkName string
param subnetName string
param RulesetName string

var dnsZones = [
  'privatelink.guestconfiguration.azure.com'
  'privatelink.his.arc.azure.com'
  'privatelink.dp.kubernetesconfiguration.azure.com'
]
var seed=substring(uniqueString(resourceGroup().name,virtualNetworkName),0,3)
var peName = 'PE-AAPLS-${seed}'
var AAPLSname  = 'AAPLS-${seed}'

resource AAPLS 'Microsoft.HybridCompute/privateLinkScopes@2021-06-10-preview' = {
  name: AAPLSname
  location: resourceGroup().location
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

resource pe 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: peName
  location: resourceGroup().location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: peName
        properties: {
          privateLinkServiceId: AAPLS.id
          groupIds: [
            'hybridcompute'
          ]
        }
      }
    ]
  }
}

resource zones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for dnsZone in dnsZones: {
  name: dnsZone
  location: 'global'
}]

resource virtualNetworkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for dnsZone in dnsZones:{
  dependsOn: zones
  name: format('{0}/{1}', dnsZone, uniqueString(virtualNetworkName))
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)
    }
  }
}]

resource zonesGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: pe
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [for i in range(0, length(dnsZones)): {
        name: dnsZones[i]
        properties: {
          privateDnsZoneId: zones[i].id
        }
    }]
  }
}

resource FarwardingRule 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2020-04-01-preview' = [for dnsZone in dnsZones:{
  dependsOn: zones
  name:  format('{0}/{1}', RulesetName, uniqueString(dnsZone))
  properties: {
    domainName: '${dnsZone}.'
    forwardingRuleState: 'Enabled'
    targetDnsServers: [
      {
        ipAddress: '10.10.0.4'
        port: 53
      }
    ]
  }
}]

output name string = AAPLS.name
