---
title: "Iterators of python"
date: 2014-10-30 09:52:32
---

在python中，iterator是一个容器对象，它实现了iterator协议，它的实现基于下面2个方法：

- next 它返回容器中的下个元素
- __iter__ 它返回iterator自己

一个Iterators对象可以通过python内置的函数iter所创建成一个序列，例如

```python
>>> i = iter('abc')
>>> i.next()
'a'
>>> i.next()
'b'
>>> i.next()
'c'
>>> i.next()
Traceback (most recent call last):
	File "<stdin>", line 1, in <module>
StopIteration
```

当这个序列超出界限时，系统将会触发StopIteration异常，这使得Iterators停止获取下个元素，这个循环是一个道理。我们可以自己定义一个iterator,按上面说的，必须重写next和__iter__这两个方法：

```python
>>> class MyIterator(object):
...     def __init__(self, step):
...         self.step = step
...     def next(self):
...         """Returns the next element."""
...         if self.step == 0:
...             raise StopIteration
...         self.step -= 1
...         return self.step
...     def __iter__(self):
...         """Returns the iterator itself."""
...         return self
...
>>> for el in MyIterator(4):
...     print el
3
2
1
0
```

Iterators在python中是一比较底层的功能和概念，任何一个程序没有它们可以照样运行。但是它提供了一个非常有趣的功能，叫generators。我将在另外一篇文章里讲解。
