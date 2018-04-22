---
title: "List process in python"
date: 2014-10-30 09:44:32
---

1. merge two lists: 

```python
result = listA + listB
```

2. remove duplicate item between tow list: 

```python	
result = set(listA) ^ set(listB)
```

3. get same item between tow list: 

```python
result = set(listA) & set(listB)
```