---
name: skill-creator
description: 辅助创建新的 OpenClaw 技能，生成 SKILL.md 模板和目录结构
version: 1.0.0
author: OpenClaw Community
source: https://github.com/VoltAgent/awesome-openclaw-skills
license: MIT
requires:
  bins: []
  permissions: [filesystem]
tags: [development, meta, utility]
triggers:
  - "创建技能"
  - "新建技能"
  - "create skill"
---

# Skill Creator 技能

帮助用户创建新的 OpenClaw 技能。

## 工作流程

当用户要求创建新技能时：

### 1. 收集信息
询问以下信息（如果用户未提供）：
- 技能名称（英文，kebab-case）
- 技能描述（一句话说明功能）
- 需要的系统工具（bins）
- 需要的权限（filesystem, network, etc.）
- 触发关键词

### 2. 生成目录结构
```
<skill-name>/
├── SKILL.md          # 技能定义文件
└── README.md         # 技能使用说明（可选）
```

### 3. 生成 SKILL.md
使用以下模板：

```markdown
---
name: <skill-name>
description: <description>
version: 1.0.0
author: <user>
requires:
  bins: [<required-bins>]
  permissions: [<required-permissions>]
tags: [<tags>]
triggers:
  - "<trigger-1>"
  - "<trigger-2>"
---

# <Skill Name>

<detailed instructions>

## 安全约束

- <safety rules>

## 使用示例

<examples>
```

### 4. 安全审查提示
生成后提醒用户：
- 审查生成的 SKILL.md 内容
- 检查权限要求是否合理
- 建议先在沙箱中测试
- 使用 `openclaw security audit` 验证

## 注意事项

- 自动生成的技能通常需要手动调整边界条件
- 不要过度授权，遵循最小权限原则
- 每个技能应有明确的安全约束部分
