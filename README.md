# Coding Plan Monitor

统一监控多个 Coding Plan 平台的用量情况。

## 支持平台

| 平台 | 7天限制 | 5小时限制 |
|------|---------|-----------|
| MiniMax | - | ✅ |
| RightCode | ✅ | - |
| Kimi Coding Plan | ✅ | ✅ |

## 功能特性

- 📊 10 格 Emoji 进度条可视化
- 🕐 北京时间重置时间显示
- 🔔 状态提醒 (✅/<85%, ⚠️/85%, 🔴/>95%)

## 快速开始

```bash
# 1. 克隆仓库
git clone https://github.com/shiquda/coding-plan-monitor-skill.git
cd coding-plan-monitor-skill

# 2. 复制配置
cp .env.example .env

# 3. 编辑 .env 填入你的 Token
# 4. 运行
./scripts/check_all_usage.sh
```

## 输出示例

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

## Token 获取

- **MiniMax**: 登录 minimaxi.com → F12 → /coding_plan/remains
- **RightCode**: 登录 right.codes → F12 → /subscriptions/list
- **Kimi**: 登录 kimi.com → F12 → GetUsages

## License

MIT

## 支持更多平台

欢迎提交 Issue 或 PR 添加更多平台的 Coding Plan 监控支持！

### 已支持平台

- MiniMax (5h)
- RightCode (7d)
- Kimi Coding Plan (7d + 5h)

### 待支持

- FoxCode (Cloudflare 盾拦截)
- 火山引擎 (无公开 API)

## 贡献

欢迎提交 Issue 报告问题，或提交 PR 添加新平台支持！

## 许可证

MIT
