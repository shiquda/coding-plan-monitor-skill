# Coding Plan Monitor

统一监控多个 Coding Plan 平台的用量情况。

## 支持平台

| 平台 | 限制类型 |
|------|----------|
| MiniMax | 5小时 |
| RightCode | 7天 |
| Kimi Coding Plan | 7天 + 5小时 |

## 快速开始

```bash
# 1. 克隆仓库
git clone https://github.com/shiquda/coding-plan-monitor-skill.git
cd coding-plan-monitor-skill

# 2. 复制配置
cp .env.example .env

# 3. 编辑 .env 填入 Token
# 4. 运行
./scripts/check_all_usage.sh
```

## Token 配置

各平台 Token 获取方式详见 `references/` 目录。

## 贡献

欢迎提交 Issue 或 PR 贡献代码和建议！
