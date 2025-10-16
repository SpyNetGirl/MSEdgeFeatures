
$FullVersionToUse = "143.0.3621.0"

$Arguments = "--enable-features=msPeriodPressurePreReadFileTrigger,msSegmentationPlatformUrlInterestsCopilotModeUpsellFeature,msSkipSWUpdateOnDevtoolsDetachIfModified,msWhatsNewContentVisible,msWhatsNewContentVisibleChromePB50,msWhatsNewContentVisibleChromePB60,msWhatsNewContentVisibleChromePB70,msWhatsNewContentVisibleChromePB80,msWhatsNewContentVisibleChromePB90,msWhatsNewContentVisibleCopilotModeEligible,msWhatsNewContentVisibleEdgePB,msWhatsNewContentVisibleNonEdgePB,msWhatsNewContentVisibleNotNtpFeedEngaged,msWhatsNewContentVisibleNtpFeedEngaged,msWhatsNewContentVisibleSourceChromePBOptimizations,msWhatsNewContentVisibleSourceEdgePBOptimizations,msWhatsNewContentVisibleSourceNonEdgePBOptimizations,msWhatsNewContentVisibleSourceOptimizations,msWhatsNewContentVisibleUnknownNtpFeedEngaged,msWhatsNewUpdateCompleteVisible,msWhatsNewUpdateCompleteVisibleFromHidden,msWhatsNewUpdateCompleteVisibleOnLaunch"

$content = @"
powershell.exe -WindowStyle hidden -Command "`$UserSID = [System.Security.Principal.WindowsIdentity]::GetCurrent().user.value;`$UserName = (Get-LocalUser | where-object -FilterScript {`$_.SID -eq `$UserSID}).name;Get-Process | where-object -FilterScript {`$_.path -eq \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`"} | ForEach-Object -Process {Stop-Process -Id `$_.id -Force -ErrorAction SilentlyContinue};& \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`" $Arguments"
"@

$content | Out-File -FilePath "C:\Users\$env:USERNAME\Downloads\EDGECAN Launcher $FullVersionToUse.bat"
