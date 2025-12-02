targetScope = 'resourceGroup'

@description('Required. The location to deploy the deployment script.')
param location string

@description('Required. The name of the deployment script.')
param scriptName string

resource sleepScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: scriptName
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '12.0'
    retentionInterval: 'PT1H'
    scriptContent: 'Start-Sleep -Seconds 300'
    timeout: 'PT10M'
  }
}
