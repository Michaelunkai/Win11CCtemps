<<<<<<< HEAD
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
=======
# Complete Temporary File Purge Script for PowerShell 5.x
# Removes ALL temporary files from every temp location on C: drive

Write-Host "Starting comprehensive temp file cleanup..." -ForegroundColor Green
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow

# Function to safely remove files and folders
function Remove-TempContent {
    param(
        [string]$Path,
        [string]$Description
    )
    
    if (Test-Path $Path) {
        Write-Host "Cleaning: $Description ($Path)" -ForegroundColor Cyan
        try {
            Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | 
                Where-Object { !$_.PSIsContainer } | 
                Remove-Item -Force -ErrorAction SilentlyContinue
            
            Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | 
                Where-Object { $_.PSIsContainer } | 
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            
            Write-Host "  ✓ Cleaned successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "  ⚠ Some files in use or protected: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "  ℹ Path not found: $Path" -ForegroundColor Gray
    }
}

# Standard Windows temp locations
$TempLocations = @{
    "$env:TEMP" = "User Temp Folder"
    "$env:TMP" = "User TMP Folder"
    "$env:LOCALAPPDATA\Temp" = "Local AppData Temp"
    "C:\Windows\Temp" = "Windows Temp"
    "C:\Windows\Prefetch" = "Windows Prefetch"
    "C:\Windows\SoftwareDistribution\Download" = "Windows Update Cache"
    "C:\Windows\Logs" = "Windows Logs"
    "C:\Windows\System32\LogFiles" = "System32 Log Files"
    "C:\ProgramData\Microsoft\Windows\WER" = "Windows Error Reporting"
    "C:\Users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files" = "IE Temp Files"
    "C:\Users\*\AppData\Local\Microsoft\Windows\INetCache" = "IE Cache"
    "C:\Users\*\AppData\Local\Temp" = "All Users Local Temp"
}

# Clean standard locations
foreach ($location in $TempLocations.GetEnumerator()) {
    if ($location.Key -like "*\**") {
        # Handle wildcard paths
        $basePath = $location.Key.Split('\*')[0]
        if (Test-Path $basePath) {
            Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $fullPath = $location.Key.Replace("*", $_.Name)
                Remove-TempContent -Path $fullPath -Description "$($location.Value) - $($_.Name)"
            }
        }
    }
    else {
        Remove-TempContent -Path $location.Key -Description $location.Value
    }
}

# Browser cache cleanup
Write-Host "`nCleaning browser caches..." -ForegroundColor Magenta

# Chrome cache
>>>>>>> d0feddd628412f7dc026f889d53852ac32b0c558
$ChromePaths = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache"
)
<<<<<<< HEAD
foreach ($p in $ChromePaths) {
    Remove-TempContent -Path $p -Description "Chrome Cache"
}

# Firefox
$ffProfile = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if ($ffProfile) {
    Remove-TempContent -Path "$($ffProfile.FullName)\cache2" -Description "Firefox Cache"
}

# Edge
=======

foreach ($path in $ChromePaths) {
    Remove-TempContent -Path $path -Description "Chrome Cache"
}

# Firefox cache
$FirefoxProfile = Get-ChildItem -Path "$env:APPDATA\Mozilla\Firefox\Profiles" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if ($FirefoxProfile) {
    Remove-TempContent -Path "$($FirefoxProfile.FullName)\cache2" -Description "Firefox Cache"
}

# Edge cache
>>>>>>> d0feddd628412f7dc026f889d53852ac32b0c558
$EdgePaths = @(
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache"
)
<<<<<<< HEAD
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
=======

foreach ($path in $EdgePaths) {
    Remove-TempContent -Path $path -Description "Edge Cache"
}

# System-wide temp folder search
Write-Host "`nSearching for additional temp folders across C: drive..." -ForegroundColor Magenta

# Search for temp folders (this may take a while)
$TempFolders = @()
try {
    $TempFolders = Get-ChildItem -Path "C:\" -Directory -Recurse -Force -ErrorAction SilentlyContinue | 
        Where-Object { 
            $_.Name -match "^(temp|tmp|cache|log|logs)$" -and 
            $_.FullName -notmatch "Windows\\(System32|SysWOW64)\\config" -and
            $_.FullName -notmatch "Windows\\servicing" -and
            $_.FullName -notmatch "\\Windows\\WinSxS"
        }
}
catch {
    Write-Host "  ⚠ Access denied to some system folders during search" -ForegroundColor Yellow
}

foreach ($folder in $TempFolders) {
    Remove-TempContent -Path $folder.FullName -Description "Found temp folder"
}

# Clean IIS temp folders if present
if (Test-Path "C:\Windows\Microsoft.NET\Framework64\v*\Temporary ASP.NET Files") {
    Get-ChildItem -Path "C:\Windows\Microsoft.NET\Framework64\v*\Temporary ASP.NET Files" -Directory | ForEach-Object {
        Remove-TempContent -Path $_.FullName -Description "ASP.NET Temp Files"
    }
}

if (Test-Path "C:\Windows\Microsoft.NET\Framework\v*\Temporary ASP.NET Files") {
    Get-ChildItem -Path "C:\Windows\Microsoft.NET\Framework\v*\Temporary ASP.NET Files" -Directory | ForEach-Object {
        Remove-TempContent -Path $_.FullName -Description "ASP.NET Temp Files (32-bit)"
    }
}

# Clean Windows Installer temp
Remove-TempContent -Path "C:\Windows\Installer\$PatchCache$" -Description "Windows Installer Patch Cache"

# Clean thumbnail cache
Remove-TempContent -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" -Description "Thumbnail Cache"

# Clean recent documents
Remove-TempContent -Path "$env:APPDATA\Microsoft\Windows\Recent" -Description "Recent Documents"

# Clean recycle bin
Write-Host "`nEmptying Recycle Bin..." -ForegroundColor Magenta
try {
    Clear-RecycleBin -Force -ErrorAction Stop
    Write-Host "  ✓ Recycle Bin emptied" -ForegroundColor Green
}
catch {
    Write-Host "  ⚠ Could not empty Recycle Bin: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Clean additional system temp locations
$AdditionalPaths = @(
    "C:\ProgramData\Package Cache",
    "C:\Windows\Panther",
    "C:\Windows\Minidump",
    "C:\Windows\LiveKernelReports",
    "C:\ProgramData\Microsoft\Windows\AppRepository",
    "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Temp",
    "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Temp"
)

foreach ($path in $AdditionalPaths) {
    Remove-TempContent -Path $path -Description "System temp location"
}

# Final cleanup - search for orphaned temp files
Write-Host "`nSearching for orphaned temp files..." -ForegroundColor Magenta
try {
    Get-ChildItem -Path "C:\" -File -Recurse -Force -ErrorAction SilentlyContinue | 
        Where-Object { 
            $_.Name -match "\.(tmp|temp|log|old|bak|cache)$" -and 
            $_.CreationTime -lt (Get-Date).AddDays(-7) -and
            $_.FullName -notmatch "Windows\\(System32|SysWOW64)" -and
            $_.FullName -notmatch "Program Files"
        } | 
        Remove-Item -Force -ErrorAction SilentlyContinue
    
    Write-Host "  ✓ Orphaned temp files cleaned" -ForegroundColor Green
}
catch {
    Write-Host "  ⚠ Some orphaned files could not be removed" -ForegroundColor Yellow
}

# Clean Windows Event Logs (optional - uncomment if needed)
# Write-Host "`nClearing Windows Event Logs..." -ForegroundColor Magenta
# Get-EventLog -List | ForEach-Object { Clear-EventLog $_.Log -ErrorAction SilentlyContinue }

# Memory cleanup
Write-Host "`nPerforming memory cleanup..." -ForegroundColor Magenta
>>>>>>> d0feddd628412f7dc026f889d53852ac32b0c558
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.GC]::Collect()

<<<<<<< HEAD
# Done
Write-Host "`n" + ("=" * 60) -ForegroundColor Green
Write-Host "✅ SYSTEM TEMP CLEANUP COMPLETE!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green
Write-Host "Returning to terminal..." -ForegroundColor Cyan

return

=======
Write-Host "`n" + "="*60 -ForegroundColor Green
Write-Host "CLEANUP COMPLETE!" -ForegroundColor Green
Write-Host "All temporary files have been purged from C: drive" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Green
Write-Host "`nReturning to PowerShell terminal..." -ForegroundColor Cyan

# Return to PowerShell prompt
return
>>>>>>> d0feddd628412f7dc026f889d53852ac32b0c558
