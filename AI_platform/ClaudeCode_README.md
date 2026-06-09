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

更新命令：

```shell
npm update -g @anthropic-ai/claude-code
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





## Claude Code 玩法说明

### Claude Code 教程

链接： https://www.runoob.com/claude-code/claude-code-tutorial.html

### 斜杠命令

/help
查看所有可用命令。忘了就敲这个，官方文档直接给你列出来。

/clear
清空对话历史。有时候聊跑偏了，或者上下文太乱，清一下重新开始，省得 Token 浪费，思路也清晰。

/exit 或 /quit
退出 Claude Code。快捷键 Ctrl+D 也能搞定，看你习惯。

/cost

显示当前会话的 Token 消耗和费用。

/model
切换 AI 模型。输入后会弹出选项让你选，想快速测试不同模型能力的时候特别方便。

/context
查看当前上下文占用情况。Token 快超了的时候赶紧看一眼，该清就清。

/review
请求代码审查。让 Claude 帮你 review 当前改动，比很多人肉查得都仔细。

/compact
压缩对话历史，总结之前的内容，腾出更多上下文空间。聊了很多轮之后，用这个能续命。

/init
交互式初始化项目，会生成 CLAUDE.md 文件。这个文件相当于给 Claude 的「项目说明书」，里面可以写：

项目整体介绍
代码风格规范
构建和测试命令
开发流程约定
以后 Claude 再改代码，就会严格按照你定的规则来，不会天马行空地乱写。这才是真的「Claude 本地化」。





### ClaudeCode三种模式详解

在 Claude Code 里有3种实用模式，操作超简单，按 shift + tab 就能一键切换，分别是普通模式、plan模式、自动接受代码编辑模式。



#### 普通模式：默认基础模式，随心聊随心操作

普通模式是打开Claude Code进入主界面的默认模式，也是最基础的模式，没什么复杂的规则，就跟咱们日常用聊天工具和AI沟通一样。

显示的是【? for shortcuts】就表示你现在是「普通模式」。



#### 自动接受代码编辑模式：自动执行模式，敲定方案后高效干活

自动接受代码编辑模式，其实就是说，默认允许Claude Code直接修改代码，不要每次修改什么代码的时候都要反问我们这样改动ok吗？我们允许吗？



#### plan模式：专属规划模式，只聊方案不写代码，项目前期超实用

Plan模式有点拗口，其实你可以理解为【讨论模式】，就是和你讨论，而且是有计划的讨论，讨论的最后呢会生成一份完整的执行计划。稍后Claude Code就会按照这份计划去推进。

所以说，plan模式是专门的**规划沟通模式**，核心特点就是：只跟你讨论、沟通需求，不会主动执行写代码、改代码这些操作，特别适合**项目前期的功能规划、方案设计阶段**。





## Tokens 问题

免费 Token 获取（免费的是最贵的）：https://mp.weixin.qq.com/s/ndviq6SCMab2zlJAvcO7tg

