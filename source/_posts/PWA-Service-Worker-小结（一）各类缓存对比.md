---
title: PWA-Service Worker 小结（一）各类缓存对比
date: 2019-12-26 16:39:55
tags: [Service Worker]
categories: [前端, PWA]
---
年底了，总结一下上半年探索的 PWA 的离线缓存技术。顺带总结了一下前端全流程每一步中都可能遇到的缓存，大部分都是概念、名词的理解和说明。涉及到的缓存有：HTTP 缓存、Manifest 缓存、CDN 缓存、Nginx 服务器缓存、Service Worker 缓存。

<!--more-->

缓存的好处：
存储频繁访问的数据，降低服务器压力；
减少网络延迟，加快页面打开速度；

### 一、HTTP 缓存
#### [浏览器缓存机制](https://www.cnblogs.com/slly/p/6732749.html)：
1. [在未设置相应头缓存字段的时候，只有用户点击“回退”按钮的时候，页面才会从缓存中读取](https://segmentfault.com/a/1190000011286027)；
2. __过期机制__ ：与服务器协商获取。对于浏览器来说，如何缓存一个资源是服务器端制定的策略，服务器对每个资源的 [HTTP 响应头设置属性和值](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Caching_FAQ)，自己只负责执行。常用的为以下几种：
    * Expires: 设置过期时间(单位日期)，某日期之前都不再询问；浏览器再次命中这个资源，直至XXX时间前都不会发起 HTTP 请求，而是直接从缓存（在硬盘中）读取。
      * 如：200 (from cache) 这种缓存速度最快。
    * Last-Modified: 设置资源上次修改时间(单位日期)，每次请求命中资源，都去询问资源是否过期；通过这种缓存方式，无论资源是否发生变更，都会发生至少一来一去的 HTTP 头传输和接收，速度比不上 Expires；
      * 如：304，若文件发生变更，则返回200。
    * Cache-Control:
      * max-age=<seconds> 设置缓存存储的最大周期，超过这个时间缓存被认为过期(单位秒)；标准中规定 max-age 的值最大不能超过一年，且以秒为单位，所以值为 31536000；
      * no-cache  字面意义“不缓存”。实际机制是对资源仍使用缓存，但每次使用前必须（MUST）向服务器对缓存资源进行验证；
      * no-store 不使用任何缓存；
3. __验证机制__ ：服务器返回资源的时候有时会在头信息中携带 __Etag（Entity Tag）__，它可作为浏览器再次请求过程的校验标识。如发现校验标识不匹配，说明资源已经修改或过期，浏览器需要重新获取资源内容。
ETag 可以保证每一个资源是唯一的，资源变化都会导致 ETag 变化。服务器根据浏览器上送的 ETag / If-None-Match 值来判断是否命中缓存。在精准度上，Etag 优于 Last-Modified。因为 Etag 是按照内容为资源增加标识，而 Last-Modified 是根据文件最后修改时间判断。

{% asset_img "协商缓存命中过程.png" "协商缓存命中过程" %}

#### 常用的缓存策略：
* 对于动态生成的 HTML 页面使用 HTTP 头: Cache-Control : no-cache;
* 对于静态 HTML 页面使用 HTTP 头: Last-Modified;
* 其他所有文件类型都设置 Cache-Control 头，并且在文件内容有所修改都时候修改文件名。

#### 如何更新文件：
按照 HTTP 规范，如果修改了请求资源的 Query String，就应该被视为一个新的文件。但是遇到运营商劫持时，会忽略 Query String，遇到这种情况只能修改文件名。

#### 疑问：
给 HTML 都设置了 Cache-Control: no-cache; 对 CSS 和 JS都用了 gulp 进行了打包编译处理，每次有变化都会变更文件名；那么此种情况下，是否还需要设置 Last-Modified？
直接设置 Cache-Control max-age 或者 Expires 难道不会节省更多 HTTP 请求吗？避免服务器为做出应答返回大量 304。

### 二、[Manifest 缓存](https://segmentfault.com/a/1190000019395237?utm_source=tag-newest)
manifest 在前端含义很多，常见的四个使用场景如下：
1. HTML 标签的 manifest 属性，用来离线缓存 HTML 文档以及资源的；
   * 如 <html manifest="xxx"\></html\>，由于坑太多，现在已经被废弃；
2. PWA 的 manifest 功能：将 web 应用程序安装到设备的主屏幕；
   * 如 <link rel="manifest" href="/manifest.json"\>；
   * 在 manifest.json 中配置应用的图标、名称等信息；通过一系列配置，就可以为 Web App 添加一个图标到手机上，点击图标即可打开站点；
3. webpack 打包时会生成个 manifest.json 的文件，用来分析打包后的文件；
4. [gulp 处理静态资源时，使用 gulp 的 gulp-rev 插件生成 manifest.json，用来记录源文件与处理后的目标文件的对照](https://blog.csdn.net/wangjun5159/article/details/79287881)。

### 三、CDN缓存
即使为各类资源文件设置了 HTTP 头，当用户手动清除缓存 ，或者由于磁盘容量限制，先缓存的文件被挤出磁盘，此时依旧需要请求资源，为了快速响应用户请求，使用 CDN 加速。CDN的分流作用不仅减少了用户的访问延时，也减少了源站的负载。
当用户手动清理本地缓存后，将去请求距离最近的 CDN 边缘节点。
CDN 边缘节点缓存策略因服务商不同而不同，但一般会遵循 HTTP 标准协议。通过 HTTP 响应头中的 Cache-Control: max-age 的字段来设置CDN边缘节点数据缓存时间，若数据失效，则向源站发出回源请求，拉取最新的数据；当源站内容有更新的时候，源站主动把内容推到CDN节点。

各家 CDN 缓存参考：[https://segmentfault.com/a/1190000006673084](https://segmentfault.com/a/1190000006673084)

CDN 回源原理：[https://www.jianshu.com/p/e7751ecb6f21](https://www.jianshu.com/p/e7751ecb6f21)

### 四、nginx 服务器缓存
<del>这里又牵扯到了两个地方...就像家用路由器和企业级路由器虽然都叫路由器但是功能完全不一样...</del>
nginx 大名 负载均衡服务器，它是服务器不是服务；CDN 加速是运营商提供的一种服务....，这俩玩意一点关系都没有。如果网站既使用了 CDN 加速，同时又使用了 Nginx 代理，那么 CDN 的位置相比于 Nginx 服务器更靠近用户。

{% asset_img "CDN&&Nginx.jpg" "CDN && Nginx" %}

网站管理者可以通过为网站配置 Nginx 服务器来达到负载均衡的目的， Nginx 可以重写静态资源的 HTTP 头的缓存信息等，也可以用 Nginx 搭建自己的 CDN 节点（原理跟运营商 CDN 差不多，都是转发到合适的机器；只不过 CDN 是将静态资源存在运营商的机器上，Nginx 做 CDN 的话就缓存在自己的机器上）。具体选择时可通过银子的多少来判断是选 CDN 加速，还是 Nginx 搭建 CDN。

综上，当 Nginx 服务器承载“CDN 加速”的功能时，可通过配置 proxy_cache 将文件缓存到本地的一个目录，缓存命中原理当与 CDN 相同；当 Nginx 服务器不充当 CDN，只是重写静态文件的响应头时，此时跟服务器写命令没差，缓存在浏览器中，原理见浏览器缓存命中机制，不再进行赘述。

### 五、Service Worker 缓存
Service Worker  是一个位于浏览器和网络之间的客户端代理，可以拦截、处理流经的 HTTP 请求，使开发者可以从缓存中向 Web 应用提供资源。可以把它看成是用户设备中的缓存提供服务器，功能十分强大。它缓存的文件同样存储在客户端（用户设备）中：

{% asset_img "web应用缓存位置图.png" "web应用缓存位置图" %}

Service Worker 是 PWA 实现离线应用的核心技术。它可以：
* 让网页可以离线访问；
* 让网页在弱网情况，使用缓存快速打开应用，提升体验；
* 同时在网络正常的情况下走网络缓存减少请求的带宽； 
* 对不支持的手机没有影响；

__缓存有各自的优先级，当依次查找缓存且都没有命中的时候，才会去请求网络：__
1. Service Worker
2. Memory Cache
3. Disk Cache
4. 网络请求

### 参考资料：
* 《web全栈工程师的自我修养》
* [由memoryCache和diskCache产生的浏览器缓存机制的思考](https://segmentfault.com/a/1190000011286027)
* [HTTP强缓存和协商缓存](https://segmentfault.com/a/1190000008956069)
* [Etag和Last-Modified](https://www.jianshu.com/p/b5c805f4e8d1)
* [傻傻分不清的Manifest](https://segmentfault.com/a/1190000019395237?utm_source=tag-newest)
* [定制修改gulp-rev返回的rev-manifest.json文件](https://blog.csdn.net/wangjun5159/article/details/79287881)
* [从HTTP响应头看各家CDN缓存技术](https://segmentfault.com/a/1190000006673084)
* [简述回源原理和CDN常见多级缓存](https://www.jianshu.com/p/e7751ecb6f21)
* [渐进式网页应用(PWA)介绍](https://zhuanlan.zhihu.com/p/96934736)
  