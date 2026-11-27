# AGENTS.md

C++ 标准:遵循 `cpp-enterprise` skill(标准版本 <x.y.z>)。本文件只写本仓库的事实、差异和已知差距,不重复标准。

## 构建与测试

- 配置:`<command>`
- 构建:`<command>`
- 测试:`<command>`
- 静态检查:`<command>`(基线 `.clang-format`/`.clang-tidy` 从 skill `assets/` 复制)
- 平台检查:`<powershell|sh> scripts/check-platform.<ps1|sh>`

## 布局

- 公共头:`include/<ns>/`
- 平台感知头:`include/<ns>/platform/handle.h`
- 平台实现:`src/platform/{win32,posix,darwin}/`
- 第三方适配:`src/adapters/<lib>/`
- 能力表:`docs/deps-registry.md`

## 依赖

- 默认立场:零第三方依赖 / 允许的库见能力表。
- 新增库先写 ADR,再更新能力表。

## 质量属性目标

- NFR 目标表:`docs/nfr-targets.md`(从 skill `assets/nfr-targets.md` 复制后填写)
- 核心模块(覆盖率与评审按此口径):`<模块列表>`
- 当前基线:`benchmarks/baseline.json` 或 CI 产出
- 性能门禁:`<command>`
- 长稳 / 故障注入:`<command 或排期>`

## 安全与合规

- 威胁模型:`docs/threat-models/<feature>.md`(模板见 skill `assets/threat-model.md`)
- 许可证策略:`docs/license-policy.md`
- 密钥来源:`<secret store / env>`,禁止入库

## 文档

- 架构:`docs/architecture.md`
- 错误码与降级矩阵:`docs/error-codes.md`、`docs/degradation-matrix.md`
- Runbook:`docs/runbooks/`
- CHANGELOG:仓库根目录

## 差异

- (无)

## 已知差距

- (无)

## 例外

- `tests/`:允许平台宏用于启动和清理,不参与业务逻辑。
