# 课堂安装详细指南

> 本文档提供更详细的安装说明，适合教师课前准备和学生自学。

---

## 目录

1. [课前准备检查清单](#课前准备检查清单)
2. [软件安装详解](#软件安装详解)
3. [安装器参数说明](#安装器参数说明)
4. [安装后验证](#安装后验证)
5. [各引擎连接配置](#各引擎连接配置)

---

## 课前准备检查清单

### 教师课前准备

- [ ] 确认机房电脑满足最低配置要求
- [ ] 提前下载必要的安装包（网络不稳定时）
- [ ] 准备 API 密钥（如需要）
- [ ] 测试安装流程

### 学生电脑最低要求

| 项目 | 最低要求 | 推荐配置 |
|------|----------|----------|
| 操作系统 | Windows 10 | Windows 11 |
| 内存 | 8 GB | 16 GB 或更多 |
| 硬盘空间 | 10 GB 可用空间 | 50 GB 以上（含游戏引擎） |
| 网络 | 能访问 GitHub 和 npm | 稳定的宽带连接 |

### 必装软件检查

打开 PowerShell，逐条运行以下命令检查：

```powershell
# 检查 Git
git --version
# 应显示类似：git version 2.x.x

# 检查 Node.js
node --version
# 应显示类似：v20.x.x 或更高

# 检查 npm
npm --version
# 应显示类似：10.x.x 或更高
```

如果某个命令显示"无法识别"，说明该软件未安装。

---

## 软件安装详解

### Git 安装

1. 访问 https://git-scm.com/download/win
2. 点击 **Click here to download** 自动下载
3. 运行下载的安装程序
4. 安装选项说明：
   - **安装位置**：默认即可
   - **选择组件**：默认即可
   - **默认编辑器**：选择你熟悉的编辑器，或保持默认
   - **PATH 环境**：选择 **Git from the command line and also from 3rd-party software**
   - 后续选项保持默认，点击 **Install**

### Node.js 安装

1. 访问 https://nodejs.org/
2. 点击 **20.x.x LTS** 按钮（长期支持版本）
3. 运行下载的安装程序
4. 安装选项说明：
   - 勾选 **Automatically install the necessary tools**（自动安装必要工具）
   - 其他选项保持默认
   - 点击 **Install**

安装完成后，**关闭并重新打开 PowerShell**，使环境变量生效。

### Python 安装（可选）

1. 访问 https://www.python.org/downloads/
2. 下载 Python 3.12.x 版本
3. 运行安装程序
4. **重要**：勾选 **Add Python to PATH**
5. 点击 **Install Now**

---

## 安装器参数说明

### 基本用法

```powershell
.\install.ps1
```

使用默认设置安装所有模块。

### 常用参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `-WorkspacePath` | 指定安装位置 | `-WorkspacePath "D:\MyWorkspace"` |
| `-DryRun` | 预览模式，不实际安装 | `-DryRun` |
| `-ConfigureApi` | 配置 API 密钥 | `-ConfigureApi` |
| `-IncludeWsl` | 启用 WSL2 支持 | `-IncludeWsl` |
| `-Modules` | 只安装指定模块 | `-Modules claude-code,game-studios` |
| `-OfflineCache` | 使用离线缓存 | `-OfflineCache "D:\cache"` |
| `-SkipMcpConfig` | 跳过 MCP 配置 | `-SkipMcpConfig` |

### 使用示例

**预览安装内容：**
```powershell
.\install.ps1 -DryRun
```

**安装到自定义位置：**
```powershell
.\install.ps1 -WorkspacePath "D:\GameCourse"
```

**只安装核心工具：**
```powershell
.\install.ps1 -Modules toolchain,claude-code,game-studios
```

**配置 API 并安装：**
```powershell
.\install.ps1 -ConfigureApi
```

**使用离线缓存（机房网络不稳定时）：**
```powershell
.\install.ps1 -OfflineCache "D:\offline-cache"
```

---

## 安装后验证

### 自动验证

安装完成后，查看健康报告：

```powershell
Get-Content "$HOME\GameCourseAI\health-report.json"
```

所有模块应显示 `"status": "PASS"` 或 `"status": "SKIP"`（SKIP 表示该软件未安装，属正常情况）。

### 手动验证

**验证 Claude Code：**
```powershell
claude --version
# 应显示版本号，如：2.1.138

claude doctor
# 运行诊断检查
```

**验证 CC Switch：**
```powershell
# 检查程序是否存在
Test-Path "$env:LOCALAPPDATA\Programs\CC Switch\cc-switch.exe"
# 应返回 True
```

**验证 Game Studios 模板：**
```powershell
Test-Path "$HOME\GameCourseAI\CLAUDE.md"
Test-Path "$HOME\GameCourseAI\.claude"
# 都应返回 True
```

**验证 MCP 配置：**
```powershell
Get-Content "$HOME\GameCourseAI\.mcp.json"
# 应显示 JSON 格式的 MCP 服务器配置
```

---

## 各引擎连接配置

### Unreal Engine 5

#### 前置条件

- 已安装 Unreal Engine 5.0 或更高版本
- 有一个 UE 项目（`.uproject` 文件）

#### 安装步骤

1. **打开 UE 项目**
   - 启动 Unreal Editor
   - 打开你的项目

2. **保持编辑器运行**，打开新的 PowerShell 窗口

3. **运行插件安装脚本**：
   ```powershell
   cd game-course-agents
   .\scripts\install-unreal-mcp-bridge.ps1
   ```

4. **脚本会自动**：
   - 检测正在运行的 UE 编辑器
   - 找到项目文件和引擎路径
   - 编译并安装 McpAutomationBridge 插件
   - 配置 Native MCP

5. **重启 Unreal Editor**

6. **验证连接**：
   - UE 编辑器右下角应显示 `MCP :3000`
   - 或运行：
     ```powershell
     Invoke-WebRequest http://localhost:3000/mcp
     ```

#### 手动指定项目路径

如果脚本无法自动检测，可以手动指定：

```powershell
.\scripts\install-unreal-mcp-bridge.ps1 `
  -UnrealProjectPath "D:\MyProject\MyProject.uproject" `
  -EnginePath "F:\Program Files\Epic Games\UE_5.5"
```

### Unity

1. 安装 Unity MCP Server 插件包
2. 在 Unity 中导入插件
3. 启用 MCP 服务
4. 配置 `.mcp.json` 中的 Unity 连接

详细步骤参考：https://github.com/AnkleBreaker-Studio/unity-mcp-server

### Godot 4

1. 下载 godot-mcp 插件
2. 复制到项目的 `addons` 目录
3. 在项目设置中启用插件
4. 配置 autoload

详细步骤参考：https://github.com/tugcantopaloglu/godot-mcp

### Blender

1. 安装 Blender 4.x 或更高版本
2. 确保 `uvx` 已安装：
   ```powershell
   uvx --version
   ```
3. 在 Blender 中启用 MCP addon
4. 安装器会自动配置 `.mcp.json`

详细步骤参考：https://github.com/ahujasid/blender-mcp

---

## 下一步

安装完成后，请阅读：

- [示例提示词](example-prompts.md) - 学习如何与 AI 协作
- [故障排查](troubleshooting.md) - 解决常见问题
- [课堂验收步骤](course-smoke-tests.md) - 确认安装成功
