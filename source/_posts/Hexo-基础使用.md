---
title: Hexo 基础使用
date: 2018-11-17 12:00:30
tags: [Hexo]
categories: 其他小结
---

记录一下 hexo 基础用法。

<!-- more -->

### 安装
node 环境下，全局安装 hexo-cli
````
npm install hexo-cli -g
````
### 初始化
进入到一个放置 blog 的 **空文件夹**
````
    hexo init 
    hexo generate
    hexo server # 默认4000端口
    hexo s -p 4001 # 在自定义端口启动
````
浏览器输入 localhost:4000，出现 blog 界面

### 换主题
Hexo 官网提供了一些主题  [https://hexo.io/themes/ ](https://hexo.io/themes/) 
* git clone 主题到 blog 项目 `/themes` 文件夹下，将全局 _config.yml 中的 theme 名字更改为 clone 下来的主题文件夹的名字
* 主题中有可供选择的几套样式，更改主题 _config.yml 里的 scheme 属性 
* 设置代码高亮样式 更改主题 _config.yml 里的 hightlight_theme 属性
* 切换 Hexo 语言 修改全局 _config.yml 里的 language 属性，值为 zh-Hans (Hexo 3+) / zh-CN(Hexo 4+) 即为简体中文（默认为英文）
* (更换完主题，需要重启&重新编译应用，方能生效)
* __由于主题也是一个 git 仓库，下载后记得删除 .git 文件，否则主题文件是无法提交的__
* 主题更新：
  * 由于先前已经删除了主题目录下的 `.git` 文件夹，所以无法通过 `git pull` 来更新。每次更新需要将新的代码 clone 到 `/theme` 文件夹中，再手动迁移，比较麻烦，建议有大版本时再更新... 
  
### 生成文章
````
    hexo new "postName" # /source/_post/postName & .md
    hexo new page "pageName" # /source/pageName/index & index.md
    hexo generate # /source/.md -> /public/.html
    hexo server 
    hexo deploy # 将 /public 目录部署到 GitHub
````

### 删除文章
````
    hexo clean # delete /public
    hexo generate # regenerate /public
    hexo deploy
````

### 其他
- **插入本地图片**
每次`hexo new 'postName'`时，都会创建一个与文章名相同的文件夹，将文章所需资源放入该文件夹里，引用时使用 `{% asset_img [文件名] %}` 即可。
- **页面增加“阅读更多”按钮**
在 .md 文件中增加 `<!--more-->` 注释，如果想自动添加“阅读更多”按钮，可在主题下的 `_config.yml` 中将 `auto_excerpt` 下的 `enable` 设置为 `true`。

### 插件
* [hexo-deployer-git](https://github.com/hexojs/hexo-deployer-git) 一键部署到 GitPage
* [hexo-douban](https://github.com/mythsman/hexo-douban) 爬取豆瓣个人条目相关信息
* [hexo-generator-search](https://github.com/wzpan/hexo-generator-search) 全文搜索功能

### 部署
`hexo d` 部署前，需要安装`npm install hexo-deployer-git --save`。
修改全局 `_config.yml` 中的配置：
````
    deploy:
        type: git
        repo: <repository url>
        branch: [branch]
        message: [message]
        name: [git user] 
        email: [git email]
        extend_dirs: [extend directory] # 其他要部署的目录
        ignore_hidden: true # 忽略隐藏文件
        ignore_pattern: regexp # 忽略正则匹配的隐藏文件
````
之后，只需要 `hexo d -g` 一条命令就可以生成和部署了。关于 hexo-deployer-git 这个插件的参数 [hexo 官方文档](https://hexo.io/zh-cn/docs/deployment.html) 介绍的并不全面，建议去 [hexo-deployer-git 官方文档](https://github.com/hexojs/hexo-deployer-git) 查看相关配置参数。

__注意:__ 
* 默认部署，只将生成的 HTML 相关文件（`/public`文件夹）推送到 github
* 若想把本地的生成器项目相关文件也推送到 github，则要配置 `extend_dirs: /`
* message、name、email 的内容要用引号括起来
* name、email 的配置信息用来覆盖全局的 git config 中的配置，更改这两项后，需要删除根目录下的 `.deploy_git` ，部署时才会生效
* master 只能放 `/public` 下的文件，将项目所有文件放到 master 分支下，会导致页面 build 失败。若想将本地代码全部提交，可部署在其他分支（在 `_config.yml` 中增加其他分支配置信息，详情参考文档）
* 避免提交 node_modules，需在项目下新建`.gitignore`文件（为什么不使用 extend_dirs ？因为需要添加的文件夹太多...）
* 若遇见 `Error: EACCES: permission denied, unlink /XXX` 相关的错误，大部分是由没权限引起的，使用 `sudo chown -R `whoami`:staff /blog 目录` 即可

### 自动化部署
1. 使用 github action 脚本自动部署 hexo pages 到目标分支。
当前开发时的源代码在 develop 分支上，静态文件会部署到 master 分支上。 原理其实就是利用 github action events 触发编译操作，在 github 提供的机器上编译后发布到 master 分支。这样就省去了在本地编译的麻烦。
需要注意的是，如果使用 ssh 方式部署，那么需要将 ssh 公钥、秘钥上传到项目中，否则机器没权限提交代码。

部署配置过程参考：https://juejin.cn/post/7014675289728876574

2. 部署后文章的更新时间异常
- __文章更新时间错误__ ：github action 默认时区是 UCT 时间 08:00，比北京时间快 8 个小时。因此运行环境要改为北京时间。（PS：中国一共[五个时区](https://zhuanlan.zhihu.com/p/450867597)，命名是历史原因，北京所在的时区名字就是 Asia/Shanghai）
  ```
  name: Deploy CI
  on:
    push
  env:
    TZ: Asia/Shanghai
  ```
- 所有文章的更新时间都被更新成最新时间：git 在推送更新时，并不保存文件的访问时间、修改时间等信息，故默认取了 github 推送时间，需要将 文件的 update 时间更改为单个文件在 github 上的推送时间。相关文章↓:
  - [hugo 博客 github action 部署后文章更新时间异常修复](https://cloud.tencent.com/developer/article/2298026)
  - [修复 CI 构建博客造成的更新时间错误](https://mrseawave.github.io/blogs/articles/2021/01/07/ci-hexo-update-time/)

### 搜索功能
全局安装插件 `npm install hexo-generator-search --save`
修改全局 `_config.yml`中的配置：
````
    search:
        path: search.xml
        field: post
        content: true
````

修改主题 `themes/next/_config.yml` 中的配置：
````
    local_search:
        enable: true
        trigger: auto
````

生效：`hexo clean`、`hexo g`、`hexo s`

### 图片放大查看功能
在 `themes/next/_config.yml` 文件中，将 `fancybox` 或者 `mediumzoom` 置为 true。 

### Hexo 目录解析
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
[hexo 浅析原理](https://www.jianshu.com/p/a938da5ddb5d)