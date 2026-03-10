# Kimi Coding Plan 配置指南

## 获取 Token

1. 登录 https://www.kimi.com/code/console
2. F12 打开开发者工具 → Network
3. 刷新页面，找到 `GetUsages` 请求
4. 复制 Request Headers 里的 `authorization` 值
5. 去掉 `Bearer ` 前缀，填入 `.env`

## 环境变量

```bash
KIMI_BEARER_TOKEN=your_bearer_token_here
```

## 限制说明

- **7天限制**: 100 次/周
- **5小时限制**: 100 次/5小时

## 注意事项



## 注意事项

⚠️ 如果在 Kimi 官网点击重新获取或刷新Token，原 Token 会失效，需要重新抓取并更新 。
