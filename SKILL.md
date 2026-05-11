---
name: coding-plan-monitor
description: 统一监控 MiniMax、Codex (ChatGPT Plus) Coding Plan 用量。支持双限制显示（7天+5小时）、10格 Emoji 进度条、北京时间重置时间显示，支持 Verbose 模式查看各账号独立用量。当需要查询或监控各平台 Coding Plan 剩余额度时触发此技能。
---

# Coding Plan Monitor

统一监控多个 Coding Plan 平台的用量情况。

## 支持平台

| 平台 | 限制类型 |
|------|----------|
| MiniMax | 5小时 |
| Codex (ChatGPT Plus) | 7天 + 5小时（**多账号平均**） |
| Kimi Coding Plan | 7天 + 5小时（**同一池额度的双重限制**） |
| Webshare Proxy | 流量上限（GB） |

## 快速开始

```bash
# 1. 复制配置
cp .env.example .env

# 2. 编辑 .env 填入 Token（详见 references/）
# 3. 运行（默认简洁模式）
./scripts/check_all_usage.sh

# 4. Verbose 模式 - 显示每个账号的独立用量
./scripts/check_all_usage.sh -v
```

## Verbose 模式

Codex 支持多账号，Verbose 模式下会先输出每个账号的 7d/5h 用量，再输出综合平均值：

```
📊 Coding Plan 用量汇总 - Verbose 模式 (2026-04-16)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[🔴] 1@shiquda.link (7d: 73%, 5h: 93%)
    7d → 剩余 27 | 11h 9m 后刷新
    5h → 剩余 7  | 1h 8m 后刷新
[✅] 3@shiquda.link (7d: 1%, 5h: 6%)
    7d → 剩余 99 | 6d 23h 后刷新
    5h → 剩余 94 | 4h 33m 后刷新
---
✅ Codex-7d ███░░░░░░░
   📈 37/100 (37%) | 💰 剩余 63 | 3d 17h 后刷新

✅ Codex-5h █████░░░░░
   📈 49/100 (49%) | 💰 剩余 51 | 2h 56m 后刷新
...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**平均规则**：所有账号的用量取**平均值**（而非最大值），更好地反映总体剩余能力。

## Token 配置

各平台 Token 获取方式：

- **MiniMax**: 见 [references/minimax.md](references/minimax.md)
- **Codex**: 见 [references/codex.md](references/codex.md)
- **Kimi**: 见 [references/kimi.md](references/kimi.md)

### Codex 特殊配置

Codex 通过 CLIProxyAPI 的 Management API 自动发现所有已登录账号，无需手动配置每个账号：

```bash
# .env 中配置
CODEX_CLI_PROXY_URL=http://100.88.53.43:8317
CODEX_MANAGEMENT_KEY=your-management-key
```

CLIProxyAPI 服务器需要开启 `allow-remote-management: true` 才能远程访问。

## 输出格式（默认简洁模式）

```
📊 Coding Plan 用量汇总 (2026-03-10)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Kimi Coding Plan-7d ███░░░░░░░
   📈 30/100 (30%) | 💰 剩余 70 | 17:44

✅ Kimi Coding Plan-5h ░░░░░░░░░░
   📈 0/100 (0%) | 💰 剩余 100 | 19:44

✅ MiniMax ░░░░░░░░░░
   📈 10/600 (2%) | 💰 剩余 590 | 4h38m

✅ Codex-7d ███░░░░░░░
   📈 37/100 (37%) | 💰 剩余 63 | 3d 17h 后刷新

✅ Codex-5h ████░░░░░░
   📈 49/100 (49%) | 💰 剩余 51 | 2h 56m 后刷新
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Kimi 判读规则（重要）

**Kimi 7d 和 Kimi 5h 不是两池独立额度，而是同一套使用的双重限制。**

这意味着：
- 用一次 Kimi，同时会消耗 **5h 窗口** 和 **7d 窗口**
- 不能因为 "5h 快刷新了" 就默认推荐继续用 Kimi
- **建议时必须优先看 7d 总体健康度**，再看 5h 短期窗口

### 正确建议逻辑

1. **如果 7d 已经偏高（如 >70%）**
   - 即使 5h 快刷新，也**不默认推荐**继续用 Kimi
   - 优先建议 MiniMax / Codex

2. **如果 7d 还健康**
   - 这时 5h 临近刷新，才有"顺手用掉"的意义

3. **对用户的表述要求**
   - 不要把 Kimi 5h 和 Kimi 7d 当成两池可独立调度的额度来说
   - 应明确说：这是 **同一池额度的双重限制**

### 错误示例

❌ `Kimi 5h 快刷新了，现在最适合用 Kimi`

### 正确示例

✅ `Kimi 5h 虽然快刷新了，但 7d 已经到 76%，不建议因为短期窗口重置就继续烧 Kimi。现在优先 MiniMax / Codex。`

## 状态说明

- ✅ 充足 (<85%)
- ⚠️ 警告 (85-95%)
- 🔴 紧张 (>95%)

## 回复规范（重要）

对用户回复时：
1. **直接调用脚本**：`./scripts/check_all_usage.sh`（或 `check_all_usage.sh -v` 询问详细用量时）
2. **只贴原始输出**，不加任何自行总结的内容
3. 如用户要求评论，再按实际状态简短评论

### 默认执行约定

当用户说：
- "查一下用量"
- "看下 coding plan"
- "用 coding-plan-monitor 查一下"
- "verbose 查看" / "详细用量"
- 或明确要求使用本 skill

默认理解为：
- 简洁用量：`./scripts/check_all_usage.sh`
- 要求详细（verbose）：`./scripts/check_all_usage.sh -v`
- **只贴原始输出**，不做任何自行总结

不要只因为 5h 快刷新，就给出误导性建议。
