---
title: 如何基于OneDrive搭建音乐云盘Ⅲ
tags:
  - 折腾
  - OneDrive
  - microsoft-graph
categories:
  - 如何基于OneDrive搭建音乐云盘
---

# 前言
前面完成了向 Microsoft 标识平台注册应用程序，那么这一节就开始基于Microsoft Graph API构建简单demo。

# 准备
创建基于spring boot的web工程，其核心依赖为
```xml
<dependency>
    <groupId>com.microsoft.graph</groupId>
    <artifactId>microsoft-graph</artifactId>
    <version>4.0.0</version>
</dependency>

<dependency>
    <groupId>com.azure</groupId>
    <artifactId>azure-identity</artifactId>
    <version>1.3.3</version>
</dependency>
```

demo源码地址: [kurisu9az/onedrive-demo](https://github.com/kurisu9az/onedrive-demo)

# 