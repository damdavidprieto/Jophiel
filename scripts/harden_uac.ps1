<#
.SYNOPSIS
    Hardens User Account Control (UAC) to Maximum Security.

.DESCRIPTION
    Applies the following UAC policies via Registry:
    1. ConsentPromptBehaviorAdmin = 2 (Prompt for consent on secure desktop) -> CHANGED TO: Prompt for Credentials (Password)
    2. ConsentPromptBehaviorUser  = 3 (Prompt for credentials on secure desktop)
    3. EnableLUA                  = 1 (UAC Enabled)
    4. PromptOnSecureDesktop      = 1 (Dim screen / Secure Desktop)

    GOAL: 
    - Always notify for any admin task.
    - Require PASSWORD even for Administrators (prevents accidental 'Yes' clicks).

.NOTES
    Project: Jophiel
    Usage: Run as Administrator. Restart required for some changes to fully take effect.
#>

#Requires -RunAsAdministrator

Write-Host "🛡️  Jophiel - UAC Extreme Hardening" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

$policyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

# Function to safely set registry value
function Set-RegValue {
    param($Name, $Value, $Desc)
    try {
        Set-ItemProperty -Path $policyPath -Name $Name -Value $Value -ErrorAction Stop
        Write-Host "  ✓ $Desc ($Name = $Value)" -ForegroundColor Green
    }
    catch {
        Write-Host "  ✗ Error setting $Name: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nApplying Policies..." -ForegroundColor Yellow

# 1. Enable UAC (Just in case)
Set-RegValue -Name "EnableLUA" -Value 1 -Desc "UAC Enabled globally"

# 2. Secure Desktop (Dim Screen) - Prevents spoofing
Set-RegValue -Name "PromptOnSecureDesktop" -Value 1 -Desc "Secure Desktop Enabled (Dim Screen)"

# 3. Behavior for Standard Users (Default is 3: Prompt for credentials)
Set-RegValue -Name "ConsentPromptBehaviorUser" -Value 3 -Desc "Standard Users: Prompt for Credentials"

# 4. Behavior for Admins (THE BIG CHANGE)
# 5 = Prompt for consent (Default "Yes/No")
# 2 = Prompt for consent on secure desktop (Better "Yes/No")
# 1 = Prompt for credentials (Require Password on secure desktop) -> EXTREME
# 
# We will set to 1 (Password Required) as requested for "Strict Policies".
Set-RegValue -Name "ConsentPromptBehaviorAdmin" -Value 1 -Desc "Administrators: REQUIRE PASSWORD for Elevation"

Write-Host "`n✅ Configuration Complete." -ForegroundColor Green
Write-Host "IMPORTANT: You may need to restart your computer for all changes to take effect." -ForegroundColor Yellow
Write-Host "From now on, ANY admin action will ask for your generic 'Charles' password." -ForegroundColor Magenta
