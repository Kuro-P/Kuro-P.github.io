// 存放一席常用的工具方法
const package = require('../package.json')
const https = require('node:https')
const { compare, compareVersions } = require('compare-versions')
const process = require('process')

const prodPackage = 'https://raw.githubusercontent.com/Kuro-P/Kuro-P.github.io/develop/package.json';


// 与线上版本进行对比
function compareVersion() {
  console.log('local package version', package.version)

  https.get(prodPackage, 
  (res) => {
    console.log('statusCode:', res.statusCode);
    let _data = ''

    res.on('data', (chunk) => {
      _data += chunk
    });


    res.on('end', () => {
      try {
        const data = JSON.parse(_data)
        console.log('current version', data.version)

        versionChanged =  compareVersions(package.version, data.version)
        if (!versionChanged) {
          console.log('version not changed !!!')
          process.exit(1)
        }
        console.log('version changed !!!')
      } catch (e) {
        console.log('response error', e.message)
      }
    })
  }).on('error', (e) => {
    console.error(e);
  });
}

compareVersion()