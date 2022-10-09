param RTname string
param addressPrefix string 
param nextHopType string 
param nextHopIpAddress string
param hasBgpOverride bool = false

resource route2fw 'Microsoft.Network/routeTables/routes@2021-08-01' = {
  name: '${RTname}/ToFW'
  properties: {
    addressPrefix: addressPrefix
    nextHopType: nextHopType
    nextHopIpAddress: nextHopIpAddress
    hasBgpOverride: hasBgpOverride
  }
}
