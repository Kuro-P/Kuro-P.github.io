---
title: PWA-Service Worker 小结（二）实践
date: 2020-01-02 15:15:08
tags: [Service Worker]
categories: [前端, PWA]
---
Service Worker 的初衷是极致优化用户体验，带来丝滑般流畅的离线应用。但同时也可以用作站点缓存使用。它本身类似于一个介于浏览器和服务端之间的网络代理，可以拦截请求并操作响应内容。功能强大，但由于兼容性问题，更适合用作渐进增强来使用。

<!--more-->

### 一、前言
* Service Worker 是独立于当前页面的一段运行在浏览器后台进程里的脚本，它有自己独立的注册文件；它是 Web Worker 的一种，不能够直接操作 DOM；
* 出于安全问题考虑，它只能在 HTTPS 域名下或者 localhost 本地运行；
* 可以通过 postMessage 接口传递数据给其他 JS 文件；
* Service Worker 中运行的代码不会被阻塞，也不会阻塞其他页面的 JS 文件中的代码；
* 每个 Service Worker（注册文件）都有自己的作用域，它只会处理自己作用域下的请求，而 Service Worker 的存放位置就是它的最大作用域；
* 缓存的资源存储在 Cache Storage 中，缓存不会过期，但是浏览器对每个网站的 Cache Storage 的大小有硬性限制，所以需要清理不必要的缓存；

### 二、Service Worker 的生命周期
1. 注册 Service worker，在网页上生效；
2. 安装成功，激活 或者 安装失败（下次加载会尝试重新安装）；
3. 激活后，在 sw 的作用域下作用所有的页面，首次注册 sw 不会生效，下次加载页面才会生效；已经注册的 sw 不会重复注册；不会因为页面的关闭而被销毁；
4. sw 作用页面后，处理 fetch（网络请求）和 postMessage（页面消息）事件 或者 被终止（节省内存）。

![](/Service-Worker-Lifecycle.png "Service Worker Lifecycle")

### 三、Service Worker 安装注册
#### 注册文件
````javascript
// service worker 注册文件
if ('serviceWorker' in window.navigator) {
  navigator.serviceWorker.register('./sw.js', { scope: './' })
    .then(function (reg) {
      console.log('success', reg);
    })
    .catch(function (err) {
      console.log('fail', err);
    });

````
register 方法接受两个参数，第一个是 service worker 文件的路径，第二个参数是 Serivce Worker 的配置项，可选填，其中比较重要的是 __scope__ 属性。

#### 拓展 Service Worker 作用域

scope的默认值为 `./`（注意，这里所有的相对路径不是相对于页面，而是相对于sw.js脚本的），因此，`navigator.serviceWorker.register('/static/home/js/sw.js')`代码中的 scope 实际上是`/static/home/js`，Service Worker也就注册在了`/static/home/js`路径下，显然无法在`/home`下生效。

可以通过添加 `Service-Worker-Allowed` 响应头的方式来扩展 service worker 的作用域：
````javascript
// express 扩展 service worker scope
app.use(serveStatic(`${sourceRoot}/home`, {
    maxAge: 0,
    setHeaders: function (res, path, stat) {
        if (/\/sw\/.+\.js/.test(path)) {
            res.set({
                'Content-Type': 'application/javascript',
                'Service-Worker-Allowed': `/${sourceRoot}//home`,
                'Cache-control': 'no-store'
            });
        }
    }
}));

````

#### 打包工具生成静态资源注册文件

自己本地调试，可以一个个写进 Service Worker 的注册文件里调试；实际开发中可以借助 gulp / webpack 等打包工具等生成站点静态文件的 sw 注册文件；
以 gulp 为例，使用 [`sw-precache`](https://github.com/GoogleChromeLabs/sw-precache) 插件生成注册文件：
````javascript
gulp.task('generate-service-worker', function(callback) {

    swPrecache.write('./service-worker.js', {
        staticFileGlobs: ['./build/public' + '/**/*.{js,css,png,jpg,webp,gif,svg,eot,ttf,woff}'],
        stripPrefix: './build'
    }, callback);

});
````

### 四、Service Worker 的更新
不要更改 service worker 的注册名称

### 落地情况
个人觉得 Service Worker 更适合在单页应用、文档类应用的等场景使用，才能把离线缓存的优势发挥出来。比如 [Vue](https://cn.vuejs.org/) 的官网。<hr/>
*2019.4.23*
未落地。主要原因有两点： 
1. 工作中想要使用 Service worker 提供离线缓存服务的是一个负责 APP 内嵌页面的 H5 站点，HTML都是动态渲染的，活动数据是实时的，不能离线访问；
2. 这个站点的页面入口都是几乎都是单独的活动页，没有一个统一 sw 注册的入口；

<hr/>
*2020.3.16*
重新看这篇文章的时候，如果在几个主要的活动入口页引入 sw 的注册文件，那么这几个长期的活动就可以应用 sw 缓存了，但这并没有覆盖全站，所以依然不是好的解决方案。

### 应用场景
这部分总结摘录自这篇文章：[Service Worker 从入门到出门](https://juejin.im/post/5d26aec1f265da1ba56b47ea#heading-6)

* 网站功能趋于稳定：频繁迭代的网站似乎不方便加 Service Worker。
* 网站需要拥有大量用户：管理后台、OA系统等场景似乎不是很有必要加 Service Worker。
* 网站真的在追求用户体验：Bug 多多、脸不好看的网站似乎不是很有必要加 Service Worker。
* 网站用户体验关乎用户留存：12306 似乎完全不需要加 Service Worker。
  
简单总结：Service Worker 的初衷是极致优化用户体验，是用来锦上添花的，技术只是技术，但实际应用前，应考虑成本和收益。

### 参考链接
* [Service Worker ——这应该是一个挺全面的整理](https://juejin.im/post/5b06a7b3f265da0dd8567513#heading-1)
* [【PWA学习与实践】(9)生产环境中PWA实践的问题与解决方案](https://www.jianshu.com/p/7eae75f46467)
* [谨慎处理 Service Worker 的更新](https://zhuanlan.zhihu.com/p/51118741)