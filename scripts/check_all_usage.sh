#!/bin/bash
# 统一查询所有 Coding Plan 平台用量 (带进度条)
# - 不同 provider 并行获取，大幅降低总等待时间
# - 单个 provider 内部顺序执行，账号间有间隔
#
# 用法:
#   ./check_all_usage.sh          # 默认，简洁输出
#   ./check_all_usage.sh -v       # Verbose 模式，显示每个账号详情
#   ./check_all_usage.sh --verbose

VERBOSE=${VERBOSE:-0}
if [ "$1" = "-v" ] || [ "$1" = "--verbose" ]; then
    VERBOSE=1
fi

#set -e  # do not use set -e, child process failures should not exit the main script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Resolve to absolute path to handle invocation from different CWDs (e.g. bash ./scripts/check_all_usage.sh)
if [ "$(dirname "$SCRIPT_DIR")" = "." ] || [[ "$SCRIPT_DIR" == ./* ]]; then
    SCRIPT_DIR="$(pwd)/$(basename "$SCRIPT_DIR")"
fi
PROVIDERS_DIR="$SCRIPT_DIR"

# 生成进度条 (10个格子)
generate_progress_bar() {
    local percent=$1
    local filled=$((percent / 10))
    if [ $filled -gt 10 ]; then filled=10; fi
    local empty=$((10 - filled))

    local bar=""
    for i in $(seq 1 $filled); do bar="${bar}█"; done
    for i in $(seq 1 $empty); do bar="${bar}░"; done
    echo "$bar"
}

# 输出带时间戳的 header
if [ "$VERBOSE" = "1" ]; then
    echo "📊 Coding Plan 用量汇总 - Verbose 模式 ($(date +%Y-%m-%d))"
else
    echo "📊 Coding Plan 用量汇总 ($(date +%Y-%m-%d))"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 收集所有 provider 脚本路径（需要有执行权限）
declare -a PROVIDER_SCRIPTS=()
for provider in "$PROVIDERS_DIR"/*.sh; do
    if [ -f "$provider" ] && [ -x "$provider" ] && [ "$(basename "$provider")" != "check_all_usage.sh" ]; then
        PROVIDER_SCRIPTS+=("$provider")
    fi
done

# 为每个 provider 创建临时文件用于捕获输出
declare -a TEMP_FILES=()
for p in "${PROVIDER_SCRIPTS[@]}"; do
    TEMP_FILES+=("$(mktemp)")
done

# 并行启动所有 provider 脚本（后台运行，结果写入 temp 文件）
for i in "${!PROVIDER_SCRIPTS[@]}"; do
    provider="${PROVIDER_SCRIPTS[$i]}"
    tempfile="${TEMP_FILES[$i]}"
    if [ "$VERBOSE" = "1" ]; then
        env VERBOSE=1 "$provider" > "$tempfile" 2>&1 &
    else
        "$provider" > "$tempfile" 2>&1 &
    fi
done

# 等待所有后台任务完成（带超时保护，防止 codex.sh 响应慢时永久阻塞）
# 使用 polling 而非 wait，避免 SIGPIPE 导致子进程全部退出的问题
TIMEOUT_SECS=40
WAIT_START=$SECONDS
ALL_PIDS=$(jobs -p)
for pid in $ALL_PIDS; do
    while kill -0 "$pid" 2>/dev/null; do
        if [ $(($SECONDS - WAIT_START)) -ge $TIMEOUT_SECS ]; then
            kill "$pid" 2>/dev/null
            wait "$pid" 2>/dev/null || true
            break
        fi
        sleep 0.5
    done
done

# 依次处理每个 provider 的输出
for i in "${!PROVIDER_SCRIPTS[@]}"; do
    tempfile="${TEMP_FILES[$i]}"

    # 读取 provider 输出
    if [ -s "$tempfile" ]; then
        RESULTS=$(cat "$tempfile")
    else
        RESULTS="ERROR|0|0|0%|0|错误|❌"
    fi

    # 清理 temp 文件
    rm -f "$tempfile"

    # 处理每一行输出
    while IFS= read -r line; do
        [ -z "$line" ] && continue

        # 检查是否是带 pipe 的完整记录行（格式：NAME|USED|TOTAL|PERCENT|REMAINING|RESET|STATUS）
        # 统计 pipe 数量，6 个 pipe = 7 个字段 = 完整记录
        pipe_count=$(echo "$line" | grep -o '|' | wc -l)
        if [ "$pipe_count" -ge 6 ]; then
            # 完整 pipe 记录，IFS 分割
            IFS='|' read -r NAME USED TOTAL PERCENT REMAINING RESET STATUS << EOF
$line
EOF
            # 提取数字百分比
            PERCENT_NUM=$(echo "$PERCENT" | sed 's/%//' | tr -d ' ')
            if ! [[ "$PERCENT_NUM" =~ ^[0-9]+$ ]]; then
                continue
            fi

            BAR=$(generate_progress_bar "$PERCENT_NUM")
            printf "%s %s %s\n" "$STATUS" "$NAME" "$BAR"
            printf "   📈 %s/%s (%s) | 💰 剩余 %s | %s\n" \
                "$USED" "$TOTAL" "$PERCENT" "$REMAINING" "$RESET"
            echo ""
        else
            # 非完整记录行（verbose 注释、ERROR 等），原样透传
            echo "$line"
        fi
    done <<< "$RESULTS"
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
