param(
  [string]$SubscriptionPrefix,
  [string]$ResourceGroupName,
  [string]$EnvironmentName
)
$resourceGroupName = "$SubscriptionPrefix-$ResourceGroupName-$EnvironmentName"


$vmList = Get-AzVM -ResourceGroupName $resourceGroupName | ForEach-Object { $_.Name }
$headers = @{
    "Accept" = "text/json"
}

foreach ($VM in $vmList) {
    $jsonData = @{
        "serverName" = $VM
        "members" = @("a_torme","a_awy","a_otras","a_johab","a_mhaag","a_torme","80aaa1c7-b625-4ca7-a48e-fcbdfa5e95f6")
    } | ConvertTo-Json

    Invoke-RestMethod -Uri "https://ocn-adgroup.equinor.com/api/ServerAdGroup" -Method Post -Body $jsonData -ContentType "application/json" -Headers $headers
}

