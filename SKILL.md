---
name: coding-plan-monitor
description: 统一监控多个国内外 Coding Plan 平台的用量和套餐额度。支持 MiniMax、RightCode (Codex/Claude Code)、Kimi 等。自动计算潜在双倍额度，定时汇报。
---

# Coding Plan Monitor

统一监控多平台 Agent Coding Plan 用量，自动获取各平台剩余配额，支持潜在额度计算和定时汇报。

## 功能特性

- ✅ **多平台支持**: MiniMax、RightCode、Kimi Coding Plan
- 📊 **进度条可视化**: 10 格 Emoji 进度条，直观显示用量进度
- 🔄 **潜在额度计算**: RightCode 支持未重置套餐的双倍潜力计算
- ⏰ **北京时间显示**: 所有重置时间转换为北京时间
- ⏰ **定时汇报**: 支持配置每日多次自动汇报 (Cron)

## 支持的平台

| 平台 | 接口类型 | 额度重置周期 | 特殊逻辑 |
|------|----------|--------------|----------|
| MiniMax | API (国内) | 每日约 07:00 (北京时间) | - |
| RightCode | API | 每日 12:00 (北京时间) | 支持未重置套餐双倍潜力 |
| KimiCP | Web 内部 API | 每日约 17:44 (北京时间) | 需抓包获取 Token |

## 使用方式

### 1. 快速查询

```bash
cd skills/coding-plan-monitor
./scripts/check_all_usage.sh
```

### 2. 输出示例

```
📊 Coding Plan 用量汇总 (2026-03-10)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 KimiCP ██████████
   📈 100/100 (100%) | 💰 剩余 0 | 17:44

✅ MiniMax █░░░░░░░░░
   📈 64/600 (11%) | 💰 剩余 536 | 2h29m

✅ RightCode ████░░░░░░
   📈 86.14/180.02 (48%) | 💰 剩余 63.88 | 12:00
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 3. 配置定时任务 (可选)

```bash
# 添加每日 10:00, 14:00, 18:00, 22:00 自动汇报
openclaw cron add \
  --name "Coding Plan Usage Monitor" \
  --cron "0 10,14,18,22 * * *" \
  --tz "Asia/Shanghai" \
  --message "📊 请执行：cd /root/.openclaw/workspace/skills/coding-plan-monitor && ./scripts/check_all_usage.sh 并将结果汇报给我。" \
  --announce \
  --channel telegram \
  --to <你的Telegram_ID> \
  --session isolated
```

## 配置指南

### 环境变量

复制 `.env.example` 为 `.env`，填入你的凭证：

```bash
# MiniMax Coding Plan API Key
MINIMAX_CODING_API_KEY=sk-cp-xxxxxxxxxxxx

# RightCode Token (从浏览器开发者工具获取)
RIGHTCODE_TOKEN=your_rightcode_token

# Kimi Web Token (需抓包获取)
KIMI_WEB_TOKEN=eyJhbGciOiJIUzUxMiIs...
```

### 各平台凭证获取方式

#### 1. MiniMax (最简单)

1. 登录 [MiniMax 开放平台](https://platform.minimaxi.com/)
2. 进入「控制台」→「API 密钥」
3. 创建或复制 Coding Plan 相关的 API Key

**端点**: `https://www.minimaxi.com/v1/api/openplatform/coding_plan/remains`

#### 2. RightCode (需抓包)

1. 登录 [RightCode](https://right.codes/)
2. 打开浏览器开发者工具 (F12) → Network
3. 访问任意页面，查找 `Authorization: Bearer` 请求头
4. 复制完整的 Token

**API**: `GET https://right.codes/subscriptions/list`

**注意**: RightCode 支持多订阅合并计算，且未重置的套餐额度会累积（潜在双倍）。

#### 3. Kimi Coding Plan (需抓包)

1. 登录 [Kimi](https://kimi.moonshot.cn/)
2. 打开浏览器开发者工具 (F12) → Network
3. 筛选 `billing` 或 `usage` 相关的请求
4. 找到 `GetUsages` API，复制 `authorization` 请求头的 Bearer Token

**API**: `POST https://www.kimi.com/apiv2/kimi.gateway.billing.v1.BillingService/GetUsages`
**Payload**: `{"scope":["FEATURE_CODING"]}`

## 输出格式规范

所有 provider 脚本必须遵循统一格式：

```
平台名|已用|总量|百分比|剩余|重置时间|状态
```

示例：
```
MiniMax|64|600|11%|536|2h29m|✅
```

### 状态图标规则

| 用量区间 | 图标 |
|----------|------|
| < 60% | ✅ |
| 60% - 85% | ⚠️ |
| > 85% | 🔴 |

## 扩展新平台

在 `providers/` 目录下创建新的脚本：

```bash
#!/bin/bash
# providers/new_platform.sh

# ... 获取数据的逻辑 ...

# 输出统一格式
echo "平台名|已用|总量|百分比|剩余|重置时间|状态"
```

确保脚本有执行权限：`chmod +x providers/new_platform.sh`

## 文件结构

```
coding-plan-monitor/
├── .env.example      # 环境变量模板
├── SKILL.md          # 本文档
├── providers/        # 各平台查询脚本
│   ├── minimax.sh
│   ├── rightcode.sh
│   └── kimi_cp.sh
└── scripts/
    └── check_all_usage.sh  # 汇总脚本
```

## 注意事项

1. **安全**: 凭证请务必保存在 `.env` 中，不要提交到 Git
2. **Kimi Token 有效期**: Web Token 可能较短，需定期更新
3. **RightCode 额度过期**: 已过期的订阅会自动排除
4. **北京时间**: 所有时间默认转换为 UTC+8 显示

## 相关资源

- MiniMax 文档: https://platform.minimaxi.com/
- RightCode: https://right.codes/
- Kimi: https://kimi.moonshot.cn/
