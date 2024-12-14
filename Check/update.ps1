function AutoUpdate {
    $owner = "niubaoshu"  
    $repo = "checkpc"    

    # GitHub API URL
    $apiUrl = "https://api.github.com/repos/$owner/$repo/releases/latest"

    $updated = $false
    try {
        $releaseInfo = Invoke-RestMethod -Uri $apiUrl -Method Get
        $latestVersion = $releaseInfo.tag_name
        $outputPath = $parentDirectory + "\checkpc_${latestVersion}.zip"
        $extractPath = $parentDirectory + "\checkpc_${latestVersion}"
        if ($latestVersion -ne $Version) {
            Write-Host "current version: $Version,latest version: $latestVersion,updating ..." -ForegroundColor Yellow
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
        else {
            Write-Host "current version: $Version,latest version: $latestVersion" -ForegroundColor Green
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