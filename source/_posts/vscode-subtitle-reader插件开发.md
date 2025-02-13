---
title: vscode-subtitle-reader插件开发
date: 2024-11-16 23:30:46
---
一个 vscode 插件开发记录，主要是用来满足自己阅读字幕文本的需要。

<!--more-->

### 一、想法诞生
习惯性收集影视剧字幕，模仿剧中角色说话的语气和神态，戏瘾大发的时候常有，于是阅读字幕文件也成了日常。

最开始用 Mac 自带文稿读，无字距行距无排版，看的眼睛生疼。

后来找到 Aegisub，编辑功能足够强大，既能更改字幕样式也能载入音频进行校准...

再后了解到 Pr 、剪映等剪辑软件也是可以自动导入、导出、预览字幕文件，但电脑风扇也同时飞起...

折腾一圈之后，觉得还不如直接用 vscode 打开字幕文本，像 markdown 文件预览那样在侧边也整一个预览面板。

之后就，撸起袖子干活。

### 二、基础功能
- 字幕文件 `.ass`、`.ssa`、`.srt` 语法高亮
- 字幕文件阅读面板
  - 面板内容同步滚动
  - 面板内容同步更新
  - 面板内容样式
  - 主语言样式切换（双语字幕）
- 定制化图标
  - 字幕文件图标
  - 功能按钮图标
  - 插件logo
#### 自定义配置
| 配置项 | 说明 | 默认值 |
| - | - | - | 
| __subtitleReader.autoOpen__ | 字幕文件打开时，是否自动打开阅读面板 | true |
| __subtitleReader.autoClose__ | 字幕文件打开时，是否自动关闭阅读面板 | false |
| __subtitleReader.showDialogueLineNumber__ | 是否展示行数 | true |
| __subtitleReader.style__ | 自定义样式 | {} |

默认用户打开字幕类型文件时，自动打开阅读面板，并展示字幕行数。

### 三、着手开发
#### 1. 数据传递
{% asset_img "extension工作流程图.png" %}

代码主要分为 extension 和 webview 两部分：
- extension 可以看为一个 node 应用，负责命令注册、生成页面内容。
- webview 则是网页是容器，用来完成页面显示和面板交互。

二者通过调用 vscode.postMessage 接口传递数据信息，除此以外，其余部分（编译、开发）都是相对独立的。
#### 2. 热更新、编译打包
vscode 官方提供的命令行工具 vsce 可将项目代码打包成 `.vsix` 文件，也是发布到 marketplace 的最终产物。
`package.json` 中 main 的属性用于设置插件入口文件路径，发布和安装时都会校验以确认插件的可用性。
```
// package.json
{
  ...
  "main": "./dist/extension.js",
  "scripts": {
    "build-extension": "NODE_ENV=production webpack --config ./build/webpack.extension.js",
    "build-panel": "NODE_ENV=production webpack --config ./build/webpack.panel.js",
  }
}

```
两部分编译，extension 打包应用相关代码，webview 打包相关静态文件，最终都输出到 `/dist` 路径下。

##### extension 编译
```sh
extension.ts # 扩展打包入口文件，所需功能接口 & 命令注册
```
dev: 开发模式下会自动打开新的 vscode 调试窗口和测试文件，不支持热更新；
prod: webpack 将以上文件打包到输出路径；

##### webview 编译
```sh
main.scss
main.ts
index.html # 模板文件：不参与编译，需要打包到最终产物里，供 extension 渲染调用
```
dev: `index.html`中的 js、css 路径是动态渲染的。若为开发模式，则会访问本地 dev server 的端口，以支持热更新；
prod: webpack 将以上三个静态文件打包到输出路径；

需要注意的是，若想要在 webview 中加载本地资源，需要将资源文件夹的 uri 提前使用 `localResourceRoots` 注册，如：
```js
const webviewPanel = vscode.window.createWebviewPanel({
  localResourceRoots: [ your assets uri ]
})
```

#### 3. UI 绘制
功能快速开发时，先随便写了一套方便测试，写完自己还觉得挺好，今年回头一看啥也不是（[点我查看](https://github.com/Kuro-P/vscode-subtitle-reader/blob/791a1a4262d02ba4ddeaa1ced9d19ff723c0279b/images/extension-screenshot.png)）...

于是趁着那点为组内分享会筹备的知识还没完全忘记。以紫色为基调，重新绘制了一套。

{% asset_img "UIdesign.png" %}

#### 4. 明暗主题切换
vscode 会在 webview 的 body 元素上注入 `data-vscode-theme-kind` 属性，用来标明用户当前使用的明暗主题，例如暗色主题值为 `vscode-dark`，webview 的 css 就会根据 body 元素此属性的值赋予元素对应的主题颜色。
```scss
@mixin if-dark {
  @at-root {
    body[data-vscode-theme-kind="vscode-dark"] & {
      @content;
    }
    body[data-vscode-theme-kind="vscode-high-contrast"] & {
      @content;
    }
  }
}

@mixin color($dark-color, $color) {
  color: $color;
  @include if-dark {
    color: $dark-color;
  }
}
```

### 四、发布准备
- 打包 extension ( vsce package)
- 优化包体积
  - 压缩图片
  - 生产环境不需要的文件移除（添加至 .vscodeignore 以避免打包）
- 本地测试
  - 在本地 vscode 中安装打包好的测试包（需要更改 package.json 的版本，避免 vscode 使用旧包）
- 发布
  - 通过 marketplace UI 界面手动上传 .vsix 文件
  - 或者通过本地命令行中使用 vsce publish 发布

{% asset_img "marketplace.png" %}

{% asset_img "extension-page.png" "extension page" %}

### 五、开发日志
- 2023.5.5 看文档，完成 srt、ass 文件语法高亮（参照 vscode-subtitles）
- 2023.5.19 预览面板可以根据打开的文件自动打开，但是打开多个文件时 webview 显示有些问题
- 2023.6.7 内容更新已经写完，截止至此，插件的基本功能几乎都有了。本想参照 markdown-all-in-one 做同步滚动，但是 markdown 是滚动同步是双向的。目前只完成了单向同步，留给下次优化了
- 2024.4.30 优化编译脚本，实现 webviewPanel 开发时的热更新
- 2024.5.7 基础功能都已开发完毕，编译命令也调试好了，之后等有空发到 vscode 社区里就可以用了
- 2024.9.16 重新绘制样式和插件图标，统一 UI 风格
- 2024.10.17 发布到 marketplace
- 2024.11.6 添加自动发布 CI

### 六、一些心情
功能实现并不难，重要的是取舍。不必要的想法太多只会耽误时间和进度。
开始和收尾工作同样重要，否则半途而废有头没尾也只是一个再次被抛弃的想法而已。
