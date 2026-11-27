# 代码质量标准

## 1. 语言与构建基线

| 项 | 标准 |
|---|---|
| 标准版本 | 全工程统一 C++17 或 C++20,写进构建文件 |
| 告警 | GCC/Clang `-Wall -Wextra -Wpedantic`,MSVC `/W4 /permissive-`;CI 加 `-Werror` |
| 硬化 | Release 开启 stack protector/FORTIFY/RELRO 等,见 `security.md` §6 |
| 扩展 | 禁止编译器私有扩展 |
| UB | UBSan/ASan 必须零报告 |
| 构建 | Debug/Release 都过;可重复构建 |
| 依赖 | 版本固定(manifest + lock / hash),禁止 latest |

## 2. 规模与结构

| 指标 | MUST(硬限) | SHOULD(目标) |
|---|---|---|
| 函数行数 | ≤ 80 | ≤ 50 |
| 圈复杂度 | ≤ 20 | ≤ 15 |
| 嵌套层数 | ≤ 5 | ≤ 4 |
| 单文件行数 | ≤ 1000 | ≤ 500 |
| 单类行数 | ≤ 500 | ≤ 300 |

- 头文件自包含,能单独 include 编译通过;include-what-you-use。
- 公共头禁止 `using namespace`;禁止在头里定义非 inline 实体。
- 禁止循环依赖;用前向声明和接口隔离打断。

## 3. 内存与资源

- RAII 全覆盖;禁止裸 `new`/`delete`/`malloc`/`free`。
- `unique_ptr` 是默认所有权;`shared_ptr` 仅在真实共享时用;不持有对象用 `T*`/`T&` 并说明生命周期。
- 遵守 Rule of 0;必须手写时五个特殊成员一起处理。
- 移动构造/赋值标 `noexcept`;移动后对象保持有效可析构。
- 析构函数不得抛异常;禁止 `std::endl`。

## 4. 接口与 API

- `const` 正确性贯穿到底;纯观察函数 `[[nodiscard]]`。
- 单参构造 `explicit`;避免 `bool` 形参和多个同类型形参,用强类型或配置结构体。
- 公开承诺 `noexcept`/异常行为,并写明。
- 库边界用 PIMPL 或不透明句柄,公开头不泄漏 STL 实现细节。
- 破坏性变更走 SemVer + 迁移说明。

## 5. 错误处理

- 不用异常做控制流;可预期失败用 `std::expected`(C++23)或等价 `expected`/`optional`/错误码。
- 异常只用于资源获取失败等真正异常路径;明确异常安全等级。
- 禁止空 `catch`;错误信息必须带上下文(操作、参数、错误码)。
- 不变式用 `assert`;`assert` 不得有副作用。
- 边界处(IO、网络、输入、反序列化)校验长度、范围、签名。

## 6. 并发

- 共享可变状态:加锁或原子,二选一,写明理由。
- 定义锁顺序;禁止无文档的嵌套锁;用 `lock_guard`/`scoped_lock`。
- 禁止 detach 线程;线程生命周期明确 join 或线程池管理。
- `memory_order` 非默认值必须注释说明。
- TSan 干净;并发代码有多线程压力测试。

## 7. 性能

热路径、指标定义、测量方法与性能门禁见 `references/performance.md`。代码层只记住:不猜、不提前优化、每处优化有数据。

## 8. 安全

完整要求见 `references/security.md`。代码层底线:禁用不安全 C 函数、整数溢出显式检查、敏感数据不入日志、外部输入在边界校验。

## 9. 测试

测试层级、覆盖率口径、flaky 策略与 CI 执行见 `references/testing.md`。代码层底线:每个公开接口有单测、bug 先补回归、测试确定性。

## 10. 静态检查与格式

```
clang-format   CI 校验无 diff;基线 skill `assets/clang-format` → `.clang-format`
clang-tidy     bugprone-*, performance-*, modernize-*, readability-*, cppcoreguidelines-*, concurrency-*
               基线 skill `assets/clang-tidy` → `.clang-tidy`(含命名规则)
cppcheck       --enable=warning,performance,portability
```

工具链版本固定,结果可复现;告警只减不增。

## 11. 文档与可观测性

文档体系与评审见 `references/maintainability.md`;日志、指标、追踪与 SLO 见 `references/observability.md`。底线:公开头注释写清前置条件与失败语义、README 能从零跑通、关键决策留 ADR。

## 12. 行业合规(按需)

- 车载/工业:MISRA C++:2023 或 AUTOSAR C++14。
- 功能安全:ISO 26262 / IEC 61508 过程证据。
- 安全编码:SEI CERT C++。
