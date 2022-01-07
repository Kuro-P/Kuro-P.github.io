---
title: H5 与 App 之间的交互
date: 2021-04-12 16:10:08
tags: [App, Webview, 交互]
categories: [前端]
---
遗留了很久的一个学习任务，最近正好在总结归纳小程序在 App 之间的交互，顺便拾起一些学过的和没学过的知识。主要涉及的知识点：URL Scheme、Webview、H5 与 App 之间的通信以及 JSBridge 的概念。
<!-- more -->

## H5 唤起 App

### 唤起方式
__H5 可以通过 location.href、iframe、a 标签三种方式来调用 URL Scheme 来实现唤起 App。__
URL Scheme 是系统提供的一种机制，它可以由应用程序注册，然后其他程序通过 URL Scheme 来调用该应用程序，其基本格式为 __`scheme://[path][?query]`__。
* __scheme__：应用标识，已安装的APP注册在系统中的标识；
* __path__：应用行为，表示应用某个页面或功能；
* __query__：应用参数，标识应用页面或者应用功能所需的条件参数；
但是此方式无法得知 App 是否唤起成功，有可能存在 App 未下载的情况。通常用计时器，监听页面是否已隐藏（监听页面 visibilityChange），若未曾隐藏则认为打开失败，再根据不同的平台跳转不同的渠道下载页。

除此之外，还有一种链接叫：__Universal Link (通用链接)__， 是 Apple 在 iOS9 推出的一种能够通过 HTTPS 链接来启动 APP 的功能。当应用支持此链接时，则会无缝跳转到 APP，而不需要其他判断；但需要注意的是，这个链接是可以访问的，直接在浏览器中打开并不会跳转 App，需要跨域访问才可以。

一个完善的唤起流程如下：
```flow
st=>start: 调用唤起 App 的方法
op1=>operation: 页面打开与 App 约定好的 URL
op2=>operation: 用定时器监听 visibilityChange 事件
c1=>condition: 页面是否隐藏
op3=>operation: 调起失败
op4=>operation: 判断当前 webview 平台
op5=>operation: 跳转到对应渠道下载页面
op6=>operation: 调起成功
e=>end: 页面的其他逻辑操作

st->op1->op2->c1
c1(no)->op3->op4->op5
c1(yes)->op6->e
```

### 若在小程序的 Webview 中尝试唤起 App 会怎么样？
（以下的逻辑参照上图的流程）
由于微信拦截了 URL Scheme，所以并不会打开 App；此时就会判断 Webview 环境，跳转对应的下载页：
如：在 Mac 上的开发者工具中会跳转 App Store：

<img src="/IOS.png" width="400"/>

而在安卓手机的微信小程序中则会跳转（腾讯的安装渠道）：

<img src="/Android.png" width="400"/>

但是由于这两个地址的域名都没有在微信后台配置，所以都会被微信认成不可信的域名，只会跳转到一个空白页面，然后提示域名不可信。


PS：主要禁止的原因是，小程序不允许将流量导出到 APP 之外；
2021.4.12 不过网上还有一种说法就是将 App 关联到腾讯的应用宝上，到时候就会自己跳转到 App Store （[参考](https://www.zhihu.com/question/24029212)）
2021.4.13 经验证，此方法不可行，在信任应用宝域名的前提下(sj.qq.com)，依旧无法唤起下载/跳转：
* 安卓表现为停止在当前 H5 并提示使用浏览器打开；
* IOS 表现为卡在当前 H5，点击下载按钮无反应；


## H5 与 App 之间的通信
### 关于 Webview 能力
Webview 是 Android / IOS 操作系统的一个组件，它可以让应用程序直接显示网页内容。
它提供了很多能力，其中最重要的一项就是 __添加 JS 和执行 JS__ 的能力。H5 与 App 之间的通信正是依赖于此。

还有很多通用能力如 __注入 Cookie__、__添加/移除响应头__、__监听页面返回操作__，__拦截 Url__，__拦截弹窗__、获取/放置证书、监听下载事件 等等。更多 API 可以查阅 [官方文档](https://developer.android.com/reference/android/webkit/WebView)

### 通信方式
通信过程主要依赖 Webview 提供的 JS API，可以简单的看成两个方向：
* App 调用 JS 代码
* JS 调用 App 代码

接下来示例的方法均以 Android API 为例。
#### App 调用 JS 代码
在 Webview 中是可以获取到 window 对象的，所以 App 可以访问挂载在全局对象上的方法。只需告知 App 方法名即可。
Andiroid 中使用这两个方法执行 JS：
* 使用 WebView 的 __`loadUrl()`__ 方法：参数 为 js 文件路径;
* 使用 WebView 的 __`evaluateJavascript()`__ 方法：参数为 js 方法名，以及回调函数；

#### JS 调用 App 代码
JS 调用 App 代码主要有两种方式，一种是页面发起行为，App __拦截__ 行为解析语义响应操作；另一种是 App 提前将方法映射成 JS，__注入__ 到 window 对象上供 JS 调用。

* 通过 WebChromeClient 的 __`onJsAlert()`__、__`onJsConfirm()`__、__`onJsPrompt()`__ 方法回调 __拦截 JS 对话框__ `alert()`、`confirm()`、`prompt()` 消息；
  * 得到消息内容后解析，再做相应的处理；
* 通过 WebViewClient 的 __`shouldOverrideUrlLoading()`__ 方法回调 __拦截 url__；
  * 一般使用这种方法拦截事先约定好 URL Scheme 上的挂载参数，再执行不同的逻辑；
* 通过 WebView 的 __`addJavascriptInterface()`__ 进行对象映射；
  * 此方法可以将 Java 对象映射映射成 JS 对象，JS 直接调用即可。


### 关于 JS Bridge
JS Bridge 只是 Native 和 H5 交互方案的一种统称，犹如它的名字一样，Webview 和 H5 将 JS 用作沟通的桥梁。它赋予了 JavaScript 操作 Native 的能力，同时也给了 Native 调用 JavaScript 的能力。上述的通信方案都可以称之为 JS Bridge 的实现。

### 联调注意事项
1. 同一方法，若确定方法名、参数等没有问题，但是调用结果与预期不一致，注意同时对比 IOS 端和 Android 端表现是否一致，若表现不一致，则应找对应的同学去修改；
2. 注意测试 App 版本号，以及 H5 中引用的 sdk 版本号，排查问题时考虑是否是版本过旧导致的；
3. 对于用作工具的测试页面出现问题，即时反馈，有可能是测试页面未更新。

### 参考链接
* [Android：你要的WebView与 JS 交互方式 都在这里了](https://blog.csdn.net/carson_ho/article/details/64904691)
* [h5 与原生 app 交互的原理](https://segmentfault.com/a/1190000016759517)
* [In-depth Profiling of JSBridge](https://alibaba-cloud.medium.com/in-depth-profiling-of-jsbridge-63dc797f8c77)
* [Android Build Version](https://developer.android.com/reference/android/os/Build.VERSION)