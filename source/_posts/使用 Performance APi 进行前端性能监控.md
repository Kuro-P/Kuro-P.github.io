---
title: 使用 Performance API 进行前端性能监控
date: 2019-07-11 18:55:59
tags: [性能监控]
categories: [前端]
---
&emsp;&emsp;平常只在测试环境测过前端页面性能，到了真实环境用户的手机上，页面性能的具体表现却未曾了解。H5 新增的 Performance API 可以精确的测量网页性能。使开发者可以通过数据上报的方式收集线上 H5 页面的性能表现，以合理优化页面性能短板，提升用户体验。
<!--more-->

### 前端性能监控指标
* __白屏时间__: 从打开网站到有内容渲染出来的时间节点
* __首屏时间__: 首屏内容渲染完毕的时间节点
* __domReady 时间__: 用户可操作的时间节点
* __onload 时间__: 总下载时间

### Performance API 简介
&emsp;&emsp;[Performace](https://developer.mozilla.org/zh-CN/docs/Web/API/Performance)是 HTML5 的新特性之一，该接口会返回当前页面性能相关的信息。Performance 对象一共提供了4个属性：

* __navigation__: 包含页面加载、刷新、重定向情况
* __timing__: 包含了各种与浏览器性能有关的时间数据
* __memory__: 返回JavaScript对内存的占用
* __timeOrigin__: 返回性能测量开始时的时间的高精度时间戳

本文主要讨论 Performance 的 timing 对象以及其他几种统计指标。
#### performance.timing
timing 对象提供了各种与浏览器处理相关的时间数据([详细](https://segmentfault.com/a/1190000014479800))，各时间节点可参照下图: 

{% asset_img "performance.png" %}

其中常用的几项计算指标如下：
````javascript
    var timing = performance.timing;
    var times = {};

     // 请求耗时
    times.request = timing.responseEnd - timing.requestStart || 0;

    // 页面白屏时间
    times.ttfb = timing.responseStart - timing.navigationStart || 0;

    // 页面可操作时间
    times.domReady = timing.domComplete - timing.responseEnd || 0;

    //dom渲染时间
    times.domRender = timing.domContentLoadedEventEnd - timing.navigationStart || 0,

    // 总下载时间
    times.onload = timing.loadEventEnd - timing.navigationStart || 0;

    // DNS解析时间
    times.lookupDomain = timing.domainLookupEnd - timing.domainLookupStart || 0;

    // TCP建立时间
    times.tcp = timing.connectEnd - timing.connectStart || 0,

    // 首屏时间
    times.now = performance.now();
````
### performance.now()
返回当前网页从performance.timing.navigationStart到当前时间之间的微秒数

### performance.getEntries()
浏览器获取网页时，会对网页中每一个对象（脚本文件、样式表、图片文件等等）发出一个HTTP请求。performance.getEntries方法以数组形式，返回这些请求的时间统计信息，有多少个请求，返回数组就会有多少个成员。

### 数据埋点及上报方式

#### 利用 <script\> 标签的 src 属性上报
工作中采用的埋点方式是脚本引入。该脚本负责收集浏览器性能指标信息，并生成一个 <script\> 节点，将指标信息拼接成 url param 的形式，通过 <script\> 标签的 src 属性发起请求，将数据上报到服务器。

#### 利用 <img\> 标签的 src 属性上报
谷歌和百度的都是用的1x1 像素的透明 gif 图片，其优点如下：
* 跨域友好
* 执行过程无阻塞
* 使用image时，部分浏览器内页面关闭不会影响数据上报
* gif 的最低合法体积最小（最小的 bmp 文件需要74个字节，png 需要67个字节，而合法的 gif，只需要43个字节）
  
#### 利用 HTML5 Beacon API 进行数据上报
Beacon API 允许开发者发送少量错误分析和上报的信息，它的特点很明显：
* 在空闲的时候异步发送统计，不影响页面诸如 JS、CSS Animation 等执行
* 即使页面在 unload 状态下，也会异步发送统计，不影响页面过渡/跳转到下跳页
* 可被客户端优化发送，尤其在 Mobile 环境下，可以将 Beacon 请求合并到其他请求上，一同处理

### 前端性能监控系统
在 github 上发现的比较好的工具，可以用来参考：
* 数据上报插件: [web-report-sdk](https://github.com/wangweianger/web-report-sdk)
* 前端性能监控UI: [web-monitoring](http://hubing.online:8083/#/sys/5cb68708838abf131c718ed1/index)

### 参考资料
[前端性能监控-window.performance](https://blog.csdn.net/weixin_42284354/article/details/80416157)
[Performance API-ruanyifeng](http://javascript.ruanyifeng.com/bom/performance.html)
[初探Performance API](https://segmentfault.com/a/1190000014479800)
[前端全（无）埋点之页面停留时长统计](https://juejin.im/entry/5a179332f265da431b6ce39c)