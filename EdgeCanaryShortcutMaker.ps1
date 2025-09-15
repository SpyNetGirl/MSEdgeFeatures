
$FullVersionToUse = "142.0.3558.0"

$Arguments = "--enable-features=msDesktopModeVisualSearch,msEdgeSettingsEnterpriseEdgePreview,msEdgeShoppingCopilotFlyoutSelfhostExperience,msEdgeShoppingSkipArbitratorForCopilotFlyoutForTesting,msImproveDefaultBrowser2ClickUxExperience,msShoppingUapiExp26,msShoppingUapiExp26Failure,msShoppingUapiExp26Success,msShoppingUapiExp27,msShoppingUapiExp27Failure,msShoppingUapiExp27Success,msShoppingUapiExp29,msShoppingUapiExp29Failure,msShoppingUapiExp29Success,msShoppingUapiExp44,msShoppingUapiExp44Failure,msShoppingUapiExp44Success,msShoppingUapiExp48,msShoppingUapiExp48Failure,msShoppingUapiExp48Success,msShoppingUapiExp49,msShoppingUapiExp49Failure,msShoppingUapiExp49Success"

$content = @"
powershell.exe -WindowStyle hidden -Command "`$UserSID = [System.Security.Principal.WindowsIdentity]::GetCurrent().user.value;`$UserName = (Get-LocalUser | where-object -FilterScript {`$_.SID -eq `$UserSID}).name;Get-Process | where-object -FilterScript {`$_.path -eq \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`"} | ForEach-Object -Process {Stop-Process -Id `$_.id -Force -ErrorAction SilentlyContinue};& \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`" $Arguments"
"@

$content | Out-File -FilePath "C:\Users\$env:USERNAME\Downloads\EDGECAN Launcher $FullVersionToUse.bat"
