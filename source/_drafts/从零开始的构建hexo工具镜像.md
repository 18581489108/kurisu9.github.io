---
title: 从零开始的构建hexo工具镜像
tags:
  - hexo
  - docker
  - wsl2
---
# 前言
之前折腾了一下NUC玩游戏，不过最后还是得爬去写代码。

在使用hexo写东西的时候，需要本地安装node环境，但是我并没有全局安装node的需求，因此决定构建一个hexo的镜像用于写东西以及本地预览。

# 搭建环境
* [适用于 Linux 的 Windows 子系统安装指南 (Windows 10)](https://docs.microsoft.com/zh-cn/windows/wsl/install-win10)
* [WSL 2 上的 Docker 远程容器入门](https://docs.microsoft.com/zh-cn/windows/wsl/tutorials/wsl-containers)

按照微软提供的教程，就可以安装配置好基于wsl2的docker环境。

# 构建hexo镜像
这里直接使用的vscode连接到wsl2中进行开发.

## 编写Dockerfile
```bash
FROM node:current-alpine3.13
WORKDIR /app
EXPOSE 4000

# 使用taobao的镜像加速npm
RUN npm --registry=https://registry.npm.taobao.org install hexo-cli -g

# Entry point
COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
CMD ["hexo", "server"]
```

ENTRYPOINT使用了```entrypoint.sh```，来提供一些额外逻辑，比如当挂载的是空目录时，执行```hexo init```，最后会默认执行```hexo server```。
```bash
#!/bin/bash

if [ `ls -a | wc -l` -eq 2 ]; then
    hexo init
fi

npm --registry=https://registry.npm.taobao.org install

$@
```
可以根据需求去编写```entrypoint.sh```，来实现在启动镜像时的一些功能。

## 构建镜像
在Dockerfile同级目录下执行:
```bash
docker build -t kurisu9/hexo-util .
```
* 将```kurisu9/hexo-util```替换为自己的镜像名

查看构建好的镜像:
```bash
docker images
```

## 启动容器
```bash
docker run -d --name <container name> \
 -p 4000:4000
 -v <blog path>:/app \
 kurisu9/hexo-util
```
* ```<container name>```替换为自己设定的容器名
* ```<blog path>```替换为自己的博客路径
* ```kurisu9/hexo-util```替换为自己的镜像名

## 测试
// TODO 补上从0开始的配置hexo

## 配置git插件
如果需要直接推送到github，那么需要安装git插件。

进入容器中:
```bash
docker exec -it <container name> /bin/bash
```

通过npm安装```hexo-deployer-git```插件

```bash
npm --registry=https://registry.npm.taobao.org install hexo-deployer-git --save
```

还有其他需要的插件，通过同样的方式进行安装即可。

## 推送镜像
可以选择把镜像推送到docker hub。
```bash
docker push kurisu9/hexo-util
```
* 需要登录docker hub账号

# 结束
docker作为本地开发仍然是一款最佳的容器工具，基于docekr镜像，可以极大节省配置开发环境的时间。
