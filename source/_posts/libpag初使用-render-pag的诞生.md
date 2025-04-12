---
title: PAG 使用 & render-pag 的诞生
date: 2023-12-28 13:57:55
tags: [JavaScript ,NodeJS, 开发小结]
categories: [前端]
---
去年设计部门与客户端团队引入了一项新的动画方案: PAG。这是一个腾讯开源的多端动画库，适用于 iOS、Android、Web。恰逢有个需求要用到，正式引到前端项目中使用。调研后封装成库（render-pag）方便组内成员调用。

<!-- more -->

### 一、 调研
[PAG](https://pag.art) 动效的制作由设计师在 AE 中完成，使用官方提供 AE 插件导出 `.pag` 文件给到工程师。下载官方工具 __PAGViewer__ 对 `.pag` 文件进行预览。

PAG 的核心代码为 C++ 代码，其 Web 端是基于 WebAssembly + WebGL 实现，最终生成的动画文件是二进制文件。使用时需要在页面中引入 `libpag.js` 和 `libpag.wasm` 两个文件。

#### 优点
- 动画文件为二进制，体积相比于 json 小很多，且不用考虑图片文件外挂的问题（如 Lottie Web）
- 利用 canvas 标签播放，移动端无需用户手动触发
- 动画文件内容可编辑、素材时长均可控
- 矢量图层/动画性能优秀
- 跨平台支持性好

#### 缺点
- 依赖文件体积较大，不支持按需加载（绘制层 wasm 是一个整体）
  - 官方推荐将 libpag.wasm（2.9M）放到 CDN 上并开启 Gzip 压缩，压缩后大概是 890k，可以秒加载
- 复杂 AE 特效需要引入额外依赖
  - 包含 BMP 序列帧的动画会依赖 video 标签，需要引入官方的解码器 ffavc.wasm
- 代码层调用结束后需要手动销毁实例
  - 以解除 JS 对 wasm 导出对象的引用，调用 PagFile.destory()

#### 兼容性
| [<img src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/chrome/chrome_48x48.png" alt="Chrome" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>Chrome | [<img src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/safari/safari_48x48.png" alt="Safari" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>Safari | [<img src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/chrome/chrome_48x48.png" alt="Chrome" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>Chrome for Android | [<img src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/safari/safari_48x48.png" alt="Safari" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>Safari on iOS |
| --------- | --------- | --------- | --------- |
| Chrome >= 69| Safari >= 11.3 | Android >= 7.0 | iOS >= 11.3 |

__公司客户端需要兼容到 IOS >= 11、Android >= 5，针对不支持 pag 动画播放的设备将显示静态图片__

### 二、render-pag 封装
#### 渲染过程
{% asset_img "render-pag渲染过程.png" 600 %}

### 代码示意
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

### 三、交互能力
render-pag 显式支持的交互如下，主要组合了原有的实例方法、封装成常用的交互方式。

- 播放/暂停
- 指定播放次数
- 设置播放进度/获取播放进度
- 播放某段时间片/多段时间片
- 替换图片、文字
- 获取动画总时长
- 刷新当前帧

*注：PAG 本身提供了很多 API，可在官网查看 PAGView Class 相关文档。*

### 四、常见问题
#### 卡顿 & 崩溃
- 受 PAG 渲染性能影响，同屏播放多个 PAG 动画，动画会明显卡顿
- 4.1.18 以下的老版本 libpag 内存泄露会使 Android、iOS Webview 崩溃，尽量升级版本到 4.2.x
- ffavc 能不用就不用，额外引入的 wasm  的文件也会占用内存资源
- 慎用包含特殊 AE 特效文件，Android 部分机型下会明显卡顿（需要 ffavc 解码器的文件同理）
- 尽量减少 pag 文件体积，过多的图层和位图的引入都会增加文件体积，同样会导致播放卡顿
#### 动画导出
- BMP 的动画导出后变糊
  - 可以将 BMP 序列帧导出看成视频的每一帧导出，为了优化体积，PAG 会进行压缩，就像压缩图片那样。这就是为什么不用 BMP 的文件比较清晰，因为矢量图只需要记录路径，不需要对图片素材做处理
- 设计师导出的 pag 文件不是 30 帧或者 60 帧
  - AE 插件导出默认为 24 帧，带 BMP 的最大 30 帧，不带 BMP 的最大 60帧
  - 设计师在 AE 中预览的效果不代表最终在手机呈现上的效果，由于帧数限制可能没有那么丝滑
- 导出的动画播放结束后会闪烁
  - 设计师在 AE 工程中最后的关键帧可能填充了黑色

### 五、相关文档
- 官方文档：https://pag.art
- Github：https://github.com/Tencent/libpag
- Web demo：https://github.com/libpag/pag-web

