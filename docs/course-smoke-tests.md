# 课堂 Smoke Test

每位学生完成安装后，按下面顺序验收。教师只需要看 `PASS/WARN/SKIP/FAIL` 和健康报告。

## 1. 基础工具

```powershell
git --version
node --version
npm --version
claude --version
```

预期：Git、Node、npm、Claude Code 都能输出版本号。

## 2. 课程工作区

```powershell
Test-Path "$HOME\GameCourseAI\CLAUDE.md"
Test-Path "$HOME\GameCourseAI\.claude"
Test-Path "$HOME\GameCourseAI\.mcp.json"
```

预期：三个命令都返回 `True`。

## 3. Claude Code 启动

```powershell
cd "$HOME\GameCourseAI"
claude
```

在 Claude Code 内输入：

```text
/start
```

预期：Game Studios 工作流出现，并引导学生选择项目阶段。

## 4. CC Switch

```powershell
ccswitch --version
```

如果命令名不同，也尝试：

```powershell
cc-switch --version
```

预期：能打开或输出版本。Provider 切换由学生在本机自行完成。

## 5. UE5

```powershell
Get-ChildItem "$env:ProgramFiles\Epic Games" -Directory -Filter "UE_5*" -ErrorAction SilentlyContinue
```

预期：已安装 UE5 的电脑能找到路径；未安装则健康报告应为 `SKIP`，不是 `FAIL`。

## 6. Unity

```powershell
Get-ChildItem "$env:ProgramFiles\Unity\Hub\Editor" -Directory -ErrorAction SilentlyContinue
```

预期：已安装 Unity 的电脑能找到编辑器路径；未安装则健康报告应为 `SKIP`。

## 7. Godot 4

```powershell
godot --version
```

预期：如果 Godot 在 PATH 中，输出版本应以 `4` 开头。便携版不在 PATH 时，可在健康报告里看到检测跳过。

## 8. Blender 4.x

```powershell
blender --version
```

预期：如果 Blender 在 PATH 中，输出版本应为 4.x。未安装时健康报告应为 `SKIP`。

## 9. MCP 配置

```powershell
Get-Content "$HOME\GameCourseAI\.mcp.json"
```

预期：包含 `unreal`、`unity`、`godot`、`blender` 四个 server 条目。

## 10. 课堂示例 Prompt

在 Claude Code 内尝试：

```text
使用 Game Studios 的 /brainstorm 流程，帮我设计一个 3 分钟可玩的 Godot 4 教学小游戏原型。先问我 3 个关键问题，不要直接写代码。
```

预期：Claude Code 使用游戏设计工作流提问，而不是立即生成大量代码。
