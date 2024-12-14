function AutoUpdate {
    # GitHub 仓库信息
    $owner = "niubaoshu"  # 替换为仓库的所有者（用户名或组织名）
    $repo = "checkpc"    # 替换为仓库的名称

    # GitHub API URL
    $apiUrl = "https://api.github.com/repos/$owner/$repo/releases/latest"

    $updated = $false
    # 获取最新发布信息
    try {
        $releaseInfo = Invoke-RestMethod -Uri $apiUrl -Method Get

        # 提取最新版本号
        $latestVersion = $releaseInfo.tag_name

        $outputPath = $parentDirectory + "\checkpc_${latestVersion}.zip"
        $extractPath = $parentDirectory + "\checkpc_${latestVersion}"
        Write-Host $latestVersion $Version
        if ($latestVersion -ne $Version) {
            #Invoke-WebRequest -Uri $releaseInfo.assets[0].browser_download_url -OutFile $outputPath
            Invoke-WebRequest -Uri $releaseInfo.zipball_url -OutFile $outputPath
            if (Test-Path -Path $outputPath) {
                Expand-Archive -Path $outputPath -DestinationPath $extractPath
                $folders = Get-ChildItem -Path $extractPath -Directory

                $sourceFolder = $extractPath + "\" + $folders[0].Name + "\Check"
                $destinationFolder = $parentDirectory   
                Write-Host $sourceFolder $destinationFolder
                Copy-Item -Path $sourceFolder -Destination $destinationFolder -Recurse -Force
            }
            Remove-Item -Path $outputPath
            Remove-Item -Path $extractPath -Recurse
            if (Test-Path $configFilePath) {
                $fileContent = Get-Content -Path $configFilePath
                $fileContent[-1] = "`$Version = `"" + $latestVersion + "`""
                Set-Content -Path $configFilePath -Value $fileContent
                $updated = $true
            }
        }
    }
    catch {
        Write-Host "something wrong,$_"
        Exit
    }
    if ($updated) {
        Write-Host "update success,$Version -> $latestVersion,please restart this program"
        Exit
    }
}