# ===================================================================
# ULTIMATE C: DRIVE CLEANUP SCRIPT - COMPREHENSIVE TEMP/LOG/CACHE CLEANER
# ===================================================================
# WARNING: This script performs aggressive cleanup. Run as Administrator.
# AUTO-CONFIRM VERSION - NO PROMPTS!
# ===================================================================

Write-Host "🚀 ULTIMATE C: DRIVE CLEANUP INITIATED (AUTO-CONFIRM MODE)" -ForegroundColor Red
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
Write-Host "Current User: $env:USERNAME" -ForegroundColor Yellow
Write-Host "=" * 70 -ForegroundColor Red

# Set confirmation preference to avoid prompts
$ConfirmPreference = 'None'
$ErrorActionPreference = 'SilentlyContinue'

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "⚠️ WARNING: Not running as Administrator. Some files may not be accessible." -ForegroundColor Yellow
}

# Initialize counters
$totalFilesDeleted = 0
$totalSizeFreed = 0
$startTime = Get-Date

# Enhanced cleanup function with size tracking and no prompts
function Remove-TempContent {
    param (
        [string]$Path,
        [string]$Description,
        [switch]$RecurseOnly,
        [string[]]$ExcludePatterns = @()
    )
    
    if (Test-Path $Path) {
        Write-Host "🔄 Processing: $Description" -ForegroundColor Cyan
        Write-Host "   📁 Path: $Path" -ForegroundColor DarkGray
        
        try {
            $itemsBefore = 0
            $sizeBefore = 0
            
            # Calculate size before deletion
            $items = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
            if ($items) {
                $itemsBefore = $items.Count
                $sizeBefore = ($items | Where-Object {!$_.PSIsContainer} | Measure-Object -Property Length -Sum).Sum
                if ($null -eq $sizeBefore) { $sizeBefore = 0 }
            }
            
            if ($RecurseOnly) {
                # Only delete contents, not the folder itself
                Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | 
                    Where-Object { 
                        $item = $_
                        $shouldExclude = $false
                        foreach ($pattern in $ExcludePatterns) {
                            if ($item.FullName -like $pattern) {
                                $shouldExclude = $true
                                break
                            }
                        }
                        return -not $shouldExclude
                    } |
                    Remove-Item -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue
            } else {
                # Delete the entire folder and its contents
                Remove-Item -Path $Path -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue
            }
            
            $script:totalFilesDeleted += $itemsBefore
            $script:totalSizeFreed += $sizeBefore
            
            $sizeFreedMB = [math]::Round($sizeBefore / 1MB, 2)
            Write-Host "   ✅ Cleaned: $itemsBefore files ($sizeFreedMB MB)" -ForegroundColor Green
        }
        catch {
            Write-Host "   ⚠️ Partial cleanup: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   ❌ Not found: $Path" -ForegroundColor DarkGray
    }
}

# Function to handle single file deletion with no prompts
function Remove-SingleFile {
    param (
        [string]$Path,
        [string]$Description
    )
    
    if (Test-Path $Path) {
        Write-Host "🔄 Processing: $Description" -ForegroundColor Cyan
        Write-Host "   📁 Path: $Path" -ForegroundColor DarkGray
        
        try {
            $file = Get-Item $Path -ErrorAction SilentlyContinue
            if ($file) {
                $fileSize = $file.Length
                Remove-Item -Path $Path -Force -Confirm:$false -ErrorAction SilentlyContinue
                $script:totalFilesDeleted += 1
                $script:totalSizeFreed += $fileSize
                
                $sizeFreedMB = [math]::Round($fileSize / 1MB, 2)
                Write-Host "   ✅ Deleted: $sizeFreedMB MB" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "   ⚠️ Could not delete: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   ❌ Not found: $Path" -ForegroundColor DarkGray
    }
}

# PHASE 1: STANDARD TEMP LOCATIONS
Write-Host "`n📂 PHASE 1: STANDARD TEMPORARY LOCATIONS" -ForegroundColor Magenta
Write-Host "=" * 50 -ForegroundColor Magenta

$StandardTempPaths = @{
    "$env:TEMP" = "User TEMP Folder"
    "$env:TMP" = "User TMP Folder"
    "$env:LOCALAPPDATA\Temp" = "Local AppData Temp"
    "C:\Windows\Temp" = "Windows System Temp"
    "C:\Temp" = "Root Temp Folder"
    "C:\tmp" = "Root tmp Folder"
    "$env:USERPROFILE\AppData\Local\Temp" = "User Profile Temp"
}

foreach ($entry in $StandardTempPaths.GetEnumerator()) {
    Remove-TempContent -Path $entry.Key -Description $entry.Value -RecurseOnly
}

# PHASE 2: WINDOWS SYSTEM CLEANUP
Write-Host "`n🖥️ PHASE 2: WINDOWS SYSTEM CLEANUP" -ForegroundColor Magenta
Write-Host "=" * 50 -ForegroundColor Magenta

$WindowsSystemPaths = @{
    "C:\Windows\Prefetch" = "Windows Prefetch Files"
    "C:\Windows\SoftwareDistribution\Download" = "Windows Update Downloads"
    "C:\Windows\Logs" = "Windows System Logs"
    "C:\Windows\Panther" = "Windows Installation Logs"
    "C:\Windows\System32\LogFiles" = "System32 Log Files"
    "C:\Windows\System32\winevt\Logs" = "Windows Event Logs (Archives)"
    "C:\Windows\Minidump" = "Memory Dump Files"
    "C:\Windows\LiveKernelReports" = "Kernel Reports"
    "C:\Windows\Installer\`$PatchCache`$" = "Windows Installer Patch Cache"
    "C:\ProgramData\Microsoft\Windows\WER" = "Windows Error Reporting"
    "C:\ProgramData\Microsoft\Windows\AppRepository" = "App Repository Cache"
    "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Temp" = "LocalService Temp"
    "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Temp" = "NetworkService Temp"
    "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache" = "LocalService Font Cache"
    "C:\Windows\System32\config\systemprofile\AppData\Local\Temp" = "System Profile Temp"
    "C:\Windows\System32\config\DEFAULT\AppData\Local\Temp" = "Default Profile Temp"
    "C:\Windows\LastGood.Tmp" = "Windows Last Good Configuration"
}

foreach ($entry in $WindowsSystemPaths.GetEnumerator()) {
    Remove-TempContent -Path $entry.Key -Description $entry.Value -RecurseOnly
}

# Handle special system files separately
$SystemFiles = @(
    @{Path = "C:\Windows\Memory.dmp"; Description = "Memory Dump File"}
    @{Path = "C:\hiberfil.sys"; Description = "Hibernation File"}
    @{Path = "C:\pagefile.sys"; Description = "Page File"}
    @{Path = "C:\swapfile.sys"; Description = "Swap File"}
)

foreach ($file in $SystemFiles) {
    if (Test-Path $file.Path) {
        Write-Host "🔄 Found: $($file.Description) - $($file.Path)" -ForegroundColor Yellow
        if ($file.Path -like "*Memory.dmp") {
            Remove-SingleFile -Path $file.Path -Description $file.Description
        } else {
            Write-Host "   ⚠️ System file - manual deletion required if needed" -ForegroundColor Yellow
        }
    }
}

# PHASE 3: USER-SPECIFIC CLEANUP
Write-Host "`n👤 PHASE 3: USER-SPECIFIC CLEANUP" -ForegroundColor Magenta
Write-Host "=" * 50 -ForegroundColor Magenta

$UserSpecificPaths = @{
    "$env:APPDATA\Microsoft\Windows\Recent" = "Recent Documents"
    "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" = "Thumbnail Cache"
    "$env:LOCALAPPDATA\Microsoft\Windows\Caches" = "Windows Caches"
    "$env:LOCALAPPDATA\Microsoft\Windows\INetCache" = "Internet Cache"
    "$env:LOCALAPPDATA\Microsoft\Windows\Temporary Internet Files" = "IE Temp Files"
    "$env:LOCALAPPDATA\Microsoft\Windows\WebCache" = "Web Cache"
    "$env:LOCALAPPDATA\Microsoft\Terminal Server Client\Cache" = "RDP Cache"
    "$env:APPDATA\Microsoft\Office\Recent" = "Office Recent Files"
    "$env:LOCALAPPDATA\Microsoft\Office\UnsavedFiles" = "Office Unsaved Files"
    "$env:LOCALAPPDATA\Microsoft\Office\OfficeFileCache" = "Office File Cache"
    "$env:LOCALAPPDATA\CrashDumps" = "User Crash Dumps"
}

foreach ($entry in $UserSpecificPaths.GetEnumerator()) {
    Remove-TempContent -Path $entry.Key -Description $entry.Value -RecurseOnly
}

# PHASE 4: ALL USERS CLEANUP
Write-Host "`n👥 PHASE 4: ALL USERS CLEANUP" -ForegroundColor Magenta
Write-Host "=" * 50 -ForegroundColor Magenta

if (Test-Path "C:\Users") {
    Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $username = $_.Name
        if ($username -notin @("All Users", "Default", "Default User", "Public")) {
            Write-Host "🔄 Processing user: $username" -ForegroundColor Cyan
            
            $userPaths = @{
                "$($_.FullName)\AppData\Local\Temp" = "$username - Local Temp"
                "$($_.FullName)\AppData\Local\Microsoft\Windows\Temporary Internet Files" = "$username - IE Temp"
                "$($_.FullName)\AppData\Local\Microsoft\Windows\INetCache" = "$username - INet Cache"
                "$($_.FullName)\AppData\Local\Microsoft\Windows\Explorer" = "$username - Explorer Cache"
                "$($_.FullName)\AppData\Roaming\Microsoft\Windows\Recent" = "$username - Recent Docs"
                "$($_.FullName)\AppData\Local\CrashDumps" = "$username - Crash Dumps"
                "$($_.FullName)\AppData\Local\Microsoft\Windows\Caches" = "$username - Windows Caches"
                "$($_.FullName)\AppData\Local\Microsoft\Windows\WebCache" = "$username - Web Cache"
            }
            
            foreach ($entry in $userPaths.GetEnumerator()) {
                Remove-TempContent -Path $entry.Key -Description $entry.Value -RecurseOnly
            }
        }
    }
}

# PHASE 5: BROWSER CACHE CLEANUP
Write-Host "`n🌐 PHASE 5: COMPREHENSIVE BROWSER CLEANUP" -ForegroundColor Magenta
Write-Host "=" * 50 -ForegroundColor Magenta

# Chrome/Chromium-based browsers
$ChromiumPaths = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Media Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\ShaderCache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\GPUCache",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Vivaldi\User Data\Default\Cache"
)

foreach ($path in $ChromiumPaths) {
    $browserName = ($path -split '\\')[3]
    Remove-TempContent -Path $path -Description "$browserName Cache" -RecurseOnly
}

# Firefox
if (Test-Path "$env:APPDATA\Mozilla\Firefox\Profiles") {
    Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-TempContent -Path "$($_.FullName)\cache2" -Description "Firefox Cache ($($_.Name))" -RecurseOnly
        Remove-TempContent -Path "$($_.FullName)\startupCache" -Description "Firefox Startup Cache ($($_.Name))" -RecurseOnly
        Remove-TempContent -Path "$($_.FullName)\OfflineCache" -Description "Firefox Offline Cache ($($_.Name))" -RecurseOnly
    }
}

# PHASE 6: APPLICATION CACHES
Write-Host "`n📱 PHASE 6: APPLICATION CACHES & LOGS" -ForegroundColor Magenta
Write-Host "=" * 50 -ForegroundColor Magenta

$AppCachePaths = @{
    "$env:LOCALAPPDATA\Steam\logs" = "Steam Logs"
    "$env:LOCALAPPDATA\Discord\Cache" = "Discord Cache"
    "$env:LOCALAPPDATA\Discord\Code Cache" = "Discord Code Cache"
    "$env:LOCALAPPDATA\Discord\GPUCache" = "Discord GPU Cache"
    "$env:LOCALAPPDATA\Spotify\Storage" = "Spotify Cache"
    "$env:LOCALAPPDATA\Spotify\Browser\Cache" = "Spotify Browser Cache"
    "$env:LOCALAPPDATA\Adobe\Common\Media Cache Files" = "Adobe Media Cache"
    "$env:APPDATA\Code\logs" = "VS Code Logs"
    "$env:APPDATA\Code\CachedData" = "VS Code Cache"
    "$env:LOCALAPPDATA\Microsoft\Windows\WebCache2" = "Windows Web Cache v2"
    "C:\ProgramData\Package Cache" = "ProgramData Package Cache"
    "C:\ProgramData\Microsoft\Windows\AppRepository2" = "Windows App Repository v2"
}

foreach ($entry in $AppCachePaths.GetEnumerator()) {
    Remove-TempContent -Path $entry.Key -Description $entry.Value -RecurseOnly
}

# Handle wildcard application paths
$WildcardAppPaths = @(
    @{Pattern = "$env:LOCALAPPDATA\Packages\*\TempState"; Description = "UWP App Temp States"}
    @{Pattern = "$env:LOCALAPPDATA\Packages\*\LocalCache"; Description = "UWP App Local Cache"}
    @{Pattern = "$env:LOCALAPPDATA\JetBrains\*\logs"; Description = "JetBrains Logs"}
    @{Pattern = "$env:LOCALAPPDATA\JetBrains\*\caches"; Description = "JetBrains Caches"}
)

foreach ($wildcardPath in $WildcardAppPaths) {
    $basePath = ($wildcardPath.Pattern -split '\\\*')[0]
    if (Test-Path $basePath) {
        Get-ChildItem $basePath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $expandedPath = $wildcardPath.Pattern -replace '\*', $_.Name
            Remove-TempContent -Path $expandedPath -Description "$($wildcardPath.Description) ($($_.Name))" -RecurseOnly
        }
    }
}

# PHASE 7: .NET & DEVELOPMENT CLEANUP
Write-Host "`n🧱 PHASE 7: .NET & DEVELOPMENT CLEANUP" -ForegroundColor Magenta
Write-Host "=" * 50 -ForegroundColor Magenta

# ASP.NET Temporary Files
$dotNetPaths = @("C:\Windows\Microsoft.NET\Framework64", "C:\Windows\Microsoft.NET\Framework")
foreach ($base in $dotNetPaths) {
    if (Test-Path $base) {
        Get-ChildItem "$base\v*\Temporary ASP.NET Files" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-TempContent -Path $_.FullName -Description "ASP.NET Temp ($($_.Parent.Name))" -RecurseOnly
        }
    }
}

# Additional development caches
$DevPaths = @{
    "$env:LOCALAPPDATA\NuGet\Cache" = "NuGet Package Cache"
    "$env:USERPROFILE\.nuget\packages" = "User NuGet Cache"
    "$env:LOCALAPPDATA\pip\cache" = "Python Pip Cache"
    "$env:APPDATA\npm-cache" = "NPM Cache"
    "$env:LOCALAPPDATA\Yarn\Cache" = "Yarn Cache"
    "C:\ProgramData\chocolatey\logs" = "Chocolatey Logs"
    "$env:LOCALAPPDATA\node-gyp\Cache" = "Node-gyp Cache"
    "$env:USERPROFILE\.gradle\caches" = "Gradle Cache"
    "$env:USERPROFILE\.m2\repository" = "Maven Repository Cache"
}

foreach ($entry in $DevPaths.GetEnumerator()) {
    Remove-TempContent -Path $entry.Key -Description $entry.Value -RecurseOnly
}

# PHASE 8: SYSTEM SERVICE LOGS
Write-Host "`n🔧 PHASE 8: SYSTEM SERVICE LOGS" -ForegroundColor Magenta
Write-Host "=" * 50 -ForegroundColor Magenta

$ServiceLogPaths = @{
    "C:\ProgramData\Microsoft\Windows Defender\Scans\History" = "Windows Defender Scan History"
    "C:\ProgramData\Microsoft\Windows Defender\Support" = "Windows Defender Support Logs"
    "C:\ProgramData\Microsoft\Network\Connections\Cm\CmTrace" = "Connection Manager Logs"
    "C:\Windows\debug" = "Windows Debug Logs"
    "C:\Windows\System32\LogFiles\WMI" = "WMI Log Files"
    "C:\Windows\System32\LogFiles\HTTPERR" = "HTTP Error Logs"
    "C:\Windows\System32\LogFiles\Firewall" = "Firewall Logs"
}

foreach ($entry in $ServiceLogPaths.GetEnumerator()) {
    Remove-TempContent -Path $entry.Key -Description $entry.Value -RecurseOnly
}

# Handle Service Profile wildcards
$ServiceProfileBase = "C:\Windows\ServiceProfiles"
if (Test-Path $ServiceProfileBase) {
    Get-ChildItem $ServiceProfileBase -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $serviceName = $_.Name
        $tempPath = "$($_.FullName)\AppData\Local\Temp"
        Remove-TempContent -Path $tempPath -Description "Service Profile Temp ($serviceName)" -RecurseOnly
    }
}

# PHASE 9: AGGRESSIVE FILE PATTERN CLEANUP
Write-Host "`n🔍 PHASE 9: AGGRESSIVE PATTERN-BASED CLEANUP (AUTO-CONFIRM)" -ForegroundColor Magenta
Write-Host "=" * 50 -ForegroundColor Magenta

Write-Host "🔄 Searching for temporary files by pattern..." -ForegroundColor Cyan

$searchPaths = @("C:\")
$tempExtensions = @("*.tmp", "*.temp", "*.log", "*.old", "*.bak", "*.cache", "*.dmp", "*.etl", "*.evtx")
$excludeDirectories = @(
    "*\Windows\System32\*",
    "*\Windows\SysWOW64\*", 
    "*\Windows\WinSxS\*",
    "*\Program Files\*",
    "*\Program Files (x86)\*"
)

foreach ($searchPath in $searchPaths) {
    foreach ($extension in $tempExtensions) {
        try {
            Write-Host "   🔍 Searching for $extension files..." -ForegroundColor DarkCyan
            
            Get-ChildItem -Path $searchPath -Filter $extension -Recurse -Force -ErrorAction SilentlyContinue |
                Where-Object { 
                    $file = $_
                    $shouldExclude = $false
                    
                    # Check exclusions
                    foreach ($excludePattern in $excludeDirectories) {
                        if ($file.FullName -like $excludePattern) {
                            $shouldExclude = $true
                            break
                        }
                    }
                    
                    # Additional safety checks
                    return (-not $shouldExclude) -and 
                           ($file.CreationTime -lt (Get-Date).AddDays(-1)) -and
                           ($file.Length -gt 0)
                } |
                ForEach-Object {
                    try {
                        $fileSize = $_.Length
                        # Use -Force -Recurse -Confirm:$false to avoid all prompts
                        Remove-Item $_.FullName -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue
                        $script:totalFilesDeleted++
                        $script:totalSizeFreed += $fileSize
                    }
                    catch {
                        # Silently continue
                    }
                }
        }
        catch {
            Write-Host "   ⚠️ Could not search for $extension`: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# PHASE 10: RECYCLE BIN & FINAL CLEANUP
Write-Host "`n🗑️ PHASE 10: RECYCLE BIN & FINAL CLEANUP" -ForegroundColor Magenta
Write-Host "=" * 50 -ForegroundColor Magenta

# Empty Recycle Bin
Write-Host "🔄 Emptying Recycle Bin..." -ForegroundColor Cyan
try {
    Clear-RecycleBin -Force -Confirm:$false -ErrorAction Stop
    Write-Host "   ✅ Recycle Bin emptied" -ForegroundColor Green
}
catch {
    Write-Host "   ⚠️ Could not empty Recycle Bin: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Memory cleanup
Write-Host "🔄 Performing memory cleanup..." -ForegroundColor Cyan
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.GC]::Collect()
Write-Host "   ✅ Garbage collection completed" -ForegroundColor Green

# FINAL REPORT
$endTime = Get-Date
$duration = $endTime - $startTime
$totalSizeFreedGB = [math]::Round($totalSizeFreed / 1GB, 2)
$totalSizeFreedMB = [math]::Round($totalSizeFreed / 1MB, 2)

Write-Host "`n" + ("=" * 70) -ForegroundColor Green
Write-Host "🎉 ULTIMATE CLEANUP COMPLETED!" -ForegroundColor Green
Write-Host "=" * 70 -ForegroundColor Green
Write-Host "📊 CLEANUP STATISTICS:" -ForegroundColor Yellow
Write-Host "   📁 Files Deleted: $totalFilesDeleted" -ForegroundColor White
Write-Host "   💾 Space Freed: $totalSizeFreedMB MB ($totalSizeFreedGB GB)" -ForegroundColor White
Write-Host "   ⏱️ Duration: $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor White
Write-Host "   📅 Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host "=" * 70 -ForegroundColor Green

Write-Host "`n💡 RECOMMENDATIONS:" -ForegroundColor Yellow
Write-Host "   • Run Disk Cleanup (cleanmgr.exe) for additional system cleanup" -ForegroundColor Cyan
Write-Host "   • Consider enabling Storage Sense for automatic cleanup" -ForegroundColor Cyan
Write-Host "   • Reboot your system to complete the cleanup process" -ForegroundColor Cyan
Write-Host "   • Run 'sfc /scannow' if you experience any issues" -ForegroundColor Cyan

Write-Host "`n✅ Script execution completed successfully! (No prompts mode)" -ForegroundColor Green

# Reset preference back to default
$ConfirmPreference = 'High'
$ErrorActionPreference = 'Continue'
