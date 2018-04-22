---
title: " Local Fulltext Search Engine"
date: 2018-1-6 22:07:32
---

在很多年之前Google还在中国的时候，曾经用过一个本地的搜索工具(具体名字忘记了，就是可以快速检索个人电脑中的文档)，搜索了[wiki](https://en.wikipedia.org/wiki/Google_Desktop)显示这个工具已经在2011年不更新了，不过还是放了几张图供大家看看

![searchbar](https://raw.githubusercontent.com/linychuo/my-blog/master/imgs/Googledesktopquickfindbox200906.png)
![searchresult](https://raw.githubusercontent.com/linychuo/my-blog/master/imgs/Desktop_scrshotmac.jpg)

后来想想这工具即然不更新了，何不自己做一个，说干就干，首先要对电脑上所有的文件进行索引，然后再做一个界面来响应用户输入的关键字，就这样一个大概的过程，同时还要响应新添加的文件和修改的文件进行重新索引。

索引这块很自然就想到了[lucene](https://lucene.apache.org/)，下面的话摘自于lucene官方网站
> Apache LuceneTM is a high-performance, full-featured text search engine library written entirely in Java. It is a technology suitable for nearly any application that requires full-text search, especially cross-platform.

> Apache Lucene is an open source project available for free download. Please use the links on the right to access Lucene.

在索引的文件过程中上，用到了**Files.walkFileTree**这个API（从1.7以后才有这个方法），这个API大致的含义就是遍历目录下所有的文件，代码如下：

```kotlin
private fun indexDocs(writer: IndexWriter, root: Path) {

	Files.walkFileTree(root, object : SimpleFileVisitor<Path>() {
		override fun visitFile(file: Path, attrs: BasicFileAttributes): FileVisitResult {
			// 对文件进行索引
			return FileVisitResult.CONTINUE
		}

		override fun preVisitDirectory(dir: Path, attrs: BasicFileAttributes): FileVisitResult {
			return if (dir == root) {
				FileVisitResult.CONTINUE
			} else {
				val dfa = Files.readAttributes(dir, DosFileAttributes::class.java)
				if (!dfa.isHidden && !dfa.isSystem) {
					FileVisitResult.CONTINUE
				} else {
					FileVisitResult.SKIP_SUBTREE
				}
			}
		}

		override fun visitFileFailed(file: Path, exc: IOException): FileVisitResult {
			return FileVisitResult.CONTINUE
		}
	})
}
```

上面的代码使用[kotlin](http://kotlinlang.org/)编写，其中walkFileTree有3个重要的回调接口，**visitFile**，**preVisitDirectory**和**visitFileFailed**，这3个方法在调用时会先执行preVisitDirectory，如果这个方法返回CONTINUE，那么才会调用visitFile，否则会忽略整个目录，也就不会访问这个目录下的文件。

1. visitFile方法有两个参数，一个是被访问的文件，另外一个是这个文件的相关属性，方法需要返回*FileVisitResult*，这里返回了*CONTINUE*意思就是继续下一个文件处理操作
2. preVisitDirectory方法也有两个参数，一个是要访问的目录，另外一个是这个目录的相关属性，我们通过这个方法来跳过系统中隐藏和系统级的目录，然后系统会根据这个方法的返回值来确定要不要调用visitFile，也就是要不要访问这个目录下的文件
3. visitFileFailed方法是在访问某个文件或目录失败时被调用，这里有个例子，在windows下，每个磁盘下都会有一个目录叫**System Volume Information**，这个目录是一个系统级的目录，访问这个目录会报**AccessDeniedException**，那么这个方法就会被调用

