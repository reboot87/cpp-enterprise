# 门禁与整改

## 1. 合并门禁(默认集合;能自动则自动,其余列入清单)

1. 构建矩阵:Windows MSVC + Linux GCC + Linux Clang(+ macOS,若发布)。
2. 单测 + 覆盖率阈值(核心 ≥80%,整体 ≥60%)。
3. ASan/UBSan/TSan 干净。
4. clang-tidy / cppcheck 零新增(基线配置见 `assets/clang-tidy`)。
5. clang-format 无 diff(基线配置见 `assets/clang-format`)。
6. 平台规则检查(`check-platform`)通过。
7. 依赖:CVE 扫描 + 许可证白名单 + NOTICE/SBOM 生成。
8. 密钥扫描。
9. benchmark 回归:同硬件对比基线,p99 >10% 或吞吐 >5% 失败。
10. 长稳:24h soak 无内存单调增长、无句柄泄漏。
11. 故障注入:超时/断依赖/资源耗尽/坏输入用例通过。
12. 可维护性:构建与单测时长在预算内,依赖图无环,重复率 ≤3%。
13. 改动影响面:常规功能 PR 触碰模块数 ≤6,超出需 ADR。
14. SAST:零严重。
15. ABI/API diff:破坏性变更必须升主版本并更新迁移说明。
16. 覆盖率趋势:新增/变更行 ≥90%,整体不下降。
17. flaky:隔离清单有修复期限,禁止重跑掩盖。
18. 发布:产物签名或哈希、SBOM、NOTICE、可复现构建校验。

## 2. 规则与检查映射

每条 MUST 必须有落点:自动检查、CI 门禁或评审清单。

| MUST | 落点 |
|---|---|
| 1 公共头平台无关 / 2 平台同名成对 / 3 core 无平台宏 | `check-platform` |
| 4 句柄不用 int | 评审清单(按名启发式易误报,不进自动门禁) |
| 5 三方只经适配器 | include 白名单检查 + 评审 |
| 6 RAII / 7 工具链干净 | clang-tidy + CI |
| 8 测试与覆盖率 | CI |
| 9 门禁全绿 | CI |
| 10 规则可判定 | 本文档自查 |
| 11 性能门禁 | CI benchmark |
| 12 资源上限与超时 | 评审清单 + 故障注入 |
| 13 版本化与弃用 | ABI diff + 评审 |
| 14 改动影响面 | PR 统计 |
| 15 安全边界 | SAST/secret scan/fuzz + 评审 |
| 16 发布可追溯 | release checklist + 签名/SBOM |
| 17 注释为中文 | 评审清单 |
| 18 依赖单向/状态所有权/错误码 | 依赖图检查 + 错误码表评审;启动/关闭有测试 |
| 19 并发有界可取消 | TSan + 压力/关闭/超时测试 |
| 20 Git 工作流 | 分支保护 + commit lint + tag/CHANGELOG 校验 |

## 3. 门禁裁剪

最小门禁(所有仓库):构建 + 单测 + 静态检查/格式 + secret scan + 平台检查。

按风险追加:

| 条件 | 追加 |
|---|---|
| 有热路径 | 性能回归 |
| 长连接/后台服务 | 24h 长稳 |
| 有外部依赖 | 故障注入 |
| 对外发布库/二进制 | SAST、ABI diff、签名、SBOM |
| 解析外部输入 | fuzz、属性测试 |

裁剪只允许减项,不允许无基线;每项豁免要有理由和到期时间。

## 4. 核心模块定义

覆盖率与评审门槛需要"核心模块"清单,由仓库在 `AGENTS.md` 明确列出。默认判据:被外部直接依赖,或承载认证/资金/数据持久化/协议解析的模块。

## 5. 平台规则检查

```powershell
# Windows,首次接入或历史债未清时用 -ReportOnly
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-platform.ps1 -ReportOnly
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-platform.ps1   # 清零后作为门禁
```

```sh
# POSIX
REPORT_ONLY=1 sh scripts/check-platform.sh
sh scripts/check-platform.sh
```

检查项:

| 检查 | 含义 |
|---|---|
| Platform macro outside platform layer | 平台目录外出现 `_WIN32`/`_MSC_VER`/`__linux__`/`__APPLE__` 等;`include/<ns>/platform/` 与适配器除外 |
| OS header in portable code | 公共头/core 里出现 `windows.h`、`sys/*` 等(`include/<ns>/platform/` 也不允许) |
| Dependency on a concrete platform backend | 公共头/core 依赖 `platform/win32|posix|darwin/` |
| Missing sentinel | 平台文件缺 `#error` 哨兵(`-RequireSentinel`) |
| Platform source pairing | `win32/` 与 `posix/` 源文件不成对(默认开,`-SkipPairing` 关闭) |

脚本自身要能自测,防止改坏:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill>/assets/selftest-check-platform.ps1
```

```sh
sh <skill>/assets/selftest-check-platform.sh
```

参数:`-Root`、`-PlatformDir`、`-IncludeDir`、`-AdapterDir`、`-MacroExempt`、`-ReportOnly`、`-RequireSentinel`、`-SkipPairing`。脚本默认跳过 `build/`、`bin/`、`obj/`、`third_party/`、`vendor/` 等目录。

依赖图检查:CMake `--graphviz` 或 include 图工具产出依赖图,CI 断言无环、无跨层边。

## 6. 棘轮(只减不增)

历史欠债不要求一次清零,但必须禁止增长:

- 记录当前违规数作为基线;CI 要求 `当前数 ≤ 基线`。
- 每次整改后下调基线。
- 新增文件直接纳入硬检查,不给豁免。

## 7. 豁免策略

- 豁免只能按目录/文件路径白名单,写在检查脚本参数或 CI 配置,并附理由和到期时间。
- 不允许按"个人习惯"或"这个文件特殊"豁免。
- `tests/` 允许平台宏用于启动/清理,但业务断言仍走公共 API。

## 8. 仓库接入步骤

1. 复制 `assets/AGENTS.template.md` 为仓库 `AGENTS.md`,填构建命令与布局。
2. 复制 `assets/check-platform.*` 到 `scripts/`,复制 `platform-sources.cmake` 到 `cmake/`。
3. 先 `-ReportOnly` 跑一次,把结果记入 `AGENTS.md` 的"已知差距"。
4. 复制 `assets/nfr-targets.md` 为 `docs/nfr-targets.md`;先填能测的数,填不了的写"未定义"。
5. 接 CI:构建矩阵、测试、静态检查、平台检查、benchmark 回归。
6. 逐步整改,更新基线,最后去掉 `-ReportOnly`。
7. 排期补长稳、故障注入、fuzz,结果写回 NFR 目标表。
8. 引入第三方库时补 ADR 和能力表。

## 9. 升级方式

规则只改 skill,不改各仓库副本;各仓库通过重新复制 `assets/` 获取新脚本。仓库 `AGENTS.md` 只保留事实,不随标准版本变化。
