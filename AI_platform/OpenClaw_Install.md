# 大龙虾安装说明



## 前期准备

+ Linux 电脑一台（这里以 Ubuntu22 为例）



## 安装龙虾

直接执行：`openclaw_install.sh`脚本进行安装

选择 ”Yes”

```shell
◆  I understand this is personal-by-default and shared/multi-user use requires lock-down. Continue?
│  ● Yes / ○ No
```

选择 “QuickStart”

```shell
◆  Onboarding mode
│  ● QuickStart (Configure details later via openclaw configure.)
│  ○ Manual
```

选择 “Skip for now”，后续可以配置

```shell
◆  Model/auth provider
│  ● OpenAI (Codex OAuth + API key)
│  ○ Anthropic
│  ○ Chutes
│  ○ vLLM
│  ○ MiniMax
│  ○ Moonshot AI (Kimi K2.5)
│  ○ Google
│  ○ xAI (Grok)
│  ○ Mistral AI
│  ○ Volcano Engine
│  ○ BytePlus
│  ○ OpenRouter
│  ○ Kilo Gateway
│  ○ Qwen
│  ...
└
```

选择 “All providers”

```shell
◆  Filter models by provider
│  ● All providers
│  ○ amazon-bedrock
│  ○ anthropic
│  ○ azure-openai-responses
│  ○ cerebras
│  ○ github-copilot
│  ○ google
│  ○ google-antigravity
│  ○ google-gemini-cli
│  ○ google-vertex
│  ○ groq
│  ○ huggingface
│  ○ kimi-coding
│  ○ minimax
│  ...
└
```

使用默认配置”Keep current“

```shell
◆  Default model
│  ● Keep current (default: anthropic/claude-opus-4-6)
│  ○ Enter model manually
│  ○ amazon-bedrock/anthropic.claude-3-haiku-20240307-v1:0
│  ○ amazon-bedrock/anthropic.claude-3-5-haiku-20241022-v1:0
│  ○ amazon-bedrock/anthropic.claude-haiku-4-5-20251001-v1:0
│  ○ amazon-bedrock/eu.anthropic.claude-haiku-4-5-20251001-v1:0
│  ○ amazon-bedrock/global.anthropic.claude-haiku-4-5-20251001-v1:0
│  ○ amazon-bedrock/us.anthropic.claude-haiku-4-5-20251001-v1:0
│  ○ amazon-bedrock/anthropic.claude-3-opus-20240229-v1:0
│  ○ amazon-bedrock/anthropic.claude-opus-4-20250514-v1:0
│  ○ amazon-bedrock/us.anthropic.claude-opus-4-20250514-v1:0
│  ○ amazon-bedrock/anthropic.claude-opus-4-1-20250805-v1:0
│  ○ amazon-bedrock/us.anthropic.claude-opus-4-1-20250805-v1:0
│  ○ amazon-bedrock/anthropic.claude-opus-4-5-20251101-v1:0
│  ...
└
```

选择 “Skip for now”，后续可以配置

```shell
◆  Select channel (QuickStart)
│  ...
│  ○ iMessage (imsg)
│  ○ Feishu/Lark (飞书)
│  ○ Nostr (NIP-04 DMs)
│  ○ Microsoft Teams (Bot Framework)
│  ○ Mattermost (plugin)
│  ○ Nextcloud Talk (self-hosted)
│  ○ Matrix (plugin)
│  ○ BlueBubbles (macOS app)
│  ○ LINE (Messaging API)
│  ○ Zalo (Bot API)
│  ○ Zalo (Personal Account)
│  ○ Synology Chat (Webhook)
│  ○ Tlon (Urbit)
│  ● Skip for now (You can add channels later via `openclaw channels add`)
```

skills的配置，可以熟悉后再配置，这里先选择 “No”，后续可以配置

```shell
◇  Select channel (QuickStart)
│  Skip for now
Updated ~/.openclaw/openclaw.json
Workspace OK: ~/.openclaw/workspace
Sessions OK: ~/.openclaw/agents/main/sessions
│
◇  Skills status ─────────────╮
│                             │
│  Eligible: 4                │
│  Missing requirements: 40   │
│  Unsupported on this OS: 7  │
│  Blocked by allowlist: 0    │
│                             │
├─────────────────────────────╯
│
◆  Configure skills now? (recommended)
│  ● Yes / ○ No
└
```

这里是钩子的设置（当你的agent命令有问题的时候，自动执行一些操作来进行恢复），这里全选

```shell
◆  Enable hooks?
│  ◻ Skip for now
│  ◼ 🚀 boot-md (Run BOOT.md on gateway startup)
│  ◼ 📎 bootstrap-extra-files (Inject additional workspace bootstrap files via glob/path patterns)
│  ◼ 📝 command-logger (Log all command events to a centralized audit file)
│  ◼ 💾 session-memory (Save session context to memory when /new or /reset command is issued)
└
```

这里是等待安装后端程序，等待即可

```shell
◒  Installing Gateway service…
Installed systemd service: /home/user/.config/systemd/user/openclaw-gateway.service
◇  Gateway service installed.
```

选择 “Hatch in TUI”

```shell
◆  How do you want to hatch your bot?
│  ● Hatch in TUI (recommended)
│  ○ Open the Web UI
│  ○ Do this later
└
```

这里选择了Hatch in TUI是命令行的方式跟openclaw进行交互

```shell
◇  How do you want to hatch your bot?
│  Hatch in TUI (recommended)
 openclaw tui - ws://127.0.0.1:18789 - agent main - session main                                                               

 session agent:main:main                                                                                        
 Wake up, my friend!                                                                                                                                                                                                 
 ⚠️ Agent failed before reply: No API key found for provider "anthropic". Auth store:                                          
 /home/user/.openclaw/agents/main/agent/auth-profiles.json (agentDir: /home/user/.openclaw/agents/main/agent). Configure auth  
 for this agent (openclaw agents add <id>) or copy auth-profiles.json from the main agentDir.                                  
 Logs: openclaw logs --follow                                                                                                  
 gateway connected | idle                                                                                                      
 agent main | session main (openclaw-tui) | anthropic/claude-opus-4-6 | think adaptive | tokens ?/200k                         
```

到这里就安装完成了，可以使用 `openclaw -v`来检查是否安装成功

```shell
user@Ubuntu22:AI_platform → main$ openclaw -v
2026.3.2
```





## 局域网访问设置

运行openclaw configure后提示，你的后端是在哪里运行，这本机的话选择第一个就行

```shell
◆  Where will the Gateway run?
│  ● Local (this machine) (Gateway reachable (ws://127.0.0.1:18789))
│  ○ Remote (info-only)
└
```

这里选择"Gateway"

```shell
◆  Select sections to configure
│  ● Workspace (Set workspace + sessions)
│  ○ Model
│  ○ Web tools
│  ○ Gateway
│  ○ Daemon
│  ○ Channels
│  ○ Skills
│  ○ Health check
│  ○ Continue
└
```

端口默认就行

```shell
◆  Gateway port
│  18789
└
```

这里选择“LAN”，注意：如果在服务器上不建议使用这个！

```shell
◆  Gateway bind mode
│  ○ Loopback (Local only)
│  ○ Tailnet (Tailscale IP)
│  ○ Auto (Loopback → LAN)
│  ● LAN (All interfaces) (Bind to 0.0.0.0 - accessible from anywhere on your network)
│  ○ Custom IP
└
```

这里选择加密方式，这里使用token就行

```shell
◆  Gateway auth
│  ● Token (Recommended default)
│  ○ Password
│  ○ Trusted Proxy
└
```

这里选择 ”Off“

```shell
◆  Tailscale exposure
│  ● Off (No Tailscale exposure)
│  ○ Serve
│  ○ Funnel
└
```

会出现新的 token 默认就行

```shell
◆  Gateway token (blank to generate)
│  b55ee031a6cc986fd16d414c5118af05585592da61de198b
└
```

这里选择“Continue“

```shell
◇  Gateway token (blank to generate)
│  b55ee031a6cc986fd16d414c5118af05585592da61de198b
Config overwrite: /home/user/.openclaw/openclaw.json (sha256 7bb61d9fee5a9e271d8c9276437ff56525239aea87487da7d72a9f77c1625e17 -> 1e2d77a6541076ed57180691cd2a3d5dabc26dcb3f79a062d33663cfe45cd2ca, backup=/home/user/.openclaw/openclaw.json.bak)
Updated ~/.openclaw/openclaw.json
│
◆  Select sections to configure
│  ● Workspace (Set workspace + sessions)
│  ○ Model
│  ○ Web tools
│  ○ Gateway
│  ○ Daemon
│  ○ Channels
│  ○ Skills
│  ○ Health check
│  ○ Continue
└
```

最后使用"openclaw gateway restart"来重启就可以了。



## openclaw 常用命令

openclaw config reload：重新加载配置

openclaw gateway restart：重启网关服务

openclaw dashboard：打开网页后台

openclaw configure

openclaw doctor --fix

openclaw logs --follow

openclaw models list
