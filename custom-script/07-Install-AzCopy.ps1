# Define the AzCopy URL and local paths
$AzCopyUrl = "https://aka.ms/downloadazcopy-v10-windows"
$AzCopyZipPath = "c:\Appl\Azcopy\AzCopy.zip"
$TempDirPath = "c:\Appl\Temp"
$AzCopyDirPath = "c:\Appl\Azcopy"
$FinalDirPath = "C:\Program Files\AzCopy"

# Download AzCopy and overwrite the existing zip file if it exists
Invoke-WebRequest -Uri $AzCopyUrl -OutFile $AzCopyZipPath

# If the Temp directory doesn't exist, create it
if (!(Test-Path -Path $TempDirPath)) {
    New-Item -ItemType Directory -Force -Path $TempDirPath
}

# Extract AzCopy to the temporary directory
Expand-Archive -Path $AzCopyZipPath -DestinationPath $TempDirPath -Force

# If the AzCopy directory doesn't exist, create it
if (!(Test-Path -Path $AzCopyDirPath)) {
    New-Item -ItemType Directory -Force -Path $AzCopyDirPath
}

# Move files from the temporary directory to AzCopy directory, overwriting existing files
Get-ChildItem -Path "$TempDirPath\*" -Recurse | ForEach-Object {
    if (!$_.PSIsContainer) {
        $destinationFile = Join-Path $AzCopyDirPath $_.Name
        if (Test-Path $destinationFile) {
            Remove-Item $destinationFile
        }
        Move-Item $_.FullName -Destination $AzCopyDirPath
    }
}

# If the final directory doesn't exist, create it
if (!(Test-Path -Path $FinalDirPath)) {
    New-Item -ItemType Directory -Force -Path $FinalDirPath
}

# Move files from AzCopy directory to final directory, overwriting existing files
Get-ChildItem -Path "$AzCopyDirPath\*" | ForEach-Object {
    $destinationFile = Join-Path $FinalDirPath $_.Name
    if (Test-Path $destinationFile) {
        Remove-Item $destinationFile
    }
    Move-Item $_.FullName -Destination $FinalDirPath
}

# Remove the temporary directory and AzCopy directory
Remove-Item -Path $TempDirPath -Recurse -Force
Remove-Item -Path $AzCopyDirPath -Recurse -Force

# Define the final AzCopy directory
$FinalDirPath = "C:\Program Files\AzCopy"

# Add AzCopy to the System PATH
$envPath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
$newEnvPath = $envPath + ";" + $FinalDirPath
[System.Environment]::SetEnvironmentVariable("PATH", $newEnvPath, "Machine")
