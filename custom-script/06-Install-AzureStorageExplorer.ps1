# Define the URL for Azure Storage Explorer
$azureStorageExplorerUrl = "https://go.microsoft.com/fwlink/?LinkId=708343&clcid=0x409"

# Download Azure Storage Explorer and overwrite if it already exists
Invoke-WebRequest -Uri $azureStorageExplorerUrl -OutFile "C:\Appl\AzureStorageExplorer.exe" -UseBasicParsing

# Install Azure Storage Explorer with silent and no restart options
Start-Process -FilePath "C:\Appl\AzureStorageExplorer.exe" -ArgumentList "/quiet", "/norestart" -NoNewWindow -Wait