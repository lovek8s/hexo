---
title: 运维必须熟悉的工具汇总
top: false
cover: false
toc: true
mathjax: true
tags:
  - 运维工具
categories:
  - linux
abbrlink: f25fecdf
date: 2018-07-19 10:14:54
password:
summary:
---

- 操作系统：Centos※, Ubuntu, Redhat※, suse，Freebsd
- 网站服务：Openresry(Nginx)※, Apache※, Lighttpd, Php※, Tomcat※, Resin
- 数据库：MySQL※, MariaDB，PostgreSQL, InfluxDB, Oracle
- DB中间件：MyCat, Amoeba, MySQL-proxy
- 代理相关：Lvs+Keepalived, Haproxy(七层), Nginx（四层+七层）, Apache, Heartbeat, Squid（此行都是※）
- 网站缓存：Squid※, Nginx※, Varnish
- NOSQL库：Memcached※,Memcachedb,TokyoTyrant※,MongoDB※,Cassandra※,Redis※,CouchDB, Codis, Pika
- 存储相关：Nfs※, Moosefs(mfs)※, Hadoop※, glusterfs※, Lustre, FastDFS
- 版本管理：svn※, git※
- 监控报警：Nagios※, Cacti※, Zabbix※, Munin, Hyperic, Mrtg, Graphite, smokping, Prometheus， Grafana
- 域名解析：Bind※, Powerdns, Dnsmasq※
- 同步软件:Rsync※,Inotify※,Sersync※,Drbd※,Csync2, Union,Lsyncd,Scp※
- 批量管理：Ssh+Rsync+Sersync※, Saltstack※, Expect※, Puppet※, Ansible, Cfengine
- 虚拟化：kvm※, Xen※, Docker, K8s
- 云计算：Openstack※, Docker, Cloudstack
- 内网软件：Iptables※, Zebra※, Iftraf, Ntop※, Tc※, Iftop, Traceroute, Jstack, Vmstat, Lsof, Sar, Iftop
- 邮件软件：Qmail, Posfix※, Sendmail
- 远程拨号：Openvpn※, Pptp, Openswan※, Ipip※
- 统一认证：Openldap(可结合微软活动目录)※
- 队列工具：ActiveMQ, RabbitMQ※, Metaq, MemcacheQ, Zeromq
- 打包发布：Mvn※, Ants※, Jenkins※, Svn
- 测试软件：Ab,Smokeping, Siege, JMeter, Webbench, LoadRunner, http_load（都是※）
- 日志相关：Syslog, Rsyslog, Awstats, Flume logstash scribe Kafka, Storm，ELK(Elasticsearch+Logstash+Kibana)
- DB代理：Mysql-proxy, Amoeba（更多还是程序实现读写分离）
- 搜索软件：Sphinx,Xapian（大公司会自己开发类似百度的小规模内部搜索引擎）

### 提示：
- 以上所有软件参照老男孩老师整理归档，另外更新了最近几年工作中用的最多的。
- 带※的为最近几年用的比较多，可信任使用的。
- 需要了解具体，直接Google官方文档即可。
- 以上软件掌握带*的就行，万变不离其宗，做到举一反三。