# 游戏配置数据

用于卡牌、套卡、合成配方、任务、等级、奖励和运营活动等结构化配置。

- `source/spreadsheets/`：策划人工维护的 Excel 源表，是配置的唯一编辑入口。
- `schemas/`：字段类型、主键、引用关系和业务约束。
- `generated/client/`：客户端使用的导出数据。
- `generated/server/`：服务端使用的导出数据。

生成目录中的文件必须由 `tools/` 自动产生，禁止手工修改。图片、音频和动画不属于游戏配置数据，应放在 `client/assets/`。
