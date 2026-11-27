# Git 工作流

## 1. 分支模型

- 默认 trunk-based:短分支,生命周期 ≤2 天,频繁合并回主干。
- 发布按需拉 release 分支;禁止长期 `develop`。
- 分支名:`feat/<topic>`、`fix/<topic>`、`chore/<topic>`。

## 2. 提交

- 一个提交一个意图,可独立编译、测试、回滚。
- 格式:Conventional Commits(`feat:`、`fix:`、`docs:`、`refactor:`、`perf:`、`test:`、`build:`、`ci:`、`chore:`)。
- 标题说"做了什么",正文说"为什么"、影响与迁移。
- 关联 issue;修复类提交注明 `Fixes #123`。
- 禁止提交注释掉的代码、构建产物、密钥、大文件。

## 3. 身份与签名

- 作者名/邮箱正确(与 GitHub 账号一致),不冒用他人。
- 发布 tag 与关键分支启用签名提交/签名 tag。
- 禁止改写已发布的公共历史;需要时用 revert。

## 4. 评审与合并

- PR 小(有效改动 ≤400 行)、单一意图;模板见 `assets/review-checklist.md`。
- `CODEOWNERS` 指定关键模块评审人;至少一人,关键模块两人。
- 分支保护:必需检查通过、禁止直推、禁止 force push 到共享分支。
- 合并策略全仓统一(squash 或 rebase);合并后删除分支。
- 首轮评审响应 ≤1 个工作日;阻塞项明确标记。

## 5. 标签与发布

- 版本 tag 用 annotated/signed tag,与 CHANGELOG 版本一一对应。
- tag 触发发布流水线,禁止手工上传产物。
- 发布分支只接受 cherry-pick 的修复,不夹带新功能。

## 6. 大文件与子模块

- 二进制/大文件用 LFS 或制品库,不进普通提交。
- 子模块锁定 commit;升级需记录原因。
- `.gitattributes` 固定换行:`* text=auto eol=lf`,脚本 LF,VS 工程/`.ps1` CRLF(模板 `assets/gitattributes`)。
- 第三方代码放独立目录,不与自研代码混排。

## 7. 反模式

- 一个 PR 混多个功能,无法回滚。
- 提交信息"fix"、"update"。
- 直接向 main 推送。
- 强制推送覆盖他人提交。
- tag 与发布产物不对应,无法复现。
