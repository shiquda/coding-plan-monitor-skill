#!/bin/bash
# Webshare Proxy 流量用量查询模块

set -e

# 加载环境变量
if [ -f "$(dirname "$0")/../.env" ]; then
    source "$(dirname "$0")/../.env"
fi

# 检查必需的环境变量
if [ -z "$WEBSHARE_API_KEY" ]; then
    echo "Webshare|N/A|N/A|N/A|N/A|N/A|❌ 缺少配置"
    exit 1
fi

# 需要 jq
if ! command -v jq &> /dev/null; then
    echo "Webshare|N/A|N/A|N/A|N/A|N/A|❌ 需要安装 jq"
    exit 1
fi

AUTH_HEADER="Authorization: Token ${WEBSHARE_API_KEY}"

# 1. 获取订阅计划信息（bandwidth_limit，单位 GB）
PLAN_RESPONSE=$(curl -s -X GET \
    "https://proxy.webshare.io/api/v2/subscription/plan/" \
    -H "$AUTH_HEADER" 2>/dev/null || echo '{"results":[]}')

BANDWIDTH_LIMIT_GB=$(echo "$PLAN_RESPONSE" | jq -r '.results[0].bandwidth_limit // 0' 2>/dev/null || echo "0")
PROXY_TYPE=$(echo "$PLAN_RESPONSE" | jq -r '.results[0].proxy_type // "Unknown"' 2>/dev/null || echo "Unknown")
PROXY_SUBTYPE=$(echo "$PLAN_RESPONSE" | jq -r '.results[0].proxy_subtype // ""' 2>/dev/null || echo "")
PLAN_NAME="${PROXY_TYPE} ${PROXY_SUBTYPE}"

# 2. 获取当前订阅期的流量统计（bandwidth_total 单位 bytes）
STATS_RESPONSE=$(curl -s -X GET \
    "https://proxy.webshare.io/api/v2/stats/aggregate/" \
    -H "$AUTH_HEADER" 2>/dev/null || echo '{}')

BANDWIDTH_USED_BYTES=$(echo "$STATS_RESPONSE" | jq -r '.bandwidth_total // 0' 2>/dev/null || echo "0")

# 3. 格式化 bytes 为人类可读
bytes_to_human() {
    local bytes=${1:-0}
    awk -v b="$bytes" 'BEGIN {
        if (b >= 1073741824) printf "%.2f GB", b/1073741824
        else if (b >= 1048576) printf "%.1f MB", b/1048576
        else if (b >= 1024) printf "%.0f KB", b/1024
        else printf "%d B", b
    }'
}

USED_HUMAN=$(bytes_to_human "$BANDWIDTH_USED_BYTES")

# 4. 计算用量百分比
if [ "$BANDWIDTH_LIMIT_GB" = "0" ] || [ "$BANDWIDTH_LIMIT_GB" = "null" ] || [ -z "$BANDWIDTH_LIMIT_GB" ]; then
    TOTAL_HUMAN="无限"
    PERCENT=0
    REMAINING="无限制"
else
    BANDWIDTH_LIMIT_BYTES=$(awk -v gb="$BANDWIDTH_LIMIT_GB" 'BEGIN {printf "%.0f", gb * 1073741824}')
    TOTAL_HUMAN="${BANDWIDTH_LIMIT_GB} GB"
    REMAINING_BYTES=$((BANDWIDTH_LIMIT_BYTES - BANDWIDTH_USED_BYTES))
    [ "$REMAINING_BYTES" -lt 0 ] 2>/dev/null && REMAINING_BYTES=0
    REMAINING=$(bytes_to_human "$REMAINING_BYTES")
    PERCENT=$(awk -v used="$BANDWIDTH_USED_BYTES" -v limit="$BANDWIDTH_LIMIT_BYTES" 'BEGIN {p=used/limit*100; if(p>100) p=100; printf "%.0f", p}')
fi
RESET_TIME="$PLAN_NAME"

# 5. 状态判断
if [ "$PERCENT" -lt 60 ]; then
    STATUS="✅"
elif [ "$PERCENT" -lt 85 ]; then
    STATUS="⚠️"
else
    STATUS="🔴"
fi

echo "Webshare|$USED_HUMAN|$TOTAL_HUMAN|$PERCENT%|$REMAINING|$RESET_TIME|$STATUS"
