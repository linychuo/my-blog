---
layout: post
title:  "StringBuilder vs StringBuffer vs StringWriter"
date:   2014-10-30 09:07:32
categories: java
---

In java programming, We often using these three class about string building. Then, what difference about them?

1. *StringBuffer* and *StringBuilder*, They were used to dynamic building string, You could know its thread safe after reading source code of *StringBuffer*, and *StringBuilder* is not thread safe, so *StringBuffer* performance less than *StringBuilder* on a single thread. But on the multi-thread, *StringBuffer* would be safe.
2. *StringWrite* also dynamic building string, It was implemented by *StringBuffer*