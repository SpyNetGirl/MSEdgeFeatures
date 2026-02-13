
$FullVersionToUse = "147.0.3858.0"

$Arguments = "--enable-features=MsWShG,msBingSearchStartedFromAddressBar,msBingSearchStartedFromBingRequery,msBingSearchStartedFromContextMenu,msBingSearchStartedFromNewTabPageSearchBox,msBingSearchStartedFromRenavigation,msBingSearchStartedFromWindowsSearch,msBingSerpNavigationStarted,msEdgeNativeVideoScrubbing,msEdgeSpaceworksPinning,msEdgeToolsSkipFRE,msEdgeToolsUseMouseWheelForScroll,msOmniboxRelatedSearchesOnZeroInputSerp,msSettingsCppDeprecated,msSkipUnloadedTabAsActive"

$content = @"
powershell.exe -WindowStyle hidden -Command "`$UserSID = [System.Security.Principal.WindowsIdentity]::GetCurrent().user.value;`$UserName = (Get-LocalUser | where-object -FilterScript {`$_.SID -eq `$UserSID}).name;Get-Process | where-object -FilterScript {`$_.path -eq \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`"} | ForEach-Object -Process {Stop-Process -Id `$_.id -Force -ErrorAction SilentlyContinue};& \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`" $Arguments"
"@

$content | Out-File -FilePath "C:\Users\$env:USERNAME\Downloads\EDGECAN Launcher $FullVersionToUse.bat"
