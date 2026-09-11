
$FullVersionToUse = "155.0.4272.0"

$Arguments = "--enable-features=msAutopilotComputerUse,msCopilotProtectedSession,msD2MSettingsEntry,msEdgeCopilotBridgeWorkerPriority,msEdgeIntentsAddressBarChipAfterFlyout,msEdgeIntentsCopilotFullPage,msEdgeOmniboxPinToTaskbar,msEdgeOptimizationGuideManifestBroker,msEdgeProfileIDClearStaleMUIDOnInitialGeneration,msEdgeSearchHistoryNavAwareAggressiveWindow,msEdgeToolsSuppressStopActionOnTabClose,msEmxAdaptiveRefreshInterval,msNurturingSplitViewPinnable,msNurturingSplitViewTabSwitchTutorial,msNurturingUndefinedFeaure,msSwapInOnResumeForAnyPriority"

$content = @"
powershell.exe -WindowStyle hidden -Command "`$UserSID = [System.Security.Principal.WindowsIdentity]::GetCurrent().user.value;`$UserName = (Get-LocalUser | where-object -FilterScript {`$_.SID -eq `$UserSID}).name;Get-Process | where-object -FilterScript {`$_.path -eq \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`"} | ForEach-Object -Process {Stop-Process -Id `$_.id -Force -ErrorAction SilentlyContinue};& \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`" $Arguments"
"@

$content | Out-File -FilePath "C:\Users\$env:USERNAME\Downloads\EDGECAN Launcher $FullVersionToUse.bat"
