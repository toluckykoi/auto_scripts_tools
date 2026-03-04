# 关于 Windows 一键脚本说明





## 支持系统

+ Windows 11





## 解决“禁止运行脚本”问题

如果您直接运行，可能会看到红色报错：
> *无法加载文件 xxx.ps1，因为在此系统上禁止运行脚本。*

这是因为 Windows 的默认执行策略是 `Restricted`。您需要将其更改为 `RemoteSigned`（允许运行本地脚本，但下载的脚本需要签名）。

**操作方法：**

1. 在文件夹空白处右键，选择 **“在终端中打开”** (Open in Terminal) 或 **“在 PowerShell 中打开”**。
2. 输入以下命令并回车：
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
3. 系统会提示确认，输入 `Y` 或 `A` 并回车。
   * *解释*：`-Scope CurrentUser` 表示只修改当前用户的设置，不需要管理员权限，更安全且不影响其他用户。





## 解决编码问题

#### 方法一：用 VS Code 重新保存为带 BOM 的 UTF-8（最推荐，最稳定）
如果您使用 **VS Code** 编辑脚本：
1. 打开 `xxxxxxxxxxxx.ps1` 文件。
2. 点击右下角的编码显示区域（通常显示为 `UTF-8`）。
3. 在弹出的菜单中选择 **“通过编码保存 (Save with Encoding)”**。
4. 选择 **`UTF-8 with BOM`** (注意：一定要选 **with BOM**)。
   * *解释*：BOM (Byte Order Mark) 会告诉 PowerShell 这是一个 UTF-8 文件，从而避免乱码。
5. 保存后，再次运行脚本即可。

#### 方法二：用记事本 (Notepad) 重新保存
如果您没有 VS Code：
1. 右键点击 `xxxxxxxxxxxx.ps1`，选择“打开方式” -> “记事本”。
2. 点击左上角“文件” -> “另存为”。
3. 在底部的“编码”下拉菜单中，选择 **`UTF-8 with BOM`** (在某些 Win10/11 版本中可能直接显示为 `UTF-8`，但新版记事本默认带 BOM；如果是旧版，请选 `ANSI` 试试，但推荐 `UTF-8 with BOM`)。
   * *注意*：如果选项里有 `UTF-8` 和 `UTF-8 带签名`，请选择 **`UTF-8 带签名`** (即带 BOM)。
4. 覆盖原文件保存。
5. 重新运行脚本。

#### 方法三：临时在终端强制指定编码（无需修改文件）

如果您不想修改文件，可以在运行脚本前，先在当前的 PowerShell 窗口中执行以下命令，强制终端使用 UTF-8 读取：

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
# 然后再次运行脚本
.\xxxxxxxxxxxx.ps1
```

*注意：这种方法只对当前终端窗口有效，关闭窗口后失效。*



