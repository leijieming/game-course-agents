# 安全边界

本项目只做本机部署和课程连接，不提供云端密钥托管。

## 密钥处理

- API Key 使用 PowerShell secure string 输入。
- 脚本不把 API Key 输出到终端。
- 健康报告只记录 provider 名称、base URL、路径和状态。
- `.gitignore` 排除 `*.local.json`、`*.secret.json` 和健康报告。

## 学生支持

教师排查问题时只收集：

- `health-report.json`
- `claude --version`
- `node --version`
- 具体软件是否已安装

不要收集：

- API Key
- CC Switch 本地密钥库
- 学生的 `.env` 文件
- 带有 Authorization header 的日志

## 上游依赖

四个 MCP/插件适配器来自独立开源项目。本仓库默认记录和引导，不把第三方二进制文件提交到仓库。
