# Blender MCP 使用指南

## 简介

Blender MCP 让 Claude Code 能够与 Blender 交互，实现 3D 建模、材质设置、渲染等自动化操作。

## 功能特性

| 功能 | 描述 | 示例用途 |
|------|------|----------|
| **建模操作** | 创建、修改 3D 模型 | 自动生成游戏资产 |
| **材质设置** | 创建和配置材质 | 批量设置 PBR 材质 |
| **动画控制** | 设置关键帧和动画 | 创建简单动画 |
| **渲染控制** | 控制渲染设置 | 批量渲染预览图 |
| **导出功能** | 导出各种格式 | 导出 FBX 到游戏引擎 |

## 安装步骤

### 1. 安装前提条件

- Blender 4.0 或更高版本
- Python 3.12 或 uvx
- Claude Code 已安装

### 2. 安装 Blender MCP

**方法一：使用 uvx（推荐）**

```powershell
# 确认 uvx 已安装
uvx --version

# Blender MCP 会自动通过 uvx 运行
```

**方法二：使用 pip 安装**

```powershell
pip install blender-mcp
```

### 3. 在 Blender 中启用插件

1. 打开 Blender
2. 编辑 → 偏好设置 → 插件
3. 点击"安装..."，选择 blender-mcp 插件
4. 启用插件

或者手动安装：

```powershell
# 复制插件到 Blender 插件目录
copy blender_mcp "%APPDATA%\Blender Foundation\Blender\4.2\scripts\addons\"
```

### 4. 配置 MCP 连接

在项目根目录创建 `.mcp.json`：

```json
{
  "mcpServers": {
    "blender": {
      "command": "uvx",
      "args": ["blender-mcp"],
      "env": {
        "BLENDER_MCP_HOST": "127.0.0.1",
        "BLENDER_MCP_PORT": "9876"
      }
    }
  }
}
```

## 使用示例

### 创建基础模型

```
你: 创建一个简单的低多边形树木模型

AI: 我会创建一个低多边形树木：
    1. 创建圆锥体作为树冠
    2. 创建圆柱体作为树干
    3. 设置材质颜色
    4. 合并为单个对象
    
    [通过 MCP 在 Blender 中创建...]
    
    已创建 LowPolyTree 对象，包含 120 个多边形。
```

### 材质操作

```
你: 为选中的对象创建一个金属材质

AI: [通过 MCP 创建 PBR 金属材质]
    
    已创建 MetalMaterial：
    - 基础色：银灰色
    - 金属度：0.9
    - 粗糙度：0.3
    - 已应用到选中对象
```

### 批量导出

```
你: 将场景中所有对象导出为 FBX，用于 Unity

AI: [通过 MCP 执行批量导出]
    
    已导出 15 个对象到 exports/ 目录：
    - Tree_01.fbx
    - Rock_01.fbx
    - Building_01.fbx
    ...
    
    导出设置：
    - 比例：1.0
    - 前进轴：-Z
    - 上轴：Y
    - 应用变换：是
```

### 渲染设置

```
你: 设置场景用于渲染产品展示图

AI: [通过 MCP 配置渲染]
    
    已配置：
    - 渲染引擎：Cycles
    - 分辨率：1920x1080
    - 采样数：256
    - 添加 HDRI 环境光
    - 创建三点布光
```

## 可用命令

### 对象操作

| 命令 | 描述 |
|------|------|
| `create_cube` | 创建立方体 |
| `create_sphere` | 创建球体 |
| `create_cylinder` | 创建圆柱体 |
| `create_cone` | 创建圆锥体 |
| `delete_object` | 删除对象 |
| `duplicate_object` | 复制对象 |
| `move_object` | 移动对象 |
| `rotate_object` | 旋转对象 |
| `scale_object` | 缩放对象 |

### 材质操作

| 命令 | 描述 |
|------|------|
| `create_material` | 创建材质 |
| `set_material_color` | 设置材质颜色 |
| `set_material_metallic` | 设置金属度 |
| `set_material_roughness` | 设置粗糙度 |
| `assign_material` | 分配材质到对象 |

### 导出操作

| 命令 | 描述 |
|------|------|
| `export_fbx` | 导出 FBX |
| `export_obj` | 导出 OBJ |
| `export_gltf` | 导出 GLTF/GLB |

### 渲染操作

| 命令 | 描述 |
|------|------|
| `render_image` | 渲染图像 |
| `set_render_resolution` | 设置渲染分辨率 |
| `set_render_engine` | 设置渲染引擎 |

## Python 脚本示例

Claude Code 可以通过 MCP 执行 Blender Python 脚本：

```python
import bpy

# 创建一个游戏资产
def create_game_asset(name, location):
    # 创建基础几何体
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.active_object
    obj.name = name
    
    # 添加细分修改器
    modifier = obj.modifiers.new(name="Subdivision", type='SUBSURF')
    modifier.levels = 2
    
    # 创建材质
    mat = bpy.data.materials.new(name=f"{name}_material")
    mat.use_nodes = True
    principled = mat.node_tree.nodes['Principled BSDF']
    principled.inputs['Base Color'].default_value = (0.8, 0.2, 0.1, 1)
    
    # 应用材质
    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)
    
    return obj

# 执行
create_game_asset("GameProp_01", (0, 0, 0))
```

## 配置选项

### 环境变量

| 变量 | 描述 | 默认值 |
|------|------|--------|
| `BLENDER_MCP_HOST` | MCP 服务主机地址 | 127.0.0.1 |
| `BLENDER_MCP_PORT` | MCP 服务端口 | 9876 |
| `BLENDER_PATH` | Blender 可执行文件路径 | 自动检测 |

### Blender 插件设置

在 Blender 偏好设置中配置：

- **Port** - MCP 服务端口
- **Auto Start** - 启动时自动启动服务
- **Allowed Operations** - 允许的操作类型

## 游戏开发工作流

### 创建游戏资产流程

```
1. 在 Blender 中创建模型
   ↓
2. 优化多边形数量
   ↓
3. UV 展开
   ↓
4. 创建材质
   ↓
5. 导出 FBX/GLTF
   ↓
6. 导入游戏引擎
```

### 自动化示例

```
你: 我有一个高模角色，需要创建游戏用的低模版本

AI: 我会帮你创建 LOD：
    1. 分析当前模型的面数
    2. 创建低模版本
    3. 生成法线贴图
    4. 导出两个版本
    
    当前模型：150,000 面
    目标低模：15,000 面
    
    [执行自动 LOD 生成...]
```

## 故障排查

### 无法连接到 Blender

1. 确认 Blender 正在运行
2. 检查插件是否已启用
3. 验证端口：

```powershell
netstat -ano | findstr :9876
```

### uvx 命令找不到

安装 uv：

```powershell
# Windows
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"

# 或使用 pip
pip install uv
```

### 导出失败

1. 检查文件路径权限
2. 确认导出格式支持
3. 查看 Blender 控制台错误信息

## 相关资源

- [Blender MCP GitHub](https://github.com/ahujasid/blender-mcp)
- [Blender Python API](https://docs.blender.org/api/current/)
- [Blender 手册](https://docs.blender.org/manual/en/latest/)
