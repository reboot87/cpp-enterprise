# C++ 语言细则

通用代码工艺(规模、内存、接口、错误、并发)见 `quality.md`;这里只写语言与 ABI 层。

## 1. 语言版本与特性

- 全工程统一 C++17 或 C++20,写进构建文件;禁止各模块自选。
- 新特性(concepts、ranges、coroutines、modules)按编译器矩阵评估后再用,不追新。
- 用 `__has_include`/`__cpp_*` 做特性检测,不用编译器宏猜。
- 禁止编译器私有扩展;`-std=c++17` 而非 `gnu++17`。

## 2. 异常与 RTTI 策略

仓库必须二选一并写进 AGENTS.md:

- **启用异常**:异常只用于资源获取失败;不得跨 ABI/模块边界;边界翻译成错误码/`expected`。
- **禁用异常**(`-fno-exceptions`):全部用 `expected`(C++23 标准或等价实现)/错误码;`new` 失败走 `nothrow` 并检查。
- RTTI 同理:默认开;嵌入式/体积敏感可关,但禁止依赖 `dynamic_cast` 的设计。

## 3. ODR 与链接

- 头文件里只放声明和 `inline`/模板;禁止非 inline 定义。
- 匿名 namespace 只用于 `.cpp`;禁止出现在头文件。
- 禁止跨编译单元的静态初始化顺序依赖;全局对象优先 `constexpr`/函数内静态。
- 禁止可变全局状态;必须有时,明确初始化与销毁顺序,并限制访问。
- `inline namespace` 可用于版本化,见 §6。

## 4. 未定义行为清单

以下必须避免,并在 CI 开对应检查:

| UB | 检查手段 |
|---|---|
| 有符号整数溢出 | UBSan |
| 移位越界/负数 | UBSan、`-Wshift-*` |
| 严格别名违规 | `-fstrict-aliasing` + 代码评审,用 `memcpy` |
| 未初始化读取 | MSan/`-Wuninitialized` |
| 越界/悬垂 | ASan、`-D_GLIBCXX_ASSERTIONS` |
| 生命周期/悬垂引用 | ASan、clang-tidy `bugprone-use-after-move` |
| 数据竞争 | TSan |
| 无效转换/窄化 | `-Wconversion`、`gsl::narrow` |
| 空指针解引用 | UBSan、静态分析 |
| `printf` 格式不匹配 | `-Wformat` |

## 5. 类型与转换

- 禁止 C 风格转换;用 `static_cast`/`reinterpret_cast`(后者需注释理由)。
- 宽窄转换显式:`gsl::narrow` 或 `static_cast` + 范围断言。
- `enum class`,不用裸 `enum`;位标志用显式重载或 `std::bitset`。
- 强类型替代裸基础类型(`UserId`、`Duration`),避免同类型形参混淆。
- `size_t`/`ptrdiff_t` 表达大小;禁止 `int` 装大小与索引混用。
- `char` 的符号性不假设;字节用 `std::byte`/`unsigned char`。

## 6. 类与 ABI

- Rule of 0/5;有虚函数则虚析构,叶类标 `final`。
- 拷贝/移动按语义显式 `delete`/`default`,不靠隐式生成。
- 库边界:PIMPL 或纯 C 句柄;公开头不暴露 STL 容器成员与内联实现。
- 符号默认隐藏(`-fvisibility=hidden`),显式导出;Windows 用 `__declspec(dllexport/import)` 宏。
- ABI 兼容:只增不改;结构体预留 padding;版本用 `inline namespace` 或句柄版本字段。
- CI 跑 ABI diff,破坏性变更必须升主版本。

## 7. 模板与编译期

- 模板错误要可读:用 `static_assert` 给约束信息;C++20 用 concepts。
- 控制实例化爆炸:热点模板显式实例化,其余下沉到 `.cpp`。
- 编译期计算优先 `constexpr`,但不要为省运行时而把逻辑埋进模板。
- 禁止宏做类型/控制流;宏只做条件编译与字符串化,且必须可 grep。

## 8. 命名与文件布局

- 文件:小写下划线,扩展名统一 `.h`/`.cpp`;一个主类一个头,头与源同名。
- 类型 `PascalCase`;函数与变量 `snake_case`(默认);常量 `kPascalCase`;成员后缀 `_`;命名空间小写。
- 命名由 clang-tidy `readability-identifier-naming` 固化(基线 `assets/clang-tidy`);格式由 `.clang-format` 固化(基线 `assets/clang-format`);仓库可在 `AGENTS.md` 覆盖。
- 禁止 `using namespace` 于头文件,`.cpp` 里也仅限函数内;评审不争论个人风格。

## 9. 注释与文档

- **注释一律用中文(简体)**;标识符、类型名、宏名、路径、命令、API 名保持英文原文;许可证头与外部代码引用可保留原文。
- 术语可中英并用,但同一句内不中英混杂堆砌。
- 新增和修改的注释用中文;存量英文注释在触碰该文件时顺带转换,不单独大改。
- 源文件统一 UTF-8(无 BOM 可接受);MSVC 用 `target_compile_options(<lib> PUBLIC /utf-8)` 让每个编译公共头的目标继承,否则按本地代码页解析,中文注释触发 C4819/C1019。不用 `add_compile_options`,它会把选项泄漏给无关目标。
- 含中文的 `.ps1` 存为 UTF-8 with BOM;Windows PowerShell 5.1 会把无 BOM 的 UTF-8 当 ANSI,直接报语法错误。
- 注释解释"为什么",不复述代码。
- 公开头用 Doxygen:前置条件、失败语义、线程安全、复杂度(Doxygen 命令保持英文,正文中文)。
- TODO 必须带负责人和 issue:`// TODO(name): ... (ISSUE-123)`。
- 删除注释掉的代码,不留历史包袱。

## 10. 分配与数值

- 默认用标准分配器;热点可用 `pmr`/arena,但生命周期、线程归属必须清楚。
- 自定义分配器先 profile 证明分配是瓶颈;必须有对齐保证和失败处理。
- over-aligned 类型用 aligned new / 对齐分配器;跨平台用 `alignas` + `static_assert`。
- 内存池只用于固定大小、同生命周期对象;池内存不归还 OS 要写明。
- 禁用异常的构建用 `nothrow` 分配并检查返回值。
- 浮点默认 IEEE 754 双精度;禁止 `-ffast-math`(破坏 NaN、结合律与可复现性)。
- 浮点比较用容差,禁止 `==`;NaN 显式处理。
- 金额/计数用整数或定点;禁止 `float`/`double` 表示金额。
- 有符号溢出是 UB;无符号按模运算;跨平台用 `__builtin_*_overflow` 或 `gsl::narrow`。
- 移位量必须小于位宽;有符号右移依赖实现,不用。
- 安全随机用 CSPRNG;测试用固定种子;禁止 `rand()`/时间戳。

## 11. 禁用与慎用清单

| 项 | 规则 |
|---|---|
| `goto` | 仅允许向下跳到统一清理点,禁止跨作用域跳入 |
| `setjmp`/`longjmp` | 禁止(与析构/异常不兼容) |
| `volatile` | 仅 MMIO/信号标志;不做线程同步 |
| `const_cast` | 不得修改原 const 对象 |
| `reinterpret_cast` | 仅 ABI/序列化底层,必须注释理由 |
| `dynamic_cast` | 设计上避免;热路径禁止 |
| `std::regex` | 热路径禁止(慢,可能栈溢出) |
| `std::vector<bool>` | 禁止(代理引用) |
| `std::endl` | 禁止 |
| `rand`/`time`/`getenv` | 禁止用于安全或唯一性;`getenv` 非线程安全 |
| `atoi`/`atol` | 禁止;用 `from_chars` + 范围检查 |
| `printf` 家族 | 仅封装内部;用 `snprintf`/`format` 并检查格式 |
| locale 相关函数 | 显式指定 locale,不依赖全局 |
| 隐式窄化 | `-Wconversion` + 显式检查 |
| `auto` | 不弱化关键类型(接口/数值/生命周期) |
| 宏常量 | 用 `constexpr` |
| 头文件 `using namespace` | 禁止 |
| 异常/RTTI 跨 DSO | 禁止/避免 |
| 静态局部可变状态 | 慎用,必须线程安全 |

## 12. 链接模型与跨 DSO

- 内部库默认静态链接;跨团队/插件边界用共享库 + 稳定 C ABI。
- 符号默认隐藏(`-fvisibility=hidden` / `.def`),显式导出。
- 共享库用 SONAME + version script;ABI 变更升 SONAME。
- 异常和 RTTI 不跨 DSO;边界用 C ABI + 错误码。
- libstdc++ 双 ABI(`_GLIBCXX_USE_CXX11_ABI`)全工程一致。
- MSVC `/MT` 与 `/MD` 全工程一致;STL debug 迭代器不跨边界。
- 插件与宿主使用同一编译器/标准库/CRT,否则只走 C ABI。
- 导出符号表纳入评审,禁止默认全部导出。

## 13. 标准映射(审计用)

| 本 skill | C++ Core Guidelines | CERT C++ |
|---|---|---|
| 内存/RAII | R(Resource management) | MEM |
| 类型/转换/UB | ES(Expressions) | INT、EXP |
| 类与接口 | C(Classes)、I(Interfaces) | OOP |
| 错误处理 | E(Error handling) | ERR |
| 并发 | CP/SL | CON |
| 模板 | T(Templates) | TMP |
| 源文件/头 | SF(Source files) | PRE |
| 命名 | NR(Naming) | - |
| 安全 | - | MSC、STR、ARR |

按需追加 MISRA C++:2023 / AUTOSAR C++14 的条款映射。

## 14. 反模式

- 用 `reinterpret_cast` 绕过类型系统。
- 头文件里 `using namespace` 或定义变量。
- 依赖静态初始化顺序。
- 用宏生成类/函数,读者无法定位。
- 为"通用"把简单函数模板化。
- 在公共头暴露 `std::vector` 成员导致 ABI 锁死。
