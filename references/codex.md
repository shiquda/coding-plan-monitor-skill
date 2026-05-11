# Codex (ChatGPT Plus) 用量查询

## 接口说明

通过 CLIProxyAPI 的 Management API 透传，自动发现所有已登录的 Codex 账号并取平均值。

**关键端点**：
1. `GET /v0/management/auth-files` - 获取所有已注册账号
2. `POST /v0/management/api-call` - 透传请求到上游 API

## 环境变量配置

在 `.env` 中添加：

```bash
# CLIProxyAPI 地址
CODEX_CLI_PROXY_URL=http://100.88.53.43:8317

# Management API 密钥（remote-management.secret-key）
CODEX_MANAGEMENT_KEY=your-secret-key
```

## CLIProxyAPI 服务端要求

服务器需要开启远程管理：

```yaml
# config.yaml
remote-management:
  allow-remote: true
  secret-key: "your-secret-key"
```

## 返回字段

每个账号返回内容包含两个配额窗口：

```json
{
  "rate_limit": {
    "primary_window": {
      "used_percent": 91,
      "reset_after_seconds": 4751
    },
    "secondary_window": {
      "used_percent": 72,
      "reset_after_seconds": 40813
    }
  }
}
```

## 限制说明

- **5h 窗口**：滚动 5 小时（18000s），用 `primary_window`
- **7d 窗口**：7 天（604800s），用 `secondary_window`
- 多账号时输出综合**平均值**
- Verbose 模式下显示每个账号的独立用量
