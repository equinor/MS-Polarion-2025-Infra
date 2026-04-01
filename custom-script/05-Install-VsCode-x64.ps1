# Define the Visual Studio Code URL and local path
$vscodeUrl = "https://update.code.visualstudio.com/latest/win32-x64/stable"

# Download Visual Studio Code if the installer does not exist
if (!(Test-Path -Path "C:\Appl\VSCodeSetup-x64-stable.exe")) {
    Invoke-WebRequest -Uri $vscodeUrl -OutFile "C:\Appl\VSCodeSetup-x64-stable.exe" -UseBasicParsing
}

# Install Visual Studio Code with silent and no restart options
Start-Process -FilePath "C:\Appl\VSCodeSetup-x64-stable.exe" -ArgumentList "/silent", "/mergetasks=!runcode" -NoNewWindow -Wait

# Add Visual Studio Code path to the System environment PATH
[System.Environment]::SetEnvironmentVariable("PATH", [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";C:\Program Files\Microsoft VS Code\bin", "Machine")
