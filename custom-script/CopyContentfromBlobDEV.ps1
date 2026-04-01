# Define the URL of your blob storage
$blobUrl = "https://polariondev.blob.core.windows.net/polarionblobdev"

# Download AzCopy
Invoke-WebRequest -Uri "https://aka.ms/downloadazcopy-v10-windows" -OutFile "AzCopy.zip" -UseBasicParsing
Expand-Archive -Path "AzCopy.zip" -DestinationPath "AzCopy" -Force

# Set AzCopy as a command
$azCopyCommand = ".\AzCopy\AzCopy.exe"

# Use AzCopy to download the blob contents
& $azCopyCommand copy "$blobUrl/*" "C:\appl\" --recursive
