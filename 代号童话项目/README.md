# 代号童话

基于 Godot 4 的社交集卡游戏。仓库采用完整单仓库结构，统一管理客户端、服务端、共享协议、策划数据和开发工具。

## 目录

| 目录 | 职责 |
|---|---|
| `client/` | Godot 客户端场景、脚本及运行时资源 |
| `server/` | Node.js + TypeScript + Fastify 服务端 |
| `shared/` | 前后端共享的 API 契约、数据结构和错误码 |
| `game-data/` | 策划源表、校验规则和导出数据 |
| `tools/` | 数据导出、配置校验和资源检查工具 |
| `art-source/` | 正式美术制作源文件，不存放参考资料 |
| `docs/` | 项目架构、玩法设计和开发规范 |
| `deploy/` | 本地、测试及生产环境部署定义 |

仓库根部的 `代号童话（策划资料）/` 是竞品参考和逆向资料，不得成为正式游戏的运行依赖。

## 数据流水线

```text
game-data/source/spreadsheets
  -> tools 校验和导出
  -> game-data/generated/client + game-data/generated/server
  -> 客户端和服务端加载
```

Excel 是人工维护的配置源。客户端和服务端只读取经过校验的生成数据，避免两端规则不一致。

## 美术资源流水线

```text
art-source（PSD、Spine、Blender 等）
  -> 导出
  -> client/assets（PNG、WebP、音频、动画数据等）
  -> Godot 导入
```

Godot 的 `.godot/` 导入缓存和构建产物不提交到 Git。
