# 009 - 故障排查与注意事项

> 常见问题、排错流程、使用注意事项汇总。

## 通用排错工具

```bash
# 万能诊断命令 — 自动检测并修复常见问题
openclaw doctor

# 查看详细日志
openclaw logs --tail 100

# 查看 Gateway 状态
openclaw status

# 验证配置文件
openclaw config get

# 安全检查
openclaw security audit --fix

# 沙箱状态
openclaw sandbox explain
```

> **原则**：遇到问题先跑 `openclaw doctor`，它能解决大部分常见问题。

---

## 常见问题与解决方案

### 1. 安装相关

#### Q: `brew install openclaw` 失败

```bash
# 更新 Homebrew
brew update

# 清理缓存
brew cleanup

# 重新安装
brew tap openclaw/tap
brew install openclaw
```

#### Q: npm 安装时出现 EACCES 权限错误

```bash
# 不要使用 sudo！修复 npm 目录权限
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
source ~/.zshrc
npm install -g openclaw
```

#### Q: Docker 容器启动后立即退出

```bash
# 查看日志
docker compose logs openclaw

# 最常见原因：API Key 缺失或格式错误
# 检查 .env 文件
cat .env

# 确认环境变量正确传递
docker exec openclaw env | grep API_KEY
```

### 2. 配置相关

#### Q: Gateway 拒绝启动，报 "unknown key" 错误

OpenClaw 配置采用严格验证，未知键会导致启动失败。

```bash
# 查看具体哪个键不被识别
openclaw doctor

# 备份当前配置
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak

# 删除问题键
openclaw config unset <unknown_key>
```

#### Q: 修改配置后没有生效

大部分配置支持热重载，但以下例外需要重启：

- `gateway.reload`
- `gateway.remote`

```bash
# 重启 Gateway
openclaw stop && openclaw start
```

#### Q: `contextWindow` 设置报错

Gateway 有硬性最低 16,000 的 `contextWindow` 检查：

```json5
{
  "agents": {
    "defaults": {
      "contextWindow": 200000    // 最小值 16000
    }
  }
}
```

#### Q: v2026.2.25 之后出现 Gateway 错误

已知问题：需要手动修复 `~/.openclaw/openclaw.json` 中的 `gateway.controlUi.allowedOrigins`：

```json5
{
  "gateway": {
    "controlUi": {
      "allowedOrigins": ["http://localhost:18789"]
    }
  }
}
```

### 3. API 与模型相关

#### Q: Claude 工具调用返回 400 错误

必须使用 `anthropic-messages` 格式：

```json5
{
  "agents": {
    "defaults": {
      "api": "anthropic-messages"    // 不要用 "openai-completions"
    }
  }
}
```

#### Q: DeepSeek API 配置不生效

DeepSeek API Key 应放在 `auth-profiles.json` 中，**不是** `openclaw.json`：

```bash
# 正确位置
cat ~/.openclaw/auth-profiles.json
```

#### Q: 模型返回空响应或超时

```bash
# 检查 API Key 是否有余额
# 检查网络连接
curl -s https://api.anthropic.com/v1/messages -H "x-api-key: $ANTHROPIC_API_KEY" | head

# 检查是否设置了回退模型
openclaw config get agents.defaults.fallback
```

### 4. 通讯平台相关

#### Q: Telegram Bot 不响应消息

1. 确认 Bot Token 正确
2. 确认 `channels.telegram.enabled` 为 `true`
3. 确认 DM 策略允许你的用户名
4. 检查 Gateway 是否在运行

```bash
openclaw status
openclaw logs --tail 20 | grep telegram
```

#### Q: WhatsApp QR 码扫描后断开

WhatsApp 使用非官方协议，连接可能不稳定：

1. 重启 Gateway
2. 重新扫描 QR 码
3. 确认手机 WhatsApp 保持联网
4. 考虑使用独立手机号

#### Q: 多平台消息不同步

确认身份已绑定：

```bash
openclaw user list
openclaw user bind telegram:@your_name whatsapp:+861381234xxxx
```

### 5. 沙箱与安全相关

#### Q: 技能在沙箱中报 "binary not found"

技能需要的二进制文件必须同时存在于宿主机和容器中：

```json5
{
  "sandbox": {
    "docker": {
      "setupCommand": "apt-get update && apt-get install -y <missing-binary>"
    }
  }
}
```

#### Q: 沙箱中网络不通

默认沙箱可能限制网络：

```json5
{
  "sandbox": {
    "docker": {
      "networkAccess": true    // 允许网络访问
    }
  }
}
```

#### Q: Docker 沙箱中无法安装包

需要满足三个条件：
1. 网络出口已开启（`networkAccess: true`）
2. 根文件系统可写
3. 容器内有 root 权限

### 6. 记忆相关

#### Q: 代理"忘记"了之前的对话

检查是否因上下文压缩导致信息丢失：

```bash
# 检查记忆文件
ls -la ~/.openclaw/memory/
cat ~/.openclaw/agents/default/MEMORY.md
```

**预防措施**：重要指令写入 SOUL.md 或 MEMORY.md，不要只在对话中口述。

#### Q: 记忆搜索返回不相关结果

调整搜索参数：

```json5
{
  "memory": {
    "search": {
      "halfLife": 30,    // 时间衰减半衰期（天），默认 30
      "topK": 10         // 返回结果数
    }
  }
}
```

---

## 排错流程图

```
问题出现
  │
  ├──► openclaw doctor（自动诊断）
  │     └── 解决？ → 完成
  │
  ├──► openclaw logs（查看日志）
  │     └── 找到错误信息？ → 搜索本文对应章节
  │
  ├──► openclaw status（检查状态）
  │     └── Gateway 未运行？ → openclaw start
  │
  ├──► openclaw config get（检查配置）
  │     └── 配置异常？ → 对比本指南模板
  │
  └──► 社区求助
        ├── GitHub Issues: github.com/openclaw/openclaw/issues
        ├── Discord 社区
        └── 提供：版本号、操作系统、错误日志、配置（隐去密钥）
```

---

## 使用注意事项

### 关于 API 费用

- 代理在自主模式下可能产生大量 API 调用
- 设置账单告警和每月预算限制
- 建议在 Anthropic Console 设置 Usage Limits
- 使用 Haiku 处理简单任务可显著降低成本

### 关于隐私

- OpenClaw 是自托管的，数据不会发送到第三方
- **但** API 调用会将对话内容发送到模型提供商
- 敏感信息不要直接在对话中提及
- 考虑使用本地模型处理敏感任务

### 关于可靠性

- 不要让代理独自处理不可逆操作（删除、发送、支付）
- 定期检查代理的行为日志
- 新技能先在沙箱中测试
- 保持 `openclaw doctor` 定期运行的习惯

### 关于更新

- 更新前先备份 `~/.openclaw/`
- 查看 [Release Notes](https://github.com/openclaw/openclaw/releases) 了解破坏性变更
- 更新后立即运行 `openclaw doctor`
- Docker 用户：`docker compose pull && docker compose up -d`

## 下一步

进入 [010 - 使用场景与用户旅程](010-usage-scenarios.md) 查看具体的使用案例。

## 参考来源

- [OpenClaw 官方入门指南](https://docs.openclaw.ai/start/getting-started)
- [LumaDock - CLI 与配置参考](https://lumadock.com/tutorials/openclaw-cli-config-reference)
- [OpenClaw GitHub Issues](https://github.com/openclaw/openclaw/issues)
- [Open-Claw.me - 从入门到中级完整指南](https://open-claw.me/blog/openclaw-complete-guide-beginner-to-intermediate)
