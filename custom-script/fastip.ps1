$vms = get-azvm
$nic = get-aznetworkinterface | Where-Object VirtualMachine -NE $null #skip Nics with no VM
$nic.IpConfigurations[0].PrivateIpAllocationMethod = "Static"

$PrivateIpAllocationMethods = Foreach ($vm in $vms) {
    # collect NIC information
    $nics = get-aznetworkinterface | Where-Object VirtualMachine -NE $null #skip Nics with no VM
	foreach($nic in $nics) {
 		[PSCustomObject]@{
            Machine = $vm.name
            Nic = $nic
            PrivateIpAllocationMethod = $nic.IpConfigurations.PrivateIpAllocationMethod
        }
    }
}
write-output $PrivateIpAllocationMethods 
foreach ($PrivateIpAllocationMethod in $PrivateIpAllocationMethods | Where-Object { $_.nic.IpConfigurations.PrivateIpAllocationMethod -like "Dynamic"} ) {
write-output "setting privateipallocationmethod on machine: $($PrivateIpAllocationMethod.Machine) - nic: $($PrivateIpAllocationMethod.nic.name)"

$PrivateIpAllocationMethod.nic.IpConfigurations[0].PrivateIpAllocationMethod = "Static"
 
Set-AzNetworkInterface -NetworkInterface $PrivateIpAllocationMethod.nic

} 

