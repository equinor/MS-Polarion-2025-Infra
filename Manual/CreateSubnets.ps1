$subnetParams = @()
# Dev
$subnetParams += [PSCustomObject]@{
  subnetName = "snet-pe-rsv-dev"
  ipRange = "10.83.157.0/27"
}


$subnetParams += [PSCustomObject]@{
  subnetName = "snet-pe-app-dev"
  ipRange = "10.83.157.32/28"
}

$subnetParams += [PSCustomObject]@{
  subnetName = "snet-compute-dev"
  ipRange = "10.83.157.48/28"
}

# QA
$subnetParams += [PSCustomObject]@{
  subnetName = "snet-pe-rsv-qa"
  ipRange = "10.83.157.64/27"
}

$subnetParams += [PSCustomObject]@{
  subnetName = "snet-pe-app-qa"
  ipRange = "10.83.157.96/28"
}

$subnetParams += [PSCustomObject]@{
  subnetName = "snet-compute-qa"
  ipRange = "10.83.157.112/28"
}

# Prod
$subnetParams += [PSCustomObject]@{
  subnetName = "snet-pe-rsv-prod"
  ipRange = "10.83.157.128/27"
}

$subnetParams += [PSCustomObject]@{
  subnetName = "snet-pe-app-prod"
  ipRange = "10.83.157.160/28"
}

$subnetParams += [PSCustomObject]@{
  subnetName = "snet-compute-prod"
  ipRange = "10.83.157.176/28"
}

$subnetParams += [PSCustomObject]@{
  subnetName = "snet-shared-services"
  ipRange = "10.83.157.192/26"
}



