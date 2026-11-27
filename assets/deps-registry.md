# 能力表(Capability registry)

每个能力只有一个默认实现;同一目标里禁止出现两个同能力库。

| 能力 | 默认实现 | 版本 | 许可证 | 维护/EOL | 适配器路径 | 未启用的替代 | 备注 |
|---|---|---|---|---|---|---|---|
| HTTP 服务 | <in-house / lib> | | | | src/core/server.cpp | | |
| JSON | <std / in-house> | | | | src/adapters/json/ | nlohmann, simdjson | |
| 哈希 | <in-house / OpenSSL> | | | | src/adapters/crypto/ | mbedTLS | |
| TLS | <none> | | | | | OpenSSL, mbedTLS, wolfSSL | 需 ADR |
| 日志 | <in-house> | | | | src/observability/ | spdlog | |
| 线程 | std::thread | C++17 | 标准库 | 随标准库 | - | - | |

规则:

- 新增行或更换默认实现,必须先有 ADR。
- "适配器路径"是唯一允许 include 厂商头的目录。
- "未启用的替代"只做记录,永不与默认实现编进同一目标。
