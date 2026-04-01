# Define the URL for VC Redistributable
$vcRedistUrl = "https://download.visualstudio.microsoft.com/download/pr/c8edbb87-c7ec-4500-a461-71e8912d25e9/99ba493d660597490cbb8b3211d2cae4/vc_redist.x86.exe"

# Download VC Redistributable and overwrite if it already exists
Invoke-WebRequest -Uri $vcRedistUrl -OutFile "C:\Appl\vc_redist.x64.exe" -UseBasicParsing

# Install VC Redistributable with silent and no restart options
Start-Process -FilePath "C:\Appl\vc_redist.x64.exe" -ArgumentList "/quiet", "/norestart" -NoNewWindow -Wait
