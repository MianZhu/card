# 02 · 登录与 SNS 适配层

对应文件：`app_sns.js`、`api.js`、`card_comm_v3.js`（登录/登出相关方法）

## 1. SNS 适配层 `QSFL.sns`（app_sns.js）

游戏运行在两种宿主，登录态/弹窗/请求的实现不同，`app_sns.js` 用**适配器模式**统一接口：

```js
var _model = window.QZONE && window.QZONE.FrontPage ? 1 : 0;   // 1=Qzone 0=QQ秀
var _inner = _model ? QSFL.sns._qzone_ : QSFL.sns._qqshow_;
// 对外暴露统一接口，内部指向对应实现
QSFL.sns.getLoginUin      = _inner.getLoginUin;
QSFL.sns.checkLogin       = _inner.checkLogin;
QSFL.sns.showModalDialog  = _inner.showModalDialog;
QSFL.sns.closeDialog      = _inner.closeDialog;
QSFL.sns.getApplicationWindow = _inner.getApplicationWindow;
```

| 方法 | Qzone (`_qzone_`) | QQ 秀 (`_qqshow_`) |
|------|-------------------|--------------------|
| `getLoginUin` | 固定/取容器 uin | `QSFL.excore.getUin()` |
| `checkLogin` | `window.g_iLoginUin` | 校验 uin cookie 合法性 |
| `showModalDialog` | `QZONE.FP.popupDialog` | `QSFL.dialog.messageBox`（居中计算） |
| `closeDialog` | `QZONE.FP.closePopup` | `messageBox.onClose` |

> 注：存档中 `_qzone_.getLoginUin` 返回固定值 `1125000300`（离线存档的占位；线上为容器实际返回值）。

## 2. 统一请求封装 `QSFL.sns.XHR`

所有服务端 CGI 请求都经此封装，核心是**自动附加 g_tk 令牌**（防 CSRF）：

```js
function _hash(str){                       // DJB 变体哈希
  var hash = 5381;
  for (var i=0; i<str.length; ++i) hash += (hash<<5) + str.charCodeAt(i);
  return hash & 0x7fffffff;
}
function getToken(){ return _hash(QSFL.cookie.get("skey")); }   // g_tk = hash(skey)
```

- 默认 `POST`（问号后参数作为 body），可指定 `GET`。
- 请求 URL 自动追加 `?g_tk=<token>`。
- `CARD.XHR = QSFL.sns.XHR`，全项目复用。

## 3. Qzone 奖励条 Hotbar（api.js + SNSAPI）

`SNSAPI.hotbar.draw(contentID, APPID, platformID, callback)`：在 Qzone 中渲染顶部"奖励工具栏"。

- 灰度控制：非白名单 App 先请求 `/cgi-bin/rewards/rewards_policy` 判断是否命中灰度，命中才渲染 `<iframe>` 加载 `rewards_toolbar`。
- 白名单老 App（353/358/372/21641）直接渲染。
- 域名：Qzone → `rewards.qq.com`，朋友网 → `rewards.pengyou.com`。

页面初始化时：

```js
if (inQzone == 1){
  SNSAPI.hotbar.draw("sns_toolbar", 365, "qzone", function(){
    haveToolBar = false;
    CARD.initToolBarDalta(haveToolBar);   // 无工具栏时弹窗 top 偏移 -70
  });
}
```

## 4. 登录 `CARD.showLogin()`

```js
showLogin: function(){
  QSFL.sns.getApplicationWindow().QSFL.dialog.mask.end([window]);
  return QSFL.sns.getApplicationWindow().QSFL.sns.showLogin.apply(QSFL.sns, arguments);
}
```

- IE6 未登录时（页面尾部脚本）直接跳转：
  `https://xui.ptlogin2.qq.com/cgi-bin/xlogin?appid=1600000084&s_url=...index_v3.html`
- `checkLogin()` = `QSFL.sns.checkLogin()`。

## 5. 登出 `CARD.myLogout()`

重新初始化并清除全部游戏相关 Cookie，然后按平台跳回首页：

```js
myLogout: function(){
  CARD.initIndex();
  var iPlatform = CARD.getCookie("cardsrc");
  // 逐项清除：uin, skey (域 qq.com)
  //           cardsrc, cardnick, cardlv, yearvip, flaversion, versionuin (域 appimg2.qq.com)
  //           QSUSRINF, viprank
  if (1 == iPlatform) location.href = "...index_v3.html?qzone=1";
  else                location.href = "...index_v3.html";
}
```

清除的 Cookie 含义：

| Cookie | 含义 |
|--------|------|
| `uin` / `skey` | QQ 登录态 |
| `cardsrc` | 来源平台（1=Qzone） |
| `cardnick` | 缓存昵称 |
| `cardlv` | 缓存等级 |
| `yearvip` | 年费红钻标记 |
| `flaversion` | Flash 版本（3/4） |
| `versionuin` | 版本关联 uin |
| `viprank` | 红钻等级 |

## 6. 昵称显示

- `getNickAtUin()` → 调 Flash `getNickAtUin(uin)` 取昵称。
- `setTopfraName()` → 取昵称写入 Cookie `cardnick`，再 `setMiniName()` 渲染到 `#SPAN_NICK`（做 XSS 转义 `escHtml`）。
- `getQQShowPassport()` → 通过 Flash SharedObject 读取"QQ 秀通行证"剩余天数，写入 `#SPAN_QQSHOW_PASS`。

## 7. 注册相关

| 方法 | 说明 |
|------|------|
| `CARD.showReg()` | 跳 `register_v3.html` |
| `CARD.flashCalls.showReg()` | 调 CGI `card_user_register`（Qzone 带 `qz_invite`） |
| `CARD.flashCalls.showRegStep()` | 弹注册第二步 `register2_v3.html` |
| `CARD.RegisterCallback(code, oDate)` | 注册结果回调：`-1001` 未登录→登录；`-1005` 回首页；其他→注册页 |
| `CARD.showParkerReg(uin)` | 园区（park）注册弹窗 `parkreg.html` |
```