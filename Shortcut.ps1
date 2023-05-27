$Version = (Invoke-RestMethod -Uri "https://raw.githubusercontent.com/HotCakeX/MSEdgeFeatures/main/last.txt").Trim()
$split = $Version.split('.')
$Added = (Invoke-RestMethod -Uri "https://raw.githubusercontent.com/HotCakeX/MSEdgeFeatures/main/Edge%20Canary/$($split[0])/$Version/added.txt") -replace ("`n", ",")

$arguments = "--enable-features=$Added"
$arguments = $arguments.TrimEnd(',')
Write-Host "Args: $arguments"

function New-Shortcut {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Path,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Target,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Description,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$WorkingDirectory,
        [string]$Arguments,
        [string]$Icon
    )
    if (!(Test-Path $Path)) {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($Path)
        $Shortcut.TargetPath = $Target
        if (![string]::IsNullOrEmpty($Arguments)) { $Shortcut.Arguments = $Arguments }
        if (![string]::IsNullOrEmpty($Icon)) { $Shortcut.IconLocation = $Icon }
        $Shortcut.Description = $Description
        $Shortcut.WorkingDirectory = $WorkingDirectory
        $Shortcut.Save()
    }
}
if (Test-Path "C:\Users\$env:USERNAME\Downloads\EDGECAN.lnk") { Remove-Item "C:\Users\$env:USERNAME\Downloads\EDGECAN.lnk" }
New-Shortcut -Path "C:\Users\$env:USERNAME\Downloads\EDGECAN.lnk" `
    -Target "C:\Users\$env:USERNAME\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe" `
    -Description "Microsoft Edge" `
    -WorkingDirectory "C:\Users\$env:USERNAME\AppData\Local\Microsoft\Edge SxS\Application" `
    -Icon "C:\Users\$env:USERNAME\AppData\Local\Microsoft\Edge SxS\User Data\Default\Edge Profile.ico" `
    -Arguments $arguments
