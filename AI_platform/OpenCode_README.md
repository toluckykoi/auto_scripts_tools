# Open Code 安装说明



## 前期准备

+ Windows 或 Linux 电脑一台
+ 官方文档：https://opencode.ai/docs/zh-cn



## 安装 Open Code

安装 OpenCode 最简单的方法是通过安装脚本。

```shell
curl -fsSL https://opencode.ai/install | bash
```

**使用 Node.js**

```shell
npm install -g opencode-ai
```

更新命令：

```shell
npm update -g opencode-ai
```

**在 macOS 和 Linux 上使用 Homebrew**

```shell
brew install anomalyco/tap/opencode
```





**配置文件修改：**

在以下路径创建配置文件 opencode.json：

- `macOS / Linux：~/.config/opencode/opencode.json`
- `Windows：C:\Users\您的用户名\.config\opencode\opencode.json`

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "sense-nova": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Sense Nova",
      "options": {
        "baseURL": "https://token.sensenova.cn/v1",
        "apiKey": "YOUR_API_KEY"
      },
      "models": {
        "sensenova-6.7-flash-lite": {
          "name": "SenseNova 6.7 Flash-Lite",
          "modalities": {
            "input": ["text", "image"],
            "output": ["text"]
          },
          "limit": {
            "context": 256000,
            "output": 65536
          }
        }
      }
    }
  }
}
```



