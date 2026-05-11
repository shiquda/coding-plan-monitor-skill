#!/bin/bash
# Xiaomi MiMo Token Plan 用量查询
# 通过平台内部 API（Cookie 认证）查询 Credit 剩余
#
# 配置：将浏览器 Cookie 放入 .xiaomi_cookie 文件

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COOKIE_FILE="$SCRIPT_DIR/../.xiaomi_cookie"

COOKIE=""
if [ -f "$COOKIE_FILE" ]; then
  COOKIE=$(cat "$COOKIE_FILE" | tr -d '\n')
fi

if [ -z "$COOKIE" ]; then
  echo "Xiaomi MiMo | ❌ Cookie 未配置"
  exit 0
fi

resp=$(curl -s 'https://platform.xiaomimimo.com/api/v1/tokenPlan/usage' \
  --compressed \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:149.0) Gecko/20100101 Firefox/149.0' \
  -H 'Accept: */*' \
  -H 'Accept-Language: zh' \
  -H 'Referer: https://platform.xiaomimimo.com/console/plan-manage' \
  -H 'x-timeZone: Asia/Shanghai' \
  -H 'Content-Type: application/json' \
  -H "Cookie: $COOKIE" \
  --max-time 10 2>/dev/null)

# Cookie 过期
echo "$resp" | grep -q "loginUrl" && {
  echo "Xiaomi MiMo | ⚠️ Cookie 已过期"
  exit 0
}

echo "$resp" | grep -q '"code":0' || {
  echo "Xiaomi MiMo | ⚠️ 查询失败"
  exit 0
}

if command -v python3 &>/dev/null; then
  echo "$resp" | python3 -c "
import json, sys

d = json.load(sys.stdin)
data = d.get('data', {})

# 取 plan_total_token（实际套餐用量）
usage = data.get('usage', {})
items = usage.get('items', [])

plan = None
for item in items:
    if item.get('name') == 'plan_total_token':
        plan = item
        break

if not plan:
    print('Xiaomi MiMo | ✅ 已连接 | 无套餐数据')
    sys.exit(0)

used = plan.get('used', 0)
limit = plan.get('limit', 0)
pct = plan.get('percent', 0) * 100

if limit > 0:
    remaining = limit - used
    if pct >= 95:
        status = '\U0001f534'
    elif pct >= 85:
        status = '\u26a0\ufe0f'
    else:
        status = '\u2705'
    bar_filled = int(pct / 10)
    bar_empty = 10 - bar_filled
    bar = '\u2588' * bar_filled + '\u2591' * bar_empty

    def fmt(n):
        if n >= 1000000000:
            return f'{n/1000000000:.1f}B'
        elif n >= 1000000:
            return f'{n/1000000:.1f}M'
        elif n >= 1000:
            return f'{n/1000:.1f}K'
        return str(n)

    print(f'Xiaomi MiMo {status} {bar}')
    print(f'   \U0001f4c8 {fmt(used)}/{fmt(limit)} ({pct:.1f}%) | \U0001f4b0 剩余 {fmt(remaining)}')
else:
    print(f'Xiaomi MiMo | \u2705 已连接')
" 2>/dev/null
else
  echo "Xiaomi MiMo | ✅ 已连接"
fi
