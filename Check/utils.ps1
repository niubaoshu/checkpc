function Get-RandomString {
    param (
        [int]$length
    )
    Add-Type -AssemblyName System.Web
    $randomString = [System.Web.Security.Membership]::GeneratePassword($length, 0)
    $randomString
}

function Get-timeStamp {
    $timestamp = [long]([datetime]::UtcNow.Ticks / 10000)
    $timestamp 
}

function Get-reversedString {
    param (
        [string]$s
    )
    $reversedString = -join ($s.ToCharArray()[($s.Length - 1)..0])
    $reversedString
}

function Get-SignalStrength {
    param (
        [string]$appId,
        [string]$appSecret,
        [string]$randString
    )
    $reversedString = Get-reversedString($randString)
    $s = $appId + $randString + $appSecret + $reversedString
    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = New-Object -TypeName System.Text.UTF8Encoding
    $hash = [System.BitConverter]::ToString(
        $md5.ComputeHash($utf8.GetBytes($s))
    ).Replace("-", "").ToLower()
    $hash
}

$rs = Get-RandomString(100)
# Write-Host $rs
# Write-Host
# Get-reversedString($rs)
# Get-timeStamp

Get-SignalStrength -appId "aaaaaaaaaa" -appSecret "bbbbbbbbb" -randString $rs


function Confirm-Continue {
    param (
        [string]$Message = "There may be issues that need to be addressed. Do you want to continue?",
        [string]$ForegroundColor = "Yellow"
    )
    $Message = $Message + " (Press 'yes' or 'y' to continue, any other key to cancel)."

    Write-Host $Message -ForegroundColor $ForegroundColor 
    $userInput = Read-Host

    if ($userInput -eq "yes" -or $userInput -eq "y") {
        return $true
    }
    else {
        return $false
    }
}