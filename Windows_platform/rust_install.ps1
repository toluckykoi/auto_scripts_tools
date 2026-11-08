#!/usr/bin/env pwsh
# @Author      ：幸运锦鲤
# @Time        : 2026-11-08
# @version     : powershell
# @Update time : 2026-11-08
# @Description : Rust 语言安装脚本 - 使用 rustup 官方工具链安装（Windows 版，对应 Linux 下 rust_install.sh）

<#
.SYNOPSIS
    在 Windows 上使用 rustup 官方安装器安装 Rust 语言环境

.DESCRIPTION
    本脚本为 Linux_auto_scripts/Linux_software_install/rust_install.sh 的 Windows 版本。
    自动检测系统架构，从 rustup 官方源（可切换国内镜像）下载 rustup-init.exe 并安装，
    完成后配置 rustup 默认工具链、cargo 国内镜像（rsproxy/清华）、环境变量等。

    * rustup 默认仅安装到当前用户目录，无需管理员权限：
      - 工具链、cargo 安装目录: %USERPROFILE%\.cargo
      - rustup 自身: %USERPROFILE%\.rustup
    * 使用 -SystemWide 参数可在管理员权限下使用官方系统级安装（默认不支持官方遮蔽）
      （实际上 rustup 官方不支持系统全局，此参数仅用于提示）

.PARAMETER Toolchain
    要安装的工具链，如 stable/beta/nightly/1.75.0，默认为 stable

.PARAMETER Profile
    安装配置：minimal/default/complete，默认为 default

.PARAMETER Mirror
    rustup 下载与 cargo 镜像：official/rsproxy/ustc/tuna/auto，默认为 auto
    - auto: 自动探测可用镜像（依次尝试 ustc -> tuna -> rsproxy，全部失败回退官方）

.PARAMETER NoProxy
    不配置 cargo 国内镜像（默认配置）

.PARAMETER Yes
    跳过确认提示（已安装时直接重装）

.PARAMETER DryRun
    仅预览将要执行的操作，不实际执行

.PARAMETER Help
    显示帮助信息

.EXAMPLE
    .\rust_install.ps1                              # 自动探测镜像安装 stable
    .\rust_install.ps1 -Toolchain 1.75.0            # 安装指定工具链版本
    .\rust_install.ps1 -Mirror rsproxy              # 使用 rsproxy 镜像
    .\rust_install.ps1 -Profile minimal             # 最小化安装
    .\rust_install.ps1 -NoProxy                     # 不配置 cargo 镜像
    .\rust_install.ps1 -DryRun                      # 预览安装步骤

.NOTES
    需要 Windows 10 / Windows 11，PowerShell 5.1+。
    卸载: rustup self uninstall
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
$script:Toolchain   = if ($Toolchain) { $Toolchain } else { 'stable' }
$script:ConfigProxy = -not $NoProxy
$script:TempDir     = Join-Path ([System.IO.Path]::GetTempPath()) "rust_install_$PID"
# rustup 在 Windows 上的默认目录（用户级，不需要管理员）
$script:CargoHome   = Join-Path $env:USERPROFILE '.cargo'
$script:RustupHome  = Join-Path $env:USERPROFILE '.rustup'
$script:Arch        = $env:PROCESSOR_ARCHITECTURE
if ($env:PROCESSOR_ARCHITEW6432) { $script:Arch = $env:PROCESSOR_ARCHITEW6432 }

# 架构映射到 rustup 目标三元组
switch ($script:Arch) {
    'AMD64' { $script:RustupTarget = 'x86_64-pc-windows-msvc';   break }
    'ARM64' { $script:RustupTarget = 'aarch64-pc-windows-msvc';  break }
    default { Write-Err "不支持的架构: $script:Arch"; exit 1 }
}

# ============================================================
# 镜像配置（init 下载地址 / RUSTUP_DIST_SERVER / cargo crates）
# ============================================================
$script:MirrorUrl = @{
    #          init下载            dist_server          update_root           cargo镜像
    official = @{ init = 'https://static.rust-lang.org/rustup'; dist = 'https://static.rust-lang.org'; update = 'https://static.rust-lang.org/rustup'; cargo = '' }
    rsproxy  = @{ init = 'https://rsproxy.cn/rustup';            dist = 'https://rsproxy.cn/rustup';    update = 'https://rsproxy.cn/rustup';    cargo = 'sparse+https://rsproxy.cn/index/' }
    ustc     = @{ init = 'https://mirrors.ustc.edu.cn/rust-static/rustup'; dist = 'https://mirrors.ustc.edu.cn/rust-static'; update = 'https://mirrors.ustc.edu.cn/rust-static/rustup'; cargo = 'sparse+https://rsproxy.cn/index/' }
    tuna     = @{ init = 'https://mirrors.tuna.tsinghua.edu.cn/rustup';   dist = 'https://mirrors.tuna.tsinghua.edu.cn/rustup';   update = 'https://mirrors.tuna.tsinghua.edu.cn/rustup';   cargo = 'sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/' }
}
$script:Cfg = $null   # 实际生效的镜像配置

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
用法: .\$name [-Toolchain <stable|beta|nightly|版本号>] [选项]

选项:
    -Toolchain <版本>      指定工具链 (默认: stable)
    -Profile <类型>        安装配置 minimal/default/complete (默认: default)
    -Mirror <源>           rustup 下载源 official/rsproxy/ustc/tuna/auto (默认: auto)
                           auto 自动探测可用镜像; 下载失败自动回退 rsproxy -> 官方
    -NoProxy               不配置 cargo 国内镜像 (默认配置)
    -Yes                   跳过确认提示 (已安装时直接重装)
    -DryRun                仅预览将要执行的操作，不实际执行
    -Help                  显示此帮助信息

示例:
    .\$name                               # 自动探测镜像安装 stable
    .\$name -Toolchain 1.75.0             # 安装指定工具链版本
    .\$name -Mirror rsproxy               # 使用 rsproxy (字节) 镜像
    .\$name -Profile minimal              # 最小化安装 (仅 rustc/cargo/rustup)
    .\$name -NoProxy                      # 不配置 cargo 镜像
    .\$name -DryRun                       # 预览安装步骤

说明:
    - rustup 默认安装到当前用户目录: %USERPROFILE%\.cargo 和 %USERPROFILE%\.rustup，无需管理员
    - 建议使用 MSVC 工具链 (需安装 Visual Studio Build Tools)，也可换 GNU 工具链:
        rustup toolchain install stable-x86_64-pc-windows-gnu
    - 国内镜像同时覆盖 rustup 下载 (RUSTUP_DIST_SERVER) 与 crates.io 依赖源
    - 卸载: rustup self uninstall
"@
}

# ============================================================
# 基础工具函数
# ============================================================
# 下载文件（优先 curl，其次 Invoke-WebRequest）
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

# 探测 URL 是否可达
function Test-Url {
    param([string]$Url)
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -sfI --max-time 8 $Url *>$null
        return $LASTEXITCODE -eq 0
    }
    try {
        $ProgressPreference = 'SilentlyContinue'
        $r = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec 8
        return $true
    } catch {
        return $false
    }
}

# 探测可用镜像并设置 $script:Cfg
function Select-Mirror {
    if ($Mirror -eq 'auto') {
        Write-Info "自动探测可用国内镜像源..."
        foreach ($c in @('ustc', 'tuna', 'rsproxy')) {
            if ($c -eq 'ustc' -or $c -eq 'tuna') {
                $testUrl = "$($script:MirrorUrl[$c].init)/dist/$($script:RustupTarget)/rustup-init.exe"
            } else {
                $testUrl = "$($script:MirrorUrl[$c].init)/dist/$($script:RustupTarget)/rustup-init.exe"
            }
            if (Test-Url $testUrl) {
                Write-Success "已选择可用镜像: $c ($($script:MirrorUrl[$c].dist))"
                $script:Cfg = $script:MirrorUrl[$c]
                $script:EffectiveMirror = $c
                return
            }
            Write-Warn "镜像 $c 不可用，尝试下一个..."
        }
        Write-Warn "所有国内镜像均不可用，回退官方源"
        $script:Cfg = $script:MirrorUrl['official']
        $script:EffectiveMirror = 'official'
    } else {
        $script:Cfg = $script:MirrorUrl[$Mirror]
        $script:EffectiveMirror = $Mirror
        Write-Info "使用镜像: $Mirror ($($script:Cfg.dist))"
    }
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

    # 工具链格式校验
    if ($script:Toolchain -notmatch '^(stable|beta|nightly|\d+\.\d+(\.\d+)?)$') {
        Write-Err "无效的工具链: $($script:Toolchain) (可选: stable/beta/nightly/版本号)"
        exit 1
    }

    # 探测可用镜像
    Select-Mirror

    # 检查是否已安装 rustup
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
# 显示安装计划
# ============================================================
function Show-Plan {
    Write-Host @"
========================================
Rust 安装计划
========================================
工具链:        $($script:Toolchain) (profile: $Profile)
架构:          $($script:Arch) ($($script:RustupTarget))
安装位置:      $($script:CargoHome) (rustup: $($script:RustupHome))
下载地址:      $($script:Cfg.init)/dist/$($script:RustupTarget)/rustup-init.exe
下载源:        $($script:EffectiveMirror)
配置 cargo 镜像: $($script:ConfigProxy -and $script:Cfg.cargo -ne '')
模拟运行:      $DryRun
========================================
"@ -ForegroundColor Gray
}

# ============================================================
# 下载 rustup-init.exe（带自动回退）
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

    # 依次尝试: 当前配置源 -> rsproxy -> 官方
    $candidates = @(
        @{ init = $script:Cfg.init; dist = $($script:Cfg.dist); update = $($script:Cfg.update) }
        @{ init = 'https://rsproxy.cn/rustup'; dist = 'https://rsproxy.cn/rustup'; update = 'https://rsproxy.cn/rustup' }
        @{ init = 'https://static.rust-lang.org/rustup'; dist = 'https://static.rust-lang.org'; update = 'https://static.rust-lang.org/rustup' }
    ) | Select-Object -Unique -Property init, dist, update

    $exePath = Join-Path $script:TempDir 'rustup-init.exe'
    $ok = $false
    foreach ($c in $candidates) {
        $url = "$($c.init)/dist/$($script:RustupTarget)/rustup-init.exe"
        Write-Info "尝试下载: $url"
        if (Invoke-Download -Url $url -OutFile $exePath) {
            # 成功，绑定实际源供后续工具链安装
            $script:Cfg = @{ init = $c.init; dist = $c.dist; update = $c.update; cargo = $script:Cfg.cargo }
            $ok = $true
            break
        }
        Write-Warn "下载失败，尝试下一个源..."
        if (Test-Path $exePath) { Remove-Item $exePath -Force -ErrorAction SilentlyContinue }
    }

    if (-not $ok) {
        Write-Err "所有源下载均失败，请检查网络连接"
        Write-Err "可尝试: .\$($MyInvocation.MyCommand.Name) -Mirror auto"
        exit 1
    }

    # 若回退到官方源，清空 cargo 镜像配置（避免指向不可用源）
    if ($script:Cfg.init -like '*static.rust-lang.org*') {
        $script:Cfg.cargo = ''
    }

    Write-Success "下载完成: $exePath (来自 $($script:Cfg.dist))"
}

# ============================================================
# 安装 Rust
# ============================================================
function Invoke-InstallRust {
    Write-Info "安装 Rust 工具链 $($script:Toolchain) (profile: $Profile)..."

    $exePath = Join-Path $script:TempDir 'rustup-init.exe'
    if ($DryRun) {
        Write-Host "[DRY-RUN] RUSTUP_DIST_SERVER=$($script:Cfg.dist) RUSTUP_UPDATE_ROOT=$($script:Cfg.update)" -ForegroundColor Yellow
        Write-Host "[DRY-RUN] $exePath -y --default-toolchain $($script:Toolchain) --profile $Profile --no-modify-path" -ForegroundColor Yellow
        return
    }

    # 设置镜像环境变量后执行安装（rustup-init 会读取）
    $env:RUSTUP_DIST_SERVER = $script:Cfg.dist
    $env:RUSTUP_UPDATE_ROOT  = $script:Cfg.update
    $env:RUSTUP_HOME         = $script:RustupHome   # python 或其它工具可能读取

    try {
        & $exePath -y --default-toolchain $script:Toolchain --profile $Profile --no-modify-path
        if ($LASTEXITCODE -ne 0) {
            Write-Err "安装失败 (退出码 $LASTEXITCODE)，请查看上方错误信息"
            exit 1
        }
    } finally {
        $env:RUSTUP_DIST_SERVER = $null
        $env:RUSTUP_UPDATE_ROOT  = $null
        $env:RUSTUP_HOME         = $null
    }

    Write-Success "Rust 安装完成"
}

# ============================================================
# 配置环境变量（将 ~/.cargo\env 加入用户 PATH；默认 rustup 已配置）
# ============================================================
function Set-RustEnvironment {
    Write-Info "配置环境变量..."

    # rustup 会生成 %USERPROFILE%\.cargo\env.ps1，直接 source 到当前会话
    $cargoEnvPs1 = Join-Path $script:CargoHome 'env.ps1'

    if ($DryRun) {
        Write-Host "[DRY-RUN] 当前会话加载: $cargoEnvPs1" -ForegroundColor Yellow
        return
    }

    if (Test-Path $cargoEnvPs1) {
        & $cargoEnvPs1
        Write-Success "已加载环境变量: $cargoEnvPs1"
    } else {
        Write-Warn "未找到 $cargoEnvPs1，检查安装是否完成"
    }

    # 确保 bin 目录在用户 PATH（防遗漏，不覆盖已有）
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $cargoBin = Join-Path $script:CargoHome 'bin'
    if ($userPath -notlike "*$cargoBin*") {
        if (-not $DryRun) {
            [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ';' + $cargoBin), 'User')
            Write-Success "已将 $cargoBin 加入用户 PATH"
        }
    } else {
        Write-Success "$cargoBin 已在用户 PATH 中"
    }
}

# ============================================================
# 配置 cargo 国内镜像 (~/.cargo/config.toml)
# ============================================================
function Set-CargoMirror {
    if ($script:NoProxy -or $script:Cfg.cargo -eq '') {
        Write-Info "跳过 cargo 国内镜像配置"
        return
    }

    $configFile = Join-Path $script:CargoHome 'config.toml'
    Write-Info "配置 cargo 国内镜像 ($script:EffectiveMirror): $($script:Cfg.cargo)"

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

    # 备份已有配置
    if ((Test-Path $configFile) -and (Select-String -Path $configFile -Pattern '\[source\.crates-io\]' -Quiet) -and -not (Test-Path "$configFile.bak")) {
        Copy-Item $configFile "$configFile.bak"
        Write-Warn "已备份原配置文件到 $configFile.bak"
    }

    # 移除旧块，避免残留冲突
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
    Write-Info "如需还原: copy $configFile.bak $configFile (若存在)"
}

# ============================================================
# 验证安装
# ============================================================
function Test-RustInstallation {
    Write-Info "验证安装..."

    if ($DryRun) {
        Write-Host "[DRY-RUN] rustc --version" -ForegroundColor Yellow
        Write-Host "[DRY-RUN] cargo --version" -ForegroundColor Yellow
        Write-Host "[DRY-RUN] rustup --version" -ForegroundColor Yellow
        return
    }

    $cargoBin = Join-Path $script:CargoHome 'bin'
    $rustc = Join-Path $cargoBin 'rustc.exe'
    $cargo = Join-Path $cargoBin 'cargo.exe'
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
    # 尝试设置 UTF-8 输出（部分终端 GBK 默认导致中文乱码）
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
    Write-Host "开始编程 (示例):" -ForegroundColor Yellow
    Write-Host "  cargo new hello_world; cd hello_world; cargo run" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "常用命令:" -ForegroundColor Yellow
    Write-Host "  rustup update                升级工具链" -ForegroundColor Yellow
    Write-Host "  rustup self uninstall        卸载 Rust" -ForegroundColor Yellow
}

# 运行主函数
Main