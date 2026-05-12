# 故障排查指南

> 遇到问题不要慌，按照这个指南一步步排查。

---

## 快速诊断

运行以下命令获取系统信息：

```powershell
Write-Host "=== 系统信息 ===" -ForegroundColor Cyan
Write-Host "Git: $(git --version 2>$null)"
Write-Host "Node: $(node --version 2>$null)"
Write-Host "npm: $(npm --version 2>$null)"
Write-Host "Python: $(python --version 2>$null)"
Write-Host "Claude: $(claude --version 2>$null)"
Write-Host ""
Write-Host "=== 安装检查 ===" -ForegroundColor Cyan
Write-Host "CC Switch: $(if (Test-Path '$env:LOCALAPPDATA\Programs\CC Switch\cc-switch.exe') { '已安装' } else { '未安装' })"
Write-Host "工作区: $(if (Test-Path '$HOME\GameCourseAI') { '已创建' } else { '未创建' })"
```

---

## 常见问题解决方案

### 问题：PowerShell 提示"无法加载文件，因为在此系统上禁止运行脚本"

**原因**：Windows 默认禁止运行未签名的脚本。

**解决方案**：

在当前 PowerShell 窗口临时允许脚本执行：

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
```

这只会影响当前窗口，关闭后恢复原设置。**不要**要求学生永久修改系统执行策略。

### 问题：`install.ps1 -DryRun` 提示 `字符串缺少终止符: "@`

**原因**：PowerShell 在执行前解析脚本失败，通常说明当前目录里的 `install.ps1` 不是最新版本，或来自旧 zip 包。

**解决方案**：

先确认脚本语法：

```powershell
$tokens=$null; $errors=$null
[System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path .\install.ps1), [ref]$tokens, [ref]$errors) > $null
$errors
```

如果 `$errors` 有内容，请拉取或重新下载最新 `main` 分支后再运行：

```powershell
git pull origin main
.\install.ps1 -DryRun
```

如果是浏览器下载的 zip 包，重新下载最新 zip；旧包里可能还包含损坏的重复 here-string 文本块。

---

### 问题：`npm install -g @anthropic-ai/claude-code` 失败

**可能原因及解决方案**：

#### 原因 1：npm 未安装或版本过旧

```powershell
# 检查 npm 版本
npm --version

# 如果版本低于 9，更新 npm
npm install -g npm@latest
```

#### 原因 2：网络问题（中国大陆常见）

```powershell
# 切换到国内镜像源
npm config set registry https://registry.npmmirror.com

# 安装完成后恢复（可选）
npm config set registry https://registry.npmjs.org
```

#### 原因 3：权限问题

```powershell
# 以管理员身份运行 PowerShell，然后执行
npm install -g @anthropic-ai/claude-code
```

---

### 问题：Claude Code 能启动，但没有 Game Studios 命令

**原因**：当前目录不是课程工作区，或模板未正确安装。

**解决方案**：

```powershell
# 1. 确认当前目录
pwd
# 应显示类似：C:\Users\你的用户名\GameCourseAI

# 2. 如果不在正确目录，切换过去
cd "$HOME\GameCourseAI"

# 3. 检查必要文件是否存在
Test-Path ".claude"
Test-Path "CLAUDE.md"
# 都应返回 True

# 4. 如果返回 False，重新安装 Game Studios 模块
cd game-course-agents
.\install.ps1 -Modules game-studios
```

---

### 问题：CC Switch 无法使用

**解决方案**：

#### 方法 1：手动配置（推荐）

1. 按 `Win` 键，搜索 "CC Switch"
2. 打开 CC Switch 应用程序
3. 在应用界面中添加服务商信息
4. **安全提示**：不要在聊天、截图或代码中分享 API 密钥

#### 方法 2：通过命令行配置

```powershell
.\install.ps1 -ConfigureApi
```

按提示输入：
- Provider name：服务商名称（如 `anthropic`）
- Base URL：API 地址（可直接按回车使用默认值）
- API key：密钥（输入时不显示字符）

---

### 问题：UE/Unity/Godot/Blender 显示 SKIP

**说明**：这不是错误！

`SKIP` 表示安装器没有检测到该软件。这不影响其他功能的使用。

**解决方案**：

1. 如果你需要使用该引擎，先安装对应的软件
2. 安装完成后重新运行安装器：
   ```powershell
   .\install.ps1 -Modules unreal    # 重新检测 UE
   .\install.ps1 -Modules unity     # 重新检测 Unity
   .\install.ps1 -Modules godot     # 重新检测 Godot
   .\install.ps1 -Modules blender   # 重新检测 Blender
   ```

---

### 问题：UE MCP 插件安装失败

**检查清单**：

1. **UE 编辑器是否正在运行？**
   ```powershell
   # 检查 UE 进程
   Get-Process -Name "UnrealEditor*" -ErrorAction SilentlyContinue
   ```
   必须先打开 UE 项目才能安装插件。

2. **是否指定了正确的项目路径？**
   ```powershell
   # 手动指定路径
   .\scripts\install-unreal-mcp-bridge.ps1 `
     -UnrealProjectPath "D:\MyProject\MyProject.uproject"
   ```

3. **UE 是否正确安装？**
   ```powershell
   # 检查 UE 安装位置
   Test-Path "C:\Program Files\Epic Games\UE_5.5"
   ```

---

### 问题：WSL2 不可用

**检查**：

```powershell
wsl --status
```

**如果显示"无法识别的命令"**：

1. 启用 WSL 功能：
   ```powershell
   wsl --install
   ```
2. 重启电脑
3. 安装 Ubuntu 或其他 Linux 发行版

**课堂建议**：WSL 是可选功能。如果课堂时间有限，可以先跳过，让学生在原生 Windows 环境下工作。

---

### 问题：合并已有项目后文件变化不符合预期

**说明**：安装器会把冲突文件备份到 `.backups` 目录。

**恢复步骤**：

```powershell
# 1. 查看备份目录
dir "$HOME\GameCourseAI\.backups"

# 2. 找到需要恢复的文件

# 3. 从备份复制回来
Copy-Item "$HOME\GameCourseAI\.backups\CLAUDE.md-20260510-120000" "$HOME\GameCourseAI\CLAUDE.md"
```

---

### 问题：健康报告包含错误信息

**查看健康报告**：

```powershell
Get-Content "$HOME\GameCourseAI\health-report.json"
```

**常见错误状态**：

| 状态 | 含义 | 是否需要处理 |
|------|------|--------------|
| `PASS` | 成功 | 否 |
| `SKIP` | 跳过（软件未安装） | 按需 |
| `WARN` | 警告，但不影响使用 | 可选 |
| `FAIL` | 失败，需要处理 | 是 |

---

### 问题：网络连接超时

**解决方案**：

#### 方案 1：使用离线缓存

教师提前准备：
```powershell
.\scripts\prepare-offline-cache.ps1 -CachePath "D:\offline-cache"
```

学生使用离线缓存安装：
```powershell
.\install.ps1 -OfflineCache "D:\offline-cache"
```

#### 方案 2：使用代理

```powershell
# 设置 npm 代理
npm config set proxy http://proxy-server:port
npm config set https-proxy http://proxy-server:port

# 设置 git 代理
git config --global http.proxy http://proxy-server:port
```

---

### 问题：安装后找不到 Claude Code 命令

**原因**：环境变量未更新。

**解决方案**：

1. **关闭所有 PowerShell 窗口**
2. **重新打开 PowerShell**
3. 再次尝试：
   ```powershell
   claude --version
   ```

如果仍然不行，手动添加到当前会话的 PATH：

```powershell
$env:Path += ";$env:APPDATA\npm"
claude --version
```

---

## 重新安装

如果需要完全重新安装：

```powershell
# 1. 删除工作区
Remove-Item -Recurse -Force "$HOME\GameCourseAI"

# 2. 卸载 Claude Code（可选）
npm uninstall -g @anthropic-ai/claude-code

# 3. 重新运行安装器
.\install.ps1
```

---

## 获取帮助

如果以上方案都无法解决问题：

1. 收集以下信息：
   - Windows 版本（运行 `winver` 查看）
   - 健康报告内容
   - 错误信息的完整截图

2. 在 GitHub 提交 Issue：
   https://github.com/leijieming/game-course-agents/issues

3. 或联系课程教师

---

## 安全提醒

- **永远不要**在聊天、截图或代码中分享你的 API 密钥
- **永远不要**把密钥提交到 Git 仓库
- 健康报告中不应包含密钥；如果发现，请立即报告
