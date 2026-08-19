# 04 · CARD 核心对象与工具方法

对应文件：`card_comm_v3.js`（`CARD` 顶层对象）

`CARD` 是游戏 JS 侧的全局主对象，聚合所有子模块。本文档只覆盖 `CARD` **顶层**的属性与工具方法；子模块见对应文档。

## 1. 核心状态属性

```js
var CARD = {
  _iUin: 0,          // 当前登录 uin
  _iOpUin: 0,        // 被操作对象 uin（好友）
  _env: "",          // 环境: qqshow / qzone
  _objFlash: null,   // 缓存的 Flash 对象引用
  _feed_load_pos: 860, // 社交记录懒加载触发滚动位置
  _feedjs_bLoad: false,
  _feedjs_handle: 0,
  _bQzone: 0,        // 是否 Qzone 环境
  _toolBarDalta: 0,  // Qzone 工具栏引起的弹窗垂直偏移
  ...
}
```

## 2. 子模块索引

| 子模块 | 职责 | 文档 |
|--------|------|------|
| `CARD.data` | 数据表建索引、卡/套卡/勋章查询、跑马灯 | [05](05-数据管理CARD-data.md) |
| `CARD.user` | 用户信息、卡箱（交换/储存）、卡炉槽位 | [06](06-用户数据CARD-user.md) |
| `CARD.elf` | 精灵等级/技能/升级弹窗 | [07](07-精灵系统.md) |
| `CARD.ui` | 弹窗渲染、卡片图片、主题选择器、验证码 | [11](11-UI与弹窗系统.md) |
| `CARD.flashCalls` | **Flash→JS 回调总入口**（各种弹窗/跳转） | [11](11-UI与弹窗系统.md)、[14](14-活动与礼包入口.md) |
| `CARD.mission` | 新手任务/成长任务状态机 | [09](09-任务系统.md) |
| `CARD.LEVEL` | 玩家等级积分换算 | [15](15-等级系统.md) |
| `CARD.props` | 道具主题常量 | 本文 §6 |
| `CARD.ptp` | 好友互动提醒（Person-To-Person） | [16](16-社交记录与消息.md) |
| `CARD.moduleDialogQueue` | 弹窗队列（避免多弹窗打架） | [11](11-UI与弹窗系统.md) |
| `CARD.dialog` | 通用提示弹窗 | [11](11-UI与弹窗系统.md) |
| `CARD.CRASH` | 网络异常兜底 | [12](12-统计与安全上报.md) |
| `CARD.XHR` | = `QSFL.sns.XHR` 请求封装 | [02](02-登录与SNS适配.md) |
| `CARD.versionFlag` | 新旧版本切换标记 | 本文 §7 |

## 3. 环境与 Flash 对象

```js
CARD.getEnv()          // 返回 qzone / qqshow（据 cookie cardsrc）
CARD.initEnvironment(env)
CARD.initFlashObj(id)  // 缓存 swf1 引用到 _objFlash
CARD.getFlashObj()     // 取 Flash 对象（懒初始化）
CARD.refresh()         // 调 Flash refresh()
CARD.scrollToFlash()   // 滚动定位到 Flash 区
```

**JS ↔ Flash 通信约定**：
- JS → Flash：`CARD.getFlashObj().<method>(...)`
- Flash → JS：`CARD.flashCalls.<method>(...)`

## 4. URL / Hash / Cookie 工具

| 方法 | 说明 |
|------|------|
| `CARD.getURLParam(name)` | 取 query 参数 |
| `CARD.setURLParam(url,name,val)` | 设 query 参数 |
| `CARD.getHashParam(name)` | 取 hash 参数 |
| `CARD.setHashParam(name,val)` | 设 hash 参数 |
| `CARD.getCookie(name,domain)` | = `QSFL.cookie.get` |
| `CARD.setCookie(...)` | = `QSFL.cookie.set` |

## 5. 动态脚本加载 `CARD.getScript`

```js
CARD.getScript(sUrl, fnLoad, charset, bCache, fnError)
```

- 自动附加 `g_tk = _hash(skey)`（防 CSRF，同 XHR）。
- `bCache=false` 时追加时间戳参数破缓存。
- 用于加载 `feed.js`、`ns.js`、`snsPtpRead_v3.js` 等。

## 6. 常量 `CARD.props`

```js
CARD.props = {
  PROPS_THEME_ID: 111,     // 道具卡所属主题 id（选主题时排除）
  UNIVERSAL_CARD_ID: 1162  // 万能卡 id
}
```

## 7. 版本标记 `CARD.versionFlag`

```js
CARD.versionFlag.setFlag(flag, callBack)
// 调 CGI card_set_flash_flag?status=<flag>，标记新/旧 Flash 版本
CARD.isNewVersion = (flag == 1);
```

配合页面导航 `goToV3()` / `CARD.flashCalls.goToV4()` 做新旧版本切换。

## 8. 通用工具函数

| 方法 | 说明 |
|------|------|
| `CARD.getType(obj)` | 精确类型判断（null/undefined/array/...） |
| `CARD.obj2str(obj)` | 对象序列化为 JSON 字符串（Safari 下传 Flash 用） |
| `CARD.getTimeString(ts)` | 时间戳 → `YYYY-M-D` |
| `CARD.checkFlashCard(bitmap)` | 位标记 `&0x08` 判断是否闪卡 |
| `CARD.checkJbCard(bitmap)` | 位标记 `&0x01` 判断是否绝版卡 |
| `CARD.uniqueArray(arr)` | 数组去重（`CARD.data` 下） |

## 9. 位标记约定（套卡 bitmap = `theme_card_list[i][12]`）

| 位 | 含义 |
|----|------|
| `& 0x01` | 绝版卡（JbCard） |
| `& 0x02` | （在主题筛选中用于过滤） |
| `& 0x04` | （闪卡筛选中排除项） |
| `& 0x08` | 闪卡（FlashCard） |

用于 `CARD.ui.showSelectTheme` 中把套卡分为"发行套卡 / 绝版套卡 / 闪卡"三类。
```