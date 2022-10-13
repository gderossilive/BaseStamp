// Creates an Azure Bastion Subnet and host in the specified virtual network
@description('The Azure region where the Bastion should be deployed')
param location string = resourceGroup().location

@description('Virtual network name')
param virtualNetworkName string

@description('The address prefix to use for the Bastion subnet')
param addressPrefix string = '10.10.0.64/26'

@description('The name of the Bastion public IP address')
param publicIpName string = 'pip-bastion'

@description('The name of the Bastion host')
param bastionHostName string = 'bastion-jumpbox'

param MyIpAddress string = '81.56.1.134'

// The Bastion Subnet is required to be named 'AzureBastionSubnet'
var subnetName = 'AzureBastionSubnet'
var Seed = substring(uniqueString(virtualNetworkName, location),0,5)
var NsgName = 'BastionNSG-${Seed}'

resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' existing = {
  name: '${virtualNetworkName}/${subnetName}'
}/*resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = {
  dependsOn: [
    AllowAzureCloudOutbound
    AllowGatewayManagerInbound
    AllowHttpsInbound
    AllowSshRdpOutbound
  ]
  name: '${virtualNetworkName}/${subnetName}'
  properties: {
    addressPrefix: addressPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Disabled'
    networkSecurityGroup: {
      id: NSG.id
    }
  }
}*/

/*
resource NSG 'Microsoft.Network/networkSecurityGroups@2021-08-01' existing = {
  name: NsgName
}


resource AllowAzureCloudOutbound 'Microsoft.Network/networkSecurityGroups/securityRules@2021-08-01' = {
  parent: NSG
  name: 'AllowAzureCloudOutbound'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '443'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: 'AzureCloud'
    access: 'Allow'
    priority: 200
    direction: 'Outbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes:[]
  }
}

resource AllowGatewayManagerInbound 'Microsoft.Network/networkSecurityGroups/securityRules@2021-08-01' = {
  parent: NSG
  name: 'AllowGatewayManagerInbound'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '443'
    sourceAddressPrefix: 'GatewayManager'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 100
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes:[]
  }
}

resource AllowHttpsInbound 'Microsoft.Network/networkSecurityGroups/securityRules@2021-08-01' = {
  parent: NSG
  name: 'AllowHttpsInbound'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '443'
    sourceAddressPrefix: MyIpAddress
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 200
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes:[]
  }
}

resource AllowSshRdpOutbound 'Microsoft.Network/networkSecurityGroups/securityRules@2021-08-01' = {
  parent: NSG
  name: 'AllowSshRdpOutbound'
  properties: {
    protocol: '*'
    sourcePortRange: '*'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: 'VirtualNetwork'
    access: 'Allow'
    priority: 100
    direction: 'Outbound'
    sourcePortRanges: []
    destinationPortRanges: [
      '22'
      '3389'
    ]
    sourceAddressPrefixes: []
    destinationAddressPrefixes:[]
  }
}
*/
resource publicIpAddressForBastion 'Microsoft.Network/publicIpAddresses@2020-08-01' = {
  name: '${publicIpName}-${Seed}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2020-06-01' = {
  name: '${bastionHostName}-${Seed}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: bastionSubnet.id
          }
          publicIPAddress: {
            id: publicIpAddressForBastion.id
          }
        }
      }
    ]
  }
}

output bastionId string = bastionHost.id
