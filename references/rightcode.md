# RightCode 配置指南

## 获取 Token

1. 登录 https://right.codes/
2. F12 打开开发者工具 → Network
3. 刷新页面，找到 `/subscriptions/list` 请求
4. 复制 Request Headers 里的 `Authorization` 值
5. 去掉 `Bearer ` 前缀，填入 `.env`

## 环境变量

```bash
RIGHTCODE_TOKEN=your_token_here
```
