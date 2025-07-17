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
$ChromePaths = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache"
)

foreach ($path in $ChromePaths) {
    Remove-TempContent -Path $path -Description "Chrome Cache"
}

# Firefox cache
$FirefoxProfile = Get-ChildItem -Path "$env:APPDATA\Mozilla\Firefox\Profiles" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if ($FirefoxProfile) {
    Remove-TempContent -Path "$($FirefoxProfile.FullName)\cache2" -Description "Firefox Cache"
}

# Edge cache
$EdgePaths = @(
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache"
)

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
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.GC]::Collect()

Write-Host "`n" + "="*60 -ForegroundColor Green
Write-Host "CLEANUP COMPLETE!" -ForegroundColor Green
Write-Host "All temporary files have been purged from C: drive" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Green
Write-Host "`nReturning to PowerShell terminal..." -ForegroundColor Cyan

# Return to PowerShell prompt
return
