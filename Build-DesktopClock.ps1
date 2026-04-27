$ErrorActionPreference = 'Stop'

$root = "C:\Users\Emon Rahman\Documents\Tools"
$src  = Join-Path $root "DesktopClock.cs"
$out  = Join-Path $root "DesktopClock.exe"

Write-Host "=== Compiling DesktopClock.cs to native .exe ===" -ForegroundColor Cyan

# Find csc.exe (ships with .NET Framework, on every Windows machine)
$csc = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) {
    $csc = "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe"
}
if (-not (Test-Path $csc)) {
    Write-Host "csc.exe not found — .NET Framework 4.x required" -ForegroundColor Red
    pause; exit 1
}
Write-Host "  csc: $csc" -ForegroundColor Green

# Find WPF reference assemblies
$refDir = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\WPF"
$refs = @(
    "$refDir\PresentationCore.dll",
    "$refDir\PresentationFramework.dll",
    "$refDir\WindowsBase.dll",
    "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\System.Xaml.dll",
    "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\System.Windows.Forms.dll",
    "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\System.Drawing.dll"
)
$missingRefs = $refs | Where-Object { -not (Test-Path $_) }
if ($missingRefs) {
    Write-Host "Missing reference DLLs:" -ForegroundColor Red
    $missingRefs | ForEach-Object { Write-Host "  $_" }
    pause; exit 1
}

# Build args
$refArgs = $refs | ForEach-Object { "/reference:`"$_`"" }
$cscArgs = @(
    "/nologo",
    "/target:winexe",
    "/optimize+",
    "/platform:x64",
    "/debug-",
    "/out:`"$out`"",
    $refArgs,
    "`"$src`""
) -join ' '

Write-Host "Compiling..." -ForegroundColor Yellow
$result = cmd /c "`"$csc`" $cscArgs 2>&1"
Write-Host $result

if (Test-Path $out) {
    $sizeKB = [math]::Round((Get-Item $out).Length / 1024, 1)
    Write-Host ""
    Write-Host "BUILD OK" -ForegroundColor Green
    Write-Host "  Output: $out" -ForegroundColor Green
    Write-Host "  Size:   $sizeKB KB" -ForegroundColor Green
    Write-Host ""
    Write-Host "Run with:  $out"
} else {
    Write-Host "BUILD FAILED" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press a key to close"
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
