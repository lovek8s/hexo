---
layout: post
title: prometheus监控之snmp流量采集
author: owelinux
categories: linux
tags: prometheus snmp 监控
excerpt: prometheus监控之snmp流量采集.
mathjax: true
abbrlink: 58e5c53a
date: 2018-07-25 19:20:54
---

* content
{:toc}


## 下载并运行prometheus
```
wget https://github.com/prometheus/prometheus/releases/download/v2.3.2/prometheus-2.3.2.linux-amd64.tar.gz
tar -zxvf prometheus-2.3.2.linux-amd64.tar.gz
mv prometheus-2.3.2.linux-amd64 prometheus
```

## 配置prometheus监控本身
```
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: 'codelab-monitor'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s

    static_configs:
      - targets: ['localhost:9090']
```

### 启动prometheus
```
./prometheus --config.file=prometheus.yml
```
### 打开浏览器验证
 http://localhost:9090/graph

## 配置写数据到es
### 下载prometheusbeat
```
mkdir -p ${GOPATH}/github.com/infonova/prometheusbeat
cd ${GOPATH}/github.com/infonova/prometheusbeat
git clone https://github.com/infonova/prometheusbeat
make package
./prometheusbeat -c prometheusbeat.yml -e -d "*"

# 查看服务是否启动
ss -lntp | grep 8088
LISTEN     0      65535                     *:8088                     *:*      users:(("prometheusbeat",29237,6))
```
### 配置prometheus输入es
```
#remote_write:
#  - url: "http://localhost:9201/write"
remote_write:
  - url: "http://localhost:8088/prometheus"
```
## 监控snmp

### 安装snmp服务
```
yum -y install net-snmp*
防火墙
#prometheus
-A INPUT -s 192.168.1.0/23 -p tcp -m state --state NEW -m tcp --dport 9100 -j ACCEPT
-A INPUT -s 192.168.1.0/23 -p tcp -m state --state NEW -m tcp --dport 9116 -j ACCEPT
-A INPUT -s 192.168.1.0/23 -p udp -m state --state NEW -m udp --dport 161 -j ACCEPT
```

### 安装snmp插件
```
wget https://github.com/prometheus/snmp_exporter/releases/download/v0.11.0/snmp_exporter-0.11.0.linux-amd64.tar.gz
tar -zxvf snmp_exporter-0.11.0.linux-amd64.tar.gz
./snmp_exporter 
```
### 配置prometheus的snmp
```
  - job_name: 'snmp'
    static_configs:
      - targets:
        - 192.168.1.1
        labels:
          tag: aliyun-hb2-10
    metrics_path: /snmp
    params:
      module: [if_mib]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 191.168.1.1:9116
```
### 验证snmp监控数据
```
curl 'http://localhost:9116/snmp?target=192.168.1.1' 
```
### snmp指标
针对普通网络设备的端口，MIB的相关定义是Interface组，主要管理如下信息:
ifIndex                 端口索引号
ifDescr                 端口描述
ifType                  端口类型
ifMtu                   最大传输包字节数
ifSpeed                 端口速度
ifPhysAddress           物理地址
ifOperStatus            操作状态
ifLastChange            上次状态更新时间
*ifInOctets             输入字节数
*ifInUcastPkts          输入非广播包数
*ifInNUcastPkts         输入广播包数
*ifInDiscards           输入包丢弃数
*ifInErrors             输入包错误数
*ifInUnknownProtos      输入未知协议包数
*ifOutOctets            输出字节数
*ifOutUcastPkts         输出非广播包数
*ifOutNUcastPkts        输出广播包数
*ifOutDiscards          输出包丢弃数
*ifOutErrors            输出包错误数
ifOutQLen               输出队长
其中，*号标识的是与网络流量有关的信息。
1、获取CISCO2900端口1的上行总流量
          snmpwalk -v 1 -c public 192.168.1.254 IF-MIB::ifInOctets.1
    返回结果
         IF-MIB::ifInOctets.1 = Counter32: 4861881
2、五秒后再获取一次
         snmpwalk -v 1 -c public 192.168.1.254 IF-MIB::ifInOctets.1
    返回结果
     IF-MIB::ifInOctets.1 = Counter32: 4870486
3、计算结果
 （后值48704863-前值4861881）/ 5＝1721b/s  （应该是BYTE）

### 配置snmp告警指标
```
cat rules/traffic.yml 
groups:
  - name: traffic
    rules:
    - record: traffic_out_bps 
      expr: (ifHCOutOctets - (ifHCOutOctets offset 1m)) *8/60
      #expr: sum by (tag, job, instance, ifIndex) ((ifHCOutOctets - (ifHCOutOctets offset 1m)) *8/60)
      #labels:
      #  instance: "{{ $labels.instance }}"
      #  ifIndex: "{{ $labels.ifIndex }}"
    - record: traffic_in_bps
      expr: (ifHCInOctets - (ifHCInOctets offset 1m)) *8/60

    ### alert
    - alert: BeijingProxyTrafficOutProblem
      expr: (sum by(tag) (avg_over_time(traffic_out_bps{ifIndex=~"7|9", tag=~"beijing.+"}[5m]) /1024/1024)) >= 200
      for: 2m
      labels:
        level: CRITICAL
      annotations:
        message: "traffic out has problem (network: {{ $labels.tag }}, current: {{ $value }}Mbps)"
    - alert: BeijingProxyTrafficInProblem
      expr: (sum by(tag) (avg_over_time(traffic_in_bps{ifIndex=~"7|9", tag=~"beijing.+"}[5m]) /1024/1024)) >= 500
      for: 2m
      labels:
        level: CRITICAL
      annotations:
        message: "traffic in has problem (network: {{ $labels.tag }}, current: {{ $value }}Mbps)"

    - alert: BeijingProxyWanTrafficOutProblem
      expr: (sum by(tag) (avg_over_time(traffic_out_bps{ifIndex=~"6|8", tag=~"beijing.+"}[5m]) /1024/1024)) >= 30
      for: 2m
      labels:
        level: CRITICAL
      annotations:
        message: "traffic out bond0 has problem (network: {{ $labels.tag }}, current: {{ $value }}Mbps)"
    - alert: BeijingProxyWanTrafficInProblem
      expr: (sum by(tag) (avg_over_time(traffic_in_bps{ifIndex=~"6|8", tag=~"beijing.+"}[5m]) /1024/1024)) >= 30
      for: 2m
      labels:
        level: CRITICAL
      annotations:
        message: "traffic in bond0 has problem (network: {{ $labels.tag }}, current: {{ $value }}Mbps)"

    - alert: AliyunProxyTrafficOutProblem
      expr: (sum by(tag) (avg_over_time(traffic_out_bps{ifIndex="2", tag=~"aliyun.+"}[5m]) /1024/1024)) > 200
      for: 2m
      labels:
        level: CRITICAL
      annotations:
        message: "traffic out has problem (network: {{ $labels.tag }}, current: {{ $value }}Mbps)"
    - alert: AliyunProxyTrafficInProblem
      expr: (sum by(tag) (avg_over_time(traffic_in_bps{ifIndex="2", tag=~"aliyun.+"}[5m]) /1024/1024)) > 200
      for: 2m
      labels:
        level: CRITICAL
      annotations:
        message: "traffic in has problem (network: {{ $labels.tag }}, current: {{ $value }}Mbps)"

```
### snmp 传输到granfan

### 参考
https://github.com/infonova/prometheusbeat
https://prometheus.io
https://github.com/prometheus/snmp_exporter
https://blog.csdn.net/huithe/article/details/7588673