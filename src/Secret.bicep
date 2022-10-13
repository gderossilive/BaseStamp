param KVname string
param secretName string
@secure()
param secret string


resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: KVname
}

resource Secret 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  parent: kv
  name: secretName
  properties: {
    value: secret
  }
}
