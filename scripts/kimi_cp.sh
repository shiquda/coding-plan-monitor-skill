#!/bin/bash
# Kimi Coding Plan 用量查询模块 (双限制版本)

set -e

# 加载环境变量
if [ -f "$(dirname "$0")/../.env" ]; then
    source "$(dirname "$0")/../.env"
fi

# 检查必需的环境变量
if [ -z "$KIMI_BEARER_TOKEN" ]; then
    echo "Kimi Coding Plan-7d|N/A|N/A|N/A|N/A|N/A|❌ 缺少配置"
    echo "Kimi Coding Plan-5h|N/A|N/A|N/A|N/A|N/A|❌ 缺少配置"
    exit 1
fi

# 调用 API
RESPONSE=$(curl -s -X POST 'https://www.kimi.com/apiv2/kimi.gateway.billing.v1.BillingService/GetUsages' \
 -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:147.0) Gecko/20100101 Firefox/147.0' \
 -H 'Content-Type: application/json' \
 -H "authorization: Bearer ${KIMI_BEARER_TOKEN}" \
 -d '{"scope":["FEATURE_CODING"]}')

# 检查 jq
if ! command -v jq &> /dev/null; then
    echo "Kimi Coding Plan-7d|N/A|N/A|N/A|N/A|N/A|❌ 需要安装 jq"
    echo "Kimi Coding Plan-5h|N/A|N/A|N/A|N/A|N/A|❌ 需要安装 jq"
    exit 1
fi

# 检查错误
if echo "$RESPONSE" | jq -e '.code' > /dev/null 2>&1; then
    echo "Kimi Coding Plan-7d|N/A|N/A|N/A|N/A|N/A|❌ Token过期"
    echo "Kimi Coding Plan-5h|N/A|N/A|N/A|N/A|N/A|❌ Token过期"
    exit 1
fi

# === 7天主限制 ===
USED_7D=$(echo "$RESPONSE" | jq -r '.usages[0].detail.used // 0')
TOTAL_7D=$(echo "$RESPONSE" | jq -r '.usages[0].detail.limit // 0')
RESET_7D_RAW=$(echo "$RESPONSE" | jq -r '.usages[0].detail.resetTime // ""')

REMAINING_7D=$((TOTAL_7D - USED_7D))
if [ "$TOTAL_7D" -gt 0 ]; then
    PERCENT_7D=$(awk "BEGIN {printf \"%.0f\", ($USED_7D/$TOTAL_7D)*100}")
else
    PERCENT_7D=0
fi

if [ -n "$RESET_7D_RAW" ] && [ "$RESET_7D_RAW" != "null" ]; then
    RESET_7D=$(TZ=Asia/Shanghai date -d "$RESET_7D_RAW" "+%H:%M" 2>/dev/null || echo "未知")
else
    RESET_7D="未知"
fi

if [ "$PERCENT_7D" -lt 60 ]; then
    STATUS_7D="✅"
elif [ "$PERCENT_7D" -lt 85 ]; then
    STATUS_7D="⚠️"
else
    STATUS_7D="🔴"
fi

# === 5小时速率限制 ===
USED_5H=$((100 - $(echo "$RESPONSE" | jq -r '.usages[0].limits[0].detail.remaining // 0')))
TOTAL_5H=$(echo "$RESPONSE" | jq -r '.usages[0].limits[0].detail.limit // 0')
RESET_5H_RAW=$(echo "$RESPONSE" | jq -r '.usages[0].limits[0].detail.resetTime // ""')

REMAINING_5H=$((TOTAL_5H - USED_5H))
if [ "$TOTAL_5H" -gt 0 ]; then
    PERCENT_5H=$(awk "BEGIN {printf \"%.0f\", ($USED_5H/$TOTAL_5H)*100}")
else
    PERCENT_5H=0
fi

if [ -n "$RESET_5H_RAW" ] && [ "$RESET_5H_RAW" != "null" ]; then
    RESET_5H=$(TZ=Asia/Shanghai date -d "$RESET_5H_RAW" "+%H:%M" 2>/dev/null || echo "未知")
else
    RESET_5H="未知"
fi

if [ "$PERCENT_5H" -lt 60 ]; then
    STATUS_5H="✅"
elif [ "$PERCENT_5H" -lt 85 ]; then
    STATUS_5H="⚠️"
else
    STATUS_5H="🔴"
fi

# 输出两行
echo "Kimi Coding Plan-7d|$USED_7D|$TOTAL_7D|$PERCENT_7D%|$REMAINING_7D|$RESET_7D|$STATUS_7D"
echo "Kimi Coding Plan-5h|$USED_5H|$TOTAL_5H|$PERCENT_5H%|$REMAINING_5H|$RESET_5H|$STATUS_5H"
