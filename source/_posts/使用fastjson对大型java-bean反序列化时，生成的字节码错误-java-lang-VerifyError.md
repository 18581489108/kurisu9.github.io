---
title: '使用fastjson对大型java bean反序列化时，生成的字节码错误: java.lang.VerifyError'
date: 2021-06-03 10:12:08
tags:
  - java
  - fastjson
---

# 前言
由于业务需求，项目中用于存储数据的bean，定义了很多字段。前面都相安无事，直到前几天新增了某个需求之后，在bean里添加了一个字段后，在从json反序列化时，抛出了```java.lang.VerifyError```。

```bash
Exception in thread "main" java.lang.VerifyError: (class: com/alibaba/fastjson/parser/deserializer/FastjsonASMDeserializer_1_LargeJavaBean, method: deserialze signature: (Lcom/alibaba/fastjson/parser/DefaultJSONParser;Ljava/lang/reflect/Type;Ljava/lang/Object;I)Ljava/lang/Object;) Illegal target of jump or branch
	at java.base/java.lang.Class.getDeclaredConstructors0(Native Method)
	at java.base/java.lang.Class.privateGetDeclaredConstructors(Class.java:3137)
	at java.base/java.lang.Class.getConstructor0(Class.java:3342)
	at java.base/java.lang.Class.getConstructor(Class.java:2151)
	at com.alibaba.fastjson.parser.deserializer.ASMDeserializerFactory.createJavaBeanDeserializer(ASMDeserializerFactory.java:87)
	at com.alibaba.fastjson.parser.ParserConfig.createJavaBeanDeserializer(ParserConfig.java:1082)
	at com.alibaba.fastjson.parser.ParserConfig.getDeserializer(ParserConfig.java:888)
	at com.alibaba.fastjson.parser.ParserConfig.getDeserializer(ParserConfig.java:593)
	at com.alibaba.fastjson.parser.DefaultJSONParser.parseObject(DefaultJSONParser.java:699)
	at com.alibaba.fastjson.JSON.parseObject(JSON.java:394)
	at com.alibaba.fastjson.JSON.parseObject(JSON.java:298)
	at com.alibaba.fastjson.JSON.parseObject(JSON.java:588)
	at com.example.Main.main(Main.java:8)
```

具体的复现demo可以见[issue 3796](https://github.com/alibaba/fastjson/issues/3796)

在遇到这个bug时，在fastjson的issues中搜索发现，在[issue 2779](https://github.com/alibaba/fastjson/issues/2779)中已经遇到该bug，而在早在19年5月就已经修复了该问题。

通过升级fastjosn到目前最新版本（1.2.76），仍然稳定复现该bug，那只能自己先排查一下问题。

# 排查问题

## 排查业务代码
1. 在对业务代码进行检查后，确定出现问题的bean在实现上是没有问题的。
2. 在注释掉新添加的字段后，进行反序列化时，正常运行

于是推测是fastjon的实现问题。

## 排查错误堆栈信息
根据错误堆栈，定位到```ASMDeserializerFactory```的第87行代码。

```java
// com.alibaba.fastjson.parser.deserializer.ASMDeserializerFactory#createJavaBeanDeserializer

byte[] code = cw.toByteArray();

Class<?> deserClass = classLoader.defineClassPublic(classNameFull, code, 0, code.length);
// jvm这里会去动态加载class，而加载class过程中，需要验证class
Constructor<?> constructor = deserClass.getConstructor(ParserConfig.class, JavaBeanInfo.class);
```

jvm在加载class时，需要进行:
1. 加载
2. 链接
    1. 验证
    2. 准备
    3. 解析
3. 初始化
4. 使用
5. 卸载

根据```java.lang.VerifyError```可以知道，在验证阶段出现了错误，那么先把生成的字节码保存到本地。

### 将字节码保存到本地
环境:
* jdk 11.0.9
* fastjson 1.2.76
* idea 2021

操作过程: 
1. 将断点设置在87行

2. 在debug中，使用```Evaluate Expression```执行
    ```java
    Files.write(Paths.get("./LargeJavaBean.class"), code)
    ```

通过上面的操作，就拿到生成的class文件。

### 检查生成的class文件
直接使用idea打开```LargeJavaBean.class```，可以发现```deserialze()```的方法体未能反编译。
```java
// com.alibaba.fastjson.parser.deserializer.FastjsonASMDeserializer_1_LargeJavaBean#deserialze

public Object deserialze(DefaultJSONParser param1, Type param2, Object param3, int param4) {
    // $FF: Couldn't be decompiled
}
```

回想起[issue 2779](https://github.com/alibaba/fastjson/issues/2779)修复的[pr 2858](https://github.com/alibaba/fastjson/pull/2858)中提到了可能是由于生成的字节码地址可能为负数。
> blindpirate:
> 在此之前，如果Java bean类过大，ASMDeserializerFactory生成的字节码中
的跳转地址如果超过了signed short能表示的范围，生成的字节码中的地址
可能是负数，即
> ```ifeq -32455```


那么接下来尝试将class文件编译为jvm指令，
```bash
javap -v LargeJavaBean.class > LargeJavaBean.txt
```

打开```LargeJavaBean.txt```，使用正则进行全文搜索
```regx
: .{1,20} *-
```
发现有一处指令符合该条件
```java
120: if_icmpeq     -32586
```
可以知道```if_icmpeq```跳转的目的地址溢出，成了负数。因此在jvm在验证该class时抛出了```java.lang.VerifyError```

## 尝试修复bug
根据[pr 2858](https://github.com/alibaba/fastjson/pull/2858)提到的方向，找到了在b站上一个解决该问题的视频[现场直播给阿里巴巴Fastjson修bug](https://www.bilibili.com/video/BV1JJ41197UK?share_source=copy_web)。

整体思路就是通过将对应的跳转语句转换为相反的跳转语句 + goto_w来实现。
例如:```ifeq```和```ifne + goto_w```在逻辑上是等价的。

同时```goto_w```使用4个字节来保存跳转的目的地址，因此可以避免出现溢出的问题。

### 定位写入错误指令的代码位置
根据错误指令的上下文来看，
```java
       107: invokevirtual #827                // Method com/alibaba/fastjson/parser/DefaultJSONParser.setContext:(Lcom/alibaba/fastjson/parser/ParseContext;Ljava/lang/Object;Ljava/lang/Object;)Lcom/alibaba/fastjson/parser/ParseContext;
       110: astore        10
       112: aload         5
       114: getfield      #831                // Field com/alibaba/fastjson/parser/JSONLexerBase.matchStat:I
       117: ldc_w         #832                // int 4
       120: if_icmpeq     -32586
       123: iconst_0
       124: istore        11
       126: iconst_0
       127: istore        12
```
在写入```if_icmpeq```前会先写入```ldc_w```、```getfield```以及```invokevirtual```，通过这些关键字，定位到了```ASMDeserializerFactory```的702行代码: ```mw.visitJumpInsn(IF_ICMPEQ, return_);```

```java
// com.alibaba.fastjson.parser.deserializer.ASMDeserializerFactory#_deserialzeArrayMapping
// 684行 - 705行
{
    mw.visitVarInsn(ALOAD, 1); // parser
    mw.visitMethodInsn(INVOKEVIRTUAL, DefaultJSONParser, "getContext", "()" + desc(ParseContext.class));
    mw.visitVarInsn(ASTORE, context.var("context"));

    mw.visitVarInsn(ALOAD, 1); // parser
    mw.visitVarInsn(ALOAD, context.var("context"));
    mw.visitVarInsn(ALOAD, context.var("instance"));
    mw.visitVarInsn(ALOAD, 3); // fieldName
    mw.visitMethodInsn(INVOKEVIRTUAL, DefaultJSONParser, "setContext", //
                        "(" + desc(ParseContext.class) + "Ljava/lang/Object;Ljava/lang/Object;)"
                                                                        + desc(ParseContext.class));
    mw.visitVarInsn(ASTORE, context.var("childContext"));
}

mw.visitVarInsn(ALOAD, context.var("lexer"));
mw.visitFieldInsn(GETFIELD, JSONLexerBase, "matchStat", "I");
mw.visitLdcInsn(com.alibaba.fastjson.parser.JSONLexerBase.END);
// 这里的跳转地址溢出了
mw.visitJumpInsn(IF_ICMPEQ, return_);

mw.visitInsn(ICONST_0); // UNKOWN
mw.visitIntInsn(ISTORE, context.var("matchStat"));
```

### 试着修复bug
```diff
- mw.visitJumpInsn(IF_ICMPEQ, return_);
+ Label continue_3 = new Label();
+ mw.visitJumpInsn(IF_ICMPNE, continue_3);
+ mw.visitJumpInsn(GOTO_W, return_);
+ mw.visitLabel(continue_3);
```

思路就是使用```if_icmpne + goto_w```替换掉```if_icmpeq```来规避跳转的目的地址溢出的问题。

# 新的问题
在跟同事讨论构造稳定复现该bug的用例时，发现不仅仅是之前提到的跳转有问题，而是在多处跳转都有可能会溢出。新的bug见[issue 3794](https://github.com/alibaba/fastjson/issues/3794)，该issue提供了一个新的测试用例，发现只要字段是96个时就会出现```java.lang.VerifyError```，同时生成的字节码目的地址为负数
```bash
if_icmpne -17541
```
由于出现该错误的地方很多，也没时间再去一步步定位问题，目前在考虑项目中使用gson来代替fastjon。

# 总结
1. fastjosn的这个bug的源头还是来自于底层使用的asm库版本过低导致的，新版本的asm库修复了很多由于跳转地址溢出的问题。希望fastjson能够把asm库的新版本代码合进去。
2. 项目中使用的bean不会太大时，使用fastjson是通常没有问题的，如果出现了该问题，又仍然得继续用fastjson时，可以考虑使用```fieldBase = true```来避免使用asm来生成字节码。具体的使用方式见[FieldBased_cn](https://github.com/alibaba/fastjson/wiki/FieldBased_cn)。


