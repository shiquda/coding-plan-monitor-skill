#!/bin/bash
# Codex (ChatGPT Plus) 用量查询模块
# 通过 CLIProxyAPI Management API 透传，自动发现所有 Codex 账号并取平均值
# Verbose 模式：VERBOSE=1 会输出每个账号的独立用量

set -e

# 加载环境变量
if [ -f "$(dirname "$0")/../.env" ]; then
    source "$(dirname "$0")/../.env"
fi

# 配置
CLI_PROXY_URL="${CODEX_CLI_PROXY_URL:-${CLI_PROXY_URL}}"
MANAGEMENT_KEY="${CODEX_MANAGEMENT_KEY:-${CLI_PROXY_MANAGEMENT_KEY}}"
VERBOSE="${VERBOSE:-0}"

# 调用 API 的函数（带 3 次重试）
api_call() {
    local auth_index="$1"
    local account_id="$2"
    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        response=$(curl -s -X POST "${CLI_PROXY_URL}/v0/management/api-call" \
            -H "Authorization: Bearer ${MANAGEMENT_KEY}" \
            -H "Content-Type: application/json" \
            --data-raw "$(printf '{"authIndex":"%s","method":"GET","url":"https://chatgpt.com/backend-api/wham/usage","header":{"Authorization":"Bearer $TOKEN$","Content-Type":"application/json","User-Agent":"codex_cli_rs/0.76.0","Chatgpt-Account-Id":"%s"}}' "$auth_index" "$account_id")" 2>/dev/null)

        # 检查是否成功（无 error 字段）
        if [ -n "$response" ] && ! echo "$response" | jq -e '.error' > /dev/null 2>&1; then
            echo "$response"
            return 0
        fi

        if [ $attempt -lt $max_attempts ]; then
            sleep 2
        fi
        attempt=$((attempt + 1))
    done

    # 全部重试失败后返回错误
    echo '{"error":true}'
    return 1
}

# 获取所有 Codex 账号列表
auth_files_response=$(curl -s "${CLI_PROXY_URL}/v0/management/auth-files" \
    -H "Authorization: Bearer ${MANAGEMENT_KEY}" \
    -H "Accept: application/json")

if [ -z "$auth_files_response" ] || echo "$auth_files_response" | jq -e '.error' > /dev/null 2>&1; then
    echo "Codex|N/A|N/A|N/A|N/A|N/A|❌ CLIProxyAPI 不可达"
    exit 1
fi

# 检查 jq 是否可用
if ! command -v jq &> /dev/null; then
    echo "Codex|N/A|N/A|N/A|N/A|N/A|❌ 需要安装 jq"
    exit 1
fi

# 提取 codex 账号（排除已禁用的）
codex_count=$(echo "$auth_files_response" | jq '.files | map(select(.provider == "codex" and (.disabled != true))) | length' 2>/dev/null || echo "0")
if [ "$codex_count" -eq 0 ]; then
    echo "Codex|N/A|N/A|N/A|N/A|N/A|❌ 未找到 Codex 账号"
    exit 1
fi

# 汇总变量
total_5h_pct=0
total_7d_pct=0
account_count=0
# 重置时间：取最早（最小值）
min_reset_5h=999999999
min_reset_7d=999999999

# 存储每个账号信息用于 verbose 输出
declare -a account_labels
declare -a account_7d_pcts
declare -a account_5h_pcts
declare -a account_7d_lefts
declare -a account_5h_lefts
declare -a account_reset_7ds
declare -a account_reset_5hs
declare -a account_plans

# 遍历每个账号查询用量
while read -r record; do
    auth_index=$(echo "$record" | jq -r '.auth_index')
    account_id=$(echo "$record" | jq -r '.id_token.chatgpt_account_id')
    account_plan=$(echo "$record" | jq -r '.id_token.plan_type // "free"')
    account_label=$(echo "$record" | jq -r '.label // .email // .account // "unknown"')

    [ -z "$auth_index" ] || [ -z "$account_id" ] && continue

    response=$(api_call "$auth_index" "$account_id")

    # api-call 返回的 body 是 JSON 字符串，需二次解析
    body=$(echo "$response" | jq -r '.body // empty' 2>/dev/null)

    # 重试后仍失败则跳过该账号
    if [ -z "$body" ] || [ "$body" = "null" ]; then
        continue
    fi

    # 账号间加间隔，避免并发瞬时过高
    sleep 1

    primary_pct=$(echo "$body" | jq -r '.rate_limit.primary_window.used_percent // 0')
    secondary_pct=$(echo "$body" | jq -r '.rate_limit.secondary_window.used_percent // 0')
    reset_5h=$(echo "$body" | jq -r '.rate_limit.primary_window.reset_after_seconds // 0')
    reset_7d=$(echo "$body" | jq -r '.rate_limit.secondary_window.reset_after_seconds // 0')

    if [ "$primary_pct" != "null" ] && [ -n "$primary_pct" ]; then
        total_5h_pct=$((total_5h_pct + primary_pct))
        total_7d_pct=$((total_7d_pct + secondary_pct))
        account_count=$((account_count + 1))
        # 重置时间取最早（最小值）
        [ "$reset_5h" -lt "$min_reset_5h" ] && min_reset_5h=$reset_5h
        [ "$reset_7d" -lt "$min_reset_7d" ] && min_reset_7d=$reset_7d

        # Verbose 模式保存数据
        if [ "$VERBOSE" = "1" ]; then
            account_labels+=("$account_label")
            account_plans+=("$account_plan")
            account_7d_pcts+=("$secondary_pct")
            account_5h_pcts+=("$primary_pct")
            account_7d_lefts+=("$((100 - secondary_pct))")
            account_5h_lefts+=("$((100 - primary_pct))")
            account_reset_7ds+=("$reset_7d")
            account_reset_5hs+=("$reset_5h")
        fi
    fi
done <<< "$(echo "$auth_files_response" | jq -c '.files[] | select(.provider=="codex" and (.disabled != true))' 2>/dev/null)"

if [ "$account_count" -eq 0 ]; then
    echo "Codex|N/A|N/A|N/A|N/A|N/A|❌ 查询失败"
    exit 1
fi

# 计算平均值（整数）
avg_5h_pct=$((total_5h_pct / account_count))
avg_7d_pct=$((total_7d_pct / account_count))
avg_reset_5h=$min_reset_5h
avg_reset_7d=$min_reset_7d

# 计算剩余量
p5h_left=$((100 - avg_5h_pct))
p7d_left=$((100 - avg_7d_pct))

# 格式化时间
format_duration() {
    local seconds=$1
    if [ "$seconds" -le 0 ]; then
        printf "%s" "即将刷新"
        return
    fi
    local days=$((seconds / 86400))
    local hours=$(((seconds % 86400) / 3600))
    local mins=$(((seconds % 3600) / 60))

    if [ "$days" -gt 0 ]; then
        printf "%s" "${days}d ${hours}h 后刷新"
    elif [ "$hours" -gt 0 ]; then
        printf "%s" "${hours}h ${mins}m 后刷新"
    else
        printf "%s" "${mins}m 后刷新"
    fi
}

RESET_5H=$(format_duration $avg_reset_5h)
RESET_7D=$(format_duration $avg_reset_7d)

# 状态判断（取两个窗口中较严重的）
max_pct=$([ "$avg_5h_pct" -gt "$avg_7d_pct" ] && echo "$avg_5h_pct" || echo "$avg_7d_pct")
if [ "$max_pct" -lt 60 ]; then
    STATUS="✅"
elif [ "$max_pct" -lt 85 ]; then
    STATUS="⚠️"
else
    STATUS="🔴"
fi

# Verbose 模式：先输出每个账号的详情（含进度条）
if [ "$VERBOSE" = "1" ] && [ "$account_count" -gt 0 ]; then
    for i in $(seq 0 $((account_count - 1))); do
        label="${account_labels[$i]}"
        plan="${account_plans[$i]}"
        p7d="${account_7d_pcts[$i]}"
        p5h="${account_5h_pcts[$i]}"
        r7d="${account_reset_7ds[$i]}"
        r5h="${account_reset_5hs[$i]}"

        RESET_7D_ACC=$(format_duration $r7d | tr -d '\r')
        RESET_5H_ACC=$(format_duration $r5h | tr -d '\r')

        max_acc=$([ "$p5h" -gt "$p7d" ] && echo "$p5h" || echo "$p7d")
        if [ "$max_acc" -lt 60 ]; then
            STA="✅"
        elif [ "$max_acc" -lt 85 ]; then
            STA="⚠️"
        else
            STA="🔴"
        fi

        # 生成进度条
        bar_7d_filled=$((p7d / 10))
        [ $bar_7d_filled -gt 10 ] && bar_7d_filled=10
        bar_7d_empty=$((10 - bar_7d_filled))
        bar_7d=""
        for b in $(seq 1 $bar_7d_filled); do bar_7d="${bar_7d}█"; done
        for b in $(seq 1 $bar_7d_empty); do bar_7d="${bar_7d}░"; done

        bar_5h_filled=$((p5h / 10))
        [ $bar_5h_filled -gt 10 ] && bar_5h_filled=10
        bar_5h_empty=$((10 - bar_5h_filled))
        bar_5h=""
        for b in $(seq 1 $bar_5h_filled); do bar_5h="${bar_5h}█"; done
        for b in $(seq 1 $bar_5h_empty); do bar_5h="${bar_5h}░"; done

        echo "[$STA] $label ($plan)"
        echo "    7d ${bar_7d} ${p7d}% → 剩余 $((100 - p7d)) | ${RESET_7D_ACC}"
        echo "    5h ${bar_5h} ${p5h}% → 剩余 $((100 - p5h)) | ${RESET_5H_ACC}"
    done
    echo "---"
fi

# 输出统一格式（综合所有账号的平均值）
echo "Codex-7d|${avg_7d_pct}|100|${avg_7d_pct}%|${p7d_left}|${RESET_7D}|${STATUS}"
echo "Codex-5h|${avg_5h_pct}|100|${avg_5h_pct}%|${p5h_left}|${RESET_5H}|${STATUS}"
