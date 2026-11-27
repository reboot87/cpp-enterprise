# cpp-enterprise

面向 C++ 项目的工程标准,以 OpenCode skill 形式发布。标准正文是 `SKILL.md`(MUST 1–20 + 路由),细则在 `references/`,可复制到项目的模板与检查器在 `assets/`。

适用:C++17/20、CMake、MSVC/GCC/Clang、需要跨平台分层、质量门禁与发布的仓库。

## 1. 安装 skill

```powershell
git clone https://github.com/reboot87/cpp-enterprise.git "$env:USERPROFILE\.config\opencode\skills\cpp-enterprise"
```

Linux/macOS:

```sh
git clone https://github.com/reboot87/cpp-enterprise.git ~/.config/opencode/skills/cpp-enterprise
```

OpenCode 通过 `SKILL.md` 的 frontmatter 自动发现,无需注册。

## 2. 让 agent 自动加载

在全局 `~/.config/opencode/AGENTS.md` 加一条(没有就新建):

```markdown
## C++

- 任何 C++ 工作(编写、评审、重构、构建、依赖选择)先加载 `cpp-enterprise` skill。
```

之后 agent 处理 C++ 时会读 MUST 与对应 reference,不需要你每次贴规则。

## 3. 新项目初始化

目录骨架:

```text
include/<ns>/                 公共头,平台无关
include/<ns>/platform/handle.h   唯一可感知平台的公共头
src/core/                     业务逻辑,禁止平台宏
src/platform/{win32,posix}/   同名文件成对,带 #error 哨兵
src/adapters/<lib>/           第三方库隔离层
tests/  docs/  cmake/  scripts/
```

复制资产(只复制,不重写):

```powershell
$skill = "$env:USERPROFILE\.config\opencode\skills\cpp-enterprise\assets"
New-Item -ItemType Directory -Force cmake,scripts,docs | Out-Null
Copy-Item "$skill\clang-format"  .clang-format
Copy-Item "$skill\clang-tidy"    .clang-tidy
Copy-Item "$skill\gitattributes" .gitattributes
Copy-Item "$skill\platform-sources.cmake" cmake\
Copy-Item "$skill\check-platform.ps1","$skill\check-platform.sh" scripts\
Copy-Item "$skill\AGENTS.template.md"    AGENTS.md
Copy-Item "$skill\nfr-targets.md"        docs\
Copy-Item "$skill\deps-registry.md"      docs\
Copy-Item "$skill\error-code-registry.md" docs\error-codes.md
Copy-Item "$skill\degradation-matrix.md"  docs\
```

其余模板按需:`threat-model.md`、`release-checklist.md`、`runbook-template.md`、`postmortem-template.md`、`adr-template.md`。完整清单见 `assets/new-project-checklist.md`。

填 `AGENTS.md`:只写本仓库的构建命令、布局、NFR 值、差异和已知差距,不抄标准。

## 4. CMake 最小接法(已验证)

```cmake
include(cmake/platform-sources.cmake)
engine_select_platform_sources(APP_PLATFORM_SOURCES)

add_library(app STATIC src/core/... ${APP_PLATFORM_SOURCES})
target_include_directories(app PUBLIC include)

if(MSVC)
    # 公共头含中文注释;PUBLIC 让编译它的目标继承同样的解码方式
    target_compile_options(app PUBLIC /W4 /permissive- /WX /utf-8)
else()
    target_compile_options(app PUBLIC -Wall -Wextra -Wpedantic -Werror)
endif()

if(WIN32)
    # CMake 默认多字节字符集;PUBLIC 保证同一二进制内 A/W 一致
    target_compile_definitions(app PUBLIC UNICODE _UNICODE)
endif()
```

## 5. 第一次检查

```powershell
# 存量仓库先只看不改
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check-platform.ps1 -ReportOnly

# 新仓库直接当门禁
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check-platform.ps1 -RequireSentinel
```

```sh
sh scripts/check-platform.sh
```

输出格式 `文件:行: 规则`,可直接定位。检查器自身有自测:`assets/selftest-check-platform.ps1|sh`,8 个正反例。

## 6. 接入 CI

门禁清单与每个 MUST 的落点见 `references/enforcement.md`。最小集合:构建矩阵、单测、ASan/UBSan/TSan、`clang-format --dry-run --Werror`、`clang-tidy`、`check-platform`、覆盖率、许可证与 CVE 扫描。

## 7. 存量项目整改

1. 先跑 `-ReportOnly`,把 finding 记成欠账,不一次性大改。
2. 按 `references/enforcement.md` 的顺序:先平台分层,再告警/格式,最后门禁。
3. 无法遵守的条目写进 `AGENTS.md` 的"差异/已知差距",不要静默跳过。

## 版本

当前 1.2.1,变更见 `CHANGELOG.md`。
