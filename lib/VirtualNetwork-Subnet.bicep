param VNetName string
param SubnetName string
param SubnetAddressPrefix string 
param NsgId string
param RtId string


resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' = {
  name: '${VNetName}/${SubnetName}'
  properties: {
    addressPrefix: SubnetAddressPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    networkSecurityGroup: NsgId == '' ? null : {id: NsgId}
    routeTable: RtId == '' ? null : {id: RtId}
  }
}
