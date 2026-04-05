# Claude Code 安装说明



## 前期准备

+ Windows 或 Linux 电脑一台



## 安装 Claude Code

1、Linux 可使用当前文件夹内的一键安装脚本

```shell
./claude_code_install.sh
```

2、Windows 使用以下命令安装（使用PowerShell）：

```powershell
irm https://claude.ai/install.ps1 | iex
```

3、npm 安装，首先需要安装好 nodejs ，再使用以下命令进行安装：

```shell
npm install -g @anthropic-ai/claude-code
```

查看版本信息：

```shell
claude --version
```



## 配置

这里默认选择第一项即可

```markdown
 Choose the text style that looks best with your terminal
 To change this later, run /theme

 ❯ 1. Dark mode ✔
   2. Light mode
   3. Dark mode (colorblind-friendly)
   4. Light mode (colorblind-friendly)
   5. Dark mode (ANSI colors only)
   6. Light mode (ANSI colors only)
```

选择接入方式

```markdown
 Claude Code can be used with your Claude subscription or billed based on API usage through your Console account.
                                                         
 Select login method:            

   1. Claude account with subscription · Pro, Max, Team, or Enterprise
                
 ❯ 2. Anthropic Console account · API usage billing
                                      
   3. 3rd-party platform · Amazon Bedrock, Microsoft Foundry, or Vertex AI
```

安全说明

```markdown
 Security notes:

 1. Claude can make mistakes
    You should always review Claude's responses, especially when
    running code.

 2. Due to prompt injection risks, only use it with code you trust
    For more details see:
    https://code.claude.com/docs/en/security

 Press Enter to continue…
```

是否同意授权当前文件夹

```markdown
 C:\Users\luckykoi

 Quick safety check: Is this a project you created or one you trust? (Like your own code, a well-known open source
 project, or work from your team). If not, take a moment to review what's in this folder first.

 Claude Code'll be able to read, edit, and execute files here.

 Security guide

 ❯ 1. Yes, I trust this folder
   2. No, exit

 Enter to confirm · Esc to cancel
```



## settings.json 配置

**使用cc-switch软件方式：**

[cc-switch](https://github.com/farion1231/cc-switch) 是一个便捷的工具，可以快速切换 Claude Code 的 API 配置。

安装  **cc-switch** ：前往 [cc-switch GitHub Releases](https://github.com/farion1231/cc-switch/releases) 页面下载最新版本的安装包。



**手动编辑配置文件方式：**

MiniMAX接入示例：

参考官网链接：https://platform.minimaxi.com/docs/token-plan/claude-code



七牛云 AI 大模型示例：

```json
{
  "autoUpdatesChannel": "latest",
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "sk-2907f87e81d74c9b2b03651f7xxxx",
    "ANTHROPIC_BASE_URL": "https://api.qnaigc.com",
    
    "ANTHROPIC_MODEL": "minimax/minimax-m2.5",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "minimax/minimax-m2.5",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "minimax/minimax-m2.5",
    "ANTHROPIC_SMALL_FAST_MODEL": "minimax/minimax-m2.5"
  },
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)"
    ]
  },
  "companyAnnouncements": [
    "您正在使用七牛云 AI 大模型推理服务 🚀"
  ]
}
```

**说明：**

  基本设置：
  - autoUpdatesChannel: "latest" - 自动更新到最新版本

  环境变量 (env)：
  - 使用七牛云 AI 大模型推理服务 (https://api.qnaigc.com)
  - 认证 token: sk-2907f87e... (已隐藏部分)
  - 模型: minimax/minimax-m2.5

  权限限制 (deny)：
  - 禁止读取 .env 文件
  - 禁止读取 .env.* 文件
  - 禁止读取 secrets/** 目录

  公告：
  - 显示 "您正在使用七牛云 AI 大模型推理服务 🚀"





## Tokens 问题

免费 Token 获取（免费的是最贵的）：https://mp.weixin.qq.com/s/ndviq6SCMab2zlJAvcO7tg

