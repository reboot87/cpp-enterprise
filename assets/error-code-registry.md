# 错误码注册表

分类与可重试语义见 `references/architecture.md` §5。

| Code | 分类 | HTTP | gRPC | 可重试 | 用户消息 | 诊断信息 | 触发条件 | 负责人 |
|---|---|---|---|---|---|---|---|---|
| `invalid_argument` | 输入 | 400 | INVALID_ARGUMENT | 否 | | | | |
| `unauthenticated` | 认证 | 401 | UNAUTHENTICATED | 否 | | | | |
| `permission_denied` | 授权 | 403 | PERMISSION_DENIED | 否 | | | | |
| `not_found` | 查询 | 404 | NOT_FOUND | 否 | | | | |
| `conflict` | 状态 | 409 | ABORTED | 视情况 | | | | |
| `rate_limited` | 限流 | 429 | RESOURCE_EXHAUSTED | 是 | | | | |
| `unavailable` | 依赖 | 503 | UNAVAILABLE | 是 | | | | |
| `internal` | 内部 | 500 | INTERNAL | 视情况 | | | | |

规则:

- `code` 一旦发布不复用、不改语义;新增需评审。
- 用户消息不泄漏内部路径、堆栈、密钥;诊断信息只进日志。
- 可重试必须同时满足:操作幂等、错误临时、调用方有重试预算。
