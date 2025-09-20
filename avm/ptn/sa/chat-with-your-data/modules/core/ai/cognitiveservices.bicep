metadata name = 'Cognitive Services'
metadata description = 'This module deploys a Cognitive Service.'

@description('Required. The name of Cognitive Services account.')
param name string

@description('Required. Kind of the Cognitive Services account. Use \'Get-AzCognitiveServicesAccountSku\' to determine a valid combinations of \'kind\' and \'SKU\' for your Azure region.')
@allowed([
  'AIServices'
  'AnomalyDetector'
  'CognitiveServices'
  'ComputerVision'
  'ContentModerator'
  'ContentSafety'
  'ConversationalLanguageUnderstanding'
  'CustomVision.Prediction'
  'CustomVision.Training'
  'Face'
  'FormRecognizer'
  'HealthInsights'
  'ImmersiveReader'
  'Internal.AllInOne'
  'LUIS'
  'LUIS.Authoring'
  'LanguageAuthoring'
  'MetricsAdvisor'
  'OpenAI'
  'Personalizer'
  'QnAMaker.v2'
  'SpeechServices'
  'TextAnalytics'
  'TextTranslation'
])
param kind string

@description('Optional. SKU of the Cognitive Services account. Use \'Get-AzCognitiveServicesAccountSku\' to determine a valid combinations of \'kind\' and \'SKU\' for your Azure region.')
@allowed([
  'C2'
  'C3'
  'C4'
  'F0'
  'F1'
  'S'
  'S0'
  'S1'
  'S10'
  'S2'
  'S3'
  'S4'
  'S5'
  'S6'
  'S7'
  'S8'
  'S9'
  'DC0'
])
param sku string = 'S0'

@description('Optional. Location for all Resources.')
param location string = resourceGroup().location

import { diagnosticSettingFullType } from 'br/public:avm/utl/types/avm-common-types:0.6.0'
@description('Optional. The diagnostic settings of the service.')
param diagnosticSettings diagnosticSettingFullType[]?

@description('Optional. Whether or not public network access is allowed for this resource. For security reasons it should be disabled. If not specified, it will be disabled by default if private endpoints are set and networkAcls are not set.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string?

@description('Conditional. Subdomain name used for token-based authentication. Required if \'networkAcls\' or \'privateEndpoints\' are set.')
param customSubDomainName string?

@description('Optional. A collection of rules governing the accessibility from specific network locations.')
param networkAcls object?

@description('Optional. Specifies in AI Foundry where virtual network injection occurs to secure scenarios like Agents entirely within a private network.')
param networkInjections networkInjectionType?

import { privateEndpointSingleServiceType } from 'br/public:avm/utl/types/avm-common-types:0.6.1'
@description('Optional. Configuration details for private endpoints. For security reasons, it is recommended to use private endpoints whenever possible.')
param privateEndpoints privateEndpointSingleServiceType[]?

import { lockType } from 'br/public:avm/utl/types/avm-common-types:0.6.0'
@description('Optional. The lock settings of the service.')
param lock lockType?

import { roleAssignmentType } from 'br/public:avm/utl/types/avm-common-types:0.6.0'
@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?

@description('Optional. Tags of the resource.')
param tags object?

@description('Optional. List of allowed FQDN.')
param allowedFqdnList array?

@description('Optional. The API properties for special APIs.')
param apiProperties object?

@description('Optional. Allow only Azure AD authentication. Should be enabled for security reasons.')
param disableLocalAuth bool = true

import { customerManagedKeyType } from 'br/public:avm/utl/types/avm-common-types:0.6.0'
@description('Optional. The customer managed key definition.')
param customerManagedKey customerManagedKeyType?

@description('Optional. The flag to enable dynamic throttling.')
param dynamicThrottlingEnabled bool = false

@secure()
@description('Optional. Resource migration token.')
param migrationToken string?

@description('Optional. Restore a soft-deleted cognitive service at deployment time. Will fail if no such soft-deleted resource exists.')
param restore bool = false

@description('Optional. Restrict outbound network access.')
param restrictOutboundNetworkAccess bool = true

@description('Optional. The storage accounts for this resource.')
param userOwnedStorage resourceInput<'Microsoft.CognitiveServices/accounts@2025-04-01-preview'>.properties.userOwnedStorage?

import { managedIdentityAllType } from 'br/public:avm/utl/types/avm-common-types:0.6.0'
@description('Optional. The managed identity definition for this resource.')
param managedIdentities managedIdentityAllType?

@description('Optional. Enable/Disable usage telemetry for module.')
param enableTelemetry bool = true

@description('Optional. Array of role assignments to create for the Cognitive Services resource.')
param roleAssignments array = []
@description('Optional. Array of role assignments to apply to the system-assigned identity at the Cognitive Services account scope. Each item: { roleDefinitionId: "<GUID or built-in role definition id>" }')
param systemAssignedRoleAssignments array = []
// Resource variables
var cognitiveResourceName = name

module cognitiveServices '../../cognitive-services/account/cognitive-services.bicep' = {
  name: take('avm.res.cognitive-services.account.${cognitiveResourceName}', 64)
  params: {
    name: cognitiveResourceName
    location: location
    tags: tags
    kind: kind
    sku: sku
    customSubDomainName: customSubDomainName
    disableLocalAuth: disableLocalAuth
    managedIdentities: { systemAssigned: enableSystemAssigned, userAssignedResourceIds: [userAssignedResourceId] }
    roleAssignments: roleAssignments
    restrictOutboundNetworkAccess: restrictOutboundNetworkAccess
    allowedFqdnList: restrictOutboundNetworkAccess ? (allowedFqdnList ?? []) : []
    enableTelemetry: enableTelemetry
    diagnosticSettings: enableMonitoring ? [{ workspaceResourceId: logAnalyticsWorkspaceId }] : null
    networkAcls: {
      bypass: kind == 'OpenAI' || kind == 'AIServices' ? 'AzureServices' : null
      defaultAction: enablePrivateNetworking ? 'Deny' : 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: enablePrivateNetworking ? 'Disabled' : 'Enabled'
    privateEndpoints: enablePrivateNetworking && !empty(privateDnsZoneResourceId)
      ? [
          {
            name: 'pep-${cognitiveResourceName}'
            customNetworkInterfaceName: 'nic-${cognitiveResourceName}'
            service: 'account'
            subnetResourceId: subnetResourceId
            privateDnsZoneGroup: {
              privateDnsZoneGroupConfigs: [
                { privateDnsZoneResourceId: privateDnsZoneResourceId }
              ]
            }
            // privateDnsZoneResourceIds: [
            //   privateDnsZoneResourceId
            // ]
          }
        ]
      : []
    deployments: deployments
  }
}
// --- System-assigned identity role assignments (optional) --- //
@description('Role assignments applied to the system-assigned identity via AVM module. Objects can include: roleDefinitionId (req), roleName, principalType, resourceId.')
module systemAssignedIdentityRoleAssignments 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = [
  for assignment in systemAssignedRoleAssignments: if (enableSystemAssigned && !empty(systemAssignedRoleAssignments)) {
    name: take(
      'avm.ptn.authorization.resource-role-assignment.${uniqueString(cognitiveResourceName, assignment.roleDefinitionId, assignment.resourceId)}',
      64
    )
    params: {
      name: privateEndpoint.?name ?? 'pep-${last(split(cognitiveService.id, '/'))}-${privateEndpoint.?service ?? 'account'}-${index}'
      privateLinkServiceConnections: privateEndpoint.?isManualConnection != true
        ? [
            {
              name: privateEndpoint.?privateLinkServiceConnectionName ?? '${last(split(cognitiveService.id, '/'))}-${privateEndpoint.?service ?? 'account'}-${index}'
              properties: {
                privateLinkServiceId: cognitiveService.id
                groupIds: [
                  privateEndpoint.?service ?? 'account'
                ]
              }
            }
          ]
        : null
      manualPrivateLinkServiceConnections: privateEndpoint.?isManualConnection == true
        ? [
            {
              name: privateEndpoint.?privateLinkServiceConnectionName ?? '${last(split(cognitiveService.id, '/'))}-${privateEndpoint.?service ?? 'account'}-${index}'
              properties: {
                privateLinkServiceId: cognitiveService.id
                groupIds: [
                  privateEndpoint.?service ?? 'account'
                ]
                requestMessage: privateEndpoint.?manualConnectionRequestMessage ?? 'Manual approval required.'
              }
            }
          ]
        : null
      subnetResourceId: privateEndpoint.subnetResourceId
      enableTelemetry: enableReferencedModulesTelemetry
      location: privateEndpoint.?location ?? reference(
        split(privateEndpoint.subnetResourceId, '/subnets/')[0],
        '2020-06-01',
        'Full'
      ).location
      lock: privateEndpoint.?lock ?? lock
      privateDnsZoneGroup: privateEndpoint.?privateDnsZoneGroup
      roleAssignments: privateEndpoint.?roleAssignments
      tags: privateEndpoint.?tags ?? tags
      customDnsConfigs: privateEndpoint.?customDnsConfigs
      ipConfigurations: privateEndpoint.?ipConfigurations
      applicationSecurityGroupResourceIds: privateEndpoint.?applicationSecurityGroupResourceIds
      customNetworkInterfaceName: privateEndpoint.?customNetworkInterfaceName
    }
  }
]

resource cognitiveService_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(cognitiveService.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: cognitiveService
  }
]

@description('The name of the cognitive services account.')
output name string = cognitiveService.name

@description('The resource ID of the cognitive services account.')
output resourceId string = cognitiveService.id

@description('The resource group the cognitive services account was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The service endpoint of the cognitive services account.')
output endpoint string = cognitiveService.properties.endpoint

@description('All endpoints available for the cognitive services account, types depends on the cognitive service kind.')
output endpoints endpointType = cognitiveService.properties.endpoints

@description('The principal ID of the system assigned identity.')
output systemAssignedMIPrincipalId string? = cognitiveService.?identity.?principalId

@description('The location the resource was deployed into.')
output location string = cognitiveService.location

@description('The private endpoints of the congitive services account.')
output privateEndpoints privateEndpointOutputType[] = [
  for (pe, index) in (privateEndpoints ?? []): {
    name: cognitiveService_privateEndpoints[index].outputs.name
    resourceId: cognitiveService_privateEndpoints[index].outputs.resourceId
    groupId: cognitiveService_privateEndpoints[index].outputs.?groupId!
    customDnsConfigs: cognitiveService_privateEndpoints[index].outputs.customDnsConfigs
    networkInterfaceResourceIds: cognitiveService_privateEndpoints[index].outputs.networkInterfaceResourceIds
  }
]

// ================ //
// Definitions      //
// ================ //

@export()
@description('The type for the private endpoint output.')
type privateEndpointOutputType = {
  @description('The name of the private endpoint.')
  name: string

  @description('The resource ID of the private endpoint.')
  resourceId: string

  @description('The group Id for the private endpoint Group.')
  groupId: string?

  @description('The custom DNS configurations of the private endpoint.')
  customDnsConfigs: {
    @description('FQDN that resolves to private endpoint IP address.')
    fqdn: string?

    @description('A list of private IP addresses of the private endpoint.')
    ipAddresses: string[]
  }[]

  @description('The IDs of the network interfaces associated with the private endpoint.')
  networkInterfaceResourceIds: string[]
}

@export()
@description('The type for a cognitive services account deployment.')
type deploymentType = {
  @description('Optional. Specify the name of cognitive service account deployment.')
  name: string?

  @description('Required. Properties of Cognitive Services account deployment model.')
  model: {
    @description('Required. The name of Cognitive Services account deployment model.')
    name: string

    @description('Required. The format of Cognitive Services account deployment model.')
    format: string

    @description('Required. The version of Cognitive Services account deployment model.')
    version: string
  }

  @description('Optional. The resource model definition representing SKU.')
  sku: {
    @description('Required. The name of the resource model definition representing SKU.')
    name: string

    @description('Optional. The capacity of the resource model definition representing SKU.')
    capacity: int?

    @description('Optional. The tier of the resource model definition representing SKU.')
    tier: string?

    @description('Optional. The size of the resource model definition representing SKU.')
    size: string?

    @description('Optional. The family of the resource model definition representing SKU.')
    family: string?
  }?

  @description('Optional. The name of RAI policy.')
  raiPolicyName: string?

  @description('Optional. The version upgrade option.')
  versionUpgradeOption: string?
}

@export()
@description('The type for a cognitive services account endpoint.')
type endpointType = {
  @description('Type of the endpoint.')
  name: string?
  @description('The endpoint URI.')
  endpoint: string?
}

@export()
@description('The type for a disconnected container commitment plan.')
type commitmentPlanType = {
  @description('Required. Whether the plan should auto-renew at the end of the current commitment period.')
  autoRenew: bool

  @description('Required. The current commitment configuration.')
  current: {
    @description('Required. The number of committed instances (e.g., number of containers or cores).')
    count: int

    @description('Required. The tier of the commitment plan (e.g., T1, T2).')
    tier: string
  }

  @description('Required. The hosting model for the commitment plan. (e.g., DisconnectedContainer, ConnectedContainer, ProvisionedWeb, Web).')
  hostingModel: string

  @description('Required. The plan type indicating which capability the plan applies to (e.g., NTTS, STT, CUSTOMSTT, ADDON).')
  planType: string

  @description('Optional. The unique identifier of an existing commitment plan to update. Set to null to create a new plan.')
  commitmentPlanGuid: string?

  @description('Optional. The configuration of the next commitment period, if scheduled.')
  next: {
    @description('Required. The number of committed instances for the next period.')
    count: int

    @description('Required. The tier for the next commitment period.')
    tier: string
  }?
}

@export()
@description('Type for network configuration in AI Foundry where virtual network injection occurs to secure scenarios like Agents entirely within a private network.')
type networkInjectionType = {
  @description('Required. The scenario for the network injection.')
  scenario: 'agent' | 'none'

  @description('Required. The Resource ID of the subnet on the Virtual Network on which to inject.')
  subnetResourceId: string

  @description('Optional. Whether to use Microsoft Managed Network. Defaults to false.')
  useMicrosoftManagedNetwork: bool?
}
