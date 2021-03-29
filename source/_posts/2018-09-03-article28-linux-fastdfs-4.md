---
layout: post
title: 文件系统（四）fastdfs部署及使用
author: owelinux
categories: linux
tags: fastdfs
excerpt: 由于业务需求，采用fastdfs作为文件存储，写这篇文章记录点滴
mathjax: true
abbrlink: 60a8f1dd
date: 2018-09-03 11:43:54
---

* content
{:toc}

# fastdfs部署及使用

在之前文章，我们了解到几个类型的文件系统优缺点，本文将详细介绍fastdfs的部署及测试使用

FastDFS is an open source high performance distributed file system (DFS). It's major functions include: file storing, file syncing and file accessing, and design for high capacity and load balance.

FastDFS是一个开源高性能分布式文件系统（DFS）。它的主要功能包括：文件存储，文件同步和文件访问，以及高容量和负载平衡的设计。

## 一、环境准备
### 系统环境
```
[root@sz-145-centos177 ~]# cat /etc/redhat-release 
CentOS release 6.8 (Final)

[root@sz-145-centos177 ~]# uname -a
Linux sz-145-centos177 2.6.32-642.el6.x86_64 #1 SMP Tue May 10 17:27:01 UTC 2016 x86_64 x86_64 x86_64 GNU/Linux
```

### 编译环境
```
yum install git gcc gcc-c++ make automake autoconf libtool pcre pcre-devel zlib zlib-devel openssl-devel -y
```
### 目录
说明 | 位置
------------- | -------------
所有安装包 | /usr/local/
tracker跟踪服务器数据 | /fastdfs/tracker
storage存储服务器数据 | /fastdfs/storage

```
mkdir -p /fastdfs/tracker  #创建跟踪服务器数据目录
mkdir -p /fastdfs/storage  #创建存储服务器数据目录
# 切换到安装目录准备下载安装包
cd /usr/local/ 
```

### 安装libfatscommon
```
git clone https://github.com/happyfish100/libfastcommon.git --depth 1
cd libfastcommon/
./make.sh && ./make.sh install
```

### 安装FastDFS
```
git clone https://github.com/happyfish100/fastdfs.git --depth 1
cd fastdfs/
./make.sh && ./make.sh install
```

#配置文件准备
```
cp /etc/fdfs/tracker.conf.sample /etc/fdfs/tracker.conf
cp /etc/fdfs/storage.conf.sample /etc/fdfs/storage.conf
cp /etc/fdfs/client.conf.sample /etc/fdfs/client.conf #客户端文件，测试用
cp /usr/local/fastdfs/conf/http.conf /etc/fdfs/ #供nginx访问使用
cp /usr/local/fastdfs/conf/mime.types /etc/fdfs/ #供nginx访问使用
```

### 安装fastdfs-nginx-module
```
git clone https://github.com/happyfish100/fastdfs-nginx-module.git --depth 1
cp /usr/local/fastdfs-nginx-module/src/mod_fastdfs.conf /etc/fdfs
安装nginx
wget http://nginx.org/download/nginx-1.12.2.tar.gz
tar -zxvf nginx-1.12.2.tar.gz
cd nginx-1.12.2/
# 修改配置文件，解决报错问题
sed -i 's#ngx_module_incs="/usr/local/include"#ngx_module_incs="/usr/include/fastdfs /usr/local/include/fastcommon/"#'g /usr/local/fastdfs-nginx-module/src/config 
sed -i 's#CORE_INCS="$CORE_INCS /usr/local/include"#CORE_INCS="$CORE_INCS /usr/include/fastdfs /usr/local/include/fastcommon/"#'g /usr/local/fastdfs-nginx-module/src/config 

sed -i 's#(pContext->range_count > 1 && !g_http_params.support_multi_range))#(pContext->range_count > 1))#g' /usr/local/fastdfs-nginx-module/src/common.c | grep '(pContext->range_count > 1))'

# 添加fastdfs-nginx-module模块
./configure --add-module=/usr/local/fastdfs-nginx-module/src/
make && make install
```

### 单机部署
#### tracker配置
```
vim /etc/fdfs/tracker.conf
#需要修改的内容如下
port=22122  # tracker服务器端口（默认22122,一般不修改）
base_path=/fastdfs/tracker  # 存储日志和数据的根目录
#保存后启动
/etc/init.d/fdfs_trackerd start #启动tracker服务
chkconfig fdfs_trackerd on #自启动tracker服务
```
#### storage配置
```
vim /etc/fdfs/storage.conf
#需要修改的内容如下
port=23000  # storage服务端口（默认23000,一般不修改）
base_path=/fastdfs/storage  # 数据和日志文件存储根目录
store_path0=/fastdfs/storage  # 第一个存储目录
tracker_server=192.168.0.xxx:22122  # tracker服务器IP和端口
http.server_port=8888  # http访问文件的端口(默认8888,看情况修改,和nginx中保持一致)
#保存后启动
/etc/init.d/fdfs_storaged start #启动storage服务
chkconfig fdfs_storaged on #自启动storage服务
```
#### 验证storage是否登记到tracker服务器

使用fdfs_monitor /etc/fdfs/storage.conf，运行fdfs_monitor查看storage服务器是否已经登记到tracker服务器。

可以在任一存储节点上使用如下命令查看集群的状态信息
```
fdfs_monitor /etc/fdfs/storage.conf
```
如果出现ip_addr = Active, 则表明storage服务器已经登记到tracker服务器，如下：
```
Storage 1:
        id = 192.168.53.90
        ip_addr = 192.168.53.90 (localhost)  ACTIVE
```
#### 文件上传下载进行测试：

文件上传
```
/usr/bin/fdfs_test /etc/fdfs/client.conf upload /var/log/yum.log
```

文件下载
```
/usr/bin/fdfs_test /etc/fdfs/client.conf download group1 M00/00/00/CnBYbVc8AaOAL78UAAADvvLPPRA782_big.log
```

#### client测试
```
vim /etc/fdfs/client.conf
#需要修改的内容如下
base_path=/fastdfs/tracker
tracker_server=192.168.1.xxx:22122    #tracker IP地址
#保存后测试,返回ID表示成功 eg:group1/M00/00/00/wKgAQ1pysxmAaqhAAA76tz-dVgg.tar.gz
fdfs_upload_file /etc/fdfs/client.conf /usr/local/src/nginx-1.12.2.tar.gz
```
#### 配置nginx访问
```
vim /etc/fdfs/mod_fastdfs.conf
#需要修改的内容如下
base_path=/fastdfs/storage           #保存日志目录
tracker_server=192.168.53.85:22122 
storage_server_port=23000         #storage服务器的端口号
group_name=group1                 #当前服务器的group名
url_have_group_name = true        #文件url中是否有group名
store_path_count=1                #存储路径个数，需要和store_path个数匹配
store_path0=/fastdfs/storage         #存储路径
group_count = 1                   #设置组的个数

#配置nginx.config
vi /usr/local/nginx/conf/nginx.conf
#添加如下配置
server {
    listen       8888;    ## 该端口为storage.conf中的http.server_port相同
    server_name  localhost;
    location ~/group[0-9]/M00 {
		root /fastdfs/storage/data
        ngx_fastdfs_module;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
    }
}
# 测试下载，用外部浏览器访问刚才已传过的nginx安装包,引用返回的ID
http://192.168.0.xxx:8888/group1/M00/00/00/wKgAQ1pysxmAaqhAAA76tz-dVgg.tar.gz
# 弹出下载单机部署全部跑通，否则首先检查防火墙，再检查其他配置。
```

#### 后续扩容
在tracker上安装nginx，并且配置upstream 负载均衡到group组机器

### 报错解决
报错一：
```
make[1]: *** [objs/addon/src/ngx_http_fastdfs_module.o] Error 1
make[1]: Leaving directory `/root/nginx-1.12.2'
make: *** [build] Error 2
```
解决：
```
sed -i 's#ngx_module_incs="/usr/local/include"#ngx_module_incs="/usr/include/fastdfs /usr/local/include/fastcommon/"#'g /usr/local/fastdfs-nginx-module/src/config 
sed -i 's#CORE_INCS="$CORE_INCS /usr/local/include"#CORE_INCS="$CORE_INCS /usr/include/fastdfs /usr/local/include/fastcommon/"#'g /usr/local/fastdfs-nginx-module/src/config 
```
报错二：
```
In file included from /usr/local/fastdfs-nginx-module/src/ngx_http_fastdfs_module.c:6:
/usr/local/fastdfs-nginx-module/src/common.c: In function ‘fdfs_http_request_handler’:
/usr/local/fastdfs-nginx-module/src/common.c:1245: error: ‘FDFSHTTPParams’ has no member named ‘support_multi_range’
make[1]: *** [objs/addon/src/ngx_http_fastdfs_module.o] Error 1
make[1]: Leaving directory `/usr/local/nginx-1.12.2'
make: *** [build] Error 2
```
解决：
```
sed -i 's#(pContext->range_count > 1 && !g_http_params.support_multi_range))#(pContext->range_count > 1))#g' /usr/local/fastdfs-nginx-module/src/common.c | grep '(pContext->range_count > 1))'
```
报错三：
```
[root@sz-145-centos177 data]# curl 'http://172.22.145.177:8888/group1/M00/00/00/rBaRsVuM9uCAEKkSAA76tz-dVgg.tar.gz'
<html>
<head><title>400 Bad Request</title></head>
<body bgcolor="white">
<center><h1>400 Bad Request</h1></center>
<hr><center>nginx/1.12.2</center>
</body>
</html>
```
解决
```
vim /etc/fdfs/mod_fastdfs.conf
url_have_group_name = false改为true
```

## 参考
> * [https://github.com/happyfish100/fastdfs/wiki](https://github.com/happyfish100/fastdfs/wiki)