# MCP 引擎连接指南

MCP（Model Context Protocol）是连接 AI 与游戏引擎的桥梁。本目录包含各引擎的详细使用说明。

## 什么是 MCP？

MCP 让 Claude Code 能够直接与游戏引擎交互，实现：

- **自动化操作**：通过 AI 指令控制引擎功能
- **资产创建**：自动生成和配置游戏对象
- **代码生成**：根据引擎规范生成正确的代码
- **调试辅助**：快速定位和修复问题

## 可用引擎连接

| 引擎 | 文档 | 状态 |
|------|------|------|
| Unreal Engine 5 | [unreal-mcp.md](unreal-mcp.md) | 推荐使用 |
| Unity | [unity-mcp.md](unity-mcp.md) | 实验性 |
| Godot 4 | [godot-mcp.md](godot-mcp.md) | 实验性 |
| Blender | [blender-mcp.md](blender-mcp.md) | 稳定 |

## Claude Code Game Studios 功能

Claude Code Game Studios 是游戏开发 AI 代理框架，详见 [game-studios.md](game-studios.md)。

## 快速开始

1. 安装 Claude Code 和对应引擎
2. 配置 MCP 连接（见各引擎文档）
3. 在项目目录启动 Claude Code
4. 输入 `/start` 开始引导式工作流
