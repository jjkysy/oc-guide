# 测试用例：002 - 基本配置与运行

> 对应指南 [002 - 基本配置与运行](../guide/002-basic-configuration.md)

## TC-002-01：引导向导完成

**操作步骤**：
1. 确保 `~/.openclaw/` 不存在或为空
2. 执行 `openclaw`
3. 按提示选择模型提供商、输入 API Key、选择通讯平台

**测试目标**：验证首次运行向导正常工作

**预期结果**：
- 向导依次展示各步骤
- 完成后自动生成 `~/.openclaw/openclaw.json`
- Gateway 自动启动

---

## TC-002-02：目录结构验证

**前置条件**：向导已完成

**操作步骤**：
1. 执行 `ls -la ~/.openclaw/`
2. 检查各子目录是否存在

**测试目标**：验证目录结构完整

**预期结果**：
- 存在 `openclaw.json`
- 存在 `agents/` 目录
- 存在 `credentials/` 目录
- 存在 `sessions/` 目录

---

## TC-002-03：CLI 配置命令

**操作步骤**：
1. 执行 `openclaw config get`
2. 执行 `openclaw config set gateway.port 18790`
3. 执行 `openclaw config get gateway.port`
4. 执行 `openclaw config unset gateway.port`

**测试目标**：验证 CLI 配置命令正常工作

**预期结果**：
- `config get` 输出完整配置
- `config set` 成功设置值
- `config get gateway.port` 返回 `18790`
- `config unset` 成功删除值

---

## TC-002-04：Gateway 启停

**操作步骤**：
1. 执行 `openclaw start`
2. 执行 `openclaw status`
3. 执行 `openclaw logs --tail 5`
4. 执行 `openclaw stop`
5. 执行 `openclaw status`

**测试目标**：验证 Gateway 生命周期管理

**预期结果**：
- `start` 后 `status` 显示运行中
- `logs` 正常输出日志
- `stop` 后 `status` 显示已停止

---

## TC-002-05：热重载验证

**前置条件**：Gateway 正在运行

**操作步骤**：
1. 执行 `openclaw config set agents.defaults.model "claude-haiku-4-5"`
2. 等待 5 秒
3. 执行 `openclaw config get agents.defaults.model`

**测试目标**：验证配置热重载生效

**预期结果**：
- 无需重启 Gateway
- 新配置值已生效
- 日志中出现 reload 相关信息

---

## TC-002-06：环境变量引用

**操作步骤**：
1. 在 `~/.zshrc` 中添加 `export TEST_TOKEN="test123"`
2. 执行 `source ~/.zshrc`
3. 在 `openclaw.json` 中使用 `"${TEST_TOKEN}"`
4. 执行 `openclaw doctor`

**测试目标**：验证环境变量在配置文件中正确解析

**预期结果**：
- `openclaw doctor` 不报环境变量解析错误
- 配置值正确读取为 `test123`

---

## TC-002-07：配置严格验证

**操作步骤**：
1. 手动在 `openclaw.json` 中添加未知键 `"unknownKey": true`
2. 执行 `openclaw start`

**测试目标**：验证配置文件的严格验证机制

**预期结果**：
- Gateway 拒绝启动
- 报错信息指出未知键名
- 删除未知键后恢复正常
