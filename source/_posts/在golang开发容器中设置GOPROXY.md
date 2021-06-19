---
title: 在golang开发容器中设置GOPROXY
tags:
  - vscode
  - golang
  - docker
date: 2021-06-19 08:10:21
---

# 前言
通过vscode+wsl2+docker进行golang的开发，避免了本机配置环境的繁琐。

配置golang开发容器，可以参考:
* [Developing inside a Container](https://code.visualstudio.com/docs/remote/containers)
* [Remote development in Containers](https://code.visualstudio.com/docs/remote/containers-tutorial)

# 问题
在使用```go get golang.org/x```拉去包时，会由于```https://golang.org/```被墙掉而拉取失败。

在本地开发时，通常会设置```GOPROXY```来进行代理。所以即使在容器中开发，也通常建议配置```GOPROXY```。

# 解决
## 无效方式
进入容器，如果像本地开发那样，直接设置```GOPROXY```，
```bash
export GOPROXY=https://goproxy.io,direct
```

查看环境变量
```bash
go env
```
可以看到已经设置上了
```bash
GOPROXY="https://goproxy.io,direct"
```

但是呢，这时候再使用gopls进行包的安装，仍然会走```https://golang.org/```，所以只是在容器里进行```GOPROXY```的设置是没有效果的。

## 有效方式
在```.devcontainer/devcontainer.json```中配置环境变量
```json
{
    "remoteEnv": {
		  "GOPROXY": "https://goproxy.io,direct"
	  }
}
```
在配置文件中增加```remoteEnv```项，并设置```GOPROXY```。

配置结束以后，重新构建容器即可。

# 参考
* [devcontainer.json reference](https://code.visualstudio.com/docs/remote/devcontainerjson-reference)