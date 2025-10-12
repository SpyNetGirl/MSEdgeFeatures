
$FullVersionToUse = "143.0.3614.0"

$Arguments = "--enable-features=msEdgeAutofillPurgeProfilesByTimeline,msEdgeAutofillStopLoadingLowDataProfiles,msEdgeToolsSkipBalancedDomainsInBloomFilter,msWhatsNewPageSeen,msWhatsNewPageSeenChromePB50,msWhatsNewPageSeenChromePB60,msWhatsNewPageSeenChromePB70,msWhatsNewPageSeenChromePB80,msWhatsNewPageSeenChromePB90,msWhatsNewPageSeenCopilotModeEligible,msWhatsNewPageSeenEdgePB,msWhatsNewPageSeenFromHidden,msWhatsNewPageSeenNonEdgePB,msWhatsNewPageSeenNotNtpFeedEngaged,msWhatsNewPageSeenNtpFeedEngaged,msWhatsNewPageSeenOnLaunch,msWhatsNewPageSeenSourceChromePBOptimizations,msWhatsNewPageSeenSourceEdgePBOptimizations,msWhatsNewPageSeenSourceNonEdgePBOptimizations,msWhatsNewPageSeenSourceOptimizations,msWhatsNewPageSeenUnknownNtpFeedEngaged"

$content = @"
powershell.exe -WindowStyle hidden -Command "`$UserSID = [System.Security.Principal.WindowsIdentity]::GetCurrent().user.value;`$UserName = (Get-LocalUser | where-object -FilterScript {`$_.SID -eq `$UserSID}).name;Get-Process | where-object -FilterScript {`$_.path -eq \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`"} | ForEach-Object -Process {Stop-Process -Id `$_.id -Force -ErrorAction SilentlyContinue};& \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`" $Arguments"
"@

$content | Out-File -FilePath "C:\Users\$env:USERNAME\Downloads\EDGECAN Launcher $FullVersionToUse.bat"
