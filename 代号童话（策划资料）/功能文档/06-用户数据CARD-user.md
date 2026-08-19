# 06 · 用户数据 CARD.user（卡箱 / 卡炉）

对应文件：`card_comm_v3.js`（`CARD.user`）

`CARD.user` 管理当前玩家的用户信息，以及三种"卡容器"：**交换箱、储存箱、卡炉**。数据均来自 Flash 本体（`getFlashObj().getXxx()`），JS 侧做缓存与增删改后再写回 Flash（`updateCardWith` / `updateInfo`）。

## 1. 内部结构

```js
CARD.user = {
  mapCoffer:   {},   // 储存箱（卡柜）槽位
  mapExchange: {},   // 交换箱槽位
  mapStove:    {},   // 卡炉槽位
  oMyData:     {},   // 我的用户信息
  _bInit: false
}
```

## 2. 初始化 `CARD.user.init(bReLoad)`

```js
init: function(bReLoad){
  if (!bReLoad && CARD.user._bInit) return true;
  try {
    CARD.user.initUser();       // 用户信息
    CARD.user.initChangeBox();  // 交换箱
    CARD.user.initCofferBox();  // 储存箱
    CARD.user.initStove();      // 卡炉
  } catch(e){ setTimeout(CARD.user.init, 500); return false; }  // Flash 未就绪则重试
  CARD.user._bInit = true;
}
```

- 若 Flash 方法尚未就绪，各 `initXxx` 会 `setTimeout` 自我重试（200ms）。
- `update()` = 刷新 Flash + 重新加载；`reload()` = 仅重新加载。

## 3. 用户信息 `oMyData`

`initUser(type)`：`type=1` 取自己（`getMyUserInfo`），否则取当前查看对象（`getCurrentUserInfo`）。同时写 Cookie `versionuin`。

`oMyData` 中被代码引用到的字段（含义据用法推断）：

| 字段 | 含义 |
|------|------|
| `uin` | QQ 号 |
| `lv` | 等级 |
| `mana` | 魔力 |
| `redvip` / `yearvip` | 红钻 / 年费红钻标记 |
| `lvupbonus` | 是否有升级奖励可领 |
| `havePet` | 是否拥有精灵 |
| `missionid` | 当前任务 id |
| `missionStepId` | 当前任务步骤 |
| `missionStatus` | 任务状态（0 进行/-2 完成待提交…） |
| `curStoreBoxCardNum` | 储存箱当前卡数 |
| `curChangeBoxCardNum` | 交换箱当前卡数 |
| `curVipChangeBoxNum` | VIP 交换箱卡数 |

## 4. 三种卡容器

| 容器 | 缓存 | Flash 取数方法 | slottype |
|------|------|----------------|----------|
| 交换箱 | `mapExchange` | `getChangeBoxInfo(-1,type)` | 0 |
| 储存箱（卡柜） | `mapCoffer` | `getStoreBoxInfo(-1,type)` | 1 |
| 卡炉 | `mapStove` | `getStoveBoxInfo(-1,type)` | — |

加载交换/储存箱时，会用 `mapCard` 补全每张卡的 `themeid/name/cardpri/type` 字段。

槽位对象常见字段：`slot`（槽号）、`id`（卡 id，0=空）、`status`、`unlock`（解锁时间戳）、`lv`、`enabled`。

## 5. 槽位操作

| 方法 | 说明 |
|------|------|
| `getAvExSlots()` / `getAvCofSlots()` | 取有卡的槽位号列表 |
| `getEmptySlot(slottype)` | 取第一个空槽号（无则 -1） |
| `getEmptySlotNum(slottype)` | 空槽数量 |
| `getOpenSlotNum()` | 返回 [交换箱已开槽数, 储存箱已开槽数] |
| `clearSlot(slotid, slottype, type)` | 清空槽位并写回 Flash |
| `setCardToSlot(cardid, slotid, slottype, type, needLock)` | 放卡到槽位；`needLock` 时锁定 300 秒（`serverTime+300`） |
| `sortSlots(arr, field, sortType)` | 按字段升/降序排序 |

写回 Flash 时对 Safari 特殊处理（先 `obj2str` 序列化）：

```js
if (QSFL.userAgent.isSafari())
  CARD.getFlashObj().updateCardWith(CARD.obj2str(t), type);
else
  CARD.getFlashObj().updateCardWith(t, type);
```

## 6. 用户信息写回

```js
CARD.user.updateInfo(oData)   // 调 Flash updateInfo（Safari 下先序列化）
```

任务完成、领奖后用 `updateInfo` 把新的金币/经验/魔力/任务进度同步给 Flash 展示。

## 7. 卡容器语义小结

- **交换箱（mapExchange）**：用于和好友/市场交换的卡片暂存区。
- **储存箱 / 卡柜（mapCoffer）**：长期存卡。
- **卡炉（mapStove）**：炼制（合成）卡片的工作台，见 [10 合成配方](10-数据表结构.md) 与卡炉相关 `flashCalls`（`showStoveV3`/`showStoveUpgrade`/`showStealStoveV3`）。
```