# @Author      ：幸运锦鲤
# @Time        : 2026-04-26 00:28:22
# @version     : powershell
# @Update time :
# @Description : Windows c/c++编译环境安装


$ErrorActionPreference = "Stop"

# Download URL
$DownloadUrl = "http://github.808066.xyz:38000/https://github.com/niXman/mingw-builds-binaries/releases/download/15.2.0-rt_v13-rev1/x86_64-15.2.0-release-win32-seh-ucrt-rt_v13-rev1.7z"

# File name
$FileName = "x86_64-15.2.0-release-win32-seh-ucrt-rt_v13-rev1.7z"

# Install directory
$InstallDir = "C:\Program Files\MinGW-w64"

# Temp download directory
$TempDir = "$env:TEMP\MinGW-w64"
$DownloadPath = "$TempDir\$FileName"

Write-Host "=== MinGW-w64 Installer ===" -ForegroundColor Cyan
Write-Host ""

# Create temp directory
if (!(Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}

# Create install directory
if (!(Test-Path $InstallDir)) {
    Write-Host "Creating install directory: $InstallDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# Download file
if (!(Test-Path $DownloadPath)) {
    Write-Host "Downloading MinGW-w64 ..." -ForegroundColor Yellow
    Write-Host "URL: $DownloadUrl" -ForegroundColor Gray

    try {
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $DownloadPath -UseBasicParsing
        Write-Host "Download completed!" -ForegroundColor Green
    } catch {
        Write-Host "Download failed: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "File exists, skipping download: $DownloadPath" -ForegroundColor Gray
}

# Extract file
Write-Host ""
Write-Host "Extracting to: $InstallDir" -ForegroundColor Yellow

# Check for 7z
$7zPath = $null
$possible7zPaths = @(
    "C:\Program Files\7-Zip\7z.exe",
    "C:\Program Files (x86)\7-Zip\7z.exe",
    "$env:ProgramFiles\7-Zip\7z.exe",
    "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
)

foreach ($path in $possible7zPaths) {
    if (Test-Path $path) {
        $7zPath = $path
        break
    }
}

if ($7zPath) {
    Write-Host "Using 7-Zip for extraction..." -ForegroundColor Gray
    & $7zPath x "$DownloadPath" -o"$InstallDir" -y | Out-Null

    # Handle nested directory structure (e.g., mingw64 folder inside)
    $topLevelDirs = Get-ChildItem -Path $InstallDir -Directory
    if ($topLevelDirs) {
        # Check if there's a single nested folder (common case: mingw64 inside)
        $nestedFolder = $topLevelDirs | Where-Object { $_.Name -notin @('bin', 'lib', 'include', 'x86_64-w64-mingw32') }
        if ($nestedFolder.Count -eq 1) {
            $nestedPath = $nestedFolder.FullName
            Write-Host "Detected nested structure, flattening..." -ForegroundColor Gray

            # Move all contents from nested folder to install directory
            Get-ChildItem -Path $nestedPath | Move-Item -Destination $InstallDir -Force
            Remove-Item -Path $nestedPath -Force
        }
    }
} else {
    Write-Host "7-Zip not found, trying to install via winget..." -ForegroundColor Yellow

    try {
        # Check if winget is available
        $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetPath) {
            Write-Host "Installing 7-Zip via winget..." -ForegroundColor Yellow
            winget install --id 7zip.7zip -e --silent --accept-package-agreements --accept-source-agreements
            Start-Sleep -Seconds 3
            $7zPath = "C:\Program Files\7-Zip\7z.exe"

            if (Test-Path $7zPath) {
                & $7zPath x "$DownloadPath" -o"$InstallDir" -y | Out-Null
            } else {
                throw "7-Zip installation via winget failed"
            }
        } else {
            throw "winget not found"
        }
    } catch {
        Write-Host "Error: Failed to install 7-Zip" -ForegroundColor Red
        Write-Host "Please install 7-Zip manually: https://www.7-zip.org/" -ForegroundColor Yellow
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }
}

Write-Host "Extraction completed!" -ForegroundColor Green

# Cleanup temp files
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

# Configure environment variables
Write-Host ""
Write-Host "Configuring environment variables..." -ForegroundColor Yellow

$MinGWbin = "$InstallDir\bin"
if (Test-Path $MinGWbin) {
    $env:Path = "$MinGWbin;$env:Path"

    # Permanent system PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($currentPath -notlike "*$MinGWbin*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$MinGWbin", "Machine")
        Write-Host "Added $MinGWbin to system PATH" -ForegroundColor Green
    }

    # Verify installation
    Write-Host ""
    Write-Host "Verifying installation..." -ForegroundColor Yellow
    $gppExePath = "$MinGWbin\g++.exe"
    if (Test-Path $gppExePath) {
        $gppVersion = & $gppExePath --version | Select-Object -First 1
        Write-Host "Installation successful!" -ForegroundColor Green
        Write-Host "g++ version: $gppVersion" -ForegroundColor Gray
    }

    $gccExePath = "$MinGWbin\gcc.exe"
    if (Test-Path $gccExePath) {
        $gccVersion = & $gccExePath --version | Select-Object -First 1
        Write-Host "gcc version: $gccVersion" -ForegroundColor Gray
    }
} else {
    Write-Host "Warning: bin directory not found, please check extraction result" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Installation Complete ===" -ForegroundColor Cyan
Write-Host "Install directory: $InstallDir" -ForegroundColor White
Write-Host "Please restart terminal or reopen PowerShell for PATH to take effect" -ForegroundColor Yellow
