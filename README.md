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

### 2022.1.7 (discarded)
* <del>hexo-douban only can work in Node 12.18.4 or older version.</del>
  * <del>referer: https://github.com/mythsman/hexo-douban/issues/77</del>
* <del>hexo deploy work env as same as hexo-douban.</del>

### 2023.7.14
__Try to Upgrade `hexo`, `theme-next` and `hexo-douban` 's version__
* `theme-next` update failed ❌
  * I perfer the old version appearance, so I keep version stay at v`5.1.4`.
  * See more: [Documentation of upgrade](https://theme-next.js.org/docs/getting-started/upgrade.html)
* `hexo` update failed ❌
  * if `theme-next` version not update, then you should keep hexo version at v`3.9.0`, or you will get `Cannot GET /%20/` error on page. See https://github.com/hexojs/hexo/issues/4375.
  * if `server` command output page with swig template, try `npm install hexo-renderer-swig` or upgrade `theme-next` version. See https://stackoverflow.com/questions/63405693/hexo-cannot-display-next-theme.
  * if `WARN No layout: index.html` error in terminal output, go to check dir name that under the `/themes`, it should be the same as `_config.yml` theme field.
* local `hexo-cli` update success ✅
* `hexo-douban` update success ✅

 
### TODO
* Gt commit warning on Windows:  `LF will be replaced by CRLF` 