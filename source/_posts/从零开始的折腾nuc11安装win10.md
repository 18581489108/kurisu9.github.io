---
title: 从零开始的折腾nuc11安装win10
date: 2021-06-15 15:30:13
tags:
  - 折腾
  - nuc11
  - win10
---
# 前言
又是一年618，在异地出差已经3个月了，苦于sp4的性能过于弱鸡，就想着装一台机器。本来是想装一台ITX，看了看相关推介，itx的大小还是不够便携，直到在知乎看到了[花 ¥3500 组装的性能强悍「迷你台式机」，用了一周说说我的体验](https://zhuanlan.zhihu.com/p/67252868)。NUC系列主机就进入了我考虑范围，看了下相关评测与真机视频，小小的体积以及够用的性能（指11代u），再搭配上之前出差为了玩ns入的便携式屏幕，差不多刚刚可以组一台便携式设备。于是乎，趁着618，直接jd下单购买了[猎豹峡谷NUC11PAHi7](https://item.jd.com/10026278896566.html)，准备在这个假期好好玩玩（虽然确实被折腾得够呛）。

# 硬件准备
由于NUC本体不包含硬盘和内存，所以需要额外购入这些硬件。

准备清单: 
* 固态硬盘M.2接口(NVMe) 
* 内存 16GB(8G×2)套装 DDR4 3200 （nuc11最高支持3200的内存条，这里使用2条内存组成双通道）
* 便携式屏幕（最好支持雷电3，这样可以省去供电的线）
* 无线蓝牙键盘（不过建议最好要有有线键盘，方便第一次装系统时，操作bios）
* 笔记本电源线 三孔梅花尾电脑适配器充电（因为nuc的包装清单里，有电源适配器，但是没有电源线，在买的时候最好问清楚，如果没有就买根电源线）
* 网线（虽然NUC自带无线模块，但是为了追求网络稳定性，还是选择了买根网线，这点可有可无）
* win10镜像

## 注意
在制作U盘镜像的时候，最好选择微软官方的[MediaCreationTool21H1](https://www.microsoft.com/zh-cn/software-download/windows10)。

之前用了某鲨的系统盘制作工具，在PE启动引导之后，无法识别固态硬盘，导致系统安装失败。尝试了几个版本的系统工具都无法正常安装，最后还是使用微软的官方工具，直接一气呵成。

# 开始安装
安装方式可参考[Intel NUC11开箱装机](https://www.bilibili.com/video/BV1Cv411a7Ey?share_source=copy_web)。

硬盘跟内存都装好以后，直接插上U盘，一步步引导即可。

## 注意
由于NUC11的集成网卡硬件比较新，win10没法自动适配合适的驱动。导致安装完系统后是没法识别有线网卡。

打开硬件管理器，应该是有```Ethernet controller```上有个感叹号，但是没法安装驱动。

可以在intel的官方驱动[Downloads for Intel® Ethernet Controller I225-V](https://downloadcenter.intel.com/product/184676/intel-ethernet-controller-i225-v)找到win10的适配版本驱动:
* [Intel® Network Adapter Driver for Windows® 10](https://downloadcenter.intel.com/download/25016/Ethernet-Intel-Network-Adapter-Driver-for-Windows-10)

下载```Wired_driver_26.3_x64.zip```后，本地直接安装，安装结束后，就可以正常使用有线网络了。

# 使用体验
装好系统以后，刷了刷B站，看视频、直播等流畅不卡。玩LOL开高配，能稳定55-60帧，但是会由于跳帧影响游戏体验。

不过折腾NUC最终的目的还是为了写代码，后续准备安装WSL2 + Docker来进行开发环境的配置。

# 结论
在mini主机这块，NUC系列是玩明白了，虽然想吐槽的是都1202年了，怎么还有电源适配器比本体还大的情况。

如果你需要的便携式的二奶机，那NUC是一个非常好的选择，十分值得尝试的。

# 参考
* [花 ¥3500 组装的性能强悍「迷你台式机」，用了一周说说我的体验](https://zhuanlan.zhihu.com/p/67252868)
* [Intel NUC11开箱装机](https://www.bilibili.com/video/BV1Cv411a7Ey?share_source=copy_web)
* [解决windows10第十一代酷睿NUC插网线无法识别有线网](https://blog.csdn.net/zhou7jing/article/details/117283577)