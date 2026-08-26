# ssh-skill（pi 移植版）

来源：[badseal/ssh-skill](https://github.com/badseal/ssh-skill) v4.0.0，MIT License。
面向 Codex / Claude Code 的 SSH 工作流 Skill，此处已适配为 pi coding agent 的
skill（Agent Skills 标准）。

## 移植改动

相对上游的全部差异集中在 `SKILL.md`，Python CLI 代码未做任何修改：

| 项 | 上游 | 本移植版 |
| --- | --- | --- |
| frontmatter | `name` / `version` / `description` / `allowed-tools: Bash, Read, Write, Glob` / `keywords` | 保留 `name` / `version` / `description`；`allowed-tools` 改为 pi 小写空格分隔（`bash read write edit`）；新增 `license` / `compatibility` / `metadata`；去掉 `keywords`（pi 忽略未知字段） |
| 根目录解析 | `<SSH_SKILL_ROOT>`，兼容 `.codex` / `.claude` 等候选位置 | 改为 `<SKILL_DIR>` = 本 SKILL.md 所在目录，全部使用相对路径 |
| 调用示例 | PowerShell 与 bash 并列 | 以 Linux/macOS `python3` 为主，Windows 细节留给平台参考文档 |
| 新增章节 | — | `Setup`（依赖检查与 paramiko 安装）、`pi Integration Notes`（`/skill:ssh-skill` 强制加载、旧入口迁移说明） |
| 兼容性章节 | Codex / Claude Code 双工具描述 | 替换为 pi 集成说明 |

上游的 `tests/`、`evals/`、`examples/`、`.github/` 属于开发资产，不随 skill 分发；
`scripts/` 与 `references/` 完整保留（含旧脚本兼容入口，供 daemon 等功能使用）。

## 运行时依赖

- Python >= 3.10、OpenSSH 客户端、Paramiko：

```bash
python3 -m pip install --user paramiko
```

## 启用方式（pi，可选，未自动执行）

是否安装到 pi 由你自己决定。若要启用，任选其一：

1. 全局软链到 pi 约定的 skill 目录（本仓库 README 记载的全局自定义 skill 位置）：

   ```bash
   mkdir -p ~/.agents/skills
   ln -s "$(pwd)" ~/.agents/skills/ssh-skill
   ```

2. 或在 `~/.pi/agent/settings.json` 中显式声明路径：

   ```json
   { "skills": ["/home/breeze/OpenProjects/agents-config/pi/skills"] }
   ```

验证：

```bash
python3 scripts/ssh_skill.py doctor --json
```

在 pi 会话中说「连接服务器 / 上传文件到某主机」等即可自动触发，
或用 `/skill:ssh-skill` 强制加载。
