# Kuro-P.github.io
My blog record. [https://kuro-p.github.io/](https://kuro-p.github.io/)

### Branch develop
If there's some files you don't want to commit, please use `.gitignore` but not hexo-deployer-git.

### 2019.11.14
Hexo's Blog use `hexo-deployer-git` deploy on master.<br/>
Other develop files use `git` deploy on develop.<br/>
Use `npm run deploy` to deploy both of these things to the branch.<br/>

### 2020.7.9
__Develop on Windows:__
1. Use `hexo g` to generate html files.
2. Use `hexo douban` to fetch data on Douban. 
3. Use `hexo deploy` to deploy your files on Github Pages & Private server. And don't forget to change your server ip in `_config.yml` before deploy.
4. Then commit files to `develop` branch.

PS: .sh file have too many errors on Windows 

__Develop on MacOS:__
* Use `npm run deploy` to deploy and commit files to master and develop branch.

### 2022.1.7
* hexo-douban only can work in Node 12.18.4 or older version.
  * referer: https://github.com/mythsman/hexo-douban/issues/77
* hexo deploy work env as same as hexo-douban.


Problems:

* git warning  `LF will be replaced by CRLF` 