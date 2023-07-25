---
title: 【译】Why Is WKWebView So Heavy and Why Is Leaking It So Bad?
date: 2022-06-09 18:57:13
tags: [App, Webview, 翻译]
categories: [App]
---
从 iOS8 开始，就引入了新的浏览器控件 WKWebView，用于取代 UIWebView。在新版本系统中使用 UIWebView 会发出警告 ⚠️ 提醒更换控件。坊间传闻 WKWebView 存在内存占用过大的问题...

__声明：这是一篇翻译水文，有用的内容不多，之前是因为好奇翻译了一半，翻译完发现并没有什么有用的知识点...__

<!-- more -->

在 Embrace 公司，我们帮助移动应用公司解决他们最困难的生产问题。其中常见的 bug 是 iOS 上对 WKWebView 的不当管理产生的。而问题是 Webview 对象在资源中占用较重。大量被占用的内存未被正确的释放则会导致系统卡顿、死机甚至崩溃。

本文中，我们将会介绍以下内容：
* 为什么 WKWebView 会这么重
* 常见的 WKWebView 导致的内存泄露方式
* 使用 WKWebView 时怎样发现内存泄露
* 使用 WKWebView 的最佳实践

### 为什么 WKWebView 会这么重
在开始之前，我们在先前的文章中已经介绍了[content process 终止导致 WebView 阻塞显示空白](https://blog.embrace.io/bug-of-the-month-blank-webviews/)以及[降级导致的 WebView 空包](https://blog.embrace.io/bug-of-the-month-blank-web-views-caused-by-downgrading/)。如果你依然因为空白的 WebView 而苦恼，看看这些文章或许会有帮助。

文本将主要探讨在加载过程中 WebView 被阻塞以及在你的 App 中存在了过多的 WebView 的问题。WebView 是可控的最重的对象之一。基本上，你可以用你的 App 来启动另一个应用并添加两个附属进程 —— content process 和 networking process。

所以如果你的应用中有 __一个 WebView__ ，则意味着你的应用实际运行在 __三个系统进程__ 上：应用进程、Web Content Process 和 Web Networking Process。

有 __两个 WebView__ 则意味着有 __五个进程__ 。
有 __三个 WenView__ 则意味着有 __七个进程__ 。

当示例个数成倍增加时，并没有形成一个规模经济效应（即进程越多越高效）。事实上，正相反。创建的 WebView 越多，你的 App 运行就越慢。

### 常见的 WKWebView 导致的内存泄露方式
WKWebView 致使内存泄露最常见的原因就是 __新建__ ，而不是复用已经创建好的实例。一些时候，工程师们以为他们已经复用了 Webview 了，但是他们并没有检查在 Xcode 已经构建的 WKWebView 实例。因为 WKWebView 是存放在 Apple 系统目录中，工程师在调试性能问题时很容易把这部分忽略掉。

例如，你有一个轮播组件（Carousel），每当用户滑动时就会加载一个 WebView，内容如以下几种：
* 加载一篇 新闻/杂志 网站的文章
* 加载一个 电商 网站的产品列表页
* 加载一段 流媒体 如视频

对于轮播组件来说，在内存中的 WebView 数量最好永远不要超过两个。一个为用户展示当前内容，另一个用作下一个内容的承接。一旦用户滑动切换到下一个 WebView，应该清空第一个 WebView 并且使之为下一次切换做准备。这样无论用户切换多少次，你的 App 中始终就只有两个 WebView。

对于 ScrollView，在同一时间内可能会有多个可见的 WebView 存在。这种情况下，其最大数量取决于填满屏幕大小需要的 WebView 个数外加一个用于预加载 WebView。

另一中泄露方式是已崩溃的 WebView 一直被保留而没有得到释放。 无论用户在何时遇见白屏页面，你都应该有一个状态码来确定当前页面是应该重新加载还是应该被移除。例如，如果是付款页面出了问题，你会想去重新加载；如果是广告页面出了问题，当你不能够修复时你会选择删除它。

### 使用 WKWebView 时怎样发现内存泄露
通过 Xcode 内存图表来查看内存泄露。 用 Xcode 进行 debug 时，查看 WebView 模块，可以在展开左边侧栏中看到当前内存中的 WebView 数量。此时滑过刚刚我们创建的组件，就可以看到到内存使用情况。

{% asset_img "Xcode-debug.png" "Xcode-debug" %}

### 使用 WKWebView 的最佳实践
首先最好的实践就是限制应用应用内 WKWebView 的数量。在 iOS 应用中，最繁重的操作之一就是创建新的 WKWebView。它们占用大量的内存并添加额外的进程。无论何时尝试将 WebView 用系统本身的某功能来代替，都是有意义的。

第二个实践是复用已有的 WKWebView 而不是新建。清除现有的旧内容并将新内容加载到现有的 WKWebView 实例中，这比直接删除和创建的性能要好的多。

第三个实践是写一些适当的测试用例来标记溢出的 WebView，代码可以严格一点。如果你仅在轮播组件中使用了 WebView，那么你很明确的知道同一时刻的内存中最多应该包含两个 WebView。当超过两个 WebView 存在时，测试用例将报错。

同理，如果你有一个产品列表在 ScrollView 中，那么你就可以通过计算填满屏幕所需的 WebView 数量来计算最大值。测试用例也是同样的方法。利用 Xcode 的内存图和适当的测试用例来发现 WebView 的泄露是很重要的，这样就可以使你的应用程序性能更佳。

### 总结一下
iOS 应用卡顿和反应慢的问题之一是创建了太多 WKWebView 实例，对已存在的 webview 没复用也没销毁（这不卡才怪...）。


### 参考文章
https://blog.embrace.io/wkwebview-memory-leaks/

### 翻译总结
* 文章部分内容写的过于重复，并不是很干货，让我想起了国内的营销号；
* 强烈怀疑原文是隔壁机翻成英文的，或者作者母语并非英语；
* 机翻比自己脑子翻好用...