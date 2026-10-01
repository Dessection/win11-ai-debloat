<#
.SYNOPSIS
    Restores Windows 11 default privacy, AI, and telemetry settings.
.DESCRIPTION
    Reverts changes made by debloat.ps1 by re-enabling telemetry services, 
    scheduled tasks, and removing restrictive Group Policies.
.NOTES
    Requires Administrator privileges (automatically self-elevates if run as standard user).
#>

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Administrative privileges required. Requesting elevation (UAC)..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"")
    exit
}

Clear-Host
Write-Host "====================================================================" -ForegroundColor Yellow
Write-Host "  REVERTING PRIVACY & AI POLICIES TO WINDOWS DEFAULTS" -ForegroundColor Yellow
Write-Host "====================================================================" -ForegroundColor Yellow
Write-Host ""

$ErrorActionPreference = 'SilentlyContinue'

function Remove-RegPropertySafe {
    param ([string]$Path, [string]$Name)
    if (Test-Path $Path) {
        Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

# 1. Re-enable AI & Copilot policies
Write-Host "[1/6] Restoring Windows AI & Copilot policies..." -ForegroundColor Cyan
Remove-RegPropertySafe "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis"
Remove-RegPropertySafe "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "TurnOffRecall"
Remove-RegPropertySafe "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis"
Remove-RegPropertySafe "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "TurnOffRecall"
Remove-RegPropertySafe "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot"
Remove-RegPropertySafe "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot"
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value 1 -ErrorAction SilentlyContinue

# 2. Re-enable Services
Write-Host "[2/6] Restoring background services..." -ForegroundColor Cyan
Set-Service -Name DiagTrack -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service -Name DiagTrack -ErrorAction SilentlyContinue
Set-Service -Name dmwappushservice -StartupType Manual -ErrorAction SilentlyContinue
Set-Service -Name WerSvc -StartupType Manual -ErrorAction SilentlyContinue

# 3. Restore DataCollection & Consumer Policies
Write-Host "[3/6] Restoring DataCollection & CloudContent policies..." -ForegroundColor Cyan
Remove-RegPropertySafe "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry"
Remove-RegPropertySafe "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "DoNotShowFeedbackNotifications"
Remove-RegPropertySafe "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures"
Remove-RegPropertySafe "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy"
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 1 -ErrorAction SilentlyContinue

# 4. Restore Widgets
Write-Host "[4/6] Restoring Widgets..." -ForegroundColor Cyan
Remove-RegPropertySafe "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests"
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 1 -ErrorAction SilentlyContinue

# 5. Restore Search & Explorer
Write-Host "[5/6] Restoring Search & Start Menu suggestions..." -ForegroundColor Cyan
Remove-RegPropertySafe "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "ConnectedSearchUseWeb"
Remove-RegPropertySafe "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch"
Remove-RegPropertySafe "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions"
Remove-RegPropertySafe "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "HideRecommendedSection"
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 1 -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchHighlightsEnabled" -Value 1 -ErrorAction SilentlyContinue

# 6. Re-enable Scheduled Tasks
Write-Host "[6/6] Re-enabling scheduled tasks..." -ForegroundColor Cyan
$tasksToEnable = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Sustainability\SustainabilityTelemetry",
    "\Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting"
)
foreach ($t in $tasksToEnable) {
    $path = $t.Substring(0, $t.LastIndexOf('\') + 1)
    $name = $t.Substring($t.LastIndexOf('\') + 1)
    Enable-ScheduledTask -TaskName $name -TaskPath $path -ErrorAction SilentlyContinue | Out-Null
}

Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host " REVERT COMPLETE. WINDOWS DEFAULT BEHAVIOR RESTORED." -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "Press any key to exit..." -ForegroundColor Gray
[System.Console]::ReadKey() | Out-Null
