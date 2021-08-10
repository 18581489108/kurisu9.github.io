---
title: 如何基于OneDrive搭建音乐云盘Ⅱ
tags:
  - 折腾
  - OneDrive
  - Azure 应用注册
categories:
  - 如何基于OneDrive搭建音乐云盘
date: 2021-08-10 18:32:36
---


# 前言
前面提到了基于Microsoft Graph API来提取OneDrive分享文件的直链，而Microsoft Graph API需要一些准备工作。

# 应用注册
1. 使用Microsoft 个人账户登录到[Azure 门户](https://portal.azure.com/)。

2. 如果首次使用Azure 门户，请先创建一个Azure AD 租户。

3. 选择所需的租户，在左侧导航窗格中，选择 Azure Active Directory 服务，然后选择**应用注册** > **新注册**。

4. 在注册应用程序页面后，输入应用程序的注册信息：
    * 名称：根据自己喜好进行命名即可，这里暂定为**onedrive-music-cloud**。
    * 支持的帐户类型：选择**仅 Microsoft 个人帐户**。
    * 重定向 URI: 选择应用类型为**Web**，然后输入重定向URI，暂定为**http://localhost:8180/msal4j/secure/aad**

5. 完成后，选择**注册**。

注:
* 这里建议使用个人账户。工作/学校账户的使用逻辑不太一致，并且在访问OneDrive API时需要提供SPO许可证。

# 生成客户端密码
web应用程序中，可以选择证书或者客户端密码来作为请求令牌时的证明。为了简单起见，这里使用客户端密码。

1. 在应用页面，选择左侧导航窗格中的**证书和密码**。

2. 选择**新客户端密码**，输入说明以后，选择**添加**

3. 请保存好该密码，这个值只会出现一次，后续都将已加密的方式出现。

# 配置权限
在用户使用应用时，需要用户同意OneDrive的相关api。

1. 在应用页面，选择左侧导航窗格中的**API 权限**。

2. 选择**添加权限**，然后选择**Microsoft Graph**。

3. 勾选**OpenId 权限**下的**offline_access**、**openid**、**profile**。

4. 在**选择权限**中输入**files**，并勾选**Files.Read**、**Files.Read.All**、**Files.Read.Selected**、**Files.ReadWrite**、**Files.ReadWrite.All**。

5. 完成后，选择**添加权限**。

# 结束
至此，前期的准备工作基本告一段落，下一阶段将基于Microsoft Graph API构建简单的demo，用于获取OneDrive相关文件。



# 参考
* [向 Microsoft 标识平台注册应用程序](https://docs.microsoft.com/zh-cn/graph/auth-register-app-v2)