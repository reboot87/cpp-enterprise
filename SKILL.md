---
name: cpp-enterprise
description: Enterprise C++ engineering standard for any C++ project. Use when writing, reviewing, refactoring, building, releasing, or adding dependencies to C++ code; covers code quality gates, architecture and module boundaries, concurrency and cancellation, cross-platform layering (platform-independent public headers plus per-OS source folders), security and hardening, testing strategy, performance and latency, robustness, observability, release engineering, and choosing or replacing third-party libraries. Triggers on C++, C++17, C++20, CMake, MSVC, GCC, Clang, platform port, cross-platform, third-party dependency, dependency choice, code review, security review, test strategy, release, thread pool, cancellation, error code, git workflow.
---

# C++ 企业级标准

适用于所有 C++ 仓库。本文件是可执行的硬规则;细节按需读 `references/`。

标准版本:1.2.1(2026-11-27),变更见 `CHANGELOG.md`。

## 使用方式

1. 硬规则见下一节,违反即视为未完成。
2. 需要细则时读对应 reference,不要凭记忆。
3. 仓库 `AGENTS.md` 只记录具体事实和差异;与本文件冲突时以本文件的 MUST 为准,并明确指出冲突。
4. 新建或整改仓库时,复制 `assets/` 下的文件,不要重写。

## 硬规则(MUST)

1. 公共头平台无关。唯一可感知平台的公共头是 `include/<ns>/platform/handle.h`,只做句柄与宽度类型映射。
2. 平台实现只放 `src/platform/<os>/`,同一接口用同名文件实现;选源只发生在构建脚本。
3. `src/core/` 与公共头里禁止平台宏和 OS 头;禁止用 `#ifdef` 兜底"以后可能用到"。
4. 句柄/描述符不用 `int` 存(Win64 的 `SOCKET` 是 64 位);宽度用 `int32_t`/`int64_t`/`size_t`/`intptr_t`/`uintptr_t`。MUST(评审项)。
5. 第三方库只能经 `src/adapters/<lib>/` 进入;厂商头不得出现在公共头和 core。一个能力只有一个默认实现,新增需 ADR。
6. 资源一律 RAII;禁止裸 `new`/`delete`;所有权用 `unique_ptr`/`shared_ptr`/引用表达。
7. 告警零新增;ASan/UBSan/TSan 干净;clang-tidy 零新增;clang-format 无 diff(基线配置见 `assets/clang-format`、`assets/clang-tidy`)。
8. 新逻辑带测试;每个 bug 修复先补回归测试;核心逻辑覆盖 ≥80%,整体 ≥60%。
9. 合并门禁全绿:构建矩阵 + 测试 + 静态检查 + 许可证/CVE。
10. 每条 MUST 必须有落点(自动检查、CI 或评审清单);做不到的标 MUST(评审项)或降为 SHOULD,映射见 `references/enforcement.md`。
11. 热路径必须有基准;p99 回归 >10% 或吞吐回归 >5% 不得合并(仓库可收紧,不可无基线)。
12. 队列/缓存/线程/连接/重试必须有上限和溢出策略;外部调用必须有超时和取消。
13. 扩展走既有扩展点;公开接口与插件 ABI 变更必须版本化,并有至少一个次版本的弃用窗口。
14. 常规功能改动影响面 ≤ 6 个文件/模块,超出先拆分或写 ADR(仓库可调整)。
15. 信任边界的输入必须校验;鉴权失败一律拒绝;密钥/口令不入代码、配置库和日志。
16. 发布可追溯:版本号 + CHANGELOG + SBOM + 许可证清单;产物签名或哈希;同一产物部署到所有环境。
17. 注释一律用中文(简体);标识符、宏、路径、命令、API 名保持英文;许可证头与外部代码引用除外。MUST(评审项)。
18. 模块依赖单向、无环、可枚举;状态单一所有者;启动顺序固定、关闭逆序;错误有稳定 `code` 与可重试标记。
19. 线程/任务有名字和上限;队列有界;异步任务可取消、超时向下传播;关闭有截止时间;禁止孤儿线程。
20. 提交单一意图、Conventional Commits;主干受保护;发布 tag 与 CHANGELOG 版本一一对应。

质量属性冲突(性能 vs 可维护、扩展 vs 简单、鲁棒 vs 延迟)必须用 ADR 显式权衡,不得静默取舍。

## 路由

| 任务 | 读 |
|---|---|
| 代码结构、函数规模、内存、接口、错误处理 | `references/quality.md` |
| 模块边界、依赖方向、状态所有权、API 契约、错误分类、降级、缓存、队列语义 | `references/architecture.md` |
| 线程模型、线程/队列规模、取消与超时、锁、信号、FFI/插件 | `references/concurrency.md` |
| C++ 语言、UB、ABI、异常/RTTI 策略、命名与布局 | `references/cpp-language.md` |
| 认证、授权、加密、密钥、输入校验、硬化编译、供应链 | `references/security.md` |
| 测试层级、覆盖率、flaky、fuzz、兼容矩阵 | `references/testing.md` |
| 构建、产物、版本、发布、回滚、数据库迁移 | `references/build-release.md` |
| 日志、指标、追踪、SLO、告警、runbook | `references/observability.md` |
| 配置、密钥注入、序列化、持久化、编码/时区/金额 | `references/data-config.md` |
| 新增平台后端、平台分歧、构建选源、目录布局 | `references/cross-platform.md` |
| 引入/替换/评估第三方库、同能力多库 | `references/third-party.md` |
| 吞吐、p99/p999、抖动、分配预算、基准与剖析 | `references/performance.md` |
| 超时、重试、熔断、降级、资源上限、故障注入、长稳 | `references/robustness.md` |
| 可维护、可修改、可扩展、扩展点、版本与弃用 | `references/maintainability.md` |
| 分支模型、提交格式、评审合并、标签与发布、子模块 | `references/git-workflow.md` |
| CI 门禁、检查脚本、整改顺序、豁免 | `references/enforcement.md` |

## 资产

- `assets/AGENTS.template.md`:仓库 `AGENTS.md` 模板,只写事实与差异。
- `assets/check-platform.ps1` / `check-platform.sh`:平台规则检查。
- `assets/clang-format`、`assets/clang-tidy`:格式与静态检查基线(复制为 `.clang-format`/`.clang-tidy`)。
- `assets/gitattributes`:跨平台换行基线(复制为 `.gitattributes`)。
- `assets/platform-sources.cmake`:构建侧平台选源。
- `assets/adr-template.md`、`assets/deps-registry.md`:选型与能力表模板。
- `assets/nfr-targets.md`:各仓库的质量属性目标表模板。
- `assets/review-checklist.md`:PR 评审清单 + 完成定义。
- `assets/threat-model.md`:STRIDE 威胁建模模板。
- `assets/release-checklist.md`:发布前检查清单。
- `assets/error-code-registry.md`:错误码、分类、可重试性与协议映射。
- `assets/degradation-matrix.md`:依赖 × 故障 × 降级动作。
- `assets/new-project-checklist.md`:新仓库从 0 到门禁全绿。
- `assets/runbook-template.md`、`assets/postmortem-template.md`:运行手册与复盘模板。
- `assets/selftest-check-platform.ps1` / `.sh`:检查脚本自测(两份实现各自有正反例)。
- `CHANGELOG.md`:标准版本变更。

## 输出要求

- 改动遵循标准;发现既有代码违反 MUST 时,在结论里列出(文件:行 + 条款),不要顺手大改。
- 无法验证的条目要明确写"未验证"及风险。
