$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
$URL1 = "https://go.microsoft.com/fwlink/?linkid=2084706&Channel=Canary&language=en"
$URL2 = "https://c2rsetup.edog.officeapps.live.com/c2r/downloadEdge.aspx?platform=Default&source=EdgeInsiderPage&Channel=Canary&language=en"
$EdgeCanaryInstallerPath = "$env:tmp\MicrosoftEdgeSetupCanary.exe"
$AppPath = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\Edge SxS\Application"
$StringsExe = "$env:tmp\strings64.exe"

Write-Host "DOWNLOADING EDGE"
try {
    $null = Invoke-RestMethod -Uri $URL1 -OutFile $EdgeCanaryInstallerPath
}
catch {
    try {
        $null = Invoke-RestMethod -Uri $URL2 -OutFile $EdgeCanaryInstallerPath
    }
    catch {
        Write-Host "Failed to download edge from both URLs. Exiting."
        exit
    }
}

Write-Host "DOWNLOADING STRINGS64"
try {
    $null = Invoke-RestMethod -Uri "https://live.sysinternals.com/strings64.exe" -OutFile $StringsExe
}
catch {
    Write-Host "Failed to download strings64. Exiting."
    exit
}

Write-Host "INSTALLING EDGE"
Start-Process -FilePath $EdgeCanaryInstallerPath

Write-Host "WAITING"

# Checking for completion of the Edge Canary online installer by actively checking for the presence of the dll file that we need, every 5 seconds
do {
    $file = Get-ChildItem -Path $AppPath -Filter "msedge.dll" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($file) {
        Write-Host "File found: $($file.FullName)"
        Start-Sleep -Seconds 5
        break
    }
    else {
        Write-Host "File not found. Waiting 5 second..."
        Start-Sleep -Seconds 5
    }
}
while ($true)

Write-Host "ACCEPTEULA STRINGS REGISTRY"

# Add the necessary registry key to accept the EULA of the Strings from SysInternals
$RegistryPath = "HKCU:\Software\Sysinternals\Strings"
$Name = "EulaAccepted"
$Value = 1
if (Test-Path $RegistryPath) {
    Set-ItemProperty -Path $RegistryPath -Name $Name -Value $Value
}
else {
    New-Item -Path $RegistryPath -Force | Out-Null
    New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force | Out-Null
}

# Finding the latest version of the Edge Canary from its installation directory's name
Write-Host "SEARCH VERSION"
$Version = (Get-ChildItem $AppPath -Directory | Where-Object { $_.Name -like '1*' } | Select-Object -First 1).Name
$Split = $Version.Split('.')
$DllPath = "$AppPath\$Version\msedge.dll"
Write-Host "DLLPATH = $DllPath"

# Creating the directory structure that is in GitHub repository
if (!(Test-Path ".\Edge Canary")) { $null = New-Item ".\Edge Canary" -ItemType Directory -Force }
if (!(Test-Path ".\Edge Canary\$($Split[0])")) { $null = New-Item ".\Edge Canary\$($Split[0])" -ItemType Directory -Force }
if (!(Test-Path ".\Edge Canary\$($Split[0])\$Version")) {

    # Creating a new directory for the new available Edge Canary version
    $null = New-Item ".\Edge Canary\$($Split[0])\$Version" -ItemType Directory -Force

    Write-Host "EXECUTING STRINGS"

    # Storing the output of the Strings64 in an object
    $Objs = & $StringsExe $DllPath |
    Select-String -Pattern '^(ms[a-zA-Z0-9]{4,})$' |
    ForEach-Object { $_.Matches.Groups[0].Value } | Sort-Object

    # Outputting the object containing the final original results to a file
    $Objs | Out-File ".\Edge Canary\$($Split[0])\$Version\original.txt"

    Write-Host "Saved = .\Edge Canary\$($Split[0])\$Version\original.txt ($($Objs.count) entries)"

    # Check whether the current Edge Canary version is the first release in a new major version. If it is, then some actions will be triggered
    if ((Get-ChildItem ".\Edge Canary\$($Split[0])" -Directory).count -eq 1) {

        # Loop through each directory of major Edge canary versions and get the directory that belongs to the last previous version
        foreach ($CurrentPipelineVersion in ((Get-ChildItem ".\Edge Canary\" -Directory | Where-Object { $_ -match '\d\d\d' } | Sort-Object Name -Descending).Name | Select-Object -Skip 1)) {     

            # Make sure the directory is not empty (which is kinda impossible)
            if ((Get-ChildItem ".\Edge Canary\$CurrentPipelineVersion" -Directory | Sort-Object Name -Descending | Select-Object -First 1).count -ne 0) {
                               
                # Locating the last version of Edge Canary that was processed prior to this current version so we can access its directory on repository
                $PreviousVersion = (Get-ChildItem ".\Edge Canary\$CurrentPipelineVersion" -Directory | Sort-Object Name -Descending | Select-Object -First 1).Name
                # Get the major version
                $PreviousVersionSplit = $PreviousVersion.Split('.')
                # if the directory is found, stop the loop
                break     
            }
            else {
                # if the directory that belongs to the previous major Edge canary version is completely empty, then skip the currently processing major version entirely and look for the one before it
                continue
            }          
        }
    }

    Write-Host "Compared $version with $PreviousVersion"    

    $PreviousObjs = Get-Content ".\Edge Canary\$($PreviousVersionSplit[0])\$PreviousVersion\original.txt" | Sort-Object

    $Added = $Objs | Where-Object { $_ -notin $PreviousObjs }
    $Added | Out-File ".\Edge Canary\$($Split[0])\$Version\added.txt"

    $Removed = $PreviousObjs | Where-Object { $_ -notin $Objs }
    $Removed | Out-File ".\Edge Canary\$($Split[0])\$Version\removed.txt"

    Write-Host "Added features .\Edge Canary\$($Split[0])\$Version\added.txt ($($Added.count) entries)"
    Write-Host "Removed features .\Edge Canary\$($Split[0])\$Version\removed.txt ($($Removed.count) entries)"

    $Version | Out-File .\last.txt
}
else {
    Write-Host "BUILD ALREADY EXISTS, EXITING."
    Exit 0
}
