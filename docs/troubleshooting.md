# 故障排查

## PowerShell 拒绝运行脚本

先在当前窗口临时放开执行策略：

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
```

不要要求学生永久改系统策略。

## `npm install -g @anthropic-ai/claude-code` 失败

检查：

```powershell
node --version
npm --version
npm config get registry
```

如果网络不稳定，改用离线缓存或课前统一准备 Node.js/npm 缓存。

## Claude Code 能启动，但没有 Game Studios 命令

确认当前目录是课程工作区：

```powershell
cd "$HOME\GameCourseAI"
Test-Path ".claude"
Test-Path "CLAUDE.md"
```

如果为 `False`，重新运行：

```powershell
.\install.ps1 -WorkspacePath "$HOME\GameCourseAI" -Modules game-studios
```

## CC Switch provider 无法使用

原则：

- API Key 只保存在学生本机。
- 不要把 key 发到聊天、截图或仓库 issue。
- 先用 CC Switch 自带界面确认 provider 可切换，再回到 Claude Code。

如果脚本录入失败，可不使用 `-ConfigureApi`，让学生手动在 CC Switch 中配置。

## UE/Unity/Godot/Blender 显示 SKIP

`SKIP` 代表安装器没有找到对应软件，不代表课程安装失败。按课程需要安装软件本体后重跑对应模块：

```powershell
.\install.ps1 -Modules unreal
.\install.ps1 -Modules unity
.\install.ps1 -Modules godot
.\install.ps1 -Modules blender
```

## WSL2 不可用

检查：

```powershell
wsl --status
```

如果命令不存在，说明系统没有启用 WSL。课堂可以先走原生 Windows 路线，WSL 作为课后增强。

## 合并已有项目后文件变化不符合预期

安装器会把冲突路径复制到：

```text
<WorkspacePath>\.backups
```

从 `.backups` 里恢复对应文件即可。

## 健康报告在哪里

默认位置：

```powershell
$HOME\GameCourseAI\health-report.json
```

报告中不应包含 API Key、token 或 secret。如发现敏感信息，停止分发当前版本并修复测试。
