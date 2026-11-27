# Changelog

## 1.2.1 — 2026-11-27

- 修复 `check-platform`:允许 `include/<ns>/platform/` 内的平台宏(与 MUST 1 一致),但该目录仍禁止 OS 头;适配器不再误报平台宏。
- 平台宏检测补 `_WIN64`、`_MSC_VER`、`__unix__`、`__MACH__`、`__FreeBSD__`、`__CYGWIN__`、`__ANDROID__`、`_POSIX_VERSION`;OS 头补 `io.h`、`process.h`、`poll.h`、`linux/` 等。
- 修复 POSIX 脚本 win32 缺对时路径写错,并与 ps1 同步适配器/平台头豁免。
- 修复 POSIX 脚本配对检查未拼 `$ROOT`,指定 `Root` 时检查了错误目录;新增 `assets/selftest-check-platform.sh`,两份实现各有 8 个正反例。
- 修正 `platform-sources.cmake`:macOS 的 `darwin/` 只覆盖同名 posix 源,而不是整目录替换。
- 修复 `enforcement.md` 规则映射编号错位与门禁重复(许可证出现两次);门禁标题改为"默认集合"。
- 新增 `assets/clang-format`、`assets/clang-tidy`(含命名规则)、`assets/gitattributes`;命名由 clang-tidy 固化,不再误写为 clang-format。
- 修正 `std::expected` 的 C++23 前提;清理 `cpp-language.md` 重复条目;`cross-platform.md` 改掉"公共头不进平台目录"与 `handle.h` 的矛盾。
- 补:日志量预算、跨机时钟同步、数据保留期、可复现构建的不确定性来源、目标架构、`.gitattributes`、RPO/覆盖率到 NFR 模板、核心模块与配置基线到 AGENTS 模板。
- 按独立验证夹具(`E:\aiwork\cpp-enterprise-validation`)实测补充三条字符集事实:编译选项用 `target_compile_options(PUBLIC)` 传播 `/utf-8`,不用 `add_compile_options`;含中文的 `.ps1` 必须 UTF-8 with BOM;Windows 目标必须用 `target_compile_definitions(PUBLIC)` 定义 `UNICODE`/`_UNICODE`(CMake 默认多字节字符集,`/utf-8` 不能替代)。

## 1.2.0 — 2026-11-27

- 新增 `references/architecture.md`:模块边界与依赖方向、状态所有权与启动/关闭顺序、一致性与幂等、API 设计、错误分类学、降级矩阵、缓存、消息队列语义。
- 新增 `references/concurrency.md`:执行模型选型、线程/队列规模(利特尔法则)、取消与超时传播、同步原语、共享数据、信号/fork、FFI/插件隔离。
- 新增 `references/git-workflow.md`:trunk-based、Conventional Commits、提交签名、评审与合并、标签与发布、大文件/子模块。
- 新增 MUST 18(依赖单向/状态所有权/错误码)、19(并发有界可取消)、20(Git 工作流)。
- 新增资产:`error-code-registry.md`、`degradation-matrix.md`、`new-project-checklist.md`、`runbook-template.md`、`postmortem-template.md`。
- `cpp-language.md` 新增分配与数值、禁用/慎用清单、链接模型与跨 DSO;命名默认值定为 `snake_case`。
- `build-release.md` 新增代码生成、支持与升级策略;`observability.md` 新增崩溃与生产诊断;`security.md` 新增依赖混淆、审计日志与 PII;`testing.md` 新增持续 fuzz;`data-config.md` 新增备份与灾备(RPO/RTO)。
- `enforcement.md` 新增门禁裁剪(最小集 + 按风险追加)与核心模块定义。
- 修正 `-D_FORTIFY_SOURCE` 需开优化的前提;性能默认阈值标注为起点。

## 1.1.1 — 2026-11-27

- 新增 MUST 17:注释一律用中文(标识符、宏、路径、命令、API 名保持英文,许可证头与外部代码引用除外),标注为评审项。
- `cpp-language.md` §9 细化注释语言规则;"触碰即转换"存量英文注释。
- 评审清单与规则映射同步。

## 1.1.0 — 2026-11-27

- 新增 `references/security.md`、`testing.md`、`cpp-language.md`、`build-release.md`、`observability.md`、`data-config.md`。
- 新增 P1 内容:文档体系、评审与 DoD、技术债、代码所有权、容量与预算、供应链合规与生命周期。
- 新增 MUST 15(安全边界)、16(发布可追溯);MUST 4 标注为评审项;MUST 10 改为"每条 MUST 必须有落点"。
- 门禁扩展到 19 条,新增"规则与检查映射"。
- `check-platform` 增加平台文件同名成对检查;新增 `assets/selftest-check-platform.ps1`。
- 新增 `assets/review-checklist.md`、`threat-model.md`、`release-checklist.md`。

## 1.0.0 — 2026-11-27

- 初始版本:质量、跨平台、第三方、性能、鲁棒性、可维护性、门禁与检查脚本。
