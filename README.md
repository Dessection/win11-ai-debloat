# Windows 11 Ultimate Privacy, AI & Telemetry Debloat

[![PowerShell](https://img.shields.io/badge/PowerShell-%E2%89%A5%205.1-blue.svg)](https://microsoft.com/powershell)
[![Windows 11](https://img.shields.io/badge/Windows%2011-24H2%20%7C%2026H2-0078D6.svg)](https://microsoft.com/windows)
[![Copilot+ PC Ready](https://img.shields.io/badge/Hardware-Copilot%2B%20%26%20NPU%20Ready-success.svg)](#copilot-pc--npu-hardware-support)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A clean, safe, and fully idempotent PowerShell script designed to disable all intrusive Windows AI components (**Windows Recall**, **Click to Do**, **Copilot**), diagnostic telemetry services, background MSN news feeds, Start menu Bing integration, and scheduled data collection tasks on Windows 11.

---

## 🎯 Why This Project?

Starting with **Windows 11 24H2 and 26H2**, Microsoft introduced deep neural engine and AI integration into the Windows kernel, specifically targeting **Copilot+ PCs** equipped with dedicated NPUs (AMD Ryzen AI 300, Snapdragon X Elite/Plus, Intel Core Ultra 200). 

After major feature updates, Windows often automatically:
1. Re-enables or deploys new background telemetry tasks (e.g., `Microsoft Compatibility Appraiser Exp`, `SustainabilityTelemetry`).
2. Activates proactive local AI caching and screen indexing (`WindowsAI\ClickToDo`, `Recall`).
3. Keeps Widgets processes (`WidgetBoard.exe`, `WidgetService.exe`) active in memory downloading MSN feeds even when the taskbar widget icon is hidden.
4. Pushes web search results and search highlights (Bing trending searches) into your local Start menu.

This project provides a single, verifiable, and 100% reversible script to lock down privacy and eliminate background bloat without breaking Windows Update, system drivers, or gaming performance.

---

## 🛡️ What Gets Disabled?

### 1. Windows AI & Copilot+ PC Features
* **Windows Recall**: Disabled via machine and user Group Policy (`DisableAIDataAnalysis = 1`, `TurnOffRecall = 1`). Also uninstalls the Recall optional component package.
* **Click to Do**: Terminates active context screen caching and prevents NPU background indexing.
* **Windows Copilot**: Completely blocked via Group Policy (`TurnOffWindowsCopilot = 1`) and taskbar button removed.
* **AI Fabric Subsystem**: Disables the `WSAIFabricSvc` system service.

### 2. Telemetry & Diagnostic Services
* **DiagTrack** (*Connected User Experiences and Telemetry*): Set to Disabled & stopped.
* **dmwappushservice** (*WAP Push Routing Service*): Set to Disabled & stopped.
* **diagnosticshub.standardcollector.service**: Set to Disabled & stopped.
* **WerSvc** (*Windows Error Reporting*): Set to Disabled & stopped.
* **DataCollection Policy**: Telemetry level set to `0` (Security / Minimum).

### 3. Start Menu & Windows Search
* **Bing Web Search**: Prevents Start menu searches from sending queries to Microsoft Bing servers (`DisableWebSearch = 1`, `ConnectedSearchUseWeb = 0`).
* **Search Highlights**: Removes daily Bing doodles and trending web topics from the search box.
* **Start Menu Ads**: Disables "Recommended" promotions, account notifications, and suggested app installations (`DisableWindowsConsumerFeatures = 1`).

### 4. Windows Widgets & Background MSN Feeds
* **Widgets Engine**: Completely blocked via Group Policy (`AllowNewsAndInterests = 0` under `HKLM\SOFTWARE\Policies\Microsoft\Dsh`).
* **Memory Optimization**: Terminates running `WidgetBoard.exe` and `WidgetService.exe` processes (frees up 100–250 MB RAM).
* **Taskbar Clean-up**: Hides the widget taskbar toggle.

### 5. Scheduled Telemetry Tasks (27 Tasks Cleaned)
Disables newly added and legacy diagnostic tasks, including:
* `\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp` (new in recent updates)
* `\Microsoft\Windows\Sustainability\SustainabilityTelemetry` (energy and carbon reporting)
* `\Microsoft\Windows\Flighting\FeatureConfig\*` (all feature A/B testing & usage data flushing tasks)
* `\Microsoft\Windows\Customer Experience Improvement Program\*` (`Consolidator`, `UsbCeip`)
* `\Microsoft\Windows\Feedback\Siuf\*` (`DmClient` feedback queries)
* `\Microsoft\Windows\Device Information\*` and `DiskFootprint\Diagnostics`

### 6. Microsoft Edge AI & Tracking
* Disables Copilot sidebar button (`HubsSidebarEnabled = 0`).
* Disables Edge Copilot reading webpage context (`CopilotPageContext = 0`).
* Disables inline text rewrite assistant (`ComposeInlineEnabled = 0`).
* Enforces `DoNotTrack`, disables shopping assistant, rewards promotions, and edge diagnostic reporting.

---

## 🚀 Quick Start

### Option 1: Run directly in PowerShell (Administrator)

Open **PowerShell** or **Windows Terminal** as Administrator and run:

```powershell
irm https://raw.githubusercontent.com/YOUR_USERNAME/win11-ai-debloat/main/debloat.ps1 | iex
```
*(Replace `YOUR_USERNAME` with your GitHub username once published).*

### Option 2: Clone and Run Locally

1. Clone the repository:
   ```powershell
   git clone https://github.com/YOUR_USERNAME/win11-ai-debloat.git
   cd win11-ai-debloat
   ```
2. Run the script:
   ```powershell
   .\debloat.ps1
   ```

> [!NOTE]
> The script includes **Auto-Elevation**. If you run it without administrator privileges, it will automatically prompt you with a standard Windows UAC confirmation dialog and relaunch itself elevated.

---

## 🔄 How to Revert

If you ever wish to restore Windows defaults (e.g. re-enable Copilot or default diagnostic data), simply run:

```powershell
.\revert.ps1
```

All modifications use standard Microsoft Group Policy keys and service startup parameters—nothing is permanently modified or destroyed.

---

## 💻 Hardware & OS Compatibility

| Operating System | Compatibility |
| :--- | :--- |
| **Windows 11 26H2** | Full Support |
| **Windows 11 24H2** | Full Support |
| **Windows 11 23H2 / 22H2** | Full Support |
| **Copilot+ PCs (AMD Ryzen AI 300 / Intel Lunar Lake / Snapdragon X)** | Optimized |

---

## 📜 License

This project is licensed under the [MIT License](LICENSE) - free to use, modify, and distribute.
