<#
.SYNOPSIS
    Deep audit of the Administrator account 'Charles' for purity and isolation.
    Revised version to fix syntax errors.
#>

#Requires -RunAsAdministrator

$targetUser = "Charles"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Build paths - using Join-Path for safety
$scriptPath = $PSScriptRoot
$parentPath = Split-Path -Parent $scriptPath
$reportsDir = Join-Path $parentPath "reports"
$reportFile = "admin_purity_$timestamp.json"
$reportPath = Join-Path $reportsDir $reportFile

# Ensure reports directory exists
if (-not (Test-Path $reportsDir)) { 
    New-Item -Path $reportsDir -ItemType Directory | Out-Null 
}

Write-Host "Jophiel - Admin Purity Audit for: $targetUser" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

$auditData = @{
    Timestamp    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TargetUser   = $targetUser
    StartupItems = @()
    Browsers     = @{}
    Downloads    = @{}
    UserSoftware = @()
}

# 1. Startup Items (Registry)
Write-Host "`nChecking Startup Items..." -ForegroundColor Yellow

# HKLM Run
$hklmRun = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue
if ($hklmRun) {
    foreach ($name in $hklmRun.PSObject.Properties.Name) {
        if ($name -match "^PS") { continue } # Skip PS internal properties
        $val = $hklmRun.$name
        
        $item = @{ Location = "HKLM:Run"; Name = $name; Value = $val }
        $auditData.StartupItems += $item
        
        Write-Host "  [HKLM] $name -> $val" -ForegroundColor Gray
    }
}

# Startup Folder (Common)
$commonStartup = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
if (Test-Path $commonStartup) {
    $items = Get-ChildItem $commonStartup
    foreach ($item in $items) {
        $auditData.StartupItems += @{ Location = "CommonStartup"; Name = $item.Name; Size = $item.Length }
        Write-Host "  [CommonStartup] $($item.Name)" -ForegroundColor Gray
    }
}

# 2. Browser Usage (Signs of heavy usage)
Write-Host "`nChecking Browser Footprint..." -ForegroundColor Yellow

$chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"
$edgePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History"
$firefoxPath = "$env:APPDATA\Mozilla\Firefox\Profiles"

$browsers = @{
    "Chrome"  = $chromePath
    "Edge"    = $edgePath
    "Firefox" = $firefoxPath
}

foreach ($key in $browsers.Keys) {
    $path = $browsers[$key]
    if (Test-Path $path) {
        $info = Get-Item $path
        $len = $info.Length
        $sizeMB = [math]::Round($len / 1MB, 2)
        
        $auditData.Browsers[$key] = @{ Detected = $true; HistorySizeMB = $sizeMB }
        Write-Host "  [WARN] $key Profile Found. History: $sizeMB MB" -ForegroundColor Yellow
    }
    else {
        $auditData.Browsers[$key] = @{ Detected = $false }
        Write-Host "  [OK] $key Clean (No default profile/history)" -ForegroundColor Green
    }
}

# 3. Downloads Folder
Write-Host "`nChecking Downloads Clutter..." -ForegroundColor Yellow
$downloadsPath = "$env:USERPROFILE\Downloads"

if (Test-Path $downloadsPath) {
    $files = Get-ChildItem $downloadsPath -File -Recurse -ErrorAction SilentlyContinue
    $count = $files.Count
    
    # Calculate size cleanly
    if ($files) {
        $stats = $files | Measure-Object -Property Length -Sum
        $totalSizeBytes = $stats.Sum
    }
    else {
        $totalSizeBytes = 0
    }
    
    $totalSizeMB = [math]::Round($totalSizeBytes / 1MB, 2)
    
    $auditData.Downloads = @{ 
        Count       = $count
        TotalSizeMB = $totalSizeMB
    }
    
    if ($count -gt 0) {
        Write-Host "  [WARN] Downloads folder contains $count files ($totalSizeMB MB)" -ForegroundColor Yellow
        Write-Host "         (Admins should keep Downloads empty)" -ForegroundColor Gray
    }
    else {
        Write-Host "  [OK] Downloads folder is empty" -ForegroundColor Green
    }
}

# 4. Persistence / User Software (HKCU Uninstall)
Write-Host "`nChecking User-Scope Installed Software..." -ForegroundColor Yellow
$uninstallKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"

if (Test-Path $uninstallKey) {
    $keys = Get-ChildItem $uninstallKey
    foreach ($key in $keys) {
        $props = Get-ItemProperty $key.PSPath
        if ($props.DisplayName) {
            $auditData.UserSoftware += $props.DisplayName
            Write-Host "  [INFO] $($props.DisplayName)" -ForegroundColor Gray
        }
    }
}

# Save Report
$json = $auditData | ConvertTo-Json -Depth 5
Set-Content -Path $reportPath -Value $json
Write-Host "`nReport saved to: $reportPath" -ForegroundColor Green
Write-Host "Complete."
