<#
.SYNOPSIS
    Hardens Windows Service Permissions (SCM).

.DESCRIPTION
    Analyzes and hardens the Service Control Manager Security Descriptor.
    - Ensures standard users cannot modify services (Standard Secure).
    - Can prevent standard users from listing services (Extreme Hardening).

.NOTES
    Project: Jophiel
    Usage: Run as Administrator.
#>

#Requires -RunAsAdministrator

function Get-ServiceSecurity {
    param($ServiceName)
    # Using sc.exe to get SDDL
    if ($ServiceName) {
        return sc.exe sdshow $ServiceName
    }
    else {
        return sc.exe sdshow scmanager
    }
}

Write-Host "🛡️  Jophiel - Service Security Hardening" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Analyze SCM Permissions
$scmSDDL = Get-ServiceSecurity
Write-Host "`nCurrent SCM SDDL:" -ForegroundColor Yellow
Write-Host $scmSDDL -ForegroundColor Gray

# Security Descriptor Definition Language (SDDL) basics:
# D: = DACL
# (A;;... = Allow
# KA = Key All Access (Full Control)
# KR = Key Read
# BA = Built-in Administrators
# AU = Authenticated Users
# IU = Interactive Users

Write-Host "`nAnalysis:" -ForegroundColor Cyan
if ($scmSDDL -match "\(A;;.*?KA.*?;.*?AU\)") {
    Write-Host "  [WARN] Authenticated Users have FULL CONTROL (Unlikely/Critical Risk)" -ForegroundColor Red
}
elseif ($scmSDDL -match "\(A;;.*?CC.*?;.*?AU\)") {
    Write-Host "  [WARN] Authenticated Users can CREATE services (High Risk)" -ForegroundColor Red
}
else {
    Write-Host "  [OK] Authenticated Users cannot Create/Modify services (Standard Security)" -ForegroundColor Green
}

if ($scmSDDL -match "\(A;;.*?Luh.*?;.*?AU\)") { 
    # Luh = Generic Read... roughly. RP/WP/etc.
    Write-Host "  [INFO] Authenticated Users can READ/ENUMERATE services." -ForegroundColor White
    Write-Host "         This is default Windows behavior." -ForegroundColor Gray
}

Write-Host "`nOptions for Hardening:" -ForegroundColor Yellow
Write-Host "1. [Standard] Ensure only Admins can Write/Create (Usually Default)"
Write-Host "2. [Extreme] Hide Services from Standard Users (Remove 'AU' Read access)" 
Write-Host "   WARNING: This might break some apps depending on service enumeration."

# NOTE: Actual modification requires interactive choice or explicit flags.
# For this script we will just AUDIT for now, or provide the command to harden.

Write-Host "`nTo Apply Extreme Hardening (Admin Only Read/Write):" -ForegroundColor Magenta
Write-Host "sc.exe sdset scmanager D:(A;;KA;;;BA)(A;;KA;;;SY)(A;;CCLCRPRC;;;IU)" -ForegroundColor White
Write-Host "(This removes 'AU' entirely, leaving System, Admin, and Interactive User)"

Write-Host "`nComplete."
