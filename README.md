# 📡 Network Radar Dashboard

**Network Radar** is a portable, single-file **Network Monitoring & Management Dashboard** built entirely with PowerShell. It enables IT administrators to visualize network status, monitor latency, and access devices instantly without any installation or third-party agents.

![Dashboard Screenshot](screenshot.png)

## 🚀 Features

* **⚡ Ultra-Fast Scanning:** Multi-threaded engine that scans hundreds of IPs and ports in seconds.
* **🟢 Live Visualization:** Features a "Pulse" (Breathing) animation for online devices to indicate real-time status.
* **🖱️ Action-Oriented:**
    * **One-Click RDP:** Generates and downloads `.rdp` connection files instantly.
    * **Web Access:** Quick links to HTTP/HTTPS management interfaces.
* **🎨 Smart Categorization:** Automatically highlights **Servers** (Purple) and **Printers** (Orange) based on naming conventions.
* **⚡ Latency Monitor:** Detects and visually alerts for high ping latency (>100ms).
* **📱 Mobile Ready:** Fully responsive design that works seamlessly on mobile phones and tablets.
* **🔍 Advanced Filtering:** Focus modes for Online, Offline, or specific device groups.

## 🛠️ Requirements

* Windows OS (Windows 10/11 or Server 2016+).
* PowerShell 5.1 or later.
* **No installation, No Database, and No RSAT required.**

## 📦 How to Use

1.  Download the `Network-Radar-Dashboard.ps1` script from this repository.
2.  Open the file with a text editor (Notepad or VS Code).
3.  **Customize** the `$CustomNames` and `$TargetSubnets` sections to match your network environment:

    ```powershell
    # Example Configuration:
    $TargetSubnets = @("192.168.1.", "10.0.0.") 
    
    $CustomNames = @{
        "192.168.1.1"  = "Gateway"
        "192.168.1.10" = "File Server"
    }
    ```
4.  Run PowerShell as Administrator.
5.  Execute the script:
    ```powershell
    .\Network-Radar-Dashboard.ps1
    ```
6.  The dashboard will automatically open in your default browser.

## 📷 Dashboard Details

The tool generates a standalone HTML5 report with a modern dark interface:
* **Top Stats:** Real-time summary of Total, Online, and Offline devices.
* **Critical Infrastructure:** Dedicated section for high-priority servers (DNS, DC, FW).
* **Interactive Cards:** Click on any device to see open ports (21, 22, 80, 443, 3389) and access management options.

## 📝 License

This project is open-source and available under the **MIT License**.

**Author:** [Kasim Aytan](https://github.com/aytan53)
