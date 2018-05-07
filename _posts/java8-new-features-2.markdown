---
title: "Java8 new features 2"
date: 2018-5-6 22:42:32
---

1. [Functional Interfaces and Lambda Expressions](#first)
2. [Java Stream API for Bulk Data Operations on Collections](#second)

## <a id="first"></a>Functional Interfaces and Lambda Expressions
If you notice above interfaces code, you will notice @FunctionalInterface annotation. Functional interfaces are new concept introduced in Java 8. An interface with exactly one abstract method becomes Functional Interface. We don’t need to use @FunctionalInterface annotation to mark an interface as Functional Interface. @FunctionalInterface annotation is a facility to avoid accidental addition of abstract methods in the functional interfaces. You can think of it like @Override annotation and it’s best practice to use it. java.lang.Runnable with single abstract method run() is a great example of functional interface.

One of the major benefits of functional interface is the possibility to use lambda expressions to instantiate them. We can instantiate an interface with anonymous class but the code looks bulky.
```java
Runnable r = new Runnable(){
			@Override
			public void run() {
				System.out.println("My Runnable");
			}};
```
Since functional interfaces have only one method, lambda expressions can easily provide the method implementation. We just need to provide method arguments and business logic. For example, we can write above implementation using lambda expression as:
```java
Runnable r1 = () -> {
			System.out.println("My Runnable");
		};
```
If you have single statement in method implementation, we don’t need curly braces also. For example above Interface1 anonymous class can be instantiated using lambda as follows:
```java
Interface1 i1 = (s) -> System.out.println(s);
		
i1.method1("abc");
```
A new package java.util.function has been added with bunch of functional interfaces to provide target types for lambda expressions and method references. Lambda expressions are a huge topic, I will write a separate article on that in future.

You can read complete tutorial at [Java 8 Lambda Expressions Tutorial](https://www.journaldev.com/2763/java-8-functional-interfaces).

## <a id="second"></a>Java Stream API for Bulk Data Operations on Collections
A new java.util.stream has been added in Java 8 to perform filter/map/reduce like operations with the collection. Stream API will allow sequential as well as parallel execution. This is one of the best feature for me because I work a lot with Collections and usually with Big Data, we need to filter out them based on some conditions.

Collection interface has been extended with stream() and parallelStream() default methods to get the Stream for sequential and parallel execution. Let’s see their usage with simple example.
```java
package com.journaldev.java8.stream;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

public class StreamExample {

	public static void main(String[] args) {
		
		List<Integer> myList = new ArrayList<>();
		for(int i=0; i<100; i++) myList.add(i);
		
		//sequential stream
		Stream<Integer> sequentialStream = myList.stream();
		
		//parallel stream
		Stream<Integer> parallelStream = myList.parallelStream();
		
		//using lambda with Stream API, filter example
		Stream<Integer> highNums = parallelStream.filter(p -> p > 90);
		//using lambda in forEach
		highNums.forEach(p -> System.out.println("High Nums parallel="+p));
		
		Stream<Integer> highNumsSeq = sequentialStream.filter(p -> p > 90);
		highNumsSeq.forEach(p -> System.out.println("High Nums sequential="+p));
	}
}
```
If you will run above example code, you will get output like this:
```
High Nums parallel=91
High Nums parallel=96
High Nums parallel=93
High Nums parallel=98
High Nums parallel=94
High Nums parallel=95
High Nums parallel=97
High Nums parallel=92
High Nums parallel=99
High Nums sequential=91
High Nums sequential=92
High Nums sequential=93
High Nums sequential=94
High Nums sequential=95
High Nums sequential=96
High Nums sequential=97
High Nums sequential=98
High Nums sequential=99
```

Notice that parallel processing values are not in order, so parallel processing will be very helpful while working with huge collections.
Covering everything about Stream API is not possible in this post, you can read everything about Stream API at [Java 8 Stream API Example Tutorial](https://www.journaldev.com/2774/java-8-stream).