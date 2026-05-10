# Unreal Engine MCP 使用指南

## 简介

Unreal MCP 让 Claude Code 能够直接与 Unreal Engine 5 交互，实现自动化开发操作。

## 功能特性

### 可用功能

| 功能 | 描述 | 示例用途 |
|------|------|----------|
| **蓝图操作** | 创建、修改蓝图 | 自动生成 UI 蓝图 |
| **资产创建** | 创建 Actor、组件等 | 批量创建道具 |
| **关卡编辑** | 放置、移动物体 | 自动布置场景 |
| **材质操作** | 创建和修改材质 | 批量修改材质参数 |
| **动画控制** | 操作动画蓝图 | 设置动画状态机 |
| **Python 脚本** | 执行 Python 代码 | 复杂批量操作 |

## 安装步骤

### 1. 安装前提条件

- Unreal Engine 5.7 或更高版本
- Python 3.12（UE 内置或系统安装）
- Claude Code 已安装

### 2. 安装 MCP 插件

**方法一：自动安装（推荐）**

1. 打开你的 UE 项目
2. 保持编辑器运行
3. 运行安装脚本：

```powershell
cd game-course-agents
.\scripts\install-unreal-mcp-bridge.ps1
```

**方法二：手动安装**

1. 从 https://github.com/ChiR24/Unreal_mcp 下载源码
2. 使用 UE 的 RunUAT 构建插件：

```powershell
RunUAT BuildPlugin -Plugin="路径\McpAutomationBridge.uplugin" -Package="输出路径"
```

3. 将构建好的插件复制到项目的 `Plugins/` 目录

### 3. 启用插件

1. 重启 Unreal Editor
2. 编辑 → 插件 → 搜索 "McpAutomationBridge"
3. 启用插件并重启

### 4. 验证连接

```powershell
# 检查 MCP 服务是否运行
Invoke-WebRequest http://localhost:3000/mcp
```

## 配置说明

### MCP 配置文件

在项目根目录的 `.mcp.json` 中添加：

```json
{
  "mcpServers": {
    "unreal-engine": {
      "type": "http",
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

### UE 项目配置

在 `Config/DefaultGame.ini` 中添加：

```ini
[/Script/McpAutomationBridge.McpAutomationBridgeSettings]
bAlwaysListen=True
ListenHost=127.0.0.1
ListenPorts=8090,8091
bMultiListen=True
bEnableNativeMCP=True
NativeMCPPort=3000
bLoadAllToolsOnStart=True
```

## 使用示例

### 在 Claude Code 中使用

```
你: 帮我创建一个简单的拾取物 Actor

AI: 我会创建一个拾取物 Actor，包含以下功能：
    - 碰撞检测
    - 旋转动画
    - 拾取逻辑
    
    [通过 MCP 在 UE 中创建 Actor...]
    
    已创建 BP_Pickup Actor，位于 Content/Blueprints/
```

### 批量操作示例

```
你: 在关卡中放置 10 个随机位置的宝箱

AI: [通过 MCP 执行关卡编辑操作]
    
    已在关卡中放置 10 个宝箱：
    - 位置随机分布在 (0,0) 到 (1000,1000) 范围内
    - 已设置随机旋转
```

### Python 脚本执行

```
你: 用 Python 导出所有静态网格体的名称

AI: [通过 MCP 执行 Python 脚本]
    
    找到 45 个静态网格体：
    1. SM_Chair
    2. SM_Table
    ...
```

## 可用命令列表

### 资产命令

| 命令 | 描述 |
|------|------|
| `create_actor` | 创建新的 Actor 蓝图 |
| `create_component` | 创建组件 |
| `duplicate_asset` | 复制资产 |
| `delete_asset` | 删除资产 |

### 关卡命令

| 命令 | 描述 |
|------|------|
| `spawn_actor` | 在关卡中生成 Actor |
| `move_actor` | 移动 Actor |
| `rotate_actor` | 旋转 Actor |
| `scale_actor` | 缩放 Actor |
| `delete_actor` | 删除关卡中的 Actor |

### 材质命令

| 命令 | 描述 |
|------|------|
| `create_material` | 创建材质 |
| `set_material_param` | 设置材质参数 |
| `assign_material` | 分配材质到网格体 |

## 故障排查

### 连接失败

1. 确认 UE 编辑器正在运行
2. 检查端口 3000 是否被占用：

```powershell
netstat -ano | findstr :3000
```

3. 确认插件已启用
4. 检查 `DefaultGame.ini` 配置

### 插件无法加载

1. 检查 UE 版本兼容性
2. 确认插件文件完整
3. 查看 UE 输出日志中的错误信息

## 进阶用法

### 自定义 MCP 工具

可以在插件中添加自定义工具：

```cpp
// 在 McpAutomationBridge 中注册新工具
REGISTER_MCP_TOOL(MyCustomTool, 
    "执行自定义操作",
    ExecuteMyCustomTool
);
```

### 多项目配置

在 `.mcp.json` 中配置多个 UE 项目：

```json
{
  "mcpServers": {
    "unreal-project-a": {
      "type": "http",
      "url": "http://localhost:3001/mcp"
    },
    "unreal-project-b": {
      "type": "http",
      "url": "http://localhost:3002/mcp"
    }
  }
}
```

## 相关资源

- [Unreal MCP GitHub](https://github.com/ChiR24/Unreal_mcp)
- [Unreal Engine Python API](https://docs.unrealengine.com/5.0/en-US/PythonAPI/)
- [MCP 协议规范](https://modelcontextprotocol.io/)
