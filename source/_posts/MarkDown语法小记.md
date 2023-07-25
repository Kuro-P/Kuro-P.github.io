---
title: markdown 语法小记
date: 2018-09-05 18:21:06
tags: [markdown]
categories: 其他小结
---
第一个 hexo-next 主题的 blog，主要记录下 markdown 语法
<!--more-->

### 测试文本样式
#### 测试加粗样式
**加粗**
#### 测试斜体样式
*斜体*
#### 测试删除线样式
~~删除线~~
#### 测试引用样式
> 山穷水尽疑无路，柳暗花明又一村

### 测试代码样式
#### 测试指定代码语言代码样式
````javascript
var FE_developer = {
	name: 'Kuro',
	age: '22'
};

console.log('info', FE_developer);
````
#### 测试单行代码样式
在 JS 中我们常用 `console.log()` 来输出调试信息。

#### 测试代码块样式
```js
function test(a, b){
  setTimeout(function () {
  	console.log(a + b);
  	setTimeout(arguments.callee, 500);
  }, 500)
}
```

### 测试连接样式
百度一下：[Baidu](https://www.baidu.com)

### 测试首行缩进样式
&emsp;&emsp;markdown 语法主要考虑的是英文，中文缩进需要依赖 HTML 的空格符号
````
    半角空格: &nbsp;
    全角空格：&emsp;
````

### 测试表格样式
| 左对齐 | 居中对齐 | 右对齐 |
| - | :-: | -: | 
| Harry Potter | Gryffindor| 90 | 
| Hermione Granger | Gryffindor | 100 | 
| Draco Malfoy | Slytherin | 90 |

表格使用 `|` 来分隔不同的单元格，使用 `-` 来分隔表头和其他行。
__注意：表格前若有文本，需要空一行才能正常显示__


### 测试插入图片
来自百度图片: 

<img src="https://ts1.cn.mm.bing.net/th/id/R-C.b2e807d164d8843a80d4e43d6d2cd14e?rik=vBI7UrFJE09fIQ&riu=http%3a%2f%2fimg95.699pic.com%2felement%2f40114%2f3510.png_860.png&ehk=VVAaXYYnxQaqoogiFcOBZsxixfBN1ZsVpGOfySvfy3Y%3d&risl=&pid=ImgRaw&r=0" width="200" alt="西瓜"/>


### 测试列表
git 常用语法
* git status
* git add .
* git commit -m"XXX"

+ git stash
+ git list
+ git stash apply stash@{n}

- git diff
- git reset --hard

1. 列表内容
   * 列表嵌套第一条
   * 列表嵌套第二条
2. 列表内容
3. 列表内容

### 测试复选框样式
- [x] 选项一
- [ ] 选项二
- [ ] 选项三

### 测试流程图样式
```flow
st=>start: 开始
e=>end: 结束
io1=>inputoutput: 输入聚类类数k
op1=>operation: 筛选初始质心
op2=>operation: 计算样本点到各个质心之间的距离
并将其归到距离其最近的质心所在簇中
op3=>operation: 计算各簇均值，生成新的质心
c1=>condition: 新旧质心距离小于阈值
io2=>inputoutput: 输出聚类结果

st->io1->op1->op2->op3->c1
c1(no)->op2
c1(yes)->io2->e
```

### 其他注意事项
* 在 markdown 中直接使用尖括号`<something>`会被文本默认为HTML标签语句而不予显示。
    * 使用转义字符`&lt;`代替`<`，用`&gt;`代替`>`
    * 或者左闭合的尖括号前加一个转义符号`\`，例如：“\\<something\>”
