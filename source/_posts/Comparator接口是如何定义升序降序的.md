---
title: Comparator接口是如何定义升序降序的
date: 2021-05-27 15:12:29
tags:
  - java
---

# 前言
在使用Comparator接口时，总是无法很好的理解到什么是升序降序，每次都需要写个用例跑一次才确定。(；′⌒`)

# 用例

## 升序
```java
public static void main(String[] args) {
    Integer[] arr = {1, 2, 3, 4, 5};
    Arrays.sort(arr, (a, b) -> a - b);
    System.out.println(Arrays.toString(arr));
}
```

输出: 
```bash
[1, 2, 3, 4, 5]
```

## 降序
```java
public static void main(String[] args) {
    Integer[] arr = {1, 2, 3, 4, 5};
    Arrays.sort(arr, (a, b) -> b - a);
    System.out.println(Arrays.toString(arr));
}
```

输出: 
```bash
[5, 4, 3, 2, 1]
```

# 浅谈
在java.util.Comparator#compare方法上的注释，说得很清楚:
> 在比较两个参数的顺序时，第一个参数为a， 第二个参数为b
> 1. a < b时返回负数
> 2. a == b时返回0
> 3. a > b时返回正数
> 4. 建议使用-1、0、1来代表三个返回值

在java.util.Arrays#sort(T[], java.util.Comparator<? super T>)实现中，会根据参数使用不同的排序算法，有binary sort和merge sort。这里直接看merge sort的实现，比较容易理解。
```java
// java.util.Arrays#mergeSort(java.lang.Object[], java.lang.Object[], int, int, int, java.util.Comparator)


private static void mergeSort(Object[] src,
                                  Object[] dest,
                                  int low, int high, int off,
                                  Comparator c) {
        int length = high - low;

        // Insertion sort on smallest arrays
        if (length < INSERTIONSORT_THRESHOLD) {
            for (int i=low; i<high; i++)
                for (int j=i; j>low && c.compare(dest[j-1], dest[j])>0; j--)
                    swap(dest, j, j-1);
            return;
        }

        // Recursively sort halves of dest into src
        int destLow  = low;
        int destHigh = high;
        low  += off;
        high += off;
        int mid = (low + high) >>> 1;
        mergeSort(dest, src, low, mid, -off, c);
        mergeSort(dest, src, mid, high, -off, c);

        // If list is already sorted, just copy from src to dest.  This is an
        // optimization that results in faster sorts for nearly ordered lists.
        if (c.compare(src[mid-1], src[mid]) <= 0) {
           System.arraycopy(src, low, dest, destLow, length);
           return;
        }

        // Merge sorted halves (now in src) into dest
        for(int i = destLow, p = low, q = mid; i < destHigh; i++) {
            if (q >= high || p < mid && c.compare(src[p], src[q]) <= 0)
                dest[i] = src[p++];
            else
                dest[i] = src[q++];
        }
    }
```
关键代码位置就是:
```java
if (length < INSERTIONSORT_THRESHOLD) {
    for (int i=low; i<high; i++)
        for (int j=i; j>low && c.compare(dest[j-1], dest[j])>0; j--)
            swap(dest, j, j-1);
    return;
}
```
这里根据的compare方法的返回值来进行了交换。可以看到当返回值大于0时，则交换dest[j-1] 和dest[j]，而返回值小于等于0时，则顺序保持不变。

# 总结
在Comparator中，只要compare方法的返回值大于0时，就将数组前一个数和后一个数进行交换，也就是说:
1. 如果需要升序，那么只要保证在参数a小于参数b时，返回负数即可
2. 如果需要降序，那么只要保证在参数a小于参数b时，返回正数即可
