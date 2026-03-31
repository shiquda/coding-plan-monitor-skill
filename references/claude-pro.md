# Claude Pro 用量查询

## Token 获取方式

Claude Pro 使用的不是普通 API Key，而是 OAuth Token，存储在 Claude Code 的本地凭据文件中。

### Windows

1. 确保已安装并登录 Claude Code (`claude --login`)
2. 读取凭据文件：
   ```powershell
   Get-Content "$env:USERPROFILE\.claude\.credentials.json"
   ```
3. 找到 `claudeAiOauth.accessToken` 字段的值

### Linux / macOS / WSL

```bash
cat ~/.claude/.credentials.json | jq -r '.claudeAiOauth.accessToken'
```

## 接口说明

Claude Code 内部调用了一个未公开的 OAuth Usage API：

```
GET https://api.anthropic.com/api/oauth/usage
Authorization: Bearer <accessToken>
User-Agent: claude-code/<版本>
anthropic-beta: oauth-2025-04-20
```

**注意**：这是未公开的内部接口，Anthropic 可能随时更改，慎用。

## 返回字段

```json
{
  "five_hour": { "utilization": 16.0, "resets_at": "2026-03-31T06:59:59.900766+00:00" },
  "seven_day": { "utilization": 41.0, "resets_at": "2026-04-03T11:59:59.900785+00:00" }
}
```

## 限制说明

- **5h 窗口**：滚动 5 小时内的用量百分比
- **7d 窗口**：7 天自然日内（北京时间）的用量百分比

## 与其他平台的关系

Claude Pro 订阅与各平台的 Coding Plan **完全独立**：

| 平台 | 额度来源 | 限制 |
|------|----------|------|
| Kimi/MiniMax/RightCode | 各平台 Coding Plan | 独立额度 |
| Claude Pro | Anthropic 订阅 | 与其他平台互不影响 |

可以同时使用，互不冲突。
