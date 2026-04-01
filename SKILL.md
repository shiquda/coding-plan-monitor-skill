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
| Kimi Coding Plan | 7天 + 5小时（**同一池额度的双重限制**） |
| Codex (ChatGPT Plus) | 7天 + 5小时 |

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
- **Codex**: 见 [references/codex.md](references/codex.md)

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

## Kimi 判读规则（重要）

**Kimi 7d 和 Kimi 5h 不是两池独立额度，而是同一套使用的双重限制。**

这意味着：
- 用一次 Kimi，同时会消耗 **5h 窗口** 和 **7d 窗口**
- 不能因为 “5h 快刷新了” 就默认推荐继续用 Kimi
- **建议时必须优先看 7d 总体健康度**，再看 5h 短期窗口

### 正确建议逻辑

1. **如果 7d 已经偏高（如 >70%）**
   - 即使 5h 快刷新，也**不默认推荐**继续用 Kimi
   - 优先建议 MiniMax / RightCode

2. **如果 7d 还健康**
   - 这时 5h 临近刷新，才有“顺手用掉”的意义

3. **对用户的表述要求**
   - 不要把 Kimi 5h 和 Kimi 7d 当成两池可独立调度的额度来说
   - 应明确说：这是 **同一池额度的双重限制**

### 错误示例

❌ `Kimi 5h 快刷新了，现在最适合用 Kimi`

### 正确示例

✅ `Kimi 5h 虽然快刷新了，但 7d 已经到 76%，不建议因为短期窗口重置就继续烧 Kimi。现在优先 MiniMax / RightCode。`

## 状态说明

- ✅ 充足 (<85%)
- ⚠️ 警告 (85-95%)
- 🔴 紧张 (>95%)

## 回复规范（重要）

对用户回复时：
1. **直接调用脚本**：`./scripts/check_all_usage.sh`
2. **只贴原始输出**，不加任何自行总结的内容
3. 如用户要求评论，再按实际状态简短评论

### 默认执行约定（新增）

当用户说：
- “查一下用量”
- “看下 coding plan”
- “用 coding-plan-monitor 查一下”
- 或明确要求使用本 skill

默认理解为：
- **无需再追问格式偏好**
- 直接运行 `./scripts/check_all_usage.sh`
- **只贴原始输出**，不做任何自行总结

不要只因为 5h 快刷新，就给出误导性建议。
