$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
$URL1 = "https://go.microsoft.com/fwlink/?linkid=2084706&Channel=Canary&language=en"
$URL2 = "https://c2rsetup.edog.officeapps.live.com/c2r/downloadEdge.aspx?platform=Default&source=EdgeInsiderPage&Channel=Canary&language=en"
$Installer = "$env:tmp\MicrosoftEdgeSetupCanary.exe"
$AppPath = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\Edge SxS\Application"
$StringsExe = "$env:tmp\strings64.exe"

Write-Host "DOWNLOADING EDGE"
try {
    $null = Invoke-RestMethod -Uri $URL1 -OutFile $Installer
} catch {
    try {
        $null = Invoke-RestMethod -Uri $URL2 -OutFile $Installer
    } catch {
        Write-Host "Failed to download edge from both URLs. Exiting."
        exit
    }
}

Write-Host "DOWNLOADING STRINGS64"
try {
    $null = Invoke-RestMethod -Uri "https://live.sysinternals.com/strings64.exe" -OutFile $StringsExe
} catch {
    Write-Host "Failed to download strings64. Exiting."
    exit
}

Write-Host "INSTALLING EDGE"
Start-Process -FilePath $Installer

Write-Host "WAITING"
do {
    $file = Get-ChildItem -Path $AppPath -Filter "msedge.dll" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($file) {
        Write-Host "File found: $($file.FullName)"
        Start-Sleep 5
        break
    } else {
        Write-Host "File not found. Waiting 5 second..."
        Start-Sleep -Seconds 5
    }
}
while ($true)

Write-Host "ACCEPTEULA STRINGS REGISTRY"
$RegistryPath = "HKCU:\Software\Sysinternals\Strings"
$Name = "EulaAccepted"
$Value = 1
if (Test-Path $RegistryPath) {
    Set-ItemProperty -Path $RegistryPath -Name $Name -Value $Value
} else {
    New-Item -Path $RegistryPath -Force | Out-Null
    New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force | Out-Null
}

Write-Host "SEARCH VERSION"
$Version = (Get-ChildItem $AppPath -Directory | Where-Object { $_.Name -like '1*' } | Select-Object -First 1).Name
$split = $Version.Split('.')
$dllPath = "$AppPath\$Version\msedge.dll"
Write-Host "DLLPATH = $dllPath"

# structure
if (!(Test-Path ".\Edge Canary")) { $null = New-Item ".\Edge Canary" -ItemType Directory -Force }
if (!(Test-Path ".\Edge Canary\$($split[0])")) { $null = New-Item ".\Edge Canary\$($split[0])" -ItemType Directory -Force }
if (!(Test-Path ".\Edge Canary\$($split[0])\$Version")) {
    $null = New-Item ".\Edge Canary\$($split[0])\$Version" -ItemType Directory -Force
    Write-Host "EXECUTING STRINGS"
    $objs = & $StringsExe $dllPath |
    Select-String -Pattern '^(ms[a-zA-Z0-9]{4,})$' |
    ForEach-Object { $_.Matches.Groups[0].Value } | Sort-Object
    $objs | Out-File ".\Edge Canary\$($split[0])\$Version\original.txt"

    Write-Host "Saved = .\Edge Canary\$($split[0])\$Version\original.txt ($($objs.count) entries)"

    $PreviousVersion = (Get-ChildItem ".\Edge Canary\$($split[0])" -Directory | Where-Object { $_.Name -like '1*' } | Sort-Object Name -Descending | Select-Object -Skip 1 -First 1).Name

    # Check if there is a previous version and the original.txt for the previous version exists
    if ($PreviousVersion -and (Test-Path ".\Edge Canary\$($split[0])\$PreviousVersion\original.txt")) {
        $PreviousObjs = Get-Content ".\Edge Canary\$($split[0])\$PreviousVersion\original.txt" | Sort-Object

        $Added = $objs | Where-Object { $_ -notin $PreviousObjs }
        $Added | Out-File ".\Edge Canary\$($split[0])\$Version\added.txt"

        $Removed = $PreviousObjs | Where-Object { $_ -notin $objs }
        $Removed | Out-File ".\Edge Canary\$($split[0])\$Version\removed.txt"

        Write-Host "Added features .\Edge Canary\$($split[0])\$Version\added.txt ($($Added.count) entries)"
        Write-Host "Removed features .\Edge Canary\$($split[0])\$Version\removed.txt ($($Removed.count) entries)"
    } else {
        Write-Error "No previous version found."
    }
    $Version | Out-File .\last.txt
} else {
    Write-Host "BUILD ALREADY EXISTS, EXITING."
    Exit 0
}
