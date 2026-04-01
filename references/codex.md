# Codex (ChatGPT Plus) 用量查询

## Token 获取方式

1. 登录 https://chatgpt.com/
2. F12 打开开发者工具 → Network
3. 刷新页面，找到 `/backend-api/wham/usage` 请求
4. 复制 **Authorization** header 的值（Bearer 后面那串 token）
5. 同一个请求里复制 **Account-Id** header 的值

## 环境变量配置

在 `.env` 中添加：

```bash
CODEX_BEARER_TOKEN=your_bearer_token_here
CODEX_ACCOUNT_ID=your_account_id_here
```

## 接口说明

```
GET https://chatgpt.com/backend-api/wham/usage
Authorization: Bearer <token>
Account-Id: <account_id>
```

## 返回字段

```json
{
  "rate_limit": {
    "primary_window": {
      "used_percent": 10,
      "limit_window_seconds": 18000,
      "reset_after_seconds": 16824
    },
    "secondary_window": {
      "used_percent": 3,
      "limit_window_seconds": 604800,
      "reset_after_seconds": 603624
    }
  }
}
```

## 限制说明

- **5h 窗口**：滚动 5 小时（18000s），用 `primary_window`
- **7d 窗口**：7 天（604800s），用 `secondary_window`
- `used_percent` 直接是百分比数字（0-100），无需计算

## 与其他平台的关系

Codex 与各平台 Coding Plan **完全独立**：

| 平台 | 额度来源 |
|------|----------|
| Kimi/MiniMax/RightCode | 各平台 Coding Plan |
| Codex | ChatGPT Plus 订阅 |

可以同时使用，互不冲突。
