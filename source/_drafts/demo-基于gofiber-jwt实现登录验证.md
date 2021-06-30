---
title: 'demo: 基于gofiber + jwt实现登录验证'
tags:
  - demo
  - golang
  - gofiber
  - jwt
---
# 前言
在分布式项目中，传统的session进行用户的登录验证已经力不从心，使用token代替seesion也逐渐成为了一种趋势。最近在拿gofiber写demo中时，为了后续再扩展为分布式应用，于是结合jwt实现了一套简单的登录验证系统。

在实现鉴权系统中，需要解决的问题:
* 密码泄漏
* 生成jwt的secret泄漏
* 修改密码后，使旧的jwt失效

# 设计思路
## 注册
![注册流程](https://gitee.com/makise.kurisu/filestorage/raw/master/images/blog/demo-%E5%9F%BA%E4%BA%8Egofiber-jwt%E5%AE%9E%E7%8E%B0%E7%99%BB%E5%BD%95%E9%AA%8C%E8%AF%81/%E6%B3%A8%E5%86%8C%E6%B5%81%E7%A8%8B.png)

1. 通过username + 随机字符串生成唯一的salt。
2. 在保存密码时，不能保存明文密码，通常需要保存密码的摘要。通过前一步生成的salt，来提高密码的安全性。
3. 最后将username、salt、hash过的密码写入数据库

## 登录
![登录流程](https://gitee.com/makise.kurisu/filestorage/raw/master/images/blog/demo-%E5%9F%BA%E4%BA%8Egofiber-jwt%E5%AE%9E%E7%8E%B0%E7%99%BB%E5%BD%95%E9%AA%8C%E8%AF%81/%E7%99%BB%E5%BD%95%E6%B5%81%E7%A8%8B.png)

1. 通过username读取出数据库中的用户信息
2. 通过存储的salt和用户输入的密码，进行hash
3. 比较hash过的密码与数据库中存储的密码是否一致

## 生成token
![生成token流程](https://gitee.com/makise.kurisu/filestorage/raw/master/images/blog/demo-%E5%9F%BA%E4%BA%8Egofiber-jwt%E5%AE%9E%E7%8E%B0%E7%99%BB%E5%BD%95%E9%AA%8C%E8%AF%81/token%E7%94%9F%E6%88%90%E6%B5%81%E7%A8%8B.png)

1. 通过存储的salt、登录时间戳生成jwt的salt，并存入redis
2. 将jwt salt与私有密钥进行hash，生成jwt secret
3. 将一些用户信息（例如用户id、username等非敏感信息）写入claims
4. 通过claims、jwt secret生成token

## 验证token
![token验证流程](https://gitee.com/makise.kurisu/filestorage/raw/master/images/blog/demo-%E5%9F%BA%E4%BA%8Egofiber-jwt%E5%AE%9E%E7%8E%B0%E7%99%BB%E5%BD%95%E9%AA%8C%E8%AF%81/token%E9%AA%8C%E8%AF%81%E6%B5%81%E7%A8%8B.png)

1. 从http header中的```Authorization```字段中读取到token
2. 从token解析出用户相关信息，包括username
3. 根据username从redis中获取到jwt salt
4. 再将jwt salt与私有密钥进行hash，生成jwt secret
5. 验证token是否合法

# 实现方案
## 项目结构

## 注册

## 登录

## 鉴权

# 结束
回到开始提出的三个问题，

Q: 如何解决密码泄漏？

A: 


# 参考
* [Web App Token 鉴权方案的设计与思考](https://zhuanlan.zhihu.com/p/28295641)
* [go-fiber](https://github.com/gofiber/fiber)
* [jwt-go](https://pkg.go.dev/github.com/form3tech-oss/jwt-go@v3.2.3+incompatible?utm_source=gopls#section-readme)
* [auth-jwt](https://github.com/gofiber/recipes/tree/master/auth-jwt)
* [JWT validation with JWKS golang](https://stackoverflow.com/questions/61850992/jwt-validation-with-jwks-golang)