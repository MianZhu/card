# 服务端

计划采用 Node.js、TypeScript 和 Fastify，以模块化单体方式开发。

业务模块按领域拆分为账号、用户、卡牌、收藏、炼制、市场、任务和社交。模块之间通过明确接口协作，不直接跨模块访问内部数据。

- `src/app/`：应用启动、插件注册和路由组装。
- `src/modules/`：业务领域模块。
- `src/infrastructure/`：PostgreSQL、Redis、日志和定时任务适配。
- `src/shared/`：仅服务端内部共享的基础能力。
- `migrations/`：数据库迁移。
- `tests/`：服务端测试。

真实密钥和环境配置不得提交。后续初始化服务端时只提交 `.env.example`。
