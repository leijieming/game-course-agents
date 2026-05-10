# Godot MCP 使用指南

## 简介

Godot MCP 让 Claude Code 能够与 Godot 4 引擎交互，实现 GDScript 代码生成、场景操作等自动化功能。

## 功能特性

| 功能 | 描述 | 示例用途 |
|------|------|----------|
| **场景操作** | 创建、修改场景节点 | 自动生成 UI 场景 |
| **脚本生成** | 生成 GDScript 代码 | 创建游戏逻辑脚本 |
| **资源管理** | 管理项目资源 | 批量导入素材 |
| **项目配置** | 修改项目设置 | 配置输入映射 |

## 安装步骤

### 1. 安装前提条件

- Godot 4.0 或更高版本
- Node.js 18 或更高版本
- Claude Code 已安装

### 2. 安装 Godot MCP

**方法一：使用 npm（推荐）**

```powershell
npm install -g godot-mcp
```

**方法二：从源码安装**

```powershell
git clone https://github.com/tugcantopaloglu/godot-mcp.git
cd godot-mcp
npm install
npm run build
```

### 3. 配置 Godot 项目

1. 打开 Godot 项目
2. 创建或确认项目有 `addons` 目录
3. 将 MCP 插件复制到 `addons/godot-mcp`

### 4. 启用插件

1. 项目 → 项目设置 → 插件
2. 启用 Godot MCP 插件
3. 重启 Godot

### 5. 配置 MCP 连接

在项目根目录创建 `.mcp.json`：

```json
{
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["你的路径/godot-mcp/dist/index.js"],
      "env": {
        "GODOT_MCP_HOST": "127.0.0.1",
        "GODOT_MCP_PORT": "9080"
      }
    }
  }
}
```

## 使用示例

### 创建节点

```
你: 创建一个玩家节点，包含精灵和碰撞检测

AI: 我会创建玩家节点：
    1. 创建 CharacterBody2D 节点
    2. 添加 Sprite2D 子节点
    3. 添加 CollisionShape2D
    4. 生成移动脚本
    
    [通过 MCP 在 Godot 中创建...]
    
    已创建 Player.tscn 和 Player.gd
```

### 生成 GDScript

```
你: 生成一个敌人 AI 脚本，可以巡逻和追击玩家

AI: [生成 GDScript 代码]

```gdscript
extends CharacterBody2D

@export var patrol_speed: float = 100.0
@export var chase_speed: float = 200.0
@export var detection_range: float = 200.0

var player: Node2D
var patrol_points: Array[Vector2]
var current_patrol_index: int = 0

func _ready():
    player = get_tree().get_first_node_in_group("player")
    setup_patrol_points()

func _physics_process(delta):
    if can_see_player():
        chase_player()
    else:
        patrol()

func can_see_player() -> bool:
    if not player:
        return false
    return global_position.distance_to(player.global_position) < detection_range

func chase_player():
    var direction = (player.global_position - global_position).normalized()
    velocity = direction * chase_speed
    move_and_slide()

func patrol():
    if patrol_points.is_empty():
        return
    var target = patrol_points[current_patrol_index]
    var direction = (target - global_position).normalized()
    velocity = direction * patrol_speed
    if global_position.distance_to(target) < 10:
        current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
    move_and_slide()

func setup_patrol_points():
    # 自动生成巡逻点
    patrol_points = [
        global_position + Vector2(-100, 0),
        global_position + Vector2(100, 0)
    ]
```

脚本已保存到 scripts/enemy.gd
```

### 场景操作

```
你: 创建一个主菜单场景

AI: [通过 MCP 创建场景结构]
    
    已创建 MainMenu.tscn：
    - Control (根节点)
      - VBoxContainer
        - Label (标题)
        - Button (开始游戏)
        - Button (设置)
        - Button (退出)
```

## 可用 API

### 节点操作

```javascript
// 创建节点
mcp.createNode(type, name, parent)

// 删除节点
mcp.deleteNode(path)

// 修改节点属性
mcp.setNodeProperty(path, property, value)

// 添加子节点
mcp.addChild(parentPath, childNode)
```

### 场景操作

```javascript
// 创建场景
mcp.createScene(name, rootType)

// 保存场景
mcp.saveScene(path)

// 打开场景
mcp.openScene(path)

// 运行场景
mcp.runScene(path)
```

### 资源操作

```javascript
// 导入资源
mcp.importResource(sourcePath, targetPath)

// 创建资源
mcp.createResource(type, path)

// 列出资源
mcp.listResources(directory)
```

## 配置选项

### 环境变量

| 变量 | 描述 | 默认值 |
|------|------|--------|
| `GODOT_MCP_HOST` | MCP 服务主机地址 | 127.0.0.1 |
| `GODOT_MCP_PORT` | MCP 服务端口 | 9080 |
| `GODOT_PATH` | Godot 可执行文件路径 | 自动检测 |

### 项目配置

在 `project.godot` 中添加：

```ini
[autoload]
GodotMCP="*res://addons/godot-mcp/godot_mcp.gd"

[godot_mcp]
port=9080
auto_start=true
```

## 故障排查

### 无法连接到 Godot

1. 确认 Godot 编辑器正在运行
2. 检查插件是否已启用
3. 验证端口设置：

```powershell
netstat -ano | findstr :9080
```

### 脚本执行错误

1. 检查 GDScript 语法
2. 确认类型提示正确
3. 查看 Godot 输出面板

## 注意事项

- Godot MCP 目前为实验性功能
- 某些操作可能需要手动刷新编辑器
- 大型项目可能需要更长的响应时间

## 相关资源

- [Godot MCP GitHub](https://github.com/tugcantopaloglu/godot-mcp)
- [Godot 官方文档](https://docs.godotengine.org/)
- [GDScript 参考](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)
