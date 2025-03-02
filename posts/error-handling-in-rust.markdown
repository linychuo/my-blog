---
title: "Rust学习总结"
date_time: 2025-03-01 20:42:32
tags: rust
---

最近迷上和copilot结对编程了，就找了自己之前的博客生成工具，让copilot挨个对之前的rs文件优化，从中又学到了不少的rust知识，把自己好多年前学的rust又捡了起来，然后专门记录一下几个小小的优化点。

### 1. PathBuf vs Path
- 两个都是用来处理文件路径的，它们比直接使用字符串更安全和方便，它们针对不同的平台有对应平台的处理，例如路径分隔符(windows的\ 和 linux的 /)，同时还大小写敏感(windows除外)。
- #### PathBuf
    1. 拥有所有权：PathBuf 是一个拥有所有权的类型，类似于 String。它可以在函数之间传递和修改。
    2. 可变：PathBuf 是可变的，可以动态地修改其值。
    3. 构建和操作路径：PathBuf 提供了多种方法来构建和操作路径，例如 push、pop 等。
- #### Path
    1. 借用类型：Path 是一个借用类型，类似于 &str。它是 PathBuf 的切片，不能修改其值。
    2. 不可变：Path 是不可变的，只能用于读取路径信息。
    3. 轻量级：Path 更轻量级，适合在不需要修改路径的情况下使用。

```rust
use std::path::{Path, PathBuf};

fn main() {
    // 使用 PathBuf 构建和修改路径
    let mut path_buf = PathBuf::from("/home/user");
    path_buf.push("documents");
    println!("PathBuf: {:?}", path_buf);

    // 使用 Path 引用路径
    let path: &Path = Path::new("/home/user/documents");
    println!("Path: {:?}", path);

    // 将 PathBuf 转换为 Path 引用
    let path_from_buf: &Path = path_buf.as_path();
    println!("Path from PathBuf: {:?}", path_from_buf);
}
```

### 2. String vs &str
- #### String
    1. 拥有所有权：String 是一个拥有所有权的类型，类似于 Vec<T>。它在堆上分配内存，可以在函数之间传递和修改。
    2. 可变：String 是可变的，可以动态地修改其值。
    3. 动态大小：String 可以动态地增长和缩小，其大小在运行时确定。
- #### &str
    1. 借用类型：&str 是一个借用类型，类似于 &[T]。它是对字符串数据的引用，不能修改其值。
    2. 不可变：&str 是不可变的，只能用于读取字符串信息。
    3. 静态或动态：&str 可以是静态的（例如字符串字面量）或动态的（例如从 String 中借用）。

```rust
fn main() {
    // 使用 String
    let mut s = String::from("Hello");
    s.push_str(", world!");
    println!("String: {}", s);

    // 使用 &str
    let s_slice: &str = &s;
    println!("&str: {}", s_slice);

    // 静态 &str
    let static_str: &str = "Hello, world!";
    println!("Static &str: {}", static_str);
}
```

### 3. unwrap or unwrap_or_else
在 Rust 中，unwrap 和 unwrap_or_else 是处理 Option 和 Result 类型的方法，用于错误处理。它们的主要区别在于错误处理的方式。
- #### unwrap
unwrap 方法用于直接获取 Option 或 Result 中的值。如果值存在，它会返回该值；如果值不存在（即 None 或 Err），它会导致程序崩溃并打印错误信息。
适用于你确定值一定存在的情况，否则会引发恐慌（panic）。

```rust
fn main() {
    let some_option = Some(5);
    let value = some_option.unwrap();
    println!("Value: {}", value);

    let none_option: Option<i32> = None;
    // 下面这行代码会导致程序崩溃
    // let value = none_option.unwrap();
}
```
- #### unwrap_or_else
unwrap_or_else 方法允许你在值不存在时提供一个默认的处理函数。它接受一个闭包，当 Option 是 None 或 Result 是 Err 时，调用该闭包并返回其结果。
适用于你需要在值不存在时执行一些自定义逻辑的情况。

```rust
fn main() {
    let some_option = Some(5);
    let value = some_option.unwrap_or_else(|| {
        println!("Value not found, returning default value.");
        0
    });
    println!("Value: {}", value);

    let none_option: Option<i32> = None;
    let value = none_option.unwrap_or_else(|| {
        println!("Value not found, returning default value.");
        0
    });
    println!("Value: {}", value);
}
```

### 4. if let
在 Rust 中，if let 是一种模式匹配的简洁语法，用于处理 Option 和 Result 类型的值。它允许你在值存在时执行某些操作，而在值不存在时执行其他操作。

```rust
fn main() {
    let some_option = Some(5);

    // 使用 if let 处理 Option
    if let Some(value) = some_option {
        println!("Value: {}", value);
    } else {
        println!("Value not found");
    }

    let none_option: Option<i32> = None;

    // 使用 if let 处理 Option
    if let Some(value) = none_option {
        println!("Value: {}", value);
    } else {
        println!("Value not found");
    }
}
```

- #### 总结
使用 if let 可以简化对 Option 和 Result 类型的模式匹配，避免显式地使用 match 语句。
当值存在时，if let 会执行相应的代码块；当值不存在时，可以使用 else 块执行其他操作。