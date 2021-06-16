---
title: Linux命令行与shell脚本学习
date: 2018-11-30 16:00:10
tags: [Linux&shell]
categories: 计算机相关知识
---
《Linux命令行与shell脚本编程大全》读书小结，熟悉一下常用的命令行操作。书籍比较基础，对熟悉Linux命令行的人来说参考意义不大。主要记录下书中提到的、没提到的常用的命令。
<!--more-->
### 基础操作
* . 代表当前目录
* .. 代表父级目录
* ~ 代表根目录 表名当前工作目录位于用户home目录之下
* man <directive\> 可查看指令可使用的参数手册
* `tab` 键自动补全文件名
* cd 切换目录
* linux 中的文件路径全部采用正斜线`/`，windows中的路径都是反斜线`\`而且带盘符
* ls 列出当前路径下的所有文件
    * -F 在显示子目录的时候在它的文件名之后加上一个斜线(“/”)字符
    * -F -R 遍历(递归)出当前目录下的子文件夹的所有内容(可以缩写成 ls -FR )
    * -a 列出所有文件，包括隐藏文件
    * -l 列出文件的所有信息
* pwd 查看当前所在位置的全路径
* sudo 以 root 用户身份运行命令
  
### 文件基础操作
* open <fileName\> 用默认程序打开文件
  * open <AppName> --args <参数> 用默认参数打开某个App
* touch <fileName\> 创建一个文件 (不可在不存在的目录下新建文件)
* mkdir <directory\> 创建一个文件夹
    * -p 创建多个层级的文件夹
* rmdir <directory\> 只删除空目录
    * 在非空目录下使用 rm -r 命令
* cp <fileName\> <targetDirectory/fileName> 复制文件到目标文件夹/文件名
    * -i 强制 shell 询问是否覆盖同名文件
* scp <fileName\> <root@targetPath> 远程拷贝文件 可以跨服务器
* mv <fileName\> <directory/fileName> 用来 移动/重命名 文件
    * -i 强制 shell 询问是否覆盖同名文件
* rm <fileName\> 删除文件/文件夹中的所有内容
    * -i 强制 shell 询问是否删除文件
    * -f 强制删除，没有警告信息也没有声音提示
    * -r 递归删除目录及目录内所有文件  
    * __注意：Linux 中没有回收站或垃圾箱，文件一旦删除，就无法再找回__
* ls -l <fileName\> 查看文件权限
* chmod value <fileName\> 更改文件权限
  * 权限描述顺序依次是：Owner(User)、Group、Other
  * r=读取属性 //值=4
  * w=写入属性 //值=2
  * x=执行属性 //值=1
  ![文件权限](/file-permissions.png)
* chown(选项)(参数) 更改文件夹所有者和所属组
  * chown -R user:group .git 将.git文件夹的权限设置为 group 下的 user
* 获取文件路径：直接将文件拖入命令行即可
  
### 文件内容操作
* file <fileName/directoryName\> 查看文件类型信息
* du <fileName/directoryName\> 用来查看文件或目录所占用的磁盘空间的大小
    * -h 以易于阅读的方式展示
    * -a 显示目录及其下子目录和文件占用的磁盘空间大小
    * -s 只展示当前目录占用磁盘空间大小
* cat/more/less <fileName\> 查看整个文件内容
    * cat 一次性加载完所有文件内容
    * more 一次显示一屏文本
    * less 一次显示一屏文本 可以上下页翻建
* tail/head <fileName\> 查看部分文件内容
    * tail 默认展示文件最后10行的效果
        * -n 2 只显示文件最后两行
        * -f 允许其他进程使用该文件时查看该文件的内容，tail会保持活跃状态，并不断显示添加到文件中的内容。（可用来实时监测系统日志）
    * head 默认展示文件前10行内容
        * 不支持 -f 属性
* grep match_pattern <fileName\> 强大的文本搜索工具，可以使用正则表达式搜索文本，并显示出匹配的行数
* sed -i 's/被替换的内容/要替换的内容/g' file  -i 表示直接修改并保存
    * [使用 sed 命令，报错`invalid command code`](https://blog.csdn.net/u010339879/article/details/90107977)，是因为 -i 原地替换是危险行为，需要指明一个备份的扩展名才可以，若给了空的扩展名，则不会备份源文件。
    * 如 sed -i '' 's/被替换的内容/要替换的内容/g' file
* ls -> xxx.txt 将命令输出的内容保存为文件


### 监控进程
* ps 显示进程信息（瞬间占用情况）
* top 显示进程信息（实时占用情况）
* lsof 查看进程打开的文件
    * lsof -i:4000 查看4000端口占用情况
* kill [PID] 杀死对应进程
  
### 网络情况
* ping <ip\> 测试主机之间的连通性(不会自动结束，需要手动 ctrl + c 强制退出)
* dig <url\> 域名查询工具，可以用来测试域名系统工作是否正常
* nsloopup <url\> 域名查询工具，查询 DNS 相关信息

### 变量
#### 环境变量
* printenv/env 默认输出所有环境变量（全局）
    * printenv JAVA_HOME 输出全局设置的JAVA SDK位置
    * env $JAVA_HOME 
    * echo $JAVA_HOME 
* echo $variableName 输出变量 ($用来表名它是个变量)
* set 输出所有环境变量（全局和局部）
* $HOME 表示的用户的主目录，与波浪线`~`作用一样

#### 普通变量
声明时直接声明即可使用 `variable=XXX`，变量名区分大小写，但需要注意的是 __赋值时，变量名、等号和值之间没有空格__ 否则会报错 `command not found`。
常用的书写习惯是 __所有的环境变量名均使用大写字母，若是自己创建的局部变量或是shell脚本，则用小写字母，变量名区分大小写。__

### vim 操作
* vim <fileName\> 以 vim 编辑器的方式查看当前文件
* 按 `I` 对文件进行 INSERT 操作
* 按 `esc` 退出当前编辑模式
* 输入 `:` 切换到底线命令模式，可以在最底行输入其他命令
* 输入 `wq` ，保存并退出；输入 `!q`，不保存直接退出
* .swp 文件: 非正常关闭的 vim 编辑器会生成一个 .swp 文件

### 杂项
#### 大小写转换
* echo $VAR_NAME | tr '[:upper:]' '[:lower:]'
* echo $VAR_NAME | tr '[A-Z]' '[a-z]'

### 其他
* alias 可用来查看当前可用的别名(内建命令)
  * alias 新的命令='原命令 -选项/参数' 用来定义命令别名
* sh <fileName.sh\> 执行shell文件
* .xxxrc 可以看做是xxx启动运行时的配置文件
    * 例如 .zshrc 就是 zsh 运行前要执行配置文件
* source <fileName\> 或者 . <fileName\> (bash内部命令) 加载文件
* 文件\包查找
  * which <fileName\> 查找该包编译器所在位置
  * whereis <fileName\> 搜索更大范围的系统目录并输出所有包含的路径
  * find <fileName\> 查找系统是否安装了某个软件包

### 代理
* [参考](https://www.jianshu.com/p/c99373ad37f7)
* 若想要在当前终端中生效，直接输入 `export http_proxy='http://ip_address:port'` 即可，注意 ip 和端口号是本机的 ip + port;
* 想要持久化全局生效的话，可以在 .zhsrc 中配置上述命令

### 常用的配置文件地址
* Host 文件 /etc/hosts
* 配置的 SSH Key: cat ~/.ssh/id_rsa.pub

### 常见文件颜色
* 白色：表示普通文件
* 蓝色：表示目录
* 绿色：表示可执行文件
* 红色：表示压缩文件
* 浅蓝色：链接文件
* 红色闪烁：表示链接的文件有问题
* 黄色：表示设备文件
* 灰色：表示其他文件

### 插件
* homebrew 包管理器
    * brew install <packageName\> 安装插件
    * brew list 查看电脑安装了哪些插件
    * 注：每次下载包之前都会进行 brew 更新检查，速度很慢，按一次 `Ctrl+C` 跳过更新
* wget 下载网页常用的工具
* curl 模拟 http 请求，类似于 POSTMAN
    * curl <url\> 直接返回 url 请求结果
* tree 以树状图形式展示目录及其子文件
    * tree <directory\> -J 以 json 形式展示文件
* tig 将git命令行可视化

__其他参考:__
* __[Linux命令大全](http://man.linuxde.net/)__
* __[Linux命令英文缩写的含义](http://blog.chinaunix.net/uid-27164517-id-3299073.html)__
* __[Shell基础](http://c.biancheng.net/shell/base/)__
