---
title: "Best Practices on how to work with collections in javascript"
date: 2018-5-19 15:14:32
---

# Motivation
Why some projects are clean, easy-to-read, and performant, while others a convoluted mess? Why, when making a modification, in some codebases everything falls into place immediately, while in others it’s more like walking on a minefield?

Writing clean code is mostly about restricting yourself from cutting corners and thus enforcing guarantees. The freedom to approach the problems from many different directions brings the responsibility not only to make the code run and do so in a performant manner but also to make it maintainable in the long run.

This list is a compilation of best practices to follow and antipatterns to avoid in order to lower the long-time cost of code involving collections. They are mostly based on principles originating from functional programming, so if you have the same background, you might find them familiar or even trivial.

A deeper understanding of how collections work helped me transition from producing code that takes more time to understand than to write, to one that is easy-to-read. I hope this compilation helps you do the same.

## Do: break functions into smaller parts
A common mistake is to write functions that do many things:
```javascript
// a user is {name: string, active: boolean, score: number}

users.filter(({active, score}) =>
	active && score > 0.5
)
```
Instead, break them into smaller parts, each responsible for one part of the logic:
```javascript
users
	.filter(({active}) =>
		active
	)
	.filter(({score}) =>
		score > 0.5
	)
```
(To learn how to use these functions, [click here](https://advancedweb.hu/2018/02/08/array_extras_course/))

## Don’t: modify the arguments
Modifying the elements of the collection seems like an optimization, as you need one less iteration. But doing so offsets the **WTFs/minute** code quality indicator in the wrong direction.

Don’t modify the elements in the iteratee:
```javascript
users.filter((user) => {
	if (user.score < 0.7) {
		user.lowrated = true;
	}
	return user.score > 0.5;
})

// users array is modified
```
Instead, do a map and copy the object:
```javascript
users
	.filter(({score}) =>
		score > 0.5
	)
	.map((user) =>
		Object.assign({}, user, user.score < 0.7 ? {lowrated: true} : {})
	)
```
Treat the input data as immutable. Processing should not change it in any way.

As a speedup, you can use a collection implementation that embraces immutability. With structural sharing, they can offer better performance than simple copying.

## Do: use object/array destructuring
When you need only a subset of the parameter objects, use destructuring.

Instead of:
```javascript
.filter((user) =>
	user.active
)
```
use:
```javascript
.filter(({active}) =>
	active
)
```
Object destructuring only works with objects. There is a [proposal](https://github.com/vacuumlabs/es-proposals/blob/master/extensible-destructuring.md) to add support to arbitrary structures, but unfortunately, it had not gained traction.

Iterables, on the other hand, are fully supported. As a result, you can destructure not only Arrays, but for example, ImmutableJs Lists, generator functions, and custom types.

## Don’t: rely on state
The iteratee should not modify anything and should use as little data bar its parameters as possible.

Instead of writing a state like this:
```javascript
let maxscore = 0;
users.filter(({score}) => {
	maxscore = Math.max(maxscore, score);
	return score > 0.5;
})
```
Use a different structure that doesn’t rely on it:
```javascript
const maxscore = users.reduce(
	(maxscore, {score}) =>
		Math.max(maxscore, score),
	0
);
```
(To learn how to use constants and make your code more readable, [click here](https://advancedweb.hu/2016/05/17/more-readable-js-without-vars/))

## Don’t: rely on the ordering of filter and map
While Javascript’s basic functions process the elements in the order they are present in the array, your code should not depend on this behavior. The iteration order is not necessarily stable in every library and definitely not in every language. Treat every iteratee function as if they are run in multiple processes concurrently, and that will set your thinking that works no matter what technology you’ll use in the future.

Instead of:
```javascript
let index = 0;
users.map(({name}) =>
	name + (index++ === 0 ? " First user!": "")
)
```
Use the index argument most of the functions get:
```javascript
users.map(({name}, index) =>
	name + (index === 0 ? " First user!": "")
)
```

## Do: use the array parameter instead of the closed array
The closed array is usually accessible in the iteratee function but use the parameter instead.

Don’t do this to make a collection of points into a circle:
```javascript
// points are {x: number, y: number}

points
	.map((point, index) =>
		[point, points[(index + 1) % points.length]]
    )
```
Do this instead:
```javascript
points
	.map((point, index, array) =>
		[point, array[(index + 1) % array.length]]
    )
```
This practice makes the code more portable. The less of the environment the functions are using, the better.

## Don’t: optimize prematurely
Optimization is usually a tradeoff between speed and readability. It’s tempting to focus on the former at the expense of the latter, but it’s usually a bad practice.

Collections are usually smaller than you think they are, and the speed of the processing is usually faster. Unless you know something is slow, don’t make it faster. Clean but slow code is easier to speed up than a fast convoluted mess to maintain.

Prefer readability, then measure. If the profiler shows a bottleneck, optimize only that bit.

## Don’t: use streaming processing (only when you know you need it)
Streaming–or lazy–processing is when only the minimum amount of processing is done to produce each result element, instead of running the steps to completion before starting the next one.

When you **map** an Array twice, all the elements are processed each time:
```javascript
[1, 2, 3]
	.map((e) => {
		console.log(`map1 ${e}`);
		return e;
	})
	.map((e) => {
		console.log(`map2 ${e}`);
		return e;
	})

// map1 1
// map1 2
// map1 3
// map2 1
// map2 2
// map2 3
```
Before the second **map** runs, all the elements had been processed by the preceding step.

Contrast that with a streaming implementation, using ImmutableJs:
```javascript
Immutable.Seq([1, 2, 3])
	.map((e) => {
		console.log(`map1 ${e}`);
		return e;
	})
	.map((e) => {
		console.log(`map2 ${e}`);
		return e;
	})
	.toArray()

// map1 1
// map2 1
// map1 2
// map2 2
// map1 3
// map2 3
```
Every element is processed completely before work on the next one starts.

(To learn how to use ES6 generator functions, [click here](https://advancedweb.hu/2016/05/31/infinite-collections-with-es6-generators/))

What seems like a performance boost and some savings in terms of memory, in practice, most of the time, the difference is negligible. On the other hand, you can easily end up with an infinite loop, more complex code, or even degrading performance.

Unless you know the performance benefits, or you work with structures you otherwise can’t (for example, infinite ones), avoid streaming processing.

(Want to know how to use generator functions with ImmutableJs? [click here](https://advancedweb.hu/2017/10/03/immutablejs_generators/))

## Do: use the Array functions if they are all you need
Arrays have most of the basic processing functions. If all you need is a **map**, **filter**, **reduce**, or **some**, use them directly on the Array without any library or wrapper. If, in the future, you’ll need a function that is missing, you can refactor them easily.

## Do: use an extensible pipeline implementation
In cases when you need to use a library of functions, opt for one that is extensible. It might not seem important the first time you want to use **last** or a similarly absent function, but later when you have complex steps, you’ll find it increasingly difficult to migrate to one.

ImmutableJs’s [update](https://facebook.github.io/immutable-js/docs/#/Collection/update) and [Lodash/FP](https://github.com/lodash/lodash/wiki/FP-Guide) are my go-to choices.

(To learn how Lodash/FP works, [click here](https://advancedweb.hu/2017/12/19/functional_composition/))

## Don’t: build an Array in reduce
**reduce** is the most versatile function used to process collections. It can emulate the others, as the return value can be anything.

But that doesn’t mean you should use it when a more specialized function is available.

While this code, using **reduce**:
```javascript
users
	.reduce(
		(acc, user) =>
			user.score > 0.5 ?
				[...acc, Object.assign({}, user, user.score < 0.7 ?
					{lowrated: true} :
					{})
				] :
				acc,
		[]
    )
```
Is the same as this one, using a filter and a map:
```javascript
users
	.filter(({score}) =>
		score > 0.5
	)
	.map((user) =>
		Object.assign({}, user, user.score < 0.7 ? {lowrated: true} : {})
    )
```
The latter communicates the intention far better.

As a rule of thumb, whenever you write a **reduce** that returns a collection instead of a value, consider whether a different function would be a better alternative. As usual, there are some exceptions, but using them usually results in more readable code.

## Do: use a flat structure
A flat structure is when most of the code is on the same indentation level. Using collection pipelines, it is usually a feature you get for free:
```javascript
users
	.map(...)
	.filter(...)
    .reduce(...)
```
In some cases, this flat structure is compromised:
```javascript
const processUsers = (users) => {...}
const filterUsers = (users) => {...}

filterUsers( // 3
	processUsers(users) // 1
		.map(...) // 2
);
```
The flat structure is gone, and as a result, the order of operations is messed up. This should be a red flag that something is wrong.

This is the scenario when using an extensible collection pipeline implementation pays off. Those support adding functions while retaining the structure. For example:
```javascript
Immutable.List(users)
	.update(processUsers) // 1
	.map(...) // 2
    .update(filterUsers) // 3
```
As usual, there are exceptions. For example, when you need processing inside a processing step:
```javascript
users
	.map((user) =>
		posts
			.filter(...)
			.map(...)
			.reduce(...)
	)
    .filter(...)
```
In complex use cases, structures like this emerge. If you want, you can move the iteratees to separate functions:
```javascript
const postsForUsers = (user) =>
	posts
		.filter(...)
		.map(...)
		.reduce(...)

users
	.map(postsForUsers)
    .filter(...)
```
Whether you want to move complex steps to separate functions or not is a matter of preference and style. Some people prefer a lot of small functions with descriptive names, some argue that having everything in one place is better.

As for myself, I prefer monoliths as long as I can understand the functionality without much difficulty. When all the functions follow a purely functional style, refactoring them is trivial.

There is an exception though. If you need the same step in multiple places, move that to a separate function instead of copy-pasting.

(To learn more about collection pipelines, [click here](https://advancedweb.hu/guides.html#collection_pipelines-ref))

## Do: provide an initial value for reduce
**reduce** has an optional second argument: the initial value. It seems like it is only useful when **undefined** is not suitable, but there is a critical difference. When an Array has no elements, **reduce** without an initial value does not return **undefined**, but throws an Error instead:
```javascript
[].reduce(() => {}) // TypeError: Reduce of empty array with no initial value
```
But with an initial value set, the result is that value:
```javascript
[].reduce(() => {}, 0) // 0
```
You should always supply an initial value for **reduce** if there is a sensible one.

## Do: use the shorter form of arrow functions
Arrow functions have shorter forms, making them more suitable for one-liners. Instead of writing out the full structure:
```javascript
() => {
	return ...
}
```
If there is only a return statement, the block is optional:
```javascript
() => ...
```
For simple steps, prefer the latter. This usually makes them one-liners, and those are easier to scan.

Instead of:
```javascript
array
	.map((e) => {
		return ...;
	})
	.filter((e) => {
		return ...;
    })
```
Use:
```javascript
array
	.map((e) => ...)
    .filter((e) => ...)
```
The parentheses around the parameters are also optional, making the construct even shorter.

## Do: reuse parts of the pipeline
If you need a piece of functionality in several places, move that to a separate function and use that, don’t copy-paste.

Instead of:
```javascript
const arr1 = users
	.filter(({score}) => score > 0.5)
	.map(...)

const arr2 = users
	.filter(({score}) => score > 0.5)
    .map(...)
```
Do:
```javascript
const bySufficientScore = ({score}) => score > 0.5;

const arr1 = users
	.filter(bySufficientScore)
	.map(...)

const arr2 = users
	.filter(bySufficientScore)
    .map(...)
```
For reusing complex steps (for example, **filter** + **map**), use a pipeline implementation that supports that.

##  Do: know the complexity of the operations
Knowing the algorithmic cost of each function helps estimate the overall complexity of the pipeline.

A few commonly used functions:
- **map**, **filter**: **O(n)**
- **reduce**: **O(n)**, but look out what you do in the iteratee function. If you build an array, it can easily be **O(n^2)**
- **sort**: **O(n * log(n))**
- **some** / **every**: **O(n)**, and they can short-circuit on the first **true** / **false**, respectively
Generally, the complexities are added for subsequent steps and multiplied for nested ones.

For a flat structure like this:
```javascript
array
	.filter(...)
	.map(...)
    .filter(...)
```
The complexity is **O(n + n + n)**, which is still **O(n)**.

For a nested structure:
```javascript
array
	.map((e) => {
		...
		users.filter(...)
		...
		return ...
    })
```
The complexity is **O(n * n)**.

As a rule of thumb, having O(n) and O(n * log(n)) should be scalable, O(n^2) will only work for small arrays, anything bigger can easily be a bottleneck.

## Closing remarks
Apart from a few general guidelines, best practices are the result of the environment too. If, for example, you work with memory-constrained embedded systems, your rules might be entirely different.

Also, software craftsmanship is more of an art than exact science, and as such, everything you write has your distinctive style. But I believe if you have no well-defined reason not to, following the principles above will help you write better code.

Is there anything you’d add? Let me know, and I’ll update this post.

[Origin Links](https://advancedweb.hu/2018/03/13/dos_donts_collection_processing/)
