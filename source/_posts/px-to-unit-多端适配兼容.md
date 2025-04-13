---
title: postcss-px-to-unit 插件开发：多端适配兼容
date: 2025-04-09 03:29:25
tags: [CSS]
categories: [前端, CSS]
---
有两个场景，一是希望单个项目能兼容不同尺寸设计稿；二是想要移动端页面在 PC/iPad 等横屏设备也能比较好的展示，而并非纯粹的等比例放大。

<!--more-->
### 一、兼容不同尺寸设计稿

目前通用设计稿画布宽度为 375，也是最常见的适配宽度。偶尔比较新的项目或者活动会有 414 底稿，罕见点会有 393。独立项目独立 config，更改适配项即可。直至 __同一个项目收到了两个尺寸的设计稿__ ，一个 375，一个 393...

由于设计师侧暂无暇重新调整为统一尺寸，只能从适配层面考虑，兼容两种尺寸。

项目使用 `postcss-px-to-viewport` 插件进行适配，默认适配 375。现为部分页面路径单独设置适配尺寸。
```js
          {
            loader: 'postcss-loader',
            options: {
              postcssOptions: (loaderContext) => {
                const _viewportConfig = {
                  unitToConvert: 'px', 
                  viewportWidth: 375,
                  unitPrecision: 5,
                  propList: [ '*', '!font-size' ],
                  ...
                }
                
                // 为 pages_need_393 路径下的页面设置特殊的适配尺寸
                if (loaderContext.resourcePath.includes('pages_need_393')) {
                  _viewportConfig.viewportWidth = 393
                }

                return {
                  plugins: [
                    px2viewport(_viewportConfig),
                    'autoprefixer',
                    'postcss-preset-env'
                  ]
                }
              },
            },
          },
```
### 二、多设备及横屏适配

#### 期望效果

{% asset_img "pagescreen.png" %}

#### postcss-px-to-viewport

__未设置 landscape 表现__

{% asset_img "fullscreen.png" %}

__设置 landscape 后，表现不如预期__
按照官方文档设置 landscape 横屏数值后，iPad 全屏可以展示，PC 端展示比例过大（感觉 px2viewport 的横/竖屏模式是按照移动设备进行适配的，PC 端并不在此种情况之内）
{% asset_img "fullscreen-landscape.png" %}

### 三、解决方式
想达到预期效果，最简单的方式就是固定页面方向（portrait），对iPad/PC等宽屏设备不做适配，使用原像素值。
扫了眼 `postcss-px-to-viewport` 的源码，它的计算方式如下：
```js
function createPxReplace(opts, viewportUnit, viewportSize) {
  return function (m, $1) {
    if (!$1) return m;
    var pixels = parseFloat($1);
    if (pixels <= opts.minPixelValue) return m;
    // 计算当前值在视口中的占比
    var parsedVal = toFixed((pixels / viewportSize * 100), opts.unitPrecision);
    return parsedVal === 0 ? '0' : parsedVal + viewportUnit;
  };
}

landscapeRule.append(decl.clone({
  value: decl.value.replace(pxRegex, createPxReplace(opts, opts.landscapeUnit, opts.landscapeWidth))
}));
```
故将插件的 landscapeWidth 设置为 100, landscapeUnit 设置为 px 即可抵消转换。
```js 
/* postcss-px-to-viewport config */
{ 
 ...
  landscape: true,
  landscapeUnit: 'px', 
  landscapeWidth: 100
}
```

### 四、更进一步，动手重写

在 webpack 中使用 postcss-loader 对 css 文件进行处理。此插件可以获得 webpack 在处理 css 时的每一步、以及在 AST 语法树生成的过程中做一些操作，例如替换 px。
插件的回调会告知处理 CSS 的每一步，届时可替换原始值为转换后的数值/单位。
#### postcss-px-to-unit

使用 CSS 变量 + 媒体查询 实现灵活适配，视口宽度交由 CSS 设置，而不是在编译阶段设置：

```js
/* postcss-px-to-unit.js */
const postcss = require('postcss')

module.exports = postcss.plugin('postcss-px-to-unit', function (options) {
  console.log('postcss-px-to-unit', options)
  const { designWidth = 375 } = options || {}

  return function (css, result) {
    css.walkRules(function (rule) {
      rule.walkDecls(function(decl) {
        if (rule.selector === 'body') {
          return decl.value
        }

        const regx = /(-?\d*)px/g
        const matchedResults = regx.exec(decl.value)
        if (matchedResults) {
          const [ matchedText, $1 ] = matchedResults
          decl.value = decl.value.replace(matchedText, `calc(${ $1 / designWidth } * var(--viewportWidth))`)
        }
      })
    })
  }
})
```

```css
/* main.css */
body {
  --viewportWidth: 550px;
  
  @media screen and (max-width: 728px) {
    --viewportWidth: 100vw;
  }
}
```
*注: 为 body 设置 550 的视口，是因为 375 的设计稿在宽屏设备上用这个比例展示看起来更舒适。*