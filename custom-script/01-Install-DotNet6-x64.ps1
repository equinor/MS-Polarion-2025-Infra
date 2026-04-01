# Define the base URI for .NET downloads
$DotNetBaseUri = "https://dotnet.microsoft.com/download/dotnet/6.0"

# Use Invoke-WebRequest to get the .NET download page content
$DotNetPage = Invoke-WebRequest -Uri $DotNetBaseUri -UseBasicParsing

# Use a regular expression to find the latest .NET 6 version number
$DotNet6Version = ($DotNetPage.Content | Select-String -Pattern 'dotnet-sdk-([0-9\.]+)-win-x64.exe' -AllMatches).Matches | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique | Select-Object -Last 1

# Define the download URI based on the version
$DotNet6Uri = "https://download.microsoft.com/download/6/$DotNet6Version/dotnet-sdk-$DotNet6Version-win-x64.exe"

# Download the file and overwrite if it already exists
Invoke-WebRequest -Uri $DotNet6Uri -OutFile "C:\Appl\dotnet6-win-x64.exe" -UseBasicParsing

# Install .NET with silent and no restart options
Start-Process -FilePath "C:\Appl\dotnet6-win-x64.exe" -ArgumentList "/quiet", "/norestart" -NoNewWindow -Wait
