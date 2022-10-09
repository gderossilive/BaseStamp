param amplsName string
param virtualNetworkName string
param subnetName string
param dnsZones array = [
  'privatelink.monitor.azure.com'
  'privatelink.oms.opinsights.azure.com'
  'privatelink.ods.opinsights.azure.com'
  'privatelink.agentsvc.azure-automation.net'
  'privatelink.blob.core.windows.net'
]

var random=uniqueString(resourceGroup().name,virtualNetworkName)
var peName = 'PE-${random}'

resource ampls 'microsoft.insights/privateLinkScopes@2021-07-01-preview' = {
  name: amplsName
  location: 'global'
  properties: {
    accessModeSettings: {
      ingestionAccessMode: 'Open'
      queryAccessMode: 'Open'
    }
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
          privateLinkServiceId: ampls.id
          groupIds: [
            'azuremonitor'
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
  location: resourceGroup().location
  properties: {
    privateDnsZoneConfigs: [for i in range(0, length(dnsZones)): {
        name: dnsZones[i]
        properties: {
          privateDnsZoneId: zones[i].id
        }
    }]
  }
}

output name string = ampls.name
