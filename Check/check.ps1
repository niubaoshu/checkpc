function Get-Memory {   
    # 使用 Get-WmiObject 获取内存插槽信息
    $memorySlots = Get-WmiObject -Class Win32_PhysicalMemory

    # 遍历每个内存插槽并输出其信息
    foreach ($slot in $memorySlots) {
        $slotLocation = $slot.DeviceLocator
        $slotCapacityGB = [math]::Round($slot.Capacity / 1GB, 2)
        $slotSpeed = $slot.Speed
        $slotManufacturer = $slot.Manufacturer
        Write-Host "memery Solt : $slotLocation,`t Capacity $slotCapacityGB GB,`tSpeed $slotSpeed MHz,`tManufacturer $slotManufacturer;"  -ForegroundColor Green
    }
}
function Get-DiskInfo {
    # 使用 Get-CimInstance 获取磁盘分区信息
    $partitions = Get-CimInstance -ClassName Win32_LogicalDisk

    # 遍历每个分区并输出其大小
    foreach ($partition in $partitions) {
        $partitionName = $partition.DeviceID
        $partitionSizeGB = [math]::Round($partition.Size / 1GB, 2)
        $freeSpaceGB = [math]::Round($partition.FreeSpace / 1GB, 2)
        $usedSpaceGB = $partitionSizeGB - $freeSpaceGB

        Write-Host "Partition: $partitionName`tSize $partitionSizeGB GB,`tUsedSpace $usedSpaceGB GB,`tFreeSpace $freeSpaceGB GB;"  -ForegroundColor Green
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
        Confirm-Continue
        Get-DeviceInfo
    }
    else {
        Write-Host "We have identified $length normal devices and $devicesNotOKCount abnormal devices."
    }
}

function Set-WiFi {
    # 定义Wi-Fi网络的名称和密码

    # 使用netsh命令连接到Wi-Fi网络
    $WIFIprofile = $scriptDirectory + "\top_prime_inc_profile.xml" 
    netsh wlan add profile filename=$WIFIprofile interface="Wi-Fi"
    netsh wlan connect name=$ssid ssid=$ssid interface="Wi-Fi"

    # 删除临时配置文件
    # Remove-Item "top_prime_inc_profile.xml"
}

function Get-WindowsVersion {
    $osVersion = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" 
    Write-Host "Os Display version:", $osVersion.DisplayVersion
    $Caption = Get-WmiObject -Class Win32_OperatingSystem
    Write-Host "Os version:", $Caption.Caption
}

function Get-PCSerialNumber {
    $bios = Get-WmiObject -Class Win32_BIOS
    Write-Host "SN:", $bios.SerialNumber
    Write-Host "BIOS Version:", $bios.SMBIOSBIOSVersion
}

function Get-CPUVersion {

    # 输出 CPU 型号和型号名称
    Write-Host "CPU:", $cpuModel
}

function Get-Model {
    # 获取笔记本电脑的型号
    $computerSystem = Get-WmiObject -Class Win32_ComputerSystem

    Write-Host "model:", $computerSystem.Model
    
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

$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
. $scriptDirectory\activate.ps1
$parentDirectory = Split-Path -Path $scriptDirectory -Parent
. $parentDirectory\check_config.ps1
# 获取 CPU 型号和型号名称
$cpuModel = (wmic cpu get name)[2]

Set-WinRecovery
Set-WiFi
Set-dynamicBrightness
Get-CPUVersion
Get-Model
Get-WindowsVersion
Get-PCSerialNumber
Get-Memory
Get-DiskInfo
Get-DeviceInfo
$r = Start-Activation
slui.exe
if ($r) {
    Remove-Wifi
    if (Confirm-Continue -Message "all things are done, do you want to shutdown this computer?") {
        shutdown /p
    }
}