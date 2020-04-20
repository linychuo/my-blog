---
title: "Saga"
date_time: 2020-04-20 22:23:32
tags: microservice saga
---

> 之前的微服务架构中提到每一个服务都有自己独立的数据库，有自己的事务处理机制，但是当在跨服务之间，你需要自己来处理事务来保持数据的一致性。

### 那么问题来了，该怎么来维护跨服务的数据一致性呢？？

首先提到一个概念2PC（Two-Phase Commit: 两阶段提交），关于这个概念在这这里不做深究，给大家分享几篇关于这个概念的文章：
- https://docs.microsoft.com/en-us/host-integration-server/core/two-phase-commit2
- https://docs.oracle.com/cd/B28359_01/server.111/b28310/ds_txns003.htm#ADMIN12222

### 解决方案
