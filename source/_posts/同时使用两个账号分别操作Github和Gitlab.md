---
title: 同时使用两个账号分别操作 github 和 gitlab
date: 2018-11-17 14:06:50
tags: [git]
categories: git
---
思路就是通过 SSH config 中为不同的域名指定不同的 SSH key，之后再使用 `git config -- local` 将 github repository 设置成自己的 github 用户账号。

<!--more-->

### 一、生成SSH秘钥
分别生成 github、gitlab 所需密钥：

* 使用 `ssh-keygen -t rsa -C "邮箱地址"` 生成两份密钥对
* 分别命名为 `id_rsa、id_rsa.pub` 和 `github_rsa、github_rsa.pub`
* 生成密钥的过程中，命令行提示输入 passphrase，用作每次进行 ssh 连接时的确认密码（电脑和账号这里都是个人使用所以直接按回车设置为空就可以）
* 将两份公钥 `id_rsa.pub`、`github_rsa.pub` 分别上传至 gitlab、github
* 由于 ssh 连接默认查找的都是私钥路径为 ~/.ssh/id_rsa，所以需要为 github 手动指明所需私钥 github_rsa，否则会报错 Permission denied (publickey) 
* 在 `~/.ssh`下创建一个 config 文件，添加配置：
````
Host github
    Hostname ssh.github.com
    Port 443
    User git
    IdentityFile ~/.ssh/github_rsa
````
_注意：若为 github 中配置了两个同名 ssh，那么 config 中谁在前谁生效_

### 二、测试连接
运行`ssh -T github` 命令测试是否配置成功。
{% asset_img "test-ssh-connect.png" %}
如果能看到一些 Welcome 信息，说明是 OK 的。

### 三、配置 git 库账号
为了使 github / gitlab 知道提交的用户是谁，需要对账户名进行配置。由于全局配置是公司的账号，所以只需要对自己想要进行操作的 github 库进行本地配置即可。
````
    git config --local user.name 'username' # github账号名称
    git config --local user.email 'username@gmail.com' # github账号邮箱
````
或者直接 init 一个 git 库，配置后 github 的代码都在这个仓库下拉取。
