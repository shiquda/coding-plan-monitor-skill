#!/bin/bash
# 统一查询所有 Coding Plan 平台用量 (带进度条)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROVIDERS_DIR="$SCRIPT_DIR/../providers"

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

echo "📊 Coding Plan 用量汇总 ($(date +%Y-%m-%d))"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 遍历所有 provider 脚本
for provider in "$PROVIDERS_DIR"/*.sh; do
    if [ -f "$provider" ] && [ -x "$provider" ]; then
        # 获取所有输出行
        RESULTS=$("$provider" 2>&1 || echo "ERROR|N/A|N/A|N/A|N/A|N/A|❌ 执行失败")
        
        # 处理每一行输出
        while IFS='|' read -r NAME USED TOTAL PERCENT REMAINING RESET STATUS; do
            # 跳过空行
            [ -z "$NAME" ] && continue
            
            # 提取数字百分比
            PERCENT_NUM=$(echo "$PERCENT" | tr -d '%')
            
            # 生成进度条
            BAR=$(generate_progress_bar $PERCENT_NUM)
            
            printf "%s %s %s\n" "$STATUS" "$NAME" "$BAR"
            printf "   📈 %s/%s (%s) | 💰 剩余 %s | %s\n" \
                "$USED" "$TOTAL" "$PERCENT" "$REMAINING" "$RESET"
            echo ""
        done <<< "$RESULTS"
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
