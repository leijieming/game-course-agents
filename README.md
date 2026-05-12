# 游戏设计课程 AI Agent 辅助项目

> 让没有编程基础的学生也能快速搭建 AI 辅助游戏开发环境

这个项目帮你一键安装以下工具：

| 工具 | 作用 |
|------|------|
| **Claude Code** | AI 编程助手，可以在终端里和你对话、帮你写代码 |
| **CC Switch** | 切换不同的 AI 服务提供商（比如切换不同的 API） |
| **Claude-Code-Game-Studios** | 游戏开发专用 AI 代理模板，包含策划、美术、程序等专业角色 |
| **引擎连接工具** | 让 AI 能直接操作 Unreal Engine、Unity、Godot、Blender |

---

## 安装前准备

在运行安装器之前，你需要先安装以下**免费软件**。

### 必需软件

| 软件 | 下载地址 | 说明 |
|------|----------|------|
| **Git** | https://git-scm.com/download/win | 代码版本管理工具，安装时一路点"Next"即可 |
| **Node.js** | https://nodejs.org/ | 选择 **LTS 版本**（长期支持版），安装时一路点"Next" |

### 可选软件

| 软件 | 说明 |
|------|------|
| **Python 3.12** | 部分引擎连接功能需要，从 [python.org](https://www.python.org/downloads/) 下载 |
| **uv** | 更快的 Python 包管理器，从 [docs.astral.sh/uv](https://docs.astral.sh/uv/getting-started/installation/) 安装 |
| **WSL2** | Windows 子系统 Linux，适合需要 Linux 工具链的高级用户 |

### 游戏引擎（按需安装）

本项目**不会自动安装**这些大型软件，但会检测它们是否存在：

- **Unreal Engine 5** - 从 Epic Games Launcher 安装
- **Unity** - 从 Unity Hub 安装
- **Godot 4** - 从 godotengine.org 下载
- **Blender 4.x** - 从 blender.org 下载

---

## 安装步骤

### 第一步：下载本项目

**方法 A：使用 Git（推荐）**

1. 按 `Win + R`，输入 `cmd`，按回车打开命令提示符
2. 复制粘贴以下命令并按回车：

```powershell
git clone https://github.com/leijieming/game-course-agents.git
cd game-course-agents
```

**方法 B：直接下载 ZIP**

1. 访问 https://github.com/leijieming/game-course-agents
2. 点击绿色的 **Code** 按钮
3. 选择 **Download ZIP**
4. 解压后进入文件夹

### 第二步：预览安装内容（推荐）

在正式安装前，可以先预览安装器会做什么：

1. 在项目文件夹中，按住 `Shift` 键，在空白处**右键点击**
2. 选择 **"在此处打开 PowerShell 窗口"** 或 **"在终端中打开"**
3. 复制粘贴以下命令并按回车：

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\install.ps1 -DryRun
```

也可以把 `start-here.cmd` 直接拖入终端窗口，按回车运行。预览安装内容时，在拖入后的路径后面加一个空格和 `-DryRun`：

```powershell
.\start-here.cmd -DryRun
```

这会显示安装器将执行的所有操作，但不会真正安装。

如果 `-DryRun` 在执行前就提示 `字符串缺少终止符: "@`，请先拉取最新 `main` 或重新下载 zip 包；这是旧安装脚本里的损坏 here-string，不是执行策略问题。更多排查见 `docs/troubleshooting.md`。

### 第三步：执行安装

确认预览内容无误后，运行正式安装：

```powershell
.\install.ps1
```

最简单的方式：把 `start-here.cmd` 拖入 PowerShell、Windows Terminal 或命令提示符，按回车即可。这个入口会自动用 `-ExecutionPolicy Bypass` 调用 `install.ps1`，不需要先手动执行 `Set-ExecutionPolicy`。

`start-here.cmd` 会先打开菜单，让你确认安装内容后再执行：

- 预览默认安装
- 安装完整课程工作区
- 自选安装 Claude Code、CC Switch、Game Studios、UE/Unity/Godot/Blender MCP 等模块
- 安装缺失的环境工具：Git、Node.js LTS、Python 3.12、uv
- 配置 API Provider
- 一键移除课程安装项

移除功能会先列出将删除的目录和可选卸载项，并要求输入 `DELETE` 才会执行。它不会自动卸载 Git、Node.js、Python、Unreal、Unity、Godot 或 Blender 这类可能属于用户原有环境的大型软件。

**安装过程说明：**

- 安装器会自动检测你电脑上已安装的软件
- 缺少的工具会自动安装，已安装的会跳过
- 整个过程大约需要 5-15 分钟，取决于网络速度

**如果需要配置 API 密钥：**

```powershell
.\install.ps1 -ConfigureApi
```

安装器会提示你输入：
1. **Provider name** - 服务商名称（如 `anthropic`、`openai` 等）
2. **Base URL** - API 地址（可直接按回车使用默认值）
3. **API key** - 你的密钥（输入时不会显示，这是安全设计）

### 第四步：验证安装

安装完成后，检查是否成功：

```powershell
# 检查 Claude Code 是否安装成功
claude --version

# 查看健康报告
Get-Content "$HOME\GameCourseAI\health-report.json"
```

---

## 如何使用

### 启动 Claude Code

1. 打开 PowerShell 或命令提示符
2. 进入课程工作区：

```powershell
cd "$HOME\GameCourseAI"
```

3. 启动 Claude Code：

```powershell
claude
```

### 首次使用

启动后，输入以下命令开始：

```
/start
```

这会显示游戏开发工作流程选项，包括：
- 游戏策划阶段
- 美术设计阶段
- 程序开发阶段
- 测试与优化

### 常用命令

| 命令 | 作用 |
|------|------|
| `/help` | 显示帮助信息 |
| `/start` | 开始游戏开发工作流 |
| `/clear` | 清空对话历史 |
| `/config` | 打开设置 |

---

## 连接游戏引擎

### Unreal Engine 5

1. **先打开你的 UE 项目**（用 Unreal Editor 打开 `.uproject` 文件）
2. 保持 UE 编辑器运行，打开新的 PowerShell 窗口
3. 运行以下命令安装插件：

```powershell
cd game-course-agents
.\scripts\install-unreal-mcp-bridge.ps1
```

4. **重启 Unreal Editor**
5. 确认右下角显示 `MCP :3000`
6. 在 UE 项目文件夹中运行 `claude`

### Unity / Godot / Blender

这些引擎的连接需要额外安装对应插件，详见以下文档：

| 引擎 | 文档 | 功能 |
|------|------|------|
| **Unreal Engine 5** | [unreal-mcp.md](docs/mcp-guides/unreal-mcp.md) | 蓝图操作、资产创建、关卡编辑 |
| **Unity** | [unity-mcp.md](docs/mcp-guides/unity-mcp.md) | 游戏对象操作、组件管理、脚本生成 |
| **Godot 4** | [godot-mcp.md](docs/mcp-guides/godot-mcp.md) | 场景操作、GDScript 生成 |
| **Blender** | [blender-mcp.md](docs/mcp-guides/blender-mcp.md) | 3D 建模、材质设置、渲染控制 |

**Claude Code Game Studios** 的完整使用说明见 [game-studios.md](docs/mcp-guides/game-studios.md)。

---

## 常见问题

### PowerShell 提示"无法加载文件，因为在此系统上禁止运行脚本"

运行以下命令临时允许脚本执行：

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
```

### 安装器显示某个软件是 SKIP

这表示安装器没有找到该软件，但不影响其他功能。你可以：
- 按需安装对应的软件
- 之后重新运行安装器

### Claude Code 无法启动

1. 确认 Node.js 已正确安装：

```powershell
node --version
npm --version
```

2. 手动安装 Claude Code：

```powershell
npm install -g @anthropic-ai/claude-code
```

### CC Switch 无法使用

1. 打开 CC Switch 应用程序（在开始菜单搜索 "CC Switch"）
2. 在应用界面中手动配置服务商信息
3. 不要在聊天、截图或代码中分享你的 API 密钥

### 想重新安装

删除工作区后重新运行安装器：

```powershell
Remove-Item -Recurse -Force "$HOME\GameCourseAI"
.\install.ps1
```

### 合并到已有项目

如果你已有游戏项目，可以将模板合并进去：

```powershell
.\install.ps1 -WorkspacePath "D:\MyGameProject" -GameStudiosMode merge
```

原有文件会被备份到 `.backups` 文件夹。

---

## 进阶用法

### 离线安装（适合网络不稳定的机房）

教师可以提前准备离线缓存：

```powershell
.\scripts\prepare-offline-cache.ps1 -CachePath "D:\offline-cache"
```

学生使用离线缓存安装：

```powershell
.\install.ps1 -OfflineCache "D:\offline-cache"
```

### 只安装特定模块

```powershell
# 只安装 Claude Code 和 Game Studios
.\install.ps1 -Modules toolchain,claude-code,game-studios

# 只配置 Unreal 连接
.\install.ps1 -Modules unreal
```

### 启用 WSL2 支持

```powershell
.\install.ps1 -IncludeWsl
```

---

## 文件结构说明

```
game-course-agents/
├── install.ps1          # 主安装脚本
├── manifests/           # 各模块的安装配置
├── scripts/             # 辅助脚本
│   ├── install-unreal-mcp-bridge.ps1  # UE 插件安装
│   └── prepare-offline-cache.ps1      # 离线缓存准备
├── examples/mcp/        # MCP 配置示例
├── docs/                # 详细文档
│   ├── getting-started.md    # 详细安装指南
│   ├── troubleshooting.md    # 故障排查
│   ├── course-smoke-tests.md # 课堂验收步骤
│   └── example-prompts.md    # 示例提示词
└── tests/               # 自动化测试
```

---

## 获取帮助

- **详细安装指南**：[docs/getting-started.md](docs/getting-started.md)
- **故障排查**：[docs/troubleshooting.md](docs/troubleshooting.md)
- **问题反馈**：https://github.com/leijieming/game-course-agents/issues

---

## 相关项目

| 项目 | 说明 |
|------|------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | 官方文档 |
| [CC Switch](https://github.com/farion1231/cc-switch) | 服务商切换工具 |
| [Claude-Code-Game-Studios](https://github.com/leijieming/Claude-Code-Game-Studios) | 游戏开发代理模板 |
| [Unreal MCP](https://github.com/ChiR24/Unreal_mcp) | UE 连接插件 |
| [Unity MCP](https://github.com/AnkleBreaker-Studio/unity-mcp-server) | Unity 连接插件 |
| [Godot MCP](https://github.com/tugcantopaloglu/godot-mcp) | Godot 连接插件 |
| [Blender MCP](https://github.com/ahujasid/blender-mcp) | Blender 连接插件 |

---

## 许可证

本项目采用 MIT 许可证，详见 [LICENSE](LICENSE)。
