#!/usr/bin/env pwsh
# @Author      ：幸运锦鲤
# @Time        : 2026-11-08
# @version     : powershell
# @Update time : 2026-11-09
# @Description : Rust 语言安装脚本 - 使用 rustup 官方工具链安装（Windows 版）

<#
.SYNOPSIS
    在 Windows 上使用 rustup 官方安装器安装 Rust 语言环境

.DESCRIPTION
    镜像路径严格按照各镜像站官方说明配置：
    * USTC   https://mirrors.ustc.edu.cn/help/rust-static.html
    * TUNA   https://mirrors.tuna.tsinghua.edu.cn/help/rustup/
    * rsproxy https://rsproxy.cn/#getStarted

.PARAMETER Toolchain
    要安装的工具链，如 stable/beta/nightly/1.75.0，默认为 stable
.PARAMETER Profile
    安装配置：minimal/default/complete，默认为 default
.PARAMETER Mirror
    镜像源：official/rsproxy/ustc/tuna/auto，默认为 auto
.PARAMETER NoProxy
    不配置 cargo 国内镜像
.PARAMETER Yes
    跳过确认提示
.PARAMETER DryRun
    仅预览
.PARAMETER Help
    显示帮助
#>

[CmdletBinding()]
param(
    [string]$Toolchain = $null,
    [ValidateSet('minimal', 'default', 'complete')]
    [string]$Profile   = 'default',
    [ValidateSet('official', 'rsproxy', 'ustc', 'tuna', 'auto')]
    [string]$Mirror    = 'auto',
    [switch]$NoProxy,
    [switch]$Yes,
    [switch]$DryRun,
    [switch]$Help
)

# ============================================================
# 默认配置
# ============================================================
$script:Toolchain       = if ($Toolchain) { $Toolchain } else { 'stable' }
$script:ConfigProxy     = -not $NoProxy
$script:TempDir         = Join-Path ([System.IO.Path]::GetTempPath()) "rust_install_$PID"
$script:CargoHome       = Join-Path $env:USERPROFILE '.cargo'
$script:RustupHome      = Join-Path $env:USERPROFILE '.rustup'
$script:EffectiveMirror = $null
$script:Arch            = $env:PROCESSOR_ARCHITECTURE
if ($env:PROCESSOR_ARCHITEW6432) { $script:Arch = $env:PROCESSOR_ARCHITEW6432 }

switch ($script:Arch) {
    'AMD64' { $script:RustupTarget = 'x86_64-pc-windows-msvc';   break }
    'ARM64' { $script:RustupTarget = 'aarch64-pc-windows-msvc';  break }
    default { Write-Host "[ERROR]   不支持的架构: $script:Arch" -ForegroundColor Red; exit 1 }
}

# ============================================================
# 镜像配置（严格按各镜像官方文档）
#   init   = rustup-init.exe 下载根    (= RUSTUP_UPDATE_ROOT)
#   dist   = RUSTUP_DIST_SERVER       (工具链 + channel 元数据根)
#   update = RUSTUP_UPDATE_ROOT       (rustup 自更新根)
#   cargo  = crates.io 稀疏索引
# ============================================================
$script:MirrorUrl = @{
    official = @{
        init   = 'https://static.rust-lang.org/rustup'
        dist   = 'https://static.rust-lang.org'
        update = 'https://static.rust-lang.org/rustup'
        cargo  = ''
    }
    ustc = @{
        init   = 'https://mirrors.ustc.edu.cn/rust-static/rustup'
        dist   = 'https://mirrors.ustc.edu.cn/rust-static'
        update = 'https://mirrors.ustc.edu.cn/rust-static/rustup'
        cargo  = 'sparse+https://mirrors.ustc.edu.cn/crates.io-index/'
    }
    tuna = @{
        init   = 'https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup'
        dist   = 'https://mirrors.tuna.tsinghua.edu.cn/rustup'
        update = 'https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup'
        cargo  = 'sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/'
    }
    rsproxy = @{
        init   = 'https://rsproxy.cn/rustup'
        dist   = 'https://rsproxy.cn'            # ★ 修正：原来错写成 .../rustup
        update = 'https://rsproxy.cn/rustup'
        cargo  = 'sparse+https://rsproxy.cn/index/'
    }
}
$script:Cfg = $null

# ============================================================
# 日志
# ============================================================
function Write-Info    { Write-Host "[INFO]    $args" -ForegroundColor Blue }
function Write-Success { Write-Host "[SUCCESS] $args" -ForegroundColor Green }
function Write-Warn    { Write-Host "[WARN]    $args" -ForegroundColor Yellow }
function Write-Err     { Write-Host "[ERROR]   $args" -ForegroundColor Red }

# ============================================================
# 帮助
# ============================================================
function Show-Help {
    $name = Split-Path -Leaf $PSCommandPath
    Write-Host @"
用法: .\$name [-Toolchain <stable|beta|nightly|版本号>] [选项]

选项:
    -Toolchain <版本>      指定工具链 (默认: stable)
    -Profile <类型>        安装配置 minimal/default/complete (默认: default)
    -Mirror <源>           rustup 下载源 official/rsproxy/ustc/tuna/auto (默认: auto)
    -NoProxy               不配置 cargo 国内镜像
    -Yes                   跳过确认提示
    -DryRun                仅预览
    -Help                  显示此帮助

镜像路径按各镜像站官方文档配置：
    USTC    RUSTUP_DIST_SERVER = https://mirrors.ustc.edu.cn/rust-static
            RUSTUP_UPDATE_ROOT = https://mirrors.ustc.edu.cn/rust-static/rustup
    TUNA    RUSTUP_DIST_SERVER = https://mirrors.tuna.tsinghua.edu.cn/rustup
            RUSTUP_UPDATE_ROOT = https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup
    rsproxy RUSTUP_DIST_SERVER = https://rsproxy.cn
            RUSTUP_UPDATE_ROOT = https://rsproxy.cn/rustup
"@
}

# ============================================================
# 基础工具
# ============================================================
function Invoke-Download {
    param([string]$Url, [string]$OutFile)
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -fSL --progress-bar $Url -o $OutFile 2>$null
        return $LASTEXITCODE -eq 0 -and (Test-Path $OutFile) -and (Get-Item $OutFile).Length -gt 0
    }
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -TimeoutSec 120
        return (Test-Path $OutFile) -and (Get-Item $OutFile).Length -gt 0
    } catch {
        return $false
    }
}

function Test-Url {
    param([string]$Url)
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -sfI --max-time 8 $Url *>$null
        return $LASTEXITCODE -eq 0
    }
    try {
        $ProgressPreference = 'SilentlyContinue'
        $null = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec 8
        return $true
    } catch {
        return $false
    }
}

# 完整校验一个镜像是否可用：
#   1) rustup-init.exe 可下载
#   2) dist 根目录下 channel-rust-stable.toml 存在（这是之前报错的根因）
function Test-MirrorAvailable {
    param([string]$Name)
    $cfg = $script:MirrorUrl[$Name]

    $initUrl = "$($cfg.init)/dist/$($script:RustupTarget)/rustup-init.exe"
    if (-not (Test-Url $initUrl)) {
        Write-Warn "  [$Name] rustup-init.exe 不可达: $initUrl"
        return $false
    }

    $channelUrl = "$($cfg.dist)/dist/channel-rust-stable.toml"
    if (-not (Test-Url $channelUrl)) {
        Write-Warn "  [$Name] 缺少 stable 频道元数据: $channelUrl"
        return $false
    }

    return $true
}

function Select-Mirror {
    if ($Mirror -eq 'auto') {
        Write-Info "自动探测可用国内镜像源（校验 rustup-init + channel-rust-stable）..."
        foreach ($c in @('ustc', 'tuna', 'rsproxy')) {
            Write-Info "测试镜像: $c"
            if (Test-MirrorAvailable $c) {
                Write-Success "已选择可用镜像: $c"
                Write-Info "  RUSTUP_DIST_SERVER = $($script:MirrorUrl[$c].dist)"
                Write-Info "  RUSTUP_UPDATE_ROOT = $($script:MirrorUrl[$c].update)"
                $script:Cfg = $script:MirrorUrl[$c]
                $script:EffectiveMirror = $c
                return
            }
        }
        Write-Warn "所有国内镜像均不可用，回退官方源"
        $script:Cfg = $script:MirrorUrl['official']
        $script:EffectiveMirror = 'official'
    } else {
        $script:Cfg = $script:MirrorUrl[$Mirror]
        $script:EffectiveMirror = $Mirror
        Write-Info "使用镜像: $Mirror"
        Write-Info "  RUSTUP_DIST_SERVER = $($script:Cfg.dist)"
        Write-Info "  RUSTUP_UPDATE_ROOT = $($script:Cfg.update)"
    }
}

# ============================================================
# 预检查
# ============================================================
function Preflight-Check {
    Write-Info "开始预检查..."

    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Err "PowerShell 版本过低，请使用 5.1 及以上版本"
        exit 1
    }

    if ($script:Toolchain -notmatch '^(stable|beta|nightly|\d+\.\d+(\.\d+)?)$') {
        Write-Err "无效的工具链: $($script:Toolchain)"
        exit 1
    }

    Select-Mirror

    $rustupExe = Join-Path $script:CargoHome 'bin\rustup.exe'
    if (Get-Command rustup -ErrorAction SilentlyContinue) {
        $existingRustup = (Get-Command rustup).Source
    } elseif (Test-Path $rustupExe) {
        $existingRustup = $rustupExe
    } else {
        $existingRustup = $null
    }

    if ($existingRustup) {
        $installedVer = (& $existingRustup --version 2>$null | Select-Object -First 1)
        Write-Warn "检测到已安装的 Rust: $installedVer ($existingRustup)"

        if ($DryRun) {
            Write-Warn "[DRY-RUN] 真实运行时会询问是否重新安装"
            return
        }
        if (-not $Yes) {
            $answer = Read-Host '是否重新安装? [y/N]'
            if ($answer -notmatch '^[Yy]$') {
                Write-Info '已取消，保留现有安装'
                Write-Info "如需升级现有工具链: rustup update $($script:Toolchain)"
                exit 0
            }
        } else {
            Write-Info "检测到 -Yes 参数，直接重新安装"
        }
    }

    Write-Success "预检查通过"
}

# ============================================================
# 安装计划
# ============================================================
function Show-Plan {
    Write-Host @"
========================================
Rust 安装计划
========================================
工具链:            $($script:Toolchain) (profile: $Profile)
架构:              $($script:Arch) ($($script:RustupTarget))
安装位置:          $($script:CargoHome) (rustup: $($script:RustupHome))
下载源:            $($script:EffectiveMirror)
RUSTUP_DIST_SERVER: $($script:Cfg.dist)
RUSTUP_UPDATE_ROOT: $($script:Cfg.update)
rustup-init 下载:   $($script:Cfg.init)/dist/$($script:RustupTarget)/rustup-init.exe
配置 cargo 镜像:    $($script:ConfigProxy -and $script:Cfg.cargo -ne '')
模拟运行:          $DryRun
========================================
"@ -ForegroundColor Gray
}

# ============================================================
# 下载 rustup-init.exe
# ============================================================
function Invoke-DownloadRustupInit {
    Write-Info "下载 rustup-init.exe ($($script:RustupTarget))..."

    if (-not (Test-Path $script:TempDir)) {
        New-Item -ItemType Directory -Path $script:TempDir -Force | Out-Null
    }

    if ($DryRun) {
        Write-Host "[DRY-RUN] 下载: $($script:Cfg.init)/dist/$($script:RustupTarget)/rustup-init.exe" -ForegroundColor Yellow
        return
    }

    # 候选顺序: 当前源 -> rsproxy -> 官方
    $active   = $script:MirrorUrl[$script:EffectiveMirror]
    $rsproxy  = $script:MirrorUrl['rsproxy']
    $official = $script:MirrorUrl['official']

    $candidates = @(
        @{ name = $script:EffectiveMirror; init = $active.init;   dist = $active.dist;   update = $active.update   }
        @{ name = 'rsproxy';               init = $rsproxy.init;  dist = $rsproxy.dist;  update = $rsproxy.update  }
        @{ name = 'official';              init = $official.init; dist = $official.dist; update = $official.update }
    )

    # 按 init 去重
    $seen = @{}
    $unique = @()
    foreach ($c in $candidates) {
        if (-not $seen.ContainsKey($c.init)) {
            $seen[$c.init] = $true
            $unique += $c
        }
    }
    $candidates = $unique

    $exePath = Join-Path $script:TempDir 'rustup-init.exe'
    $ok = $false
    foreach ($c in $candidates) {
        $url = "$($c.init)/dist/$($script:RustupTarget)/rustup-init.exe"
        Write-Info "尝试下载: $url"
        if (Invoke-Download -Url $url -OutFile $exePath) {
            $script:Cfg = @{
                init   = $c.init
                dist   = $c.dist
                update = $c.update
                cargo  = $script:MirrorUrl[$c.name].cargo
            }
            $ok = $true
            break
        }
        Write-Warn "下载失败，尝试下一个源..."
        if (Test-Path $exePath) { Remove-Item $exePath -Force -ErrorAction SilentlyContinue }
    }

    if (-not $ok) {
        Write-Err "所有源下载均失败，请检查网络连接"
        exit 1
    }

    Write-Success "下载完成: $exePath (来自 $($script:Cfg.init))"
}

# ============================================================
# 安装 Rust（镜像失败自动回退官方源）
# ============================================================
function Invoke-InstallRust {
    Write-Info "安装 Rust 工具链 $($script:Toolchain) (profile: $Profile)..."

    $exePath = Join-Path $script:TempDir 'rustup-init.exe'
    if ($DryRun) {
        Write-Host "[DRY-RUN] RUSTUP_DIST_SERVER=$($script:Cfg.dist) RUSTUP_UPDATE_ROOT=$($script:Cfg.update)" -ForegroundColor Yellow
        Write-Host "[DRY-RUN] $exePath -y --default-toolchain $($script:Toolchain) --profile $Profile --no-modify-path" -ForegroundColor Yellow
        return
    }

    # 第一次尝试：当前镜像
    $env:RUSTUP_DIST_SERVER = $script:Cfg.dist
    $env:RUSTUP_UPDATE_ROOT  = $script:Cfg.update
    $env:RUSTUP_HOME         = $script:RustupHome
    try {
        $output = & $exePath -y --default-toolchain $script:Toolchain --profile $Profile --no-modify-path 2>&1
        $exitCode = $LASTEXITCODE
        $output | ForEach-Object { Write-Host $_ }
    } finally {
        $env:RUSTUP_DIST_SERVER = $null
        $env:RUSTUP_UPDATE_ROOT  = $null
        $env:RUSTUP_HOME         = $null
    }

    if ($exitCode -eq 0) {
        Write-Success "Rust 安装完成"
        return
    }

    $errText = $output -join "`n"
    if ($errText -match 'no release found' -and $script:EffectiveMirror -ne 'official') {
        Write-Warn "镜像 $($script:EffectiveMirror) 仍缺少 stable 频道，回退官方源重试..."

        $off = $script:MirrorUrl['official']
        $env:RUSTUP_DIST_SERVER = $off.dist
        $env:RUSTUP_UPDATE_ROOT  = $off.update
        $env:RUSTUP_HOME         = $script:RustupHome
        try {
            $retryOutput = & $exePath -y --default-toolchain $script:Toolchain --profile $Profile --no-modify-path 2>&1
            $retryExitCode = $LASTEXITCODE
            $retryOutput | ForEach-Object { Write-Host $_ }
        } finally {
            $env:RUSTUP_DIST_SERVER = $null
            $env:RUSTUP_UPDATE_ROOT  = $null
            $env:RUSTUP_HOME         = $null
        }

        if ($retryExitCode -ne 0) {
            Write-Err "官方源安装仍然失败 (退出码 $retryExitCode)"
            exit 1
        }

        $script:Cfg.cargo = ''
        Write-Success "已通过官方源完成 Rust 安装"
        Write-Info "cargo 国内镜像已临时禁用"
        return
    }

    Write-Err "安装失败 (退出码 $exitCode)，请查看上方错误信息"
    Write-Info "可尝试: .\$($MyInvocation.MyCommand.Name) -Mirror official"
    exit 1
}

# ============================================================
# 环境变量
# ============================================================
function Set-RustEnvironment {
    Write-Info "配置环境变量..."
    $cargoEnvPs1 = Join-Path $script:CargoHome 'env.ps1'
    if ($DryRun) {
        Write-Host "[DRY-RUN] 加载: $cargoEnvPs1" -ForegroundColor Yellow
        return
    }

    if (Test-Path $cargoEnvPs1) {
        & $cargoEnvPs1
        Write-Success "已加载环境变量: $cargoEnvPs1"
    } else {
        Write-Warn "未找到 $cargoEnvPs1"
    }

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $cargoBin = Join-Path $script:CargoHome 'bin'
    if ($userPath -notlike "*$cargoBin*") {
        [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ';' + $cargoBin), 'User')
        Write-Success "已将 $cargoBin 加入用户 PATH"
    } else {
        Write-Success "$cargoBin 已在用户 PATH 中"
    }
}

# ============================================================
# cargo 镜像
# ============================================================
function Set-CargoMirror {
    if ($NoProxy -or [string]::IsNullOrEmpty($script:Cfg.cargo)) {
        Write-Info "跳过 cargo 国内镜像配置"
        return
    }

    $configFile = Join-Path $script:CargoHome 'config.toml'
    Write-Info "配置 cargo 国内镜像 ($($script:EffectiveMirror)): $($script:Cfg.cargo)"

    if (-not (Test-Path $script:CargoHome)) {
        New-Item -ItemType Directory -Path $script:CargoHome -Force | Out-Null
    }

    if ($DryRun) {
        Write-Host "[DRY-RUN] 写入 ${configFile}:" -ForegroundColor Yellow
        Write-Host "  [source.crates-io]" -ForegroundColor Yellow
        Write-Host "  replace-with = 'mirror'" -ForegroundColor Yellow
        Write-Host "  [source.mirror]" -ForegroundColor Yellow
        Write-Host "  registry = `"$($script:Cfg.cargo)`"" -ForegroundColor Yellow
        return
    }

    if ((Test-Path $configFile) -and (Select-String -Path $configFile -Pattern '\[source\.crates-io\]' -Quiet) -and -not (Test-Path "$configFile.bak")) {
        Copy-Item $configFile "$configFile.bak"
        Write-Warn "已备份原配置文件到 $configFile.bak"
    }

    if (Test-Path $configFile) {
        $content = Get-Content $configFile | Where-Object { $_ -notmatch '^\[source\.crates-io\]$|^replace-with = ' }
        $content | Set-Content $configFile -Encoding UTF8
    }

    @"

# Rust crates.io 镜像配置 (由 rust_install.ps1 生成)
[source.crates-io]
replace-with = 'mirror'

[source.mirror]
registry = "$($script:Cfg.cargo)"
"@ | Add-Content $configFile -Encoding UTF8

    Write-Success "cargo 镜像配置完成: $configFile"
}

# ============================================================
# 验证
# ============================================================
function Test-RustInstallation {
    Write-Info "验证安装..."

    if ($DryRun) {
        Write-Host "[DRY-RUN] rustc --version / cargo --version / rustup --version" -ForegroundColor Yellow
        return
    }

    $cargoBin = Join-Path $script:CargoHome 'bin'
    $rustc  = Join-Path $cargoBin 'rustc.exe'
    $cargo  = Join-Path $cargoBin 'cargo.exe'
    $rustup = Join-Path $cargoBin 'rustup.exe'

    if (-not (Test-Path $rustc)) {
        Write-Err "rustc 验证失败，请检查安装"
        exit 1
    }

    Write-Success "rustc 版本: $(& $rustc --version)"
    Write-Success "cargo 版本: $(& $cargo --version)"
    Write-Success "rustup 版本: $(& $rustup --version)"
    Write-Info "已安装工具链: $(& $rustup toolchain list | Out-String)"
}

# ============================================================
# 清理
# ============================================================
function Remove-TempDir {
    if (Test-Path $script:TempDir) {
        if ($DryRun) {
            Write-Host "[DRY-RUN] 清理: $($script:TempDir)" -ForegroundColor Yellow
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
    try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

    if ($Help) { Show-Help; exit 0 }

    Write-Host "========================================" -ForegroundColor Blue
    Write-Host "   Rust 语言安装脚本 (rustup 官方工具链)" -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host ""

    try {
        Preflight-Check
        Show-Plan

        if ($DryRun) {
            Write-Info "模拟运行模式，不执行实际操作"
            Write-Host ""
        }

        Invoke-DownloadRustupInit
        Invoke-InstallRust
        Set-RustEnvironment
        Set-CargoMirror
        Test-RustInstallation
    } finally {
        Remove-TempDir
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "     安装完成！"                        -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "请关闭当前 PowerShell 窗口后重新打开，使环境变量立即生效:" -ForegroundColor Yellow
    Write-Host "  验证: rustc --version && cargo --version" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "常用命令:" -ForegroundColor Yellow
    Write-Host "  rustup update                升级工具链" -ForegroundColor Yellow
    Write-Host "  rustup self uninstall        卸载 Rust" -ForegroundColor Yellow
}

Main