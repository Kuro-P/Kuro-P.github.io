---
title: H5 与 App 之间的交互
date: 2021-04-12 16:10:08
tags: [App, Webview, 交互]
categories: [前端]
---
遗留了很久的一个学习任务，最近正好在总结归纳小程序在 App 之间的交互，顺便拾起一些学过的和没学过的知识。主要涉及的知识点：URL Scheme、Webview、H5 与 App 之间的通信以及 JSBridge 的概念。
<!-- more -->

### 一、H5 与 App 之间的通信
#### 1. JS Bridge
Webview 是原生 App 的组件，它可以向当前网页内容 __添加和执行 JS__ ，使页面和 App 互相通过 JS 进行数据传递、函数调用。 

*注：以下示例均为 Android 代码*

__App 调用 JS 代码__

```java
// 方法一：直接调用 JS 函数
webView.loadUrl("javascript:jsFunction('" + arg + "')");

// 方法二：直接执行 JS 代码
webView.evaluateJavascript(
    "(console,log('test from app'); })();",
)
```
__JS 调用 App 代码__

```java
// 将方法名注册到 window 对象上
webView.addJavascriptInterface(new JsBridge(), "AppFunction");
public class AppFunction {
    @JavascriptInterface
    public void doSomething() {
        ....
    }
}
```

```js
// JS 调用
window.AppFunction.doSomething()
```

#### 2. URL Scheme
__JS 调用 App 代码__
```java
// 拦截 URL Scheme
webView.setWebViewClient(new WebViewClient() {
    @Override
    public boolean shouldOverrideUrlLoading(WebView view, String url) {
        if (url.startsWith("scheme://")) {
            // do something
            return true;
        }
        return false;
    }
});
```

```js
// JS 调用
location.href = 'scheme://doSomething?param1=xxx';
```

除此之外，还有一种链接：__Universal Link (通用链接)__ ， 是 Apple 在 iOS9 推出的一种能够通过 HTTPS 链接来启动 APP 的功能。当应用支持此链接时，则会无缝跳转到 APP，而不需要其他判断；若用户未安装当前 App，则会使用浏览器直接打开此网页。

### 二、H5 唤起 App
大致流程如下：

<div class="custom-flow-chart">
<style>
  .custom-flow-chart svg {
    display: block;
    margin: 0 auto;
  }
</style> 
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
</div>

#### 若在小程序的 Webview 中尝试唤起 App 会怎么样？
由于微信拦截了 URL Scheme，所以并不会打开 App。
介时小程序底层就会判断 Webview 环境，跳转对应的应用商店。
__在 Mac 上的开发者工具中会跳转 App Store__

{% asset_img "IOS.png" 400 %}

__在安卓手机的微信小程序中则会跳转（腾讯的安装渠道）__

{% asset_img "Android.png" 400 %}

由于上述两个示例的域名都没有在微信后台配置，故会被微信认为是不可信的域名，跳转到一个空白页面，提示域名不可信。


*注：主要禁止的原因是，小程序不允许将流量导出到 APP 之外。*

### 联调注意事项
1. 同一方法，若确定方法名、参数等没有问题，但是调用结果与预期不一致，注意同时对比 IOS 端和 Android 端表现是否一致，若表现不一致，则应找对应的客户端同事去修改；
2. 注意测试 App 版本号，以及 H5 中引用的 sdk 版本号，排查问题时考虑是否是版本过旧导致的；
3. 对于用作工具的测试页面出现问题，即时反馈，有可能是测试页面未更新。

### 参考链接
* [Android：你要的WebView与 JS 交互方式 都在这里了](https://blog.csdn.net/carson_ho/article/details/64904691)
* [h5 与原生 app 交互的原理](https://segmentfault.com/a/1190000016759517)
* [In-depth Profiling of JSBridge](https://alibaba-cloud.medium.com/in-depth-profiling-of-jsbridge-63dc797f8c77)
* [Android Build Version](https://developer.android.com/reference/android/os/Build.VERSION)