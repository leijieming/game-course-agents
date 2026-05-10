# 课堂安装说明

## 课前准备

学生电脑建议准备：

- Windows 10/11
- PowerShell 5.1 或 PowerShell 7
- Git
- Node.js LTS
- 可选：Python 3、uv、WSL2
- 至少安装一个课程使用的软件：UE5、Unity、Godot 4、Blender 4.x

安装器不会自动安装 UE、Unity、Godot 或 Blender。本项目只负责 Claude Code、CC Switch、Game Studios 模板和 MCP 连接层。

## 第一步：下载课程仓库

```powershell
git clone https://github.com/leijieming/game-course-agents.git
cd game-course-agents
```

如果课堂还没有公开仓库，可以把本目录拷贝到学生电脑后直接进入目录运行。

## 第二步：先做 dry-run

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\install.ps1 -DryRun -IncludeWsl
```

dry-run 只显示将要执行的动作，不会复制模板、写配置或安装包。

## 第三步：正式安装

```powershell
.\install.ps1 -WorkspacePath "$HOME\GameCourseAI" -IncludeWsl -ConfigureApi
```

`-ConfigureApi` 会交互式询问 provider 名称、base URL 和 API Key。脚本使用 `Read-Host -AsSecureString` 获取密钥，不把密钥输出到终端或健康报告。

## 第四步：打开 Claude Code

```powershell
cd "$HOME\GameCourseAI"
claude
```

进入后先运行：

```text
/start
```

然后按课程目标选择游戏设计阶段、引擎和 review 强度。

## 原生 Windows 与 WSL2 的分工

- 原生 Windows：检测 UE/Unity/Godot/Blender，安装或启用桌面软件内插件，启动 MCP bridge。
- WSL2：适合运行 Linux 命令行工具、Git、Node、Python、Claude Code。
- 课程建议：学生主要在原生 Windows 使用桌面软件；需要 Linux 工具链时再打开 WSL2。

## 离线缓存模式

如果机房网络不稳定，教师可以提前准备：

```powershell
.\install.ps1 -OfflineCache "D:\game-course-cache"
```

当前 V1 会校验缓存文件是否存在和校验和是否匹配；具体缓存文件见 `manifests/*.json` 的 `cacheArtifacts`。

## 合并到已有项目

默认安装器把 Game Studios 模板复制到新的课程工作区。要合并到已有项目：

```powershell
.\install.ps1 -WorkspacePath "D:\MyGameProject" -GameStudiosMode merge
```

如果目标目录已有 `CLAUDE.md`、`.claude`、`docs` 等路径，安装器会先复制到 `.backups`，再写入模板内容。

## 四个软件的连接策略

- UE5：安装器会安装 `unrealcli` 和 Python 包 `unrealmcp`，并把 Claude Code 配置为 stdio MCP server。UE 内 UnrealMCP Bridge 启用并运行后再让 Claude Code 连接。
- Unity：优先使用 `AnkleBreaker-Studio/unity-mcp-server`，Unity 侧导入插件包。
- Godot 4：优先使用 `tugcantopaloglu/godot-mcp`，项目侧启用 autoload 或插件。
- Blender 4.x：优先使用 `ahujasid/blender-mcp`，Blender 侧启用 addon，Claude Code 侧用 `uvx blender-mcp`。

具体插件安装步骤以对应上游项目 README 为准；本仓库负责把课程路径、MCP 配置和健康检查串起来。

### UE 5.7 验证

安装器会优先从 Epic Launcher 安装清单检测 UE5，因此支持 `F:\Program Files\Epic Games\UE_5.7` 这类非 C 盘安装路径。

只配置 Unreal 相关工具可以运行：

```powershell
.\install.ps1 -WorkspacePath "$HOME\GameCourseAI" -Modules toolchain,game-studios,unreal
```

安装完成后可以检查：

```powershell
Get-Content "$HOME\GameCourseAI\.mcp.json"
ue-cli doctor
```

如果 `ue-cli doctor` 提示没有 `.uproject` 或无法连接 `127.0.0.1:55557`，说明当前还没有打开具体 UE 项目，或 UE 编辑器内的 UnrealMCP Bridge 没有启动。

## CC Switch 安装说明

CC Switch 是桌面应用，不按 npm 包处理。安装器会优先检测本机是否已安装；如果没有安装，会尝试从 GitHub latest release 下载 Windows MSI。机房网络不稳定时，教师可以提前把 MSI 放入离线缓存：

```text
<OfflineCache>\cc-switch\release.msi
```
