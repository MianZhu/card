# 客户端

Godot 4 客户端工程。`project.godot` 位于本目录，因此请使用 Godot 导入 `代号童话项目/client/`。

- `assets/`：游戏运行时直接加载的切图、图标、动画、音频、字体和 Shader。
- `scenes/`：按功能域组织的 Godot 场景。
- `scripts/autoload/`：会话、网络、配置和事件等全局服务。
- `scripts/domain/`：卡牌、套卡、配方等领域模型。
- `scripts/features/`：首页、收藏、炼制、市场、任务和社交功能。
- `scripts/infrastructure/`：HTTP、WebSocket、本地持久化和资源加载。
- `resources/`：Godot `.tres`、`.res` 等资源。
- `tests/`：客户端自动化测试。

参考资料不得复制到 `assets/`。只有游戏正式使用并具有明确来源的导出资源才能放入该目录。
