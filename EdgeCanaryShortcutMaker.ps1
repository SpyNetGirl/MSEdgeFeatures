
$FullVersionToUse = "148.0.3964.0"

$Arguments = "--enable-features=msEdgeToolsAutoScrollProgrammatic,msM365LinkInsightsFooterShowCount,msM365LinkInsightsMinPageWidthPixels,msM365LinkInsightsQuickDismissMaxCount,msM365LinkInsightsQuickDismissThresholdSec,msWebView2EnableMinimalWindow"

$content = @"
powershell.exe -WindowStyle hidden -Command "`$UserSID = [System.Security.Principal.WindowsIdentity]::GetCurrent().user.value;`$UserName = (Get-LocalUser | where-object -FilterScript {`$_.SID -eq `$UserSID}).name;Get-Process | where-object -FilterScript {`$_.path -eq \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`"} | ForEach-Object -Process {Stop-Process -Id `$_.id -Force -ErrorAction SilentlyContinue};& \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`" $Arguments"
"@

$content | Out-File -FilePath "C:\Users\$env:USERNAME\Downloads\EDGECAN Launcher $FullVersionToUse.bat"
