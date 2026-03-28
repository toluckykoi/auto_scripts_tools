#!/usr/bin/env pwsh
# @Author      ：幸运锦鲤
# @Time        : 2026-03-28 20:47:01
# @version     : powershell
# @Update time :
# @Description : 用于管理 (auto_scripts_tools) Mkfile_Manager 文件的程序

<#
.SYNOPSIS
    管理 (auto_scripts_tools) Mkfile_Manager 文件的脚本（PowerShell 版本）

.DESCRIPTION
    用于创建带有标准文件头的 .sh / .py / .ps1 脚本文件，以及更新文件头中的 @Update time 字段。

.EXAMPLE
    .\)Mkfile_Manager.ps1 -c hello.sh
    .\)Mkfile_Manager.ps1 -c hello.py
    .\)Mkfile_Manager.ps1 -c hello.py -d "主程序"
    .\)Mkfile_Manager.ps1 -c hello.ps1 -d "PowerShell脚本"
    .\)Mkfile_Manager.ps1 -u hello.py
#>

param (
    [string]$c,       # 创建文件
    [string]$u,       # 更新 @Update time
    [string]$d = "",  # 描述（配合 -c 使用）
    [switch]$h        # 显示帮助
)

# ── 辅助函数 ────────────────────────────────────────────────────────────────

function Show-Usage {
    $name = Split-Path -Leaf $PSCommandPath
    Write-Host @"
用法：
  .\$name [选项] <文件名>

选项：
  -c <文件名>    创建新文件并写入文件头（支持 .sh / .py / .ps1）
  -u <文件名>    更新文件头中的 @Update time 为当前时间
  -d <描述>      创建时附加 @Description 内容（配合 -c 使用）
  -h             显示帮助信息

示例：
  .\$name -c hello.sh                  # 创建 Shell 脚本
  .\$name -c hello.py                  # 创建 Python 脚本
  .\$name -c hello.ps1                 # 创建 PowerShell 脚本
  .\$name -c hello.py -d "主程序"       # 创建时附加描述
  .\$name -u hello.py                  # 更新 Update time
"@
    exit 0
}

function Get-Now {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

# ── 文件头模板 ───────────────────────────────────────────────────────────────

function Get-ShHeader {
    param ([string]$Desc)
    $now = Get-Now
    return @"
#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : $now
# @version     : bash
# @Update time :
# @Description : $Desc

"@
}

function Get-PyHeader {
    param ([string]$Desc)
    $now = Get-Now
    return @"
#!/usr/bin/env python
# -*-coding:utf-8 -*-

'''
# @Author      ：幸运锦鲤
# @Time        : $now
# @version     : python3
# @Update time :
# @Description : $Desc
'''

"@
}

function Get-Ps1Header {
    param ([string]$Desc)
    $now = Get-Now

    if ($IsLinux -or $IsMacOS) {
        return @"
#!/usr/bin/env pwsh

# @Author      ：幸运锦鲤
# @Time        : $now
# @version     : powershell
# @Update time :
# @Description : $Desc

"@
    } else {
        return @"
<#
# @Author      ：幸运锦鲤
# @Time        : $now
# @version     : powershell
# @Update time :
# @Description : $Desc
#>

"@
    }
}

# ── 核心功能 ─────────────────────────────────────────────────────────────────
function New-ScriptFile {
    param (
        [string]$FilePath,
        [string]$Desc
    )

    $ext = [System.IO.Path]::GetExtension($FilePath).TrimStart('.')

    # 文件已存在则询问是否覆盖
    if (Test-Path $FilePath) {
        $confirm = Read-Host "文件 '$FilePath' 已存在，是否覆盖？[y/N]"
        if ($confirm -notmatch '^[Yy]$') {
            Write-Host "已取消。"
            exit 0
        }
    }

    switch ($ext) {
        'sh' {
            $header = Get-ShHeader -Desc $Desc
            # 使用 UTF-8 无 BOM 编码，保持 Unix 换行符
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText(
                (Resolve-NewPath $FilePath),
                ($header -replace "`r`n", "`n"),
                $utf8NoBom
            )
            Write-Host "已创建 Shell 脚本：$FilePath"
        }
        'py' {
            $header = Get-PyHeader -Desc $Desc
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText(
                (Resolve-NewPath $FilePath),
                ($header -replace "`r`n", "`n"),
                $utf8NoBom
            )
            Write-Host "已创建 Python 脚本：$FilePath"
        }
        'ps1' {
            $header = Get-Ps1Header -Desc $Desc
            # ps1 使用 UTF-8 无 BOM，Windows 换行符
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText(
                (Resolve-NewPath $FilePath),
                $header,
                $utf8NoBom
            )
            Write-Host "已创建 PowerShell 脚本：$FilePath"
        }
        default {
            Write-Host "不支持的文件类型：.$ext（仅支持 .sh / .py / .ps1）"
            exit 1
        }
    }
}

function Resolve-NewPath {
    param ([string]$FilePath)
    # 如果是相对路径，拼接当前工作目录
    if (-not [System.IO.Path]::IsPathRooted($FilePath)) {
        return [System.IO.Path]::Combine((Get-Location).Path, $FilePath)
    }
    return $FilePath
}

function Update-FileTime {
    param ([string]$FilePath)

    if (-not (Test-Path $FilePath)) {
        Write-Host "文件不存在：$FilePath"
        exit 1
    }

    $content = Get-Content $FilePath -Raw -Encoding UTF8

    if ($content -notmatch '@Update time') {
        Write-Host "文件中未找到 '@Update time' 字段：$FilePath"
        exit 1
    }

    $timestamp = Get-Now

    # 同时兼容 "# @Update time :" 与 "# @Update time :" 两种格式（sh/py/ps1）
    $newContent = $content -replace '(#?\s*@Update time\s*:)[^\r\n]*', "`$1 $timestamp"

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText(
        (Resolve-NewPath $FilePath),
        $newContent,
        $utf8NoBom
    )

    Write-Host "已更新 @Update time → $timestamp（文件：$FilePath）"
}

# ── 入口逻辑 ─────────────────────────────────────────────────────────────────

# 无参数 / 显示帮助
if ($h -or ($PSBoundParameters.Count -eq 0)) {
    Show-Usage
}

if ($c) {
    New-ScriptFile -FilePath $c -Desc $d
}
elseif ($u) {
    Update-FileTime -FilePath $u
}
else {
    Write-Host "请指定操作：-c（创建）或 -u（更新）"
    Show-Usage
}


Write-Host "Windows 下需要注意文件保持格式和CRLF和LF的问题"
