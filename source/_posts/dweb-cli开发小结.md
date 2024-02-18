---
title: dweb-cli 开发小结
date: 2023-12-20 16:21:07
tags: [JavaScript ,NodeJS, 开发小结]
categories: [前端]
---
每次都是从老项目中 `Ctrl+C` & `Ctrl+V` 拷贝一份文件目录和编译脚本，然后删删改改就可以跑新项目了。大多项目的编译模块其实都大同小异。于是在 2022 年年中的时候写了一个前端脚手架，主要功能是【生成项目模板】并【统一内部打包工具】。
今年主要是按需维护和更新，从 v1 升级至 v2 ，并剔除第二个功能😲。

<!-- more -->

### 前期准备
- 确定项目名称：好记、一目了然
- 确定主要功能
- 确定依赖版本：调研组内项目、构建工具的 webpack 和 React 版本 
- 确定命令行基础交互功能：参考 vue-cli 和 create-react-app 两个脚手架 
- 确定脚手架项目结构
- 确定生成的模板项目结构：调研组内项目

### 项目搭建
#### 项目名称
脚手架名字定为 dweb-cli ，表示这是一个用于 douban web 项目开发的工具。
#### 主要功能
- 生成通用项目模板
- 集成编译脚本：让用户可以通过 dweb-cli 直接编译脚手架生成的项目、而无需再手动配置。
#### 依赖版本
`Webpack 5`、`React 17.0.2`
#### 命令行交互

__1. 项目创建__
```sh
dweb create <projectName>
```
自定义选项:
- 是否需要 react router
- 是否需要 reset.css
- UI 适配模式：none | flex2rem | viewport
- 是否在创建完成后自动执行 `npm install`

__2. 项目编译__
```sh
dweb run serve # 本地启用 webpack-dev-server 开发
dweb run dev # 开发模式
dweb run build # 生产模式
```
可选参数：
- `-c， --config` 指定 webpack 配置路径
- `-d, --deploy-config` 指定编译完成后的回调函数（文件）路径
- `-e, --entry` 指定要编译的入口名，默认编译全部入口
- `--dev-server-options` 指定 webpack-dev-server 配置路径
- `--free-config` 完全使用的 `--config` 中指定的配置，不使用 cli 自带的默认配置

__3. 其他命令__
```sh
dweb clean # 清理 /dist 文件夹
dweb export <configType> # 导出 cli 中的某项配置到当前目录
```
#### 脚手架目录结构
```sh
 ├── .github/workflows # github ci 配置文件
 ├── .husky # 代码提交相关的钩子配置（eslint）
 ├── bin # npm 注册的命令
 ├── build/utils # 构建工具
 ├── lib # 命令相关的实现
 ├── template # 模板项目
```
   
#### 模板项目目录结构
```
├── README.md
├── deploy.config.js
├── package.json
├── src
│   ├── common
│   │   ├── assets
│   │   ├── components
│   │   │   └── App
│   │   │       ├── index.tsx
│   │   │       └── style.scss
│   │   ├── const
│   │   │   └── index.ts
│   │   ├── types
│   │   │   └── index.d.ts
│   │   └── utils
│   │       └── axios-instance.ts
│   └── pages
│       ├── test
│       │   ├── index.tsx
│       │   └── style.scss
│       └── test1
│           ├── index.tsx
│           └── style.scss
├── tsconfig.json
├── webpack.config.js
└── yarn.lock
```
   
### v1 升级至 v2
v1 试用半年后，发现团队使用习惯更注重灵活性。如果将编译全部集成在 dweb 里，很多小项目定制化配置反倒复杂了一些。且大家对于 dweb 内已集成的 loader 和编译配置实际上并不知晓（很少会点进项目查看），更希望能 __直接__ 看到当前项目的“编译配置”。
所以 v2 版本的 dweb 不再集成编译工作，而是将基础的编译配置放到项目模板中，创建新项目时会自动在新项目中生成一套默认的编译脚本。
#### 其他更新
- 使用 `swc-loader` 替换 `babel-loader` 以减少编译耗时
- 支持第三方插件 css module 单独编译
- 增加 CI、Log 埋点上报、登录状态获取等基础配置
- 增加 页面导航头、ErrorBoundary 等常用组件

### 开发过程中用到的工具
- [commander](https://github.com/tj/commander.js)：命令行参数接收工具
- [chalk](https://github.com/chalk/chalk)：命令行美化工具，用于调整输出信息各字体颜色
- [inquirer](https://github.com/SBoudrias/Inquirer.js)：命令行交互工具，用于获取用户交互结果 并用 promise 返回值
- [ora](https://github.com/sindresorhus/ora)：命令行进度条美化工具
- [handlebars](https://github.com/handlebars-lang/handlebars.js)：模板渲染工具


