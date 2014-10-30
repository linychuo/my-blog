---
layout: post
title:  "eval usage"
date:   2014-10-30 09:21:32
categories: javascript
---
eval()函数

JavaScript有许多小窍门来使编程更加容易。
其中之一就是eval()函数，这个函数可以把一个字符串当作一个JavaScript表达式一样去执行它。
举个小例子：

	var the_unevaled_answer = "2 + 3";
	var the_evaled_answer = eval("2 + 3");
	alert("the un-evaled answer is " + the_unevaled_answer + " and the evaled answer is " + the_evaled_answer);
 
	var name="Jimmy",
	var age=23;
	var json="{name:'"+name+"',age:"+age+"}";
	//这里通过eval函数可以将一个字符串转换成json. 
	json = eval('('+json+')');
	alert(json.name+"="+json.age);



	//也可以用以下的办法，也可以将一个字符串转换成json 
	var fun = new Function("return "+arr);
	var obj = fun();
	alert(obj.name+"="+obj.age);


不过这种方法明显没有eval用起来方便。 