---
title: 同时使用两个账号分别操作 github 和 gitlab
date: 2018-11-17 14:06:50
tags: [git]
categories: git
---
思路就是通过 SSH config 中为不同的域名指定不同的 SSH key，之后再使用 `git config -- local` 将 github repository 设置成自己的 github 用户账号。

<!--more-->

### 一、生成 SSH 秘钥
分别生成 github、gitlab 所需密钥：

* 使用 `ssh-keygen -t rsa -C "邮箱地址"` 生成两份密钥对
* 分别命名为 `id_rsa、id_rsa.pub` 和 `github_rsa、github_rsa.pub`
* 生成密钥的过程中，命令行提示输入 passphrase，用作每次进行 ssh 连接时的确认密码（电脑和账号这里都是个人使用所以直接按回车设置为空就可以）
* 将两份公钥 `id_rsa.pub`、`github_rsa.pub` 分别上传至 gitlab、github
* 由于 ssh 连接默认查找的都是私钥路径为 ~/.ssh/id_rsa，所以需要为 github 手动指明所需私钥 github_rsa，否则会报错 Permission denied (publickey) 
* 在 `~/.ssh`下创建一个 config 文件，添加配置：
````
Host github.com
    Hostname ssh.github.com
    Port 443
    User git
    IdentityFile ~/.ssh/github_rsa
````
_注意：若为 github 中配置了两个同名 ssh，那么 config 中谁在前谁生效_

### 二、测试 SSH 连接
运行`ssh -T github` 命令测试是否配置成功。
{% asset_img "test-ssh-connect.png" %}
如果能看到一些 Welcome 信息，说明是 OK 的。

### 三、配置多个 git 用户名/邮箱
为了使 git 知道提交的用户是谁，需要对账户名进行配置。由于全局配置是公司的账号，所以只需对自己想要进行操作的 git 库进行配置即可。

#### 1. 单独配置某个 git 库
使用 `git config` 为不同代码库单独指定用户名。

````
    git config --local user.name 'username' # github账号名称
    git config --local user.email 'username@gmail.com' # github账号邮箱
````

设置之后，在当前 git 库下使用 `git config --get user.name` 查看用户名是否设置成功。
缺点是当代码库多的时候，每次都需要重新指定，有点麻烦。

#### 2. 同时配置多个 git 库
在全局配置中 `~/,gitconfig` 指定某个文件夹下所有 git 库使用的配置文件。
```
[user]
	name = Kuro-P
	email = XXXX@XXXX.com

[includeIf "gitdir:~/githubProjects/"]
	path = ~/.gitconfig_github
```
设置之后，进入当前文件夹下任一 git 库中查看 user.name 是否生效。
这种方式能解决大部分场景，批量操作方便。 