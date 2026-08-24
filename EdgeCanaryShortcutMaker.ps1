
$FullVersionToUse = "154.0.4236.0"

$Arguments = "--enable-features=msEdgeDevToolsOpenVSCode,msEdgeDevToolsSymbolServerExtension,msEdgeDevToolsUncaughtException,msEdgePdfShellPreviewBtr,msEdgePdfViewerBtrInPrintPreview,msEnableScrollAnimation,msIdlePauseSeconds,msMediaControlBadgeUpsellAnyBadgeShownDurationInDays,msMediaControlBadgeUpsellBrowserUsageFetchDurationInDays,msMediaControlBadgeUpsellControlVersion,msMediaControlBadgeUpsellExecutionCadenceSeconds,msMediaControlBadgeUpsellFreshnessInMinutes,msMediaControlBadgeUpsellHistoryFetchDurationInDays,msMediaControlBadgeUpsellInitialExecutionDelaySeconds,msMediaControlBadgeUpsellMinChromeUsageMB,msMediaControlBadgeUpsellMinChromeUsagePercentage,msMediaControlBadgeUpsellMinDaysSinceFre,msMediaControlBadgeUpsellMinTargetSiteVisits,msMediaControlBadgeUpsellModelVersion,msMediaControlBadgeUpsellNotificationExpireDurationInDays,msPauseAnimationInEfficiencyMode,msQuickSearchInCopilot,msQuickSearchShowSearchLabelInCommandBar,msReadAloudReliabilityImprovements,msRewardsMediaControlBadgeUpsellHVAWebUI,msRewardsMediaControlBadgeUpsellHVAWebUIForTesting,msRotateOnlyInLastActiveWindow,msScrollAnimationDurationMs,msSegmentationPlatformMediaControlBadgeUpsellFeature,msSegmentationPlatformMediaControlBadgeUpsellLaunchNotification,msWebOOUIInChildFrame,msWhatsNewPageNurturingUI"

$content = @"
powershell.exe -WindowStyle hidden -Command "`$UserSID = [System.Security.Principal.WindowsIdentity]::GetCurrent().user.value;`$UserName = (Get-LocalUser | where-object -FilterScript {`$_.SID -eq `$UserSID}).name;Get-Process | where-object -FilterScript {`$_.path -eq \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`"} | ForEach-Object -Process {Stop-Process -Id `$_.id -Force -ErrorAction SilentlyContinue};& \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`" $Arguments"
"@

$content | Out-File -FilePath "C:\Users\$env:USERNAME\Downloads\EDGECAN Launcher $FullVersionToUse.bat"
