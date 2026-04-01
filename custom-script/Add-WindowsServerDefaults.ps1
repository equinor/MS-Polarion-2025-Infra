# Set Edge as the default web browser
$ProgID = "MSEdgeHTM"
$UserChoicePath = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice"
Set-ItemProperty -Path $UserChoicePath -Name ProgId -Value $ProgID

# Create a new folder at C:\Appl
New-Item -ItemType Directory -Force -Path C:\Appl

# Set the default download location to C:\Appl
$DownloadKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
Set-ItemProperty -Path $DownloadKeyPath -Name "{374DE290-123F-4565-9164-39C4925E467B}" -Value "C:\Appl"