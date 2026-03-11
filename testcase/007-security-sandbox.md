# 测试用例：007 - 安全沙箱配置

> 对应指南 [007 - 安全沙箱配置](../guide/007-security-sandbox.md)

## TC-007-01：沙箱模式 - all

**前置条件**：Docker Desktop 已安装

**操作步骤**：
1. 配置 `sandbox.mode` 为 `all`
2. 启动 Gateway
3. 发送 "执行 whoami 命令"
4. 发送 "列出 /etc/passwd 的内容"

**测试目标**：验证所有工具调用在 Docker 容器中执行

**预期结果**：
- `whoami` 返回容器内的用户（如 `root`）
- 文件内容来自容器环境，非宿主机
- `openclaw sandbox explain` 确认沙箱策略为 `all`

---

## TC-007-02：沙箱模式 - non-main

**操作步骤**：
1. 配置 `sandbox.mode` 为 `non-main`
2. 在主 DM 中发送 "执行 whoami"
3. 在群组中发送 "@bot 执行 whoami"

**测试目标**：验证非主线程使用沙箱隔离

**预期结果**：
- 主 DM 中 `whoami` 返回宿主机用户
- 群组中 `whoami` 返回容器用户

---

## TC-007-03：工作区挂载 - readonly

**操作步骤**：
1. 配置 `workspaceMount` 为 `readonly`
2. 发送 "在工作区创建一个 test.txt 文件"

**测试目标**：验证只读挂载阻止写入

**预期结果**：
- 代理报告无法写入文件
- 日志中有 permission denied 相关错误

---

## TC-007-04：工具 deny 列表

**操作步骤**：
1. 配置 `tools.deny` 包含 `["execute_shell", "delete_file"]`
2. 发送 "执行 ls 命令"
3. 发送 "删除 test.txt 文件"

**测试目标**：验证 deny 列表阻止指定工具

**预期结果**：
- 代理拒绝执行被禁止的工具
- 解释操作被安全策略禁止

---

## TC-007-05：执行审批

**操作步骤**：
1. 配置 `execApproval` 为 `true`
2. 发送 "帮我执行 echo hello"

**测试目标**：验证执行审批机制

**预期结果**：
- 代理在执行前发送确认请求
- 用户确认后执行
- 用户拒绝后不执行

---

## TC-007-06：安全审计命令

**操作步骤**：
1. 执行 `openclaw security audit`
2. 执行 `openclaw security audit --fix`
3. 执行 `openclaw sandbox explain`

**测试目标**：验证安全工具正常运行

**预期结果**：
- 审计报告包含各安全检查项
- `--fix` 修复可自动修复的问题
- `sandbox explain` 清晰显示当前沙箱策略

---

## TC-007-07：elevated 模式

**操作步骤**：
1. 配置 elevated 模式，限制 `allowedSenders` 和 `commands`
2. 用允许的用户发送允许的命令
3. 用允许的用户发送不允许的命令
4. 用不允许的用户发送命令

**测试目标**：验证提权模式的访问控制

**预期结果**：
- 允许的用户 + 允许的命令 → 正常执行
- 允许的用户 + 不允许的命令 → 拒绝
- 不允许的用户 → 拒绝
