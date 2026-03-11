# 测试用例：004 - 通讯软件配置

> 对应指南 [004 - 通讯软件配置](../guide/004-messaging-platforms.md)

## TC-004-01：Telegram Bot 创建与连接

**操作步骤**：
1. 在 Telegram 中找到 @BotFather，发送 `/newbot`
2. 按提示设置名称和用户名
3. 将 Bot Token 配置到 `openclaw.json`
4. 启动 Gateway
5. 在 Telegram 中找到新创建的 Bot，发送 "测试"

**测试目标**：验证 Telegram 端到端连接

**预期结果**：
- Bot 在数秒内回复
- 首次对话触发配对验证流程
- 配对后正常对话

---

## TC-004-02：Telegram DM 策略 - allowlist

**前置条件**：Telegram Bot 已配置

**操作步骤**：
1. 设置 `dmPolicy` 为 `allowlist`
2. 设置 `allowFrom` 为 `["@your_username"]`
3. 使用白名单中的账号发送消息
4. 使用不在白名单中的账号发送消息

**测试目标**：验证白名单访问控制

**预期结果**：
- 白名单用户正常收到回复
- 非白名单用户的消息被忽略或收到拒绝提示

---

## TC-004-03：WhatsApp QR 配对

**前置条件**：Gateway 配置了 WhatsApp 通道

**操作步骤**：
1. 启动 Gateway
2. 在终端中观察 QR 码输出
3. 用手机 WhatsApp → 设置 → 关联设备 → 扫描 QR 码
4. 发送测试消息

**测试目标**：验证 WhatsApp 配对和消息通讯

**预期结果**：
- QR 码正常显示
- 扫描后显示连接成功
- 消息正常收发

---

## TC-004-04：Discord Bot 连接

**前置条件**：已创建 Discord Application 和 Bot

**操作步骤**：
1. 配置 Discord Bot Token
2. 邀请 Bot 到测试 Server
3. 启动 Gateway
4. 在 Discord Server 中 @Bot 发送消息

**测试目标**：验证 Discord 集成

**预期结果**：
- Bot 显示为在线
- @提及后 Bot 回复
- DM 渠道正常工作

---

## TC-004-05：Signal 连接

**前置条件**：已安装 signal-cli

**操作步骤**：
1. 执行 `signal-cli link -n "OpenClaw Agent"`
2. 用 Signal App 扫描链接
3. 配置 OpenClaw Signal 通道
4. 发送测试消息

**测试目标**：验证 Signal 集成（实验性）

**预期结果**：
- signal-cli 成功关联
- 消息正常收发
- 端到端加密正常工作

---

## TC-004-06：多平台身份绑定

**前置条件**：至少两个平台已配置

**操作步骤**：
1. 在 Telegram 上开始一个话题对话
2. 执行 `openclaw user bind telegram:@name whatsapp:+86138xxxx`
3. 在 WhatsApp 上继续同一话题

**测试目标**：验证跨平台会话连贯性

**预期结果**：
- 代理在 WhatsApp 上能引用 Telegram 的对话上下文
- 用户身份正确关联

---

## TC-004-07：群组策略

**前置条件**：Bot 已加入群组

**操作步骤**：
1. 设置 `groupPolicy` 为 `disabled`
2. 在群组中 @Bot 发送消息
3. 改为 `allowlist` 并添加群组 ID
4. 再次在群组中 @Bot 发送消息

**测试目标**：验证群组访问控制

**预期结果**：
- `disabled` 时不响应群组消息
- `allowlist` 且群组在列表中时正常响应
