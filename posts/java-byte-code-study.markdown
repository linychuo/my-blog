---
title: "java byte code study"
date_time: 2022-11-25 10:01:32
tags: java
---

关于java byte code的问题，源于昨天和同事看了一段奇怪的代码，代码逻辑其实很简单，如下：

```java
package li.yongchao;

import org.apache.commons.lang3.RandomUtils;

public class TestA {
    public static void main(String[] args) {
        int totalPages;

        do {
            totalPages = RandomUtils.nextInt(1, 15);
        } while (totalPages > 7);
    }
}
```

通过IDE工具debug时，会发现其中的totalPages变量不会出现在断点跟踪列表里，分析了半天，觉得要通过看字节码应该才能明白其中的原因。通过**javap -c -l -s TestA.class**得到下面的内容。
我本地的java版本是
```
java version "1.8.0_202"
Java(TM) SE Runtime Environment (build 1.8.0_202-b08)
Java HotSpot(TM) 64-Bit Server VM (build 25.202-b08, mixed mode)
```

反编译出的字节码：
```
Compiled from "TestA.java"
public class li.yongchao.TestA {
  public li.yongchao.TestA();
    descriptor: ()V
    Code:
       0: aload_0
       1: invokespecial #1                  // Method java/lang/Object."<init>":()V
       4: return
    LineNumberTable:
      line 5: 0
    LocalVariableTable:
      Start  Length  Slot  Name   Signature
          0       5     0  this   Lli/yongchao/TestA;

  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    Code:
       0: iconst_1
       1: bipush        15
       3: invokestatic  #2                  // Method org/apache/commons/lang3/RandomUtils.nextInt:(II)I
       6: istore_1
       7: iload_1
       8: bipush        7
      10: if_icmpgt     0
      13: return
    LineNumberTable:
      line 9: 0
      line 10: 7
      line 11: 13
    LocalVariableTable:
      Start  Length  Slot  Name   Signature
          0      14     0  args   [Ljava/lang/String;
          7       7     1 totalPages   I
}
```

这里直接调到最核心的地方，Code部分。这其中有几个指令：iconst_\<i>，bipush \<i>，istore_\<i>，iload_\<i>，if_icmpgt。我们一个一个来看。附上[java虚拟机规范(java se8)链接](https://docs.oracle.com/javase/specs/jvms/se8/html/)

## iconst_\<i>
这个指令将int类型的常量(-1, 0, 1, 2, 3, 4 or 5)压到操作数栈，手册中有说明这个指令其实和bipush \<i>是一样的，但是有个细节，这里的iconst只适用于-1到5区间的常量。上面的字节码中有 incost_1, iconst_2它们分别的意思是将1(源码中nextInt方法的第一个参数)和2(源码中while条件 totalPages做比较的数)这两个常量压到操作数栈中。

## bipush \<i>
这个指令把-128到127的int常量压到操作数栈，上面有提到它和iconst是一样的，但是当被压入的常量超出-1到5这个区间时，java编译字节码时就会使用bipush，这是因为bipush指令有两上字节，第一个字节是操作码，第二个字节是有符号的8位的整数。而为什么-1到5这个区间的数不用bipush呢，这是因为iconst指令只有一个字节，比较节省空间。上面字节码中bipush 15就是将15(源码中netxtInt方法的第二个参数)压入到操作数栈中，这里我做过几次尝试，将15改为128，编译出的字节码中就变成了sipush指令，这里sipush能够存储16位的整数。

## istore_\<i>
这个指令将int变量值存储到局部变量中，这里的i表示在栈上的局部变量数组中的索引，通过出栈后将值赋给变量。

## iload_\<i>
这个指令和上面的istroe刚好相反，从变量数组中把索引i对应的值压到操作数栈中。这里的i和上面的含义是一样的。

## if_icmpgt
这里if_icmpgt其实是if_icmp\<cond>，cond有eq, ne, lt, ge, gt, le这些选项，而gt表示value1 > value2，在字节码中并没有value1和value2，仔细看一下，在这条指令前有iload_1和bipush 7这两条指令，而if_icmpgt会从操作数栈中弹出后进行比较。


写这篇文章中参考的一些链接
1. [The Java® Virtual Machine Specification - Java SE 8 Edition](https://docs.oracle.com/javase/specs/jvms/se8/html/)
2. [How does bipush work in JVM?](https://stackoverflow.com/questions/50167675/how-does-bipush-work-in-jvm)
3. [ASMSupport](http://asmsupport.github.io/)