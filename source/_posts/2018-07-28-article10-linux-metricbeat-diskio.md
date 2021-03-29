---
layout: post
title: metricbeat部署及监控linux系统指标汇总
author: owelinux
categories: linux
tags: linux 监控 metricbeat
excerpt: metricbeat部署及监控linux系统指标汇总.
mathjax: true
abbrlink: a73b344
date: 2018-07-30 11:09:54
---

* content
{:toc}

# Metricbeat
## 轻量型指标采集器
用于从系统和服务收集指标。从 CPU 到内存，从 Redis 到 Nginx，Metricbeat 能够以一种轻量型的方式，输送各种系统和服务统计数据。

## 系统级监控，更简洁
将 Metricbeat 部署到您所有的 Linux、Windows 和 Mac 主机，并将它连接到 Elasticsearch 就大功告成啦：您可以获取系统级的 CPU 使用率、内存、文件系统、磁盘 IO 和网络 IO 统计数据，以及获得如同系统上 top 命令类似的各个进程的统计数据。探索[在线演示](https://demo.elastic.co/app/kibana#/dashboard/Metricbeat-system-overview?_g=()&_a=(description:'',filters:!(),fullScreenMode:!f,options:(darkTheme:!f,useMargins:!f),panels:!((gridData:(h:5,i:'9',w:48,x:0,y:0),id:System-Navigation,panelIndex:'9',type:visualization,version:'6.3.1'),(embeddableConfig:(vis:(defaultColors:('0%20-%20100':'rgb(0,104,55)'))),gridData:(h:10,i:'11',w:8,x:0,y:5),id:c6f2ffd0-4d17-11e7-a196-69b9a7a020a9,panelIndex:'11',type:visualization,version:'6.3.1'),(embeddableConfig:(vis:(defaultColors:('0%20-%20100':'rgb(0,104,55)'))),gridData:(h:25,i:'12',w:24,x:24,y:15),id:fe064790-1b1f-11e7-bec4-a5e9ec5cab8b,panelIndex:'12',type:visualization,version:'6.3.1'),(gridData:(h:25,i:'13',w:24,x:0,y:15),id:'855899e0-1b1c-11e7-b09e-037021c4f8df',panelIndex:'13',type:visualization,version:'6.3.1'),(embeddableConfig:(vis:(defaultColors:('0%25%20-%2015%25':'rgb(247,252,245)','15%25%20-%2030%25':'rgb(199,233,192)','30%25%20-%2045%25':'rgb(116,196,118)','45%25%20-%2060%25':'rgb(35,139,69)'))),gridData:(h:30,i:'14',w:48,x:0,y:40),id:'7cdb1330-4d1a-11e7-a196-69b9a7a020a9',panelIndex:'14',type:visualization,version:'6.3.1'),(embeddableConfig:(vis:(defaultColors:('0%20-%20100':'rgb(0,104,55)'))),gridData:(h:10,i:'16',w:8,x:32,y:5),id:'522ee670-1b92-11e7-bec4-a5e9ec5cab8b',panelIndex:'16',type:visualization,version:'6.3.1'),(gridData:(h:10,i:'17',w:8,x:40,y:5),id:'1aae9140-1b93-11e7-8ada-3df93aab833e',panelIndex:'17',type:visualization,version:'6.3.1'),(gridData:(h:10,i:'18',w:8,x:24,y:5),id:'825fdb80-4d1d-11e7-b5f2-2b7c1895bf32',panelIndex:'18',type:visualization,version:'6.3.1'),(gridData:(h:10,i:'19',w:8,x:16,y:5),id:d3166e80-1b91-11e7-bec4-a5e9ec5cab8b,panelIndex:'19',type:visualization,version:'6.3.1'),(gridData:(h:10,i:'20',w:8,x:8,y:5),id:'83e12df0-1b91-11e7-bec4-a5e9ec5cab8b',panelIndex:'20',type:visualization,version:'6.3.1')),query:(language:lucene,query:(query_string:(analyze_wildcard:!t,default_field:'*',query:'*'))),timeRestore:!f,title:'%5BMetricbeat%20System%5D%20Overview',viewMode:view))。

## 安装 Metricbeat
```
wget https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-6.3.2-linux-x86_64.tar.gz
tar -zxvf metricbeat-6.3.2-linux-x86_64.tar.gz
mv metricbeat-6.3.2-linux-x86_64 metricbeat
```

## 配置 Metricbeat
```
metricbeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false
setup.template.settings:
  index.number_of_shards: 1
  index.codec: best_compression
setup.kibana:
  host: "localhost:5602"
output.elasticsearch:
  hosts: ["192.168.1.1:29200"]
## 开启sytem监控
$ cat modules.d/system.yml 
- module: system
  period: 10s
  metricsets:
    - cpu
    - load
    - memory
    - network
    - process
    - process_summary
    #- core
    - diskio
    - socket
  processes: ['.*']
  process.include_top_n:
    by_cpu: 5      # include top 5 processes by CPU
    by_memory: 5   # include top 5 processes by memory

- module: system
  period: 1m
  metricsets:
    - filesystem
    #- fsstat
  processors:
  - drop_event.when.regexp:
      system.filesystem.mount_point: '^/(sys|cgroup|proc|dev|etc|host|lib)($|/)'

- module: system
  period: 1m
  metricsets:
    - uptime
```

## 启动kibana、es、metricbeat
```
/usr/local/metricbeat/metricbeat -e -c /usr/local/metricbeat/metricbeat.yml
```
## 使用Granfan可视化 
### 系统指标采集汇总

| 指标类型 | 指标    |  指标含义  |
| -------- | ---------------------:| :-------------------------: |
| cpu      | system.cpu.total.pct | cpu使用总的百分比 |
| cpu      | system.cpu.cores | cpu核数 |
| cpu      | system.cpu.iowait.pct | 等待输入输出的CPU时间百分比 |
| cpu      | system.cpu.user.pct | 用户空间占用CPU百分比 |
| cpu      | system.cpu.system.pct | 内核空间占用CPU百分比 |
| cpu      | system.cpu.nice.pct | 进程改变占用CPU百分比|
| cpu      | system.cpu.idle.pct | 空闲CPU百分比 |
| memory   | system.memory.used.bytes | 内存使用大小 |
| memory   | system.memory.used.pct | 内存使用百分比 |
| memory   | system.memory.free | 内存剩余大小 |
| memory   | system.memory.total | 内存总大小 |
| memory   | system.memory.swap.used.pct | swap内存使用百分比 |
| memory   | system.memory.swap.used.bytes | swap内存使用大小 |
| memory   | system.memory.swap.free | swap剩余内存 |
| memory   | system.memory.swap.total | swap内存总大小 |
| network  | system.network.name | 网卡名 |
| network  | system.network.in.packets | 网卡入口包数量 |
| network  | system.network.in.errors | 网卡入口错误包数量 |
| network  | system.network.in.dropped | 网卡入口拒收包数量 |
| network  | system.network.in.bytes | 网卡入口包大小 |
| network  | system.network.out.packets	| 网卡出口网卡包数量 |
| network  | system.network.out.bytes | 网卡出口包大小 |
| network  | system.network.out.errors | 网卡出口错误包数量 |
| network  | system.network.out.dropped | 网卡出口拒收包数量 |	
| load  | system.load.1 | 1分钟的系统平均负载 |
| load  | system.load.5 | 5分钟的系统平均负载 |
| load  | system.load.15 | 15分钟的系统平均负载 |
| process_summary | system.process.summary.stopped | 停止进程 | 
| process_summary | system.process.summary.zombie | 僵尸进程 |
| process_summary | system.process.summary.unknown | 无状态进程 |
| process_summary | system.process.summary.total | 进程总数 |
| process_summary | system.process.summary.sleeping | 休眠进程 |
| process_summary | system.process.summary.running | 运行进程 |
| uptime | system.uptime.duration.ms | 系统运行时间 |
| socket | system.socket.local.ip | 本机ip |
| diskio | system.diskio.iostat.read.per_sec.bytes | 每秒从设备（drive expressed）读取的数据量(kB_read/s) |
| diskio | system.diskio.iostat.write.per_sec.bytes | 每秒向设备（drive expressed）写入的数据量(kB_wrtn/s) | 
| diskio | system.diskio.iostat.read.request.per_sec | 每秒读取的扇区数(rsec/s) |
| diskio | system.diskio.iostat.write.request.per_sec | 每秒写入的扇区数(wsec/s)	 |
| diskio | system.diskio.iostat.read.request.merges_per_sec | 每秒这个设备相关的读取请求有多少被Merge(rrqm/s) |
| diskio | system.diskio.iostat.write.request.merges_per_sec | 每秒这个设备相关的写入请求有多少被Merge(wrqm/s) |
| diskio | system.diskio.iostat.await | 每一个IO请求的处理的平均时间（单位是微秒) |
| diskio | system.diskio.read.bytes  | 读取的总数据量(kB_read) |
| diskio | system.diskio.write.bytes | 写入的总数量数据量(kB_wrtn) | 
| filesystem | system.filesystem.device_name | 文件系统设备名 | 
| filesystem | system.filesystem.free | 磁盘剩余空间 |
| filesystem | system.filesystem.mount_point | 磁盘挂载分区 |
| filesystem | system.filesystem.total | 磁盘总大小 |
| filesystem | system.filesystem.used.pct | 磁盘使用率 |
| filesystem | system.filesystem.used.bytes | 磁盘使用大小 |
| filesystem | system.filesystem.used.bytes | 磁盘使用大小 |

### 增加主机分组，并在grafana引用
```
[root@bj-ops3 metricbeat]# grep -Ev '#|^$' metricbeat.yml 
metricbeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false
setup.template.settings:
  index.number_of_shards: 1
  index.codec: best_compression
name: 192.168.1.1
fields:
  group: OPS
setup.kibana:
  host: "localhost:5602"
output.elasticsearch:
  hosts: ["192.168.1.1:29200"]
```
## grafana配置
![](https://owelinux.github.io/images/2018-07-28-article10-linux-metricbeat-diskio/mericbeat_group.png)

### 绘图模板
[system-metrics](https://grafana.com/dashboards/7225)
### 效果如下图
![](https://owelinux.github.io/images/2018-07-28-article10-linux-metricbeat-diskio/system_merticbeat.png)

## 参考：
> * [https://www.elastic.co/cn/products/beats/metricbeat](https://www.elastic.co/cn/products/beats/metricbeat)
> * [https://www.elastic.co/guide/en/beats/metricbeat/current/exported-fields-system.html](https://www.elastic.co/guide/en/beats/metricbeat/current/exported-fields-system.html)
