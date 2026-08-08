@echo off
rem ============================================================================
rem  @Author      ：幸运锦鲤
rem  @Time        : 2026-08-08 15:04:00
rem  @version     : cmd
rem  @Update time :
rem  @Description : Auto Scripts Tools 一键脚本主程序 (Windows CMD 版)
rem ============================================================================

setlocal enabledelayedexpansion
chcp 65001 >nul
title Auto Scripts Tools v2.0.0 (Windows CMD)

rem ────────────────────────────────────────────────────────────
rem  全局配置区
rem ────────────────────────────────────────────────────────────
set "ROOT_PATH=%~dp0"
set "ROOT_PATH=%ROOT_PATH:~0,-1%"
rem 若去掉反斜杠后变成了裸盘符 (如 C:)，则补回反斜杠，避免盘符相对路径
if "%ROOT_PATH%"=="%ROOT_PATH:\=@" set "ROOT_PATH=%ROOT_PATH%\"
set "VERSION=v2.0.0"

rem 颜色定义 (ANSI 转义序列)
set "C_RED=[0;31m"
set "C_GREEN=[0;32m"
set "C_YELLOW=[1;33m"
set "C_BLUE=[0;34m"
set "C_PURPLE=[0;35m"
set "C_CYAN=[0;36m"
set "C_WHITE=[1;37m"
set "C_GRAY=[0;90m"
set "C_NC=[0m"

rem 环境检测
net session >nul 2>&1
if %errorlevel% equ 0 (
    set "ENV_TEXT=[管理员]"
    set "ENV_COLOR=%C_GREEN%"
) else (
    set "ENV_TEXT=[普通用户]"
    set "ENV_COLOR=%C_CYAN%"
)

rem 主入口
goto :main_menu

rem ────────────────────────────────────────────────────────────
rem  工具函数
rem ────────────────────────────────────────────────────────────

rem 等待按键
:wait_key
echo.
echo %C_YELLOW%>>> 按任意键返回菜单...%C_NC%
pause >nul
echo.
exit /b 0

rem 读取用户输入
:read_choice
set "choice="
set /p "choice=%~1"
exit /b 0

rem ────────────────────────────────────────────────────────────
rem  脚本执行 (类型: ps1 / admin / py)
rem  参数: %1=目录  %2=脚本名  %3=类型
rem ────────────────────────────────────────────────────────────
:invoke_script
set "SCRIPT_DIR=%~1"
set "SCRIPT_NAME=%~2"
set "SCRIPT_TYPE=%~3"

cls
echo %C_CYAN%╔═════════════════════════════════════════════════════════════════════════╗%C_NC%
echo %C_CYAN%║%C_NC% => 正在启动: %SCRIPT_NAME%                                              %C_CYAN%║%C_NC%
echo %C_CYAN%╚═════════════════════════════════════════════════════════════════════════╝%C_NC%
echo.

set "FULL_PATH=%ROOT_PATH%\%SCRIPT_DIR%\%SCRIPT_NAME%"
if not exist "%FULL_PATH%" (
    echo %C_RED%[X] 错误: 脚本不存在 -- %FULL_PATH%%C_NC%
    echo.
    echo %C_YELLOW%请检查仓库文件是否完整。%C_NC%
    call :wait_key
    exit /b 0
)

pushd "%ROOT_PATH%\%SCRIPT_DIR%"
set "EXIT_CODE=0"

if "%SCRIPT_TYPE%"=="admin" (
    rem 检查管理员权限
    net session >nul 2>&1
    if !errorlevel! equ 0 (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%FULL_PATH%"
        set "EXIT_CODE=!errorlevel!"
    ) else (
        echo %C_YELLOW%[!] 此功能需要管理员权限，正在请求 UAC 提权...%C_NC%
        powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','!FULL_PATH!' -Wait"
        if !errorlevel! neq 0 (
            echo.
            echo %C_RED%[X] 管理员授权已取消或提权失败%C_NC%
            set "EXIT_CODE=1"
        )
    )
) else if "%SCRIPT_TYPE%"=="py" (
    where python >nul 2>&1
    if !errorlevel! equ 0 (
        python "%FULL_PATH%"
        set "EXIT_CODE=!errorlevel!"
    ) else (
        echo %C_RED%[X] 未检测到 python，请先安装 Python%C_NC%
        set "EXIT_CODE=1"
    )
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%FULL_PATH%"
    set "EXIT_CODE=!errorlevel!"
)

popd

echo.
if "%EXIT_CODE%"=="0" (
    echo %C_GREEN%[OK] 脚本执行结束 (退出码: %EXIT_CODE%)%C_NC%
) else (
    echo %C_RED%[X] 脚本执行异常 (退出码: %EXIT_CODE%)%C_NC%
)
call :wait_key
exit /b 0

rem ────────────────────────────────────────────────────────────
rem  快速系统信息 (内置功能)
rem ────────────────────────────────────────────────────────────
:quick_sysinfo
cls
echo %C_CYAN%╔═════════════════════════════════════════════════════════════════════════╗%C_NC%
echo %C_CYAN%║%C_NC%                              系统基本信息                               %C_CYAN%║%C_NC%
echo %C_CYAN%╚═════════════════════════════════════════════════════════════════════════╝%C_NC%
echo.
powershell -NoProfile -Command ^
  "$os=Get-CimInstance Win32_OperatingSystem; $cs=Get-CimInstance Win32_ComputerSystem; $cpu=Get-CimInstance Win32_Processor; " ^
  "Write-Host ('操作系统     ：' + $os.Caption); " ^
  "Write-Host ('计算机名     ：' + $cs.Name); " ^
  "Write-Host ('当前用户     ：' + $env:USERDOMAIN + '\' + $env:USERNAME); " ^
  "Write-Host ('处理器       ：' + $cpu.Name); " ^
  "Write-Host ('逻辑核心数   ：' + $cpu.NumberOfLogicalProcessors); " ^
  "Write-Host ('物理内存     ：' + [math]::Round($cs.TotalPhysicalMemory/1GB,2) + ' GB'); " ^
  "Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object { Write-Host ('磁盘 ' + $_.DeviceID + '     ：总容量 ' + [math]::Round($_.Size/1GB,2) + ' GB / 可用 ' + [math]::Round($_.FreeSpace/1GB,2) + ' GB') }; " ^
  "Write-Host ('启动时间     ：' + $os.LastBootUpTime); " ^
  "$up=(Get-Date)-$os.LastBootUpTime; " ^
  "Write-Host ('运行时长     ：' + $up.Days + ' 天 ' + $up.Hours + ' 小时 ' + $up.Minutes + ' 分钟'); " ^
  "Write-Host ('PowerShell   ：' + $PSVersionTable.PSVersion.ToString())"
call :wait_key
exit /b 0

rem ────────────────────────────────────────────────────────────
rem  mkfile_manager 交互式封装
rem ────────────────────────────────────────────────────────────
:mkfile_manager
set "MK_PATH=%ROOT_PATH%\Windows_platform\Mkfile_Manager.ps1"
if not exist "%MK_PATH%" (
    echo %C_RED%[X] 错误: 脚本不存在 -- %MK_PATH%%C_NC%
    call :wait_key
    exit /b 0
)

cls
echo %C_CYAN%╔═════════════════════════════════════════════════════════════════════════╗%C_NC%
echo %C_CYAN%║%C_NC%                 mkfile_manager -- 创建/管理脚本文件模板                 %C_CYAN%║%C_NC%
echo %C_CYAN%╚═════════════════════════════════════════════════════════════════════════╝%C_NC%
echo.
echo   1) 创建新脚本文件 (-c)      支持 .sh / .py / .ps1
echo   2) 更新文件的 @Update time (-u)
echo   0) 返回
echo.
call :read_choice "请选择操作: "
set "MK_OP=!choice!"

if "!MK_OP!"=="1" (
    set /p "FNAME=请输入要创建的文件名 (如 hello.ps1): "
    set /p "FDESC=请输入脚本描述 (可留空): "
    if not "!FNAME!"=="" (
        pushd "%ROOT_PATH%"
        powershell -NoProfile -ExecutionPolicy Bypass -File "%MK_PATH%" -c "!FNAME!" -d "!FDESC!"
        popd
    ) else (
        echo %C_RED%[X] 文件名不能为空，已取消%C_NC%
    )
    call :wait_key
) else if "!MK_OP!"=="2" (
    set /p "FPATH=请输入目标文件路径: "
    if not "!FPATH!"=="" (
        pushd "%ROOT_PATH%"
        powershell -NoProfile -ExecutionPolicy Bypass -File "%MK_PATH%" -u "!FPATH!"
        popd
    ) else (
        echo %C_RED%[X] 文件路径不能为空，已取消%C_NC%
    )
    call :wait_key
)
exit /b 0

rem ────────────────────────────────────────────────────────────
rem  子菜单
rem ────────────────────────────────────────────────────────────

rem ---- 1. 系统信息查询 ----
:sysinfo_menu
cls
echo %C_CYAN%╔═════════════════════════════════════════════════════════════════════════╗%C_NC%
echo %C_CYAN%║%C_NC%                           Auto Scripts Tools                            %C_CYAN%║%C_NC%
echo %C_CYAN%║%C_NC% [1] 系统信息查询                                                        %C_CYAN%║%C_NC%
echo %C_CYAN%╠═════════════════════════════════════════════════════════════════════════╣%C_NC%
echo %C_CYAN%║%C_NC% 编号 ^| 功能说明                                                         %C_CYAN%║%C_NC%
echo %C_CYAN%╠═════════════════════════════════════════════════════════════════════════╣%C_NC%
echo %C_CYAN%║%C_NC% 1   ^| 查看系统综合信息 (System_Info)                                    %C_CYAN%║%C_NC%
echo %C_CYAN%║%C_NC% 2   ^| 快速获取系统基本信息 (内置)                                       %C_CYAN%║%C_NC%
echo %C_CYAN%╠═════════════════════════════════════════════════════════════════════════╣%C_NC%
echo %C_CYAN%║%C_NC% 0 / b = 返回上级     q = 退出程序                                       %C_CYAN%║%C_NC%
echo %C_CYAN%╚═════════════════════════════════════════════════════════════════════════╝%C_NC%
echo.
call :read_choice "请输入序号: "
if "!choice!"=="1" (
    call :invoke_script "Windows_platform" "System_Info.ps1" "ps1"
) else if "!choice!"=="2" (
    call :quick_sysinfo
) else if "!choice!"=="q" (
    call :exit_safe
    exit /b 0
) else if "!choice!"=="b" (
    goto :main_menu
) else if "!choice!"=="0" (
    goto :main_menu
)
goto :sysinfo_menu

rem ---- 2. 开发环境管理 ----
:devenv_menu
cls
echo %C_CYAN%╔═════════════════════════════════════════════════════════════════════════╗%C_NC%
echo %C_CYAN%║%C_NC%                           Auto Scripts Tools                            %C_CYAN%║%C_NC%
echo %C_CYAN%║%C_NC% [2] 开发环境管理                                                        %C_CYAN%║%C_NC%
echo %C_CYAN%╠═════════════════════════════════════════════════════════════════════════╣%C_NC%
echo %C_CYAN%║%C_NC% 编号 ^| 功能说明                                                         %C_CYAN%║%C_NC%
echo %C_CYAN%╠═════════════════════════════════════════════════════════════════════════╣%C_NC%
echo %C_CYAN%║%C_NC% 1   ^| 安装 MinGW-w64 (C/C++ 编译环境) [需管理员]                        %C_CYAN%║%C_NC%
echo %C_CYAN%╠═════════════════════════════════════════════════════════════════════════╣%C_NC%
echo %C_CYAN%║%C_NC% 0 / b = 返回上级     q = 退出程序                                       %C_CYAN%║%C_NC%
echo %C_CYAN%╚═════════════════════════════════════════════════════════════════════════╝%C_NC%
echo.
call :read_choice "请输入序号: "
if "!choice!"=="1" (
    call :invoke_script "Windows_platform" "MinGW-w64-Builds.ps1" "admin"
) else if "!choice!"=="q" (
    call :exit_safe
    exit /b 0
) else if "!choice!"=="b" (
    goto :main_menu
) else if "!choice!"=="0" (
    goto :main_menu
)
goto :devenv_menu

rem ---- 3. 实用工具箱 ----
:tools_menu
cls
echo %C_CYAN%╔═════════════════════════════════════════════════════════════════════════╗%C_NC%
echo %C_CYAN%║%C_NC%                           Auto Scripts Tools                            %C_CYAN%║%C_NC%
echo %C_CYAN%║%C_NC% [3] 实用工具箱                                                          %C_CYAN%║%C_NC%
echo %C_CYAN%╠═════════════════════════════════════════════════════════════════════════╣%C_NC%
echo %C_CYAN%║%C_NC% 编号 ^| 功能说明                                                         %C_CYAN%║%C_NC%
echo %C_CYAN%╠═════════════════════════════════════════════════════════════════════════╣%C_NC%
echo %C_CYAN%║%C_NC% 1   ^| PowerShell 运行环境测试 (Powershell_Test)                         %C_CYAN%║%C_NC%
echo %C_CYAN%║%C_NC% 2   ^| mkfile_manager -- 创建/管理脚本文件模板                           %C_CYAN%║%C_NC%
echo %C_CYAN%╠═════════════════════════════════════════════════════════════════════════╣%C_NC%
echo %C_CYAN%║%C_NC% 0 / b = 返回上级     q = 退出程序                                       %C_CYAN%║%C_NC%
echo %C_CYAN%╚═════════════════════════════════════════════════════════════════════════╝%C_NC%
echo.
call :read_choice "请输入序号: "
if "!choice!"=="1" (
    call :invoke_script "Windows_platform" "Powershell_Test.ps1" "ps1"
) else if "!choice!"=="2" (
    call :mkfile_manager
) else if "!choice!"=="q" (
    call :exit_safe
    exit /b 0
) else if "!choice!"=="b" (
    goto :main_menu
) else if "!choice!"=="0" (
    goto :main_menu
)
goto :tools_menu

rem ────────────────────────────────────────────────────────────
rem  退出
rem ────────────────────────────────────────────────────────────
:exit_safe
cls
echo %C_CYAN%╔═════════════════════════════════════════════════════════════════════════╗%C_NC%
echo %C_CYAN%║%C_NC%                                                                         %C_CYAN%║%C_NC%
echo %C_CYAN%║%C_NC%                   感谢使用 Auto Scripts Tools，再见！                   %C_CYAN%║%C_NC%
echo %C_CYAN%║%C_NC%                                                                         %C_CYAN%║%C_NC%
echo %C_CYAN%╚═════════════════════════════════════════════════════════════════════════╝%C_NC%
echo.
exit 0

rem ────────────────────────────────────────────────────────────
rem  主菜单
rem ────────────────────────────────────────────────────────────
:main_menu
cls
echo %C_CYAN%╔═════════════════════════════════════════════════════════════════════════╗%C_NC%
echo %C_CYAN%║%C_NC%                                                                         %C_CYAN%║%C_NC%
echo %C_CYAN%║%C_NC%                Auto Scripts Tools 一键脚本主界面 v2.0.0                 %C_CYAN%║%C_NC%
echo %C_CYAN%║%C_NC%                                                                         %C_CYAN%║%C_NC%
echo %C_CYAN%╠═════════════════════════════════════════════════════════════════════════╣%C_NC%
echo %C_CYAN%║%C_NC% 检测到当前环境：!ENV_COLOR!!ENV_TEXT!%C_NC%  Windows                                     %C_CYAN%║%C_NC%
echo %C_CYAN%╠═════════════════════════════════════════════════════════════════════════╣%C_NC%
echo %C_CYAN%║%C_NC% 编号 ^| 功能分类                                                         %C_CYAN%║%C_NC%
echo %C_CYAN%╠═════════════════════════════════════════════════════════════════════════╣%C_NC%
echo %C_CYAN%║%C_NC% 1   ^| 系统信息查询                                                      %C_CYAN%║%C_NC%
echo %C_CYAN%║%C_NC%         └── 查看系统综合信息 (硬件/软件/网络)                           %C_CYAN%║%C_NC%
echo %C_CYAN%║%C_NC% 2   ^| 开发环境管理                                                      %C_CYAN%║%C_NC%
echo %C_CYAN%║%C_NC%         └── C/C++ 编译环境 (MinGW-w64) 安装                             %C_CYAN%║%C_NC%
echo %C_CYAN%║%C_NC% 3   ^| 实用工具箱                                                        %C_CYAN%║%C_NC%
echo %C_CYAN%║%C_NC%         └── PowerShell 环境测试、脚本文件模板管理                       %C_CYAN%║%C_NC%
echo %C_CYAN%╠═════════════════════════════════════════════════════════════════════════╣%C_NC%
echo %C_CYAN%║%C_NC% q   ^| 退出程序                                                          %C_CYAN%║%C_NC%
echo %C_CYAN%╚═════════════════════════════════════════════════════════════════════════╝%C_NC%
echo.
call :read_choice "请输入序号进入: "
if "!choice!"=="1" (
    call :sysinfo_menu
) else if "!choice!"=="2" (
    call :devenv_menu
) else if "!choice!"=="3" (
    call :tools_menu
) else if "!choice!"=="q" (
    call :exit_safe
    exit /b 0
)
goto :main_menu
