# MiniMax 配置指南

## 获取 Token

1. 登录 https://www.minimaxi.com/
2. F12 打开开发者工具 → Network
3. 刷新页面，找到 `/coding_plan/remains` 请求
4. 复制 Request Headers 里的 `Authorization` 值
5. 去掉 `Bearer ` 前缀，填入 `.env`

## 环境变量

```bash
MINIMAX_CODING_API_KEY=your_api_key_here
```

## 限制说明

- **限制类型**: 5 小时
- **免费额度**: 600 次/5小时

## 注意事项

⚠️ 如果在 MiniMax 官网点击重新生成API Key，原 Key 会失效，需要重新获取并更新 。
