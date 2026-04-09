# Reference:
# ## Without system.web 
# https://dev.to/onlyann/user-password-generation-in-powershell-core-1g91#:~:text=In%20PowerShell%20%28as%20in%20Windows%20PowerShell%29%2C%20the%20commonly,Add-Type%20-AssemblyName%20System.Web%20%23%20Generate%20random%20password%20%5BSystem.Web.Security.Membership%5D%3A%3AGeneratePassword%288%2C2%29
# adjusted to work with ps7 and 5.1

function GeneratePassword {
    param(
        [ValidateRange(12, 256)]
        [int] 
        $maxLength = 24,
        $minLength = 18,
        [switch]$SecureString
    )

    # Add characters that will be available for the password function
    $symbols = "!@#$%^&*_-".ToCharArray()
    $characterList = [char[]]("a"[0].."z"[0]) + [char[]]("A"[0].."Z"[0]) + "0".."9" + $symbols

    do {

        $length = Get-Random -Minimum $minLength -Maximum $maxLength
        $password = -join (0..$length | % { $characterList | Get-Random })
        
        [int]$hasLowerChar = $password -cmatch '[a-z]'
        [int]$hasUpperChar = $password -cmatch '[A-Z]'
        [int]$hasDigit = $password -match '[0-9]'
        [int]$hasSymbol = $password.IndexOfAny($symbols) -ne -1

    }
    until (($hasLowerChar + $hasUpperChar + $hasDigit + $hasSymbol) -ge 3)

    if ($SecureString.IsPresent) {
        $password | ConvertTo-SecureString -AsPlainText -Force
    }
    else {
        $password
    }   
}

GeneratePassword -maxLength 48 -minLength 38 