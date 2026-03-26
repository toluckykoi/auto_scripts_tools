<#
.SYNOPSIS
    电脑详细信息收集脚本
.DESCRIPTION
    收集并输出电脑详细硬件与系统信息。
    涵盖系统、CPU、内存、磁盘、网络、显卡、软件、服务、用户、电池及 BIOS 信息。
    支持自动导出报告至临时目录，便于归档或分享。
.AUTHOR
    幸运锦鲤 (luckykoi)
.CREATED
    2025-03-04 17:40:06
.VERSION
    PowerShell 5.1+
.LINK
    https://github.com/luckykoi/
.EXAMPLE
    .\System_Info.ps1
.EXAMPLE
    # 以管理员身份运行以获取完整信息
    Start-Process powershell -Verb RunAs -FilePath ".\System_Info.ps1"
.NOTES
    部分信息（如 BIOS 序列号、详细硬件信息）需要管理员权限才能完整获取。
    默认使用 Get-WmiObject，适用于 Windows PowerShell 5.1。
#>


# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# 颜色输出函数
function Write-Color {
    param($Text, $Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

# 分隔线
function Write-Separator {
    Write-Host ("=" * 62) -ForegroundColor Cyan
}

# 标题
Write-Color "╔════════════════════════════════════════════════════════════╗" "Green"
Write-Color "║                    电脑详细信息报告                        ║" "Green"
Write-Color "╚════════════════════════════════════════════════════════════╝" "Green"
Write-Separator
Write-Host "生成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Separator

# 1. 系统信息
Write-Color "`n【1】系统信息" "Magenta"
$os = Get-WmiObject -Class Win32_OperatingSystem
$cs = Get-WmiObject -Class Win32_ComputerSystem
Write-Host "操作系统：$($os.Caption)"
Write-Host "版本号：$($os.Version)"
Write-Host "系统架构：$($os.OSArchitecture)"
Write-Host "计算机名：$($cs.Name)"
Write-Host "制造商：$($cs.Manufacturer)"
Write-Host "型号：$($cs.Model)"
Write-Host "系统目录：$($os.SystemDirectory)"
Write-Host "启动时间：$($os.ConvertToDateTime($os.LastBootUpTime))"
Write-Host "运行时间：$((New-TimeSpan -Start $os.ConvertToDateTime($os.LastBootUpTime) -End (Get-Date)).ToString('d\.hh\:mm\:ss'))"

# 2. CPU 信息
Write-Color "`n【2】CPU 信息" "Magenta"
$cpu = Get-WmiObject -Class Win32_Processor
Write-Host "处理器名称：$($cpu.Name)"
Write-Host "核心数：$($cpu.NumberOfCores)"
Write-Host "逻辑处理器数：$($cpu.NumberOfLogicalProcessors)"
Write-Host "最大时钟频率：$($cpu.MaxClockSpeed) MHz"
Write-Host "架构：$($cpu.Architecture)"

# 3. 内存信息
Write-Color "`n【3】内存信息" "Magenta"
$mem = Get-WmiObject -Class Win32_PhysicalMemory
$totalMem = ($mem | Measure-Object -Property Capacity -Sum).Sum / 1GB
Write-Host "总内存：$([math]::Round($totalMem, 2)) GB"
Write-Host "内存条数量：$($mem.Count)"
$mem | ForEach-Object {
    Write-Host "  - 容量：$([math]::Round($_.Capacity / 1GB, 2)) GB, 速度：$($_.Speed) MHz, 制造商：$($_.Manufacturer)"
}

# 4. 磁盘信息
Write-Color "`n【4】磁盘信息" "Magenta"
$disk = Get-WmiObject -Class Win32_DiskDrive
$disk | ForEach-Object {
    Write-Host "磁盘：$($_.Model)"
    Write-Host "  容量：$([math]::Round($_.Size / 1GB, 2)) GB"
    Write-Host "  接口类型：$($_.InterfaceType)"
}
$vol = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
$vol | ForEach-Object {
    $free = [math]::Round($_.FreeSpace / 1GB, 2)
    $total = [math]::Round($_.Size / 1GB, 2)
    $percent = [math]::Round(($_.FreeSpace / $_.Size) * 100, 2)
    Write-Host "盘符：$($_.DeviceID) - 总容量：$total GB, 可用：$free GB ($percent%)"
}

# 5. 网络信息
Write-Color "`n【5】网络信息" "Magenta"
$net = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }
$net | ForEach-Object {
    Write-Host "网卡：$($_.Description)"
    Write-Host "  MAC 地址：$($_.MACAddress)"
    Write-Host "  IP 地址：$($_.IPAddress -join ', ')"
    Write-Host "  默认网关：$($_.DefaultIPGateway -join ', ')"
    Write-Host "  DNS 服务器：$($_.DNSServerSearchOrder -join ', ')"
}

# 6. 显卡信息
Write-Color "`n【6】显卡信息" "Magenta"
$gpu = Get-WmiObject -Class Win32_VideoController
$gpu | ForEach-Object {
    Write-Host "显卡：$($_.Name)"
    Write-Host "  显存：$([math]::Round($_.AdapterRAM / 1MB, 2)) MB"
    Write-Host "  驱动版本：$($_.DriverVersion)"
}

# 7. 已安装软件
Write-Color "`n【7】已安装软件（部分）" "Magenta"
$apps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
Where-Object { $_.DisplayName } | Select-Object DisplayName, DisplayVersion, Publisher
$apps | Select-Object -First 20 | Format-Table -AutoSize

# 8. 服务状态
Write-Color "`n【8】关键服务状态" "Magenta"
$services = Get-Service | Where-Object { $_.Status -eq 'Running' } | Select-Object -First 10
$services | Format-Table Name, DisplayName, Status -AutoSize

# 9. 用户信息
Write-Color "`n【9】用户信息" "Magenta"
Write-Host "当前用户：$($env:USERNAME)"
Write-Host "用户域：$($env:USERDOMAIN)"
Write-Host "用户主目录：$($env:USERPROFILE)"

# 10. 电池信息（仅笔记本）
Write-Color "`n【10】电池信息" "Magenta"
$battery = Get-WmiObject -Class Win32_Battery -ErrorAction SilentlyContinue
if ($battery) {
    $battery | ForEach-Object {
        Write-Host "电池：$($_.Name)"
        Write-Host "  设计容量：$($_.DesignCapacity) mAh"
        Write-Host "  当前电量：$($_.EstimatedChargeRemaining)%"
        Write-Host "  状态：$($_.BatteryStatus)"
    }
}
else {
    Write-Host "未检测到电池（可能为台式机）" -ForegroundColor Gray
}

# 11. BIOS 信息
Write-Color "`n【11】BIOS 信息" "Magenta"
$bios = Get-WmiObject -Class Win32_BIOS
Write-Host "BIOS 版本：$($bios.SMBIOSBIOSVersion)"
Write-Host "BIOS 制造商：$($bios.Manufacturer)"
Write-Host "序列号：$($bios.SerialNumber)"

# 12. 导出报告
Write-Color "`n【12】导出报告" "Magenta"
$outputPath = "$env:TEMP\SystemInfo_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$null = Start-Transcript -Path $outputPath -Append
Write-Host "报告已保存至：$outputPath" -ForegroundColor Green
Stop-Transcript

Write-Separator
Write-Color "报告生成完成！" "Green"
Write-Separator

# 如果不是管理员，提示部分信息可能受限
if (-not $isAdmin) {
    Write-Color "⚠ 注意：部分信息需要管理员权限才能完整获取" "Yellow"
}

Write-Color "`n按任意键退出..." "Gray"
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
