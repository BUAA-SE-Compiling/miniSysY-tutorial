

``` shell
npm install -g gitbook-cli #这里只下载了gitbook-cli
gitbook -V #如果这里在下载gitbook的时候报了一个TypeError的错误，可以使用 sudo n 10.21.0 切到较早版本的nodejs后重新下载
gitbook install #下载添加的插件
gitbook build #
```

build以后页边栏会变成点击无法跳转,[fix](https://cloud.tencent.com/developer/article/1479117) 

`/_book/gitbook/`目录下找到theme.js 搜索`if(m)for(n.handler&& `把 `if(m)`改为`if(false)`

