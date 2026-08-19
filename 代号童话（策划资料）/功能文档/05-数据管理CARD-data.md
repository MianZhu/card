# 05 · 数据管理 CARD.data

对应文件：`card_comm_v3.js`（`CARD.data`）、数据表见 [10-数据表结构](10-数据表结构.md)

`CARD.data` 负责把全局数组数据表建成 **id → 记录** 的映射索引，并提供查询、图片 URL 拼接、勋章名解析、跑马灯提示等能力。

## 1. 内部映射表

| 映射 | 源数据表 | 键 | 说明 |
|------|----------|----|------|
| `mapCard` | `card_list` | card_id | 卡片 |
| `mapTheme` | `theme_card_list` | theme_id | 套卡主题 |
| `mapFlashTheme` | `theme_card_list` | flash_src_tid | 闪卡主题反查 |
| `mapCompose` | `theme_compose_list` | cardtar | 合成配方（按目标卡） |
| `mapGift` | `gift_list` | gift_id | 礼包/QQ 秀 |
| `mapProps` | `g_props_data` | prop_id | 道具 |
| `mapBadge` | `badge_list` | badge_id | 勋章 |
| `mapMyMiniCol` | 服务端 | theme_id | 我已集成的套卡数 |

## 2. 初始化 `CARD.data.init()`

```js
init: function(){
  if (CARD.data._bInit) return;
  CARD.data.initCardData();     // card_list → mapCard
  CARD.data.initComposeData();  // theme_compose_list → mapCompose
  CARD.data.initThemeData();    // theme_card_list → mapTheme / mapFlashTheme
  CARD.data.initGiftData();     // gift_list → mapGift
  CARD.data._bInit = true;
}
```

`initThemeData` 里同时判断闪卡位标记，建立闪卡主题反查表：

```js
if (CARD.checkFlashCard(theme_card_list[i][12]))
  mapFlashTheme[ theme_card_list[i][16] ] = theme_card_list[i][0];
```

`initBadgeData` / `initPropsData` 按需单独调用。

## 3. 查询方法

| 方法 | 返回 |
|------|------|
| `getCard(id)` | 卡片记录数组 |
| `getCardName(id)` | 卡片名（`card[2]`） |
| `getTheme(id)` | 套卡记录数组 |

## 4. 图片 URL 拼接

图片带 `ver` 版本号做缓存控制：

```js
getCardImgUrl(id, type)  // type=0 小图 _56 ；否则大图
  // '/card/img/card/<id>_56?ver=<card[7]>'
getThemeBgUrl(id, type)
  // '/card/img/theme/<theme[0]>?ver=<theme[13]>'
```

（`CARD.ui` 里还有 `getCardMiniImg` / `getCardBigImg` / `getThemeBigLogo` / `getThemeMiniLogo`，见 [11](11-UI与弹窗系统.md)。）

## 5. 勋章名解析 `getBadgeName`

```js
getBadgeName(iID, iRecord, live, liveEx, liveEx2, liveEx3)
```

这是 `CARD.data` 中最复杂的方法，负责根据勋章类型和玩家状态位解析勋章名与图标 URL：

- **参数 live/liveEx/liveEx2/liveEx3**：玩家节日勋章的状态位（每个勋章占 2 bit，表示金/银/铜/无）。
- **勋章类型（`badge_list[i][2]`）**：
  - `4` 套卡勋章：按 `iRecord` 取 金*/银*/铜*，名称取自套卡名。
  - `3/5/6/7` 节日勋章：按解析出的状态位取金/银/铜。
    - 类型 `7`：状态位在 `liveEx3` 中按 `cur[4]*2` 偏移取 2 bit。
    - `bid >= 1409`：从 `liveEx2` 低位取，右移 2。
    - `bid >= 948`：从 `liveEx` 低位取，右移 2。
    - 其余：从 `live` 低位取，右移 2。
  - 其他类型：直接取 `badge_list[i][1]` 名称。
- 图标 URL 前缀：`http://appimg2.qq.com/card/img/badge/<id>`（银 `_2`、铜 `_3`）。

> 细节与勋章数据表见 [08-勋章系统](08-勋章系统.md)。

## 6. 跑马灯提示 `initTipsData`

```js
initTipsData: function(){
  // GET /card/mk/tips.xml
  // 解析 <a href="..">文本</a> 列表 → arrTips[]
  // arrTipsInfo[0]=数量, [1]=当前索引, [2]=定时器句柄
}
```

配合 `CARD.showTips(type)` 轮播（5s 间隔，可上一条/下一条）。若 Flash 报告"已集齐某套卡"（`getFinishTheme`），则优先提示集齐信息。

## 7. Flash SharedObject 读写

```js
CARD.data.loadShareObj(uin, name)          // 读 Flash 本地共享对象
CARD.data.saveShareObj(uin, name, data)    // 写
```

用于持久化"每日礼物弹窗时间""PTP 弹窗时间""QQ 秀通行证时间"等标记（存在 Flash 的 LSO 里）。
```