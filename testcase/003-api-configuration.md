# 测试用例：003 - API 获取与配置

> 对应指南 [003 - API 获取与配置](../guide/003-api-configuration.md)

## TC-003-01：Anthropic Claude API 连接

**前置条件**：已获取 Anthropic API Key

**操作步骤**：
1. 设置环境变量 `export ANTHROPIC_API_KEY="sk-ant-xxx"`
2. 在 `openclaw.json` 中设置 `agents.defaults.model` 为 `claude-sonnet-4-6`
3. 设置 `agents.defaults.api` 为 `anthropic-messages`
4. 启动 Gateway
5. 通过已配置的通讯平台发送 "你好"

**测试目标**：验证 Claude API 正常连接

**预期结果**：
- 代理正常回复
- 无 400/401/403 错误
- 日志中显示使用的模型为 claude-sonnet-4-6

---

## TC-003-02：Claude API 格式错误验证

**操作步骤**：
1. 设置 `agents.defaults.api` 为 `openai-completions`（故意错误）
2. 通过通讯平台发送消息触发工具调用

**测试目标**：确认使用错误 API 格式时的表现

**预期结果**：
- 多轮工具调用时返回 400 错误
- 日志中有相关错误信息
- 改回 `anthropic-messages` 后恢复正常

---

## TC-003-03：Moonshot Kimi API 连接

**前置条件**：已获取 Moonshot API Key

**操作步骤**：
1. 设置环境变量 `export MOONSHOT_API_KEY="your-key"`
2. 在 `openclaw.json` 中配置 Moonshot provider（见指南）
3. 设置 `agents.defaults.model` 为 `kimi-k2.5`
4. 启动 Gateway
5. 发送测试消息

**测试目标**：验证 Kimi API 通过 OpenAI 兼容接口正常工作

**预期结果**：
- 代理使用 Kimi K2.5 模型正常回复
- 中文回复质量良好

---

## TC-003-04：OpenRouter API 连接

**前置条件**：已获取 OpenRouter API Key

**操作步骤**：
1. 设置环境变量 `export OPENROUTER_API_KEY="sk-or-xxx"`
2. 设置 `agents.defaults.model` 为 `openrouter/anthropic/claude-sonnet-4.5`
3. 启动 Gateway
4. 发送测试消息

**测试目标**：验证 OpenRouter 路由正常工作

**预期结果**：
- 代理正常回复
- 无需配置 `models.providers`（内置支持）

---

## TC-003-05：模型回退机制

**操作步骤**：
1. 配置主模型和 fallback 列表（见指南）
2. 故意使用一个无效的主模型名称
3. 发送测试消息

**测试目标**：验证 fallback 自动切换

**预期结果**：
- 主模型失败后自动切换到 fallback 模型
- 日志中记录 fallback 行为
- 用户正常收到回复

---

## TC-003-06：API Key 优先级

**操作步骤**：
1. 同时设置 ANTHROPIC_API_KEY 和 OPENROUTER_API_KEY
2. 不指定 `agents.defaults.model`
3. 启动 Gateway
4. 发送测试消息

**测试目标**：验证多 API Key 时的自动优先级

**预期结果**：
- 自动使用 Anthropic（最高优先级）
- 日志中显示选择的模型为 Claude 系列
