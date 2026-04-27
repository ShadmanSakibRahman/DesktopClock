$ErrorActionPreference = 'Stop'

$appName    = "DesktopClock"
$appVersion = "1.0.0"
$publisher  = "Emon Rahman"

$installDir = Join-Path $env:LOCALAPPDATA $appName
$exeName    = "DesktopClock.exe"
$exeSource  = Join-Path $PSScriptRoot $exeName
if (-not (Test-Path $exeSource)) {
    $exeSource = Join-Path "C:\Users\Emon Rahman\Documents\Tools" $exeName
}
$exeDest    = Join-Path $installDir $exeName

Write-Host "=== Installing $appName ===" -ForegroundColor Cyan

if (-not (Test-Path $exeSource)) {
    [System.Windows.Forms.MessageBox]::Show("Cannot find $exeName next to installer or in Documents\Tools\.", "Install failed", "OK", "Error") | Out-Null
    exit 1
}

# Stop running instance if any
Get-Process DesktopClock -EA 0 | Stop-Process -Force
Start-Sleep -Milliseconds 500

# Create install dir
if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir -Force | Out-Null }

# Copy exe
Copy-Item -Path $exeSource -Destination $exeDest -Force
Write-Host "  Copied to $exeDest" -ForegroundColor Green

# Startup shortcut
$startup = [Environment]::GetFolderPath('Startup')
$lnk = Join-Path $startup "$appName.lnk"
$wshell = New-Object -ComObject WScript.Shell
$shortcut = $wshell.CreateShortcut($lnk)
$shortcut.TargetPath = $exeDest
$shortcut.WorkingDirectory = $installDir
$shortcut.Description = "Minimal iOS-style desktop clock"
$shortcut.Save()
Write-Host "  Auto-start enabled" -ForegroundColor Green

# Register in Apps and Features (HKCU - no admin needed)
$uninstKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$appName"
if (-not (Test-Path $uninstKey)) { New-Item -Path $uninstKey -Force | Out-Null }
$uninstaller = Join-Path $installDir "DesktopClock-Uninstall.exe"
$uninstallerPs1 = Join-Path "C:\Users\Emon Rahman\Documents\Tools" "DesktopClock-Uninstall.exe"
$useUninst = if (Test-Path $uninstallerPs1) { $uninstallerPs1 } else { $exeDest }

Set-ItemProperty -Path $uninstKey -Name "DisplayName"     -Value $appName
Set-ItemProperty -Path $uninstKey -Name "DisplayVersion"  -Value $appVersion
Set-ItemProperty -Path $uninstKey -Name "Publisher"       -Value $publisher
Set-ItemProperty -Path $uninstKey -Name "InstallLocation" -Value $installDir
Set-ItemProperty -Path $uninstKey -Name "DisplayIcon"     -Value $exeDest
Set-ItemProperty -Path $uninstKey -Name "UninstallString" -Value "`"$useUninst`""
Set-ItemProperty -Path $uninstKey -Name "NoModify"        -Value 1 -Type DWord
Set-ItemProperty -Path $uninstKey -Name "NoRepair"        -Value 1 -Type DWord
Write-Host "  Registered in Apps and Features" -ForegroundColor Green

# Launch the clock
Start-Process -FilePath $exeDest

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show(
    "$appName installed successfully.`n`nThe clock is now running.`nIt will auto-start on every login.`n`nUninstall via: Settings -> Apps -> Installed apps -> $appName.",
    "Install complete",
    "OK",
    "Information"
) | Out-Null
