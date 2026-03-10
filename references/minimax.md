# MiniMax 配置指南

## 获取 API Key

1. 登录 MiniMax 开放平台开发者后台：https://platform.minimaxi.com/
2. 进入"API Keys"页面
3. 创建或复制已有的 API Key
4. 填入 `.env`

## 环境变量

```bash
MINIMAX_CODING_API_KEY=your_api_key_here
```

## 限制说明

- **限制类型**: 5 小时
- **免费额度**: 600 次/5小时

## 注意事项

⚠️ 如果在 MiniMax 官网点击"重新生成"API Key，原 Key 会失效，需要重新获取并更新 `.env`。
