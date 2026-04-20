$subnetParams = @()
# Dev
$subnetParams += [PSCustomObject]@{
  subnetName = "snet-pe-rsv-polarion-dev"
  ipRange = "10.83.157.0/27"
  networkSecurityGroupSuffix = "snet-pe-rsv-polarion-dev-nsg"
}
$subnetParams += [PSCustomObject]@{
  subnetName = "snet-pe-app-polarion-dev"
  ipRange = "10.83.157.32/28"
  networkSecurityGroupSuffix = "snet-pe-app-polarion-dev-nsg"

}
$subnetParams += [PSCustomObject]@{
  subnetName = "snet-compute-polarion-dev"
  ipRange = "10.83.157.48/28"
  networkSecurityGroupSuffix = "snet-compute-polarion-dev-nsg"

}

# QA
$subnetParams += [PSCustomObject]@{
  subnetName = "snet-pe-rsv-polarion-qa"
  ipRange = "10.83.157.64/27"
  networkSecurityGroupSuffix = "snet-pe-rsv-polarion-qa-nsg"
}
$subnetParams += [PSCustomObject]@{
  subnetName = "snet-pe-app-polarion-qa"
  ipRange = "10.83.157.96/28"
  networkSecurityGroupSuffix = "snet-pe-app-polarion-qa-nsg"
}
$subnetParams += [PSCustomObject]@{
  subnetName = "snet-compute-polarion-qa"
  ipRange = "10.83.157.112/28"
  networkSecurityGroupSuffix = "snet-compute-polarion-qa-nsg"
}

# Prod
$subnetParams += [PSCustomObject]@{
  subnetName = "snet-pe-rsv-polarion-prod"
  ipRange = "10.83.157.128/27"
  networkSecurityGroupSuffix = "snet-pe-rsv-polarion-prod-nsg"
}
$subnetParams += [PSCustomObject]@{
  subnetName = "snet-pe-app-polarion-prod"
  ipRange = "10.83.157.160/28"
  networkSecurityGroupSuffix = "snet-pe-app-polarion-prod-nsg"
}
$subnetParams += [PSCustomObject]@{
  subnetName = "snet-compute-polarion-prod"
  ipRange = "10.83.157.176/28"
  networkSecurityGroupSuffix = "snet-compute-polarion-prod-nsg"
}


# Shared Services
$subnetParams += [PSCustomObject]@{
  subnetName = "snet-shared-polarion-services"
  ipRange = "10.83.157.192/26"
  networkSecurityGroupSuffix = "snet-shared-polarion-services-nsg"
}


################################


  {
    nameSuffix: 'snet-pe-rsv-polarion-dev'
    addressPrefix: '10.83.157.0/27'
    networkSecurityGroupSuffix: 'snet-pe-rsv-polarion-dev-nsg'
  }
  {
    nameSuffix: 'snet-pe-app-polarion-dev'
    addressPrefix: '10.83.157.32/28'
    networkSecurityGroupSuffix: 'snet-pe-app-polarion-dev-nsg'
  }
  {
    nameSuffix: 'snet-compute-polarion-dev'
    addressPrefix: '10.83.157.48/28'
    networkSecurityGroupSuffix: 'snet-compute-polarion-dev-nsg'
  }
  {
    nameSuffix: 'snet-pe-rsv-polarion-qa'
    addressPrefix: '10.83.157.64/27'
    networkSecurityGroupSuffix: 'snet-pe-rsv-polarion-qa-nsg'
  }
  {
    nameSuffix: 'snet-pe-app-polarion-qa'
    addressPrefix: '10.83.157.96/28'
    networkSecurityGroupSuffix: 'snet-pe-app-polarion-qa-nsg'
  }
  {
    nameSuffix: 'snet-compute-polarion-qa'
    addressPrefix: '10.83.157.112/28'
    networkSecurityGroupSuffix: 'snet-compute-polarion-qa-nsg'
  }
  {
    nameSuffix: 'snet-pe-rsv-polarion-prod'
    addressPrefix: '10.83.157.128/27'
    networkSecurityGroupSuffix: 'snet-pe-rsv-polarion-prod-nsg'
  }
  {
    nameSuffix: 'snet-pe-app-polarion-prod'
    addressPrefix: '10.83.157.160/28'
    networkSecurityGroupSuffix: 'snet-pe-app-polarion-prod-nsg'
  }
  {
    nameSuffix: 'snet-compute-polarion-prod'
    addressPrefix: '10.83.157.176/28'
    networkSecurityGroupSuffix: 'snet-compute-polarion-prod-nsg'
  }
  {
    nameSuffix: 'snet-shared-polarion-services'
    addressPrefix: '10.83.157.192/26'
    networkSecurityGroupSuffix: 'snet-shared-polarion-services-nsg'
  }

