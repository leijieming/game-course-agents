# 游戏设计课程 AI Agent 辅助项目

这个仓库提供一套面向 Windows 课堂的部署工具，让学生可以快速准备：

- Claude Code
- CC Switch
- Claude-Code-Game-Studios 课程工作区
- Unreal Engine 5、Unity、Godot 4、Blender 的 MCP 连接入口

V1 的目标是把 AI 工具链和软件连接层装好，而不是替学生安装 UE、Unity、Godot 或 Blender 这些大型软件本体。安装器会检测它们是否存在；没安装时记录为 `SKIP/WARN`，不会让整套流程失败。

## 快速开始

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
- UnrealMCP: https://pypi.org/project/unrealmcp/
- Unity MCP Server: https://github.com/AnkleBreaker-Studio/unity-mcp-server
- Godot MCP: https://github.com/tugcantopaloglu/godot-mcp
- Blender MCP: https://github.com/ahujasid/blender-mcp

## 开发检查

```bash
npm test
```

CI 会检查 manifest 结构、入口文件、MCP 示例和文档骨架。
