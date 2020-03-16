---
title: 同时使用两个账号分别操作Github和Gitlab
date: 2018-11-17 14:06:50
tags: [git]
categories: git
---
公司用 gitlab 存管代码，自己用 github 。懒得下班后用自己电脑提交到 github ，故学习一下如何在同一台电脑上使用两个 git 账号。在 SSH config 中为不同的域名指定不同的 SSH key，之后再将自己本地的 github 库的 git config -- local 设置成自己的 github 账号。
<!--more-->
### 一、生成SSH秘钥
分别对githubn和gitlab生成对应的密钥
* 用`ssh-keygen -t rsa -C "公司邮箱地址"`生成对应的gitlab密钥：id_rsa和id_rsa.pub
* 将 gitlab 公钥(id_rsa.pub)中的内容配置到公司的gitlab上
* 用`ssh-keygen -t rsa -C "自己邮箱地址" -f ~/.ssh/github_rsa`生成对应的github密钥：github_rsa 和 github_rsa.pub
* 生成公私钥的过程中，会提示你输入`passphrase`，用作每次进行 ssh 连接时的确认密码。由于电脑和账号都是个人使用所以直接按回车设置为空就可以了
![设置 passphrase](/enter-passphrase.png)
* 将 github 公钥(github_rsa.pub)中的内容配置到自己的github上
* 到目前为止本地 ~/.ssh 中已经存在 github_rsa、github_rsa.pub、id_rsa、id_rsa.pub 四个文件了，由于 github 和 gitlab 建立连接默认查找的都是~/.ssh/id_rsa，所以需要为 github 手动指明使用的私钥名称 github_rsa，否则会报错 <span style="color: #c7254e; background: #f2f2f2"> Permission denied (publickey) </span>
* 进入密钥生成的位置，创建一个 config 文件，添加配置：
````
    # githab
    Host github.com
        HostName github.com
        User kuro-p
        IdentityFile ~/.ssh/github_rsa
````
### 二、测试连接
运行`ssh -T git@hostName`命令测试 ssh key 对 gitlab 与 github的连接
![测试连接是否正常](/test-ssh-connect.png)
如果能看到一些 Welcome 信息，说明是 OK 的。
### 三、配置 git 库账号
为了使 github / gitlab 知道提交的用户是谁，需要对账户名进行配置。由于全局配置是公司的账号，所以只需要对自己想要进行操作的 github 库进行本地配置即可。
````
    git config --local user.name 'username' # github账号名称
    git config --local user.email 'username@gmail.com' # github账号邮箱
````
或者直接 init 一个 git 库，配置后 github 的代码都在这个仓库下拉取。

### 参考资料
[如何在同一台电脑上使用github和gitlab](https://segmentfault.com/a/1190000014626841?utm_source=channel-hottest)
[同时使用两个账号分别操作Github和Gitlab](https://blog.csdn.net/mycafe_/article/details/79231599)
[由于SSH配置文件的不匹配，导致的Permission denied (publickey)及其解决方法](http://www.cnblogs.com/lpdi/p/6816380.html)