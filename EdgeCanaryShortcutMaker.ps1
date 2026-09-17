
$FullVersionToUse = "155.0.4283.0"

$Arguments = "--enable-features=MsW59J,msEdgeAllowLegacyMV2Extensions,msEdgeExtensionManifestV2DeprecationWarning,msEdgeExtensionManifestV2Disabled,msEdgeExtensionManifestV2ExceptionList,msEdgeExtensionManifestV2Unsupported,msEdgeExtensionsManifestV3Only,msEdgeTranslateSettingsCard,msForceOneAuthWAM,msPdfMipProtectionHttpTransportRefactor"

$content = @"
powershell.exe -WindowStyle hidden -Command "`$UserSID = [System.Security.Principal.WindowsIdentity]::GetCurrent().user.value;`$UserName = (Get-LocalUser | where-object -FilterScript {`$_.SID -eq `$UserSID}).name;Get-Process | where-object -FilterScript {`$_.path -eq \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`"} | ForEach-Object -Process {Stop-Process -Id `$_.id -Force -ErrorAction SilentlyContinue};& \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`" $Arguments"
"@

$content | Out-File -FilePath "C:\Users\$env:USERNAME\Downloads\EDGECAN Launcher $FullVersionToUse.bat"
