---
title: libpag 初使用 & render-pag 的诞生
date: 2023-12-28 13:57:55
tags: [JavaScript ,NodeJS, 开发小结]
categories: [前端]
---
去年设计部门与客户端团队落地了一项新的动画方案: libpag，是腾讯开源的一个全平台动效插件。公司内还剩前端组未接入，正好去年年中有个需求需要用到 pag 动画，简单用了一下并封装成 js 库方便组内调用。
今年主要是维护和修 bug，并支持了 React 组件渲染。 
（emmm 这也是一篇本该属于2022年完成的文章...）

<!-- more -->

### libpag 调研
libpag 核心代码为 C++ 代码，其 Web 端是基于 WebAssembly + WebGL实现，最终生成的动画文件是二进制文件，所以在体积上很占优势。
引入时需要引入 `libpag.js` 和 `libpag.wasm` 两个文件。

### 相关文档
官方文档  https://pag.art <br/>
Github https://github.com/Tencent/libpag <br/>
Github demo https://github.com/libpag/pag-web <br/>
libpag 官方 CDN https://cdn.jsdelivr.net/npm/libpag@latest/lib/ <br/>
ffavc 官方 CDN https://cdn.jsdelivr.net/npm/ffavc@latest/lib/ <br/>
（需要注意的是，腾讯的 CDN 并没有提供 Gzip， 所以访问起来会比较慢）

#### 优点
- 生成文件格式为二进制，文件相比于 json 小很多，且不用考虑图片文件外挂的问题（如 Lottie Web）
- 利用 canvas 实现播放，无需用户手动触发
  - 如果包含 BMP 序列帧则需要用户手动触发交互（因为 BMP 会调用视频标签），使用官方推荐的解码器 (ffavc) 可解决这一问题
- 如果动画较长较复杂且没有交互，则更推荐使用 MP4。PAG 的优势在于矢量性能优于视频、BMP 预合成、可编辑性、跨平台支持等

#### 缺点
- ES6 方式引入需要额外处理 .wasm 文件
  - libpag 依赖的 wasm 文件是比较大的，有 2.9M 左右；官方推荐的方式的将 wasm 放到 CDN 上并开启 Gzip 压缩，压缩后的 Gzip 文件大概是 890k，可以秒加载
- 由于底层用 WebAssembly 来编译 C++ 代码，需要手动 GC（手动 destroy 实例）

#### 兼容性
| [<img src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/chrome/chrome_48x48.png" alt="Chrome" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>Chrome | [<img src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/safari/safari_48x48.png" alt="Safari" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>Safari | [<img src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/chrome/chrome_48x48.png" alt="Chrome" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>Chrome for Android | [<img src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/safari/safari_48x48.png" alt="Safari" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>Safari on iOS |
| --------- | --------- | --------- | --------- |
| Chrome >= 69| Safari >= 11.3 | Android >= 7.0 | iOS >= 11.3 |

__公司客户端需要兼容到 IOS >= 11、Android >= 5，针对不支持 pag 动画播放的设备将显示静态图片__

### 绘制流程
{% asset_img "render-pag渲染过程.png" 600 %}

### 简要代码
```js
import { PAGInit } from "libpag";

// 初始化 wasm 实例
const PAG = await PAGInit();

// 初始化 pag 文件数据
const PAGData = await fetch(pagUrl);
const PAGFileBuffer = await PAGData.arrayBuffer();
const PAGFile = await PAG.PAGFile.load(PAGFileBuffer);

// 创建 canvas
const canvasEl = document.createElement("canvas");
document.body.appendChild(canvasEl);

// 绘制画布（结束）
const PAGView = await PAG.PAGView.init(PAGFile, canvasEl);

```

### 交互能力
render-pag 用到的 libpag 功能如下（libpag 本身支持很多能力，可以在官网查看 PAGView Class 的方法）
- 支持替换图片
- 支持替换文字
- 支持声音输出
- 支持播放/暂停/指定播放次数
- 设置播放进度/获取播放进度
- 获取动画总时长
- 刷新当前帧

### 常见问题
#### wasm 文件加载
- 加载慢：开启 Gzip。
  - wasm 文件有 2.9M，官方推荐开启 Gzip 并放到 CDN 上，以减少加载时间，或者让客户端缓存在本地。
- 按需加载：不支持。
  - 绘制层的 wasm 是一个整体，并且已压缩到最小。
#### 卡顿 & 崩溃
- 受 PAG 渲染性能影响，不要在同屏播放多个 PAG 动画，否则动画会明显卡顿
- 4.1.18 以下的老版本 libpag 会内存泄露使 Android、iOS Webview 崩溃，升级 4.2.x 以后问题得到解决
- 不需要 ffavc 的场景则尽量不要使用 ffavc，额外 wasm  的文件引入也会占用内存
- 加了特殊 AE 特效的 pag 文件在不建议在使用，在 Android 下会明显卡顿（需要 ffavc 解码器的动画同理）
- 优化 pag 文件体积，过多的图层和位图的引入都会增加文件体积，同样会导致播放卡顿
#### 动画导出
- 使用 BMP 的动画导出后变糊了？
  - 可以将 BMP 序列帧导出看成视频的每一帧导出，为了优化体积，PAG 会进行压缩，就像压缩图片那样。这就是为什么不用 BMP 的文件比较清晰，因为矢量图只需要记录路径，不需要对图片素材做处理
- 设计师导出的 pag 文件不是 30 帧或者 60 帧？
  - AE 插件导出默认为 24 帧，带 BMP 的最大 30 帧，不带 BMP 的最大 60帧
  - （设计师在 AE 中预览的效果不代表最终在用户手机上的效果，由于帧数限制可能没有那么丝滑）
