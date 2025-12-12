# =============================================================================
# Proje: AĞ RADARI
# Geliştirici: Kasım Aytan
# =============================================================================

# --- 0. LOGLAMA SİSTEMİ ---
$LogPath = "$([Environment]::GetFolderPath('Desktop'))\AgRadari_Log.txt"
function Write-Log {
    param([string]$Msg, [string]$Level="BİLGİ")
    $Timestamp = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
    try { Add-Content -Path $LogPath -Value "[$Timestamp] [$Level] $Msg" -Encoding UTF8 -ErrorAction SilentlyContinue } catch {}
    switch ($Level) { "HATA" { Write-Host $Msg -ForegroundColor Red } default { Write-Host $Msg -ForegroundColor Cyan } }
}

try { if (Test-Path $LogPath) { Remove-Item $LogPath -ErrorAction SilentlyContinue } } catch {}
Write-Log "Ağ Radarı Başlatılıyor..."

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    $ErrorActionPreference = "Stop"

    # --- 1. AYARLAR & LİSTELER (TEMİZLENMİŞ) ---
    $CustomNames = @{
        "192.168.1.1"   = "Gateway / Modem"
        "192.168.1.10"  = "File Server (Dosya Sunucusu)"
        "192.168.1.20"  = "Yazıcı - Muhasebe"
        "192.168.1.30"  = "IT Yönetici PC"
        "192.168.1.50"  = "Kamera Kayıt Cihazı (NVR)"
        "192.168.1.100" = "Misafir Ağı Access Point"
    }

    $CriticalTargets = @(
        @{ Name="Google DNS";          IP="8.8.8.8" },
        @{ Name="Gateway / Modem";     IP="192.168.1.1" },
        @{ Name="Local DNS";           IP="192.168.1.2" },
        @{ Name="File Server";         IP="192.168.1.10" }
    )

    $TargetSubnets = @("192.168.1.")
    $MaxThreads = 40
    $PingTimeout = 250
    $PortTimeout = 150

    Write-Log "Ayarlar yüklendi. Hızlı erişim butonları hazırlanıyor..."

    # --- NAVIGASYON ---
    $NavButtonsHTML = "<a href='#sec-monitor' class='nav-btn critical'><i class='fa-solid fa-heart-pulse'></i> Kritik Sistemler</a>"
    foreach ($Subnet in $TargetSubnets) {
        $LinkId = $Subnet.Replace(".", "-")
        $NavButtonsHTML += "<a href='#sec-$LinkId' class='nav-btn'><i class='fa-solid fa-network-wired'></i> $Subnet" + "0/24</a>"
    }

    Write-Log "Rapor arayüzü oluşturuluyor..."

    # --- HTML ŞABLON ---
    $HtmlContent = @"
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Ağ Radarı</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        :root { --bg: #0f172a; --card: #1e293b; --text: #f8fafc; --green: #22c55e; --gray: #334155; --blue: #3b82f6; --red: #ef4444; --orange: #f59e0b; --nav-bg: #1e293b; --border: #334155; --purple: #a855f7; }
        .light-theme { --bg: #f8fafc; --card: #ffffff; --text: #0f172a; --gray: #e2e8f0; --nav-bg: #ffffff; --border: #cbd5e1; }
        html { scroll-behavior: smooth; }
        body { background-color: var(--bg); color: var(--text); font-family: 'Inter', sans-serif; margin: 0; padding: 0; transition: 0.3s; }
        
        @keyframes pulse { 0% { box-shadow: 0 0 0 0 rgba(34, 197, 94, 0.7); } 70% { box-shadow: 0 0 0 5px rgba(34, 197, 94, 0); } 100% { box-shadow: 0 0 0 0 rgba(34, 197, 94, 0); } }
        @keyframes flash-orange { 0% { opacity: 1; } 50% { opacity: 0.5; } 100% { opacity: 1; } }

        /* HEADER */
        .app-header { position: sticky; top: 0; z-index: 1000; background: var(--nav-bg); border-bottom: 1px solid var(--border); box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        .main-navbar { padding: 5px 20px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border); flex-wrap: wrap; }
        .brand-wrapper { display: flex; align-items: center; gap: 8px; }
        .logo-icon { font-size: 1.2rem; color: #38bdf8; filter: drop-shadow(0 0 3px rgba(56,189,248,0.5)); }
        .brand-text { display: flex; flex-direction: column; justify-content: center; }
        .app-name { font-size: 1rem; font-weight: 800; letter-spacing: -0.3px; line-height: 1; color: #38bdf8; }
        .dev-name { font-size: 0.6rem; color: #94a3b8; letter-spacing: 0.5px; font-weight: 600; margin-top: 1px; }
        
        .search-area { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
        .search-box { position: relative; width: 220px; }
        .search-input { width: 100%; background: var(--bg); border: 1px solid var(--border); padding: 5px 10px 5px 30px; border-radius: 4px; color: var(--text); font-size: 0.75rem; transition: 0.3s; }
        .search-input:focus { border-color: #38bdf8; outline: none; }
        .search-icon { position: absolute; left: 8px; top: 50%; transform: translateY(-50%); color: #94a3b8; font-size: 0.7rem; }
        
        .filter-btn { background: transparent; border: 1px solid var(--border); color: #94a3b8; padding: 5px 10px; border-radius: 4px; font-size: 0.7rem; cursor: pointer; transition: 0.2s; font-weight: 600; }
        .filter-btn:hover { color: var(--text); border-color: #64748b; }
        .filter-btn.active { background: var(--blue); color: white; border-color: var(--blue); }

        .nav-actions { display: flex; gap: 8px; }
        .action-btn { background: transparent; border: 1px solid var(--border); color: var(--text); padding: 4px 10px; border-radius: 4px; cursor: pointer; font-size: 0.7rem; display: flex; align-items: center; gap: 5px; font-weight: 600; transition: 0.2s; }
        .action-btn:hover { background: var(--blue); color: white; border-color: var(--blue); }

        .sub-navbar { padding: 5px 20px; display: flex; align-items: center; gap: 8px; overflow-x: auto; white-space: nowrap; background: rgba(0,0,0,0.02); }
        .sub-navbar::-webkit-scrollbar { height: 0px; }
        .nav-btn { background: var(--card); color: var(--text); text-decoration: none; padding: 4px 10px; border-radius: 4px; font-size: 0.7rem; font-weight: 600; border: 1px solid var(--border); transition: 0.2s; display: flex; align-items: center; gap: 5px; }
        .nav-btn:hover { background: var(--blue); color: white; border-color: var(--blue); transform: translateY(-1px); }
        .nav-btn.critical { border-color: var(--orange); color: var(--orange); background: rgba(245, 158, 11, 0.1); }
        .nav-btn.critical:hover { background: var(--orange); color: white; }

        .stats-bar { display: flex; gap: 10px; padding: 10px 20px; border-bottom: 1px solid var(--border); background: var(--bg); flex-wrap: wrap; }
        .stat-item { background: var(--card); padding: 5px 12px; border-radius: 5px; border: 1px solid var(--border); display: flex; align-items: center; gap: 8px; flex: 1; min-width: 120px; box-shadow: 0 2px 3px rgba(0,0,0,0.05); }
        .stat-icon { font-size: 1.1rem; opacity: 0.9; }
        .stat-info div:first-child { font-size: 0.6rem; color: #94a3b8; text-transform: uppercase; font-weight: 700; }
        .stat-info div:last-child { font-size: 1rem; font-weight: 800; color: var(--text); }

        .container { padding: 15px 20px; max-width: 1800px; margin: 0 auto; }
        
        .monitor-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 8px; margin-bottom: 30px; }
        .mon-card { background: var(--card); border: 1px solid var(--border); border-radius: 5px; padding: 8px; position: relative; overflow: hidden; transition: 0.2s; }
        .mon-card:hover { transform: translateY(-2px); box-shadow: 0 5px 10px rgba(0,0,0,0.1); }
        .mon-card.up { border-bottom: 2px solid var(--green); }
        .mon-card.down { border-bottom: 2px solid var(--red); }
        .mon-name { font-size: 0.65rem; color: #94a3b8; font-weight: 700; text-transform: uppercase; margin-bottom: 2px; }
        .mon-val { font-size: 1rem; font-weight: 800; color: var(--text); }
        .mon-ip { font-size: 0.65rem; color: #64748b; font-family: monospace; margin-top: 1px; }
        .mon-icon { position: absolute; right: 8px; top: 8px; font-size: 1rem; opacity: 0.8; }
        
        /* FİLTRE BARI */
        .filter-bar { display: flex; align-items: center; justify-content: center; gap: 10px; margin-bottom: 30px; padding: 8px; background: rgba(0,0,0,0.1); border-radius: 6px; border: 1px solid var(--border); flex-wrap: wrap; }
        .filter-label { font-size: 0.7rem; font-weight: 700; color: #94a3b8; margin-right: 5px; }

        .subnet-section { margin-bottom: 40px; scroll-margin-top: 130px; }
        .subnet-header { display: flex; align-items: center; justify-content: flex-start; gap: 12px; margin-bottom: 10px; border-bottom: 1px solid var(--border); padding-bottom: 6px; }
        .subnet-title { font-size: 1.1rem; font-weight: 700; color: var(--text); display: flex; align-items: center; gap: 8px; }
        .badge { background: var(--blue); font-size: 0.65rem; padding: 2px 8px; border-radius: 10px; color: white; font-weight: 600; }

        .grid-container { display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: 6px; }
        .ip-card { background: var(--card); border: 1px solid var(--border); border-radius: 5px; padding: 8px; text-align: center; transition: 0.2s; position: relative; overflow: hidden; cursor: default; }
        .ip-card:hover { transform: translateY(-2px); border-color: #38bdf8; z-index: 10; box-shadow: 0 5px 8px -2px rgba(0,0,0,0.15); }
        .ip-card.online { cursor: pointer; border-top: 2px solid var(--green); background: linear-gradient(180deg, rgba(34,197,94,0.02) 0%, var(--card) 100%); }
        .ip-card.offline { opacity: 0.5; border-top: 2px solid var(--gray); }
        
        .ip-card.cat-server { border-top: 3px solid #a855f7 !important; background: linear-gradient(180deg, rgba(168, 85, 247, 0.05) 0%, var(--card) 100%); }
        .ip-card.cat-printer { border-top: 3px solid #f97316 !important; background: linear-gradient(180deg, rgba(249, 115, 22, 0.05) 0%, var(--card) 100%); }

        .ip-addr { font-size: 0.85rem; font-weight: 700; margin-bottom: 2px; color: var(--text); display: flex; justify-content: center; align-items: center; gap: 6px; }
        .host-name { font-size: 0.65rem; color: #94a3b8; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; height: 12px; font-weight: 500; }
        
        /* GÜNCELLENEN NOKTA (DOT) STİLİ */
        .status-dot { height: 8px; width: 8px; border-radius: 50%; display: inline-block; flex-shrink: 0; }
        .online .status-dot { background: var(--green); box-shadow: 0 0 6px var(--green); animation: pulse 2s infinite; }
        .offline .status-dot { background: transparent; border: 2px solid #475569; opacity: 0.6; }
        
        .ping-badge { font-size: 0.6rem; padding: 1px 4px; border-radius: 3px; font-weight: normal; margin-left: 3px; background: rgba(0,0,0,0.2); }
        .ping-high { color: #f59e0b; animation: flash-orange 2s infinite; font-weight: 700; }
        .ping-ok { color: #4ade80; opacity: 0.8; }

        .card-badges { margin-top: 4px; display: flex; justify-content: center; gap: 2px; height: 14px; }
        .port-icon { font-size: 0.6rem; padding: 1px 3px; border-radius: 2px; color: #fff; background: #334155; }
        .p-rdp { background: #f59e0b; } .p-web { background: #3b82f6; } .p-ssh { background: #8b5cf6; } 

        .modal-overlay { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.8); display: none; justify-content: center; align-items: center; z-index: 2000; backdrop-filter: blur(4px); }
        .modal-content { background: var(--card); border: 1px solid var(--border); width: 400px; padding: 25px; border-radius: 12px; box-shadow: 0 20px 40px rgba(0, 0, 0, 0.5); animation: popIn 0.2s cubic-bezier(0.175, 0.885, 0.32, 1.275); color: var(--text); }
        @keyframes popIn { from {transform: scale(0.9); opacity: 0;} to {transform: scale(1); opacity: 1;} }
        .m-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; border-bottom: 1px solid var(--border); padding-bottom: 10px; }
        .m-title { font-size: 1.4rem; font-weight: 800; letter-spacing: -0.5px; }
        .m-close { cursor: pointer; color: #94a3b8; font-size: 1.2rem; transition: 0.2s; } .m-close:hover { color: var(--text); transform: rotate(90deg); }
        .m-row { display: flex; justify-content: space-between; margin-bottom: 10px; font-size: 0.85rem; border-bottom: 1px solid rgba(255,255,255,0.05); padding-bottom: 5px; }
        .m-label { color: #94a3b8; } .m-val { font-weight: 600; text-align: right; }
        
        .modal-actions { display: flex; gap: 10px; margin-top: 20px; border-top: 1px solid var(--border); padding-top: 15px; }
        .modal-btn { flex: 1; padding: 8px; border-radius: 6px; border: 1px solid var(--border); background: var(--bg); color: var(--text); font-size: 0.8rem; cursor: pointer; font-weight: 600; display: flex; align-items: center; justify-content: center; gap: 8px; transition: 0.2s; }
        .modal-btn:hover { background: var(--blue); color: white; border-color: var(--blue); }
        .modal-btn.rdp:hover { background: #f59e0b; border-color: #f59e0b; }
        .modal-btn.web:hover { background: #10b981; border-color: #10b981; }

        .port-tag { padding: 4px 8px; border-radius: 4px; font-size: 0.75rem; background: #334155; color: white; display: flex; align-items: center; gap: 5px; margin-right: 5px; margin-bottom: 5px; display: inline-flex; }
        .tag-open { background: rgba(34, 197, 94, 0.15); color: #4ade80; border: 1px solid rgba(34, 197, 94, 0.3); }
        .tag-closed { opacity: 0.5; font-style: italic; }
        .footer { margin-top: 40px; text-align: center; font-size: 0.65rem; color: #64748b; padding-bottom: 30px; border-top: 1px solid var(--border); padding-top: 15px; }

        @media (max-width: 768px) {
            .main-navbar { flex-direction: column; gap: 10px; padding: 10px; align-items: flex-start; }
            .brand-wrapper { width: 100%; justify-content: center; }
            .search-area { width: 100%; flex-direction: column; }
            .search-box { width: 100%; }
            .filter-btn { width: 100%; text-align: center; }
            .nav-actions { width: 100%; justify-content: center; margin-top: 5px; }
            .stats-bar { grid-template-columns: repeat(2, 1fr); }
            .monitor-grid { grid-template-columns: repeat(auto-fit, minmax(130px, 1fr)); }
            .grid-container { grid-template-columns: repeat(auto-fill, minmax(120px, 1fr)); }
            .subnet-header { flex-direction: column; align-items: flex-start; }
        }
    </style>
</head>
<body>
    <div class="app-header">
        <div class="main-navbar">
            <div class="brand-wrapper">
                <i class="fa-solid fa-satellite-dish logo-icon"></i>
                <div class="brand-text">
                    <span class="app-name">AĞ RADARI</span>
                    <span class="dev-name">Geliştirici: Kasım Aytan</span>
                </div>
            </div>
            
            <div class="search-area">
                <div class="search-box">
                    <i class="fa-solid fa-magnifying-glass search-icon"></i>
                    <input type="text" class="search-input" id="searchInput" placeholder="Cihaz Ara..." onkeyup="filterGrid()">
                </div>
            </div>
            
            <div class="nav-actions">
                <button class="action-btn" onclick="toggleTheme()"><i class="fa-solid fa-moon"></i> Tema</button>
                <button class="action-btn" onclick="exportToCSV()"><i class="fa-solid fa-file-csv"></i> Excel</button>
            </div>
        </div>
        <div class="sub-navbar">$NavButtonsHTML</div>
    </div>

    <div class="stats-bar">
        <div class="stat-item"><i class="fa-solid fa-server stat-icon" style="color:#38bdf8"></i><div class="stat-info"><div>Toplam Cihaz</div><div id="totalCount">...</div></div></div>
        <div class="stat-item"><i class="fa-solid fa-circle-check stat-icon" style="color:#4ade80"></i><div class="stat-info"><div>Aktif (Online)</div><div id="onlineCount">...</div></div></div>
        <div class="stat-item"><i class="fa-solid fa-power-off stat-icon" style="color:#94a3b8"></i><div class="stat-info"><div>Pasif (Offline)</div><div id="offlineCount">...</div></div></div>
        <div class="stat-item"><i class="fa-solid fa-clock stat-icon" style="color:#f59e0b"></i><div class="stat-info"><div>Son Güncelleme</div><div id="scanTime">...</div></div></div>
    </div>

    <div class="container">
"@

    # --- 3. KRİTİK CİHAZLAR ---
    Write-Log "Kritik cihazlar taranıyor..."
    $HtmlContent += '<div id="sec-monitor" class="subnet-section"><div class="subnet-header"><div class="subnet-title"><i class="fa-solid fa-bolt" style="color:#f59e0b; margin-right:10px"></i>Kritik Altyapı</div></div><div class="monitor-grid">'
    foreach ($Item in $CriticalTargets) {
        $Ping = Test-Connection -ComputerName $Item.IP -Count 1 -Quiet
        if ($Ping) {
            $PingObj = Test-Connection -ComputerName $Item.IP -Count 1
            $HtmlContent += "<div class='mon-card up'><div class='mon-name'>$($Item.Name)</div><div class='mon-val'>$($PingObj.ResponseTime)ms</div><div class='mon-ip'>$($Item.IP)</div><i class='fa-solid fa-circle-check mon-icon' style='color:#4ade80'></i></div>"
        } else {
            $HtmlContent += "<div class='mon-card down'><div class='mon-name'>$($Item.Name)</div><div class='mon-val' style='color:#ef4444'>KAPALI</div><div class='mon-ip'>$($Item.IP)</div><i class='fa-solid fa-triangle-exclamation mon-icon' style='color:#ef4444'></i></div>"
        }
    }
    $HtmlContent += '</div></div>' 

    # --- FİLTRE BUTONLARI ---
    $HtmlContent += @"
    <div class="filter-bar">
        <span class="filter-label">GÖRÜNÜM FİLTRESİ:</span>
        <button class="filter-btn active" onclick="setFilter('all', this)">TÜM CİHAZLAR</button>
        <button class="filter-btn" onclick="setFilter('online', this)">SADECE ONLINE</button>
        <button class="filter-btn" onclick="setFilter('offline', this)">SADECE OFFLINE</button>
    </div>
"@

    # --- 4. SUBNET TARAMA ---
    Write-Log "Runspace havuzu başlatılıyor..."
    $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
    $RunspacePool.Open()
    
    $TotalDevices = 0
    $TotalOnline = 0
    
    foreach ($Subnet in $TargetSubnets) {
        $DisplaySubnet = "$($Subnet)0/24"
        $LinkId = $Subnet.Replace(".", "-")
        Write-Log "Taranıyor: $DisplaySubnet"
        
        $Tasks = @()
        for ($i = 1; $i -le 254; $i++) {
            $IP = "$Subnet$i"
            $ScriptBlock = {
                param($TargetIP, $PingTime, $PortTime, $CustomName)
                try {
                    $ResultObj = [PSCustomObject]@{ IP = $TargetIP; Status = $false; Name = ""; OpenPorts = @(); IsCustom = $false; Error = $null; PingMs = 0 }
                    
                    if ($CustomName) {
                        $ResultObj.Status = $true
                        $ResultObj.Name = $CustomName
                        $ResultObj.IsCustom = $true
                        $PortsToCheck = @(21, 22, 80, 443, 3389) 
                        foreach ($Port in $PortsToCheck) { try { $Tcp=New-Object System.Net.Sockets.TcpClient; $C=$Tcp.BeginConnect($TargetIP,$Port,$null,$null); if($C.AsyncWaitHandle.WaitOne(100,$false)){ $Tcp.EndConnect($C); $ResultObj.OpenPorts+=$Port }; $Tcp.Close() } catch {} }
                    } else {
                        $PingSender = New-Object System.Net.NetworkInformation.Ping
                        $Reply = $PingSender.Send($TargetIP, $PingTime)
                        if ($Reply.Status -eq "Success") {
                            $ResultObj.Status = $true
                            $ResultObj.PingMs = $Reply.RoundtripTime
                            try { $DnsTask=[System.Net.Dns]::GetHostEntryAsync($TargetIP); if($DnsTask.Wait(800)){ $ResultObj.Name=$DnsTask.Result.HostName } else { $ResultObj.Name="Bilinmiyor" } } catch { $ResultObj.Name="Bilinmiyor" }
                            $PortsToCheck = @(21, 22, 80, 443, 3389) 
                            foreach ($Port in $PortsToCheck) { try { $Tcp=New-Object System.Net.Sockets.TcpClient; $C=$Tcp.BeginConnect($TargetIP,$Port,$null,$null); if($C.AsyncWaitHandle.WaitOne(100,$false)){ $Tcp.EndConnect($C); $ResultObj.OpenPorts+=$Port }; $Tcp.Close() } catch {} }
                        }
                    }
                    return $ResultObj
                } catch {
                    return [PSCustomObject]@{ IP=$TargetIP; Status=$false; Name="ERROR"; Error=$_.Exception.Message }
                }
            }
            
            $MapName = if ($CustomNames.ContainsKey($IP)) { $CustomNames[$IP] } else { $null }
            $PS = [powershell]::Create().AddScript($ScriptBlock).AddArgument($IP).AddArgument($PingTimeout).AddArgument($PortTimeout).AddArgument($MapName)
            $PS.RunspacePool = $RunspacePool
            $Tasks += [PSCustomObject]@{ Pipe = $PS; Result = $PS.BeginInvoke() }
        }

        $Results = @()
        foreach ($Task in $Tasks) { $Data = $Task.Pipe.EndInvoke($Task.Result); $Task.Pipe.Dispose(); $Results += $Data }
        
        $OnlineCount = ($Results | Where-Object { $_.Status -eq $true }).Count
        $TotalOnline += $OnlineCount
        $TotalDevices += 254

        $HtmlContent += @"
        <div id='sec-$LinkId' class='subnet-section'>
            <div class='subnet-header'>
                <div class='subnet-title'><i class='fa-solid fa-network-wired' style='color:#38bdf8'></i>$DisplaySubnet</div>
                <span class='badge'>$OnlineCount Online</span>
            </div>
            <div class='grid-container'>
"@

        $SortedResults = $Results | Sort-Object { [int]($_.IP -split '\.')[3] }
        foreach ($Res in $SortedResults) {
            $Class = if ($Res.Status) { "online" } else { "offline" }
            $NameStr = if ($Res.Name) { $Res.Name } else { "-" }
            $NameStr = $NameStr -replace "\.[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+", ""
            $PortsJS = if ($Res.OpenPorts) { $Res.OpenPorts -join "," } else { "" }
            
            $NameStyle = if ($Res.IsCustom) { "color:#38bdf8; font-weight:700;" } else { "" }

            # --- KATEGORİ RENKLENDİRME ---
            $CategoryClass = ""
            if ($NameStr -match "Sunucu|Server|DC|Gateway|Firewall|Santral") { $CategoryClass = "cat-server" }
            elseif ($NameStr -match "Yazıcı|Printer") { $CategoryClass = "cat-printer" }

            # --- ROZET HTML OLUŞTURMA ---
            $BadgesHtml = ""
            if ($Res.OpenPorts -contains 3389) { $BadgesHtml += '<i class="fa-brands fa-windows port-icon p-rdp" title="RDP"></i>' }
            if ($Res.OpenPorts -contains 80 -or $Res.OpenPorts -contains 443) { $BadgesHtml += '<i class="fa-solid fa-globe port-icon p-web" title="WEB"></i>' }
            if ($Res.OpenPorts -contains 22) { $BadgesHtml += '<i class="fa-solid fa-terminal port-icon p-ssh" title="SSH"></i>' }

            # --- PING SÜRESİ MANTIĞI ---
            $PingHtml = ""
            if ($Res.Status) {
                if ($Res.PingMs -gt 100) {
                    $PingHtml = "<span class='ping-badge ping-high'><i class='fa-solid fa-triangle-exclamation'></i> " + $Res.PingMs + "ms</span>"
                } elseif ($Res.PingMs -gt 0) {
                    $PingHtml = "<span class='ping-badge ping-ok'>" + $Res.PingMs + "ms</span>"
                }
            }

            if ($Res.Status) {
                $HtmlContent += @"
                <div class="ip-card online $CategoryClass" onclick="showDetails(this)" data-ip="$($Res.IP)" data-name="$NameStr" data-ports="$PortsJS">
                    <div class="ip-addr"><span class="status-dot"></span>$($Res.IP)$PingHtml</div>
                    <div class="host-name" style="$NameStyle">$NameStr</div>
                    <div class="card-badges">$BadgesHtml</div>
                </div>
"@
            } else {
                $HtmlContent += @"
                <div class="ip-card offline">
                    <div class="ip-addr"><span class="status-dot"></span>$($Res.IP)</div>
                    <div class="host-name">$NameStr</div>
                    <div class="card-badges"></div>
                </div>
"@
            }
        }
        $HtmlContent += "</div></div>"
    }

    $RunspacePool.Close()
    $RunspacePool.Dispose()
    $TotalOffline = $TotalDevices - $TotalOnline
    $CurrentTime = Get-Date -Format "HH:mm:ss"

    # --- JAVASCRIPT & FOOTER ---
    $HtmlContent += @"
    </div>
    <div class='modal-overlay' id='modalOverlay' onclick='closeModal()'>
        <div class='modal-content' onclick='event.stopPropagation()'>
            <div class='m-header'>
                <div class='m-title' id='mIP'>IP</div>
                <div class='m-close' onclick='closeModal()'><i class='fa-solid fa-xmark'></i></div>
            </div>
            <div class='m-row'><span class='m-label'>Cihaz Adı:</span><span class='m-val' id='mName'>-</span></div>
            <div class='m-row'><span class='m-label'>Durum:</span><span class='m-val' style='color:#4ade80; font-weight:bold;'> <i class='fa-solid fa-circle-check'></i> Çevrimiçi</span></div>
            <div style='margin-top:20px; border-top:1px solid rgba(255,255,255,0.1); padding-top:10px;'>
                <div style='color:#94a3b8; font-size:0.7rem; font-weight:700; margin-bottom:10px;'>AÇIK SERVİSLER</div>
                <div class='port-list' id='mPorts'></div>
            </div>
            <div class='modal-actions' id='modalActions'></div>
        </div>
    </div>
    
    <script>
        document.getElementById('totalCount').innerText = '$TotalDevices';
        document.getElementById('onlineCount').innerText = '$TotalOnline';
        document.getElementById('offlineCount').innerText = '$TotalOffline';
        document.getElementById('scanTime').innerText = '$CurrentTime';

        function toggleTheme() { document.body.classList.toggle('light-theme'); }

        function exportToCSV() {
            let csv = 'IP,Isim,Durum\n';
            document.querySelectorAll('.ip-card').forEach(card => {
                let ip = card.querySelector('.ip-addr').innerText;
                let name = card.querySelector('.host-name').innerText;
                let status = card.classList.contains('online') ? 'Online' : 'Offline';
                csv += ip + ',' + name + ',' + status + '\n';
            });
            let blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
            let link = document.createElement('a');
            link.href = URL.createObjectURL(blob);
            link.download = 'Ag_Radari_Rapor.csv';
            link.click();
        }

        function setFilter(type, btn) {
            document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            var cards = document.getElementsByClassName('ip-card');
            for(var i=0; i<cards.length; i++) {
                if(type === 'all') { cards[i].style.display = ""; } 
                else if(type === 'online') { cards[i].style.display = cards[i].classList.contains('online') ? "" : "none"; } 
                else if(type === 'offline') { cards[i].style.display = cards[i].classList.contains('offline') ? "" : "none"; }
            }
        }

        function filterGrid() {
            var input = document.getElementById('searchInput');
            var filter = input.value.toUpperCase();
            var cards = document.getElementsByClassName('ip-card');
            for (var i = 0; i < cards.length; i++) {
                var ip = cards[i].querySelector('.ip-addr').innerText;
                var name = cards[i].querySelector('.host-name').innerText;
                if (ip.toUpperCase().indexOf(filter) > -1 || name.toUpperCase().indexOf(filter) > -1) { cards[i].style.display = ""; } else { cards[i].style.display = "none"; }
            }
        }

        function showDetails(element) {
            var ip = element.getAttribute('data-ip');
            var name = element.getAttribute('data-name');
            var ports = element.getAttribute('data-ports');
            var portsArr = ports ? ports.split(',') : [];

            document.getElementById('mIP').innerText = ip;
            document.getElementById('mName').innerText = name;
            
            let h = ''; 
            if(portsArr.length === 0 || portsArr[0] === ''){ h = '<span class="port-tag tag-closed">Servis Bulunamadı</span>'; } 
            else { 
                let d = {'21':{n:'FTP'},'22':{n:'SSH'},'80':{n:'HTTP'},'443':{n:'HTTPS'},'3389':{n:'RDP'}};
                portsArr.forEach(x => { 
                    let n = d[x] ? d[x].n : 'Port '+x;
                    h += '<span class="port-tag tag-open">' + x + ' (' + n + ')</span>';
                }); 
            }
            document.getElementById('mPorts').innerHTML = h;

            let btns = '';
            btns += '<button onclick="copyIP(\'' + ip + '\')" class="modal-btn"><i class="fa-regular fa-copy"></i> Kopyala</button>';
            if(portsArr.includes('3389')) { btns += '<button onclick="downloadRdp(\'' + ip + '\')" class="modal-btn rdp"><i class="fa-brands fa-windows"></i> RDP</button>'; }
            if(portsArr.includes('80') || portsArr.includes('443')) { btns += '<button onclick="window.open(\'http://' + ip + '\', \'_blank\')" class="modal-btn web"><i class="fa-solid fa-globe"></i> Web</button>'; }
            document.getElementById('modalActions').innerHTML = btns;
            document.getElementById('modalOverlay').style.display = 'flex';
        }

        function downloadRdp(ip) {
            var content = "full address:s:" + ip + "\nprompt for credentials:i:1";
            var blob = new Blob([content], { type: "application/x-rdp" });
            var link = document.createElement("a");
            link.href = URL.createObjectURL(blob);
            link.download = "Baglan_" + ip + ".rdp";
            link.click();
        }

        function copyIP(text) {
            var input = document.createElement('input');
            input.setAttribute('value', text);
            document.body.appendChild(input);
            input.select();
            document.execCommand('copy');
            document.body.removeChild(input);
        }

        function closeModal() { document.getElementById('modalOverlay').style.display = 'none'; }
    </script>
    <div class='footer'>Ağ Radarı • Ağ Takip Aracı • 2025</div>
</body>
</html>
"@

    $OutFile = "$([Environment]::GetFolderPath('Desktop'))\Ag_Radari.html"
    [System.IO.File]::WriteAllText($OutFile, $HtmlContent, [System.Text.UTF8Encoding]::new($true))
    Write-Log "Rapor oluşturuldu: $OutFile"
    Write-Host "   [V] İŞLEM TAMAMLANDI! Ağ Radarı Açılıyor..." -ForegroundColor Green
    Invoke-Item $OutFile

} catch {
    Write-Log "KRİTİK HATA: $($_.Exception.Message)" "HATA"
    Read-Host "Hata oluştu. Enter'a bas..."

}

