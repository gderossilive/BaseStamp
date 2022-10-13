param NSGname string
param location string = resourceGroup().location

resource NSG 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: NSGname
  location: location
  properties: {
    securityRules: []
  }
}

output NsgId string = NSG.id
