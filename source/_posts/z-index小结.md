---
title: z-index小结
date: 2019-08-05 16:36:13
tags: [CSS]
categories: [前端, CSS]
---
z-index 这东西简单的用法大家都会用，但是当多个规则多个层级共同作用时，展现的效果往往跟自己的想法有很大差异，论 CSS 基本功的重要性。本文总结了 CSS 层叠的特性、基本准则和创建条件，内容大多参考了张鑫旭大神的《CSS世界》。
<!--more-->

### 层叠的基本概念
* 层叠上下文(stacking context)：当前元素所处的层叠规则，即元素所处的 z 轴。一个页面中，层叠上下文不止一个。
* 层叠水平(stacking level)：同一个层叠上下文中元 素在 z 轴上的显示等级。
* 层叠顺序(stacking order)：
  * background/border 指在同一层叠上下文元素的边框和背景色。
  * inline水平盒子指的是包括inline/inline-block/inline-table元素的“层叠顺序”，它们都是同等级别的。
  * 内联元素的层叠顺序要比浮动元素和块状元素都高，是因为float元素在起始时是作为布局元素存在的。由于“内容”的重要性远大于“装饰”和“布局”，所以内容元素层叠顺序比较高，详情见下图：
![层叠顺序图](/stacking-order.png)

### z-index
__z-index 属性只有和定位元素(position 不为 static 的元素)在一起的时候才有作用，可以是正数也可以是负数。在同一层叠上下文中，数值越大层级越高。__ 在CSS3中，z-index 已经并非只对定位元素有效，flex 盒子的子元素 也可以设置 z-index 属性。

#### 层叠准则
1. 谁大谁上：在同一个层叠上下文领域，具有明显的层叠水平标识的时候，层叠水平值大的那一个覆盖小的那一个，例如 z-index 属性值。
2. 后来居上：当元素的层叠水平一致、层叠顺序相同的时候，在 DOM 流中处于后面的元素会覆盖前面的元素。

#### 层叠上下文的特性
* 层叠上下文的层叠水平要比普通元素高。
* 层叠上下文可以阻断元素的混合模式。
* 层叠上下文可以嵌套，内部层叠上下文及其所有子元素均受制于外部的“层叠上下文”。
* 每个层叠上下文和兄弟元素独立，也就是说，当进行层叠变化或渲染的时候，只需要考虑后代元素。
* 每个层叠上下文是自成体系的，当元素发生层叠的时候，整个元素被认为是在父层叠上下文的层叠顺序中。

#### 页面中的层叠上下文
* __根层叠上下文__：页面根元素具</html>有层叠上下文，称为“根层叠上下文”。故页面中所有的元素至少处于一个层叠上下文中。
* __定位元素与传统层叠上下文__：对于 position 值为 relative/absolute 以及 Firefox/IE 浏览器(不包括 Chrome 浏览 器)下含有 position:fixed 声明的定位元素，当其 z-index 值不是 auto 的时候，会创建层叠上下文(__z-index 一旦变成数值，即使是 0，也创建一个层叠上下文__)。
* __CSS3新属性的层叠上下文__：
  * 元素为 flex 布局元素(父元素 display:flex|inline-flex)，同时 z-index 值不是 auto。
  * 元素的 opacity 值不是 1
  * 元素的 transform 值不是 none。
  * 元素 mix-blend-mode 值不是 normal。
  * 元素的 filter 值不是 none。
  * 元素的 isolation 值是 isolate。
  * 元素的 will-change 属性值为上面 2~6 的任意一个(如 will-change:opacity、will-chang:transform 等)。
  * 元素的-webkit-overflow-scrolling 设为 touch。

#### CSS3 属性与 z-index 的兼容性问题
1. Safari 3D变换会忽略 z-index[(解决方案)](https://blog.csdn.net/sherry_0706/article/details/52593888)