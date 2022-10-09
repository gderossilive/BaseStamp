param RTname string
param location string = resourceGroup().location
param disableBgpRoutePropagation bool = false

resource RT 'Microsoft.Network/routeTables@2021-08-01' = {
  name: RTname
  location: location
  properties: {
    disableBgpRoutePropagation: disableBgpRoutePropagation
    routes: []
  }
}

output RTid string = RT.id
