# Webshare Proxy 流量查询

## API 端点

- **流量统计**: `GET https://proxy.webshare.io/api/v2/stats/aggregate/`
- **订阅计划**: `GET https://proxy.webshare.io/api/v2/subscription/plan/`

## 认证

```
Authorization: Token <API_KEY>
```

## 返回字段

### stats/aggregate/
- `bandwidth_total` — 已用流量（bytes）
- `bandwidth_projected` — 投影流量（bytes）
- `requests_total` — 总请求数

### subscription/plan/
- `results[0].bandwidth_limit` — 流量上限（GB，0 = 无限）
- `results[0].proxy_type` — 代理类型（semidedicated/dedicated）
- `results[0].proxy_subtype` — 代理子类型（isp/datacenter）

## 注意事项

- 流量统计默认为当前订阅期
- API 限速 240 次/分钟
- 最多查询最近 90 天
