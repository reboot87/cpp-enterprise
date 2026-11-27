# 新 C++ 仓库启动清单

## 骨架

- [ ] 目录:`include/<ns>/`、`src/{core,platform,adapters}/`、`tests/`、`docs/`、`cmake/`
- [ ] CMake presets + toolchain 文件;三平台可配置
- [ ] `.clang-format`、`.clang-tidy`、`.editorconfig`、`.gitattributes` 入库(基线从 skill `assets/` 复制)
- [ ] `AGENTS.md` 从 `assets/AGENTS.template.md` 填写
- [ ] `.gitignore` 覆盖构建产物;确认不误伤 `CMakeLists.txt`

## 质量与测试

- [ ] 告警即错误;ASan/UBSan/TSan 任务
- [ ] 测试框架 + 一个示例单测 + 覆盖率上报
- [ ] `clang-tidy`、`cppcheck`、格式检查接入 CI
- [ ] 核心模块列表与覆盖率阈值写进 `docs/nfr-targets.md`

## 平台

- [ ] `include/<ns>/platform/handle.h` 定义句柄/宽度类型
- [ ] `src/platform/{win32,posix}/` 同名文件成对
- [ ] 平台文件带 `#error` 哨兵
- [ ] `scripts/check-platform.ps1|sh` 接入并先 `-ReportOnly`

## 安全与合规

- [ ] 依赖许可证白名单 + SBOM + CVE 扫描
- [ ] secret scan;密钥来源确定(secret store/env)
- [ ] `assets/threat-model.md` 用于首批对外接口
- [ ] Release 硬化编译选项确认生效

## 交付

- [ ] 版本从 0.1.0 开始;`CHANGELOG.md` 建立
- [ ] 发布清单 `assets/release-checklist.md` 接入
- [ ] 调试符号归档;崩溃诊断方案确定
- [ ] `CODEOWNERS` 与分支保护

## 文档

- [ ] README 能在干净机器上从零跑通
- [ ] 架构文档(C4 L1/L2)与模块 README
- [ ] Runbook 初版(`assets/runbook-template.md`)
- [ ] 错误码表与降级矩阵初版
