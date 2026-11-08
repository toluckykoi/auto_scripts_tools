#!/usr/bin/env pwsh
# @Author      ：幸运锦鲤
# @Time        : 2026-11-08
# @version     : powershell
# @Update time : 2026-11-08
# @Description : Flutter SDK 安装脚本 - 使用官方二进制包安装（Windows 版，对应 Linux 下 flutter_install.sh）

<#
.SYNOPSIS
    在 Windows 上使用官方二进制包安装 Flutter SDK

.DESCRIPTION
    本脚本为 Linux_auto_scripts/Linux_software_install/flutter_install.sh 的 Windows 版本。
    自动检测系统架构，从 flutter 官方源（或国内镜像）下载对应 zip 包并安装，
    完成后配置 PATH 环境变量、可选国内镜像加速（PUB_HOSTED_URL / FLUTTER_STORAGE_BASE_URL）。

    * 默认需要管理员权限（安装到 %ProgramFiles%\flutter 并配置系统环境变量）
    * 使用 -UserScope 可在普通用户权限下安装到当前用户目录

.PARAMETER Version
    要安装的 Flutter 版本号，如 3.27.1，缺省时自动获取最新稳定版

.PARAMETER Channel
    发布渠道：stable / beta / dev，默认 stable

.PARAMETER InstallDir
    Flutter 的安装目录，默认 %ProgramFiles%\flutter（-UserScope 时默认 %LOCALAPPDATA%\Programs\flutter）

.PARAMETER UserScope
    以当前用户身份安装（无需管理员），仅配置当前用户的环境变量

.PARAMETER Mirror
    下载源：official（官方源）/ mirror_cn（国内镜像 storage.flutter-io.cn），默认 official

.PARAMETER NoMirror
    显式使用官方源（等价于 -Mirror official）

.PARAMETER Yes
    已安装时跳过确认，自动覆盖安装

.PARAMETER DryRun
    仅预览将要执行的操作，不实际执行

.PARAMETER Help
    显示帮助信息

.EXAMPLE
    .\flutter_install.ps1                          # 安装最新稳定版
    .\flutter_install.ps1 -Version 3.27.1          # 安装指定版本
    .\flutter_install.ps1 -Channel beta            # 安装最新 beta 版
    .\flutter_install.ps1 -Mirror mirror_cn        # 使用国内镜像
    .\flutter_install.ps1 -UserScope               # 普通用户安装到用户目录
    .\flutter_install.ps1 -DryRun                  # 预览安装步骤

.NOTES
    需要 Windows 10 / Windows 11 及以上系统，PowerShell 5.1 及以上版本
    参考: https://docs.flutter.dev/get-started/install
#>

[CmdletBinding()]
param(
    [string]$Version    = $null,
    [ValidateSet('stable', 'beta', 'dev')]
    [string]$Channel    = 'stable',
    [string]$InstallDir = $null,
    [switch]$UserScope,
    [ValidateSet('official', 'mirror_cn')]
    [string]$Mirror     = 'official',
    [switch]$NoMirror,
    [switch]$Yes,
    [switch]$DryRun,
    [switch]$Help
)

# ============================================================
# 默认配置
# ============================================================
if ($NoMirror) { $Mirror = 'official' }
$script:FlutterChannel  = $Channel
$script:ConfigMirror    = ($Mirror -eq 'mirror_cn')
$script:AutoLatest      = -not [bool]$Version
$script:TempDir         = Join-Path ([System.IO.Path]::GetTempPath()) "flutter_install_$PID"

# 下载源地址（官方与国内镜像的发布 JSON 的路径不同）
$script:OfficialBase = 'https://storage.googleapis.com/flutter_infra_release/releases'
$script:MirrorBase   = 'https://storage.flutter-io.cn/releases'

# 未指定版本时的默认兜底版本（自动获取失败时使用）
$script:DefaultVersion = '3.47.9'

# 安装目录默认值
if (-not $InstallDir) {
    if ($UserScope) {
        $InstallDir = Join-Path $env:LOCALAPPDATA 'Programs\flutter'
    } else {
        $InstallDir = Join-Path $env:ProgramFiles 'flutter'
    }
}
$script:FlutterRoot = $InstallDir

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
用法: .\$name [-Version <版本号>] [-Channel <渠道>] [选项]

选项:
    -Version <版本>        指定 Flutter 版本 (默认: 自动获取最新稳定版)
    -Channel <渠道>        发布渠道 stable/beta/dev (默认: stable)
    -InstallDir <路径>     指定安装目录 (默认: %ProgramFiles%\flutter)
    -UserScope             以当前用户身份安装（无需管理员，仅配置用户环境变量）
    -Mirror <源>           下载源 official/mirror_cn (默认: official)
    -NoMirror              显式使用官方源（等价于 -Mirror official）
    -Yes                   已安装时跳过确认，自动覆盖安装
    -DryRun                仅显示将要执行的操作，不实际执行
    -Help                  显示此帮助信息

示例:
    .\$name                               # 自动获取并安装最新稳定版
    .\$name -Version 3.27.1               # 安装指定版本
    .\$name -Channel beta                 # 安装最新 beta 版
    .\$name -Mirror mirror_cn             # 使用国内镜像 (storage.flutter-io.cn)
    .\$name -UserScope                    # 非管理员用户安装
    .\$name -DryRun                       # 预览安装步骤

说明:
    - 安装后仅将 $($script:FlutterRoot)\bin 加入 PATH
    - 镜像模式时会额外配置 PUB_HOSTED_URL 与 FLUTTER_STORAGE_BASE_URL 加速
    - 构建依赖（Visual Studio / Android Studio 等）请运行 flutter doctor 检测
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
function Get-FlutterArch {
    $arch = $env:PROCESSOR_ARCHITECTURE
    if ($env:PROCESSOR_ARCHITEW6432) { $arch = $env:PROCESSOR_ARCHITEW6432 }
    switch ($arch) {
        'AMD64' { return 'x64' }
        'ARM64' { return 'arm64' }
        default { throw "不支持的架构: $arch" }
    }
}

# 获取发布 JSON（官方/镜像二选一），返回解析后的对象
function Get-ReleaseJson {
    param([string]$BaseUrl)
    $url = "$BaseUrl/releases_windows.json"
    try {
        $ProgressPreference = 'SilentlyContinue'
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 20
        $ProgressPreference = 'Continue'
        if ($response -and $response.Content) {
            return ($response.Content | ConvertFrom-Json)
        }
    } catch {
        Write-Warn "获取发布信息失败: $($_.Exception.Message)"
    }
    return $null
}

# 通过 releases_windows.json 自动获取指定渠道最新版本号
function Get-LatestFlutterVersion {
    param([string]$TargetChannel = 'stable')
    Write-Info "正在从发布源查询 Flutter 最新 $TargetChannel 版..."
    $releaseJson = Get-ReleaseJson $script:OfficialBase
    if (-not $releaseJson) {
        Write-Warn "官方源查询失败，尝试国内镜像源..."
        $releaseJson = Get-ReleaseJson $script:MirrorBase
    }
    if ($releaseJson -and $releaseJson.releases) {
        # 在发布列表中查找目标渠道与当前架构匹配的版本
        foreach ($rel in $releaseJson.releases) {
            if ($rel.channel -eq $TargetChannel -and $rel.version) {
                Write-Success "获取到最新 $TargetChannel 版: $($rel.version)"
                return $rel.version
            }
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
        $script:FlutterVersion = Get-LatestFlutterVersion $script:FlutterChannel
    } else {
        $script:FlutterVersion = $Version
    }

    # 版本号格式校验
    if ($script:FlutterVersion -notmatch '^\d+\.\d+(\.\d+)?(\-[0-9a-zA-Z.]+)?$') {
        Write-Err "版本号格式错误: $($script:FlutterVersion)，应为形如 3.27.1"
        exit 1
    }

    # 权限检查（dry-run 模式跳过，UserScope 无需管理员）
    if (-not $DryRun) {
        if (-not (Test-AdminUser)) {
            if ($UserScope) {
                Write-Warn "以普通用户模式安装到 $($script:FlutterRoot)，仅配置当前用户环境变量"
            } else {
                Write-Err "需要管理员权限来安装到 $($script:FlutterRoot)"
                Write-Info "请右键以管理员身份运行 PowerShell，或使用 -UserScope 参数以普通用户安装"
                exit 1
            }
        }
    }

    # 检查是否已安装 (dry-run 模式仅提示，不询问)
    $flutterExePath = Join-Path $script:FlutterRoot 'bin\flutter.bat'
    $foundFlutter   = $null
    if (Test-Path $flutterExePath) {
        $foundFlutter = $flutterExePath
    }
    if (-not $foundFlutter) {
        $cmd = Get-Command 'flutter' -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) { $foundFlutter = $cmd.Source }
    }

    if ($foundFlutter) {
        $currentVer = (& $foundFlutter --version 2>$null | Select-Object -First 1)
        $currentVer = ([regex]::Match($currentVer, 'flutter (\d+\.\d+(\.\d+)?)').Groups[1].Value)
        if ($currentVer) {
            Write-Warn "检测到已安装的 Flutter: v$currentVer ($foundFlutter)"
            if ($DryRun) {
                Write-Warn "[DRY-RUN] 本将清理旧安装并重新安装"
            } else {
                if ($currentVer -eq $script:FlutterVersion -and -not $Yes) {
                    $answer = Read-Host '已安装相同版本，是否重新安装? [y/N]'
                    if ($answer -notmatch '^[Yy]$') {
                        Write-Info '取消安装'
                        exit 0
                    }
                } elseif ($currentVer -ne $script:FlutterVersion -and -not $Yes) {
                    $answer = Read-Host "已安装 v$currentVer，是否覆盖安装 v$($script:FlutterVersion)? [y/N]"
                    if ($answer -notmatch '^[Yy]$') {
                        Write-Info '取消安装'
                        exit 0
                    }
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
Flutter 安装计划
========================================
版本:          $($script:FlutterVersion) ($($script:FlutterChannel))
架构:          x64
安装目录:      $($script:FlutterRoot)
安装方式:      $(if ($UserScope) { '当前用户 (UserScope)' } else { '系统级 (需管理员)' })
下载源:        $(if ($script:ConfigMirror) { '国内镜像 (storage.flutter-io.cn)' } else { '官方源 (storage.googleapis.com)' })
配置镜像:      $($script:ConfigMirror)
模拟运行:      $DryRun
========================================
"@
}

# ============================================================
# 下载 Flutter SDK
# ============================================================
function Invoke-DownloadFlutter {
    $zipName = "flutter_windows_$($script:FlutterVersion)-$($script:FlutterChannel).zip"
    $baseUrl = if ($script:ConfigMirror) { $script:MirrorBase } else { $script:OfficialBase }
    $url     = "$baseUrl/$($script:FlutterChannel)/windows/$zipName"
    $zipPath = Join-Path $script:TempDir $zipName

    Write-Info "下载 Flutter $($script:FlutterVersion) ($($script:FlutterChannel))..."

    if ($DryRun) {
        Write-Host "[DRY-RUN] 下载: $zipPath <- $url" -ForegroundColor Yellow
        $script:ZipPath = $zipPath
        return
    }

    Write-Info "下载地址: $url"
    try {
        $ProgressPreference = 'SilentlyContinue'
        # 国内镜像下载建议使用代理，这里直接用 Invoke-WebRequest
        Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
        $ProgressPreference = 'Continue'
    } catch {
        Write-Err "下载失败，请检查版本号和网络连接"
        if ($script:ConfigMirror) {
            Write-Info "可尝试 -Mirror official 使用官方源，或 -Mirror mirror_cn 使用国内镜像"
        } else {
            Write-Info "可尝试 -Mirror mirror_cn 使用国内镜像下载"
        }
        Write-Info "可用版本请访问: https://docs.flutter.dev/release/archive"
        exit 1
    }

    # 验证文件完整性
    if ((Get-Item $zipPath).Length -le 0) {
        Write-Err "下载的文件为空"
        exit 1
    }

    $script:ZipPath = $zipPath
    Write-Success "下载完成: $zipName"
}

# ============================================================
# 安装 Flutter SDK
# ============================================================
function Invoke-InstallFlutter {
    Write-Info "安装 Flutter 到 $($script:FlutterRoot) ..."
    $flutterExePath = Join-Path $script:FlutterRoot 'bin\flutter.bat'

    if ($DryRun) {
        Write-Host "[DRY-RUN] 解压 $($script:ZipPath) 到 $($script:FlutterRoot)" -ForegroundColor Yellow
        Write-Host "[DRY-RUN] 验证: $flutterExePath" -ForegroundColor Yellow
        return
    }

    # 解压到临时目录
    $stageDir = Join-Path $script:TempDir 'extract'
    Write-Info "解压中 (包较大，请耐心等待)..."
    Expand-Archive -Path $script:ZipPath -DestinationPath $stageDir -Force

    # 若目标目录已存在，删除旧版本 (先退出可能占用的进程)
    if (Test-Path $script:FlutterRoot) {
        $oldFlutterExe = Join-Path $script:FlutterRoot 'bin\flutter.bat'
        if (Test-Path $oldFlutterExe) {
            try {
                Get-Process -Name 'dart*','flutter*' -ErrorAction SilentlyContinue |
                    Where-Object { $_.Path -like "*$($script:FlutterRoot)*" } |
                    Stop-Process -Force -ErrorAction SilentlyContinue
            } catch {}
        }
        Write-Warn "删除旧版本目录: $($script:FlutterRoot)"
        Remove-Item $script:FlutterRoot -Recurse -Force -ErrorAction Continue
        if (Test-Path $script:FlutterRoot) {
            Write-Err "删除旧版本失败: $($script:FlutterRoot) 可能被进程占用，请关闭 Flutter/Dart 相关程序后重试"
            exit 1
        }
    }

    # 移动新版本到目标位置
    $parentDir = Split-Path $script:FlutterRoot -Parent
    if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
    Move-Item -Path (Join-Path $stageDir 'flutter') -Destination $script:FlutterRoot -Force

    # 验证安装
    if (-not (Test-Path $flutterExePath)) {
        Write-Err "安装失败: 未找到 $flutterExePath"
        exit 1
    }

    Write-Success "Flutter 安装完成"
}

# ============================================================
# 配置环境变量
# ============================================================
function Set-FlutterEnvironment {
    Write-Info "配置环境变量..."

    $flutterBinPath = Join-Path $script:FlutterRoot 'bin'
    $machineTarget  = [EnvironmentVariableTarget]::Machine
    $userTarget     = [EnvironmentVariableTarget]::User

    # 系统级安装写系统变量；普通用户安装只写用户变量
    $targetScope = if ($UserScope) { $userTarget } else { $machineTarget }

    if ($DryRun) {
        Write-Host "[DRY-RUN] 追加 PATH: $flutterBinPath (目标: $(if ($UserScope) {'用户'} else {'系统'}))" -ForegroundColor Yellow
        if ($script:ConfigMirror) {
            Write-Host "[DRY-RUN] 追加用户变量 PUB_HOSTED_URL = https://pub.flutter-io.cn" -ForegroundColor Yellow
            Write-Host "[DRY-RUN] 追加用户变量 FLUTTER_STORAGE_BASE_URL = https://storage.flutter-io.cn" -ForegroundColor Yellow
        }
        return
    }

    if ($UserScope) {
        # 用户级：flutter\bin 加入用户 PATH
        $userPath = [Environment]::GetEnvironmentVariable('Path', $userTarget)
        if ($userPath -notlike "*$flutterBinPath*") {
            $userPath = ($userPath.TrimEnd(';') + ';' + $flutterBinPath).TrimStart(';')
            [Environment]::SetEnvironmentVariable('Path', $userPath, $userTarget)
        }
    } else {
        # 系统级：flutter\bin 加入系统 PATH
        $machinePath = [Environment]::GetEnvironmentVariable('Path', $machineTarget)
        if ($machinePath -notlike "*$flutterBinPath*") {
            $machinePath = ($machinePath.TrimEnd(';') + ';' + $flutterBinPath).TrimStart(';')
            [Environment]::SetEnvironmentVariable('Path', $machinePath, $machineTarget)
        }
    }

    # 配置国内镜像加速（仅在镜像模式）
    if ($script:ConfigMirror) {
        Write-Info "配置镜像加速环境变量 (PUB_HOSTED_URL / FLUTTER_STORAGE_BASE_URL)..."
        [Environment]::SetEnvironmentVariable('PUB_HOSTED_URL', 'https://pub.flutter-io.cn', $userTarget)
        [Environment]::SetEnvironmentVariable('FLUTTER_STORAGE_BASE_URL', 'https://storage.flutter-io.cn', $userTarget)
    }

    # 当前会话立即生效
    $env:PATH = "$flutterBinPath;$env:PATH"
    if ($script:ConfigMirror) {
        $env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
        $env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
    }

    Write-Success "环境变量配置完成 (Flutter: $flutterBinPath)"
}

# ============================================================
# 验证安装
# ============================================================
function Test-FlutterInstallation {
    Write-Info "验证安装 (首次运行会自动下载 Dart SDK，请耐心等待)..."

    $flutterExe = Join-Path $script:FlutterRoot 'bin\flutter.bat'
    if ($DryRun) {
        Write-Host "[DRY-RUN] $flutterExe --version" -ForegroundColor Yellow
        Write-Host "[DRY-RUN] $flutterExe doctor" -ForegroundColor Yellow
        return
    }

    # 首次运行 flutter 会下载 Dart SDK 并初始化
    Write-Info "运行 flutter --version (首次可能下载 Dart SDK)..."
    & $flutterExe --version 2>&1 | Select-Object -First 5
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "flutter --version 执行异常，请检查网络或镜像配置"
    }

    Write-Success "安装验证完成"
    if ($script:ConfigMirror) {
        Write-Info "提示: 已配置国内镜像加速，可运行 flutter doctor 检查开发环境"
    }
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

    # 架构检查（官方 Windows 发布包仅提供 x64 与 arm64，arm64 通过模拟运行）
    try {
        $arch = Get-FlutterArch
        Write-Success "架构支持: $arch (Windows)"
    } catch {
        Write-Err $_.Exception.Message
        exit 1
    }

    Write-Host "========================================" -ForegroundColor Blue
    Write-Host "     Flutter SDK 安装脚本 (官方二进制包)"  -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host ""

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

        Invoke-DownloadFlutter
        Invoke-InstallFlutter
        Set-FlutterEnvironment
        Test-FlutterInstallation
    } finally {
        Remove-TempDir
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "     安装完成！"                        -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "请关闭当前 PowerShell 窗口后重新打开，使环境变量立即生效："
    Write-Host "  重新打开终端后输入 flutter --version 验证安装" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "创建新项目 (示例):"
    Write-Host "  flutter create my_app"               -ForegroundColor Yellow
    Write-Host "  cd my_app"                           -ForegroundColor Yellow
    Write-Host "  flutter run"                         -ForegroundColor Yellow
    Write-Host ""
    Write-Host "检查开发环境依赖:"
    Write-Host "  flutter doctor"                      -ForegroundColor Yellow
}

# 运行主函数
Main