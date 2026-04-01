# Download Windows Admin Center installation package
$WACDownloadUrl = "https://aka.ms/WACDownload/win"
$WACDownloadPath = "C:\WAC\WindowsAdminCenter.msi"

Invoke-WebRequest -Uri $WACDownloadUrl -OutFile $WACDownloadPath

# Install Windows Admin Center silently
$WACArguments = @(
    "/i $WACDownloadPath",
    "/qn",
    "/norestart",
    "/accepteula"
)

$Installer = Start-Process -FilePath "msiexec" -ArgumentList $WACArguments -Wait -PassThru

# Check if the installation was successful
if ($Installer.ExitCode -ne 0) {
    Write-Error "Installation failed with exit code $($Installer.ExitCode)"
}
else {
    Write-Output "Installation completed successfully"
}

# Enable Windows Admin Center extension
$enabledWACExtension = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ServerManagementGateway\CurrentVersion\Features' -Name ServerManagementGateway
if ($null -eq $enabledWACExtension) {
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ServerManagementGateway\CurrentVersion\Features' -Name ServerManagementGateway -Value "1" -Type DWord
    Write-Output "Windows Admin Center extension enabled successfully"
}
else {
    Write-Output "Windows Admin Center extension already enabled"
}
