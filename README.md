# 游戏设计课程 AI Agent 辅助项目

这个仓库提供一套面向 Windows 课堂的部署工具，让学生可以快速准备：

- Claude Code
- CC Switch
- Claude-Code-Game-Studios 课程工作区
- Unreal Engine 5、Unity、Godot 4、Blender 的 MCP 连接入口

V1 的目标是把 AI 工具链和软件连接层装好，而不是替学生安装 UE、Unity、Godot 或 Blender 这些大型软件本体。安装器会检测它们是否存在；没安装时记录为 `SKIP/WARN`，不会让整套流程失败。

## 快速开始

学生电脑建议先准备：

- Git
- Node.js LTS（需要 `node` 和 `npm`）
- Python 3.12 或 Python Launcher（`py`）
- 可选：`uv`/`uvx`、WSL2
- 已安装的课程软件，例如 Unreal Engine 5.7、Unity、Godot 4 或 Blender

在 Windows PowerShell 里运行：

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\install.ps1 -WorkspacePath "$HOME\GameCourseAI" -IncludeWsl -ConfigureApi
```

首次课堂建议先 dry-run：

```powershell
.\install.ps1 -DryRun -IncludeWsl
```

安装完成后查看：

```powershell
Get-Content "$HOME\GameCourseAI\health-report.json"
```

## Unreal Engine 5.7 与 MCP

`unreal` 模块会：

- 从 Epic Launcher 安装清单和常见安装目录检测 UE5，支持安装在非 C 盘的 `UE_5.x`。
- 使用 `ChiR24/Unreal_mcp` 的 `McpAutomationBridge` 插件作为 UE 侧服务。
- 把 Claude Code 的项目级 `.mcp.json` 配置为 HTTP MCP server。
- 默认连接 `http://localhost:3000/mcp`。

只配置 UE MCP 相关内容可以运行：

```powershell
.\install.ps1 -WorkspacePath "$HOME\GameCourseAI" -Modules toolchain,game-studios,unreal
```

安装完成后，`$HOME\GameCourseAI\.mcp.json` 会包含 `unreal-engine` MCP server。要把 UE 插件安装到某个项目，可以先打开 `.uproject`，然后运行：

```powershell
.\scripts\install-unreal-mcp-bridge.ps1 -WorkspacePath "$HOME\GameCourseAI"
```

脚本会优先检测当前正在运行的 Unreal Editor 项目，构建并安装 `McpAutomationBridge`，写入项目 `Config/DefaultGame.ini`，并生成项目级 `.claude/settings.json` 和 `.mcp.json`。完成后必须重启 UE 编辑器，看到右下角 `MCP :3000` 后，在 UE 项目目录运行 `claude`。

## 仓库结构

```text
install.ps1                 主安装入口
manifests/                  每个模块的检测、安装、配置、验证声明
examples/mcp/               Claude Code 项目级 MCP 示例
docs/getting-started.md     课堂安装说明
docs/course-smoke-tests.md  课堂验收步骤
docs/troubleshooting.md     常见问题排查
tests/                      Node.js 静态契约测试
```

## 设计原则

- 不收集学生密钥，不把密钥写进仓库或日志。
- 默认新建课程工作区，也支持合并到已有项目；合并前会备份冲突路径。
- 原生 Windows 负责桌面软件插件和路径检测，WSL2 负责 Linux 命令行工具链。
- 每个软件模块独立，可单独跳过、重跑和排查。

## 常用命令

只配置 Claude Code、CC Switch 和 Game Studios：

```powershell
.\install.ps1 -Modules toolchain,claude-code,cc-switch,game-studios
```

只配置 Claude Code、Game Studios 和 Unreal MCP 客户端入口：

```powershell
.\install.ps1 -Modules toolchain,claude-code,game-studios,unreal
```

使用离线缓存：

```powershell
.\install.ps1 -OfflineCache "D:\game-course-cache"
```

合并到已有项目：

```powershell
.\install.ps1 -WorkspacePath "D:\MyUnityGame" -GameStudiosMode merge
```

## 上游项目

- Claude Code: https://docs.anthropic.com/en/docs/claude-code/setup
- CC Switch: https://github.com/farion1231/cc-switch ，Windows 版优先使用 Releases 中的 MSI/Portable 包。
- Claude-Code-Game-Studios: https://github.com/leijieming/Claude-Code-Game-Studios
- Unreal MCP Automation Bridge: https://github.com/ChiR24/Unreal_mcp
- Unity MCP Server: https://github.com/AnkleBreaker-Studio/unity-mcp-server
- Godot MCP: https://github.com/tugcantopaloglu/godot-mcp
- Blender MCP: https://github.com/ahujasid/blender-mcp

## 开发检查

```bash
npm test
```

CI 会检查 manifest 结构、入口文件、MCP 示例、文档骨架、PowerShell 语法和安装器 dry-run。
