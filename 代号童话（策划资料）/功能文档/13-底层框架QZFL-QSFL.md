# 13 · 底层框架 QZFL / QSFL

对应文件：`core.js`（1396 行）、`card_comm_v3.js`（`QZFL.JSONGetter`）

`QZFL`（QZone Frontend Library）/ `QSFL` 是腾讯 QQ 空间的前端基础库，为游戏提供 DOM、事件、样式、Cookie、XHR、JSONP、对话框、UA 检测等能力。游戏代码大量依赖它。本文档概述常用命名空间，非逐 API 详解。

## 1. 命名空间初始化（core.js 开头）

```js
if (typeof QSFL == "undefined") var QSFL = {};
window.QZFL = window.QZFL || {};
if (typeof QZONE == "object") QZFL = QZONE;
else window.QZONE = QZFL = {};
QZFL.version = "2.0.6.3";
```

- `QZFL` 与 `QZONE` 指向同一对象（Qzone 环境下复用容器命名空间）。
- `QSFL` 是集卡游戏侧的别名/扩展（`QSFL.sns` 在 app_sns.js 中定义）。

## 2. 主要子模块

| 命名空间 | 能力 |
|----------|------|
| `QZFL.userAgent` | 浏览器/OS 检测：`ie`/`firefox`/`chrome`/`safari`/`opera`/`webkit`/`windows`/`macs`。派生 `ua.isIE()`/`isIE6()`/`isFireFox()`/`isSafari()` |
| `QZFL.object` | `map`/`extend`（深浅拷贝）/`each`/`getType`/`route`/`bind` |
| `QZFL.dom` | DOM 操作：`get`/`getById`/`removeElement`/`createElementIn`/`getStyle`/`setStyle`/`getXY`/`getSize`/`getScrollTop`/`getClientHeight` 等 |
| `QZFL.css` | 类名操作：`hasClassName`/`addClassName`/`removeClassName`/`toggleClassName`/`insertCSSLink`/`getRuleBySelector` |
| `QZFL.event` | 事件绑定：`addEvent`/`removeEvent`，`KEYS` 常量 |
| `QZFL.string` | 字符串工具：`trim`/`escString` 等（含 `escHtml`/`escNone`/`escScript`/`escUrl`/`asclen` 原型扩展） |
| `QZFL.lang` | 类型判断：`isArray`/`isString`/`isElement` |
| `QZFL.cookie` (`QSFL.cookie`) | `get`/`set`（支持域/过期/路径） |
| `QZFL.console` | `print`（包装 console.log） |
| `QZFL.JsLoader` | 动态 `<script>` 加载器 |

## 3. 配置 `QZFL.config`

```js
QZFL.config = {
  defaultDataCharacterSet: "GB2312",
  DCCookieDomain: "qzone.qq.com",
  domainPrefix: "qq.com",
  gbEncoderPath: "https://imgcache.qq.com/qzone/v5/toolpages/",
  staticServer: "https://imgcache.qq.com/ac/qzone/qzfl/lc/"
}
```

## 4. XHR / JSONP

| 能力 | 说明 |
|------|------|
| `QSFL.xhr.XHR` | 底层 XMLHttpRequest 封装 |
| `QSFL.xhr.getXml` | 拉 XML（多数 CGI 返回 XML `<QQHOME code=...>`） |
| `QSFL.sns.XHR` | 业务请求封装（自动加 g_tk，见 [02](02-登录与SNS适配.md)） |
| `QZFL.JSONGetter` | **跨域 JSONP 获取器**（card_comm 末尾定义） |

### `QZFL.JSONGetter`（跨域 JSON）
定义在 `card_comm_v3.js` 末尾，实现了兼容各浏览器的跨域 JSONP：
- 老 IE（<10）用 `document.createElement("script")` + `documentFragment`。
- 其他浏览器用 **动态 iframe** 内写 `<script>` 拉数据，回调经 `frameElement.callback` 回传（绕过跨域）。
- 支持超时（默认 5s）、成功/失败队列、字符集（默认 GB2312）。

## 5. 对话框 `QSFL.dialog`

| 能力 | 说明 |
|------|------|
| `QSFL.dialog.messageBox` | 模态弹窗（iframe 承载页面），`CARD.showModalDialog` mode=1 底层 |
| `QSFL.dialog.mask` | 遮罩层 `show/hide/end` |
| `QSFL.dialog.process` | loading 进度提示 |

## 6. 字符串原型扩展（游戏依赖）

代码里频繁用到的 String 原型方法（由 QZFL 扩展）：

| 方法 | 作用 |
|------|------|
| `.escHtml()` | HTML 转义（防 XSS） |
| `.escNone()` | 反转义/占位处理（innerHTML 前用） |
| `.escScript()` | 脚本转义（序列化用） |
| `.escUrl()` | URL 编码 |
| `.asclen()` | ASCII 长度（验证码校验） |

## 7. JsonTools 数据渲染

```js
QSFL.jsontools.showJsonData(xData, oParent, sHtml, mapName, bi, ei, ne)
// CARD.showCardData / 全局 showCardData 的底层，把数据按模板渲染进容器
```

## 8. Qzone 容器 API `fusion2`

Qzone 应用容器提供：

| API | 作用 |
|-----|------|
| `fusion2.canvas.setHeight({height})` | 自适应 iframe 高度 |
| `fusion2.api.sendRequest(param)` | 发送好友请求/分享（撒礼、邀请） |

## 9. 依赖关系图

```
core.js (QZFL/QSFL 基础)
   ↓
app_sns.js (QSFL.sns 适配层)
   ↓
card_comm_v3.js (CARD 业务逻辑，依赖上面全部)
   ↓
card_info_v3.js / badge_info_v3.js (纯数据)
```
```