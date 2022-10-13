param connection_name string
param LocalGWId string
param RemoteGWId string
param location string

resource Connection 'Microsoft.Network/connections@2022-01-01' = {
  name: connection_name
  location: location
  properties: {
    sharedKey: 'Azure.123'
    connectionType: 'Vnet2Vnet'
    connectionProtocol: 'IKEv2'
    routingWeight: 0
    enableBgp: false
    useLocalAzureIpAddress: false
    usePolicyBasedTrafficSelectors: false
    ipsecPolicies:[]
    trafficSelectorPolicies: []
    expressRouteGatewayBypass: false
    dpdTimeoutSeconds: 0
    connectionMode: 'Default'
    virtualNetworkGateway1: {
      id: RemoteGWId
    }
    virtualNetworkGateway2: {
      id: LocalGWId
    }
  }
}
