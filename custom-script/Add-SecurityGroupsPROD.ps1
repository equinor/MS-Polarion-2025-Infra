$serverNames = @("S499PLWS01-PROD", "S499PLWS02-PROD", "S499PLWS03-PROD", "S499PLWS04-PROD")

foreach ($serverName in $serverNames) {
    $securityGroupName = "Admin_$serverName"
    $domainSecurityGroup = "statoil.net\$securityGroupName"
    Invoke-Command -ComputerName $serverName -ScriptBlock {
        param($dsg)
        Add-LocalGroupMember -Group "Administrators" -Member $dsg
    } -ArgumentList $domainSecurityGroup
}