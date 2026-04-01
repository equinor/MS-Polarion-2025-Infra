$serverNames = @("S499PLWS01-QA", "S499PLWS02-QA", "S499PLWS03-QA", "S499PLWS04-QA")

foreach ($serverName in $serverNames) {
    $securityGroupName = "Admin_$serverName"
    $domainSecurityGroup = "statoil.net\$securityGroupName"
    Invoke-Command -ComputerName $serverName -ScriptBlock {
        param($dsg)
        Add-LocalGroupMember -Group "Administrators" -Member $dsg
    } -ArgumentList $domainSecurityGroup
}
