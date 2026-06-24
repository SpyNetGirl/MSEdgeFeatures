
$FullVersionToUse = "151.0.4114.0"

$Arguments = "--enable-features=msR1ColorThemesSessionOneTrigger,msR1ColorThemesSessionThreeOnwardsTrigger,msR1ColorThemesSessionTwoTrigger,msR1ColorThemesSessionZeroTrigger,msSegmentationPlatformNetworkUsageCacheExecutionCadenceSeconds,msSegmentationPlatformNetworkUsageCacheFeature,msSegmentationPlatformNetworkUsageCacheInitialExecutionDelaySeconds,msSegmentationPlatformNetworkUsageCacheMaxBackfillPerFire,msSegmentationPlatformNetworkUsageCacheProcessList,msSegmentationPlatformNetworkUsageCacheSchemaVersion,msSegmentationPlatformNetworkUsageCacheWindowDays,msWebView2HostResourceAccessHardening"

$content = @"
powershell.exe -WindowStyle hidden -Command "`$UserSID = [System.Security.Principal.WindowsIdentity]::GetCurrent().user.value;`$UserName = (Get-LocalUser | where-object -FilterScript {`$_.SID -eq `$UserSID}).name;Get-Process | where-object -FilterScript {`$_.path -eq \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`"} | ForEach-Object -Process {Stop-Process -Id `$_.id -Force -ErrorAction SilentlyContinue};& \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`" $Arguments"
"@

$content | Out-File -FilePath "C:\Users\$env:USERNAME\Downloads\EDGECAN Launcher $FullVersionToUse.bat"
