# Define the OpenSSL URL and local path
$opensslUrl = "https://slproweb.com/download/Win64OpenSSL-3_1_4.msi"

# Download OpenSSL if the MSI file does not exist
if (!(Test-Path -Path "C:\Appl\Win64OpenSSL-3_1_4.msi")) {
    Invoke-WebRequest -Uri $opensslUrl -OutFile "C:\Appl\Win64OpenSSL-3_1_4.msi" -UseBasicParsing
}

# Install OpenSSL with silent and no restart options
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "C:\Appl\Win64OpenSSL-3_1_4.msi", "/quiet", "/norestart" -NoNewWindow -Wait

# Add OpenSSL path to the System environment PATH
[System.Environment]::SetEnvironmentVariable("PATH", [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";C:\Program Files\OpenSSL-Win64\bin", "Machine")

