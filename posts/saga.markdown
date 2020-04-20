---
title: "Saga"
date_time: 2020-04-20 22:23:32
tags: microservice saga
---

> 之前的微服务架构中提到每一个服务都有自己独立的数据库，有自己的事务处理机制，但是当在跨服务之间，你需要自己来处理事务来保持数据的一致性。

### 那么问题来了，该怎么来维护跨服务的数据一致性呢？？

首先提到一个概念2PC（Two-Phase Commit: 两阶段提交），关于这个概念在这这里不做深究，给大家分享几篇关于这个概念的文章：
- <a href="https://docs.microsoft.com/en-us/host-integration-server/core/two-phase-commit2" target="_blank">https://docs.microsoft.com/en-us/host-integration-server/core/two-phase-commit2</a>
- <a href="https://docs.oracle.com/cd/B28359_01/server.111/b28310/ds_txns003.htm#ADMIN12222" targe="_blank">https://docs.oracle.com/cd/B28359_01/server.111/b28310/ds_txns003.htm#ADMIN12222</a>

### 解决方案
为每个业务服务实现一个本地事务管理器，它会横跨多个业务服务，这就是一个Saga。一个Saga就是一组本地事务的序列。每个本地事务会在更新数据库时发布消息或触发事件去告知这个Saga里其它的本地事务，如果其中一个业务服务的本地事务失败，那么Saga会通过执行一系列的补偿措施例如回滚之前的本地事务的操作来达到数据的一致性
![From_2PC_To_Saga.png](/imgs/From_2PC_To_Saga.png)

有两种方式的Saga事务协调机制
- 每一个本地事务通过发布领域事件来告知其它服务的本地事务
- 每一个参与者告诉其它的参与者我的本地事务都干一些什么