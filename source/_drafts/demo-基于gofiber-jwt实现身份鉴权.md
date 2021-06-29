---
title: 'demo: 基于gofiber + jwt实现身份鉴权'
tags:
  - demo
  - golang
  - gofiber
  - jwt
---
# 前言
在分布式项目中，传统的session进行用户的身份鉴权已经力不从心，使用token代替seesion也逐渐成为了一种趋势。最近在拿gofiber写demo中时，为了后续再扩展为分布式应用，于是结合jwt实现了一套简单的鉴权系统。

在实现鉴权系统中，需要解决的问题:
* 密码泄漏
* 生成jwt的secret泄漏
* 修改密码后，使旧的jwt失效

# 设计思路
## 注册

## 登录

## 鉴权

# 实现方案
## 项目结构

## 注册

## 登录

## 鉴权

# 结束


# 参考
* [Web App Token 鉴权方案的设计与思考](https://zhuanlan.zhihu.com/p/28295641)
* [go-fiber](https://github.com/gofiber/fiber)
* [jwt-go](https://pkg.go.dev/github.com/form3tech-oss/jwt-go@v3.2.3+incompatible?utm_source=gopls#section-readme)
* [auth-jwt](https://github.com/gofiber/recipes/tree/master/auth-jwt)
* [JWT validation with JWKS golang](https://stackoverflow.com/questions/61850992/jwt-validation-with-jwks-golang)