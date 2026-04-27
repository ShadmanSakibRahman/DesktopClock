$ErrorActionPreference = 'Continue'

$appName = "DesktopClock"
$installDir = Join-Path $env:LOCALAPPDATA $appName

Add-Type -AssemblyName System.Windows.Forms

$confirm = [System.Windows.Forms.MessageBox]::Show(
    "Uninstall $appName?`n`nThis will remove the clock and stop it from auto-starting on login.",
    "Confirm uninstall",
    "YesNo",
    "Question"
)
if ($confirm -ne "Yes") { exit 0 }

# Stop running clock
Get-Process DesktopClock -EA 0 | Stop-Process -Force
Start-Sleep -Milliseconds 500

# Remove startup shortcut
$startup = [Environment]::GetFolderPath('Startup')
$lnk = Join-Path $startup "$appName.lnk"
if (Test-Path $lnk) { Remove-Item $lnk -Force }

# Remove from Apps and Features registry
Remove-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$appName" -Recurse -Force -EA 0

# Remove install dir (delayed via background process so this script can finish first)
$cleanupCmd = "Start-Sleep -Seconds 2; Remove-Item -Path '$installDir' -Recurse -Force -EA 0"
Start-Process powershell -ArgumentList "-NoProfile","-WindowStyle","Hidden","-Command",$cleanupCmd -WindowStyle Hidden

[System.Windows.Forms.MessageBox]::Show(
    "$appName uninstalled successfully.",
    "Uninstall complete",
    "OK",
    "Information"
) | Out-Null
