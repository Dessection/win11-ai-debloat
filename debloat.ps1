<#
.SYNOPSIS
    Ultimate Windows 11 Privacy, AI & Telemetry Debloat Script.
.DESCRIPTION
    Comprehensive, idempotent PowerShell script designed to disable all intrusive Windows AI 
    features (Recall, Copilot, Click to Do), telemetry services, background diagnostics, 
    MSN Widgets feeds, Bing search integration in Start, Explorer ads, and scheduled data collection tasks.
    
    Includes native support for Windows 11 24H2 / 26H2 and Copilot+ PCs (AMD Ryzen AI, Intel Core Ultra, Snapdragon X).
.NOTES
    Requires Administrator privileges (automatically self-elevates if run as standard user).
#>

# ------------------------------------------------------------------------------
# 0. PRIVILEGE CHECK & AUTO-ELEVATION
# ------------------------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Administrative privileges required. Requesting elevation (UAC)..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"")
    exit
}

Clear-Host
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  WINDOWS 11 ULTIMATE PRIVACY, AI & TELEMETRY DEBLOAT SCRIPT" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = 'SilentlyContinue'

# Helper function for idempotent registry writes
function Set-RegValue {
    param (
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWord"
    )
    if (!(Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force | Out-Null
}

# ------------------------------------------------------------------------------
# 1. WINDOWS AI, RECALL, CLICK TO DO & COPILOT
# ------------------------------------------------------------------------------
Write-Host "[1/8] Disabling Windows AI, Recall, Click to Do & Copilot..." -ForegroundColor Green

# Machine Policy for Windows AI and Recall
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "TurnOffRecall" 1

# Current User Policy for Windows AI and Recall
Set-RegValue "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
Set-RegValue "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "TurnOffRecall" 1

# Machine and User Policy for Windows Copilot
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
Set-RegValue "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1

# Hide Copilot taskbar button
Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCopilotButton" 0

# Stop and disable Windows AI Fabric service
Get-Service -Name WSAIFabricSvc | Stop-Service -Force -ErrorAction SilentlyContinue
Set-Service -Name WSAIFabricSvc -StartupType Disabled -ErrorAction SilentlyContinue

# Uninstall Recall as an Optional Windows Feature (if present)
Disable-WindowsOptionalFeature -Online -FeatureName "Recall" -NoRestart -ErrorAction SilentlyContinue | Out-Null

# ------------------------------------------------------------------------------
# 2. TELEMETRY & DIAGNOSTIC SERVICES
# ------------------------------------------------------------------------------
Write-Host "[2/8] Stopping and disabling telemetry & diagnostic background services..." -ForegroundColor Green

$servicesToDisable = @(
    "DiagTrack",                                 # Connected User Experiences and Telemetry
    "dmwappushservice",                          # WAP Push Service for routing telemetry
    "diagnosticshub.standardcollector.service",     # Diagnostics Hub Standard Collector
    "WerSvc",                                    # Windows Error Reporting Service
    "RetailDemo"                                 # Retail Demo Service
)

foreach ($svc in $servicesToDisable) {
    Get-Service -Name $svc | Stop-Service -Force -ErrorAction SilentlyContinue
    Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------------------------
# 3. GROUP POLICIES FOR TELEMETRY & CONSUMER EXPERIENCES
# ------------------------------------------------------------------------------
Write-Host "[3/8] Enforcing privacy, telemetry & consumer policies via Group Policy..." -ForegroundColor Green

# Set Telemetry level to 0 (Security / Minimum) and suppress feedback popups
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "DoNotShowFeedbackNotifications" 1
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "MaxTelemetryAllowed" 0

# Disable preinstalled consumer apps and silent background app installations
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableCloudOptimizedContent" 1

# Disable Advertising ID
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" 1
Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0

# Disable Tailored Experiences using diagnostic data
Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 0

# Disable feedback query frequency (SIUF)
Set-RegValue "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" 0

# Set Delivery Optimization to HTTP only (no P2P upload to other internet PCs)
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" 0

# Disable background GameDVR telemetry
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0

# ------------------------------------------------------------------------------
# 4. WIDGETS & MSN FEED
# ------------------------------------------------------------------------------
Write-Host "[4/8] Disabling Widgets and terminating background feed processes..." -ForegroundColor Green

# Block Widgets via machine policy
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0

# Hide Widgets icon from taskbar
Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" 0

# Terminate active widget background processes
Stop-Process -Name "WidgetBoard", "WidgetService" -Force -ErrorAction SilentlyContinue

# ------------------------------------------------------------------------------
# 5. START MENU, BING SEARCH & EXPLORER RECOMMENDATIONS
# ------------------------------------------------------------------------------
Write-Host "[5/8] Removing Bing web search from Start menu & disabling suggestions..." -ForegroundColor Green

# Disable Bing web search in Start menu via Group Policy
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "ConnectedSearchUseWeb" 0
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" 1
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0

# Disable search box suggestions & hide "Recommended" section in Start
Set-RegValue "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 1
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "HideRecommendedSection" 1

# Disable Bing web integration for current user
Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "SearchHighlightsEnabled" 0
Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" "IsBingSearchEnabled" 0

# Disable app recommendations, promotional toasts & account notifications in Start
Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_IrisRecommendations" 0
Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_AccountNotifications" 0
Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowSyncProviderNotifications" 0

# Disable tips, welcome experiences & suggestions (ContentDeliveryManager)
$cdmPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
Set-RegValue $cdmPath "ContentDeliveryAllowed" 0
Set-RegValue $cdmPath "FeatureManagementEnabled" 0
Set-RegValue $cdmPath "PreInstalledAppsEnabled" 0
Set-RegValue $cdmPath "PreInstalledAppsEverEnabled" 0
Set-RegValue $cdmPath "OemPreInstalledAppsEnabled" 0
Set-RegValue $cdmPath "SilentInstalledAppsEnabled" 0
Set-RegValue $cdmPath "RotatingLockScreenEnabled" 0
Set-RegValue $cdmPath "RotatingLockScreenOverlayEnabled" 0
Set-RegValue $cdmPath "SoftLandingEnabled" 0
Set-RegValue $cdmPath "SystemPaneSuggestionsEnabled" 0
Set-RegValue $cdmPath "SubscribedContent-310093Enabled" 0 # Welcome experience
Set-RegValue $cdmPath "SubscribedContent-338387Enabled" 0
Set-RegValue $cdmPath "SubscribedContent-338388Enabled" 0
Set-RegValue $cdmPath "SubscribedContent-338389Enabled" 0
Set-RegValue $cdmPath "SubscribedContent-338393Enabled" 0 # Settings recommendations
Set-RegValue $cdmPath "SubscribedContent-353694Enabled" 0
Set-RegValue $cdmPath "SubscribedContent-353696Enabled" 0
Set-RegValue $cdmPath "SubscribedContent-353698Enabled" 0

# ------------------------------------------------------------------------------
# 6. SCHEDULED TASKS FOR TELEMETRY & DIAGNOSTICS
# ------------------------------------------------------------------------------
Write-Host "[6/8] Disabling scheduled telemetry, flighting & diagnostic tasks..." -ForegroundColor Green

$tasksToDisable = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp",
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Application Experience\StartupAppTask",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver",
    "\Microsoft\Windows\Feedback\Siuf\DmClient",
    "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload",
    "\Microsoft\Windows\Flighting\FeatureConfig\BootstrapUsageDataReporting",
    "\Microsoft\Windows\Flighting\FeatureConfig\GovernedFeatureUsageProcessing",
    "\Microsoft\Windows\Flighting\FeatureConfig\ReconcileConfigs",
    "\Microsoft\Windows\Flighting\FeatureConfig\ReconcileFeatures",
    "\Microsoft\Windows\Flighting\FeatureConfig\SafeguardsReconciliation",
    "\Microsoft\Windows\Flighting\FeatureConfig\UsageDataFlushing",
    "\Microsoft\Windows\Flighting\FeatureConfig\UsageDataReceiver",
    "\Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting",
    "\Microsoft\Windows\Flighting\FlightReset\ResetFlightData",
    "\Microsoft\Windows\Flighting\OneSettings\RefreshCache",
    "\Microsoft\Windows\Sustainability\SustainabilityTelemetry",
    "\Microsoft\Windows\Device Information\Device",
    "\Microsoft\Windows\Device Information\Device User",
    "\Microsoft\Windows\DiskFootprint\Diagnostics",
    "\Microsoft\Windows\PerformanceTrace\ShowFeedbackToast",
    "\Microsoft\Windows\Maps\MapsToastTask",
    "\Microsoft\Windows\Maps\MapsUpdateTask",
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
)

foreach ($t in $tasksToDisable) {
    $path = $t.Substring(0, $t.LastIndexOf('\') + 1)
    $name = $t.Substring($t.LastIndexOf('\') + 1)
    Disable-ScheduledTask -TaskName $name -TaskPath $path -ErrorAction SilentlyContinue | Out-Null
}

# ------------------------------------------------------------------------------
# 7. MICROSOFT EDGE PRIVACY & COPILOT LOCKDOWN
# ------------------------------------------------------------------------------
Write-Host "[7/8] Disabling Copilot and telemetry in Microsoft Edge..." -ForegroundColor Green

$edgePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
Set-RegValue $edgePolicy "HubsSidebarEnabled" 0
Set-RegValue $edgePolicy "CopilotPageContext" 0
Set-RegValue $edgePolicy "ComposeInlineEnabled" 0
Set-RegValue $edgePolicy "DiagnosticData" 0
Set-RegValue $edgePolicy "UserFeedbackAllowed" 0
Set-RegValue $edgePolicy "PersonalizationReportingEnabled" 0
Set-RegValue $edgePolicy "ShowRecommendationsEnabled" 0
Set-RegValue $edgePolicy "ConfigureDoNotTrack" 1
Set-RegValue $edgePolicy "AlternateErrorPagesEnabled" 0
Set-RegValue $edgePolicy "EdgeCollectionsEnabled" 0
Set-RegValue $edgePolicy "EdgeShoppingAssistantEnabled" 0
Set-RegValue $edgePolicy "MicrosoftEdgeInsiderPromotionEnabled" 0
Set-RegValue $edgePolicy "ShowMicrosoftRewards" 0
Set-RegValue $edgePolicy "WebWidgetAllowed" 0
Set-RegValue $edgePolicy "EdgeAssetDeliveryServiceEnabled" 0
Set-RegValue $edgePolicy "WalletDonationEnabled" 0
Set-RegValue $edgePolicy "HideFirstRunExperience" 1

# ------------------------------------------------------------------------------
# 8. REFRESH EXPLORER SHELL
# ------------------------------------------------------------------------------
Write-Host "[8/8] Restarting Windows Explorer to apply interface changes..." -ForegroundColor Green
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host " COMPLETE! ALL AI, TELEMETRY & TRACKING FEATURES ARE DISABLED." -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "Press any key to exit..." -ForegroundColor Gray
[System.Console]::ReadKey() | Out-Null
