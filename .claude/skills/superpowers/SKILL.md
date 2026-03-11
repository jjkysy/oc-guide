---
name: superpowers
description: 增强 OpenClaw 代理的系统操作能力，包括文件管理、进程监控和网络工具
version: 1.2.0
author: OpenClaw Community
source: https://github.com/VoltAgent/awesome-openclaw-skills
license: MIT
requires:
  bins: [curl, jq]
  permissions: [filesystem, network]
tags: [system, utility, productivity]
triggers:
  - "系统信息"
  - "磁盘空间"
  - "进程列表"
  - "网络状态"
---

# Superpowers 技能

增强代理的系统操作能力。

## 能力

### 系统信息
当用户询问系统信息时，收集并返回：
- 操作系统版本和架构
- CPU 使用率和内存使用情况
- 磁盘空间使用率
- 网络连接状态

### 文件操作增强
- 批量重命名文件
- 目录大小统计
- 文件内容搜索

### 进程管理
- 列出运行中的进程
- 按 CPU/内存排序
- 查找特定进程

## 安全约束

- 不执行任何删除操作（除非用户明确确认）
- 不修改系统关键文件（/etc, /usr, /System）
- 不终止系统进程
- 所有操作先预览再执行

## 使用示例

用户: "查看当前磁盘使用情况"
→ 执行 df -h，以表格形式返回各分区使用率

用户: "找出占用内存最多的 5 个进程"
→ 执行 ps 命令，排序返回前 5 个
