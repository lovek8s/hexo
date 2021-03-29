---
layout: post
title: CDH 5.15安装文档
author: owelinux
categories: linux
tags: CDH
excerpt: CDH 5.15安装文档
mathjax: true
abbrlink: ddb5881c
date: 2018-09-04 16:02:54
---

* content
{:toc}

# CDH 5.15安装文档

在测试开发环境，初始化一个数据库，通常选择yum来安装，本文将常见的mysqlyum源及安装方式梳理

## 系统环境
操作系统：centos6.8

数据库：mysql5.7，编码utf-8

java：jdk1.8


## 安装包下载

* cloudera-manager-el6-cm5.15.1_x86_64.tar.gz

* CDH-5.15.1-1.cdh5.15.1.p0.4-el6.parcel

* CDH-5.15.1-1.cdh5.15.1.p0.4-el6.parcel.sha1

* manifest.json

```
wget https://archive.cloudera.com/cm5/cm/5/cloudera-manager-el6-cm5.15.1_x86_64.tar.gz

wget https://archive.cloudera.com/cdh5/parcels/5.15.1/CDH-5.15.1-1.cdh5.15.1.p0.4-el6.parcel

wget https://archive.cloudera.com/cdh5/parcels/5.15.1/CDH-5.15.1-1.cdh5.15.1.p0.4-el6.parcel.sha1

wget https://archive.cloudera.com/cdh5/parcels/5.15.1/manifest.json
```

CHD5 相关的 Parcel 包放到主节点的/opt/cloudera/parcel-repo/目录中
CDH-5.15.1-1.cdh5.15.1.p0.4-el6.parcel.sha1 重命名为 CDH-5.15.1-1.cdh5.15.1.p0.4-el6.parcel.sha

这点必须注意，否则，系统会重新下载 CDH-5.15.1-1.cdh5.15.1.p0.4-el6.parcel 文件

本文采用离线安装方式，在线安装方式请参照官方文


主机名	ip地址	安装服务
node1 (Master)	172.22.145.177	jdk、cloudera-manager、MySql

node2 (Agents)	172.22.145.178	jdk、cloudera-manager

node3 (Agents)	172.22.145.179	jdk、cloudera-manager

## 系统环境搭建

### 配置系统环境
```
echo 0 > /proc/sys/vm/swappiness

echo never > /sys/kernel/mm/transparent_hugepage/defrag echo never > /sys/kernel/mm/transparent_hugepage/enabled
```


### 配置hostname
```
vim /etc/sysconfig/network
hostname node1
```

### 配置hosts
```
vim /etc/hosts
172.22.145.177 node1
172.22.145.178 node2
172.22.145.179 node3
```

### 配置免密码登陆
```
vim /etc/ssh/sshd_config
RSAAuthentication yes      #开启私钥验证PubkeyAuthentication yes   #开启公钥验证
service sshd reload

生成公钥，私钥
ssh-keygen -t rsa -P ''

每个节点的公钥放入认证文件
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

以上步骤每台机器需要配置，配置完成严重免密登陆
```
### 关闭防火墙和selinux
```
service iptables stop
setenforce 0
vi /etc/selinux/config
将 SELINUX=enforcing 改为 SELINUX=disabled
```

### 安装jdk环境
```
wget http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/jdk-8u181-linux-x64.tar.gz
tar -zxvf jdk-8u181-linux-x64.tar.gz -C /usr
vim /etc/profile

JAVA_HOME=/usr/jdk1.8.0_51
PATH=$JAVA_HOME/bin:$PATH
CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export JAVA_HOME
export PATH
export CLASSPATH
```

### 配置ntp时间同步
```
ntpdate -d 182.92.12.11
```

## mysql安装及配置
```
# yum安装mysql5.7
yum install -y http://repo.mysql.com//mysql57-community-release-el6-8.noarch.rpm
yum install -y mysql-community-server
groupadd mysql
useradd mysql -g mysql

# 启动数据库
service mysqld start
# 查看密码
cat  /var/log/mysqld.log |  grep "password" | grep "generated" 
# 登陆数据库
mysql-uroot -p
# 修改密码
SET PASSWORD = PASSWORD('your new password');
grant all privileges on *.*  to  'root'@'%'  identified by 'your new password'  with grant option;
flush privileges;
exit;
```
### MySQL新建数据库
```
# amon
create database amon DEFAULT CHARACTER SET utf8; 
grant all on amon.* TO 'amon'@'%' IDENTIFIED BY 'amon';

#hive
create database hive DEFAULT CHARACTER SET utf8; 
grant all on hive.* TO 'hive'@'%' IDENTIFIED BY 'hive';

#oozie
create database oozie DEFAULT CHARACTER SET utf8; 
grant all on oozie.* TO 'oozie'@'%' IDENTIFIED BY 'oozie';
```

## 安装依赖包
```
yum -y install chkconfig bind-utils psmisc libxslt zlib sqlite cyrus-sasl-plain cyrus-sasl-gssapi fuse portmap fuse-libs redhat-lsb
```

## cloudera manager Server & Agent 安装

### 安装 CM Server & Agent

在所有节点，创建/opt/cloudera-manager
```
mkdir /opt/cloudera-manager
cd /opt/
tar -zxvf cloudera-manager-el6-cm5.15.1_x86_64.tar.gz -C /opt/cloudera-manager
```

### 创建用户(所有节点)
```
useradd --system --home=/opt/cloudera-manager/cm-5.15.1/run/cloudera-scm-server/ --no-create-home --shell=/bin/false --comment "Cloudera SCM User" cloudera-scm
```

### 配置CM Agent
修改 node1 节点
```
vi /opt/cloudera-manager/cm-5.15.1/etc/cloudera-scm-agent/config.ini
将server_host改为为主节点的主机名。
在node1 操作将 node1 节点修改后的 (复制到所有节点)
```
### 配置CM Server的数据库
在主节点 node1 初始化CM5的数据库：

下载 mysql 驱动包

地址：[https://downloads.mysql.com/archives/c-j/](https://downloads.mysql.com/archives/c-j/)

```
cd /opt/cloudera-manager/cm-5.15.1/share/cmf/lib
wget https://cdn.mysql.com/archives/mysql-connector-java-5.1/mysql-connector-java-5.1.46.tar.gz
tar -zxvf mysql-connector-java-5.1.46.tar.gz && mv mysql-connector-java-5.1.46/mysql-connector-java-5.1.46.jar . && rm -rf mysql-connector-java-5.1.46.tar.gz mysql-connector-java-5.1.46
```

启动MySQL服务
```
service mysql.server start
cd /opt/cloudera-manager/cm-5.15.1/share/cmf/schema/
./scm_prepare_database.sh mysql cm -h master -uroot -proot --scm-host master scm scm scm  

以下信息为正常：
[                          main] DbCommandExecutor              INFO  Successfully connected to database.
All done, your SCM database is configured correctly!
```
### 创建Parcel目录

Manager 节点创建目录/opt/cloudera/parcel-repo
```
mkdir -p /opt/cloudera/parcel-repo
chown cloudera-scm:cloudera-scm -R /opt/cloudera/parcel-repo
cd /opt/cloudera/parcel-repo
mv CDH-5.15.0-1.cdh5.15.0.p0.21-el6.parcel.sha1  CDH-5.15.0-1.cdh5.15.0.p0.21-el6.parcel.sha
mv /opt/manifest.json /opt/CDH-5.15.1-1.cdh5.15.1.p0.4-el6.parcel .
```

Agent 节点创建目录/opt/cloudera/parcels，执行：
```
mkdir -p /opt/cloudera/parcels
chown cloudera-scm:cloudera-scm -R /opt/cloudera/parcels
```

### 启动 CM Manager&Agent 服务

在 node1 (master) 执行：
Server
```
/opt/cloudera-manager/cm-5.15.1/etc/init.d/cloudera-scm-server start
```

在 node2-7 (Agents) 执行：
Agents
```
/opt/cloudera-manager/cm-5.15.1/etc/init.d/cloudera-scm-agent start
```
访问 http://Master:7180 若可以访问（用户名、密码：admin），则安装成功。

Manager 启动成功需要等待一段时间，过程中会在数据库中创建对应的表需要耗费一些时间。

## CDH5 安装
CM Manager && Agent 成功启动后，登录前端页面进行 CDH 安装配置。


## 参考
*  [https://yq.aliyun.com/articles/341408](https://yq.aliyun.com/articles/341408)