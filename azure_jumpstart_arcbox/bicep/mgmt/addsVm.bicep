@description('The FQDN of the domain')
param addsDomainName string = 'jumpstart.local'

@description('The name of your Virtual Machine')
param clientVMName string = '${namingPrefix}-ADDS'

@description('Username for the Virtual Machine')
param windowsAdminUsername string = 'arcdemo'

@description('Password for Windows account. Password must have 3 of the following: 1 lower case character, 1 upper case character, 1 number, and 1 special character. The value must be between 12 and 123 characters long.')
@minLength(12)
@maxLength(123)
@secure()
param windowsAdminPassword string

@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version')
param windowsOSVersion string = '2022-datacenter-g2'

@description('Location for all resources')
param azureLocation string = resourceGroup().location

@description('The size of the VM')
//param vmSize string = 'Standard_B2ms'
param vmSize string = 'Standard_B1ms'

@description('Choice to deploy Azure Bastion')
param deployBastion bool = false

@description('Base URL for ARM template')
param templateBaseUrl string = ''

@maxLength(7)
@description('The naming prefix for the nested virtual machines. Example: ArcBox-Win2k19')
param namingPrefix string = 'ArcBox'

var networkInterfaceName = '${clientVMName}-NIC'
var virtualNetworkName = '${namingPrefix}-VNet'
var dcSubnetName = '${namingPrefix}-DC-Subnet'
var addsPrivateIPAddress = '10.16.2.100'
var bastionName = '${namingPrefix}-Bastion'
var osDiskType = 'Premium_LRS' //'Standard_LRS'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, dcSubnetName)
var networkInterfaceRef = networkInterface.id
var publicIpAddressName = ((!deployBastion) ? '${clientVMName}-PIP' : '${bastionName}-PIP')
var PublicIPNoBastion = {
  id: publicIpAddress.id
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: networkInterfaceName
  location: azureLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: addsPrivateIPAddress
          publicIPAddress: ((!deployBastion) ? PublicIPNoBastion : null)
        }
      }
    ]
  }
}

resource publicIpAddress 'Microsoft.Network/publicIpAddresses@2022-01-01' = if (!deployBastion) {
  name: publicIpAddressName
  location: azureLocation
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
}

resource clientVM 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: clientVMName
  location: azureLocation
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        name: '${clientVMName}-OSDisk'
        caching: 'ReadWrite'
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        diskSizeGB: 128
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOSVersion
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceRef
        }
      ]
    }
    osProfile: {
      computerName: clientVMName
      adminUsername: windowsAdminUsername
      adminPassword: windowsAdminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: false
      }
    }
  }
}

resource vmName_DeployADDS 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: clientVM
  name: 'DeployADDS'
  location: azureLocation
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      fileUris: [
        uri(templateBaseUrl, 'artifacts/SetupADDS.ps1')
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File SetupADDS.ps1 -domainName ${addsDomainName} -domainAdminUsername ${windowsAdminUsername} -domainAdminPassword ${windowsAdminPassword} -templateBaseUrl ${templateBaseUrl}'
    }
  }
}

output scriptfile string = uri(templateBaseUrl, 'artifacts/SetupADDS.ps1')
