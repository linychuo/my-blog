---
title: "Java8 new features [3]"
date: 2018-5-7 19:05:32
---

1. [Java Time API](#first)
2. [Collection API improvements](#second)
3. [Concurrency API improvements](#third)
4. [Java IO improvements](#fourth)
5. [Miscellaneous Core API improvements](#fifth)

## <a id="first"></a>Java Time API
It has always been hard to work with Date, Time and Time Zones in java. There was no standard approach or API in java for date and time in Java. One of the nice addition in Java 8 is the java.time package that will streamline the process of working with time in java.

Just by looking at Java Time API packages, I can sense that it will be very easy to use. It has some sub-packages **java.time.format** that provides classes to print and parse dates and times and **java.time.zone** provides support for time-zones and their rules.

The new Time API prefers enums over integer constants for months and days of the week. One of the useful class is **DateTimeFormatter** for converting datetime objects to strings.

For complete tutorial, head over to [Java Date Time API Example Tutorial](https://www.journaldev.com/2800/java-8-date-localdate-localdatetime-instant).

## <a id="second"></a>Collection API improvements
We have already seen forEach() method and Stream API for collections. Some new methods added in Collection API are:

- **Iterator** default method **forEachRemaining(Consumer action)** to perform the given action for each remaining element until all elements have been processed or the action throws an exception.
- **Collection** default method **removeIf(Predicate filter)** to remove all of the elements of this collection that satisfy the given predicate.
- **Collection spliterator()** method returning Spliterator instance that can be used to traverse elements sequentially or parallel.
- Map **replaceAll()**, **compute()**, **merge()** methods.
- Performance Improvement for HashMap class with Key Collisions

## <a id="third"></a>Concurrency API improvements
Some important concurrent API enhancements are:

- **ConcurrentHashMap** compute(), forEach(), forEachEntry(), forEachKey(), forEachValue(), merge(), reduce() and search() methods.
- **CompletableFuture** that may be explicitly completed (setting its value and status).
- **Executors newWorkStealingPool()** method to create a work-stealing thread pool using all available processors as its target parallelism level.

## <a id="fourth"></a>Java IO improvements
Some IO improvements known to me are:

- Files.list(Path dir) that returns a lazily populated Stream, the elements of which are the entries in the directory.
- Files.lines(Path path) that reads all lines from a file as a Stream.
- Files.find() that returns a Stream that is lazily populated with Path by searching for files in a file tree rooted at a given starting file.
- BufferedReader.lines() that return a Stream, the elements of which are lines read from this BufferedReader.

## <a id="fifth"></a>Miscellaneous Core API improvements
Some misc API improvements that might come handy are:

1. [ThreadLocal](https://www.journaldev.com/1076/java-threadlocal-example) static method withInitial(Supplier supplier) to create instance easily.
2. [Comparator](https://www.journaldev.com/780/comparable-and-comparator-in-java-example) interface has been extended with a lot of default and static methods for natural ordering, reverse order etc.
3. min(), max() and sum() methods in Integer, Long and Double wrapper classes.
4. logicalAnd(), logicalOr() and logicalXor() methods in Boolean class.
5. [ZipFile](https://www.journaldev.com/957/java-zip-file-folder-example).stream() method to get an ordered Stream over the ZIP file entries. Entries appear in the Stream in the order they appear in the central directory of the ZIP file.
6. Several utility methods in Math class.
7. **jjs** command is added to invoke Nashorn Engine.
8. **jdeps** command is added to analyze class files
9. JDBC-ODBC Bridge has been removed.
10. PermGen memory space has been removed