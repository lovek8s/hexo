---
layout: post
title: Elas2.3.4升级到es5.X
author: owelinux
categories: linux
tags: linux  ELK
excerpt: Elas2.3.4升级到es5.X
mathjax: true
abbrlink: a8bec429
date: 2018-08-23 18:41:54
---

* content
{:toc}

# Elas2.3.4升级到es5.X

## 1、Disable shard allocation
```
curl -XPOST http://127.0.0.1:9200/_flush/synced

curl -XPUT http://127.0.0.1:9200/_cluster/settings -d'
{
  "persistent": {
    "cluster.routing.allocation.enable": "none"
  }
}'
```

## 2、Perform a synced flush
```
curl -XPOST http://127.0.0.1:9200/_flush/synced
```

## 3、Shutdown and upgrade all nodes
```
curl -XPOST http://127.0.0.1:9200/_cluster/nodes/_local/_shutdown
```

## 4、Upgrade any plugins


## 5、Start the cluster
```
curl -XGET  http://127.0.0.1:9200/_cat/health
curl -XGET  http://127.0.0.1:9200/_cat/nodes
```

## 6、Wait for yellow

## 7、Reenable allocation
```
curl -XPUT http://127.0.0.1:9200/_cluster/settings -d'
{
  "persistent": {
    "cluster.routing.allocation.enable": "all"
  }
}'

curl -XGET  http://127.0.0.1:9200/_cat/health

curl -XGET  http://127.0.0.1:9200/_cat/recovery
```

## 参考
> * [https://www.elastic.co/guide/en/elasticsearch/reference/5.5/setup-upgrade.html](https://www.elastic.co/guide/en/elasticsearch/reference/5.5/setup-upgrade.html)