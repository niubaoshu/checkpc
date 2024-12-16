$cpuModel = (wmic cpu get name)[2]
$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$parentDirectory = Split-Path -Path $scriptDirectory -Parent
$configFilePath = $parentDirectory + "\check_config.ps1"

. $scriptDirectory\check.ps1
. $scriptDirectory\activate.ps1
. $scriptDirectory\update.ps1
. $parentDirectory\check_config.ps1

if ($args[0] -eq "update") {
    Set-WiFi
    Start-Sleep -Seconds 2
    Get-LastVersion
    Exit
}

Set-WiFi
Set-WinRecovery
Set-dynamicBrightness
$model = Get-Model
$osVersion = Get-WindowsVersion
$serialNumber = Get-PCSerialNumber
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



# 加载 System.Windows.Forms 和 System.Drawing 命名空间
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 获取屏幕的宽度和高度
$screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height

# 创建一个新的窗体
$form = New-Object System.Windows.Forms.Form
$form.Text = "Computer Check"
$form.TopMost = $true
$form.Size = New-Object System.Drawing.Size(700, 1000)
$form.StartPosition = "Manual"  #   
# 禁用最小化按钮
$form.MinimizeBox = $false

# 禁用最大化按钮
$form.MaximizeBox = $false

# 禁用关闭按钮
#$form.ControlBox = $false




# 计算窗口的左侧位置（屏幕宽度 - 窗口宽度）
$windowWidth = $form.Width
$windowLeft = $screenWidth - $windowWidth

# 设置窗口的位置
$form.Location = New-Object System.Drawing.Point($windowLeft, 0)
$formWidth = $form.Width
$formHeight = $form.Height
# 创建一个 Panel 对象
$panel = New-Object System.Windows.Forms.Panel
$panel.Size = New-Object System.Drawing.Size(700, 900)  # Panel 的大小
$panel.BackColor = [System.Drawing.Color]::LightGray  # Panel 的背景颜色

# 定义列数和每列的标签数量
$columns = 2
$labelsPerColumn = 8

# 获取窗体的宽度和高度
$panelWidth = $panel.ClientSize.Width
$panelHeight = $panel.ClientSize.Height

# 计算每个标签的宽度和高度
$labelWidth = $panelWidth / $columns
$labelHeight = $panelHeight / $labelsPerColumn

# 定义 labelTexts 数组
$labelTexts = @(
    "Memory", $totalMemory,
    "Disk", $totalDisk,
    "Partition", $totalPartitions,
    "CPU", $cpuModel,
    "Model", $model,
    "OS", $osVersion,
    "Serial", $serialNumber,
    "Signal", $signalStrength
)

# 获取 labelTexts 的长度
$labelCount = $labelTexts.Length

# 动态调整标签数量
$rowsNeeded = [math]::Ceiling($labelCount / $columns)

# 创建标签并添加到窗体
for ($row = 0; $row -lt $rowsNeeded; $row++) {
    for ($col = 0; $col -lt $columns; $col++) {
        $index = $row * $columns + $col
        if ($index -ge $labelCount) {
            break  # 如果索引超出 labelTexts 的长度，跳出循环
        }

        $label = New-Object System.Windows.Forms.Label
        $label.AutoSize = $false  # 禁用自动调整大小

        $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter  # 文本居中
        $label.BackColor = [System.Drawing.Color]::LightGray  # 背景颜色
        $label.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle  # 添加边框

        # 设置标签的位置和大小
        $label.Location = New-Object System.Drawing.Point(
            [int]($col * $labelWidth), # 确保是数值类型
            [int]($row * $labelHeight) # 确保是数值类型
        )
        $label.Size = New-Object System.Drawing.Size(
            [int]$labelWidth, # 确保是数值类型
            [int]$labelHeight  # 确保是数值类型
        )
        $label.Text = $labelTexts[$index]
        $label.Font = New-Object System.Drawing.Font("Arial", 16) 

        $label.Add_Paint({
                param($sender, $e)
                $graphics = $sender.CreateGraphics()

                # 计算文本的字符长度
                $textLength = $sender.Text.Length

                # 计算合适的字体大小
                $fontSize = [Math]::Min(
                    $sender.Width / $textLength * 1.5, # 根据宽度计算字体大小
                    $sender.Height / 1.5                # 根据高度计算字体大小
                )

                # 设置新的字体大小
                $sender.Font = New-Object System.Drawing.Font($sender.Font.FontFamily, $fontSize)

                # 释放 Graphics 对象
                $graphics.Dispose()
            })
        $panel.Controls.Add($label)
    }
}
$form.Controls.Add($panel)


# 创建一个按钮，并将其放置在窗口的中央
$button = New-Object System.Windows.Forms.Button
$button.Text = "Colse Computer"
$button.Size = New-Object System.Drawing.Size(200, 50)
$button.Font = New-Object System.Drawing.Font("Arial", 14)

$button.Location = New-Object System.Drawing.Point(
    [int](($formWidth - $button.Width) / 2),
    [int]($panelHeight + ($formHeight - $panelHeight - $button.Height) / 2)# Y 坐标（垂直居中）
)
# 为按钮添加点击事件处理程序

$button.Add_Click({
        # 关闭计算机
        Stop-Computer -Force
    })

# 将按钮添加到窗体
if ($r) {
    $form.Controls.Add($button)
}
# 显示窗体
$form.ShowDialog()