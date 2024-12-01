function Get-KeyByServer {
    param(
        $userName,
        $pw,
        [int]$index,
        $osVersion,
        $computerSN,
        $result
    )

    # 定义服务器地址和端口
    $server = "127.0.0.1"
    $port = 12345

    # 创建 TCP 客户端
    $client = New-Object System.Net.Sockets.TcpClient($server, $port)

    # 获取网络流
    $stream = $client.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream)
    $reader = New-Object System.IO.StreamReader($stream)
    $writer.AutoFlush = $true

    # 发送数据
    $message = "$userName,$pd,$index,$osVersion,$computerSN"
    $writer.WriteLine($message)
    Write-Host "send data:$message"

    # 读取响应数据
    $response = $reader.ReadLine()
    Write-Host "recived data:$response"

    # 关闭连接
    $writer.Close()
    $reader.Close()
    $client.Close()
    $response
}

function Get-activationStatus {
    $result = (cscript.exe //nologo C:\WINDOWS\system32\slmgr.vbs /xpr) -Join ""
    $r = $result.Contains("The machine is permanently activated")
    if ($r) {
        Write-Host $result -ForegroundColor Green
    }
    return $r
}
function Get-ExistKeys {
    $result = (cscript.exe //nologo C:\WINDOWS\system32\slmgr.vbs /div) -Join ""
}

function Start-Activation {
    $result = ""
    $index = -1
    $osVersion = (Get-WmiObject -Class Win32_OperatingSystem).Caption
    $computerSN = (Get-WmiObject -Class Win32_BIOS).SerialNumber 
    $keyFileName = Get-KeyFileName -osVersion $osVersion
    $ks = [Keys]::new($keyFileName, $GetKeyByServer)
    $secondKey = $false
    :activate while (-not $(Get-activationStatus)) {
        if ($IsChangeKeys) {
            $kr = $ks.GetNextKey($userName, $pd, $index, $osVersion, $computerSN, $result) -split ","
            $index = $kr[0]
            $key = $kr[1]
            if ($index -eq -2) {
                Write-Host "The keys has been used up,this computer is not activated"  -ForegroundColor Red
                return $false
            }
            Write-Host "get key:", $key, "at ", $index, " line in ", $keyFileName -ForegroundColor Green
            changepk.exe /ProductKey $key -ErrorAction Stop
            if ($secondKey){
                Start-Sleep -Seconds 5
            }
            $secondKey = $true
        }
        :retry while ($true) {
            $result = (cscript.exe //nologo C:\WINDOWS\system32\slmgr.vbs /ato) -Join ""
            switch -Wildcard ($result) {
                "*Product activated successfully.*" { 
                    $ks.GetNextKey($userName, $pd, $index, $osVersion, $computerSN, $result)
                    Write-Host $result -ForegroundColor Green
                    break activate 
                }
                "*The activation server determined that the specified product key could not be used*" {
                    Write-Host $key "has used,we will try next keys" -ForegroundColor Red
                    break retry
                }
                "*The activation server determined the specified product key is blocked*" {
                    Write-Host $key "is blocked,we will try next keys" -ForegroundColor Red
                    break retry
                }
                "*The Software Licensing Service reported that the product key is not available*" {
                    Write-Host "!" -NoNewline -ForegroundColor Green
                    continue retry
                }
                "*Error: Product activation failed*" {
                    Write-Host "%" -NoNewline -ForegroundColor Green
                    continue retry
                }
                "*Error: * On a computer running Microsoft Windows non-core edition, run 'slui.exe *' to display the error text.*" {
                    Write-Host "#" -NoNewline -ForegroundColor Green
                    continue retry
                }
                "*The network location cannot be reached. For information about network troubleshooting, see Windows Help*" {
                    Write-Host "*" -NoNewline -ForegroundColor Green
                    continue retry
                }
                "*This operation returned because the timeout period expired*" {
                    Write-Host "@" -NoNewline -ForegroundColor Green
                    continue retry
                }
                Default {
                    Write-Host $result -ForegroundColor Red
                    Write-Host "I am uncertain whether this computer has been activated. Unexpected events have occurred, and the program is unable to handle them properly. Please call the program maintainer."  -ForegroundColor Red
                    return $false
                }
            }
        }
    }
    return $true
}

class Keys {
    [string]$FileName
    [string[]]$Lines
    [int]$index
    [bool]$getKeyByServer
    Keys([string]$FileName, [bool]$getKeyByServer) {
        $this.FileName = $FileName
        $this.Lines = (Get-Content -Path $FileName).Trim() -split "`n"
        $this.getKeyByServer = $getKeyByServer
    }
    [string] GetNextKey ([string]$userName, [string]$pd, [int]$index, [string]$osVersion, [string]$ComputerSN, [string]$result ) {
        if ($this.getKeyByServer) {
            $result = Get-KeyByServer -userName $userName -pd $pd -index $index -osVersion $osVersion -ComputerSN $ComputerSN    
            return $result
        }
        else {
            if ($index -ge 0) {
                $this.Lines[$index] = $this.Lines[$index].Trim() + "`t`t" + $result.Trim() + "`t`t" + $ComputerSN
                $this.WriteKeyFile()
            }
            for ($ri = $index + 1; $ri -lt $this.Lines.Count; $ri = $ri + 1) {
                $line = $this.Lines[$ri]
                $fileds = $line -split "\s+"
                if ($fileds.Length -eq 2) {
                    return $ri.ToString() + "," + $fileds[0]
                }
            }
        }
        $this.WriteKeyFile()
        return "-2,"
    } 
    WriteKeyFile() {
        try {
            Set-Content -Path $this.FileName -Value ($this.Lines -Join "`n")
        }
        catch {
            Write-Host $this.Lines
        }
    }
}
function Get-KeyFileName {
    param(
        $osVersion
    )
    $KeysFileName = $HomeKeysFileName
    if ($osVersion.Contains("Pro")) {
        $KeysFileName = $ProKeysFileName
    }
    return $KeysFIleName
}


# Start-Activation
# $r = Get-KeyByFile -fileName $HomeKeysFileName


function Confirm-Continue {
    param (
        [string]$Message = "There may be issues that need to be addressed. Do you want to continue?",
        [string]$ForegroundColor = "Yellow"
    )
    $Message = $Message + " (Press 'yes' or 'y' to continue, any other key to cancel)."

    # 显示提示信息并读取用户输入
    Write-Host $Message -ForegroundColor $ForegroundColor 
    $userInput = Read-Host

    # 检查用户输入是否为 "yes" 或 "y"
    if ($userInput -eq "yes" -or $userInput -eq "y") {
        return $true
    }
    else {
        return $false
    }
}
