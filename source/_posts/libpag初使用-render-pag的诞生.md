---
title: PAG 移动端动效方案
date: 2023-12-28 13:57:55
tags: [JavaScript ,NodeJS, 开发小结]
categories: [前端]
---
去年设计部门与客户端团队引入了腾讯新开源的 PAG 动画方案，用于在移动端展示复杂动画，其适用于 iOS、Android、Web、小程序等多个平台。稳定可行后，正式引到前端项目中使用。调研后封装成库（render-pag）方便组内成员调用。

<!-- more -->

### 一、 调研
[PAG](https://pag.art) 官方提供三个工具：
- 面向设计师：__PAG AE 插件__ ，用于导出动画文件；
- 面向设计师&开发者：__PAG Viewer 应用__ ，用于预览动画文件；
- 面向开发者：__PAG SDK__ ，项目代码中引用，用于解析、渲染动画文件；

#### 工作流
设计师在 AE 中完成动效设计，使用 PAG AE 插件导出动效文件（`.pag`）。开发者拿到动效文件后在 PAG Viewer 中进行预览，无问题后在项目中引入相关 SDK 及动效文件即可。

#### 兼容性
PAG 核心代码为 C++ 代码，其 Web 端是基于 WebAssembly + WebGL 实现，最终生成的动画文件是二进制文件。使用时需要在页面中引入 `libpag.js` 和 `libpag.wasm` 两个文件。

PAG 依赖 WebGL，需确保目标环境支持。

| [<img src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/chrome/chrome_48x48.png" alt="Chrome" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>Chrome | [<img src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/safari/safari_48x48.png" alt="Safari" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>Safari | [<img src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/chrome/chrome_48x48.png" alt="Chrome" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>Chrome for Android | [<img src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/safari/safari_48x48.png" alt="Safari" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>Safari on iOS |
| --------- | --------- | --------- | --------- |
| Chrome >= 69| Safari >= 11.3 | Android >= 7.0 | iOS >= 11.3 |

__公司客户端需要兼容到 IOS >= 11、Android >= 5，针对不支持 PAG 的设备将显示静态图片__

### 二、优缺点

#### 优点
- 二进制动画文件，体积比传统 json 动画小很多，且不用考虑图片文件外挂的问题（如 Lottie Web）
- 使用 canvas 标签实现播放，移动端无需用户手动触发
- 动画文件内容可编辑、素材时长均可控，API 灵活
- 矢量图层/动画性能优秀
- 跨平台支持性好

#### 缺点
- 依赖文件体积较大，不支持按需加载（绘制层 wasm 是一个整体）
  - 官方推荐将 libpag.wasm（2.9M）放到 CDN 上并开启 Gzip 压缩，压缩后大概是 890k，可以秒加载
- 复杂 AE 特效需要引入额外依赖
  - 包含 BMP 序列帧的动画会依赖 video 标签，需要引入官方的解码器 ffavc.wasm
- 代码层调用结束后需要手动销毁实例
  - 以解除 JS 对 wasm 导出对象的引用，需调用 PagFile.destory()

### 二、render-pag 的封装

`render-pag` 将 PAG 依赖加载过程进行封装，使调用方无需再关注动画参数以外的细节。同时得益于 PAG 本身提供的大量灵活 API，交互效果可自由组合。

#### 使用场景
__场景一__ ：虚拟形象，4500ms 的 PAG 文件，每 500ms 为一个新的状态（摆手、思考、开心、再见），根据用户交互播放不同片段 [0, 500]、[500, 1000]...

__场景二__ ：可复用的特效弹层，更改数值/图片，再次播放

#### 配置项
```ts
export interface Config {
  // 需要挂载的目标元素
  container: HTMLElement;
  // pag 素材地址
  pagUrl: string;
  // libpag.wasm 文件地址（未设置将使用默认值）
  wasmUrl?: string;
  // ffavc.wasm 文件地址（未设置将使用默认值）
  ffavcWasmUrl?: string;
  // 是否开启 ffavc 解码（针对微信环境或者对含有 BMP序列帧的文件使用）
  enableFFAVC?: boolean;
  // 不支持 pag 播放或者 pag 加载失败时的默认展示图片
  defaultPic?: string;
  // 画布宽度
  width?: number;
  // 画布高度
  height?: number;
  // 加载完成是否自动播放
  autoPlay?: boolean;
  // 是否循环播放动画
  isInfinite?: boolean;
  // 是否显示加载动画
  showLoading?: boolean;
  // 加载动画配置
  loadingConfig?: LoadingConfig;
  // PAG 实例初始化前的回调函数（通常用来替换图片/文字）
  beforePAGInit?: (view: PAGView) => void;
  // PAG 实例初始化完成的回调
  onPAGInitialized?: (PAG: PAGInstance) => void;
}
```

#### 核心代码
```ts
async function renderInit(config: Config): Promise<PAGInstance> {
  // ...
  const initList = [];
  initList.push(initWasm({ wasmUrl, ffavcWasmUrl, enableFFAVC }));
  initList.push(initPagFile(pagUrl));

  const [PAG, pagFileBuffer] = await Promise.all(initList);
  const PAGFile = await PAG.PAGFile.load(pagFileBuffer);

  const PAGInstance = await PAG.PAGView.init(PAGFile, canvasEl);
  return PAGInstance;
}


// 加载 wasm 文件
async function initWasm(
  config: {
    wasmUrl?: string;
    ffavcWasmUrl?: string;
    enableFFAVC?: boolean;
  } = {},
): Promise<PAG> {
  const PAG = await PAGInit({ locateFile: () => wasmUrl });
  if (enableFFAVC) {
    const FFAVC = await FFAVCInit({ locateFile: () => ffavcWasmUrl });
    const ffavcDecoderFactory = new FFAVC.FFAVCDecoderFactory();
    PAG.registerSoftwareDecoderFactory(ffavcDecoderFactory);
  }
  return PAG;
}

// 加载 PAG 素材
async function initPagFile(url: string): Promise<ArrayBuffer> {
  const data = await fetch(url);
  const buffer = await data.arrayBuffer();
  return buffer;
}
```

#### 渲染过程
{% asset_img "render-pag渲染过程.png" 600 %}

### 三、常见问题
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
#### 版本相关
- wasm 文件主版本需要与 PAG 主版本相对应，否则渲染报错
- 浏览器是否支持，需要自行判断当前环境是否支持 WebAssembly、WebGL

### 四、相关文档
- 官方文档：https://pag.art
- Github：https://github.com/Tencent/libpag
- Web demo：https://github.com/libpag/pag-web

### 其他
2025.8.6 支付宝的集五福动效方案 Galacean Effect，是一套蚂蚁自研的 Lottie-Like 动效工具。动效交付文件同样为 `json`，相对于 Lottie，支持了更多高级效果（如粒子）。
