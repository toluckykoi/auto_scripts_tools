<#
# @Author      ：幸运锦鲤
# @Time        : 2026-08-06 22:38:50
# @version     : powershell
# @Update time :
# @Description : Auto Scripts Tools 一键脚本主程序 (Windows 版)
#>


# ═══════════════════════════════════════════════════════════════
#  平台检查
# ═══════════════════════════════════════════════════════════════

if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "[X] 需要 PowerShell 5.1 及以上版本" -ForegroundColor Red
    exit 1
}
if ($IsLinux -or $IsMacOS) {
    Write-Host "[X] 本脚本仅支持 Windows 平台，Linux/macOS 请使用 main.sh" -ForegroundColor Red
    exit 1
}

# ═══════════════════════════════════════════════════════════════
#  全局配置区
# ═══════════════════════════════════════════════════════════════

$ROOT_PATH = $PSScriptRoot
$VERSION = "v2.0.0"

# 尝试设置控制台 UTF-8 输入/输出，避免中文乱码
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

# 控制台窗口标题
try { $Host.UI.RawUI.WindowTitle = "Auto Scripts Tools $VERSION (Windows)" } catch {}

# ---- 颜色定义 (对应 main.sh 中的 RED/GREEN/YELLOW/...) ----
$C_RED    = "Red"
$C_GREEN  = "Green"
$C_YELLOW = "Yellow"
$C_BLUE   = "Blue"
$C_PURPLE = "Magenta"
$C_CYAN   = "Cyan"
$C_WHITE  = "White"

# ---- 环境检测 (对应 main.sh 的 Desktop/Server 检测) ----
$script:IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$script:OsCaption = "Windows"
try {
    $script:OsCaption = ((Get-CimInstance -ClassName Win32_OperatingSystem).Caption -replace '^Microsoft\s*', '').Trim()
} catch {}

if ($script:IsAdmin) {
    $script:EnvTypeText  = "[管理员]"
    $script:EnvTypeColor = $C_GREEN
    $script:EnvWarn      = ""
} else {
    $script:EnvTypeText  = "[普通用户]"
    $script:EnvTypeColor = $C_CYAN
    $script:EnvWarn      = "[!] 部分功能需要管理员权限，建议以管理员身份运行！"
}

# 子脚本所使用的 PowerShell 解释器
# 固定使用 Windows PowerShell 5.1：子脚本 (如 System_Info.ps1) 使用了
# Get-WmiObject 等仅 5.1 提供的命令，pwsh 7 中已被移除
$script:ChildPSExe = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
if (-not (Test-Path $script:ChildPSExe)) { $script:ChildPSExe = "powershell.exe" }

# ═══════════════════════════════════════════════════════════════
#  框绘制函数 (与 main.sh 保持一致：总宽 75 列，内宽 73 列)
#  右侧 ║ 通过 CJK 显示宽度计算 + 空格补齐定位，
#  不依赖 ANSI 光标定位，兼容 conhost / Windows Terminal
# ═══════════════════════════════════════════════════════════════

# 计算字符串终端显示宽度 (ASCII=1, CJK/全角=2)
function Get-DisplayWidth {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return 0 }
    $width = 0
    foreach ($ch in $Text.ToCharArray()) {
        $code = [int]$ch
        # UTF-16 代理对 (emoji 等)：高代理计 2 列，低代理计 0 列
        if ($code -ge 0xD800 -and $code -le 0xDBFF) { $width += 2; continue }
        if ($code -ge 0xDC00 -and $code -le 0xDFFF) { continue }
        $wide = ($code -ge 0x1100 -and $code -le 0x115F) -or
                ($code -ge 0x2E80 -and $code -le 0x303E) -or
                ($code -ge 0x3041 -and $code -le 0x33FF) -or
                ($code -ge 0x3400 -and $code -le 0x4DBF) -or
                ($code -ge 0x4E00 -and $code -le 0x9FFF) -or
                ($code -ge 0xA000 -and $code -le 0xA4CF) -or
                ($code -ge 0xAC00 -and $code -le 0xD7A3) -or
                ($code -ge 0xF900 -and $code -le 0xFAFF) -or
                ($code -ge 0xFE30 -and $code -le 0xFE4F) -or
                ($code -ge 0xFF00 -and $code -le 0xFF60) -or
                ($code -ge 0xFFE0 -and $code -le 0xFFE6)
        if ($wide) { $width += 2 } else { $width += 1 }
    }
    return $width
}

# 边框 (每条含 73 个 ═，加角符总宽 75)
$script:BORDER_MID = [string]::new([char]0x2550, 73)
function Write-BoxTop    { Write-Host ("╔" + $script:BORDER_MID + "╗") -ForegroundColor $C_CYAN }
function Write-BoxSep    { Write-Host ("╠" + $script:BORDER_MID + "╣") -ForegroundColor $C_CYAN }
function Write-BoxBottom { Write-Host ("╚" + $script:BORDER_MID + "╝") -ForegroundColor $C_CYAN }
function Write-BoxEmpty  { Write-Host ("║" + (" " * 73) + "║") -ForegroundColor $C_CYAN }

# 构造一个带颜色的文本片段
function New-Seg {
    param([string]$Text, [string]$Color = "White")
    return @{ Text = $Text; Color = $Color }
}

function Get-SegmentsWidth {
    param([object[]]$Segments)
    $w = 0
    foreach ($s in $Segments) { $w += Get-DisplayWidth $s.Text }
    return $w
}

# 普通内容行：║ + 空格 + 内容 + 补齐空格 + ║
function Write-BoxLine {
    param([object[]]$Segments, [string]$BorderColor = "Cyan")
    $w = Get-SegmentsWidth $Segments
    $pad = 72 - $w
    if ($pad -lt 0) { $pad = 0 }
    Write-Host "║ " -NoNewline -ForegroundColor $BorderColor
    foreach ($s in $Segments) { Write-Host $s.Text -NoNewline -ForegroundColor $s.Color }
    if ($pad -gt 0) { Write-Host (" " * $pad) -NoNewline }
    Write-Host "║" -ForegroundColor $BorderColor
}

# 居中内容行 (公式与 main.sh 的 box_center 一致)
function Write-BoxCenter {
    param([object[]]$Segments, [string]$BorderColor = "Cyan")
    $w = Get-SegmentsWidth $Segments
    $startCol = 3 + [math]::Floor((72 - $w) / 2)
    if ($startCol -lt 3) { $startCol = 3 }
    $leftPad = $startCol - 2
    $rightPad = 73 - $leftPad - $w
    if ($rightPad -lt 0) { $rightPad = 0 }
    Write-Host "║" -NoNewline -ForegroundColor $BorderColor
    if ($leftPad -gt 0) { Write-Host (" " * $leftPad) -NoNewline }
    foreach ($s in $Segments) { Write-Host $s.Text -NoNewline -ForegroundColor $s.Color }
    if ($rightPad -gt 0) { Write-Host (" " * $rightPad) -NoNewline }
    Write-Host "║" -ForegroundColor $BorderColor
}

# ═══════════════════════════════════════════════════════════════
#  菜单公共渲染函数
# ═══════════════════════════════════════════════════════════════

function Write-MenuItem {
    param([string]$Num, [string]$Name, [string]$Desc)
    Write-BoxLine @( (New-Seg "  "), (New-Seg $Num $C_GREEN), (New-Seg "   | "), (New-Seg $Name $C_WHITE) )
    if ($Desc) {
        Write-BoxLine @( (New-Seg "        └── "), (New-Seg $Desc $C_CYAN) )
    }
}

function Write-SubMenuItem {
    param([string]$Num, [string]$Name)
    Write-BoxLine @( (New-Seg "  "), (New-Seg $Num $C_GREEN), (New-Seg "  | "), (New-Seg $Name $C_WHITE) )
}

function Write-Footer {
    Write-BoxSep
    Write-BoxLine @( (New-Seg "0" $C_YELLOW), (New-Seg " / "), (New-Seg "b" $C_YELLOW),
                     (New-Seg " = 返回上级    "), (New-Seg "q" $C_YELLOW), (New-Seg " = 退出程序") )
    Write-BoxBottom
}

function Show-MainHeader {
    Clear-Host
    Write-BoxTop
    Write-BoxEmpty
    Write-BoxCenter @( (New-Seg "Auto Scripts Tools 一键脚本主界面 " $C_GREEN), (New-Seg $VERSION $C_WHITE) )
    Write-BoxEmpty
    Write-BoxSep
    Write-BoxLine @( (New-Seg "检测到当前环境："),
                     (New-Seg $script:EnvTypeText $script:EnvTypeColor),
                     (New-Seg "  $script:OsCaption" "Gray") )
    if ($script:EnvWarn) {
        Write-BoxLine @( (New-Seg $script:EnvWarn $C_YELLOW) )
    }
    Write-BoxSep
    Write-BoxLine @( (New-Seg "编号 | 功能分类" $C_WHITE) )
    Write-BoxSep
}

function Show-SectionHeader {
    param([string]$Title)
    Clear-Host
    Write-BoxTop
    Write-BoxCenter @( (New-Seg "Auto Scripts Tools" $C_GREEN) )
    Write-BoxLine @( (New-Seg $Title $C_WHITE) )
    Write-BoxSep
    Write-BoxLine @( (New-Seg "编号 | 功能说明" $C_WHITE) )
    Write-BoxSep
}

# ═══════════════════════════════════════════════════════════════
#  交互工具函数
# ═══════════════════════════════════════════════════════════════

function Wait-KeyPress {
    Write-Host ""
    Write-Host ">>> 按任意键返回菜单..." -NoNewline -ForegroundColor $C_YELLOW
    try {
        if ([Console]::IsInputRedirected) {
            # 输入被重定向 (如管道) 时 ReadKey 会阻塞，退化为读取一行
            Read-Host
        } else {
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    } catch {
        Read-Host
    }
    Write-Host ""
}

# 读取菜单选项；Ctrl+C 时给出与 main.sh trap 一致的提示
function Read-MenuChoice {
    param([string]$Prompt = "请输入序号")
    $val = ""
    try {
        $val = Read-Host $Prompt
    } catch {
        Write-Host ""
        Write-Host "[!] 使用 q 键退出，不要用 Ctrl+C 哦~" -ForegroundColor $C_YELLOW
        Start-Sleep -Milliseconds 800
        return ""
    }
    return $val.Trim().ToLower()
}

# ═══════════════════════════════════════════════════════════════
#  脚本执行工具
#  Type: ps1  = 普通 PowerShell 脚本
#        admin = 需要管理员权限 (非管理员时自动 UAC 提权)
#        py   = Python 脚本
# ═══════════════════════════════════════════════════════════════

function Invoke-Script {
    param(
        [string]$Dir,
        [string]$Script,
        [string]$Type = "ps1"
    )

    Clear-Host
    Write-BoxTop
    Write-BoxLine @( (New-Seg "=> 正在启动: $Script" $C_PURPLE) )
    Write-BoxBottom
    Write-Host ""

    $scriptPath = Join-Path (Join-Path $ROOT_PATH $Dir) $Script
    if (-not (Test-Path $scriptPath)) {
        Write-Host "[X] 错误: 脚本不存在 -- $scriptPath" -ForegroundColor $C_RED
        Write-Host ""
        Write-Host "请检查仓库文件是否完整。" -ForegroundColor $C_YELLOW
        Wait-KeyPress
        return
    }

    Push-Location (Split-Path $scriptPath -Parent)
    $exitCode = 0
    try {
        switch ($Type) {
            "admin" {
                if ($script:IsAdmin) {
                    & $script:ChildPSExe -NoProfile -ExecutionPolicy Bypass -File $scriptPath
                    $exitCode = $LASTEXITCODE
                } else {
                    # 当前非管理员：通过 UAC 提升权限，在新窗口中执行
                    $cmd = "& '$scriptPath'; Write-Host ''; Write-Host '>>> 执行结束，按回车键关闭此窗口...' -ForegroundColor Yellow; Read-Host"
                    $argStr = "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`""
                    try {
                        Write-Host "[!] 此功能需要管理员权限，正在请求 UAC 提权..." -ForegroundColor $C_YELLOW
                        Start-Process -FilePath $script:ChildPSExe -Verb RunAs -ArgumentList $argStr -Wait
                    } catch {
                        Write-Host ""
                        Write-Host "[X] 管理员授权已取消或提权失败" -ForegroundColor $C_RED
                        $exitCode = 1
                    }
                }
            }
            "py" {
                $pyCmd = Get-Command python -ErrorAction SilentlyContinue
                if (-not $pyCmd) { $pyCmd = Get-Command python3 -ErrorAction SilentlyContinue }
                if ($pyCmd) {
                    & $pyCmd.Source $scriptPath
                    $exitCode = $LASTEXITCODE
                } else {
                    Write-Host "[X] 未检测到 python，请先安装 Python" -ForegroundColor $C_RED
                    $exitCode = 1
                }
            }
            default {
                & $script:ChildPSExe -NoProfile -ExecutionPolicy Bypass -File $scriptPath
                $exitCode = $LASTEXITCODE
            }
        }
    } finally {
        Pop-Location
    }

    Write-Host ""
    if ($exitCode -eq 0) {
        Write-Host "[OK] 脚本执行结束 (退出码: $exitCode)" -ForegroundColor $C_GREEN
    } else {
        Write-Host "[X] 脚本执行异常 (退出码: $exitCode)" -ForegroundColor $C_RED
    }
    Wait-KeyPress
}

# ═══════════════════════════════════════════════════════════════
#  扩展说明：新增 Windows 脚本的方法
#  1. 将新的 .ps1 脚本放入 Windows_platform/ 目录
#  2. 在下方对应子菜单中增加一行 Write-SubMenuItem
#  3. 在 switch 分支中调用 Invoke-Script "Windows_platform" "脚本名.ps1" "类型"
# ═══════════════════════════════════════════════════════════════

# ---- 快速系统信息 (内置功能，对应 main.sh 的 common_info) ----
function Show-QuickSysInfo {
    Clear-Host
    Write-BoxTop
    Write-BoxCenter @( (New-Seg "系统基本信息" $C_GREEN) )
    Write-BoxBottom
    Write-Host ""
    try {
        $os  = Get-CimInstance -ClassName Win32_OperatingSystem
        $cs  = Get-CimInstance -ClassName Win32_ComputerSystem
        $cpu = Get-CimInstance -ClassName Win32_Processor
        Write-Host "操作系统     ：$($os.Caption)"
        Write-Host "计算机名     ：$($cs.Name)"
        Write-Host "当前用户     ：$env:USERDOMAIN\$env:USERNAME"
        Write-Host "处理器       ：$($cpu.Name)"
        Write-Host "逻辑核心数   ：$($cpu.NumberOfLogicalProcessors)"
        Write-Host "物理内存     ：$([math]::Round($cs.TotalPhysicalMemory / 1GB, 2)) GB"
        Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
            $free  = [math]::Round($_.FreeSpace / 1GB, 2)
            $total = [math]::Round($_.Size / 1GB, 2)
            Write-Host "磁盘 $($_.DeviceID)     ：总容量 $total GB / 可用 $free GB"
        }
        Write-Host "启动时间     ：$($os.LastBootUpTime)"
        $up = (Get-Date) - $os.LastBootUpTime
        Write-Host "运行时长     ：$($up.Days) 天 $($up.Hours) 小时 $($up.Minutes) 分钟"
        Write-Host "PowerShell   ：$($PSVersionTable.PSVersion.ToString())"
    } catch {
        Write-Host "[X] 获取系统信息失败: $($_.Exception.Message)" -ForegroundColor $C_RED
    }
    Wait-KeyPress
}

# ---- mkfile_manager 交互式封装 (对应 main.sh 应用市场第 12 项) ----
function Invoke-MkfileManager {
    $mkPath = Join-Path $ROOT_PATH "Windows_platform\Mkfile_Manager.ps1"
    if (-not (Test-Path $mkPath)) {
        Write-Host "[X] 错误: 脚本不存在 -- $mkPath" -ForegroundColor $C_RED
        Wait-KeyPress
        return
    }

    Clear-Host
    Write-BoxTop
    Write-BoxCenter @( (New-Seg "mkfile_manager -- 创建/管理脚本文件模板" $C_GREEN) )
    Write-BoxBottom
    Write-Host ""
    Write-Host "  1) 创建新脚本文件 (-c)      支持 .sh / .py / .ps1"
    Write-Host "  2) 更新文件的 @Update time (-u)"
    Write-Host "  0) 返回"
    Write-Host ""

    $op = Read-MenuChoice "请选择操作"
    $didWork = $false

    Push-Location $ROOT_PATH
    try {
        switch ($op) {
            "1" {
                $fname = Read-Host "请输入要创建的文件名 (如 hello.ps1)"
                $desc  = Read-Host "请输入脚本描述 (可留空)"
                if ($fname.Trim()) {
                    & $script:ChildPSExe -NoProfile -ExecutionPolicy Bypass -File $mkPath -c $fname.Trim() -d $desc
                } else {
                    Write-Host "[X] 文件名不能为空，已取消" -ForegroundColor $C_RED
                }
                $didWork = $true
            }
            "2" {
                $fname = Read-Host "请输入目标文件路径"
                if ($fname.Trim()) {
                    & $script:ChildPSExe -NoProfile -ExecutionPolicy Bypass -File $mkPath -u $fname.Trim()
                } else {
                    Write-Host "[X] 文件路径不能为空，已取消" -ForegroundColor $C_RED
                }
                $didWork = $true
            }
            default {}
        }
    } catch {
        Write-Host ""
        Write-Host "[!] 使用 q 键退出，不要用 Ctrl+C 哦~" -ForegroundColor $C_YELLOW
        Start-Sleep -Milliseconds 800
        $didWork = $true
    } finally {
        Pop-Location
    }

    if ($didWork) { Wait-KeyPress }
}

# ═══════════════════════════════════════════════════════════════
#  子菜单函数区 (大分类的子菜单)
# ═══════════════════════════════════════════════════════════════

# ---- 1. 系统信息查询 ----
function Show-SysInfoMenu {
    while ($true) {
        Show-SectionHeader "[1] 系统信息查询"
        Write-SubMenuItem "1" "查看系统综合信息 (System_Info)"
        Write-SubMenuItem "2" "快速获取系统基本信息 (内置)"
        Write-Footer

        $choice = Read-MenuChoice
        switch ($choice) {
            "1" { Invoke-Script "Windows_platform" "System_Info.ps1" "ps1" }
            "2" { Show-QuickSysInfo }
            { $_ -eq "b" -or $_ -eq "0" } { return }
            "q" { Exit-Safe }
            default {}
        }
    }
}

# ---- 2. 开发环境管理 ----
function Show-DevEnvMenu {
    while ($true) {
        Show-SectionHeader "[2] 开发环境管理"
        Write-SubMenuItem "1" "安装 MinGW-w64 (C/C++ 编译环境) [需管理员]"
        Write-Footer

        $choice = Read-MenuChoice
        switch ($choice) {
            "1" { Invoke-Script "Windows_platform" "MinGW-w64-Builds.ps1" "admin" }
            { $_ -eq "b" -or $_ -eq "0" } { return }
            "q" { Exit-Safe }
            default {}
        }
    }
}

# ---- 3. 实用工具箱 ----
function Show-ToolsMenu {
    while ($true) {
        Show-SectionHeader "[3] 实用工具箱"
        Write-SubMenuItem "1" "PowerShell 运行环境测试 (Powershell_Test)"
        Write-SubMenuItem "2" "mkfile_manager -- 创建/管理脚本文件模板"
        Write-Footer

        $choice = Read-MenuChoice
        switch ($choice) {
            "1" { Invoke-Script "Windows_platform" "Powershell_Test.ps1" "ps1" }
            "2" { Invoke-MkfileManager }
            { $_ -eq "b" -or $_ -eq "0" } { return }
            "q" { Exit-Safe }
            default {}
        }
    }
}

# ═══════════════════════════════════════════════════════════════
#  退出
# ═══════════════════════════════════════════════════════════════

function Exit-Safe {
    Clear-Host
    Write-BoxTop
    Write-BoxEmpty
    Write-BoxCenter @( (New-Seg "感谢使用 Auto Scripts Tools，再见！" $C_WHITE) )
    Write-BoxEmpty
    Write-BoxBottom
    Write-Host ""
    exit 0
}

# ═══════════════════════════════════════════════════════════════
#  主菜单
# ═══════════════════════════════════════════════════════════════

function Show-MainMenu {
    while ($true) {
        Show-MainHeader
        Write-MenuItem "1" "系统信息查询"     "查看系统综合信息 (硬件/软件/网络)"
        Write-MenuItem "2" "开发环境管理"     "C/C++ 编译环境 (MinGW-w64) 安装"
        Write-MenuItem "3" "实用工具箱"       "PowerShell 环境测试、脚本文件模板管理"
        Write-BoxSep
        Write-BoxLine @( (New-Seg "  "), (New-Seg "q" $C_RED), (New-Seg "   | "), (New-Seg "退出程序" $C_RED) )
        Write-BoxBottom
        Write-Host ""

        $choice = Read-MenuChoice "请输入序号进入"
        switch ($choice) {
            "1" { Show-SysInfoMenu }
            "2" { Show-DevEnvMenu }
            "3" { Show-ToolsMenu }
            "q" { Exit-Safe }
            default {}
        }
    }
}

Show-MainMenu
