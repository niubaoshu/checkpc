function Get-Memory {   
    # 使用 Get-WmiObject 获取内存插槽信息
    $memorySlots = Get-WmiObject -Class Win32_PhysicalMemory

    # 遍历每个内存插槽并输出其信息
    $id = 0
    $totalMemory = 0
    foreach ($slot in $memorySlots) {
        $totalMemory = $totalMemory + $slot.Capacity
        $slotCapacityGB = [math]::Round($slot.Capacity / 1GB, 2)
        $slotSpeed = $slot.Speed
        $slotManufacturer = $slot.Manufacturer
        Write-Host "memery${id}:`t Capacity $slotCapacityGB GB,`tSpeed $slotSpeed MHz,`tManufacturer $slotManufacturer;"  -ForegroundColor Green
        $id = $id + 1
    }
    return [math]::Round($totalMemory / 1GB, 0).ToString() + "GB"
}
function Get-PartitionInfo {
    # 使用 Get-CimInstance 获取磁盘分区信息
    $partitions = Get-CimInstance -ClassName Win32_LogicalDisk

    $totalPartitions = 0
    # 遍历每个分区并输出其大小
    foreach ($partition in $partitions) {
        if ($partition.DriveType -eq 3) {
            $totalPartitions = $totalPartitions + $partition.Size
        }
        $partitionName = $partition.DeviceID
        $partitionSizeGB = [math]::Round($partition.Size / 1GB, 2)
        $freeSpaceGB = [math]::Round($partition.FreeSpace / 1GB, 2)
        $usedSpaceGB = $partitionSizeGB - $freeSpaceGB

        Write-Host "Partition: $partitionName`tSize $partitionSizeGB GB,`tUsedSpace $usedSpaceGB GB,`tFreeSpace $freeSpaceGB GB;"  -ForegroundColor Green
    }
    return [math]::Round($totalPartitions / 1GB, 0).ToString() + "GB"
}
function Get-DiskInfo {
    $disks = Get-CimInstance -ClassName Win32_DiskDrive
    $id = 0
    $totalDisk = 0
    foreach ($disk in $disks) {
        if ($disk.MediaType -eq "Fixed hard disk media") {
            $totalDisk = $totalDisk + $disk.Size 
        }
        $sizeGB = [math]::Round($disk.Size / 1GB, 2)
        if ($disk.Status -eq "OK") {
            Write-Host "disk$($id): Total Size: $sizeGB GB,Disk mode: $($disk.Model),Interface Type: $($disk.InterfaceType)" -ForegroundColor Green
        }
        else {
            Write-Host "disk$($id): Total Size: $sizeGB GB,Disk mode: $($disk.Model),Interface Type: $($disk.InterfaceType)" -ForegroundColor Red
        }
        $id = $id + 1
    }
    return [math]::Round($totalDisk / 1GB, 0).ToString() + "GB"
}

function Get-Date2 {
    $cDate = Get-Date -Format "yyyy-MM-dd"
    if ($cDate -ne $currentDate) {
        if (Confirm-Continue -Message "Notify the maintainer of major problems with the program" -ForegroundColor "Red") {
            if (Test-Path $configFilePath) {
                $fileContent = Get-Content -Path $configFilePath
                if ($fileContent.Length -eq 0) {
                    return $false
                }
                $lastLine = $fileContent[-1]
                if ($lastLine -match "^\d{4}-\d{2}-\d{2}$") {
                    $fileContent[-1] = "`$currentDate = `"" + $currentDate + "`""
                    Set-Content -Path $configFilePath -Value $fileContent
                    return $true
                }
            }
        }
    }
}

function Get-DeviceInfo {
    # 使用 Get-CimInstance 获取设备驱动信息
    $devices = Get-CimInstance -ClassName Win32_PnPEntity

    # 遍历每个设备并输出其驱动状态
    $devicesNotOKCount = 0
    foreach ($device in $devices) {
        if ($device.Status -ne "OK") {
            Write-Host  $device -ForegroundColor Red
            $devicesNotOKCount = $devicesNotOKCount + 1
        }
    }
    $length = $devices.Count
    if ($devicesNotOKCount -gt 0) {
        C:\Windows\System32\devmgmt.msc
        Confirm-Continue
        Get-DeviceInfo
        reutrn $false
    }
    else {
        Write-Host "We have identified $length normal devices and $devicesNotOKCount abnormal devices." -ForegroundColor Green
        return $true
    }
}

function Set-WiFi {
    $wifiInfo = netsh wlan show interfaces
    $adapterName = ($wifiInfo | Select-String "Name" | ForEach-Object { $_ -replace ".*: ", "" }).Trim()


    # 定义Wi-Fi网络的名称和密码

    # 使用netsh命令连接到Wi-Fi网络
    $WIFIprofile = $parentDirectory + "\top_prime_inc_profile.xml" 
    netsh wlan add profile filename=$WIFIprofile interface=$adapterName
    netsh wlan connect name=$ssid ssid=$ssid interface=$adapterName

    # 删除临时配置文件
    # Remove-Item "top_prime_inc_profile.xml"
}

function Get-WindowsVersion {
    $osVersion = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" 
    Write-Host "Os Display version:", $osVersion.DisplayVersion
    $Caption = Get-WmiObject -Class Win32_OperatingSystem
    Write-Host "Os version:", $Caption.Caption
    return $Caption.Caption
}

function Get-PCSerialNumber {
    $bios = Get-WmiObject -Class Win32_BIOS
    Write-Host "SN:", $bios.SerialNumber
    return $bios.SerialNumber
}
function Get-BIOSVersion {
    $bios = Get-WmiObject -Class Win32_BIOS
    Write-Host "BIOS Version:", $bios.SMBIOSBIOSVersion
    return $bios.SMBIOSBIOSVersion
}

function Get-CPUVersion {

    # 输出 CPU 型号和型号名称
    Write-Host "CPU:", $cpuModel
}

function Get-Model {
    # 获取笔记本电脑的型号
    $computerSystem = Get-WmiObject -Class Win32_ComputerSystem

    Write-Host "model:", $computerSystem.Model
    return $computerSystem.Model
}

function Set-dynamicBrightness {
    if ($cpuModel.Contains("AMD")) {
        # Disable CABC
        $regFile = $scriptDirectory + "\Off_Change_brightness_based_on_content.reg"
        reg import $regFile
        # Changing brightness to 100
        $r = WMIC /NAMESPACE:\\root\wmi PATH WmiMonitorBrightnessMethods WHERE "Active=TRUE" CALL WmiSetBrightness Brightness=100 Timeout=0
        $r = $r -Join ""
        if ($r.Contains("Method execution successful.")) {
            Write-Host "Changing brightness to 100" -ForegroundColor Green
        }
    } 
}

function Disclaimer {
    if (Confirm-Continue -Message "all things are done, do you want to shutdown this computer?") {
        shutdown /p
    }
}

function Remove-Wifi {
    if ($removeWIFI) {
        netsh wlan delete profile name=*
    }
}

function Set-WinRecovery {
    # 检测 ReAgentC 状态
    $reagentcStatus = & reagentc /info

    # 检查状态是否为 "Enabled"
    if ($reagentcStatus -match "Windows RE status:\s+Disabled") {
        Write-Host "Windows Recovery is Disabled. Enabling it now..." -ForegroundColor Yellow
    
        # 启用 Windows RE
        & reagentc /enable
    
        # 再次检查状态
        $reagentcStatus = & reagentc /info
    
        if ($reagentcStatus -match "Windows RE status:\s+Enabled") {
            Write-Host "Windows Recovery has been successfully enabled." -ForegroundColor Green
        }
        else {
            Write-Host "Failed to enable Windows Recovery." -ForegroundColor Red
        }
    }
    else {
        Write-Host "Windows Recovery is already Enabled." -ForegroundColor Green
    }
    
}

function Get-SignalStrength {
    $wifiInfo = netsh wlan show interfaces

    $signalStrengthPercentage = ($wifiInfo | Select-String "Signal" | ForEach-Object { $_ -replace ".*: ", "" }).Trim()

    $connectionName = ($wifiInfo | Select-String "SSID" | ForEach-Object { $_ -replace ".*: ", "" }).Trim()

    $adapterName = ($wifiInfo | Select-String "Name" | ForEach-Object { $_ -replace ".*: ", "" }).Trim()

    if ($signalStrengthPercentage -le "50%") {
        Write-Host "Adapter Name: $adapterName,SSID: $connectionName, Signal Strength: $signalStrengthPercentage" -ForegroundColor Red
    }
    else {
        Write-Host "Adapter Name: $adapterName,SSID: $connectionName, Signal Strength: $signalStrengthPercentage" -ForegroundColor Green
    }
    return $signalStrengthPercentage
}