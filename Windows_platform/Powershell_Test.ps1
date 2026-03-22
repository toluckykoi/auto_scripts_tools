<#
.SYNOPSIS
    PowerShell 运行环境测试脚本
.DESCRIPTION
    仅用于测试脚本能否正常运行，展示不同级别的日志颜色输出。
    包含：Info, Success, Warning, Error 四种状态。
.AUTHOR
    幸运锦鲤 (luckykoi)
.CREATED
    2025-03-04 17:40:06
.VERSION
    PowerShell 5.1+ / PowerShell Core 7+
#>

# --- 1. 定义颜色变量 ---
$C_Info    = "Cyan"       # 青色：普通信息
$C_Success = "Green"      # 绿色：成功/OK
$C_Warn    = "Yellow"     # 黄色：警告
$C_Error   = "Red"        # 红色：错误
$C_Text    = "White"      # 白色：正文内容

Write-Host "`n========================================" -ForegroundColor $C_Info
Write-Host "  🧪 PowerShell 脚本运行测试 (Test Run)" -ForegroundColor $C_Info
Write-Host "========================================`n" -ForegroundColor $C_Info

# --- 2. 模拟各种日志输出 ---

# [INFO] 普通信息
Write-Host "[INFO] " -NoNewline -ForegroundColor $C_Info
Write-Host "脚本已开始执行，当前时间：$(Get-Date -Format 'HH:mm:ss')" -ForegroundColor $C_Text

# [INFO] 模拟加载过程
Write-Host "[INFO] " -NoNewline -ForegroundColor $C_Info
Write-Host "正在加载 Test 环境配置..." -ForegroundColor $C_Text
Start-Sleep -Milliseconds 1000       # 暂停 1 秒模拟耗时

# [OK] 成功状态
Write-Host "[OK]   " -NoNewline -ForegroundColor $C_Success
Write-Host "环境配置加载成功！" -ForegroundColor $C_Text

# [WARN] 警告状态
Write-Host "[WARN] " -NoNewline -ForegroundColor $C_Warn
Write-Host "检测到未连接的可选设备 (LiDAR)，将跳过相关初始化。" -ForegroundColor $C_Text

# [ERROR] 错误状态 (模拟)
Write-Host "[ERROR]" -NoNewline -ForegroundColor $C_Error
Write-Host "配置文件 config.yaml 未找到，使用默认参数。" -ForegroundColor $C_Text

# --- 3. 结束总结 ---
Write-Host "`n----------------------------------------" -ForegroundColor $C_Info
Write-Host "  ✅ 测试完成：脚本运行正常，颜色显示正确。" -ForegroundColor $C_Success
Write-Host "----------------------------------------`n" -ForegroundColor $C_Info

# ---------------------------------------------------------
# 固定窗口运行：
# Read-Host 会阻塞程序，直到用户按下回车。
# ---------------------------------------------------------
Write-Host ""
Write-Host "👉 请按 [回车键] 结束/关闭此窗口..."
Read-Host 
