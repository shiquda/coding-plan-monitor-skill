---
name: coding-plan-monitor
description: 统一监控 MiniMax、RightCode、Kimi Coding Plan 用量。支持双限制显示（7天+5小时）、10格 Emoji 进度条、北京时间重置时间显示。当需要查询或监控各平台 Coding Plan 剩余额度时触发此技能。
---

# Coding Plan Monitor

统一监控多个 Coding Plan 平台的用量情况。

## 支持平台

| 平台 | 限制类型 |
|------|----------|
| MiniMax | 5小时 |
| RightCode | 7天 |
| Kimi Coding Plan | 7天 + 5小时 |

## 快速开始

```bash
# 1. 复制配置
cp .env.example .env

# 2. 编辑 .env 填入 Token（详见 references/）
# 3. 运行
./scripts/check_all_usage.sh
```

## Token 配置

各平台 Token 获取方式：

- **MiniMax**: 见 [references/minimax.md](references/minimax.md)
- **RightCode**: 见 [references/rightcode.md](references/rightcode.md)
- **Kimi**: 见 [references/kimi.md](references/kimi.md)

## 输出格式

```
📊 Coding Plan 用量汇总 (2026-03-10)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Kimi Coding Plan-7d ███░░░░░░░
   📈 30/100 (30%) | 💰 剩余 70 | 17:44

✅ Kimi Coding Plan-5h ░░░░░░░░░░
   📈 0/100 (0%) | 💰 剩余 100 | 19:44

✅ MiniMax ░░░░░░░░░░
   📈 10/600 (2%) | 💰 剩余 590 | 4h38m

✅ RightCode ████░░░░░░
   📈 86/180 (48%) | 💰 剩余 64 | 🔄⏳
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 状态说明

- ✅ 充足 (<85%)
- ⚠️ 警告 (85-95%)
- 🔴 紧张 (>95%)
