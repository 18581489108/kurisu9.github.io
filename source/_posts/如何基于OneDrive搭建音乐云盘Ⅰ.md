---
title: 如何基于OneDrive搭建音乐云盘Ⅰ
tags:
  - 折腾
  - OneDrive
categories:
  - 如何基于OneDrive搭建音乐云盘
date: 2021-08-02 19:29:30
---


# 前言
写写代码、听听歌想必是十分惬意，不过由于网x云、xx音乐等平台的版权限制，导致以前经常听的歌被下架，想要完整的听完歌单里的歌已经很难了。虽然可以选择下载到本地，但是多设备使用的时候却很烦恼。

于此之前，尝试使用了Listen1来作为音乐播放器，作为一款开源播放器，在日常使用中体验已然不错。基于Listen1的实现，我想到能否利用Listen1来播放自定义来源的歌曲。经过对Listen1进行了小小的改造，支持了自定义来源歌曲的播放，那现在就需要一个搭载歌曲文件的服务器。

于是，我将目光着眼于了OneDrive。OneDrive支持将文件进行分享，让所有人都可以访问，这个特性刚好适用于作为音乐服务器。不过Listen1中只能直接播放直链，而OneDrive分享链接打开是一个网页，因此需要提取出文件的下载链接以供Listen1使用。

# 提取文件下载链接

## 使用OneDrive直链获取工具
利用[OneDrive直链获取工具v1.4](https://onedrive.gimhoy.com/)可以根据分享链接提取出下载链接，该链接用于Listen1播放歌曲的来源已然足够。但是要考虑到歌曲的数量很多，那就需要每首歌都要进行手动获取分享链接然后进行直链的获取，这对我来说是无法接受的。

同时该工具获取的链接按地址来看，应该是某个cdn上的资源，这样就有了一个问题，Listen1可以播放跨域的音频文件，但是无法获取跨域的歌词文件。

## 基于Microsoft Graph API提取直链
[Microsoft Graph](https://docs.microsoft.com/zh-cn/graph/api/resources/onedrive?view=graph-rest-1.0)提供了操作用户OneDrive的api接口。

核心思路是，通过Microsoft Graph API创建共享链接，获取到文件的shareId，最后使用```https://api.onedrive.com/v1.0/shares/{shareId}/root/content```来作为文件直链。

值得一提的是，该api是支持跨域的，那么同时解决了将歌词文件存放到OneDrive，然后由Listen1跨域获取的问题。

# 结束
1. 利用已有的工具获取直链较为简单，但是对于批量生成直链来说不够友好。
2. 而基于Microsoft Graph API，需要额外的代码才能实现提取直链的需求，但是与之带来的高度可自定义性、便携性，我认为还是值得的。

本文只提供了简单的思路以供参考，实际上要基于Microsoft Graph API进行音乐云盘的搭建，还有一些路子要走、一些坑要填，如果有时间那再写吧。

# 参考
* [Microsoft Graph](https://docs.microsoft.com/zh-cn/graph/api/resources/onedrive?view=graph-rest-1.0)
* [harrisoff/onedrive](https://github.com/harrisoff/onedrive)