# Comprehensive Temp File Cleanup Script for Windows PowerShell 5.x

Write-Host "🧹 Starting system-wide temp cleanup..." -ForegroundColor Green
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow

# Define the cleanup function
function Remove-TempContent {
    param (
        [string]$Path,
        [string]$Description
    )
    if (Test-Path $Path) {
        Write-Host "➡️  Cleaning: $Description ($Path)" -ForegroundColor Cyan
        try {
            Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue |
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "   ✅ Cleaned successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "   ⚠️ Could not clean: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   ❌ Path not found: $Path" -ForegroundColor DarkGray
    }
}

# Initialize unique TEMP locations
$TempLocations = @{}

if ($env:TEMP -ne $env:TMP) {
    $TempLocations[$env:TEMP] = "User TEMP Folder"
    $TempLocations[$env:TMP] = "User TMP Folder"
} else {
    $TempLocations[$env:TEMP] = "User TEMP/TMP Folder"
}

# Add known cleanup targets
$TempLocations["$env:LOCALAPPDATA\Temp"] = "Local AppData Temp"
$TempLocations["C:\Windows\Temp"] = "Windows Temp"
$TempLocations["C:\Windows\Prefetch"] = "Windows Prefetch"
$TempLocations["C:\Windows\SoftwareDistribution\Download"] = "Windows Update Cache"
$TempLocations["C:\Windows\Logs"] = "Windows Logs"
$TempLocations["C:\Windows\System32\LogFiles"] = "System32 Logs"
$TempLocations["C:\ProgramData\Microsoft\Windows\WER"] = "Windows Error Reporting"
$TempLocations["C:\Windows\Installer\$PatchCache$"] = "Windows Installer Cache"
$TempLocations["$env:APPDATA\Microsoft\Windows\Recent"] = "Recent Documents"
$TempLocations["$env:LOCALAPPDATA\Microsoft\Windows\Explorer"] = "Thumbnail Cache"
$TempLocations["C:\ProgramData\Package Cache"] = "ProgramData Package Cache"
$TempLocations["C:\Windows\Panther"] = "Windows Panther"
$TempLocations["C:\Windows\Minidump"] = "Minidumps"
$TempLocations["C:\Windows\LiveKernelReports"] = "Live Kernel Reports"
$TempLocations["C:\ProgramData\Microsoft\Windows\AppRepository"] = "AppRepository Cache"
$TempLocations["C:\Windows\ServiceProfiles\LocalService\AppData\Local\Temp"] = "LocalService Temp"
$TempLocations["C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Temp"] = "NetworkService Temp"

# Clean standard locations
foreach ($entry in $TempLocations.GetEnumerator()) {
    Remove-TempContent -Path $entry.Key -Description $entry.Value
}

# Clean wildcard user directories
Write-Host "`n🧭 Cleaning wildcard user temp paths..." -ForegroundColor Magenta
$WildcardPaths = @(
    "C:\Users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files",
    "C:\Users\*\AppData\Local\Microsoft\Windows\INetCache",
    "C:\Users\*\AppData\Local\Temp"
)
foreach ($pattern in $WildcardPaths) {
    $root = ($pattern -split '\\\*')[0]
    if (Test-Path $root) {
        Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $expanded = $pattern -replace '\*', $_.Name
            Remove-TempContent -Path $expanded -Description "Wildcard: $expanded"
        }
    }
}

# Clean browser caches
Write-Host "`n🌐 Cleaning browser caches..." -ForegroundColor Magenta

# Chrome
$ChromePaths = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache"
)
foreach ($p in $ChromePaths) {
    Remove-TempContent -Path $p -Description "Chrome Cache"
}

# Firefox
$ffProfile = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if ($ffProfile) {
    Remove-TempContent -Path "$($ffProfile.FullName)\cache2" -Description "Firefox Cache"
}

# Edge
$EdgePaths = @(
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache"
)
foreach ($p in $EdgePaths) {
    Remove-TempContent -Path $p -Description "Edge Cache"
}

# ASP.NET Temp
Write-Host "`n🧱 Cleaning ASP.NET Temp files..." -ForegroundColor Magenta
$aspPaths = @(
    "C:\Windows\Microsoft.NET\Framework64",
    "C:\Windows\Microsoft.NET\Framework"
)
foreach ($base in $aspPaths) {
    if (Test-Path $base) {
        Get-ChildItem "$base\v*\Temporary ASP.NET Files" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-TempContent -Path $_.FullName -Description "ASP.NET Temp"
        }
    }
}

# Search for orphaned temp/log/cache files
Write-Host "`n🔍 Searching orphaned temp files (may take time)..." -ForegroundColor Magenta
try {
    Get-ChildItem -Path "C:\" -File -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -match "\.(tmp|log|old|bak|cache)$" -and
            $_.CreationTime -lt (Get-Date).AddDays(-7) -and
            $_.FullName -notmatch "\\Windows\\(System32|SysWOW64|WinSxS)" -and
            $_.FullName -notmatch "\\Program Files"
        } |
        Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "   ✅ Orphaned files cleaned" -ForegroundColor Green
}
catch {
    Write-Host "   ⚠️ Could not remove some orphaned files" -ForegroundColor Yellow
}

# Empty recycle bin
Write-Host "`n🗑️ Emptying Recycle Bin..." -ForegroundColor Magenta
try {
    Clear-RecycleBin -Force -ErrorAction Stop
    Write-Host "   ✅ Recycle Bin emptied" -ForegroundColor Green
}
catch {
    Write-Host "   ⚠️ Could not empty Recycle Bin: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Memory cleanup
Write-Host "`n🧠 Forcing .NET garbage collection..." -ForegroundColor Magenta
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.GC]::Collect()

# Done
Write-Host "`n" + ("=" * 60) -ForegroundColor Green
Write-Host "✅ SYSTEM TEMP CLEANUP COMPLETE!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green
Write-Host "Returning to terminal..." -ForegroundColor Cyan

return

