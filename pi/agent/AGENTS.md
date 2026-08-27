# 全局开发配置

## 语言和环境

- **语言**: 所有输出（回复、代码注释和 commit 信息）一律使用简体中文
- **commit 规范**: 使用 Conventional Commits 前缀（feat/fix/docs/chore/refactor/test/perf 等），格式 `type: 描述`
- **操作系统**: Debian 13
- **环境限制**: 系统使用mise管理uv、bun、nodejs、python、java、npm全局包、pipx全局包等

## mise 全局包管理

安装全局包必须走 mise backend，禁止直接用系统 npm/pip：

- **npm 全局包** → `mise use -g npm:<包名>`（如 `mise use -g npm:pnpm`）
- **pip 全局包** → `mise use -g pipx:<包名>`（如 `mise use -g pipx:ruff`；mise 检测到 uv 时会自动改用 uvx，无需预先安装 pipx）
- 升级到最新 → `mise use -g <工具>@latest`（或 `mise upgrade <工具>`）

原因：直接 `npm i -g` / `pip install` 的包装在当前 node/python 版本各自的全局路径下，升级或切换对应运行时后，这些全局包就丢失了。mise backend 把包装到 mise 统一管理的位置，跟随配置保持可用。

## 编码原则（核心哲学）

### 1. 先思考，再编码

- 明确说明假设；有多种解读时，列出选项，不要悄悄选一个
- 遇到更简单的方案，主动说出来；真正不清楚时，**停下来问**

### 2. 简洁优先

- 只实现被要求的功能，不写投机性代码
- 单次使用的代码不做抽象；不要"未来可能用到"的灵活性
- 写了 200 行但 50 行能解决 → 重写

### 3. 外科手术式修改

- 只改必须改的地方；不"顺手优化"无关代码
- 保持现有代码风格，即使你会用不同写法
- 你的改动产生的孤儿代码（无用 import/变量）→ 删掉；原有死代码 → 仅提及，不删除

### 4. 目标驱动执行

将任务转化为可验证的目标：

- "修复 bug" → "写一个能复现它的测试，然后让它通过"
- "重构 X" → "确保重构前后测试都通过"

多步骤任务先列计划：

```text
1. [步骤] → 验证: [检查点]
2. [步骤] → 验证: [检查点]
```

## 命令执行策略

### AI 自动执行（✅ 允许）

- **文件操作**：使用专用工具代替 shell 命令
- **Git 只读**：`git status/log/diff/branch/show/blame`
- **项目外文件**：除读取外的任何操作（写入、删除、移动、重命名等）必须先经用户确认

### 提供给用户执行（bash/zsh 代码块）

需要root权限、交互式操作、长运行进程的命令 → 给出 bash/zsh 代码块，由用户手动执行

### 绝对禁止

- 交互式命令（文本编辑器、交互式安装向导）
- 系统管理命令（需要管理员权限）

## 核心工作流

### 普通功能

规划 → 编码 → code review

### 复杂功能 / 架构变更

生成计划 → 用户确认 → 分阶段实现 → 全面审查

## MCP 工具

当前配置了 MCP 服务器，按需调用。首次使用某服务器时需先 `connect`。
**如果配置了 `代码语义检索/LSP` 之类的MCP，例如 `idea` `serena`，必须使用该类MCP代替原始工具和shell命令**

### 使用方式

- 查看服务器状态：`mcp({})`
- 连接服务器：`mcp({ connect: "server-name" })`
- 搜索工具：`mcp({ search: "keyword" })`
- 查看工具详情：`mcp({ describe: "tool_name" })`
- 调用工具：`mcp({ tool: "tool_name", args: { ... } })`
- 批量调用：用 `mcpScript` 编写 JavaScript 串联多个调用
