---
title: "Function invoking rule of javascript"
date: 2014-10-30 09:23:32
---

- JavaScript函数调用规则一

全局函数调用
	
	function makeArray( arg1, arg2 ){ 
		return [this , arg1 , arg2 ]; 
	}

这是一个最常用的定义函数方式。相信学习JavaScript的人对它的调用并不陌生。调用代码如下：
	
	makeArray('one', 'two'); 
	// => [window, 'one', 'two'] 

这种方式可以说是全局的函数调用。 为什么说是全局的函数？ 因为它是全局对象window 的一个方法, 我们可以用如下方法验证：

	alert( typeof window.methodThatDoesntExist ); 
	// => undefined 
	alert( typeof window.makeArray); 
	// => function  

所以我们之前调用 makeArray的方法是和下面调用的方法一样的

	window.makeArray('one', 'two'); 
	// => [ window, 'one', 'two' ] 


- JavaScript函数调用规则二

对象方法调用

	//creating the object 
	var arrayMaker = { 
		someProperty: 'some value here', 
		make: makeArray 
	}; 
	arrayMaker.make('one', 'two');     // => [ arrayMaker, 'one', 'two' ] 
	//或者用下面的方法调用： 
	arrayMaker['make']('one', 'two');  // => [ arrayMaker, 'one', 'two' ]  


看到这里跟刚才的区别了吧,this的值变成了对象本身. 你可能会质疑：为什么原始的函数定义并没有改变,而this却变化了呢？非常好，有质疑是正确的。这里涉及到 函数在JavaScript中传递的方式,  函数在JavaScript 里是一个标准的数据类型, 确切的说是一个对象.你可以传递它们或者复制他们. 就好像整个函数连带参数列表和函数体都被复制, 且被分配给了 arrayMaker 里的属性 make,那就好像这样定义一个 arrayMaker:

	var arrayMaker = { 
		someProperty: 'some value here', 
		make: function (arg1, arg2) { 
			return [ this, arg1, arg2 ]; 
		} 
	};

如果不把调用规则二 弄明白，那么在事件处理代码中 经常会遇到各种各样的bug，举个例子：

	<input type="button" value="Button 1" id="btn1" /> 
	<input type="button" value="Button 2" id="btn2" /> 
	<input type="button" value="Button 3" id="btn3" onclick="buttonClicked();"/> 
	<script type="text/javascript"> 
		function buttonClicked(){ 
			var text = (this === window) ? 'window' : this.id; 
			alert( text ); 
		} 
		var button1 = document.getElementById('btn1'); 
		var button2 = document.getElementById('btn2'); 
		button1.onclick = buttonClicked; 
		button2.onclick = function(){    
			buttonClicked();    
		}; 
	</script>   


点击第一个按钮将会显示”btn1”，因为它是一个方法调用,this为所属的对象(按钮元素) 。 
点击第二个按钮将显示”window”，因为 buttonClicked 是被直接调用的( 不像 obj.buttonClicked() )， 
这和第三个按钮,将事件处理函数直接放在标签里是一样的.所以点击第三个按钮的结果是和第二个一样的。
所以请大家注意：

	button1.onclick = buttonClicked; 
	button2.onclick = function(){    
		buttonClicked();    
	}; 

**this指向是有区别的。**

- JavaScript函数调用规则三

当然，如果使用的是jQuery库，那么你不必考虑这么多，它会帮助重写this的值以保证它包含了当前事件源元素的引用。

	//使用jQuery 
	$('#btn1').click( function() { 
		alert( this.id ); // jQuery ensures 'this' will be the button 
	}); 

那么 jQuery是如何重载this的值的呢? 
答案是： call()和apply();

当函数使用的越来越多时，你会发现你需要的this 并不在相同的上下文里，这样导致通讯起来异常困难。在Javascript中函数也是对象,函数对象包含一些预定义的方法,其中有两个便是apply()和call(),我们可以使用它们来对this进行上下文重置。

	<input type="button" value="Button 1" id="btn1"  /> 
	<input type="button" value="Button 2" id="btn2"  /> 
	<input type="button" value="Button 3" id="btn3"  onclick="buttonClicked();"/> 
	<script type="text/javascript"> 
	function buttonClicked(){ 
		var text = (this === window) ? 'window' : this.id; 
		alert( text ); 
	} 
	var button1 = document.getElementById('btn1'); 
	var button2 = document.getElementById('btn2'); 
	button1.onclick = buttonClicked; 
	button2.onclick = function(){    
		buttonClicked.call(this);  // btn2 
	}; 
	</script>

- JavaScript函数调用规则四

构造器

我不想深入研究在Javascript中类型的定义,但是在此刻我们需要知道在Javascript中没有类, 而且任何一个自定义的类型需要一个初始化函数,使用原型对象(作为初始化函数的一个属性)定义你的类型也是一个不错的想法, 让我们来创建一个简单的类型

	//声明一个构造器 
	function ArrayMaker(arg1, arg2) { 
		this.someProperty = 'whatever'; 
		this.theArray = [ this, arg1, arg2 ]; 
	} 
	// 声明实例化方法 
	ArrayMaker.prototype = { 
		someMethod: function () { 
			alert( 'someMethod called'); 
		}, 
		getArray: function () { 
			return this.theArray; 
		} 
	}; 
	var am = new ArrayMaker( 'one', 'two' ); 
	var other = new ArrayMaker( 'first', 'second' ); 
	am.getArray(); 
	// => [ am, 'one' , 'two' ] 
	other.getArray(); 
	// => [ other, 'first', 'second'  ] 

一个非常重要并值得注意的是出现在函数调用前面的new运算符,没有那个,你的函数就像全局函数一样,且我们创建的那些属性都将是创建在全局对象上(window)，而你并不想那样。 

另外一点,因为在你的构造器里没有返回值,所以如果你忘记使用new运算符,将导致你的一些变量被赋值为 undefined。所以构造器函数以大写字母开头是一个好的习惯,这可以作为一个提醒,让你在调用的时候不要忘记前面的new运算符.这样 初始化函数里的代码和你在其他语言里写的初始化函数是相似的.this的值将是你将创建的对象.

总结: 我希望通过这些来使你们理解各种函数调用方式的不同，让你的JavaScript代码远离bugs。知道this的值是你避免bugs的第一步。