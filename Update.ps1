$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
[System.Uri]$URL1 = 'https://go.microsoft.com/fwlink/?linkid=2084706&Channel=Canary&language=en'
[System.Uri]$URL2 = 'https://c2rsetup.edog.officeapps.live.com/c2r/downloadEdge.aspx?platform=Default&source=EdgeInsiderPage&Channel=Canary&language=en'
[System.String]$EdgeCanaryInstallerPath = "$env:tmp\MicrosoftEdgeSetupCanary.exe"
[System.String]$AppPath = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\Edge SxS\Application"
[System.String]$StringsExe = "$env:tmp\strings64.exe"

#Region Downloading-Stuff
Write-Host -Object 'Downloading Edge Canary'
try {
    Write-Host -Object 'Trying the primary URL'
    Invoke-RestMethod -Uri $URL1 -OutFile $EdgeCanaryInstallerPath | Out-Null
}
catch {
    try {
        Write-Host -Object 'Downloading from the primary URL failed, trying the secondary URL'
        Invoke-RestMethod -Uri $URL2 -OutFile $EdgeCanaryInstallerPath | Out-Null
    }
    catch {
        Write-Host -Object 'Failed to download Edge from both URLs. Exiting...'
        exit 1
    }
}

Write-Host -Object 'Downloading Strings64.exe'
try {
    Invoke-RestMethod -Uri 'https://live.sysinternals.com/strings64.exe' -OutFile $StringsExe | Out-Null
}
catch {
    Write-Host -Object 'Failed to download Strings64. Exiting...'
    exit 2
}
#EndRegion Downloading-Stuff

Write-Host -Object 'Installing Edge Canary'
Start-Process -FilePath $EdgeCanaryInstallerPath

Write-Host -Object 'Waiting for Edge Canary to be downloaded and installed' -ForegroundColor Green

# Checking for completion of the Edge Canary online installer by actively checking for the presence of the dll file that we need, every 5 seconds
# Setting a timer for 60 minutes
[System.TimeSpan]$Timer = New-TimeSpan -Minutes 60
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
do {
    [System.IO.FileInfo]$File = Get-ChildItem -Path $AppPath -Filter 'msedge.dll' -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($File) {
        Write-Host -Object "File found: $($File.FullName)"
        Start-Sleep -Seconds 5
        break
    }
    else {
        Write-Host -Object 'File not found. Waiting for 5 second...'
        Start-Sleep -Seconds 5
    }
}
# Breaking the loop if the timer expires
while ($StopWatch.Elapsed -lt $Timer)
$StopWatch.Stop()

Write-Host -Object "Accepting Strings64's EULA via Registry"

# Add the necessary registry key to accept the EULA of the Strings from SysInternals
[System.String]$RegistryPath = 'HKCU:\Software\Sysinternals\Strings'
[System.String]$Name = 'EulaAccepted'

if (Test-Path -Path $RegistryPath) {
    Set-ItemProperty -Path $RegistryPath -Name $Name -Value '1'
}
else {
    New-Item -Path $RegistryPath -Force | Out-Null
    New-ItemProperty -Path $RegistryPath -Name $Name -Value '1' -PropertyType 'DWORD' -Force | Out-Null
}

# Finding the latest version of the Edge Canary from its installation directory's name
Write-Host -Object 'Searching for the Edge Canary version that was just downloaded' -ForegroundColor Yellow
[System.String]$FullVersion = (Get-ChildItem -Path $AppPath -Directory | Where-Object -FilterScript { $_.Name -like '1*' } | Select-Object -First 1).Name
[System.Int32]$MajorVersion = $FullVersion.Split('.')[0]
[System.String]$DllPath = "$AppPath\$FullVersion\msedge.dll"
Write-Host -Object "DLL PATH: $DllPath" -ForegroundColor Yellow

# Expanding the current directory structure that is in GitHub repository to include the new Edge Canary version

# Create the root directory for the Edge Canary if it doesn't exist
if (-NOT (Test-Path -Path '.\Edge Canary')) { New-Item -Path '.\Edge Canary' -ItemType Directory -Force | Out-Null }

# Create the directory for the current Edge Canary's major version if it doesn't exist
if (-NOT (Test-Path -Path ".\Edge Canary\$MajorVersion")) { New-Item -Path ".\Edge Canary\$MajorVersion" -ItemType Directory -Force | Out-Null }

# Create the directory for the current Edge Canary's full version if it doesn't exist or if it exists but is empty
if (-NOT (Test-Path -Path ".\Edge Canary\$MajorVersion\$FullVersion\*")) {

    # Creating a new directory for the new available Edge Canary's full version
    New-Item -Path ".\Edge Canary\$MajorVersion\$FullVersion" -ItemType Directory -Force | Out-Null

    # Check whether the current Edge Canary version is the first release in a new major version. If it is, then some actions will be triggered
    if ((Get-ChildItem -Path ".\Edge Canary\$MajorVersion" -Directory).count -eq 1) {

        # Loop through each directory of major Edge canary versions and get the directory that belongs to the last previous version
        foreach ($CurrentPipelineVersion in ((Get-ChildItem -Path '.\Edge Canary\' -Directory | Where-Object -FilterScript { $_.Name -match '^\d\d\d$' } | Sort-Object -Property Name -Descending).Name | Select-Object -Skip 1)) {

            # Make sure the directory is not empty (which is kinda impossible to be empty, but just in case)
            if ((Get-ChildItem -Path ".\Edge Canary\$CurrentPipelineVersion" -Directory | Sort-Object -Property Name -Descending | Select-Object -First 1).count -ne 0) {

                # Locating the last major version of Edge Canary that was processed prior to this current major version so we can access its directory on repository
                [System.String]$PreviousFullVersion = (Get-ChildItem -Path ".\Edge Canary\$CurrentPipelineVersion" -Directory | Sort-Object -Property Name -Descending | Select-Object -First 1).Name
                # Get the major version
                [System.Int32]$PreviousMajorVersion = $PreviousFullVersion.Split('.')[0]
                # if the directory is found, stop the loop
                break
            }
            else {
                # if the directory that belongs to the previous major Edge canary version is completely empty, then skip the currently processing major version entirely and look for the one before it
                continue
            }
        }
    }
    # if the current Edge canary version is not the first release in a major version
    else {
        [System.String]$PreviousFullVersion = (Get-ChildItem -Path ".\Edge Canary\$MajorVersion" -Directory | Sort-Object -Descending | Select-Object -Skip 1 -First 1).Name
        [System.Int64]$PreviousMajorVersion = $PreviousFullVersion.Split('.')[0]
    }

    Write-Host -Object "Comparing version: $FullVersion with version: $PreviousFullVersion" -ForegroundColor Cyan

    Write-Host -Object 'Strings64 Running...'

    # Storing the output of the Strings64 in an array of strings
    [System.String[]]$CurrentOriginalFeatures = & $StringsExe $DllPath |
    Select-String -Pattern '^(ms[a-zA-Z0-9]{4,})$' |
    ForEach-Object -Process { $_.Matches.Groups[0].Value } | Sort-Object

    # Outputting the object containing the final original results to a file
    $CurrentOriginalFeatures | Out-File -FilePath ".\Edge Canary\$MajorVersion\$FullVersion\original.txt" -Force

    Write-Host -Object "Saved: .\Edge Canary\$MajorVersion\$FullVersion\original.txt ($($CurrentOriginalFeatures.count) entries)"

    [System.String[]]$PreviousOriginalFeatures = Get-Content -Path ".\Edge Canary\$PreviousMajorVersion\$PreviousFullVersion\original.txt" | Sort-Object

    [System.String[]]$Added = $CurrentOriginalFeatures | Where-Object -FilterScript { $_ -notin $PreviousOriginalFeatures }
    $Added | Out-File -FilePath ".\Edge Canary\$MajorVersion\$FullVersion\added.txt" -Force

    [System.String[]]$Removed = $PreviousOriginalFeatures | Where-Object -FilterScript { $_ -notin $CurrentOriginalFeatures }
    $Removed | Out-File -FilePath ".\Edge Canary\$MajorVersion\$FullVersion\removed.txt" -Force

    Write-Host -Object "Added features .\Edge Canary\$MajorVersion\$FullVersion\added.txt ($($Added.count) entries)"
    Write-Host -Object "Removed features .\Edge Canary\$MajorVersion\$FullVersion\removed.txt ($($Removed.count) entries)"

    # Storing the latest version in a file
    $FullVersion | Out-File -FilePath .\last.txt -Force

    #region ReadMe-Updater
    [System.String]$DetailsToReplace = @"
`n### <a href="https://github.com/HotCakeX/MSEdgeFeatures"><img width="35" src="https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/WebP/Edge%20Canary.webp"></a> Latest Edge Canary version: $FullVersion`n
### Last processed at: $(Get-Date -AsUTC) (UTC+00:00)`n
<details>
<summary>$($Added.count) new features were added in the latest Edge Canary update</summary>

<br>

$($Added | ForEach-Object -Process {"* $_`n"})
</details>`n
"@

    # Showing extra details on the Readme page of the repository about the latest Edge Canary version
    [System.String]$Readme = Get-Content -Raw -Path 'README.md' -Force
    $Readme = $Readme -replace '(?s)(?<=<!-- Edge-Canary-Version:START -->).*(?=<!-- Edge-Canary-Version:END -->)', $DetailsToReplace
    Set-Content -Path 'README.md' -Value $Readme.TrimEnd() -Force
    #endregion ReadMe-Updater

    #region GitHub-Committing

    # Committing the changes back to the repository
    git config --global user.email 'spynetgirl@outlook.com'
    git config --global user.name 'HotCakeX'
    git add --all
    git commit -m 'Automated Update'
    git push

    #endregion GitHub-Committing


    #region Edge-Canary-ShortCut-Maker-Code

    # Putting the Edge canary shortcut maker's code in the EdgeCanaryShortcutMaker.ps1 file

    New-Item -Path '.\EdgeCanaryShortcutMaker.ps1' -Force | Out-Null

    [System.String[]]$AddedArray = $Added -join ','
    $PreArguments = "--enable-features=$AddedArray"
    $PreArguments = $PreArguments.TrimEnd(',')
    # Content to add the PowerShell script that creates the bat script that launches Edge with new features
    [System.String]$ContentToAdd = @"

`$FullVersionToUse = `"$FullVersion`"

`$Arguments = `"$PreArguments`"

`$content = @`"
powershell.exe -WindowStyle hidden -Command "```$UserSID = [System.Security.Principal.WindowsIdentity]::GetCurrent().user.value;```$UserName = (Get-LocalUser | where-object -FilterScript {```$_.SID -eq ```$UserSID}).name;Get-Process | where-object -FilterScript {```$_.path -eq "\"C:\Users\```$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\""} | ForEach-Object -Process {Stop-Process -Id ```$_.id -Force -ErrorAction SilentlyContinue};& \"C:\Users\```$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\" `$Arguments"
`"@

`$content | Out-File -FilePath "C:\Users\`$env:USERNAME\Downloads\EDGECAN Launcher `$FullVersionToUse.bat"

"@

    Set-Content -Value $ContentToAdd -Path '.\EdgeCanaryShortcutMaker.ps1' -Force


    #endregion Edge-Canary-ShortCut-Maker-Code

    #region GitHub-Release-Publishing

    # Publishing the Release without Body of the Release (i.e. text)

    # Doing this first so that people watching the repository will see this in the Emails that they get
    # But won't see the PowerShell link because it will be added to the Release body using the Patch method, after this
    # Without this, the email would have empty content for the body of the Release

    [System.String]$GitHubReleaseBodyContent = @"

# <img width="35" src="https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/WebP/Edge%20Canary.webp"> Automated update

## Processed at: $(Get-Date -AsUTC) (UTC+00:00)`n

Visit the GitHub's release section for full details on how to use it:
https://github.com/HotCakeX/MSEdgeFeatures/releases/tag/$FullVersion

### $($Added.count) New features were added

$($Added | ForEach-Object -Process {"* $_`n"})

<br>

### $($Removed.count) Features were removed

$($Removed | ForEach-Object -Process {"* $_`n"})

<br>

"@

    # Get the latest commit SHA
    $LATEST_SHA = git rev-parse HEAD
    # Create a release with the latest commit as tag and target
    $RELEASE_RESPONSE = Invoke-RestMethod -Uri 'https://api.github.com/repos/HotCakeX/MSEdgeFeatures/releases' `
        -Method POST `
        -Headers @{Authorization = "token $env:GITHUB_TOKEN" } `
        -Body (
        @{
            tag_name         = "$FullVersion"
            target_commitish = $LATEST_SHA
            name             = "Edge Canary version $FullVersion"
            body             = "$GitHubReleaseBodyContent"
            draft            = $false
            prerelease       = $false
        } | ConvertTo-Json
    )

    # Use the gh CLI command to upload the EdgeCanaryShortcutMaker.ps1 file to the release as asset
    gh release upload $FullVersion ./EdgeCanaryShortcutMaker.ps1 --clobber

    [System.String]$ASSET_NAME = 'EdgeCanaryShortcutMaker.ps1'

    # Making sure the download link is direct
    [System.String]$ASSET_DOWNLOAD_URL = "https://github.com/HotCakeX/MSEdgeFeatures/releases/download/$FullVersion/$ASSET_NAME"


    # Body of the Release that is going to be added via a patch method
    [System.String]$GitHubReleaseBodyContent = @"

# <img width="35" src="https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/WebP/Edge%20Canary.webp"> Automated update

## Processed at: $(Get-Date -AsUTC) (UTC+00:00)`n

### $($Added.count) New features were added

$($Added | ForEach-Object -Process {"* $_`n"})

<br>

### $($Removed.count) Features were removed

$($Removed | ForEach-Object -Process {"* $_`n"})

<br>

### How to use the new features in this Edge canary update

1. First make sure your Edge canary is up to date

2. Copy and paste the code below in your PowerShell. NO admin privileges required. An Edge canary `.bat` file will be created in your Downloads folder. Double-click/tap on it to launch Edge canary with the features added in this update.

<br>

``````powershell
invoke-restMethod '$ASSET_DOWNLOAD_URL' | Invoke-Expression
``````

"@

    # Add the body of the Release with the link to the EdgeCanaryShortcutMaker.ps1 asset file included
    Invoke-RestMethod -Uri "https://api.github.com/repos/HotCakeX/MSEdgeFeatures/releases/$($RELEASE_RESPONSE.id)" -Method Patch -Headers @{Authorization = "token $env:GITHUB_TOKEN" } -Body (@{body = "$GitHubReleaseBodyContent" } | ConvertTo-Json) -ContentType 'application/json'

    #endregion GitHub-Release-Publishing

}
else {
    Write-Host -Object 'BUILD ALREADY EXISTS, EXITING.' -ForegroundColor Red
    exit 0
}
