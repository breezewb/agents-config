#!/bin/bash
# Antigravity CLI Custom Status Line
DATA=$(cat)
[ -z "$DATA" ] && exit 0

# 调试记录：自动转存实际收到的 JSON payload
#echo "$DATA" > /tmp/antigravity_statusline_payload.json 2>/dev/null

# 1. 快速提取全部字段（精准匹配 Antigravity CLI 的真实字段层级）
eval "$(echo "$DATA" | jq -r '
  @sh "EXEC_MODE=\(.execution_mode // .mode // "")",
  @sh "AGENT_STATE=\(.agent_state // .state // "")",
  @sh "CWD=\(.cwd // "")",
  @sh "RAW_MODEL=\(.model.display_name // .model.id // "Unknown")",
  @sh "EFFORT=\(.model.effort // .model.reasoning_effort // .model.thinking_effort // .model.thinking_level // .reasoning_effort // .thinking_effort // "")",
  @sh "IN_TOKENS=\(.context_window.total_input_tokens // .tokens.total_input_tokens // .usage.prompt_tokens // 0)",
  @sh "OUT_TOKENS=\(.context_window.total_output_tokens // .tokens.total_output_tokens // .usage.completion_tokens // 0)",
  @sh "CURR_INPUT=\(.context_window.current_usage.input_tokens // 0)",
  @sh "CACHE_READ=\(.context_window.current_usage.cache_read_input_tokens // .context_window.cache_read_tokens // .context_window.cache_read_input_tokens // .context_window.cached_tokens // 0)",
  @sh "CACHE_PCT=\(.context_window.cache_hit_percentage // .context_window.cache_hit_rate // "")",
  @sh "USAGE=\(.context_window.used_percentage // 0)",
  @sh "WINDOW_SIZE=\(.context_window.context_window_size // .context_window.max_tokens // 0)"
')"

# 24-bit TrueColor 精准配色（One Dark 色系）
C_CYAN="\033[38;2;86;182;194m"     # #56b6c2（模型青色 / Tokens 青色）
C_YELLOW="\033[38;2;229;192;123m"  # #e5c07b（模式/中等思考暖黄）
C_GREEN="\033[38;2;152;195;121m"   # #98c379（目录柔和绿）
C_BLUE="\033[38;2;97;175;239m"     # #61afef（Git 天蓝色）
C_PURPLE="\033[38;2;198;120;221m"  # #c678dd（上下文紫色）
C_ORANGE="\033[38;2;240;130;60m"   # #f0823c（高思考强度暖橙色）
C_GRAY="\033[38;2;92;99;112m"      # #5c6370（分隔符暗灰）
C_RED="\033[38;2;224;108;117m"     # #e06c75（冲突/修改告警红）
C_RESET="\033[0m"

# 数字格式化函数（单位 k / M）
fmt_tok() {
  local n="${1:-0}"
  if [ "$n" -ge 1000000 ]; then
    awk "BEGIN {printf \"%.1fM\", $n/1000000}"
  elif [ "$n" -ge 10000 ]; then
    awk "BEGIN {printf \"%.0fk\", $n/1000}"
  elif [ "$n" -ge 1000 ]; then
    awk "BEGIN {printf \"%.1fk\", $n/1000}"
  else
    echo "$n"
  fi
}

PARTS=()

# 1. 左侧开头：执行模式与 Agent 状态（如 💤 local · idle 或 💤 idle）
if [ -n "$EXEC_MODE" ] || [ -n "$AGENT_STATE" ]; then
  STATE_ICON="⚡"
  STATE_COLOR="$C_CYAN"
  case "$AGENT_STATE" in
    idle)                  STATE_ICON="💤"; STATE_COLOR="$C_GRAY" ;;
    thinking)              STATE_ICON="🤔"; STATE_COLOR="$C_ORANGE" ;;
    running|working)       STATE_ICON="⚡"; STATE_COLOR="$C_CYAN" ;;
    tool_calling|tool_use) STATE_ICON="🛠️"; STATE_COLOR="$C_YELLOW" ;;
    waiting_for_input)     STATE_ICON="⏳"; STATE_COLOR="$C_YELLOW" ;;
  esac

  if [ -n "$EXEC_MODE" ] && [ -n "$AGENT_STATE" ]; then
    PARTS+=("${STATE_ICON} ${C_YELLOW}${EXEC_MODE}${C_RESET} ${C_GRAY}·${C_RESET} ${STATE_COLOR}${AGENT_STATE}${C_RESET}")
  elif [ -n "$EXEC_MODE" ]; then
    PARTS+=("${STATE_ICON} ${C_YELLOW}${EXEC_MODE}${C_RESET}")
  elif [ -n "$AGENT_STATE" ]; then
    PARTS+=("${STATE_ICON} ${STATE_COLOR}${AGENT_STATE}${C_RESET}")
  fi
fi

# 2. 当前工作目录：📁 ~/Projects/edr-server
if [ -z "$CWD" ]; then
  CWD="$PWD"
fi
DISPLAY_CWD="${CWD/#$HOME/\~}"
PARTS+=("📁 ${C_GREEN}${DISPLAY_CWD}${C_RESET}")

# 3. Git 版本控制：🌿 v1.8-yd ✓（支持 clean ✓ / dirty ● / conflict ⚠ / remote ↑n ↓n）
if [ -d "$CWD" ] && git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  GIT_STATUS_OUT=$(git -C "$CWD" status --porcelain=v1 -b 2>/dev/null)
  if [ -n "$GIT_STATUS_OUT" ]; then
    FIRST_LINE=$(echo "$GIT_STATUS_OUT" | head -n 1)
    BRANCH_PART="${FIRST_LINE#\#\# }"
    BRANCH="${BRANCH_PART%%...*}"
    BRANCH="${BRANCH%% *}"

    # 解析领先/落后 commit 数量 (ahead / behind)
    AHEAD=0
    BEHIND=0
    if [[ "$FIRST_LINE" =~ ahead[[:space:]]+([0-9]+) ]]; then
      AHEAD="${BASH_REMATCH[1]}"
    fi
    if [[ "$FIRST_LINE" =~ behind[[:space:]]+([0-9]+) ]]; then
      BEHIND="${BASH_REMATCH[1]}"
    fi

    # 检查冲突、未暂存/暂存修改、未跟踪文件
    HAS_CONFLICT=0
    HAS_MODIFIED=0
    HAS_UNTRACKED=0

    while IFS= read -r line; do
      [ -z "$line" ] && continue
      xy="${line:0:2}"
      if [[ "$xy" =~ ^(UU|AA|DD|AU|UA|DU|UD)$ ]]; then
        HAS_CONFLICT=1
      elif [ "$xy" = "??" ]; then
        HAS_UNTRACKED=1
      else
        HAS_MODIFIED=1
      fi
    done < <(echo "$GIT_STATUS_OUT" | tail -n +2)

    # 状态指示：冲突 ⚠、修改 ●（红）、未跟踪 ●（黄）、干净 ✓（绿）
    if [ "$HAS_CONFLICT" -eq 1 ]; then
      ST_ICON="⚠"
      ST_COLOR="$C_RED"
    elif [ "$HAS_MODIFIED" -eq 1 ]; then
      ST_ICON="●"
      ST_COLOR="$C_RED"
    elif [ "$HAS_UNTRACKED" -eq 1 ]; then
      ST_ICON="●"
      ST_COLOR="$C_YELLOW"
    else
      ST_ICON="✓"
      ST_COLOR="$C_GREEN"
    fi

    REMOTE_INFO=""
    if [ "$AHEAD" -gt 0 ]; then
      REMOTE_INFO="${REMOTE_INFO} ↑${AHEAD}"
    fi
    if [ "$BEHIND" -gt 0 ]; then
      REMOTE_INFO="${REMOTE_INFO} ↓${BEHIND}"
    fi

    PARTS+=("🌿 ${C_BLUE}${BRANCH}${C_RESET} ${ST_COLOR}${ST_ICON}${C_RESET}${C_BLUE}${REMOTE_INFO}${C_RESET}")
  fi
fi

# 4. 模型与思考等级：🤖 Gemini 3.8 Flash · high
if [[ "$RAW_MODEL" =~ ^(.*)[[:space:]]*\((High|Medium|Low|None|[0-9]+k?)\)$ ]]; then
  MODEL_NAME="$(echo "${BASH_REMATCH[1]}" | sed 's/[[:space:]]*$//')"
  [ -z "$EFFORT" ] && EFFORT="${BASH_REMATCH[2]}"
else
  MODEL_NAME="$RAW_MODEL"
fi

EFFORT_LOWER=$(echo "$EFFORT" | tr "[:upper:]" "[:lower:]")
case "$EFFORT_LOWER" in
  max|extreme) EFFORT_COLOR="$C_RED" ;;      # 极高：强红色
  high)        EFFORT_COLOR="$C_ORANGE" ;;   # 高：暖橙色（与上下文紫色区分）
  medium)      EFFORT_COLOR="$C_YELLOW" ;;   # 中：亮黄色
  low)         EFFORT_COLOR="$C_CYAN" ;;     # 低：青色
  *)           EFFORT_COLOR="$C_GRAY" ;;     # 默认暗灰
esac

if [ -n "$EFFORT_LOWER" ] && [ "$EFFORT_LOWER" != "none" ]; then
  PARTS+=("🤖 ${C_CYAN}${MODEL_NAME}${C_RESET} ${C_GRAY}·${C_RESET} ${EFFORT_COLOR}${EFFORT_LOWER}${C_RESET}")
else
  PARTS+=("🤖 ${C_CYAN}${MODEL_NAME}${C_RESET}")
fi

# 5. 上下文使用量：🧠 19% 314k/1.0M
TOTAL_TOKENS=$((IN_TOKENS + OUT_TOKENS))
USED_FMT=$(fmt_tok "$TOTAL_TOKENS")

if [ -z "$WINDOW_SIZE" ] || [ "$WINDOW_SIZE" -eq 0 ]; then
  if (( $(awk "BEGIN {print ($USAGE > 0)}") )); then
    WINDOW_SIZE=$(awk "BEGIN {printf \"%.0f\", ($TOTAL_TOKENS * 100) / $USAGE}")
  fi
fi

if [ -n "$WINDOW_SIZE" ] && [ "$WINDOW_SIZE" -ge 1000000 ]; then
  MAX_FMT="$(awk "BEGIN {val=$WINDOW_SIZE/1000000; if (val >= 10) printf \"%.0fM\", val; else printf \"%.1fM\", val}")"
elif [ -n "$WINDOW_SIZE" ] && [ "$WINDOW_SIZE" -ge 1000 ]; then
  MAX_FMT="$(awk "BEGIN {printf \"%.0fk\", $WINDOW_SIZE/1000}")"
else
  MAX_FMT="1.0M"
fi

USAGE_PCT="$(awk "BEGIN {printf \"%.0f\", $USAGE}")"
CTX_COLOR="$C_PURPLE"
if [ "$USAGE_PCT" -ge 90 ]; then
  CTX_COLOR="$C_RED"
fi

PARTS+=("🧠 ${CTX_COLOR}${USAGE_PCT}% ${USED_FMT}/${MAX_FMT}${C_RESET}")

# 6. 右侧末尾：输入输出 Token 与缓存百分比（如 📊 ↑202k ↓112k 🎯98.5%）
IN_FMT=$(fmt_tok "$IN_TOKENS")
OUT_FMT=$(fmt_tok "$OUT_TOKENS")

if [ -z "$CACHE_PCT" ]; then
  # 优先按照当前轮次的缓存读取比例计算：cache_read / (cache_read + current_input)
  CURR_TOTAL=$((CACHE_READ + CURR_INPUT))
  if [ "$CURR_TOTAL" -gt 0 ] && [ "$CACHE_READ" -gt 0 ]; then
    CACHE_PCT=$(awk "BEGIN {printf \"%.1f\", ($CACHE_READ * 100) / $CURR_TOTAL}")
  elif [ "$IN_TOKENS" -gt 0 ] && [ "$CACHE_READ" -gt 0 ]; then
    CACHE_PCT=$(awk "BEGIN {printf \"%.1f\", ($CACHE_READ * 100) / $IN_TOKENS}")
  else
    CACHE_PCT="0.0"
  fi
else
  CACHE_PCT=$(awk "BEGIN {printf \"%.1f\", $CACHE_PCT}")
fi

PARTS+=("📊 ${C_CYAN}↑${IN_FMT} ↓${OUT_FMT} 🎯${CACHE_PCT}%${C_RESET}")

# 7. 组装输出（细腻竖线分隔）
SEP=" ${C_GRAY}│${C_RESET} "
OUTPUT=""
for PART in "${PARTS[@]}"; do
  if [ -z "$OUTPUT" ]; then
    OUTPUT="$PART"
  else
    OUTPUT="${OUTPUT}${SEP}${PART}"
  fi
done

echo -e "$OUTPUT"
