# AGENTS.md

本仓库是 `cpp-enterprise` 标准的发布源(OpenCode skill),不是应用项目。标准正文即仓库内容,版本见 `SKILL.md` 首屏,不在此重复。本文件只写本仓库的事实、差异和已知差距。

## 构建与测试

本仓库无编译产物,只有文档、模板和两个检查脚本。

- 检查器自测(必跑):
  - `powershell -NoProfile -ExecutionPolicy Bypass -File assets/selftest-check-platform.ps1`
  - `sh assets/selftest-check-platform.sh`
- 脚本语法:`bash -n assets/check-platform.sh`
- 文档链接与版本一致性:仓库外脚本 `E:\aiwork\cpp-enterprise-validation\validate.ps1`
- 静态检查:`assets/clang-format`、`assets/clang-tidy` 是发给项目的基线,不是本仓库的执行配置

## 布局

- `SKILL.md`:路由、MUST 1–20、版本、资产索引
- `references/`:16 篇分领域规则
- `assets/`:20 个模板与检查器(含 `AGENTS.template.md`)
- `CHANGELOG.md`:版本历史

## 版本与变更

- MUST 或检查器行为变化 → 次版本号 + `CHANGELOG.md` 条目。
- 措辞、错字、链接修复 → 补丁号。
- 检查器新增规则会让存量仓库 finding 数上升,属预期,需在 CHANGELOG 写明。

## 依赖

- 零第三方依赖。检查器只依赖 PowerShell 5.1 / POSIX sh 与 git。
- `clang-format`/`clang-tidy` 可选,只用于验证资产配置语法,不在本仓库强制。

## 已知差距

1. 无 CI:自测、链接检查、脚本语法检查均靠人工执行。
2. 本机未安装 `clang-format`/`clang-tidy`,两份基线配置未实际运行过。
3. `assets/check-platform.sh` 仅在 WSL 上通过自测,未在真实 Linux/macOS CI 验证。
4. 链接与版本一致性检查在仓库外的验证工程里,未入库。
5. 无 `README.md`、`LICENSE`:对外可见,但不说明安装方式与授权。
6. 检查器是文本启发式,不解析 C++ 语法;宏出现在字符串或注释中会误报。
7. 含中文的 `.ps1` 必须带 UTF-8 BOM,否则 Windows PowerShell 5.1 报语法错误;复制资产时容易丢 BOM。

## 例外

- `assets/check-platform.*` 与 `assets/selftest-check-platform.*` 中的平台宏、OS 头字样是有意的检测目标,不适用 MUST 1。
- 本仓库不遵循 `assets/AGENTS.template.md` 首行的"遵循某版本 skill"写法:本仓库就是标准本身。
