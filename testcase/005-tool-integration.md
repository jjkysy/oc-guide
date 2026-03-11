# 测试用例：005 - 工具类软件配置

> 对应指南 [005 - 工具类软件配置](../guide/005-tool-integration.md)

## TC-005-01：浏览器工具安装与使用

**操作步骤**：
1. 执行 `openclaw skill install browser-tool`
2. 启动 Gateway
3. 发送 "访问 https://example.com 并告诉我页面内容"

**测试目标**：验证浏览器 MCP 工具正常工作

**预期结果**：
- 技能安装成功
- 代理能获取并返回网页内容
- 内容转换为可读文本

---

## TC-005-02：Google Calendar 集成

**前置条件**：已安装 Google Calendar 技能并完成 OAuth 认证

**操作步骤**：
1. 发送 "查看我今天的日程"
2. 发送 "创建一个明天下午 3 点的会议，标题为'测试会议'"
3. 发送 "删除刚才创建的测试会议"

**测试目标**：验证日历的读取、创建、删除操作

**预期结果**：
- 正确列出今日日程
- 成功创建事件，返回确认信息
- 成功删除事件

---

## TC-005-03：Gmail 集成

**前置条件**：已安装 Gmail MCP 技能并完成 OAuth

**操作步骤**：
1. 发送 "搜索最近 3 封来自 xxx@example.com 的邮件"
2. 发送 "帮我起草一封邮件给 test@example.com，主题是测试"

**测试目标**：验证邮件搜索和草稿功能

**预期结果**：
- 返回匹配的邮件列表
- 创建草稿（不自动发送）
- 草稿可在 Gmail 中查看

---

## TC-005-04：工具 deny 列表

**操作步骤**：
1. 在配置中添加 `"tools": { "deny": ["send_email"] }`
2. 发送 "帮我发一封邮件给 test@example.com"

**测试目标**：验证 deny 列表阻止敏感操作

**预期结果**：
- 代理无法执行 send_email 工具
- 代理解释该操作被禁止

---

## TC-005-05：Composio 集成

**前置条件**：已注册 Composio 并获取 Consumer Key

**操作步骤**：
1. 配置 Composio plugin（见指南）
2. 重启 Gateway
3. 发送 "使用浏览器工具访问 example.com"

**测试目标**：验证 Composio 托管 MCP 连接

**预期结果**：
- 插件成功连接到 Composio MCP Server
- 工具注册到代理
- 工具调用正常执行

---

## TC-005-06：自定义 MCP Server

**操作步骤**：
1. 执行 `openclaw skill create test-tool`
2. 编辑生成的 SKILL.md 和 server.js
3. 添加一个简单工具（如返回当前时间）
4. 重启 Gateway
5. 触发自定义工具

**测试目标**：验证自建 MCP Server 流程

**预期结果**：
- 技能模板正确生成
- 自定义工具成功注册
- 工具调用返回预期结果
