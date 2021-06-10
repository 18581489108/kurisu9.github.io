---
title: log4j2输出方法堆栈
date: 2021-06-10 10:36:05
tags:
  -- java
  -- log4j2
---

# 前言
最近在排查日志时，发现有些方法总是被传入了非法参数，但是由于该方法被调用的地方很多，而且运行的上下文不明确。为了抓住错误参数的来源，那么只能在日志输出时，增加方法堆栈的输出。

# 使用org.slf4j.Logger#error(java.lang.String, java.lang.Throwable)
在输出error日志时，在第二个参数传入```Throwable```时，可以输出异常抛出时的堆栈信息。

测试代码:
```java
package com.example.demo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * @author kurisu9
 * @date 2021/6/10 10:47
 **/
public class TestLogTrace {
    private static final Logger LOGGER = LoggerFactory.getLogger(TestLogTrace.class);

    public static void main(String[] args) {
        test1();
    }

    private static void test1() {
        test2();
    }

    private static void test2() {
        LOGGER.error("异常堆栈: ", new NullPointerException());
    }
}
```

输出的日志信息:
```bash
10:50:07.376 [main] ERROR com.example.demo.TestLogTrace - 异常堆栈: 
java.lang.NullPointerException: null
	at com.example.demo.TestLogTrace.test2(TestLogTrace.java:23)
	at com.example.demo.TestLogTrace.test1(TestLogTrace.java:19)
	at com.example.demo.TestLogTrace.main(TestLogTrace.java:15)
```

不仅仅是error级别，其他级别也提供了第二个参数为```Throwable```的接口:
* ```org.slf4j.Logger#debug(java.lang.String, java.lang.Throwable)```
* ```org.slf4j.Logger#info(java.lang.String, java.lang.Throwable)```
* ```org.slf4j.Logger#warn(java.lang.String, java.lang.Throwable)```

# 使用java.lang.Throwable#getStackTrace获取堆栈信息
前面提到可以通过在输出日志时传入异常对象来输出堆栈信息，如果不想要抛出一个异常，那么可以选择这种折中的方式。
```java
package com.example.demo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Arrays;

/**
 * @author kurisu9
 * @date 2021/6/10 10:47
 **/
public class TestLogTrace {
    private static final Logger LOGGER = LoggerFactory.getLogger(TestLogTrace.class);

    public static void main(String[] args) {
        test1();
    }

    private static void test1() {
        test2();
    }

    private static void test2() {
        StackTraceElement[] stackTraceElements = new Throwable().getStackTrace();

        LOGGER.error("异常堆栈: {}", Arrays.toString(stackTraceElements));
    }
}
```
输出的日志信息:
```bash
10:59:28.581 [main] ERROR com.example.demo.TestLogTrace - 异常堆栈: [com.example.demo.TestLogTrace.test2(TestLogTrace.java:25), com.example.demo.TestLogTrace.test1(TestLogTrace.java:21), com.example.demo.TestLogTrace.main(TestLogTrace.java:17)]
```

这种方式感觉上还是比较邪教，不过这是比较方便的就能拿到调用的堆栈信息，用于简单排错也是够用了。

# 总结
日常使用日志输出时，只是输出简单日志，有时候没法溯源，所以偶尔需要在日志输出的同时输出相关的堆栈信息，以便更好的定位问题。
