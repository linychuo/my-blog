---
title: "Lookahead and Lookbehind in Java Regex"
date_time: 2021-12-30 10:07:32
tags: java regex
---

## 1. Overview
Sometimes we might face difficulty matching a string with a regular expression. For example, we might not know what we want to match exactly, but we can be aware of its surroundings, like what comes directly before it or what is missing from after it. In these cases, we can use the lookaround assertions. These expressions are called assertions because they only indicate if something is a match or not but are not included in the result.

In this tutorial, we'll take a look at how we can use the four types of regex lookaround assertions.

## 2. Positive Lookahead
Let's say we'd like to analyze the imports of java files. First, let's look for import statements that are static by checking that the static keyword follows the import keyword.

Let's use a positive lookahead assertion with the (?=criteria) syntax in our expression to match the group of characters static after our main expression import:

```java
Pattern pattern = Pattern.compile("import (?=static).+");

Matcher matcher = pattern
  .matcher("import static org.junit.jupiter.api.Assertions.assertEquals;");
assertTrue(matcher.find());
assertEquals("import static org.junit.jupiter.api.Assertions.assertEquals;", matcher.group());

assertFalse(pattern.matcher("import java.util.regex.Matcher;").find());
```

## 3. Negative Lookahead
Next, let's do the direct opposite of the previous example and look for import statements that are not static. Let's do this by checking that the static keyword does not follow the import keyword.

Let's use a negative lookahead assertion with the (?!criteria) syntax in our expression to ensure that the group of characters static cannot match after our main expression import:

```java
Pattern pattern = Pattern.compile("import (?!static).+");

Matcher matcher = pattern.matcher("import java.util.regex.Matcher;");
assertTrue(matcher.find());
assertEquals("import java.util.regex.Matcher;", matcher.group());

assertFalse(pattern
  .matcher("import static org.junit.jupiter.api.Assertions.assertEquals;").find());
```

## 4. Limitations of Lookbehind in Java
Up until Java 8, we might run into the limitation that unbound quantifiers, like + and *, are not allowed within a lookbehind assertion. That is to say, for example, the following assertions will throw PatternSyntaxException up until Java 8:

- (?<!fo+)bar, where we don't want to match bar if fo with one or more o characters come before it
- (?<!fo*)bar, where we don't want to match bar if it is preceded by an f character followed by zero or more o characters
- (?<!fo{2,})bar, where we don't want to match bar if foo with two or more o characters come before it

As a workaround, we might use a curly braces quantifier with a specified upper limit, for example (?<!fo{2,4})bar, where we maximize the number of o characters following the f character to 4.

Since Java 9, we can use unbound quantifiers in lookbehinds. However, because of the memory consumption of the regex implementation, it is still recommended to only use quantifiers in lookbehinds with a sensible upper limit, for example (?<!fo{2,20})bar instead of (?<!fo{2,2000})bar.


## 5. Positive Lookbehind
Let's say we'd like to differentiate between JUnit 4 and JUnit 5 imports in our analysis. First, let's check if an import statement for the assertEquals method is from the jupiter package.

Let's use a positive lookbehind assertion with the (?<=criteria) syntax in our expression to match the character group jupiter before our main expression .*assertEquals:

```java
Pattern pattern = Pattern.compile(".*(?<=jupiter).*assertEquals;");

Matcher matcher = pattern
  .matcher("import static org.junit.jupiter.api.Assertions.assertEquals;");
assertTrue(matcher.find());
assertEquals("import static org.junit.jupiter.api.Assertions.assertEquals;", matcher.group());

assertFalse(pattern.matcher("import static org.junit.Assert.assertEquals;").find());
```

## 6. Negative Lookbehind
Next, let's do the direct opposite of the previous example and look for import statements that are not from the jupiter package.

To do this, let's use a negative lookbehind assertion with the (?<!criteria) syntax in our expression to ensure that the group of characters jupiter.{0,30} cannot match before our main expression assertEquals:

```java
Pattern pattern = Pattern.compile(".*(?<!jupiter.{0,30})assertEquals;");

Matcher matcher = pattern.matcher("import static org.junit.Assert.assertEquals;");
assertTrue(matcher.find());
assertEquals("import static org.junit.Assert.assertEquals;", matcher.group());

assertFalse(pattern
  .matcher("import static org.junit.jupiter.api.Assertions.assertEquals;").find());
```