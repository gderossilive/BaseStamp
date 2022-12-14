@description('Specifies the name of the key vault.')
param keyVaultName string

@description('Specifies the Azure location where the key vault should be created.')
param location string = resourceGroup().location

@description('Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.')
param enabledForDeployment bool = false

@description('Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.')
param enabledForDiskEncryption bool = false

@description('Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
param enabledForTemplateDeployment bool = true

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param objectId string

@description('Specifies the permissions to keys in the vault. Valid values are: all, encrypt, decrypt, wrapKey, unwrapKey, sign, verify, get, list, create, update, import, delete, backup, restore, recover, and purge.')
param keysPermissions array = [
  'list'
]

@description('Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge.')
param secretsPermissions array = [
  'list'
  'get'
  'set'
]

@description('Specifies whether the key vault is a standard vault or a premium vault.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

param VnetName string
param SubnetName string
param MyIPaddress string
param RulesetName string


var RuleName = 'KV-${seed}'
var seed = substring(uniqueString(resourceGroup().name,VnetName),0,5)
var PEname = 'PE-KV-${seed}'

resource Ruleset 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2020-04-01-preview' existing = {
  name: RulesetName
}

resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    tenantId: tenantId
    accessPolicies: [
      {
        objectId: objectId
        tenantId: tenantId
        permissions: {
          keys: keysPermissions
          secrets: secretsPermissions
        }
      }
    ]
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: [
        {
          value: '${MyIPaddress}/32'
        }
      ]
      virtualNetworkRules: []
    }
  }
}

resource VNet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: VnetName
}

resource Subnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  parent:VNet
  name: SubnetName
}

resource KVPE 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: PEname
  location: location
  properties: {
    subnet: {
      id: Subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: PEname
        properties: {
          privateLinkServiceId: kv.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

resource DNSzone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
}

resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  dependsOn: [
    DNSzone
  ]
  name: 'privatelink.vaultcore.azure.net/${uniqueString(tenantId)}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: VNet.id
    }
    registrationEnabled: false
  }
}

resource DNSzoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-03-01' = {
  dependsOn: [
    KVPE
  ]
  name: '${PEname}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-vaultcore-azure-net'
        properties: {
          privateDnsZoneId: DNSzone.id
        }
      }
    ]
  }
}

resource FarwardingRule 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2020-04-01-preview' = {
  name: '${RulesetName}/${RuleName}'
  properties: {
    domainName: 'privatelink.vaultcore.azure.net.'
    forwardingRuleState: 'Enabled'
    targetDnsServers: [
      {
        ipAddress: '10.10.0.4'
        port: 53
      }
    ]
  }
}
