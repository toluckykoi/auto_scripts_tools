#!/usr/bin/env pwsh
# @Author      ：幸运锦鲤
# @Time        : 2026-11-08 10:00:00
# @version     : powershell
# @Update time : 2026-11-08
# @Description : GO 程序安装脚本 - 使用官方二进制包安装（Windows 版，对应 Linux 下 go_install.sh）

<#
.SYNOPSIS
    在 Windows 上使用官方二进制包安装 Go 语言

.DESCRIPTION
    本脚本为 Linux_auto_scripts/Linux_software_install/go_install.sh 的 Windows 版本。
    自动检测系统架构，从 go.dev 官方源下载对应 Windows zip 包并安装，
    完成后配置 GOROOT / PATH 环境变量、可选的 GOPROXY 国内加速、Go 工作空间等。

    * 默认需要管理员权限（安装到 %ProgramFiles%\Go 并配置系统环境变量）
    * 使用 -UserScope 可在普通用户权限下安装到当前用户目录

.PARAMETER Version
    要安装的 Go 版本号，如 1.22.5，默认为 1.23.0

.PARAMETER InstallDir
    Go 的安装目录（GOROOT），默认 %ProgramFiles%\Go（-UserScope 时默认 %LOCALAPPDATA%\Programs\Go）

.PARAMETER UserScope
    以当前用户身份安装（无需管理员），仅配置当前用户的环境变量

.PARAMETER NoProxy
    不配置 GOPROXY（默认配置为 goproxy.cn 中国大陆加速代理）

.PARAMETER Workspace
    创建 Go 工作空间目录 %USERPROFILE%\go\bin（默认不创建）

.PARAMETER NoWorkspace
    显式禁用工作空间创建（与 -Workspace 同时出现时以此为准）

.PARAMETER DryRun
    仅预览将要执行的操作，不实际执行

.PARAMETER Help
    显示帮助信息

.EXAMPLE
    .\go_install.ps1                              # 导装默认版本
    .\go_install.ps1 -Version 1.22.5              # 安装指定版本
    .\go_install.ps1 -Workspace                   # 安装并创建工作空间
    .\go_install.ps1 -NoProxy                     # 不配置代理
    .\go_install.ps1 -UserScope                   # 普通用户安装到用户目录
    .\go_install.ps1 -DryRun                      # 预览安装步骤

.NOTES
    需要 Windows 10 / Windows 11 及以上系统，PowerShell 5.1 及以上版本
#>

[CmdletBinding()]
param(
    [string]$Version    = $null,
    [string]$InstallDir = $null,
    [switch]$UserScope,
    [switch]$NoProxy,
    [switch]$Workspace,
    [switch]$NoWorkspace,
    [switch]$DryRun,
    [switch]$Help
)

# ============================================================
# 默认配置
# ============================================================
$script:DefaultVersion  = '1.23.0'
$script:GoVersion       = if ($Version) { $Version } else { $script:DefaultVersion }
$script:ConfigProxy     = -not $NoProxy
$script:CreateWorkspace = $false
if ($Workspace)   { $script:CreateWorkspace = $true }
if ($NoWorkspace) { $script:CreateWorkspace = $false }
$script:TempDir         = Join-Path ([System.IO.Path]::GetTempPath()) "go_install_$PID"
# 未指定版本时，自动获取最新稳定版
$script:AutoLatest      = -not [bool]$Version

# 安装目录（GOROOT）默认值
if (-not $InstallDir) {
    if ($UserScope) {
        $InstallDir = Join-Path $env:LOCALAPPDATA 'Programs\Go'
    } else {
        $InstallDir = Join-Path $env:ProgramFiles 'Go'
    }
}
$script:GoRoot = $InstallDir

# 检测到的架构（amd64 / arm64 / 386）
$script:GoArch = 'unknown'

# ============================================================
# 日志函数
# ============================================================
function Write-Info    { Write-Host "[INFO]    $args" -ForegroundColor Blue }
function Write-Success { Write-Host "[SUCCESS] $args" -ForegroundColor Green }
function Write-Warn    { Write-Host "[WARN]    $args" -ForegroundColor Yellow }
function Write-Err     { Write-Host "[ERROR]   $args" -ForegroundColor Red }

# ============================================================
# 显示帮助信息
# ============================================================
function Show-Help {
    $name = Split-Path -Leaf $PSCommandPath
    Write-Host @"
用法: .\$name [-Version <版本号>] [选项]

选项:
    -Version <版本>        指定 Go 版本 (默认: 自动获取最新稳定版)
    -InstallDir <路径>     指定安装目录 (默认: %ProgramFiles%\Go)
    -UserScope             以当前用户身份安装（无需管理员，仅配置用户环境变量）
    -NoProxy               不配置 GOPROXY (默认配置为中国大陆代理 goproxy.cn)
    -Workspace             创建 Go 工作空间目录 %USERPROFILE%\go\bin (默认不创建)
    -NoWorkspace           显式禁用工作空间创建
    -DryRun                仅显示将要执行的操作，不实际执行
    -Help                  显示此帮助信息

示例:
    .\$name                               # 自动获取并安装最新稳定版（不创建工作空间）
    .\$name -Version 1.22.5               # 安装指定版本
    .\$name -Workspace                    # 安装并创建工作空间
    .\$name -NoProxy                      # 不配置代理
    .\$name -UserScope                    # 非管理员用户安装
    .\$name -DryRun                       # 预览安装步骤

说明:
    - 仅添加 $GoRoot\bin 和 %USERPROFILE%\go\bin 到 PATH
    - 不设置 GOPATH (Go 1.11+ 使用模块模式，无需 GOPATH，默认 %USERPROFILE%\go)
    - 工作空间仅创建 %USERPROFILE%\go\bin 目录用于存放编译产物
"@
}

# ============================================================
# 基础工具函数
# ============================================================
# 检测是否管理员权限
function Test-AdminUser {
    $identity = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $identity.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 架构检测
function Get-GoArch {
    $arch = $env:PROCESSOR_ARCHITECTURE
    if ($env:PROCESSOR_ARCHITEW6432) { $arch = $env:PROCESSOR_ARCHITEW6432 }
    switch ($arch) {
        'AMD64' { return 'amd64' }
        'ARM64' { return 'arm64' }
        'x86'   { return '386' }
        default { throw "不支持的架构: $arch" }
    }
}

# 获取官方最新稳定版版本号
function Get-LatestGoVersion {
    Write-Info "正在查询 Go 官方最新稳定版..."
    # 官方来源：https://go.dev/VERSION?m=text  返回类似: go1.24.2
    $latestUrl = 'https://go.dev/VERSION?m=text'
    try {
        $ProgressPreference = 'SilentlyContinue'
        $response = Invoke-WebRequest -Uri $latestUrl -UseBasicParsing -TimeoutSec 15
        $ProgressPreference = 'Continue'
        if ($response -and $response.Content) {
            # 官方直接返回最新版本号字符串，去掉前导 go
            $latest = ($response.Content -split "`n")[0].Trim() -replace '^go', ''
            if ($latest -match '^\d+\.\d+(\.\d+)?$') {
                Write-Success "获取到最新稳定版: go$latest"
                return $latest
            }
            Write-Warn "解析最新版本失败: '$latest'，使用兜底版本"
        }
    } catch {
        Write-Warn "查询官方最新版本失败: $($_.Exception.Message)"
        # 尝试中国大陆镜像源
        try {
            Write-Info "尝试从中国大陆镜像源查询: https://golang.google.cn/VERSION?m=text"
            $ProgressPreference = 'SilentlyContinue'
            $response = Invoke-WebRequest -Uri 'https://golang.google.cn/VERSION?m=text' -UseBasicParsing -TimeoutSec 15
            $ProgressPreference = 'Continue'
            $latest = ($response.Content -split "`n")[0].Trim() -replace '^go', ''
            if ($latest -match '^\d+\.\d+(\.\d+)?$') {
                Write-Success "获取到最新稳定版: go$latest"
                return $latest
            }
        } catch {
            Write-Warn "中国大陆镜像查询也失败: $($_.Exception.Message)"
        }
    }
    Write-Warn "无法获取最新版本，使用默认版本 $($script:DefaultVersion) 安装"
    return $script:DefaultVersion
}

# ============================================================
# 预检查
# ============================================================
function Preflight-Check {
    Write-Info "开始预检查..."

    # PowerShell 版本检查（需要 5.1 及以上）
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Err "PowerShell 版本过低，请使用 5.1 及以上版本"
        exit 1
    }

    # 未指定版本时，自动查询最新稳定版
    if ($script:AutoLatest) {
        $script:GoVersion = Get-LatestGoVersion
    }

    # 版本号格式校验
    if ($script:GoVersion -notmatch '^\d+\.\d+(\.\d+)?$') {
        Write-Err "版本号格式错误: $($script:GoVersion)，应为形如 1.23.0"
        exit 1
    }

    # 权限检查（dry-run 模式跳过，UserScope 无需管理员）
    if (-not $DryRun) {
        if (-not (Test-AdminUser)) {
            if ($UserScope) {
                Write-Warn "以普通用户模式安装到 $($script:GoRoot)，仅配置当前用户环境变量"
            } else {
                Write-Err "需要管理员权限来安装到 $($script:GoRoot)"
                Write-Info "请右键以管理员身份运行 PowerShell，或使用 -UserScope 参数以普通用户安装"
                exit 1
            }
        }
    }

    # 检查是否已安装 (dry-run 模式仅提示，不询问)
    $goExePath = Join-Path $script:GoRoot 'bin\go.exe'
    $script:OldGoRoot = $null          # 旧版本根目录 (位于其他位置时需要自动清理)
    $foundGo   = $null
    # 1. 优先在目标安装目录检测
    if (Test-Path $goExePath) {
        $foundGo = $goExePath
    }
    # 2. 目标目录未检出时，再检查 PATH 中是否已有 go
    if (-not $foundGo) {
        $cmd = Get-Command 'go' -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) { $foundGo = $cmd.Source }
    }

    if ($foundGo) {
        $currentVer = (& $foundGo version 2>$null | Select-Object -First 1)
        $currentVer = ([regex]::Match($currentVer, 'go\d+\.\d+(\.\d+)?').Value) -replace '^go', ''
        if ($currentVer) {
            $sameVersion = ($currentVer -eq $script:GoVersion)
            $inTarget    = ([IO.Path]::GetFullPath($foundGo) -ieq [IO.Path]::GetFullPath($goExePath))
            Write-Warn "检测到已安装的 Go: v$currentVer ($foundGo)"

            if ($DryRun) {
                if ($sameVersion) {
                    Write-Warn "[DRY-RUN] 版本相同，本将清理旧安装并重新安装"
                } else {
                    Write-Warn "[DRY-RUN] 检测到旧版本，本将清理旧版本并安装新版本"
                }
                if (-not $inTarget) {
                    Write-Warn "[DRY-RUN] 注意: 旧版本位于其他目录，安装后将自动删除旧版本目录并清理 PATH 配置"
                }
            } else {
                if ($sameVersion) {
                    $answer = Read-Host '已安装相同版本，是否重新安装? [y/N]'
                } else {
                    $answer = Read-Host '已安装不同版本，是否清理并重新安装? [y/N]'
                }
                if ($answer -notmatch '^[Yy]$') {
                    Write-Info '取消安装'
                    exit 0
                }
                # 旧版本不在目标目录时，记录其根目录，安装时自动删除并清理 PATH
                if (-not $inTarget) {
                    $script:OldGoRoot = Split-Path (Split-Path $foundGo -Parent) -Parent
                    Write-Warn "将自动删除旧版本目录: $($script:OldGoRoot) 并清理其 PATH 配置"
                }
            }
        }
    }

    Write-Success "预检查通过"
}

# ============================================================
# 显示安装计划
# ============================================================
function Show-Plan {
    Write-Host @"
========================================
Go 安装计划
========================================
版本:          go$($script:GoVersion)
架构:          $($script:GoArch)
安装目录:      $($script:GoRoot)
安装方式:      $(if ($UserScope) { '当前用户 (UserScope)' } else { '系统级 (需管理员)' })
配置代理:      $($script:ConfigProxy)
创建工作空间:  $($script:CreateWorkspace)
模拟运行:      $DryRun
========================================
"@
}

# ============================================================
# 下载 Go 安装包
# ============================================================
function Invoke-DownloadGo {
    $zipName = "go$($script:GoVersion).windows-$($script:GoArch).zip"
    $url     = "https://go.dev/dl/$zipName"
    $zipPath = Join-Path $script:TempDir $zipName
    $downloadUrl = $url

    Write-Info "下载 Go $($script:GoVersion) ($($script:GoArch))..."

    if ($DryRun) {
        Write-Host "[DRY-RUN] 下载: $zipPath <- $downloadUrl" -ForegroundColor Yellow
        $script:GoZipPath = $zipPath
        return
    }

    # 先尝试中国大陆镜像，失败后回退官方源
    Write-Info "下载地址: $downloadUrl"
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
        $ProgressPreference = 'Continue'
    } catch {
        Write-Err "下载失败，请检查版本号和网络连接"
        Write-Info "可用版本请访问: https://go.dev/dl/"
        exit 1
    }

    # 验证文件完整性
    if ((Get-Item $zipPath).Length -le 0) {
        Write-Err "下载的文件为空"
        exit 1
    }

    $script:GoZipPath = $zipPath
    Write-Success "下载完成: $zipName"
}

# ============================================================
# 安装 Go
# ============================================================
function Invoke-InstallGo {
    Write-Info "安装 Go 到 $($script:GoRoot) ..."
    $goExePath = Join-Path $script:GoRoot 'bin\go.exe'

    if ($DryRun) {
        Write-Host "[DRY-RUN] 解压 $($script:GoZipPath) 到 $($script:GoRoot)" -ForegroundColor Yellow
        Write-Host "[DRY-RUN] 验证: $goExePath" -ForegroundColor Yellow
        return
    }

    # 解压到临时目录
    $stageDir = Join-Path $script:TempDir 'extract'
    Expand-Archive -Path $script:GoZipPath -DestinationPath $stageDir -Force

    # 删除旧版本 (先退出可能占用文件的进程)
    if (Test-Path $script:GoRoot) {
        # 若目标目录正被 go 进程占用，先结束
        $oldGoExe = Join-Path $script:GoRoot 'bin\go.exe'
        if (Test-Path $oldGoExe) {
            try {
                Get-Process -Name 'go*' -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*$($script:GoRoot)*" } | Stop-Process -Force -ErrorAction SilentlyContinue
            } catch {}
        }
        Write-Warn "删除旧版本目录: $($script:GoRoot)"
        Remove-Item $script:GoRoot -Recurse -Force -ErrorAction Continue
        if (Test-Path $script:GoRoot) {
            Write-Err "删除旧版本失败: $($script:GoRoot) 可能被进程占用，请关闭 Go 相关程序后重试"
            exit 1
        }
    }

    # 移动新版本到目标位置
    $parentDir = Split-Path $script:GoRoot -Parent
    if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
    Move-Item -Path (Join-Path $stageDir 'go') -Destination $script:GoRoot -Force

    # 验证安装
    if (-not (Test-Path $goExePath)) {
        Write-Err "安装失败: 未找到 $goExePath"
        exit 1
    }

    Write-Success "Go 安装完成"
}

# ============================================================
# 配置环境变量
# ============================================================
function Set-GoEnvironment {
    Write-Info "配置环境变量..."

    $goBinPath    = Join-Path $script:GoRoot 'bin'
    $userGoBin    = '%USERPROFILE%\go\bin'      # 用户工作空间 bin（字面量，避免硬编码用户目录）
    $machineTarget = [EnvironmentVariableTarget]::Machine
    $userTarget    = [EnvironmentVariableTarget]::User

    # 系统级安装：GOROOT + PATH 写入系统变量；普通用户安装：只写用户变量
    $targetScope = if ($UserScope) { $userTarget } else { $machineTarget }

    if ($DryRun) {
        Write-Host "[DRY-RUN] 设置环境变量 GOROOT = $($script:GoRoot) (目标: $(if ($UserScope) {'用户'} else {'系统'}))" -ForegroundColor Yellow
        Write-Host "[DRY-RUN] 追加 PATH: $goBinPath (目标同作用域)" -ForegroundColor Yellow
        Write-Host "[DRY-RUN] 追加用户 PATH: $userGoBin (仅用户)" -ForegroundColor Yellow
        if ($script:OldGoRoot) {
            Write-Host "[DRY-RUN] 删除旧版本目录: $($script:OldGoRoot) 并清理其 PATH 残留" -ForegroundColor Yellow
        }
        return
    }

    # ── 清理位于其他目录的旧版本 (用户确认重装后) ──
    if ($script:OldGoRoot -and (Test-Path $script:OldGoRoot)) {
        $oldGoExe = Join-Path $script:OldGoRoot 'bin\go.exe'
        # 结束可能占用旧目录的 go 进程
        if (Test-Path $oldGoExe) {
            try {
                Get-Process -Name 'go*' -ErrorAction SilentlyContinue |
                    Where-Object { $_.Path -like "*$($script:OldGoRoot)*" } |
                    Stop-Process -Force -ErrorAction SilentlyContinue
            } catch {}
            # 清理旧版本 GOROOT 环境变量
            [Environment]::SetEnvironmentVariable('GOROOT', $null, $targetScope)
        }
        Write-Warn "删除旧版本目录: $($script:OldGoRoot)"
        Remove-Item $script:OldGoRoot -Recurse -Force -ErrorAction Continue
        if (Test-Path $script:OldGoRoot) {
            Write-Err "删除旧版本失败: $($script:OldGoRoot) 可能被进程占用，请关闭 Go 相关程序后重试"
            exit 1
        }
    }

    # ── 清理 PATH 中旧版本残留 (仅清理旧版本相关路径，不误删其他) ──
    # 需要从 PATH 中移除的路径: 旧版本根目录下的 bin 及旧 GOROOT 相关路径
    $removePaths = @()
    if ($script:OldGoRoot) {
        $removePaths += @(
            (Join-Path $script:OldGoRoot 'bin').TrimEnd('\'),
            $script:OldGoRoot.TrimEnd('\')
        )
    }
    foreach ($scope in @($machineTarget, $userTarget)) {
        if (-not $removePaths) { break }
        $pathValue = [Environment]::GetEnvironmentVariable('Path', $scope)
        if (-not $pathValue) { continue }
        $cleaned = @()
        $removed = @()
        foreach ($entry in ($pathValue -split ';')) {
            if ([string]::IsNullOrWhiteSpace($entry)) { continue }
            $e = $entry.Trim().TrimEnd('\')
            $isOld = $false
            foreach ($r in $removePaths) {
                if ($e -ieq $r.TrimEnd('\')) { $isOld = $true; break }
            }
            if ($isOld) { $removed += $entry } else { $cleaned += $entry }
        }
        $newValue = ($cleaned -join ';').Trim(';')
        if ($newValue -ne $pathValue) {
            Write-Warn "清理 PATH 残留 ($scope): $(($removed -join ', '))"
            [Environment]::SetEnvironmentVariable('Path', $newValue, $scope)
        }
    }

    # 设置 GOROOT
    [Environment]::SetEnvironmentVariable('GOROOT', $script:GoRoot, $targetScope)

    # 配置 PATH（系统级时：GOROOT\bin 进系统 PATH；用户 go\bin 进用户 PATH）
    if ($UserScope) {
        # 用户级：GOROOT\bin 和 %USERPROFILE%\go\bin 都加入用户 PATH
        $userPath = [Environment]::GetEnvironmentVariable('Path', $userTarget)
        foreach ($p in @($goBinPath, $userGoBin)) {
            if ($userPath -notlike "*$p*") {
                $userPath = ($userPath.TrimEnd(';') + ';' + $p).TrimStart(';')
            }
        }
        [Environment]::SetEnvironmentVariable('Path', $userPath, $userTarget)
    } else {
        # 系统级：GOROOT\bin 加入系统 PATH
        $machinePath = [Environment]::GetEnvironmentVariable('Path', $machineTarget)
        if ($machinePath -notlike "*$goBinPath*") {
            $machinePath = ($machinePath.TrimEnd(';') + ';' + $goBinPath).TrimStart(';')
            [Environment]::SetEnvironmentVariable('Path', $machinePath, $machineTarget)
        }
        # %USERPROFILE%\go\bin 加入当前用户 PATH
        $userPath = [Environment]::GetEnvironmentVariable('Path', $userTarget)
        if ($userPath -notlike "*$userGoBin*") {
            $userPath = ($userPath.TrimEnd(';') + ';' + $userGoBin).TrimStart(';')
            [Environment]::SetEnvironmentVariable('Path', $userPath, $userTarget)
        }
    }

    # 当前会话立即生效 (同时清理旧版本路径)
    $env:GOROOT = $script:GoRoot
    if ($script:OldGoRoot) {
        $oldBin = (Join-Path $script:OldGoRoot 'bin').TrimEnd('\')
        $env:PATH = (($env:PATH -split ';') |
            Where-Object { ($_.TrimEnd('\') -ine $oldBin) -and -not [string]::IsNullOrWhiteSpace($_) }) -join ';'
    }
    $env:PATH = "$goBinPath;$env:PATH"

    Write-Success "环境变量配置完成 (GOROOT=$($script:GoRoot))"
}

# ============================================================
# 配置 GOPROXY
# ============================================================
function Set-GoProxy {
    if (-not $script:ConfigProxy) {
        Write-Info "跳过 GOPROXY 配置"
        return
    }

    Write-Info "配置 GOPROXY (中国大陆加速)..."

    $goExe = Join-Path $script:GoRoot 'bin\go.exe'
    if ($DryRun) {
        Write-Host "[DRY-RUN] $goExe env -w GO111MODULE=on" -ForegroundColor Yellow
        Write-Host "[DRY-RUN] $goExe env -w GOPROXY=https://goproxy.cn,direct" -ForegroundColor Yellow
        return
    }

    & $goExe env -w GO111MODULE=on
    & $goExe env -w GOPROXY=https://goproxy.cn,direct

    Write-Success "GOPROXY 配置完成: $(& $goExe env GOPROXY)"
}

# ============================================================
# 创建工作空间
# ============================================================
function New-GoWorkspace {
    if (-not $script:CreateWorkspace) {
        Write-Info "跳过工作空间创建"
        return
    }

    $wsDir = Join-Path $env:USERPROFILE 'go\bin'
    Write-Info "创建 Go 工作空间目录: $wsDir"

    if ($DryRun) {
        Write-Host "[DRY-RUN] 创建目录: $wsDir" -ForegroundColor Yellow
        return
    }

    New-Item -ItemType Directory -Path $wsDir -Force | Out-Null
    Write-Success "工作空间创建完成: $wsDir"
}

# ============================================================
# 验证安装
# ============================================================
function Test-GoInstallation {
    Write-Info "验证安装..."

    $goExe = Join-Path $script:GoRoot 'bin\go.exe'
    if ($DryRun) {
        Write-Host "[DRY-RUN] $goExe version" -ForegroundColor Yellow
        Write-Host "[DRY-RUN] $goExe env GOPROXY" -ForegroundColor Yellow
        return
    }

    Write-Success "Go 版本: $(& $goExe version)"
    Write-Info "GOPROXY: $(& $goExe env GOPROXY)"
    Write-Info "GOROOT : $(& $goExe env GOROOT)"
}

# ============================================================
# 清理临时文件
# ============================================================
function Remove-TempDir {
    if (Test-Path $script:TempDir) {
        if ($DryRun) {
            Write-Host "[DRY-RUN] 清理临时目录: $($script:TempDir)" -ForegroundColor Yellow
        } else {
            Remove-Item $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Info "临时文件已清理"
        }
    }
}

# ============================================================
# 主函数
# ============================================================
function Main {
    # 尝试设置 UTF-8 输出（部分终端默认识别为 GBK 时显示为乱码）
    try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

    if ($Help) { Show-Help; exit 0 }

    Write-Host "========================================" -ForegroundColor Blue
    Write-Host "     Go 语言安装脚本 (官方二进制包)"      -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host ""

    # 检测架构
    try {
        $script:GoArch = Get-GoArch
    } catch {
        Write-Err $_.Exception.Message
        exit 1
    }

    # 创建临时目录
    if (-not (Test-Path $script:TempDir)) {
        New-Item -ItemType Directory -Path $script:TempDir -Force | Out-Null
    }

    try {
        Preflight-Check
        Show-Plan

        if ($DryRun) {
            Write-Info "模拟运行模式，不执行实际操作"
            Write-Host ""
        }

        Invoke-DownloadGo
        Invoke-InstallGo
        Set-GoEnvironment
        Set-GoProxy
        New-GoWorkspace
        Test-GoInstallation
    } finally {
        Remove-TempDir
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "     安装完成！"                        -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "请关闭当前 PowerShell 窗口后重新打开，使环境变量立即生效："
    Write-Host "  重新打开终端后输入 go version 验证安装" -ForegroundColor Yellow
    Write-Host "  验证: go version"                       -ForegroundColor Yellow
    Write-Host ""
    Write-Host "开始编程 (示例):"
    Write-Host "  cd $env:USERPROFILE\go"                -ForegroundColor Yellow
    Write-Host "  go mod init hello"                     -ForegroundColor Yellow
    Write-Host "  go run hello.go"                       -ForegroundColor Yellow
}

# 运行主函数
Main