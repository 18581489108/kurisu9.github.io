---
title: 使用docker镜像部署spring cloud config repo
date: 2021-05-21 16:03:46
tags: 
  - 折腾
---

# 前言
之前折腾了一些spring cloud config repo来存放一些项目的配置文件，由于不需要自定义开发，于是就使用了别人制作好的docker镜像。

# 使用

## 准备配置文件
准备好spring cloud confg repo的配置文件
```yaml
# application.yml
server:
  port: 8888

spring:
  cloud:
    config:
      server:
        git:
          uri: git@github.com:{username}/{your-config-repo}.git
          timeout: 10
          # 添加你的配置文件路径
          search-paths:
            - configs
          clone-on-start: true
          # 支持直接使用用户名和密码登录github仓库，但是不推荐
          # github已经警告过将会不再支持该方式
          # 因此这里建议使用ssh来登录到仓库
          #username: 
          #password: 
```

## 配置ssh key
如何生成ssh key以及上传到github，详情见
(Connecting to GitHub with SSH)[https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh]

## 使用镜像启动
镜像: ```hyness/spring-cloud-config-server:2.2.6.RELEASE-jdk8```

启动命令
```bash
# 1. 需要将application.yml映射到镜像
# 2. 如果是使用ssh来连接到github，那么需要将当前用户的ssh目录映射到镜像
# 3. 如果应用也是跑到docker中，那么建议创建docker net来进行config server与应用的通信
#    否则需要将config server暴露端口给外部应用访问

docker run --name spring-config-server \
 -v ./application.yml:/config/application.yml \
 -v /home/{usr}/.ssh:/root/.ssh \
 -d hyness/spring-cloud-config-server:2.2.6.RELEASE-jdk8
```
