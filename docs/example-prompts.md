# 课程示例 Prompts

这些 prompts 用于验证 Game Studios 工作流是否真的参与设计过程。课堂中建议先让学生观察 Claude Code 如何提问，再进入代码生成。

## 游戏概念发散

```text
使用 /brainstorm 帮我设计一个 3 分钟可玩的教学小游戏。主题是“资源有限时的策略选择”。先问我 3 个关键问题，不要直接写代码。
```

## 系统设计

```text
使用 /design-system 为一个 Godot 4 原型设计核心循环。请输出玩家目标、资源、反馈、失败条件和最小可玩范围。
```

## 引擎选择

```text
使用 /setup-engine 比较 UE5、Unity、Godot 4 对这个课堂原型的适配度。请优先考虑学生电脑配置、学习成本和一节课内能否跑起来。
```

## Unity 原型

```text
请调用 Unity specialist 帮我把这个玩法拆成 3 个脚本、2 个场景对象和 1 个测试清单。先给结构，不要直接写完整代码。
```

## Unreal 原型

```text
请调用 Unreal specialist 设计一个 Blueprint-first 的课堂原型方案。要求能在 45 分钟内演示输入、反馈和胜负条件。
```

## Godot 原型

```text
请调用 Godot specialist 设计一个 Godot 4 场景树结构和 GDScript 文件划分。要求节点命名适合初学者理解。
```

## Blender 资产

```text
请调用 art-director 和 technical-artist 为这个原型制定 5 个低多边形资产规格，并说明哪些可以在 Blender 中快速制作。
```

## 课堂复盘

```text
请使用 /retrospective 总结本节课的 AI 协作过程：哪些决策由人做，哪些由 agent 辅助，哪些输出需要人工验证。
```
