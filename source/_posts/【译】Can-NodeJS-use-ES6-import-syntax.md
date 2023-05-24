---
title: 【译】Can NodeJS use ES6 import syntax ?
date: 2020-12-10 20:36:12
tags: [NodeJS, 翻译]
categories: [后端]
---
偶然在一篇文章中看到 Node 可以使用 import 语法了，无需再使用 babel 做额外的转换，遂去了解下 Node 相关的更新。本文主要介绍在最新版本 Node(14.15.1) 中如何使用 import 语法。大部分内容翻译自官网和外网文章。关于 JS 模块机制之前已经总结过一篇[文章](/2019/01/03/前端模块化/#more)，这里不再赘述。

（ PS：原本是公司部门要求的 kpi 文章，现做了精简 ）
<!--more-->

## 概览
本文主要内容：
* Node 对 ES Modules 的支持
* 在 Node 使用 import 语法
* Node 中 ES Modules 的现状和未来

## Node 对 ES Modules 支持
Node 13.2.0 开始正式支持 ES Modules 特性（移除了 --experimental-modules 启动参数）.

注意：相关的 ESM 的实验性标志都虽然被移除
（但是由于 ESM loader 还是实验性的，所以运行 ES Modules 代码依然会有警告：
````bash
(node:47324) ExperimentalWarning: The ESM module loader is experimental.
````

## 在 NodeJS 中使用 ES Modules
使 Node 支持 ES modules 有两种方式：
1. 在 package.json中，增加 `type: "module"`配置，即可在 node 代码中使用 `import`和`export`语法:

文件目录结构：
````bash
.
├── index.js
├── package.json
└── utils
    └── speak.js
````

````javascript
// utils/speak.js
export function speak() {
  console.log('Come from speak.')
}

// index.js
import { speak } from './utils/speak.js';
speak(); //come from speak
````

2. 在 .mjs 文件中直接使用 `import`和`export`；

文件目录结构：
````bash
.
├── index.mjs
├── package.json
└── utils
    └── sing.mjs
````

````javascript
// utils/sing.mjs
export function sing() {
  console.log('Come from sing')
}

// index.mjs
import { sing } from './utils/sing.mjs';
sing(); //come from sing
````

注意：
  * 若不添加上述两项中任一项，直接使用在 Node 中使用 ES modules，则会抛出警告：
  ````bash
  Warning: To load an ES module, set "type": "module" in the package.json or use the .mjs extension.
  ````
  * __根据ESM规范，使用import关键字并不会像 CommonJS 模块那样，在默认情况下以文件扩展名完成文件路径。因此，ES Modules 必须明确文件扩展名。__

### 模块作用域
一个模块的作用域，由父级中有 `type: "module"` 的 package.json 文件路径定义。而使用`.mjs`扩展文件加载模块，则不受限于包的作用域。
同理，`package.json`中没有`type`标志的包都会默认采用 CommonJS 模块机制，`.cjs`类型的扩展文件使用 CommonJS 方式加载模块同样不受限于包的作用域。

### 包的入口
定义包的入口有两种方式，在 package.json 中定义`main`字段或者`exports`字段
````javascript
{
  "main": "./main.js",
  "exports": "./main.js"
}
````
需要注意的是，当`exports`字段被定义后，包的所有子路径都将被封装，子路径的文件不可再被导入。例如 require('pkg/subpath.js') 将会报错：
````bash
ERR_PACKAGE_PATH_NOT_EXPORTED error.
````
参考官方文档：https://nodejs.org/api/packages.html#packages_main_entry_point_export

### 两个模块机制在执行时机上的区别
* ES Modules 导入的模块会被预解析，以便在代码运行前导入：
  * 根据 EMS 规范 import / export 必须位于模块顶级，不能位于作用域内；
  * 模块内的 import/export 会提升到模块顶部；
* 在 CommonJS 中，模块将在运行时解析；

举一个简单的例子来直观的对比下二者的差别：
````javascript
// ES Modules

// a.js
console.log('Come from a.js.');
import { hello } from './b.js';
console.log(hello);

// b.js
console.log('Come from b.js.');
export const hello = 'Hello from b.js';
````
输出：
````bash
Come from b.js.
Come from a.js.
Hello from b.js
````

同样的代码使用 CommonJS 机制：
````javascript
// CommonJS

// a.js
console.log('Come from a.js.');
const hello = require('./b.js');
console.log(hello);

// b.js
console.log('Come from b.js.');
module.exports = 'Hello from b.js';
````
输出：
````bash
Come from a.js.
Come from b.js.
Hello from b.js
````
可以看到 ES Modules 预先解析了模块代码，而 CommonJS 是代码运行的时候解析的。

### 两个模块在原理上的区别

1. CommonJS

Node 将每个文件都视为独立的模块，它定义了一个 Module 构造函数，它代表模块自身：
````javascript
function Module(id = '', parent) {
  this.id = id;
  this.path = path.dirname(id);
  this.exports = {};
  this.parent = parent;
  this.filename = null;
  this.loaded = false;
  this.children = [];
};
````

而 require 函数接收一个代表模块ID或者路径的值作为参数，它返回的是用`module.exports`导出的对象。在执行代码模块之前，NodeJs 将使一  个包装器对模块中的代码其进行封装：
````javascript
(function(exports, require, module, __filename, __dirname) { 
    // Module code actually lives in here 
}); 
````

> 引自 NodeJS 官网
> 
> 通过这样做，Node.js 实现了以下几点：
> * 它保持了顶层的变量（用 var、 const 或 let 定义）作用在模块范围内，而不是全局对象。
> * 它有助于提供一些看似全局的但实际上是模块特定的变量，例如：
>   * 实现者可以用于从模块中导出值的 module 和 exports 对象。
>   * 包含模块绝对文件名和目录路径的快捷变量 __filename 和 __dirname 。

简言之，每个模块都有自己的函数包装器， Node 通过此种方式确保模块内的代码对它是私有的。在包装器执行之前，模块内的导出内容是不确定的。
除此之外，第一次加载的模块会被缓存到 `Module._cache`中。一个完整的加载周期大致如下：
````bash
  Resolution (解析) –> Loading (加载) –> Wrapping (私有化) –> Evaluation (执行) –> Caching (缓存)
````

2. ES Modules

在 ESM 中，import 语句用于在解析代码时导入模块依赖的静态链接。文件的依赖关系在编译阶段就确定了。对于 ESM，模块的加载大致分为三步：
````bash
  Construction (解析) -> Instantiation (实例化、建立链接) -> Evaluation (执行)
````
这些步骤是异步执行的，每一步都可以看作是相互独立的。这一点跟 CommonJS 有很大不同，对于 CommonJS 来说，每一步都是同步进行的。

### 两种模块间的相互引用
CommonJS 和 ES Modules 都支持 `Dynamic import()`。它可以支持两种模块机制的导入：
#### 在 CommonJS 文件中导入 ES Modules 模块
由于 ES Modules 的加载、解析和执行都是异步的，而 require() 的过程是同步的、所以不能通过 require() 来引用一个 ES6 模块。ES6 提议的 import() 函数将会返回一个 Promise，它在 ES Modules 加载后标记完成。借助于此，我们可以在 CommonJS 中使用异步的方式导入 ES Modules：
````javascript
// 使用 then() 来进行模块导入后的操作
import("es6-modules.mjs").then((module)=>{/*…*/}).catch((err)=>{/**…*/})
// 或者使用 async 函数
(async () => {
  await import('./es6-modules.mjs');
})();
````

### 在 ES Modules 文件中导入 CommonJS 模块
在 ES6 模块里可以很方便地使用 import 来引用一个 CommonJS 模块，因为在 ES6 模块里异步加载并非是必须的：
````javascript
import { default as cjs } from 'cjs';

// The following import statement is "syntax sugar" (equivalent but sweeter)
// for `{ default as cjsSugar }` in the above import statement:
import cjsSugar from 'cjs';

console.log(cjs);
console.log(cjs === cjsSugar);
````

## Node 中 ES Modules 的现状和未来
在引入 ES6 标准之前，服务器端 JavaScript 代码都是依赖 CommonJS 模块机制进行包管理的。
如今，随着 ES Modules 的引入，开发人员可以享受到与发布规范相关的许多好处。但需要注意的是，截止至当前时间(2020.11.30)，在最新版 Node v15.1.0 中，该特性依然是实验性的（Stability: 1），不建议在生产环境中使用该功能。

最后，由于两种模块格式之间存在不兼容问题，将当前项目从 CommonJS 到 ES Modules 转换将是一个很大的挑战。可以借助 Babel 相关插件实现 CommonJS 和 ES Modules 间的相互转换：
* [plugin-transform-modules-commonjs](https://babel.docschina.org/docs/en/babel-plugin-transform-modules-commonjs)
* [babel-plugin-transform-commonjs](https://www.npmjs.com/package/babel-plugin-transform-commonjs)

## 参考链接
### 翻译原文
* [es-modules-in-node-today](https://blog.logrocket.com/es-modules-in-node-today/)
* [an-update-on-es6-modules-in-node-js](https://aotu.io/notes/2017/04/22/an-update-on-es6-modules-in-node-js/index.html)

### 官方文档
* [Node Documentation](https://nodejs.org/dist/latest-v14.x/docs/api/modules.html)
* [Node version13+ release log](https://github.com/nodejs/node/blob/master/doc/changelogs/CHANGELOG_V13.md#13.4.0)
* [Node version14+ release log](https://github.com/nodejs/node/blob/master/doc/changelogs/CHANGELOG_V14.md#14.15.0)
* [Node modules wrapper](https://github.com/nodejs/ecmascript-modules/blob/modules-lkgr/doc/api/modules.md#the-module-wrapper)
* [Node Source code: cjs](https://github.com/nodejs/node/blob/master/lib/internal/modules/cjs/loader.js#L195)
* [ECMA262 Modules](https://tc39.es/ecma262/#sec-modules)
* [TC39 Proposal Dynamic import](https://github.com/tc39/proposal-dynamic-import)
