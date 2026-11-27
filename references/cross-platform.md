# 跨平台代码限制

## 1. 目录布局

```
include/<ns>/                 # 公共 API,平台无关
include/<ns>/platform/
  handle.h                    # 全项目唯一的平台感知公共头(只做类型映射)
src/core/                     # 业务逻辑,禁止 OS 头和平台宏
src/platform/
  common/                     # 平台无关的公共实现
  win32/                      # 仅 Windows
  posix/                      # Linux/macOS
  darwin/                     # 仅 BSD 特有行为不同时才建
src/adapters/<lib>/           # 第三方库适配,与平台层正交
```

规则:

- 除 `include/<ns>/platform/handle.h` 外,公共头不放进 `include/` 下的平台子目录;平台实现不对外发头。
- 同一能力在各平台目录用**同名文件**实现同一接口,构建时二选一。同名能保证链接进两个时直接重复符号,架构错误立刻暴露。
- `win32/` 与 `posix/` 的源文件集合必须一一对应;`darwin/` 允许是 `posix/` 的子集(只覆盖 BSD 特有行为)。由 `check-platform` 校验。
- `common/` 只放与 OS 无关的公共逻辑,不放带 `#ifdef` 的实现。

## 2. 依赖方向

```
core/ ──► include/<ns>/*.h ──► include/<ns>/platform/*.h
                                  ▲
win32/ , posix/ , darwin/ ────────┘
```

- 允许:平台实现 → 公共头;公共头 → 平台声明头。
- 禁止:公共头 → OS 头;`core/` → 具体平台目录;`common/` → 具体平台。
- 用 `assets/check-platform.ps1` / `.sh` 机器校验。

## 3. 公共头的平台无关化

用不透明句柄 + 语义函数隔绝差异,而不是假设两边类型一样。

```cpp
// include/<ns>/platform/handle.h —— 全项目唯一允许的平台分支
namespace ns::platform {
#ifdef _WIN32
using SocketHandle = std::uintptr_t;   // Win64 SOCKET 是 UINT_PTR
#else
using SocketHandle = int;
#endif
constexpr SocketHandle kInvalidSocket = /* ... */;
}
```

- 业务头只出现 `SocketHandle`,不出现 `SOCKET`/`HANDLE`/`int fd`。
- 头里的 `#ifdef` 只做 typedef,不放逻辑;更干净的做法是构建时传 `-D` 指定类型,头里零 `#ifdef`。
- 语义错误判断(`isRecoverable` / `isClosed` / `isTimeout`)在头里只声明,实现放各平台 `.cpp`。

## 4. 类型与 ABI

| 禁止 | 原因 | 替代 |
|---|---|---|
| `long` / `unsigned long` | Windows 32 位,Linux 64 位 | `int32_t`/`int64_t` |
| `wchar_t` 进接口 | Win 2 字节,POSIX 4 字节 | UTF-8 `char`/`char8_t` |
| `int` 存句柄 | Win64 句柄 64 位,会截断 | 平台 `SocketHandle` |
| 位域 / `#pragma pack` 做线格式 | 字节序和对齐不保证 | 显式序列化 + 固定宽度 |
| 假设 `sizeof(struct)` | ABI 不同 | `static_assert` + 显式 padding |
| `char` 当数字 | 有/无符号随平台 | `signed char`/`unsigned char` |

`time_t`、`off_t`、`ssize_t`、`socklen_t`、`pid_t` 一律走平台别名。

## 5. 文件与路径

- 只用 `std::filesystem`;禁止手拼 `/` 或 `\`。
- 必须处理:大小写敏感差异、`MAX_PATH` 260、保留名(`CON`/`NUL`/`COM1`)、盘符、符号链接、文件锁语义、原子 rename 覆盖语义。
- 文本/二进制模式显式;编码统一 UTF-8;Windows 非 ASCII 路径用 `u8path` 或宽字符 API。
- Windows 目标在所有配置显式定义 `UNICODE`/`_UNICODE`,用 `target_compile_definitions(<lib> PUBLIC ...)` 让链接方继承(同一二进制内所有 TU 必须一致);CMake 默认生成 MultiByte。Win32 调用显式用 `...W`;`/utf-8` 只决定源文件与执行字符集,不能替代 `UNICODE`。

## 6. 进程、线程、信号

- 线程用 `std::thread`,显式处理命名、栈大小、join、`thread_local` 析构顺序。
- `fork` 在 Windows 不存在;进程创建/守护抽象成 `Process`。
- 信号语义不同;关闭流程抽象成 `requestShutdown()`,业务代码不直接 `signal()`。
- 定时器、条件变量唤醒、单调时钟差异要有测试。

## 7. 网络

- 句柄独立类型;禁止 `int` 存 `SOCKET`。
- `WSAStartup`/`WSACleanup` 全局一次,放平台层;POSIX 无此概念。
- 错误码不做数值比较,走语义函数。
- 必须封装:`MSG_NOSIGNAL`/`SO_NOSIGPIPE`、`EPIPE` vs `WSAECONNRESET`、`SO_REUSEADDR` 语义、Windows `select` 的 `FD_SETSIZE=1024`、IPv6 双栈默认行为。
- 事件循环先抽象成 `Poller`,不让 `epoll_wait`/IOCP 漏进业务层。

## 8. 构建与工具链

- 构建系统单一来源,源码入库;IDE 工程是生成产物。
- Windows:固定 `_WIN32_WINNT`、`UNICODE`;`/MT` 与 `/MD` 全工程一致。
- Linux:在最低支持发行版上构建;发布包禁用 `-march=native`。
- macOS:固定 deployment target。
- 目标架构明确:默认 x86-64;ARM64 纳入矩阵;32 位需 ADR 与独立测试(指针宽度、`size_t`、对齐都会变)。
- 告警策略集中定义,禁止各文件各自 `#pragma warning`。
- 平台选源只写在构建脚本:

```cmake
include(cmake/platform-sources.cmake)
engine_select_platform_sources(ENGINE_PLATFORM_SOURCES)
```

## 9. 防错

- 平台文件顶部加哨兵,构建配置写错立即失败:

```cpp
#ifndef _WIN32
#  error "win32/socket.cpp must not be compiled on this platform"
#endif
```

- 不支持的系统建 `src/platform/stub/`,明确返回 `ENOSYS` 或启动时拒绝,不静默降级。
- 平台文件只装 OS 原语差异(通常几十行);重试、超时、协议逻辑放 `common/`,避免多份漂移。

## 10. 测试

- 最低矩阵:Windows MSVC + Linux GCC + Linux Clang(+ macOS Clang,若发布)。
- 平台特有行为各有测试;禁止用 `#ifdef` 把失败测试跳过。
- 至少保留一次交叉编译检查(只编不跑)。

## 11. 数据模型与编码

- 数据模型:Windows 是 LLP64,Linux/macOS 是 LP64;`long` 与指针宽度不同,禁止用 `long` 存大小或指针。
- 端序:线格式显式指定字节序;禁止直接写结构体或依赖主机端序。
- 对齐与布局:`alignof` + `static_assert` 校验跨平台假设。
- Unicode:全链路 UTF-8;macOS 文件名可能是 NFD,比较与存储前明确归一化策略。
- 编译器差异:MSVC 与 GCC/Clang 的特性缺口用 `__has_include`/`__cpp_*` 检测,并写进构建矩阵。
