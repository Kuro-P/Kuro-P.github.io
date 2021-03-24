---
title: Hexo 基础使用
date: 2018-11-17 12:00:30
tags: [Hexo]
categories: 其他小结
---

### 安装
node 环境下，全局安装 hexo-cli
````
npm install hexo-cli -g
````
### 初始化
进入到一个放置blog的**空文件夹**
````
    hexo init 
    hexo generate
    hexo server # 默认4000端口
    hexo s -p 4001 # 在自定义端口启动
````
浏览器输入localhost:4000，出现blog界面

### 换主题
Hexo官网提供了一些主题  [https://hexo.io/themes/ ](https://hexo.io/themes/) 
* git clone 主题地址到 blog 目录下，将全局_condig.yml中的theme名字改为clone下来的文件夹的名字
* 主题中有可供选择的几套样式，更改主题 _config.yml 里的 scheme 
* 设置代码高亮样式 更改主题 _condig.yml 里的 hightlight_theme
* 切换Hexo语言 在全局 _condig.yml 里的 language 改成 zh-Hans 即为主题下的简体中文（默认为英文）
* (更换完主题，需要重启应用，方能生效)
* __由于主题也是一个git仓库，下载后记得删除.git文件，否则主题文件是无法提交的__
  
### 生成文章
````
    hexo new "postName" # /source/_post/postName & .md
    hexo new page "pageName" # /source/pageName/index & index.md
    hexo generate # /source/.md -> /public/.html
    hexo server 
    hexo deploy #将.deploy目录部署到GitHub
````

### 删除文章
````
    hexo clean # delete /public
    hexo generate # regenerate /public
    hexo deploy
````

### 其他
- **插入本地图片**
每次`hexo new 'postName'`时，都会创建一个与文章名相同的文件夹，将文章所需资源放入该文件夹里，引用的时候直接写文件名即可。
- **页面增加“阅读更多”按钮**
在 .md 文件中增加`<!--more-->`注释，如果想自动添加“阅读更多”按钮，可在主题下的`_config.yml`中将`auto_excerpt`下的`enable`设置为`true`。

### 插件
* [hexo-deployer-git](https://github.com/hexojs/hexo-deployer-git) 一键部署到 GitPage
* [hexo-douban](https://github.com/mythsman/hexo-douban) 爬取豆瓣相关信息
* [hexo-generator-search](https://github.com/wzpan/hexo-generator-search) 全文搜索功能

### 部署
`hexo d`部署前，需要安装`npm install hexo-deployer-git --save`。
修改全局 `_config.yml` 中的配置：
````
    deploy:
        type: git
        repo: <repository url>
        branch: [branch]
        message: [message]
        name: [git user] 
        email: [git email]
        extend_dirs: [extend directory] #其他要提交的目录
        ignore_hidden: true #忽略隐藏文件
        ignore_pattern: regexp #忽略正则匹配的隐藏文件
````
之后，只需要`hexo d -g`一条命令就可以生成和部署了。关于 hexo-deployer-git 这个插件的参数[hexo官方文档](https://hexo.io/zh-cn/docs/deployment.html)介绍的并不全面，建议去[hexo-deployer-git官方文档](https://github.com/hexojs/hexo-deployer-git)查看相关配置参数。

__注意:__ 
* 默认部署，只将生成的HTML相关文件(/public)推送到 github
* 若想把本地的生成器项目相关文件也推送到 github，则要配置 `extend_dirs: /`
* message、name、email 的内容要用引号括起来
* name、email 的配置信息用来覆盖全局的 git config 中的配置，更改这两项后，需要删除根目录下的`.deploy_git`，部署时才会生效
* master 只能放`/public`下的文件，将项目所有文件放到 master 分支下，会导致页面 build 失败。若想将本地代码全部提交，可部署在其他分支（在`_config.yml`中增加其他分支配置信息，详情参考文档）
* 不提交 node_modules 的话，注意在项目下新建`.gitignore`文件（为什么不使用 extend_dirs ？因为需要添加的文件夹太多...）
* 若遇见 `Error: EACCES: permission denied, unlink /XXX` 相关的错误，大部分是由没权限引起的，使用 `sudo chown -R `whoami`:staff /你的blog目录` 即可

### 搜索功能
全局安装插件`npm install hexo-generator-search --save`
修改全局`_config.yml`中的配置：
````
    search:
        path: search.xml
        field: post
        content: true
````

修改主题`themes/next/_config.yml`中的配置：
````
    local_search:
        enable: true
        trigger: auto
````

生效：`hexo clean`、`hexo g`、`hexo s`
### Hexo目录解析
````
    ├── node_modules # 依赖包-安装插件及所需nodejs模块。
    ├── public  # 最终网页信息。即存放通过 markdown 渲染出来的 html文件。
    ├── scaffolds # 模板文件夹。即新建文章时，根据 scaffold 生成文件。
    ├── source  # 资源文件夹。即存放用户资源。
    |   └── _posts # 博客文章目录。
    └── themes #存放主题。Hexo根据主题生成静态页面。
    ├── _config.yml #网站的全局配置信息。标题、网站名称等。
    ├── db.json：# source 解析所得到的缓存文件。
    ├── package.json  # 应用程序信息。即配置Hexo运行需要js包。
````

### 参考资料
[利用 hexo + Gitpage 开发自己的博客](https://cherryblog.site/Use-Gitpagehexo-to-develop-their-own-blog.html)
[hexo浅析原理](https://www.jianshu.com/p/a938da5ddb5d)