---
title: 关于折腾github pages那些事
date: 2021-05-17 11:40:33
tags: 
  - 折腾
---
# 前言
之前用过CSDN来写博客，但由于CSDN越来越拉，不得已就自建博客了。由于之前阿里云到期，现在在折腾腾讯云，自建博客也凉凉。于是就干脆折腾下github pages。

以下是在折腾过程中参考的文章，以及遇到的问题。

# 开始
以下大部分内容参考的是微信文章[超全面！如何用 GitHub 从零开始搭建一个博客 ？](https://mp.weixin.qq.com/s/3li0n8REcU1DviwWiEYw_A)。

这里也不做复制怪了，有兴趣的之前看别人的文章即可。

关于使用github workflow进行自动构建，可以参考官方教程[GitHub Pages](https://hexo.io/docs/github-pages)。

# 遇到的问题
## github pages的域名问题
github pages的域名通常是```{username}.github.io```，这个前提是基于这个仓库与你的自己账号名相同（不是指登录账号），否则域名将会是```{username}.github.io/{reponame}```。

同时hexo的模板代码生成的根路径是直接使用的```/```，所以在有reponame时，访问hexo生成的页面时会加载不到css、js。所以将自己的账号名更改以后，正常的可以用```{username}.github.io```进行访问。

## 使用github workflow构建失败
```bash
The page build failed for the `main` branch with the following error:

The tag `note` on line 11 in `themes/next/docs/AUTHORS.md` is not a recognized Liquid tag. For more information, see https://docs.github.com/github/working-with-github-pages/troubleshooting-jekyll-build-errors-for-github-pages-sites#unknown-tag-error.

For information on troubleshooting Jekyll see:

  https://docs.github.com/articles/troubleshooting-jekyll-builds

If you have any questions you can submit a request at https://support.github.com/contact?repo_id=367273128&page_build_id=253761474
```

在参考了issue[The tag note is not a recognized Liquid tag](https://github.com/theme-next/hexo-theme-next/issues/410)，我选择直接删除掉next主题下的doc目录，目前暂不知道是否会有版权问题，如果会造成侵权，那么我在还原回去（逃。

## 使用github workflow构建成功却有警告
```bash
The page build completed successfully, but returned the following warning for the `main` branch:

You are attempting to use a Jekyll theme, "next", which is not supported by GitHub Pages. Please visit https://pages.github.com/themes/ for a list of supported themes. If you are using the "theme" configuration variable for something other than a Jekyll theme, we recommend you rename this variable throughout your site. For more information, see https://docs.github.com/github/working-with-github-pages/adding-a-theme-to-your-github-pages-site-using-jekyll.

For information on troubleshooting Jekyll see:

  https://docs.github.com/articles/troubleshooting-jekyll-builds

If you have any questions you can submit a request at https://support.github.com/contact?repo_id=367273128&page_build_id=253763232
```

这是没有安装```hexo-deployer-git```插件引起的，在本地安装一下即可。
```bash
npm install hexo-deployer-git --save
```