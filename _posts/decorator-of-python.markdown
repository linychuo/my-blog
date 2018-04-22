---
title: "Decorator of python"
date: 2014-10-30 09:51:32
---

在python2.4的添加一个新的特性叫装饰器，它用来包装函数（一个函数能够接受一个函数类型的参数，然后扩展这个函数，返回其调用的结果），这样让我们更容易阅读和了解一个函数的定义。老的语法里可以将一个类里的函数定义成static method，这种语法可以认为是decorator的前身，通常是这样：

```python
class WhatFor(object):
	def it(cls):
		print 'work with %s' % cls
	it = classmethod(it)
	
	def uncommon():
		print 'I could be a global function'
	
	uncommon = staticmethod(uncommon)
```

但是这种方式比较难以阅读，尤其是当一个函数变得很大的时候，或者我们定义了很多的static method的时候。所以装饰器这种轻量的语法结构对于我们阅读代码就非常容易，就象下面这样：

```python
class WhatFor(object):
	@classmethod
	def it(cls):
		print 'work with %s' % cls

	@staticmethod
	def uncommon():
		print 'I could be a global function'
```

```bash
>>> this_is = WhatFor()
>>> this_is.it()
work with <class '__main__.WhatFor'>
>>> this_is.uncommon()
I could be a global function
```

接下来，我们就来看看怎么样写一个Decorator, 其实有好多种方式来自定义一个decorator，但是最简单和可读性最好的一种方法就是定一个函数，在这个函数里返回一个子函数，这个子函数用来包装原来的函数调用，代码如下：

```python
def mydecorator(function):
	def _mydecorator(*args, **kw):
		# do some stuff before the rea
		# function gets called 
		res = function(*args, **kw)
		# do some stuff after
		return res
	# returns the sub-function
	return _mydecorator
```

这里要注意的是，当你定义一个decorator时，你最好是给出一个明确的子函数名字象_mydecorator一样，而不是一个很通俗的名字wrapper，因为当出现错误或者异常的时候，你就很容易通过阅读错误日志去修改你的decorator。当一个函数在执行时需要检查参数的话，你就需要第二级的扩展函数。就象这样

```python
def mydecorator(arg1, arg2):
	def _mydecorator(function):
		def __mydecorator(*args, **kw):
			# do some stuff before the real
			# function gets called 
			res = function(*args, **kw)
			# do some stuff after
			return res
		# returns the sub-function
		return __mydecorator
	return _mydecorator
```

当一个模块第一次被读取的时候，它里面的decorator被解释器加载，那么它就被限定为是一个包装器能够被去修饰所有的函数。如果一个decorator绑定一个类方法或者是一个函数，那么这个类方法或者是函数的功能就会被增强，而在你在定义调用目标函数或者类方式时，这段代码尽量不要复杂。

在任何情况下，当你定义了decorator，最好的做法就是单独一个模块将它们组织在一起，这样有利于后期的维护。

在python里面，decorator已经被广泛的应用以下的模式中：

- 参数检查
- 缓存
- 代理
- 上下文管理
