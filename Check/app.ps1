$cpuModel = (wmic cpu get name)[2]
$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$parentDirectory = Split-Path -Path $scriptDirectory -Parent
$configFilePath = $parentDirectory + "\check_config.ps1"

. $scriptDirectory\check.ps1
. $scriptDirectory\activate.ps1
. $scriptDirectory\update.ps1
. $scriptDirectory\utils.ps1
. $parentDirectory\check_config.ps1

if ($args[0] -eq "update") {
    Set-WiFi
    Start-Sleep -Seconds 2
    Get-LastVersion
    Exit
}

$osVersion = Get-WindowsVersion
$serialNumber = Get-PCSerialNumber
$model = Get-Model

Get-KeyByServer -userName $userName -osVersion  $osVersion -sn $serialNumber -model $model
Exit


Set-WiFi
Set-WinRecovery
Set-dynamicBrightness
$totalMemory = Get-Memory
$totalDisk = Get-DiskInfo
$totalPartitions = Get-PartitionInfo
$status = Get-DeviceInfo
$signalStrength = Get-SignalStrength
#Get-LastVersion
$r = Start-Activation
if ($r) {
    Remove-Wifi
}
slui.exe
#if ($r) {
#    Remove-Wifi
#    if (Confirm-Continue -Message "all things are done, do you want to shutdown this computer?") {
#        shutdown /p
#    }
#}



Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height

$form = New-Object System.Windows.Forms.Form
$form.Text = "Computer Check"
$form.TopMost = $true
$form.Size = New-Object System.Drawing.Size(600, 900)
$form.StartPosition = "Manual"  #   

$form.MinimizeBox = $false

$form.MaximizeBox = $false

#$form.ControlBox = $false




$windowWidth = $form.Width
$windowLeft = $screenWidth - $windowWidth

$form.Location = New-Object System.Drawing.Point($windowLeft, 0)
$formWidth = $form.Width
$formHeight = $form.Height
$panel = New-Object System.Windows.Forms.Panel
$panel.Size = New-Object System.Drawing.Size(600, 700)  # Panel 的大小
$panel.BackColor = [System.Drawing.Color]::LightGray  # Panel 的背景颜色

$columns = 2
$labelsPerColumn = 5

$panelWidth = $panel.ClientSize.Width
$panelHeight = $panel.ClientSize.Height

$labelWidth = $panelWidth / $columns
$labelHeight = $panelHeight / $labelsPerColumn
$osv = ""

if ($osVersion.Contains("Pro")) {
    $osv = " Pro  "
}
if ($osVersion.Contains("Home")) {
    $osv = " Home "
}

$labelTexts = @(
    "Memory", $totalMemory,
    "Disk", $totalDisk,
    " OS  ", $osv,
    "Serial", $serialNumber,
    "Signal", $signalStrength
)

$labelCount = $labelTexts.Length

$rowsNeeded = [math]::Ceiling($labelCount / $columns)

for ($row = 0; $row -lt $rowsNeeded; $row++) {
    for ($col = 0; $col -lt $columns; $col++) {
        $index = $row * $columns + $col
        if ($index -ge $labelCount) {
            break  # 如果索引超出 labelTexts 的长度，跳出循环
        }

        $label = New-Object System.Windows.Forms.Label
        $label.AutoSize = $false  

        $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter  
        $label.BackColor = [System.Drawing.Color]::LightGray  
        $label.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle  

        $label.Location = New-Object System.Drawing.Point(
            [int]($col * $labelWidth), 
            [int]($row * $labelHeight) 
        )
        $label.Size = New-Object System.Drawing.Size(
            [int]$labelWidth, 
            [int]$labelHeight  
        )
        $label.Text = $labelTexts[$index]
        $label.Font = New-Object System.Drawing.Font("Arial", 14) 

        $label.Add_Paint({
                param($sender, $e)
                $graphics = $sender.CreateGraphics()

                $textLength = $sender.Text.Length

                $fontSize = [Math]::Min(
                    [int] ($sender.Width / $textLength), 
                    [int] ($sender.Height)
                )

                $sender.Font = New-Object System.Drawing.Font($sender.Font.FontFamily, $fontSize)

                $graphics.Dispose()
            })
        $panel.Controls.Add($label)
    }
}
$form.Controls.Add($panel)


$button = New-Object System.Windows.Forms.Button
$button.Text = "Colse Computer"
$button.Size = New-Object System.Drawing.Size(200, 50)
$button.Font = New-Object System.Drawing.Font("Arial", 14)

$button.Location = New-Object System.Drawing.Point(
    [int](($formWidth - $button.Width) / 2),
    [int]($panelHeight + ($formHeight - $panelHeight - $button.Height) / 2) 
)

$button.Add_Click({
        Stop-Computer -Force
    })

if ($r) {
    $form.Controls.Add($button)
}

$form.ShowDialog()