---
title: PWA-Service Worker 小结（二）实践
date: 2020-01-02 15:15:08
tags: [Service Worker]
categories: [前端, PWA]
---
19年上半年探索的 Service Worker 最终没有在公司落地实践。Service Worker 带来的离线访问功能很爽，对于单页应用来说做离线缓存再合适不过。但对于多页应用，拿它用作本地缓存加速的可行性有待于进一步探索。

<!--more-->

### 一、前言
* Service Worker 是独立于当前页面的一段运行在浏览器后台进程里的脚本，它有自己独立的注册文件；
* Service worker 是一个可编程的网络代理，允许你去控制如何处理页面的网络请求， 可以处理 fetch 请求，但只能基于 HTTPS；
* 每个 Service Worker（注册文件）都有自己的作用域，它只会处理自己作用域下的请求，而 Service Worker 的存放位置就是它的最大作用域；
* Service Workder 是 Web Worker 的一种，它不能够直接操作 DOM。

### 二、Service Worker 的生命周期
1. 注册 Service worker，在网页上生效；
2. 安装成功，激活 或者 安装失败（下次加载会尝试重新安装）；
3. 激活后，在 sw 的作用域下作用所有的页面，首次注册 sw 不会生效，下次加载页面才会生效；已经注册的 sw 不会重复注册；
4. sw 作用页面后，处理 fetch（网络请求）和 message（页面消息）事件 或者 被终止（节省内存）。

![](/Service-Worker-Lifecycle.png "Service Worker Lifecycle")

### 三、其他
#### 公司的使用场景中为什么没有落地该技术？
公司想要应用 Service Worker 的站点是一个多页的 WAP 端，负责长期或者短期的活动...它不像其他应用有一个固定的入口（类似首页），那么 sw 的注册文件应该在哪里引入就成了一个问题。
在这种情况下，即使注册文件写在 layout 中，但实际渲染出来却是相当于每个页面都引入了 sw.js，这种方案虽可行，但我认为它并不是很合理...有种拿手术刀切水果的感觉...

个人觉得 Service Worker 更适合在单页应用、文档类应用的等场景使用，才能把离线缓存的优势发挥出来。比如 [Vue](https://cn.vuejs.org/) 的官网，离线体验做的如丝般顺滑...
#### 应用场景
这部分总结摘录自这篇文章：[Service Worker 从入门到出门](https://juejin.im/post/5d26aec1f265da1ba56b47ea#heading-6)

* 网站功能趋于稳定：频繁迭代的网站似乎不方便加 Service Worker。
* 网站需要拥有大量用户：管理后台、OA系统等场景似乎不是很有必要加 Service Worker。
* 网站真的在追求用户体验：Bug 多多、脸不好看的网站似乎不是很有必要加 Service Worker。
* 网站用户体验关乎用户留存：12306 似乎完全不需要加 Service Worker。
  
简单总结：Service Worker 的初衷是极致优化用户体验，是用来锦上添花的，技术只是技术，但实际应用前，应考虑成本和收益。