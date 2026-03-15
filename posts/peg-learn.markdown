---
title: "Parsing Expression Garmmer"
date_time: 2025-03-15 14:41:32
tags: peg zig
---

## PEG
PEG(Parsing Expression Garmmer，解析文法表达式)是一种用于定义语法规则的形式化的方法，主要用于解析(Parsing)。它特别适合解析器的实现。

### PEG 语法规则
PEG 规则通常由以下几种基本操作组成：

- **序列（Sequence）**：`A B` 表示 `A` 解析成功后，继续解析 `B`。
- **选择（Ordered Choice）**：`A / B` 表示尝试解析 `A`，如果失败，再尝试 `B`。
- **零次或多次（Zero or More）**：`A*` 表示匹配 `A` 0 次或多次。
- **一次或多次（One or More）**：`A+` 表示匹配 `A` 1 次或多次。
- **可选（Optional）**：`A?` 表示 `A` 可以出现 0 或 1 次。
- **前瞻（Lookahead）**：
    - 正前瞻：`&A` 表示如果 `A` 可以匹配，则继续（但不消费输入）。
    - 负前瞻：`!A` 表示如果 `A` 不能匹配，则继续（不消费输入）。

## 举个例子
以解析一行最基础的sql为例，来实现一个最简单的解析器, sql如下:
```sql
SELECT name, age FROM users;
```

拆解成不同的组成部分：

1. `SELECT` 关键字（必须有）。
2. **列列表**：`name, age`（可以是多个，用 , 分隔）。
3. `FROM` 关键字（必须有）。
4. **表名**：`users`（单个标识符）。
5. 语句以 `;` 结束（可选）。


### 定义PEG语法
```peg
SelectStatement <- "SELECT" _ ColumnList _ "FROM" _ TableName _ ";"
ColumnList      <- "*" / Identifier ("," _ Identifier)*
TableName       <- Identifier
Identifier      <- [a-zA-Z_][a-zA-Z0-9_]*
_               <- [ \t\n\r]*
```

### 语法解释
- `SelectStatement`
    - 以`SELECT`开头(区分大小写)
    - 解析`ColumnList`(支持*或多个列名)
    - `FROM`关键字
    - `TableName`单个标识符
    - 以`;`结束
- `ColumnList`
    - `*`代表所有列
    - 或者是一组`Identifier`(列名)，用`,`分隔
- `TableName`
    - 解析一个`标识符`，代表表名
- `Identifier`
    - 匹配`SQL允许的标识符`(字母，数字，下划线)
- `_`
    - 允许空格，换行等，确保解析不会被空格干扰|

### 解析实例
```sql
SELECT name, age FROM users;
```
#### 解析步骤
1. `SELECT` 匹配成功。
2. `ColumnList` 解析：
    - `name`（标识符）
    - `, age`（标识符）
3. `FROM` 匹配成功。
4. `TableName` 解析 `users`。
5. `;` 结束，解析成功！


```sql
SELECT * FROM employees;
```
#### 解析步骤
1. `SELECT` 匹配成功。
2. `ColumnList` 解析 `*`。
3. `FROM` 匹配成功。
4. `TableName` 解析 `employees`。
5. `;` 结束，解析成功！