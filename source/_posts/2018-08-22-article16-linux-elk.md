---
layout: post
title: ELK(6.x版本)日志分析平台+Granfan可视化
author: owelinux
categories: linux
tags: linux  ELK
excerpt: ELK日志分析平台+Granfan可视化
mathjax: true
abbrlink: c7d22367
date: 2018-08-22 18:41:54
---

* content
{:toc}

# ELK(6.x版本)日志分析平台+Granfan可视化

## 系统环境准备
```
# 系统版本及内核信息
[root@test03 config]# uname  -a
Linux test03 3.10.0-862.el7.x86_64 #1 SMP Fri Apr 20 16:44:24 UTC 2018 x86_64 x86_64 x86_64 GNU/Linux

# 配置java1.8版本
[root@test03 local]# wget jdk-8u171-linux-x64.tar.gz
[root@test03 local]# tar -zxvf jdk-8u171-linux-x64.tar.gz -C /usr/local/

echo "JAVA_HOME=/usr/local/jdk1.8.0_171 >> /etc/profile
echo "CLASSPATH=.:\$JAVA_HOME/lib/tools.jar:\$JAVA_HOME/lib/dt.jar" >> /etc/profile 
echo "PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile 
source /etc/profile
```

## 采集方案（本教程采用第三种方案）

### 方案一 
log_files -> filebeat  -->  logstash -> - elasticsearch -> kibana

### 方案二
log_files ->  filebeat -> logstash  -->  redis -> - logstash -> - elasticsearch -> kibana

### 方案三
log_files ->  filebeat -> elasticsearch-> kibana

## 配置nginx日志格式log_format
```
        log_format  main  '$host $remote_addr - $remote_user [$time_local] "$request" '
                '$status $body_bytes_sent $upstream_response_time "$http_referer" '
                '"$http_user_agent" "$http_x_forwarded_for" "$uid_got" "$uid_set" "$http_x_tencent_ua" "$upstream_addr" "$upstream_http_x_cached_from" "$upstream_http_cache_control"';
```

## 配置filebeat（根据官网改造支持nginx日志格式）
下载软件：
```
[root@test03 local]# wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.3.2-linux-x86_64.tar.gz
[root@test03 local]# tar -zxvf filebeat-6.3.2-linux-x86_64.tar.gz
```
配置filebeat：
```
[root@WEB3 include]# cat /etc/filebeat/config.yml  | grep -Ev  '#|^$'
filebeat.prospectors:
- input_type: log
  paths:
    - /var/log/nginx/*access.log
  grok_pattern: '%{USERNAME:domain} %{IPV4:client_ip} (.*) \[%{HTTPDATE:timestamp}\] (.*) %{URIPATH:path}(.*)\" (?:%{INT:response_status}|-) (?:%{INT:response_bytes}|-) (?:%{NUMBER:response_time}|-)'
  ignore_older: 1h
name: 192.168.1.1
output.elasticsearch:
  enabled: true
  hosts: ["192.168.1.1:9200"]
  index: "beijing-web-%{+yyyy.MM.dd}"
  template.enabled: false
  template.versions.2x.enabled: false
  template.versions.6x.enabled: false
output.file:
  enabled: true
  path: /tmp/filebeat
path.config: /etc/filebeat
path.data: /tmp/filebeat/data
path.logs: /var/log
logging.to_files: true
logging.files:
  path: /var/log
  name: filebeat
```

## 配置logstash

下载软件：
```
[root@test03 local]# wget https://artifacts.elastic.co/downloads/logstash/logstash-6.3.2.tar.gz
[root@test03 local]# tar -zxvf logstash-6.3.2.tar.gz
```

几种插件的使用：
### 1、grok插件

作用:解析message信息或其他操作

* logstash的grok：    [https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html](https://www.elastic.co/guide/enlogstash/current/plugins-filters-grok.html)

* grok正则测试：[http://grokdebug.herokuapp.com](http://grokdebug.herokuapp.com)

#### nginx日志的正则匹配
```
match => { 
          "message" => "(?<domain>%{IP:ip}|(?:%{NOTSPACE:subsite}\.)?(?<site>[-a-zA-Z0-9]+?).com|%{NOTSPACE:unknown}) %{IPORHOST:dayuip} - (?<user>[a-zA-Z\.\@\-\+_%]+) \[%{HTTPDATE:timestamp}\] \"%{WORD:verb} (?<request_path>(?<biz>\/[^/?]*)%{URIPATH:}?)(?:%{URIPARAM:request_param})? HTTP/%{NUMBER:httpversion}\" %{NUMBER:response} (?:%{NUMBER:bytes}|-) (?:%{BASE10NUM:request_duration}|-) (?:\"(?:%{URI:referrer}|-)\"|%{QS:referrer}) %{QS:agent} \"(?:%{IPORHOST:clientip}(?:[^\"]*)|-)\" %{QS:uidgot} %{QS:uidset} \"(?:[^\" ]* )*(?<upstream>[^ \"]*|-)\""
      }
```
 

#### Java的正则匹配
```
match => {
      "message" => "\[entry\]\[ts\](?<ts>.*)\[/ts\]\[lv\](?<lv>.*)\[/lv\]\[th\](?<th>.*)\[/th\]\[lg\](?<lg>.*)\[/lg\]\[cl\](?<cl>.*)\[/cl\]\[m\](?<m>.*)\[/m\]\[ln\](?<ln>.*)\[/ln\]\[bsid\](?<bsid>.*)\[/bsid\]\[esid\](?<esid>.*)\[/esid\](\[cmid\](?<cmid>.*)\[/cmid\])?\[txt\](?<txt>.*)\[/txt\]\[ex\](?<ex>.*)\[/ex\]\[/entry\]"
}
```
 

#### PHP的正则匹配
```
match => {
        "message" => "\[entry\]\[ts\](?<ts>.*)\[/ts\]\[lv\](?<lv>.*)\[/lv\]\[th\](?<th>.*)\[/th\]\[lg\](?<lg>.*)\[/lg\]\[cl\](?<cl>.*)\[/cl\]\[m\](?<m>.*)\[/m\]\[ln\](?<ln>.*)\[/ln\]\[bsid\](?<bsid>.*)\[/bsid\]\[esid\](?<esid>.*)\[/esid\]\[txt\](?<txt>.*)\[/txt\]\[proj\](?<proj>.*)\[/proj\]\[iid\](?<iid>.*)\[/iid\]\[file\](?<file>.*)\[/file\]\[ex\](?<ex>.*)\[/ex\]\[type\](?<logtype>.*)\[/type\]\[/entry\]"
}
```
 
### 2、date 插件

作用：将解析到的时间作为展示在kibana的time

```   
filter {
        date {
               match => [ "logdate", "MMM dd yyyy HH:mm:ss" ]
             }
      }
```

### logstash配置优化
```
input {
    beats {
        port => "5043"
    }
}
filter {
    grok {
        match => { "message" => "^(?<domain>%{IP:ip}|(?:%{NOTSPACE:subsite}\.)?(?<site>[-a-zA-Z0-9]+?).com|%{NOTSPACE:unknown}) %{IPORHOST:dayuip} - (?<user>[a-zA-Z\.\@\-\+_%]+) \[%{HTTPDATE:timestamp}\] \"%{WORD:verb} (?<request_path>(?<biz>\/[^/?]*)%{URIPATH:}?)(?:%{URIPARAM:request_param})? HTTP/%{NUMBER:httpversion}\" %{NUMBER:response} (?:%{NUMBER:bytes}|-) (?:%{BASE10NUM:request_duration}|-) (?:\"(?:%{URI:referrer}|-)\"|%{QS:referrer}) %{QS:agent} \"(?:%{IPORHOST:clientip}(?:[^\"]*)|-)\" %{QS:uidgot} %{QS:uidset} %{QS:tencentua} \"(?:[^\" ]* )*(?<upstream>[^ \"]*|-)\" %{QS:cachedfrom} %{QS:cachectrl}"}
    }

   date {
      # Try to pull the timestamp from the 'timestamp' field (parsed above with
      # grok). The apache time format looks like: "18/Aug/2011:05:44:34 -0700"
      locale => "en"
      timezone => "Asia/Shanghai"
      match => [ "timestamp", "dd/MMM/yyyy:HH:mm:ss Z" ]
      add_tag => [ "tsmatch" ]
    }

    if [ip] {
         mutate { add_field => { "site" => "unknown" "subsite" => "ip" } }    
    } else if [unknown] {
         mutate { add_field => { "site" => "unknown" "subsite" => "unknown" } }    
    } else if ! [subsite] {
         mutate { add_field => { "subsite" => "-" } }    
    }

    if ![site] {
         mutate { add_field => { "site" => "unknown" } }    
    }


    mutate {
        convert => { "bytes" => "integer" "request_duration" => "float"}
    }

    if [request_path] =~ "\/count\/a682ab23d4b4c95f84c744b2826419cd" {
        mutate { add_field => {"clkstrm" => "1" } }
    }
    
    if [clientip] =~ "." {
        geoip {
            source => "clientip"
        }
    }
}

output {
    elasticsearch {
        hosts => [ "192.168.1.1:9200" ]
    }

#    http {
#        format=>"json"
#        http_method=>"post"
#        url => "http://localhost:8989/api/v1/metrics"
#    }
}

```

## elasticsearch配置调优

下载软件：
```
[root@test03 local]# wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.3.2.tar.gz
[root@test03 local]# tar -zxvf elasticsearch-6.3.2.tar.gz
```

优化文件描述符：
```
ulimit -n 65536

cat >>/etc/security/limits.conf<<EOF
# allow user 'elasticsearch' mlockall
* soft nofile 65536
* hard nofile 131072
* soft nproc 2048
* hard nproc 4096
EOF

sed -i 's#*          soft    nproc     1024#*          soft    nproc     2048#'g /etc/security/limits.d/90-nproc.conf 

echo "vm.max_map_count=655360" >>/etc/sysctl.conf
sysctl -p

```
创建对应目录：
```
useradd -M -s /sbin/nologin elasticsearch
mkdir -p /var/log/elasticsearch /mnt/elasticsearch /mnt/backups
chown -R elasticsearch. /var/log/elasticsearch /mnt/elasticsearch /mnt/backups /usr/local/elasticsearch

vim ./bin/elasticsearch
ES_JAVA_OPTS="-Xms8g -Xmx8g" 
export JAVA_HOME=/usr/java/jdk1.8.0_171

vim config/elasticsearch.yml
bootstrap.memory_lock: true

swapoff -a
```
es配置文件优化:
```
[root@test03 elasticsearch-6.3.2]# cat config/elasticsearch.yml

cluster.name: bill-eye
node.name: node-test1

node.master: true 
node.data: true 
node.ingest: true

path.logs: /var/log/elasticsearch
path.data: /mnt/elasticsearch
path.repo: /mnt/backups

bootstrap.memory_lock: false
bootstrap.system_call_filter: false

network.host: [_site_, _local_, _ens160_]
network.publish_host: [_site_, _local_, _ens160_]
transport.tcp.port: 9300
http.port: 9200
http.enabled: true
http.cors.enabled: true
http.cors.allow-origin: "*"

discovery.zen.ping_timeout: 60s
discovery.zen.join_timeout: 30s
discovery.zen.fd.ping_timeout: 180s
discovery.zen.fd.ping_retries: 8
discovery.zen.fd.ping_interval: 30s

discovery.zen.ping.unicast.hosts: ["192.168.1.1:9200"]
discovery.zen.minimum_master_nodes: 2
discovery.zen.commit_timeout: 120s

gateway.expected_nodes: 1
gateway.recover_after_time: 5m
gateway.recover_after_nodes: 2

indices.breaker.total.limit: 70%
indices.breaker.fielddata.limit: 60%  
indices.breaker.request.limit: 60%
indices.fielddata.cache.size: 30% 
indices.queries.cache.size: 10%
indices.requests.cache.size: 2%
indices.recovery.max_bytes_per_sec: 20mb
```
启动es：
```
sudo -u elasticsearch ./bin/elasticsearch -d 
```

## 配置kibana    
下载软件：
```
[root@test03 local]# wget https://artifacts.elastic.co/downloads/kibana/kibana-6.3.2-linux-x86_64.tar.gz
[root@test03 local]# tar -zxvf kibana-6.3.2-linux-x86_64.tar.gz
```
配置kibana：
``` 
[root@test03 kibana-6.3.2-linux-x86_64]# grep -Ev '^$|#' config/kibana.yml
server.port: 5601
server.host: "192.168.1.1"
elasticsearch.url: "http://192.168.1.1:9200"
kibana.index: ".kibana"
elasticsearch.pingTimeout: 2500
elasticsearch.requestTimeout: 60000
```
启动kibana：
```
nohup ./bin/kibana &
```

## 配置granfan
下载软件：
```
[root@test03 local]# wget https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-5.2.2.linux-amd64.tar.gz 
[root@test03 local]# tar -zxvf grafana-5.2.2.linux-amd64.tar.gz 
```
启动：
```
[root@test03 grafana-5.2.2]# nohup ./bin/grafana-server  & 
```

## 最终效果
![](https://owelinux.github.io/images/2018-08-22-article16-linux-elk/kibana-filebeat.png)

## 参考
> * [https://www.elastic.co/guide/en/beats/filebeat/current/index.html](https://www.elastic.co/guide/en/beats/filebeat/current/index.html)
> * [https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html](https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html)