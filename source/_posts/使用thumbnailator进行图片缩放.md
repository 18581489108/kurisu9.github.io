---
title: 使用thumbnailator进行图片缩放
date: 2021-06-08 17:40:02
tags:
  - java
  - thumbnailator
---

# 前言
在之前基于[mirai](https://github.com/mamoe/mirai)实现qq机器人时，有个根据关键字来回复图片的需求。开始的时候是直接将原图发送出去，但是由于上传网速和原图的大小的限制，导致图片发送过于缓慢。不过想了想，对图片的精度要求并不高，那么可以选择压缩图片，尝试过几个开源库之后，选择了[thumbnailator](https://github.com/coobird/thumbnailator)来进行图片的压缩。

# 使用
导入依赖: 
```xml
<!-- https://mvnrepository.com/artifact/net.coobird/thumbnailator -->
<dependency>
    <groupId>net.coobird</groupId>
    <artifactId>thumbnailator</artifactId>
    <version>0.4.14</version>
</dependency>
```
目前最新版本号位```0.4.14```，自行选择相应的版本号[Thumbnailator maven仓库](https://mvnrepository.com/artifact/net.coobird/thumbnailator)。

## 从图像文件来创建缩略图
```java
Thumbnails.of(new File("original.jpg"))   // 图片来源
        .size(160, 160)
        .toFile(new File("thumbnail.jpg")); // 输出图片路径
```

同时```Thumbnails.of()```也支持传入字符串路径的来读取图片。
```java
Thumbnails.of("original.jpg")
        .size(160, 160)
        .toFile("thumbnail.jpg");
```

## 创建旋转和水印的缩略图
```java
Thumbnails.of(new File("original.jpg"))       // 图片来源
        .size(160, 160)
        .rotate(90)            // 顺时针旋转90°
        .watermark(Positions.BOTTOM_RIGHT, ImageIO.read(new File("watermark.png")), 0.5f)   // 添加水印
        .outputQuality(0.8)     // 输出的质量，可以用于压缩图片
        .toFile(new File("image-with-watermark.jpg")); // 输出图片路径
```

## 将创建的缩略图写入到```OutputStream```
```java
OutputStream os = ...;
		
Thumbnails.of("large-picture.jpg")
        .size(200, 200)
        .outputFormat("png")   // 输出格式
        .toOutputStream(os);   // 写入的输出流
```

## 创建固定大小的缩略图
```java
BufferedImage originalImage = ImageIO.read(new File("original.png"));

BufferedImage thumbnail = Thumbnails.of(originalImage)
        .size(200, 200)
        .asBufferedImage();
```

## 设置图片的输出规模
```java
BufferedImage originalImage = ImageIO.read(new File("original.png"));

BufferedImage thumbnail = Thumbnails.of(originalImage)
        .scale(0.25)   // 缩放为25%
        .asBufferedImage();
```

## 旋转图片
```java
BufferedImage originalImage = ImageIO.read(new File("original.jpg"));

BufferedImage thumbnail = Thumbnails.of(originalImage)
        .size(200, 200)
        .rotate(90)    // 顺时针旋转90°
        .asBufferedImage();
```

## 为图片增加水印
```java
BufferedImage originalImage = ImageIO.read(new File("original.jpg"));    // 原始图片
BufferedImage watermarkImage = ImageIO.read(new File("watermark.png"));  // 用做水印的图片

BufferedImage thumbnail = Thumbnails.of(originalImage)
        .size(200, 200)
        .watermark(Positions.BOTTOM_RIGHT, watermarkImage, 0.5f)  // 设置水印
        .asBufferedImage();

```
* 根据```watermark()```的第一个参数```Positions```这个枚举来设置水印的位置
* 根据```watermark()```的最后一个参数来调整水印的透明度，```0.0f```是完全透明的，```1.0f```是完全不透明

## 将多张缩略图写入到指定目录
```java
File destinationDir = new File("path/to/output");

Thumbnails.of("apple.jpg", "banana.jpg", "cherry.jpg")
        .size(200, 200)
        .toFiles(destinationDir, Rename.PREFIX_DOT_THUMBNAIL);
```
在写入到指定目录时，可以设置是否在文件名上增加前缀。设置了```Rename.PREFIX_DOT_THUMBNAIL```以后，输出的文件如下:
* path/to/output/thumbnail.apple.jpg
* path/to/output/thumbnail.banana.jpg
* path/to/output/thumbnail.cherry.jpg

如果设置为```Rename.NO_CHANGE```，那么不会修改输出时的文件名。

## 使用byte数组来进行图片的压缩
由于在获取图片是来自于byte数组，同时需要输出为byte数组。
```java
public byte[] compressImage(byte[] bytes) throws IOException {
    try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream(1024);
            ByteArrayInputStream inputStream = new ByteArrayInputStream(bytes)) {
        Thumbnails.of(inputStream)
                .scale(1.0f)
                .outputQuality(0.3f)
                .outputFormat("jpg")
                .toOutputStream(outputStream);

        return outputStream.toByteArray();
    }
}
```

# 总结
虽然只是在写玩具的时候接触到需要进行图片压缩的场景，但是也可以借此拓宽自己的视野。

# 参考
* [coobird / thumbnailator](https://github.com/coobird/thumbnailator)
* [thumbnailator examples](https://github.com/coobird/thumbnailator/wiki/Examples#examples)
