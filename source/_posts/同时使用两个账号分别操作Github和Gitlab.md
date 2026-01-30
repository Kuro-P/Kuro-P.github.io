---
title: 同时使用两个账号分别操作 github 和 gitlab
date: 2018-11-17 14:06:50
tags: [git]
categories: git
---
使用多个 git 账号和多个 ssh 连接的场景。思路是通过 SSH config 中为不同的连接指定不同的 key，通过 `git_config` 为不同的目录指定不同的 git 账号。

<!--more-->

### 一、配置 SSH 秘钥

#### 1. 生成并上传秘钥对：
* 生成密钥对：`ssh-keygen -t rsa -C "邮箱地址"`
* 为密钥对设置名称：如公司设置为 `id_rsa`、`id_rsa.pub`，个人设置为 `github_rsa`、`github_rsa.pub`
* 生成密钥的过程中，命令行提示输入 passphrase，用作每次进行 ssh 连接时的确认密码（电脑和账号这里都是个人使用所以直接按回车设置为空就可以）
* 将两份公钥 `id_rsa.pub`、`github_rsa.pub` 分别上传至公司 git 站点 和 个人 git 站点


#### 2. 更改 ssh 配置 
在 `~/.ssh`下创建一个 config 文件，添加配置：

这里的 Host 是对应配置一个别名，自行设置，不可以重复；而 Hostname 则是站点域名或 ip 地址，可以重复。
````
Host github.com
    Hostname github.com
    User git
    IdentityFile ~/.ssh/id_rsa

Host personal.github.com
    Hostname github.com
    User git
    IdentityFile ~/.ssh/github_rsa

Host blog_site_git
    Hostname 123.12.21.321
    User git
    IdentityFile ~/.ssh/blog_site_git.pem
````

#### 3. 测试 SSH 连接
运行 `ssh -T <User>@[Hostname]` 命令测试是否成功，例如 `ssh -T git@personal.github.com`
{% asset_img "test-ssh-connect.png" %}
如果能看到一些 Welcome 信息，说明是 OK 的。


### 二、配置 git 账号
为了使 git 知道提交的用户是谁，需要对账户名进行配置。

可以通过 `git config --global`、`git config --local` 来精细的指定全局/某一个仓库的账号名。
也可以通过 `.gitconfig` 文件来对某一目录下的文件使用单独的配置。

这里记录一下根据文件目录区分配置的方式：
```sh
# .gitconfig
[user]
	name = user_name_1
	email = user_email_1

[includeIf "gitdir:~/personal_projects/**"]
	path = ~/.gitconfig_personal

[includeIf "gitdir:~/work_projects/**"]
	path = ~/.gitconfig_work
```

```sh
# .gitconfig_personal
[user]
	name = user_name_personal
	email = user_email_personal
```

```sh
# .gitconfig_work
[user]
	name = user_name_work
	email = user_email_work
```

设置之后，进入配置中的文件夹执行 `git config user.name` 查看 user.name 是否生效。

### 三、修改本地 git 指向的远端仓库
在 `.ssh/config` 若有同名的 HostName，且设置了 Host 别名后，直接推代码会出现 Access Deny，大概率是因为当前推送代码的账号用的 ssh 连接错误，需要手动指定，如：

```sh
git remote set-url origin git@personal.github.com:Kuro-P/Kuro-P.github.io.git
```
