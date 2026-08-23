# Pi Coding Agent 配置
### 配置文件位置

| 文件 | 作用 |
| --- | --- |
| `~/.pi/agent/settings.json` | 全局设置：packages 列表、主题、默认模型等 |
| `~/.pi/agent/tools.json` | 工具开关：哪些工具 active / inactive |
| `~/.pi/agent/models.json` | provider 和模型定义 |
| `~/.pi/agent/extensions/*.ts` | 全局自定义扩展（auto-discover，支持 `/reload`） |
| `~/.agents/skills/` | 全局自定义 skill |
| `~/.config/mcp/mcp.json` | MCP server 配置 |
| `.pi/settings.json` | 项目级设置（可跟团队共享） |
| `.pi/extensions/` | 项目级扩展 |

---

### 🤖 代理编排与工作流

#### `pi-subagents`

子代理委派框架。让主代理可以把任务派给子代理，支持五种工作模式：

- **single**：单个子代理独立完成一个任务
- **chain**：多个子代理串成流水线，前一个的输出喂给后一个
- **parallel**：多个子代理并行跑同一类任务
- **async**：后台异步执行，完成后通知
- **forked-context**：从父会话 fork 出独立上下文

适合做「先让一个代理研究、再让另一个代理实现、最后让第三个代理 review」这种复杂流程。配带一个 `pi-subagents` skill 教模型怎么编排。

- 📦 仓库：<https://github.com/nicobailon/pi-subagents>

#### `@narumitw/pi-goal`

目标驱动模式。用 `/goal` 设一个目标，Pi 会自主推进直到完成，中途遇到阻塞会主动停下来等你。适合那种「给我做完这个 feature」的长任务。

- 📦 仓库：<https://github.com/narumiruna/pi-extensions>

#### `@narumitw/pi-plan-mode`

只读的计划模式（类似 Codex 的 read-only collaboration）。让模型先出方案、跟你讨论清楚，再进入执行。避免一上来就乱改文件。

- 📦 仓库：<https://github.com/narumiruna/pi-extensions>

### 🔍 代码智能与上下文管理

#### `pi-lens`

Pi 的「IDE 眼睛」。给 Pi 加上 AST 级别的代码理解能力：

- 基于 **ast-grep** 的结构化搜索 / 替换（比纯文本 grep 精准）
- 基于 **tree-sitter** 的语法规则检查
- **LSP 诊断**：跑构建前主动查类型错误
- 符号搜索、模块报告、读符号体等「廉价读代码」工具

配套 4 个 skill：`pi-lens-ast-grep`、`pi-lens-lsp-navigation`、`pi-lens-write-ast-grep-rule`、`pi-lens-write-tree-sitter-rule`（教你写自定义规则）。

- 📦 仓库：<https://github.com/apmantza/pi-lens>

#### `context-mode`

省 token 的核心插件。把大输出（日志、构建结果、网页内容、git diff 等）路由进一个沙箱，用代码处理，只把摘要返回给模型。内置一个 **FTS5 全文检索知识库**，可以索引文档、网页、历史会话，之后按需检索。

效果：分析 47 个源文件，直接 read 要烧 ~700KB 上下文；走 context-mode 只回 ~3.6KB。配套 8 个 skill（ctx-search / ctx-index / ctx-stats / ctx-purge / ctx-insight / ctx-doctor / ctx-upgrade / context-mode 本体）。

- 📦 仓库：<https://github.com/mksglu/context-mode>

#### `pi-hermes-memory`

跨会话记忆。让 Pi 记住你之前告诉过它的事（你的偏好、项目约定、之前踩过的坑），下次开新会话还能用上。记忆分 user / memory / project / failure 四类，可搜索。默认基于策略的 token 感知记忆，带 SQLite FTS5 检索 + 自动合并。

- 📦 仓库：<https://github.com/chandra447/pi-hermes-memory>

### 🌐 浏览、检索与外部接入

#### `pi-web-access`

Web 访问全家桶：

- **web_search**：多引擎网页搜索（OpenAI / Brave / Exa / Tavily / Perplexity / Gemini）
- **fetch_content**：抓 URL 内容转 markdown，支持 YouTube 转录、GitHub 仓库克隆、PDF 提取、本地视频抽帧
- 配带 `librarian` skill：带 GitHub 永链的库研究，适合深挖某个开源库的内部实现
- 📦 仓库：<https://github.com/nicobailon/pi-web-access>

#### `pi-playwright`

Playwright 浏览器自动化。让 Pi 能开浏览器、填表单、点按钮、截图、查 console / network。配带 `playwright-browser` skill。适合测 Web 应用、做端到端自动化。

- 📦 仓库：<https://github.com/guwidoe/pi-playwright>

#### `pi-mcp-adapter`

MCP（Model Context Protocol）适配器。让 Pi 能连接任何 MCP server，把它的工具接进来。本仓库的 2 个 MCP server 就是通过它生效的。支持 OAuth、安全审查、按需懒启动。

- 📦 仓库：<https://github.com/nicobailon/pi-mcp-adapter>

#### `pi-marketplace`

Pi 包市场入口。在 Pi 里直接搜索、查看详情、安全审计、安装 npm 上的 pi 包。配套 `marketplace_search` / `marketplace_detail` / `marketplace_audit` / `marketplace_install` 工具。发现新插件很方便。

- 📦 仓库：<https://pi.dev/packages/pi-marketplace>

### ✨ 实用工具与主题

#### `@juicesharp/rpiv-todo`

给模型的 todo list，渲染成实时浮层，**扛得住 `/reload` 和会话压缩**。多步骤任务进度可视化，不容易跑偏。

- 📦 仓库：<https://github.com/juicesharp/rpiv-mono>

#### `@narumitw/pi-statusline`

状态栏增强。替换 Pi 默认 footer，在底部显示模型、上下文占用、git 状态等更丰富的信息，一眼看清当前状态。

- 📦 仓库：<https://github.com/narumiruna/pi-extensions>

#### `@narumitw/pi-github-pr`

在 Pi 里看 GitHub PR 的 review / checks / comment 状态，不用切浏览器。

- 📦 仓库：<https://github.com/narumiruna/pi-extensions>

#### `pi-simplify`

审最近改动的代码，从清晰度、一致性、可维护性角度给建议。改完代码跑一下，把烂味道扫干净。

- 📦 仓库：<https://github.com/MattDevy/pi-extensions>

#### `@firstpick/pi-prompts-git-pr`

一套可复用的 prompt 模板：提交信息、PR 描述、PR review 流程。直接 `/` 唤起对应模板，省得每次手敲。

- 📦 仓库：<https://github.com/Firstp1ck/pi-coding-agent-forge>

#### `@firstpick/pi-skill-deep-research`

带 `deep-research` skill：两阶段严谨研究流程，带 schema / policy 校验。适合需要多源证据、事实核查的高 stakes 研究。

- 📦 仓库：<https://github.com/Firstp1ck/pi-coding-agent-forge>

#### `@victor-software-house/pi-curated-themes`

精选暗色终端主题集（从 iTerm2-Color-Schemes 迁移）

- 📦 仓库：<https://github.com/victor-software-house/pi-curated-themes>

#### `pi-cometix-footer`

pi底部状态栏

- 📦 仓库：<https://github.com/Xichun123/pi-cometix-footer>

---

## 七、全局 Skill 清单（18 个）

所有 skill 都是全局的——装了包就处处可用，跟当前在哪个项目无关。

| 类别 | Skill | 来源包 |
| --- | --- | --- |
| 研究/浏览 | `librarian`、`deep-research`、`chrome-devtools` | pi-web-access / @firstpick / 自定义 |
| 浏览器 | `playwright-browser` | pi-playwright |
| 上下文/知识库 | `context-mode`、`ctx-search`、`ctx-index`、`ctx-stats`、`ctx-purge`、`ctx-insight`、`ctx-doctor`、`ctx-upgrade` | context-mode |
| 代码智能 | `pi-lens-ast-grep`、`pi-lens-lsp-navigation`、`pi-lens-write-ast-grep-rule`、`pi-lens-write-tree-sitter-rule` | pi-lens |
| 代理编排 | `pi-subagents` | pi-subagents |
| 主题 | `adapt-ghostty-theme-to-pi` | @victor-software-house |

> 其中 `chrome-devtools` 是我放在 `~/.agents/skills/` 的自定义全局 skill，不在任何 npm 包里，需要自己创建（参考第二节「写一个 Skill」）。

---

## 八、MCP Server（2 个）

配置在 `mcp.json`，安装脚本会合并到 `~/.config/mcp/mcp.json`。

### `context7`

Upstash 的 Context7 MCP。给模型实时拉取第三方库的**最新文档**，避免它用过时的训练知识写代码。

```json
{
  "command": "npx",
  "args": ["-y", "@upstash/context7-mcp@latest"],
  "lifecycle": "lazy"
}
```

### `chrome-devtools`

Chrome DevTools 远程控制，29 个工具（点击、截图、网络抓包、性能分析等）。配合 `chrome-devtools` skill 调试网页很顺手。

> 这个 server 需要本地装一个 `chrome-devtools-mcp` 二进制，路径在 `mcp.json` 里是写死的，换机器后请改成你自己的路径。

两个都设了 `"lifecycle": "lazy"`——按需启动，不常驻，省资源。

---
