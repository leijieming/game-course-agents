# Unity MCP 使用指南

## 简介

Unity MCP 让 Claude Code 能够直接与 Unity 编辑器交互，实现自动化开发操作。

## 功能特性

| 功能 | 描述 | 示例用途 |
|------|------|----------|
| **游戏对象操作** | 创建、修改、删除游戏对象 | 批量创建场景物体 |
| **组件管理** | 添加、配置组件 | 自动配置碰撞器 |
| **资产创建** | 创建 Prefab、材质等 | 批量生成 Prefab |
| **场景编辑** | 编辑场景内容 | 自动布置关卡 |
| **脚本生成** | 生成 C# 脚本 | 创建游戏逻辑代码 |

## 安装步骤

### 1. 安装前提条件

- Unity 2021.3 或更高版本
- Node.js 18 或更高版本
- Claude Code 已安装

### 2. 安装 Unity MCP Server

**方法一：使用 npm 安装（推荐）**

```powershell
npm install -g unity-mcp-server
```

**方法二：从源码安装**

```powershell
git clone https://github.com/AnkleBreaker-Studio/unity-mcp-server.git
cd unity-mcp-server
npm install
npm run build
```

### 3. 在 Unity 项目中启用

1. 打开 Unity 项目
2. 将 MCP Server 包导入项目
3. 在菜单中选择 Tools → MCP Server → Enable
4. 确认服务启动（默认端口 8090）

### 4. 配置 MCP 连接

在项目根目录创建 `.mcp.json`：

```json
{
  "mcpServers": {
    "unity": {
      "command": "node",
      "args": ["你的路径/unity-mcp-server/build/index.js"],
      "env": {
        "UNITY_MCP_HOST": "127.0.0.1",
        "UNITY_MCP_PORT": "8090"
      }
    }
  }
}
```

## 使用示例

### 创建游戏对象

```
你: 在场景中创建一个玩家对象，包含移动和跳跃功能

AI: 我会创建一个玩家对象：
    1. 创建 Player 游戏对象
    2. 添加 Rigidbody2D 组件
    3. 添加碰撞器
    4. 生成 PlayerController.cs 脚本
    
    [通过 MCP 在 Unity 中执行...]
    
    已创建 Player 对象和对应的控制器脚本。
```

### 批量操作

```
你: 创建 10 个随机位置的敌人

AI: [通过 MCP 执行批量创建]
    
    已在场景中创建 10 个敌人：
    - 位置随机分布
    - 已添加 Enemy 脚本
    - 已配置碰撞检测
```

### 资产生成

```
你: 为所有 Sprite 创建对应的 Prefab

AI: [扫描项目中的 Sprite 并创建 Prefab]
    
    已创建 25 个 Prefab：
    - Assets/Prefabs/Sprites/Sprite_01.prefab
    - Assets/Prefabs/Sprites/Sprite_02.prefab
    ...
```

## 可用 API

### 游戏对象操作

```javascript
// 创建游戏对象
mcp.createGameObject(name, position, rotation)

// 查找游戏对象
mcp.findGameObject(name)

// 删除游戏对象
mcp.destroyGameObject(name)

// 添加组件
mcp.addComponent(gameObject, componentType)
```

### 资产操作

```javascript
// 创建 Prefab
mcp.createPrefab(name, gameObject)

// 创建材质
mcp.createMaterial(name, shader)

// 导入资产
mcp.importAsset(path)
```

### 场景操作

```javascript
// 保存场景
mcp.saveScene()

// 加载场景
mcp.loadScene(name)

// 获取场景中的所有对象
mcp.getSceneObjects()
```

## 配置选项

### 环境变量

| 变量 | 描述 | 默认值 |
|------|------|--------|
| `UNITY_MCP_HOST` | MCP 服务主机地址 | 127.0.0.1 |
| `UNITY_MCP_PORT` | MCP 服务端口 | 8090 |
| `UNITY_PROJECT_PATH` | Unity 项目路径 | 当前目录 |

### Unity 编辑器设置

在 `Edit → Preferences → MCP Server` 中配置：

- **Enable MCP Server** - 启用 MCP 服务
- **Port** - 监听端口
- **Auto Start** - 编辑器启动时自动启动服务

## 故障排查

### 连接失败

1. 确认 Unity 编辑器正在运行
2. 检查 MCP Server 是否已启用
3. 验证端口未被占用：

```powershell
netstat -ano | findstr :8090
```

### 脚本执行失败

1. 检查脚本是否有编译错误
2. 确认脚本继承自 MonoBehaviour
3. 查看 Unity Console 中的错误日志

## 注意事项

- Unity MCP 目前为实验性功能
- 某些操作可能需要重新编译脚本
- 大量操作时注意性能影响

## 相关资源

- [Unity MCP Server GitHub](https://github.com/AnkleBreaker-Studio/unity-mcp-server)
- [Unity Scripting API](https://docs.unity3d.com/ScriptReference/)
- [MCP 协议规范](https://modelcontextprotocol.io/)
