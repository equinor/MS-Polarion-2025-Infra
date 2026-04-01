# Download OpenJDK 11 if the MSI file does not exist
if (!(Test-Path -Path "C:\Program Files\AdoptOpenJDK\jdk-11.0.20+8\bin")) {
    Invoke-WebRequest -Uri "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.20%2B8/OpenJDK11U-jdk_x64_windows_hotspot_11.0.20_8.msi" -OutFile "C:\Program Files\AdoptOpenJDK\jdk-11.0.20+8\bin" -UseBasicParsing
}

# Install OpenJDK 11 with silent and no restart options
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "C:\Program Files\AdoptOpenJDK\jdk-11.0.20+8\bin", "/quiet", "/norestart" -NoNewWindow -Wait

# Download OpenJDK 17 if the MSI file does not exist
if (!(Test-Path -Path "C:\Appl\OpenJDK17U-jdk_x64_windows_hotspot_17.0.5_8.msi")) {
    Invoke-WebRequest -Uri "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.5%2B8/OpenJDK17U-jdk_x64_windows_hotspot_17.0.5_8.msi" -OutFile "C:\Appl\OpenJDK17U-jdk_x64_windows_hotspot_17.0.5_8.msi" -UseBasicParsing
}

# Install OpenJDK 17 with silent and no restart options
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "C:\Appl\OpenJDK17U-jdk_x64_windows_hotspot_17.0.5_8.msi", "/quiet", "/norestart" -NoNewWindow -Wait


# Add OpenJDK paths to the System environment PATH
[System.Environment]::SetEnvironmentVariable("PATH", [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";C:\Program Files\AdoptOpenJDK\jdk-11.0.20+8\bin;C:\Program Files\AdoptOpenJDK\jdk-17.0.5+8\bin", "Machine")

# Set JAVA_HOME to point to OpenJDK 11 by default
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\AdoptOpenJDK\jdk-11.0.20+8", "Machine")
