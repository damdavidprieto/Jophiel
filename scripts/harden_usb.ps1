<#
.SYNOPSIS
    Manages USB Storage Access (Lock/Unlock).
    Revised version: No emojis/special chars.

.DESCRIPTION
    Controls the 'USBSTOR' service start type.
    - Lock: Disables the USBSTOR driver (Value 4).
    - Unlock: Enables the USBSTOR driver (Value 3).
    
    Usage: Run as Administrator.
#>

#Requires -RunAsAdministrator

param(
    [switch]$Lock,
    [switch]$Unlock,
    [switch]$Status
)

$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR"
$regName = "Start"

function Get-UsbStatus {
    try {
        $val = Get-ItemProperty -Path $regPath -Name $regName -ErrorAction Stop
        return $val.$regName
    }
    catch {
        return $null
    }
}

Write-Host "Jophiel - USB Storage Control" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

$current = Get-UsbStatus

if ($Status -or (-not $Lock -and -not $Unlock)) {
    Write-Host "Current Status: " -NoNewline
    if ($current -eq 3) {
        Write-Host "ENABLED (Unlocked)" -ForegroundColor Green
        Write-Host "  Any user can insert and use USB drives." -ForegroundColor Gray
    }
    elseif ($current -eq 4) {
        Write-Host "DISABLED (Locked)" -ForegroundColor Red
        Write-Host "  USB Mass Storage driver is disabled." -ForegroundColor Gray
    }
    else {
        Write-Host "UNKNOWN ($current)" -ForegroundColor Yellow
    }
    
    if (-not $Lock -and -not $Unlock) {
        Write-Host "`nUsage: .\harden_usb.ps1 -Lock | -Unlock" -ForegroundColor White
    }
}

if ($Lock) {
    Write-Host "`n[LOCK] Locking USB Storage..." -ForegroundColor Yellow
    try {
        Set-ItemProperty -Path $regPath -Name $regName -Value 4
        Write-Host "  [OK] USB Storage Disabled." -ForegroundColor Green
        Write-Host "  Standard users will NOT be able to mount new USB drives." -ForegroundColor Gray
    }
    catch {
        Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($Unlock) {
    Write-Host "`n[UNLOCK] Unlocking USB Storage..." -ForegroundColor Yellow
    try {
        Set-ItemProperty -Path $regPath -Name $regName -Value 3
        Write-Host "  [OK] USB Storage Enabled." -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
    }
}
