---
layout: post
title: Telegraf+Infludb+Grafana构建可视化监控系统
author: owelinux
categories: linux
tags: linux  telegraf infludb granfan
excerpt: Telegraf+Infludb+Grafana构建可视化监控系统
mathjax: true
abbrlink: 1847d09
date: 2018-08-24 15:37:54
---

* content
{:toc}

# Telegraf+Infludb+Grafana构建可视化监控系统

## telegraf介绍
Telegraf是TICK Stack的一部分，是一个插件驱动的服务器代理，用于收集和报告指标。 Telegraf集成了直接从其运行的容器和系统中提取各种指标，事件和日志，从第三方API提取指标，甚至通过StatsD和Kafka消费者服务监听指标。它还具有输出插件，可将指标发送到各种其他数据存储，服务和消息队列，包括InfluxDB，Graphite，OpenTSDB，Datadog，Librato，Kafka，MQTT，NSQ等等。

![](https://2bjee8bvp8y263sjpl3xui1a-wpengine.netdna-ssl.com/wp-content/uploads/Tick-Stack-Telegraf-2.png)

### telegraf部署
```
$ wget https://dl.influxdata.com/telegraf/releases/telegraf-1.7.3_linux_amd64.tar.gz
$ tar xf telegraf-1.7.3_linux_amd64.tar.gz
```

### telegraf配置及优化
```
[global_tags]
[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = ""
  debug = false
  quiet = false
  logfile = ""
  hostname = "192.168.1.1"
  omit_hostname = false

[[outputs.influxdb]]
  urls = ["http://192.168.1.1:8086"]
  database = "telegraf"
  precision = "s"
  timeout = "5s"
  username = "monitor"
  password = "EMZ1LdVUu0pMXbkaoPzpCO9S1J2bqvPi"

[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false

[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs"]

[[inputs.diskio]]

[[inputs.kernel]]

[[inputs.mem]]

[[inputs.processes]]

[[inputs.swap]]

[[inputs.system]]

[[inputs.netstat]]

[[inputs.net]]
  interfaces = ["eth0"]

#[[inputs.zookeeper]]
# servers = ["192.168.1.1:2181"]
```

### telegraf启动
```
$ nohup /usr/local/telegraf/usr/bin/telegraf --config /usr/local/telegraf/etc/telegraf/telegraf.conf & 
```

## infludb介绍
聆听翻译 InfluxDB用作涉及大量带时间戳数据的任何用例的数据存储，包括DevOps监控，日志数据，应用程序指标，物联网传感器数据和实时分析。通过配置InfluxDB来保存机器上的空间，以便将数据保留一段定义的时间，自动使系统中不需要的数据到期和删除。 InfluxDB还提供类似SQL的查询语言，用于与数据交互。

### infludb部署
```
$ wget https://dl.influxdata.com/influxdb/releases/influxdb-1.6.1_linux_amd64.tar.gz
$ tar xvfz influxdb-1.6.1_linux_amd64.tar.gz
```
### influbd启动
```
$ nohup /usr/local/influxdb/usr/bin/influxd &
```

### 创建数据库及配置权限
```
$ influx
$ create database telegraf

# 显示用户
$ SHOW USERS

# 创建用户
$ CREATE USER "username" WITH PASSWORD 'password'

# 创建管理员权限的用户
$ CREATE USER "username" WITH PASSWORD 'password' WITH ALL PRIVILEGES

# 删除用户
$ DROP USER "username"
```

### 数据保存策略

查看当前数据库的Retention Policies
```
$ SHOW RETENTION POLICIES ON "testDB"
```

创建新的Retention Policies
```
$ CREATE RETENTION POLICY "rp_name" ON "db_name" DURATION 30d REPLICATION 1 DEFAULT
```

其中：
* 1. rp_name：策略名
* 2. db_name：具体的数据库名
* 3. 30d：保存30天，30天之前的数据将被删除,它具有各种时间参数，比如：h（小时），w（星期）
* 4. REPLICATION 1：副本个数，这里填1就可以了
* 5. DEFAULT 设为默认的策略

修改Retention Policies
```
$ ALTER RETENTION POLICY "rp_name" ON "db_name" DURATION 3w DEFAULT
```

删除Retention Policies
```
$ DROP RETENTION POLICY "rp_name" ON "db_name"
```

### 最终效果
![](https://owelinux.github.io/images/2018-08-24-article19-linux-telegraf-infludb/telegraf-Infludb.png)

模板采用：[https://grafana.com/dashboards/914](https://grafana.com/dashboards/914)

## 参考
> * [https://www.influxdata.com/time-series-platform/telegraf/](https://www.influxdata.com/time-series-platform/telegraf/)
> * [https://docs.influxdata.com/chronograf/v1.6/introduction/getting-started/](https://docs.influxdata.com/chronograf/v1.6/introduction/getting-started/)
> * [https://kiswo.com/article/1020](https://kiswo.com/article/1020)
> * [https://www.linuxdaxue.com/series/influxdb-series/](https://www.linuxdaxue.com/series/influxdb-series/)